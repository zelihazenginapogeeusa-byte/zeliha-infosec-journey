# INE eJPT Skill-Check CTFs — Cheat Sheet

A consolidated "path to the flags" reference distilled from my own 15 solved INE eJPT skill-check CTFs (full write-ups linked at the bottom). Organized by INE's own module breakdown — Assessment Methodologies → Host & Network Penetration Testing → Web Application Penetration Testing — the same order the actual exam is structured around.

This page is **not** a copy of tool syntax that already lives in this repo's other cheat sheets — it's the sequence: which tool ran first, what its output pointed to next, and the one thing that actually mattered in each skill-check. For full command reference, follow the cross-links to the dedicated cheat sheets.

---

## Domain 1 — Assessment Methodologies

### 1.1 Information Gathering

**Scenario:** A single web target, five flags, pure passive/light-active recon — no exploitation.

**Path to the flags:**
1. `nmap -sV -Pn -A -p- target.ine.local` — full port sweep + service/version ID
2. Check `/robots.txt` directly — search-engine directives often leak paths nobody meant to expose
3. `dirb target.ine.local` → then a second, extension-targeted pass: `dirb target.ine.local -w /usr/share/dirb/wordlists/big.txt -X .bak,.tar.gz,.zip,.sql`
4. `curl` a discovered backup file directly (`wp-config.bak`) once dirb pointed at it
5. `httrack target.ine.local -O target.html` — full local mirror, then grep the mirrored files offline for anything the live crawl missed

**Lesson worth remembering:** the "quick win" order is robots.txt → nmap version detection → directory brute-force → *then* a second brute-force pass restricted to backup/archive extensions specifically. Full-site mirroring (HTTrack) is a good last resort when the target's own crawl-blocking hides things a live dirb pass won't reach.

Full command reference: [`nmap-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/nmap-cheatsheet-professional.md) · [`dirb-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/dirb-cheatsheet-professional.md) · [`osint-cheatsheet.md`](osint-cheatsheet.md)

---

### 1.2 Footprinting and Scanning

**Scenario:** Similar single-target setup, four flags — this time enumeration snowballs from one exposed service into full database access.

**Path to the flags:**
1. `nmap -sV -A -Pn -p- target.ine.local` — identified an FTP service allowing **anonymous login**
2. Browser dev tools / response headers as a secondary server-ID method (worth doing alongside nmap, not instead of it)
3. `robots.txt` → hidden path → `curl` the flag file directly
4. `ftp target.ine.local` with anonymous credentials → downloaded a `creds.txt` sitting in the FTP root
5. Those FTP-harvested credentials were valid for **MySQL** on 3306: `mysql -u db_admin -p -h target.ine.local` → `show databases;`

**Lesson worth remembering:** anonymous FTP is still a live finding in 2026 skill-checks, and credentials found in one service (FTP) routinely unlock a completely different one (MySQL) later in the same chain — always harvest and reuse, never treat a service as a dead end just because it wasn't the final target.

Full command reference: [`nmap-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/nmap-cheatsheet-professional.md)

---

### 1.3 Vulnerability Assessment

**Scenario:** Four flags, Nessus dashboard provided alongside manual tooling — the point of this module is connecting scanner output to manual confirmation.

**Path to the flags:**
1. `nmap -sV -A -sC -Pn -p- target.ine.local`
2. `cat /etc/hosts` to confirm name resolution was actually pointing where expected
3. Nmap's own output surfaced an exposed **`.git/`** directory — browsed to it directly for the flag
4. `robots.txt` → exposed `/passwords/` and `/phpmyadmin/` paths
5. `dirb` turned up `phpinfo.php` — full PHP config disclosure, flag embedded in the output
6. `/passwords/flag.txt` — plain-text file sitting in the exposed directory from step 4

**Lesson worth remembering:** an exposed `.git/` directory and a reachable `phpinfo.php` are two of the highest-value "free" findings a vuln scan (or a human reading nmap output carefully) can turn up — both disclose far more than their innocuous names suggest, and both are still common in real engagements.

Full command reference: [`vulnerability-assessment-cheatsheet-professional.md`](vulnerability-assessment-cheatsheet-professional.md) · [`nmap-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/nmap-cheatsheet-professional.md)

---

### 1.4 Enumeration

**Scenario:** One Linux target, four flags, entirely built around SMB enumeration snowballing into FTP and SSH.

**Path to the flags:**
1. `nmap -sV -Pn -A -p- -sC target.ine.local` — SMB (445), FTP (non-standard port), SSH open
2. `smbmap -H <IP> -u anonymous` then `-r pubfiles` — anonymous SMB access confirmed, public share listed
3. `enum4linux -a target.ine.local` — pulled four valid usernames straight off SMB
4. Metasploit `auxiliary/scanner/smb/smb_login` against those usernames — weak credential found
5. `hydra -L smbusers.txt -P unix_passwords.txt ftp://target.ine.local -s <port>` — FTP brute-force using the SMB-derived username list
6. `ssh target.ine.local` with the same credential pattern for the final flag

**Lesson worth remembering:** SMB is usually the richest *username* source on a Linux box (via `enum4linux`), even when the actual compromise ends up happening over FTP or SSH — enumerate the "boring" service first specifically to build the credential/username list you'll brute-force everything else with.

Full command reference: [`smb-windows-enumeration-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/smb-windows-enumeration-cheatsheet-professional.md) · [`hydra-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/hydra-cheatsheet-professional.md) · [`crackmapexec-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/crackmapexec-cheatsheet-professional.md)

---

## Domain 2 — Host & Network Penetration Testing

### 2.1 System/Host-Based Attacks — CTF 1

**Scenario:** Two targets, four flags — WebDAV misconfiguration on target1, SMB admin-share access on target2.

**Path to the flags:**
1. Recon both hosts: `cat /etc/hosts`, `nmap -sV -A -Pn -p- target1.ine.local`
2. `crackmapexec smb` / `hydra ... http-get` against a known username (`bob`) → weak password recovered
3. `dirb` (authenticated) found `/webdav/` — `davtest -auth bob:<pass> -url .../webdav` confirmed write access
4. `cadaver .../webdav/` → uploaded an ASP web shell → command execution through the HTTP interface (Metasploit's WebDAV module is the alternate path here)
5. On target2: `hydra` against SMB → admin credentials recovered → `crackmapexec smb ... --shares` → `smbclient //target2/C$ -U administrator` → walked the filesystem (`Users` → `Desktop`) for the remaining two flags

**Lesson worth remembering:** WebDAV that allows `PUT` is a direct code-execution primitive the moment you have valid credentials for it — always run `davtest` the instant dirb/gobuster surfaces a `/webdav/` path. On the Windows side, `C$` admin-share access is effectively full filesystem read once administrator credentials are in hand.

Full command reference: [`web-shells-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/web-shells-cheatsheet-professional.md) · [`smb-windows-enumeration-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/smb-windows-enumeration-cheatsheet-professional.md) · [`hydra-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/hydra-cheatsheet-professional.md)

---

### 2.2 System/Host-Based Attacks — CTF 2

**Scenario:** Two targets, four flags — Shellshock on target1, libssh auth bypass + SUID-style binary hijack on target2.

**Path to the flags:**
1. `nmap -sV -sC -p- -Pn -A` + `dirb` on target1 → CGI endpoint identified
2. Metasploit Shellshock module against the CGI endpoint → shell → read `/flag.txt` and hidden files under the web root
3. On target2: Metasploit's **libssh authentication bypass** module, `SPAWN_PTY true` set explicitly — this option matters, without it the session doesn't behave like an interactive shell
4. Privilege escalation via **binary hijacking**: `strace ./welcome` to see what it called → removed the legitimate `greetings` binary it invoked → replaced it with a copy of `/bin/bash` → ran the sudoer-privileged `welcome` binary → landed root

**Lesson worth remembering:** `strace` on an unfamiliar sudoer-privileged binary is the fastest way to spot a hijackable subprocess call — if it invokes another binary by name (not full path) and you can write to that name earlier in `$PATH`, that's privilege escalation. This is the same class of bug the repo's [privesc cheat sheet](../03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md) calls PATH-hijacking.

Full command reference: [`metasploit-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/metasploit-cheatsheet-professional.md) · [`privilege-escalation-linux-windows-cheatsheet.md`](../03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md)

---

### 2.3 Network-Based Attacks

**Scenario:** No live target at all — a single `.pcap` capture of a malware-infected Windows client, six flags, 100% Wireshark.

**Path to the flags:**
1. `http.response.code == 200` — isolate the successful requests first, ignore the noise
2. Plain `http` filter → traced which domain the infected host actually talked to
3. `nbns` (or `udp.port == 137`) → NetBIOS Name Service broadcast revealed the infected host's hostname
4. Edit → Find Packet for a suspicious filename (`mystery_file.ps1`) referenced in the traffic → pulled the raw packet bytes, searched them for a `Users\` path to get the logged-in username
5. Searched packet data for a PowerShell-specific User-Agent string
6. Found a Coinbase reference → Follow → TCP Stream → reconstructed the full request/response to pull a wallet/extension ID out of the JSON body

**Lesson worth remembering:** this entire skill-check never touched a live host — it's pure PCAP triage, and the flag order tells you the intended analyst workflow: filter to successful HTTP first, then work outward (host ID → NetBIOS → filename search → follow-stream). This maps directly onto the repo's [Wireshark/PCAP threat-hunting playbook](../../Blue-Team/02-DFIR-and-Threat-Intelligence/wireshark-pcap-threat-hunting-playbook.md) — worth reading that side even for the offensive exam, since the analysis technique is identical either direction.

---

### 2.4 Exploitation — CTF 1

**Scenario:** Two Linux targets, four flags — a CMS exploit with supplied creds, SSH brute-force, and a WordPress plugin file-read bug.

**Path to the flags:**
1. Standard recon (`nmap -p- -sV -sC -A`, `dirb`) on target1 identified a **FlatCore CMS** install
2. `searchsploit flatcore` → a public Python PoC (`50262.py`) run directly against the target with supplied admin credentials → flag + shell-equivalent access
3. `hydra -l <user> -P unix_passwords.txt ssh://<target1>` against a second, weaker system user → SSH in directly for flag 2
4. On target2: `gobuster dir ... -w wp-plugins.lst` against `/wp-content/plugins/` specifically (not the general wordlist) → found the **Duplicator** plugin
5. Metasploit's Duplicator arbitrary file-read module → dumped `/etc/passwd` → identified an unauthenticated system user → SSH'd straight in for the last flag

**Lesson worth remembering:** when the target is confirmed as WordPress, running gobuster against `/wp-content/plugins/` with a plugin-specific wordlist (`wp-plugins.lst`, ships with nmap's NSE data) finds vulnerable plugins far faster than a generic directory brute-force ever will.

Full command reference: [`web-enumeration-common-vulns-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/web-enumeration-common-vulns-cheatsheet-professional.md) · [`exploitation-techniques-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/exploitation-techniques-cheatsheet-professional.md) · [`hydra-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/hydra-cheatsheet-professional.md)

---

### 2.5 Exploitation — CTF 2

**Scenario:** One Windows target (IIS + SMB + FTP), four flags — the longest chain of the fifteen: SMB brute-force → leaked hash file → pass-the-hash → FTP creds → full reverse shell via file upload.

**Path to the flags:**
1. `hydra ... smb://` **failed outright** against a modern SMBv2/v3 host — the lesson embedded in the write-up itself: legacy Hydra SMB modules don't handle newer dialects, switch to `crackmapexec smb` instead
2. `crackmapexec smb target -u tom -p rockyou.txt` → valid password found → `--shares` to enumerate what tom could reach
3. `smbclient` into an HR share → `mget *` pulled down a file that itself contained a **leaked NTLM hash dump**
4. Extracted the NTLM column (`cut -d':' -f2`), then tested **pass-the-hash** directly against another account (`nancy`) with `smbclient --pw-nt-hash` — no cracking needed, the hash alone was enough
5. Confirmed the same login via Metasploit's `smb_login` scanner using the hash as the "password" field
6. Separately, FTP credentials (`david`) turned up in an accessible share → used to `put` an `msfvenom`-generated `windows/x64/meterpreter/reverse_tcp` payload as `shell.aspx`
7. `multi/handler` listener set up, payload triggered by requesting `shell.aspx` over HTTP (IIS executes it) → full Meterpreter session → final flag

**Lesson worth remembering:** a leaked NTLM hash doesn't need cracking to be useful — pass-the-hash against SMB works directly, and it's often faster than sending the hash to John/Hashcat first. Also: tool choice matters — Hydra's SMB module choking on a modern dialect isn't a dead end, it's a signal to reach for CrackMapExec instead.

Full command reference: [`crackmapexec-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/crackmapexec-cheatsheet-professional.md) · [`metasploit-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/metasploit-cheatsheet-professional.md) · [`meterpreter-command-reference-cheatsheet.md`](../03-Exploitation-and-Post-Exploitation/meterpreter-command-reference-cheatsheet.md) · [`web-shells-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/web-shells-cheatsheet-professional.md)

---

### 2.6 Exploitation — CTF 3

**Scenario:** Two Linux targets, four flags — a ProFTPD CVE, a mystery local service on loopback, an SMB-delivered PHP web shell, and classic SUID privesc.

**Path to the flags:**
1. `nmap -sV -sC -Pn -p- -A` on target1 → **ProFTPD 1.3.5** identified → Metasploit had a matching module (`set SITEPATH`, `set RHOSTS`, `exploit`) → shell → flag 1
2. From that shell, `netstat -tuln | grep 127.0.0.1` turned up a service listening **only on loopback** on a high port → `nc -nv 127.0.0.1 <port>` → prompted for a passphrase found earlier in recon → flag 2
3. On target2: `enum4linux -a` → writable `site-uploads` SMB share → copied `/usr/share/webshells/php/php-reverse-shell.php`, edited the IP/port, `put` it via `smbclient` → requested it over HTTP → caught the callback with a netcat listener → flag 3
4. `find / -perm -4000 -type f 2>/dev/null` → a SUID binary that supports `-exec` → `find / -exec /bin/rbash -p \; -quit` to spawn a privileged (and `-p` = permission-preserving) shell → root → flag 4

**Lesson worth remembering:** always check `netstat -tuln` for loopback-only services after landing any shell — they're invisible from nmap entirely and are often exactly where the next flag/pivot lives. And the classic `find ... -exec ... -p` SUID escape (straight off GTFOBins) still shows up in current skill-checks essentially unchanged.

Full command reference: [`privilege-escalation-linux-windows-cheatsheet.md`](../03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md) · [`web-shells-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/web-shells-cheatsheet-professional.md) · [`netcat-reverse-shell-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/netcat-reverse-shell-cheatsheet-professional.md)

---

### 2.7 The Metasploit Framework — CTF 1

**Scenario:** One Windows target, four flags, MSSQL → privesc → deep filesystem exploration — and a specific architecture-mismatch trap.

**Path to the flags:**
1. Recon confirmed MSSQL on 1433 → Metasploit module search for **SQL Server 2012**
2. First attempt used an **x86** reverse_tcp payload against what turned out to be an **x64** target — exploit ran but no session; re-ran with `windows/x64/meterpreter/reverse_tcp` and it landed
3. Initial access was as the `MSSQLSERVER` service account, not a full admin — `getsystem` escalated via **Named Pipe Impersonation** (`SeImpersonatePrivilege`)
4. From there: `dir C:\Windows\System32\*.txt /s /b` (recursive search) located flags scattered across `C:\`, `System32\config`, `System32\drivers\etc`, and `Users\Administrator\Desktop`

**Lesson worth remembering:** always confirm target architecture (`nmap`'s OS/service fingerprinting, or just try both) before picking a Metasploit payload — an x86 payload against an x64 target frequently "succeeds" at the exploit stage and then silently produces no session, which looks like a different failure entirely if you don't know to check architecture first.

Full command reference: [`metasploit-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/metasploit-cheatsheet-professional.md) · [`meterpreter-command-reference-cheatsheet.md`](../03-Exploitation-and-Post-Exploitation/meterpreter-command-reference-cheatsheet.md)

---

### 2.8 The Metasploit Framework — CTF 2

**Scenario:** Two targets, four flags — unauthenticated RSYNC backup exposure, then a web app exploit, then cron-job credential discovery.

**Path to the flags:**
1. `nmap` found RSYNC (873) open → `rsync rsync://<target>/` listed modules **with no authentication required at all**
2. `rsync -av rsync://<target>/backupwscohen ./backupwscohen` — pulled the entire backup module locally → sensitive files inside contained flag 2 directly, no exploitation needed
3. On target2: Metasploit module for **Roxy-WI** → Python-based Meterpreter payload → shell as `www-data`
4. Meterpreter's non-interactive shell was upgraded to a real interactive one (`/bin/bash -i`) for usability
5. `ls -la /etc/cron.d/` → a `www-data`-owned cron file contained the final flag in plaintext

**Lesson worth remembering:** an unauthenticated RSYNC module is functionally the same severity as an open S3 bucket — full read access to whatever's inside, no exploit required, just `rsync -av` and read. Also worth internalizing: `/etc/cron.d/` and other scheduled-task locations are a startlingly common place to find plaintext credentials once you have any shell at all — check them by habit, not just when stuck.

Full command reference: [`metasploit-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/metasploit-cheatsheet-professional.md) · [`post-exploitation-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/post-exploitation-cheatsheet-professional.md)

---

### 2.9 Post-Exploitation — CTF 1

**Scenario:** Two targets, five flags — libssh auth bypass, config-file harvesting, credential reuse across hosts, and direct `/etc/shadow` editing for root.

**Path to the flags:**
1. Metasploit's **libssh** module against target1 (`SPAWN_PTY true`) → unauthenticated shell → flags pulled straight from `/etc/passwd`, `/etc/group`, `/etc/cron.d`, and `/etc/hosts` in sequence
2. Credentials for a user (`john`) turned up sitting in a home-directory file during that enumeration → reused directly for **SSH into target2**
3. On target2, with filesystem write access already established: generated a new password hash (`openssl passwd -1 -salt abc <password>`), edited `/etc/shadow` directly to replace root's hash, then `su root`

**Lesson worth remembering:** if you can already write to `/etc/shadow` (rare, but it happens when permissions are misconfigured), you don't need a formal privesc exploit at all — generating a compatible hash with `openssl passwd` and overwriting root's entry is faster and simpler than hunting for a kernel exploit or SUID binary.

Full command reference: [`privilege-escalation-linux-windows-cheatsheet.md`](../03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md) · [`post-exploitation-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/post-exploitation-cheatsheet-professional.md)

---

### 2.10 Post-Exploitation — CTF 2

**Scenario:** One Windows target, four flags — SSH brute-force, offline hash cracking, Print Spooler privesc, then an ACL fix to reach the flag.

**Path to the flags:**
1. `hydra -l alice -P unix_passwords.txt <target> ssh` → password found → SSH in
2. A discovered `hashdump.txt` cracked offline both ways — `john --format=NT` and `hashcat -m 1000`, same wordlist — recovering a second user's (`david`) password
3. `scp PrintSpoofer64.exe david@target:...` → `PrintSpoofer64.exe -i -c cmd` → SYSTEM via the **Print Spooler** service abuse
4. The flag file's ACL explicitly denied `NT AUTHORITY\SYSTEM` — `icacls flag /remove:d "NT AUTHORITY\SYSTEM"` stripped the deny entry before the flag could actually be read

**Lesson worth remembering:** getting SYSTEM doesn't automatically mean you can read every file — an explicit **Deny ACE** on a specific principal (even SYSTEM) overrides any Allow, exactly as covered in the [Windows/Linux access-control cheat sheet](../../Blue-Team/01-SOC-and-SIEM-Analysis/windows-linux-system-security-access-control-cheatsheet.md). `icacls /remove:d` is the fix once you have the rights to modify the ACL at all.

Full command reference: [`hydra-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/hydra-cheatsheet-professional.md) · [`john-the-ripper-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/john-the-ripper-cheatsheet-professional.md) · [`hashcat-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/hashcat-cheatsheet-professional.md) · [`privilege-escalation-linux-windows-cheatsheet.md`](../03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md)

---

## Domain 3 — Web Application Penetration Testing

### 3.1 Web Application Penetration Testing

**Scenario:** One web target, four flags — LFI, directory enumeration, credential brute-force, and a straightforward SQLi auth bypass to close it out.

**Path to the flags:**
1. `nmap -sV -sC -A -p- -Pn` + `dirb`/`gobuster` located a file-viewing feature (`?file=`)
2. Path traversal — `../../../../` prefixed onto the parameter — read `flag1.txt` straight off the filesystem
3. Directory brute-force alone (no exploitation) surfaced flag 2 in an unlinked but accessible directory
4. `hydra ... http-post-form "/login:username=^USER^&password=^PASS^:Invalid username or password"` — the exact error string is what makes Hydra's form-based brute-force work; found valid admin credentials
5. Separately, the login form itself was vulnerable — `admin' OR 1=1 -- -` bypassed authentication entirely without needing the brute-forced password at all

**Lesson worth remembering:** this box deliberately has two different ways into the same admin panel — brute-force *and* SQLi — which is a good reminder that a successful credential attack doesn't mean the form itself was actually secure; always still test the injection angle even after a brute-force succeeds, since exam graders (and real assessments) usually want both findings documented.

Full command reference: [`web-enumeration-common-vulns-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/web-enumeration-common-vulns-cheatsheet-professional.md) · [`sqlmap-cheatsheet-professional.md`](../02-Web-and-Network-Pentesting/sqlmap-cheatsheet-professional.md) · [`hydra-cheatsheet-professional.md`](../03-Exploitation-and-Post-Exploitation/hydra-cheatsheet-professional.md)

---

## Patterns That Show Up Across All 15

A few things repeated often enough across every domain that they're worth calling out as habits rather than per-CTF notes:

- **First move, every single time:** `cat /etc/hosts` to confirm resolution, then `nmap -sV -sC -Pn -A -p-` — full port range, not the default top-1000. Every one of the fifteen write-ups opened this way.
- **`robots.txt` and backup-extension directory brute-forcing** (`.bak`, `.zip`, `.sql`, `.old`) turned up a flag or a credential in roughly a third of the web-facing CTFs — it's disproportionately high-value for the time it costs.
- **Credentials never stay in the service they were found in** — FTP creds unlocked MySQL; SMB enumeration produced the username list FTP/SSH were brute-forced with; a leaked hash dump on one share enabled pass-the-hash against a completely different account. Treat every credential as reusable everywhere until proven otherwise.
- **Metasploit's own bundled wordlists** (`/usr/share/metasploit-framework/data/wordlists/`) came up constantly — `unix_passwords.txt` and `common_users.txt` specifically — often before reaching for `rockyou.txt`.
- **Tool choice matters at the protocol-version level** — Hydra's SMB module failed outright against a modern SMBv2/v3 host in one write-up; CrackMapExec is the safer default for SMB authentication testing today.
- **Post-exploitation checklist that paid off repeatedly:** `/etc/passwd`, `/etc/group`, `/etc/cron.d/` (or Windows scheduled tasks), and any user home directory — all four produced either a flag or a credential for lateral movement in multiple write-ups, independent of how the initial shell was obtained.
- **SUID/GTFOBins-style privesc** (`find ... -exec ... -p`) and **Windows service-abuse privesc** (Print Spooler / PrintSpoofer) each appeared more than once — both are still worth checking early rather than as a last resort.

---

## Full Write-ups (Medium)

**Domain 1 — Assessment Methodologies:**
- [Information Gathering — CTF 1](https://medium.com/@zeliharich/ejpt-ine-assessment-methodologies-information-gathering-ctf-1-9b30bbe5c21b)
- [Footprinting and Scanning — CTF 1](https://medium.com/@zeliharich/ejpt-ine-assessment-methodologies-footprinting-and-scanning-ctf-1-7a40ba327576)
- [Vulnerability Assessment — CTF 1](https://medium.com/@zeliharich/ejpt-ine-assessment-methodologies-vulnerability-assessment-ctf-1-6955b71813f1)
- [Enumeration — CTF 1](https://medium.com/@zeliharich/ejpt-ine-assessment-methodologies-enumeration-ctf-1-814413430315)

**Domain 2 — Host & Network Penetration Testing:**
- [System/Host-Based Attacks — CTF 1](https://medium.com/@zeliharich/host-network-penetration-testing-system-host-based-attacks-ctf-1-05ed3fee4823)
- [System/Host-Based Attacks — CTF 2](https://medium.com/@zeliharich/host-network-penetration-testing-system-host-based-attacks-ctf-2-d7b41f01ca61)
- [Network-Based Attacks — CTF 1](https://medium.com/@zeliharich/host-network-penetration-testing-network-based-attacks-ctf-1-d46c1cb4cddd)
- [Exploitation — CTF 1](https://medium.com/@zeliharich/host-network-penetration-testing-exploitation-ctf-1-e4d944a532da)
- [Exploitation — CTF 2](https://medium.com/@zeliharich/host-network-penetration-testing-exploitation-ctf-2-7a6fb2b13aa8)
- [Exploitation — CTF 3](https://medium.com/@zeliharich/host-network-penetration-testing-exploitation-ctf-3-e89601e7cc26)
- [The Metasploit Framework — CTF 1](https://medium.com/@zeliharich/host-network-penetration-testing-the-metasploit-framework-ctf-1-5e539b8cd3fe)
- [The Metasploit Framework — CTF 2](https://medium.com/@zeliharich/host-network-penetration-testing-the-metasploit-framework-ctf-2-df183244e98b)
- [Post-Exploitation — CTF 1](https://medium.com/@zeliharich/host-network-penetration-testing-post-exploitation-ctf-1-11244ad143c5)
- [Post-Exploitation — CTF 2](https://medium.com/@zeliharich/host-network-penetration-testing-post-exploitation-ctf-2-ine-ejpt-17e1df0279bf)

**Domain 3 — Web Application Penetration Testing:**
- [Web Application Penetration Testing — CTF 1](https://medium.com/@zeliharich/web-application-penetration-testing-ctf-1-2ffa27eea1f8)

---

*Exam-day methodology and checklist: [`ejpt-exam-checklist-and-methodology.md`](ejpt-exam-checklist-and-methodology.md). Full technical syntax for anything referenced above lives in the linked cheat sheets, not repeated here. Defensive-side counterpart: [`blue-team-labs-online-btlo-cheatsheet.md`](../../Blue-Team/02-DFIR-and-Threat-Intelligence/blue-team-labs-online-btlo-cheatsheet.md).*
