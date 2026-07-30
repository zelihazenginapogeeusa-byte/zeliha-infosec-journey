# Blue Team Labs Online (BTLO) Cheat Sheet

A consolidated investigation-methodology reference distilled from my own 7 solved Blue Team Labs Online challenges (full write-ups linked at the bottom). Same idea as the [INE eJPT skill-check cheat sheet](../../Red-Team/01-Recon-and-OSINT/ine-ejpt-skill-check-ctfs-cheatsheet.md) on the offensive side: not a copy of tool syntax that already lives elsewhere in this repo, but the investigation sequence — what got checked first, what that pointed to next, and the one thing that actually mattered in each case.

For full command/query reference, follow the cross-links to the dedicated cheat sheets.

---

## 1. Log Analysis — Sysmon

**Scenario:** Reconstruct a full attacker kill chain from a single `sysmon-events.json` export — no live host, no SIEM, just raw process-creation/network/DLL-load events in a text file.

**Investigation path:**
1. Located the initial-access artifact first — an `updater.hta` file — before touching anything else in the log
2. Searched for PowerShell download cmdlets (`Invoke-WebRequest`) to find the payload-delivery step
3. Spotted **environment-variable manipulation** (`comspec` redirected to a malware path) — a defense-evasion technique worth specifically pattern-matching for
4. Tracked **LOLBIN abuse** — `ftp.exe` invoked from `SysWOW64`, a legitimate Windows binary repurposed for file transfer
5. Followed child-process spawning (`ipconfig`) as the recon step, then DLL loads (`python27.dll` + a PyInstaller `_MEI` temp-directory signature) to fingerprint the malware's implementation language
6. Found the secondary-payload download URL (a **JuicyPotato** privesc tool pulled from its official GitHub release — attackers regularly weaponize legitimate repos this way)
7. Closed the chain with the persistence mechanism — a Netcat reverse shell bound to `cmd.exe` on a specific port

**Lesson worth remembering:** a `_MEI` temp directory next to an unfamiliar process is a near-certain sign of PyInstaller-packaged Python malware — worth pattern-matching for by habit. And a privesc/offensive tool downloaded straight from its legitimate GitHub release (not a C2 server) is common enough that "official-looking download source" is not itself a signal of safety.

Full reference: [`windows-event-id-reference-cheatsheet-professional.md`](../01-SOC-and-SIEM-Analysis/windows-event-id-reference-cheatsheet-professional.md) · [`deepblue-cli-cheatsheet-professional.md`](../01-SOC-and-SIEM-Analysis/deepblue-cli-cheatsheet-professional.md) · [`event-log-triage-playbook-deepbluecli.md`](../01-SOC-and-SIEM-Analysis/event-log-triage-playbook-deepbluecli.md)

---

## 2. Malicious PowerShell Analysis

**Scenario:** "GothamLegend" was breached after an employee opened a phishing email; the IR team has an obfuscated PowerShell script (`ps_script.txt`, inside a password-protected archive) and needs the malware family plus IOCs.

**Investigation path:**
1. Extracted the archive, identified a Base64-encoded PowerShell blob
2. Ran it through **CyberChef** as a layered recipe, in this exact order: `From Base64` → `Decode text (UTF-16LE / 1200)` — PowerShell's `-EncodedCommand` always uses wide-character/UTF-16LE, so this step is not optional → `Find/Replace (Regex)` to strip obfuscation junk characters → `Find/Replace (Simple String)` to clean up concatenated protocol strings/URLs → `Split` to turn the resulting single-line blob into readable rows
3. Extracted each IOC (target directory, dropped DLL name, execution method, C2 domain) from the cleaned output
4. Cross-checked the domain/hash against VirusTotal, URLScan.io, and URLhaus to confirm the malware family (**Emotet**) and pull related C2 infrastructure

**Lesson worth remembering:** `From Base64 → Decode text (UTF-16LE)` is the specific two-step CyberChef combo for any PowerShell `-EncodedCommand` — trying to Base64-decode without the UTF-16LE step afterward produces garbled null-byte-interleaved text that looks like a dead end but isn't. Also: `Rundll32` executing a freshly-dropped `.dll` is a classic living-off-the-land execution pattern worth flagging on sight.

Full reference: [`malware-analysis-yara-cheatsheet-professional.md`](../02-DFIR-and-Threat-Intelligence/malware-analysis-yara-cheatsheet-professional.md) · [`reputation-lookup-tools-cheatsheet-professional.md`](../02-DFIR-and-Threat-Intelligence/reputation-lookup-tools-cheatsheet-professional.md) · [`python-for-blue-team-soc-automation-cheatsheet.md`](../01-SOC-and-SIEM-Analysis/python-for-blue-team-soc-automation-cheatsheet.md) (for scripted IOC extraction once the pattern is known)

---

## 3. The Report

**Scenario:** Different format from the others — no PCAP or log file, this challenge hands you a real-world annual threat report and asks you to translate it into detection strategy: MITRE ATT&CK mapping, specific CVEs, and actionable rules.

**Investigation path:**
1. Read the report through a **MITRE ATT&CK lens** rather than as prose — mapped each described campaign to specific technique IDs as you go (supply-chain/Log4j, `T1059` command execution, ProxyLogon/ProxyShell against Exchange, PrintNightmare privilege escalation, SEO-poisoning social engineering)
2. Traced Ransomware-as-a-Service affiliate structures — who the initial-access broker was vs. who deployed the actual ransomware (Qbot/BazarLoader/IcedID as loaders feeding into RaaS deployment)
3. Flagged legacy/outdated software (JBoss, WebLogic) as the recurring cryptojacking entry point across multiple incidents in the report
4. Converted each finding into a detection idea — e.g., parent-process monitoring for `wscript.exe` spawned somewhere it shouldn't be

**Lesson worth remembering:** this is the "read a CTI report like an analyst, not like a reader" skill — the useful output isn't a summary of what happened, it's a list of technique IDs and a parent-process/behavioral rule per technique. MFA on RDP specifically comes up across multiple ransomware case studies as the single highest-leverage mitigation — worth citing by name in any related report you write yourself.

Full reference: [`threat-intelligence-mitre-attack-cheatsheet-professional.md`](../02-DFIR-and-Threat-Intelligence/threat-intelligence-mitre-attack-cheatsheet-professional.md) · [`ransomware-incident-response-playbook.md`](../02-DFIR-and-Threat-Intelligence/ransomware-incident-response-playbook.md) · [`incident-response-lifecycle-cheatsheet-professional.md`](../02-DFIR-and-Threat-Intelligence/incident-response-lifecycle-cheatsheet-professional.md)

---

## 4. Network Analysis — Web Shell

**Scenario:** A SIEM alert fired for "Local to Local Port Scanning" between two internal IPs. A PCAP was provided containing the full chain from recon through webshell upload to reverse shell.

**Investigation path:**
1. `Statistics > Conversations > IPv4` first — immediately showed one pair of IPs dominating packet count (15,883 packets)
2. `tcp.flags.syn == 1 && tcp.flags.ack == 0` — isolated SYN-only packets to confirm this was a **half-open TCP SYN scan**, then `Statistics > Conversations > TCP` to see the scan swept ports 1–1024 with a consistent 2-packet-per-port pattern (scan fingerprint, not real traffic)
3. Plain HTTP traffic review turned up GET requests probing hidden files (`/.bashrc`, `/.history`) — then the User-Agent header directly named the tool: `gobuster/3.0.1`
4. A later batch of requests carried URL-encoded `UNION SELECT` payloads with a different User-Agent — `sqlmap/1.4.7` — confirming automated SQLi probing followed the directory brute-force
5. `http.request.method == "POST"` narrowed to the upload request → **Follow → HTTP Stream** showed the Referer header pointing back to `editprofile.php` (the vulnerable upload feature) and the MIME multipart body named the uploaded file: `dbfunctions.php`
6. Filtered on `http.request.uri contains "dbfunctions.php"` to watch it get invoked — the PHP checked a `cmd` request parameter, first command run was `id`, then a Python one-liner reverse shell connected back out

**Lesson worth remembering:** the User-Agent header alone identified both attack tools (`gobuster`, `sqlmap`) without needing to touch the payload bodies at all — always check it early in HTTP-heavy PCAP triage. The general shape here (broad stats view → narrow SYN filter → HTTP method filter → follow the one stream that matters) is the repeatable pattern for any "was this host compromised" PCAP question.

Full reference: [`wireshark-advanced-cheatsheet.md`](wireshark-advanced-cheatsheet.md) · [`wireshark-pcap-threat-hunting-playbook.md`](wireshark-pcap-threat-hunting-playbook.md) (port-scan and web-shell-upload playbooks specifically) · cross-team: [`web-shells-cheatsheet-professional.md`](../../Red-Team/02-Web-and-Network-Pentesting/web-shells-cheatsheet-professional.md) for what the offensive side of `dbfunctions.php` actually looks like

---

## 5. Phishing Analysis

**Scenario:** A suspicious `.eml` was forwarded to the SOC in a password-protected archive; the objective is collecting artifacts on the sender infrastructure and phishing tactics.

**Investigation path:**
1. Opened the `.eml` in an **isolated Thunderbird instance** — never a production mail client, for exactly the reason this challenge exists
2. **View > Message Source** for the raw headers — pulled the `X-Originating-IP` (`103.9.171.10`) directly out of the routing chain
3. Reverse-DNS'd that IP via WHOis/domaintools.com to get the resolved hosting host name
4. Viewed the body first in **Simple HTML** (safe layout check) then switched to **Plain Text** specifically to expose links that HTML rendering had disguised as button text
5. Ran the extracted URL through **URL2PNG** — a screenshot sandbox — to see the landing page without ever loading it in a real browser

**Lesson worth remembering:** switching an `.eml` between HTML, Simple HTML, and Plain Text views in sequence is the single most useful trick here — each view surfaces something the others hide, and Plain Text specifically is what defeats "the visible link text doesn't match the actual href" tricks.

Full reference: [`phishing-cheatsheet.md`](phishing-cheatsheet.md) · [`phishing-investigation-playbook.md`](phishing-investigation-playbook.md) · [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md)

---

## 6. Phishing Analysis II

**Scenario:** A second phishing triage exercise — this one impersonating Amazon, with an urgency-themed subject line ("Your Account has been locked").

**Investigation path:**
1. Same isolated-Thunderbird approach, switched immediately to **"Original HTML"** view to bypass a masked/templated layout
2. Raw headers gave sender (`amazon@zyevantoby.cn` — spoofed domain, not amazon.com) and timestamp
3. The call-to-action button's underlying URL went through an **Outlook Safe Links wrapper** (`emea01.safelinks.protection.outlook.com`) — had to decode through that wrapper layer to see the actual destination
4. Found a **Base64-encoded content block** in the email body — decoded in CyberChef — which revealed an asset URL pulling the fake Amazon logo from a legitimate CDN (`images.squarespace-cdn.com`), used specifically to make the fake page look authentic

**Lesson worth remembering:** a Safe Links–wrapped URL is not itself a sign of safety — it's Microsoft's own infrastructure being used by the attacker as an extra obfuscation layer around whatever the real destination is, and it always needs one more decode step, not zero. Also worth noting: attackers routinely pull real assets (logos, CSS) from legitimate CDNs to make a phishing page's chrome indistinguishable from the real thing — visual authenticity says nothing about the URL underneath it.

Full reference: [`phishing-cheatsheet.md`](phishing-cheatsheet.md) · [`phishing-investigation-playbook.md`](phishing-investigation-playbook.md)

---

## 7. Network Analysis — Malware Compromise

**Scenario:** SIEM alerted on connections from Sara's (an accountant's) machine to a known-malicious domain, after she opened a macro-enabled "invoice" attachment that crashed her Office app. Full PCAP provided; objective is the complete infection chain, malware families, and C2 infrastructure.

**Investigation path:**
1. `Statistics > Capture File Properties` then `Protocol Hierarchy` for a timeline/protocol overview before touching a single filter
2. `Statistics > Conversations > IPv4` sorted by byte count — immediately isolated the victim host (`10.11.27.101`) talking to three distinct external IPs
3. Checked all three external IPs against **VirusTotal** before doing any deeper packet work — confirmed all three were malicious, which set the investigation priority order
4. IP #1 (`95.181.198.231`): `ip.addr == ... && http` → GET request for `spet10.spr` → inspected the raw bytes, found an **MZ header** — a Windows executable disguised with a non-executable extension. A later request in the same stream pulled a second payload, `oiioiashdqbwe.rar` — deliberately randomized filename, a signal in itself
5. IP #2 (`176.32.33.108`): a GET to `/images` → Follow TCP Stream revealed the actual domain behind it, `cochrimato[.]com` — a configuration-retrieval callout, not real image content
6. IP #3 (`83.166.247.211`): no plaintext to read — this traffic was TLS. Read the **Client Hello's SNI field** directly (no decryption needed) to get the C2 domain `mautergase[.]com`, then fingerprinted the encrypted payload behavior as **Dridex** banking-trojan C2
7. Filtered the `185.0.0.0/8` range separately for a distinct post-infection beacon → found the actual exfiltration endpoint, `185.244.150.230`, with a TCP-SYN-to-TLS-1.2 handshake pattern indicating a secure tunnel had been established for the exfil channel

**Lesson worth remembering:** the **SNI field in a TLS Client Hello is readable in plaintext even when everything after the handshake is encrypted** — this is how you get a C2 domain out of fully-encrypted traffic without needing to decrypt anything. Also: a deliberately randomized filename (`oiioiashdqbwe.rar`) is itself a signal — normal traffic doesn't name files that way, so treat naming randomness as a detection heuristic, not just a curiosity. This case chained two distinct malware families (**Ursnif** as the initial dropper/credential harvester, **Dridex** as the secondary banking-trojan payload) — don't assume a single IOC set means a single piece of malware.

Full reference: [`wireshark-advanced-cheatsheet.md`](wireshark-advanced-cheatsheet.md) · [`wireshark-pcap-threat-hunting-playbook.md`](wireshark-pcap-threat-hunting-playbook.md) (C2/beaconing playbook specifically) · [`threat-intelligence-mitre-attack-cheatsheet-professional.md`](threat-intelligence-mitre-attack-cheatsheet-professional.md) (T1193, T1105, T1036, T1041 referenced in this case) · [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md)

---

## Patterns That Show Up Across All 7

- **Isolate before you open anything.** Every phishing/malware challenge starts the same way — an isolated Thunderbird instance for `.eml` files, sandboxed screenshot tools (URL2PNG, Browserling) for URLs, VirusTotal lookups before deep packet analysis. None of these write-ups touch the actual malicious artifact directly until it's contained.
- **Start broad, narrow progressively, then follow one stream.** Both PCAP challenges open with `Statistics > Conversations`/`Protocol Hierarchy` before a single display filter is typed — get the shape of the traffic first, then narrow to the conversation that matters, then `Follow Stream` for the payload.
- **User-Agent headers are an underused goldmine.** They directly named `gobuster`, `sqlmap`, and (implicitly through behavior) automated scanning tools across multiple write-ups — check this field early in any HTTP-heavy investigation.
- **Encrypted traffic still leaks metadata.** SNI fields in TLS Client Hello packets gave up C2 domains without any decryption — this is a repeatable technique any time TLS shows up in a PCAP challenge.
- **CyberChef's Base64 → UTF-16LE combo is specifically for PowerShell.** It came up in more than one challenge; worth having as a saved recipe rather than re-deriving it each time.
- **Randomized/nonsensical filenames and domains are themselves an indicator** — real infrastructure and real users don't name things `oiioiashdqbwe.rar` or `35000usdperwwekpodf.blogspot.sg`. Naming entropy is a cheap, fast heuristic before any reputation lookup.
- **Report-reading is its own skill, distinct from log/PCAP analysis** — "The Report" challenge is a reminder that CTI consumption (mapping prose to ATT&CK technique IDs and turning that into a detection rule) is tested separately from technical triage, and is just as much a BTL1-relevant skill.

---

## Full Write-ups (Medium)

- [Log Analysis — Sysmon](https://medium.com/@zeliharich/blue-team-online-btlo-log-analysis-sysmon-e0d4f15518ed)
- [Malicious PowerShell Analysis](https://medium.com/@zeliharich/blue-team-labs-online-btlo-malicious-powershell-analysis-ce8f7bbc2afd)
- [The Report](https://medium.com/@zeliharich/blue-team-online-btlo-the-report-bd6af1552d8f)
- [Network Analysis — Web Shell](https://medium.com/@zeliharich/blue-team-labs-online-btlo-network-analysis-web-shell-b81811ef8b38)
- [Phishing Analysis](https://medium.com/@zeliharich/blue-team-labs-online-phishing-analysis-2dff1c2c5182)
- [Phishing Analysis II](https://medium.com/@zeliharich/blue-team-labs-online-phishing-analysis-ii-bd4b72d29523)
- [Network Analysis — Malware Compromise](https://medium.com/@zeliharich/blue-team-labs-online-network-analysis-malware-compromise-challenge-bc8fa57b6dac)

---

*BTL1 exam-day methodology and checklist: [`incident-response-exam-checklist.md`](incident-response-exam-checklist.md). Full command/query syntax for anything referenced above lives in the linked cheat sheets, not repeated here. Offensive-side counterpart: [`ine-ejpt-skill-check-ctfs-cheatsheet.md`](../../Red-Team/01-Recon-and-OSINT/ine-ejpt-skill-check-ctfs-cheatsheet.md).*
