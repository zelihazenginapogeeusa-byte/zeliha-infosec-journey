# Wireshark / PCAP Threat-Hunting Playbook

Scenario-driven investigation procedures — for filter syntax, stream-following, and tshark usage itself, see [`wireshark-advanced-cheatsheet.md`](wireshark-advanced-cheatsheet.md). This document is about **what to look for, in order**, once you have a capture in front of you (live capture or a provided `.pcap`/`.pcapng`).

> All techniques below are for use in **authorized environments only** — this playbook assumes an authorized lab, exam, or incident-response engagement.

---

## Playbook 1 — "I Have a PCAP, No Context" (General Triage)

**Trigger:** You've been handed a capture with little or no context and told to "find anything suspicious."

1. Check **Statistics → Protocol Hierarchy** first — an unusual protocol distribution (e.g., unexpected DNS volume, raw TCP with no recognized upper-layer protocol) points you where to dig before you look at a single packet.
2. Check **Statistics → Conversations** (TCP/UDP tabs, sorted by bytes) — the top talkers are your starting point, not a random scroll through the packet list.
3. Check **Statistics → Endpoints** — anything talking to a public IP that has no business reason to (unexpected geography, unfamiliar ASN).
4. Skim **DNS queries** for anything algorithmically-generated-looking (long random subdomains, high query volume to one domain) — see the beaconing/DGA notes in the cheat sheet.
5. **Escalate if:** a host is exchanging traffic with an unfamiliar external IP/domain at a suspiciously regular interval, or protocol hierarchy shows something that shouldn't be there (e.g., DNS-over-TCP-53 tunneling patterns, HTTP where only HTTPS is expected).
6. **Close as benign if:** every top talker/protocol maps to a known, expected business service (backup jobs, update servers, approved SaaS).

---

## Playbook 2 — Suspected C2 / Beaconing

**Trigger:** A host is suspected of checking in with a command-and-control server (recurring outbound connections, EDR alert referencing network activity, or found while working Playbook 1).

1. Isolate the suspect host's traffic (`ip.addr == <host>`) and sort by time — look for a **regular interval** between connection attempts (every N seconds/minutes, with low jitter — a strong beaconing indicator vs. organic human browsing).
2. Check the destination — is it a raw IP with no legitimate reverse DNS, a newly-registered-looking domain, or a domain not matching the traffic's claimed protocol (e.g., "HTTPS" traffic to a domain with no valid cert)?
3. Check payload size consistency — beacons are frequently small, uniform-size check-ins rather than the variable sizes of normal browsing.
4. Follow the TCP/TLS stream for the session — for unencrypted C2, look directly at the payload; for TLS, check the **SNI** field and certificate details (self-signed, mismatched CN, very recent issue date).
5. **Escalate if:** regular-interval connections to an unfamiliar/unreputable destination are confirmed — treat the source host as compromised.
6. **Containment:** isolate the host, block the destination IP/domain at the firewall/proxy, preserve the full pcap for the affected window before retention rolls it off.

---

## Playbook 3 — Data Exfiltration Over the Wire

**Trigger:** Alert on abnormal outbound volume, or found while triaging a host already flagged for other suspicious activity.

1. Filter to the suspect host and sort **Conversations by bytes sent** (not received) — exfil shows up as an outbound-heavy asymmetry, the opposite of normal browsing/download traffic.
2. Identify the protocol carrying the volume — is it going out over an expected channel (HTTPS to a sanctioned SaaS) or something unusual (DNS with abnormally large/frequent queries — a classic DNS-tunneling signal; FTP/unencrypted protocols to an external host; large POST bodies to an unfamiliar domain)?
3. If DNS is the suspected channel: check for abnormally long subdomains, high query rate to one domain, and TXT/NULL record types being used unusually heavily — see the DNS-tunneling notes in the cheat sheet.
4. Check the timing — does the transfer correlate with any other suspicious activity on the same host (phishing click, PowerShell alert)? Exfil is rarely an isolated first-stage event.
5. **Escalate if:** outbound volume to an unfamiliar/external destination is confirmed and not explained by an approved application.
6. **Containment:** block the destination, isolate the host, preserve logs/pcap, and scope what data the host had access to before the transfer.

---

## Playbook 4 — Credential Capture / Cleartext Protocol Abuse

**Trigger:** Concern that credentials may have been sent in the clear, or captured via a rogue service on the network (e.g., suspected LLMNR/NBT-NS poisoning, rogue AP, ARP spoofing).

1. Filter for cleartext auth protocols carrying credentials: `http.authorization`, `ftp.request.command == "PASS"`, `pop.request.command == "PASS"`/`imap`, or plaintext `telnet` sessions.
2. Follow the relevant stream directly — cleartext credentials will be visible in the payload.
3. For suspected LLMNR/NBT-NS/mDNS poisoning: filter `llmnr || nbns || mdns` and look for an unexpected host answering name-resolution requests it has no authority over, followed by an SMB/NTLM auth attempt to that host.
4. For suspected ARP spoofing: filter `arp` and look for duplicate/conflicting MAC-to-IP mappings, or an unusually high rate of ARP replies from one host.
5. **Escalate if:** credentials are confirmed captured in cleartext, or a rogue host is confirmed answering name-resolution requests it shouldn't.
6. **Containment:** force a password reset for any exposed account, identify and remove the rogue host/service, and check for lateral movement using the exposed credential.

---

## Playbook 5 — Port Scan / Internal Reconnaissance Detected

**Trigger:** Alert on a burst of connection attempts across many ports/hosts from a single source.

1. Confirm the shape: one source touching many destination ports on one host (**port scan**) vs. one/few ports across many destination hosts (**host/network sweep**) — filter and sort by destination port and destination IP respectively.
2. Check the TCP flags used — SYN-only with no completed handshake (`tcp.flags.syn==1 && tcp.flags.ack==0`) suggests a stealth/SYN scan; full handshakes suggest a connect-scan or legitimate service probing.
3. Identify the source — internal host (potentially compromised, now scanning laterally) or external (perimeter probing)?
4. Check whether any scanned port received a **follow-up connection** after the scan completed — this is the difference between "someone scanned and walked away" and "someone scanned, then exploited what they found."
5. **Escalate if:** the source is an internal host not authorized to perform scanning (i.e., not a vuln-scanner/asset-management tool), or any follow-up exploitation traffic is observed.
6. **Containment:** isolate the scanning host if internal and unauthorized; block the source at the perimeter if external and aggressive.

---

## General Escalation Criteria (Applies Across All Playbooks)

Escalate to incident response / management immediately, regardless of the specific playbook, if any of the following are true:
- Traffic confirms an internal host communicating with a known-bad or highly suspicious external destination.
- Evidence of credentials transmitted in the clear or captured via a rogue service.
- Evidence that reconnaissance (scanning) was followed by actual exploitation traffic.
- Multiple playbooks correlate on the same host in sequence (e.g., scan → credential capture → beaconing) — treat this as a single incident.

---

*Filter/tshark syntax: [`wireshark-advanced-cheatsheet.md`](wireshark-advanced-cheatsheet.md). Category reference: [`attack-types-detection-cheatsheet-professional.md`](attack-types-detection-cheatsheet-professional.md). Host-side follow-up: [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md).*
