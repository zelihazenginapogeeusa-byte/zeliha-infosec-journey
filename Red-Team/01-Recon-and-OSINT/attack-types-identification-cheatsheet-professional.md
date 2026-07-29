# Attack Types — Offensive Identification Cheat Sheet

How to look at recon output and decide **which category of attack actually applies** to a target — the decision layer that sits between "I scanned the box" and "I picked the right technique."

> All techniques below are for use in **authorized environments only** — personal labs, CTFs, and engagements covered by written authorization (RoE).

---

## 1. How to Think About This

Every attack type has a **signal** that tells you it's on the table. Recon isn't just "what's open" — it's "which attack categories does this open up." Work through the categories below in order; most real engagements chain 2–3 of them together (e.g., web app → credentials → AD → privesc).

---

## 2. Network-Based Attacks

| Signal you'll see in recon | Attack type it points to | Go-to tools |
|---|---|---|
| Same broadcast domain / VLAN access | ARP spoofing, MITM | `arpspoof`, `bettercap`, `ettercap` |
| LLMNR/NBT-NS enabled (common on Windows networks) | Responder-style credential capture | `Responder`, `Inveigh` |
| No 802.1X / open switch ports | VLAN hopping, rogue device | `yersinia`, manual trunk negotiation |
| DHCP server reachable, no snooping | DHCP starvation / rogue DHCP | `Yersinia`, `dhcpstarv` |
| Unencrypted protocols in traffic capture (FTP, Telnet, HTTP, SNMP v1/2c) | Credential sniffing | `Wireshark`, `tcpdump`, `net-creds` |

**Tell:** you're on the same L2 segment as the target, or traffic is traversing a switch you can influence.

---

## 3. Web Application Attacks

| Signal | Attack type | Go-to tools |
|---|---|---|
| User input reflected in response without encoding | Reflected/Stored XSS | Burp Repeater, manual payloads |
| Input concatenated into a DB query (error messages, odd behavior on `'`) | SQL Injection | `sqlmap`, Burp |
| App fetches a URL you can influence (webhooks, "import from URL") | SSRF | Burp Collaborator, manual |
| XML input accepted (SOAP, some upload flows) | XXE | Burp, manual DTD payloads |
| File upload with weak extension/type validation | Malicious file upload → RCE | Burp, manual |
| Shell metacharacters reach a system call | Command Injection | manual, `commix` |
| Predictable object references in URLs/params (`?id=101`) | IDOR | Burp, manual enumeration |
| Old CMS/plugin version fingerprinted | Known-CVE exploitation | `wpscan`, `searchsploit`, Metasploit |

**Tell:** the target exposes a web app with user-controllable input — this is almost always the first thing to rule in/out.

---

## 4. Authentication Attacks

| Signal | Attack type | Go-to tools |
|---|---|---|
| Login form / SSH / RDP / SMB with no lockout policy | Brute-force | `Hydra`, `medusa` |
| Known breach-list overlap likely (reused corporate emails) | Credential stuffing | `Hydra` w/ combo lists |
| One password sprayed across many accounts to dodge lockouts | Password spraying | `kerbrute`, `CrackMapExec` |
| Captured hash (NTLM, Kerberos ticket, `/etc/shadow`) | Offline cracking | `hashcat`, `John the Ripper` |
| SMB/AD reachable with valid creds | Pass-the-hash / pass-the-ticket | `CrackMapExec`, `Impacket` |

**Tell:** you have a login surface or a captured credential artifact (hash, ticket) and need to turn it into access.

---

## 5. Active Directory / Windows Domain Attacks

| Signal | Attack type | Go-to tools |
|---|---|---|
| Domain-joined host, valid low-priv creds | AD enumeration | `BloodHound`, `PowerView`, `CrackMapExec` |
| Service account with SPN set | Kerberoasting | `Rubeus`, `GetUserSPNs.py` (Impacket) |
| Account with no Kerberos pre-auth required | AS-REP Roasting | `GetNPUsers.py` (Impacket) |
| Misconfigured ACLs found via BloodHound | ACL abuse (e.g., GenericAll, WriteDACL) | `BloodHound`, `Impacket` |
| Unconstrained/constrained delegation enabled | Delegation abuse | `Rubeus`, `Impacket` |

**Tell:** you're inside a Windows domain with at least one set of valid (even low-privilege) credentials.

---

## 6. Malware-Delivery Style Attacks

| Signal | Attack type | Go-to tools |
|---|---|---|
| Client-side execution needed (no direct network path) | Phishing payload delivery | `msfvenom`, custom macros/HTA |
| AV/EDR present on target | Payload obfuscation / evasion needed | `Veil`, manual encoding, LOLBins |
| Persistence required across reboots | Backdoor/implant placement | scheduled tasks, registry run keys, cron |

**Tell:** direct remote exploitation isn't viable and you need the user (or a scheduled process) to execute something for you.

---

## 7. Social Engineering

| Signal | Attack type | Go-to approach |
|---|---|---|
| Employee emails/org chart discoverable (OSINT) | Phishing / spear-phishing | `SET`, GoPhish, crafted pretext |
| Physical access in scope | Tailgating, badge cloning, USB drop | Physical engagement rules apply |
| Help desk / support line in scope | Vishing / pretexting | Scripted pretext calls |

**Tell:** the human is the weakest link in scope, and technical controls alone won't get you in.

---

## 8. Denial of Service

| Signal | Attack type | Note |
|---|---|---|
| Resource-intensive endpoint (search, PDF export, regex input) | Application-layer DoS | Almost always **out of scope** on live/prod systems — confirm RoE explicitly |
| No rate limiting on auth endpoints | Account lockout DoS | Same caveat |

**Tell:** DoS is rarely authorized outside dedicated test environments — treat any DoS-shaped finding as a reporting item unless RoE explicitly permits testing it live.

---

## 9. Wireless

| Signal | Attack type | Go-to tools |
|---|---|---|
| WPA2-PSK network in scope | Handshake capture + offline crack | `aircrack-ng`, `hashcat` |
| WPS enabled | WPS PIN attack | `reaver`, `bully` |
| Open/guest SSID reachable | Rogue AP / evil twin | `airbase-ng`, `hostapd-wpe` |

---

## 10. Cloud / Misconfiguration

| Signal | Attack type | Go-to tools |
|---|---|---|
| S3 bucket / blob storage referenced in app | Public bucket exposure | `aws s3 ls` (unauthenticated), `cloud_enum` |
| IAM role attached to a compromised EC2/VM | Metadata service abuse → credential theft | `curl 169.254.169.254`, `pacu` |
| Overly permissive IAM policy discovered | Privilege escalation in cloud | `pacu`, `ScoutSuite` |

---

## 11. Quick Decision Flow

1. **What surface is exposed?** (network / web / auth / domain / human / wireless / cloud) — pick the matching section above.
2. **What artifact do I already have?** (a shell, a hash, a set of creds, a ticket) — that determines whether you're still in initial access or already in post-exploitation territory.
3. **What does the RoE actually permit?** — DoS, physical, and social engineering categories are frequently excluded; always confirm before acting.

---

*Companion to [`attack-types-detection-cheatsheet-professional.md`](../Blue-Team/attack-types-detection-cheatsheet-professional.md) in Blue-Team — same categories, viewed from the defender's side.*

*Prepared for eJPT-aligned offensive work. Use only in authorized environments.*
