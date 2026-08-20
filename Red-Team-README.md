# Red Team Cheat Sheets
## 🧰 Interactive Tools (open live, don't click the raw file)

| Tool | Live Preview |
|---|---|
| ejpt-study-notes.html | [Open live ↗](https://htmlpreview.github.io/?https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/blob/cybersecurity-learning-hub/Red-Team/ejpt-study-notes.html) |
| ejpt-study-reference.html | [Open live ↗](https://htmlpreview.github.io/?https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/blob/cybersecurity-learning-hub/Red-Team/ejpt-study-reference.html) |

Offensive-side reference material, prepared primarily around the **eJPT** (eLearnSecurity Junior Penetration Tester) exam objectives — recon, enumeration, exploitation, post-exploitation, and reporting. Organized by phase, matching the Penetration Testing Lifecycle.

---

## 📁 01-Recon-and-OSINT

| File | Covers |
|---|---|
| [assessment-methodology-report-writing-cheatsheet-professional.md](01-Recon-and-OSINT/assessment-methodology-report-writing-cheatsheet-professional.md) | PTES phases, scoping/RoE, finding write-ups, report skeleton — shared reference for both eJPT and BTL1 reporting |
| [penetration-testing-methodology-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/penetration-testing-methodology-cheatsheet-professional.md) | Assessment types, box models, framework overview — read this one first |
| [attack-types-identification-cheatsheet-professional.md](01-Recon-and-OSINT/attack-types-identification-cheatsheet-professional.md) | How to read recon output and decide which attack category applies — network, web, auth, AD, malware, social engineering, DoS, wireless, cloud |
| [osint-cheatsheet.md](01-Recon-and-OSINT/osint-cheatsheet.md) | Passive recon — domain/DNS, dorking, email/username enumeration, social media, metadata, infrastructure lookup tools |
| [vulnerability-assessment-cheatsheet-professional.md](01-Recon-and-OSINT/vulnerability-assessment-cheatsheet-professional.md) | VA workflow, Nessus/OpenVAS/Nikto, CVSS v3 scoring, false-positive triage |
| [host-network-auditing-fundamentals-cheatsheet-professional.md](01-Recon-and-OSINT/host-network-auditing-fundamentals-cheatsheet-professional.md) | Baseline security auditing — CIS Benchmarks, Windows/Linux config checks, network baseline review |
| [web-http-protocol-fundamentals-cheatsheet-professional.md](01-Recon-and-OSINT/web-http-protocol-fundamentals-cheatsheet-professional.md) | HTTP request/response anatomy, methods, headers, status codes, cookies, TLS basics |
| [ejpt-exam-checklist-and-methodology.md](01-Recon-and-OSINT/ejpt-exam-checklist-and-methodology.md) | Exam-day checklist — per-host methodology loop, time management, pitfalls, submission checklist |

## 📁 02-Web-and-Network-Pentesting

| File | Covers |
|---|---|
| [nmap-cheatsheet-professional.md](02-Web-and-Network-Pentesting/nmap-cheatsheet-professional.md) | Scan types, targeting, timing, NSE, evasion — the first tool run on every engagement |
| [gobuster-cheatsheet-professional.md](02-Web-and-Network-Pentesting/gobuster-cheatsheet-professional.md) | Directory/DNS/vhost brute-forcing |
| [dirb-cheatsheet-professional.md](02-Web-and-Network-Pentesting/dirb-cheatsheet-professional.md) | Web content brute-forcing with dirb |
| [web-enumeration-common-vulns-cheatsheet-professional.md](02-Web-and-Network-Pentesting/web-enumeration-common-vulns-cheatsheet-professional.md) | LFI/RFI, XSS, SSRF, command injection, file upload, IDOR |
| [burp-suite-cheatsheet-professional.md](02-Web-and-Network-Pentesting/burp-suite-cheatsheet-professional.md) | Proxy/Repeater/Intruder workflow for manual web testing |
| [sqlmap-cheatsheet-professional.md](02-Web-and-Network-Pentesting/sqlmap-cheatsheet-professional.md) | Automated SQL injection detection and exploitation |
| [network-based-attacks-cheatsheet-professional.md](02-Web-and-Network-Pentesting/network-based-attacks-cheatsheet-professional.md) | ARP spoofing, MITM, Responder/LLMNR-NBTNS poisoning, VLAN hopping, DHCP starvation |
| [smb-windows-enumeration-cheatsheet-professional.md](02-Web-and-Network-Pentesting/smb-windows-enumeration-cheatsheet-professional.md) | SMB/Windows host enumeration |

## 📁 03-Exploitation-and-Post-Exploitation

| File | Covers |
|---|---|
| [active-directory-enumeration-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/active-directory-enumeration-cheatsheet-professional.md) | AD enumeration & attacks (BloodHound, Kerberoasting, etc.) |
| [active-directory-attack-chain-playbook.md](03-Exploitation-and-Post-Exploitation/active-directory-attack-chain-playbook.md) | Scenario walkthrough of a full AD attack chain — foothold → Kerberoasting/AS-REP Roasting → lateral movement → DCSync/Golden Ticket → Domain Admin |
| [crackmapexec-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/crackmapexec-cheatsheet-professional.md) | SMB/AD enumeration + credential testing + execution in one tool |
| [hydra-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/hydra-cheatsheet-professional.md) | Online/network service brute-forcing |
| [john-the-ripper-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/john-the-ripper-cheatsheet-professional.md) | Offline hash cracking (CPU-focused) |
| [hashcat-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/hashcat-cheatsheet-professional.md) | Offline hash cracking (GPU-accelerated), hash-mode reference |
| [exploitation-techniques-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/exploitation-techniques-cheatsheet-professional.md) | Manual exploitation — searchsploit, adapting/compiling public exploits, exploit reliability triage |
| [metasploit-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/metasploit-cheatsheet-professional.md) | Framework basics, module usage, Meterpreter, msfvenom |
| [netcat-reverse-shell-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/netcat-reverse-shell-cheatsheet-professional.md) | Catching/stabilizing shells, file transfer, pivoting |
| [linux-windows-pentest-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/linux-windows-pentest-cheatsheet-professional.md) | Host-level privilege escalation on Linux & Windows |
| [privilege-escalation-linux-windows-cheatsheet.md](03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md) | Deep-dive privesc checklist — SUID/GTFOBins, sudo, cron, kernel exploits (Linux); AlwaysInstallElevated, unquoted paths, token impersonation (Windows) |
| [command-line-obfuscation-evasion-cheatsheet.md](03-Exploitation-and-Post-Exploitation/command-line-obfuscation-evasion-cheatsheet.md) | PowerShell/Bash obfuscation, LOLBins, AMSI bypass context — plus a detection cross-reference |
| [post-exploitation-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/post-exploitation-cheatsheet-professional.md) | Situational awareness, loot/credential collection, persistence, pivoting, cleanup |
| [social-engineering-set-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/social-engineering-set-cheatsheet-professional.md) | Social-Engineer Toolkit (SET), pretexting |
| [ai-enhanced-pentesting-cheatsheet-professional.md](03-Exploitation-and-Post-Exploitation/ai-enhanced-pentesting-cheatsheet-professional.md) | Practical, risk-aware use of generative AI across the pentest workflow |

---

> `ejpt-roadmap.md` (repo root) is a study roadmap rather than a technical cheat sheet — left as-is, not duplicated here.

*All techniques should only be used within written authorization (scope/RoE).*
