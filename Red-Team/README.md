# Red Team Cheat Sheets

Offensive-side reference material, prepared primarily around the **eJPT** (eLearnSecurity Junior Penetration Tester) exam objectives — recon, enumeration, exploitation, post-exploitation, and reporting.

| File | Covers |
|---|---|
| [penetration-testing-methodology-cheatsheet-professional.md](penetration-testing-methodology-cheatsheet-professional.md) | Assessment types, box models, framework overview — read this one first |
| [osint-cheatsheet.md](osint-cheatsheet.md) | Passive recon — domain/DNS, dorking, email/username enumeration, social media, metadata, infrastructure lookup tools |
| [nmap-cheatsheet-professional.md](nmap-cheatsheet-professional.md) | Scan types, targeting, timing, NSE, evasion — the first tool run on every engagement |
| [vulnerability-assessment-cheatsheet-professional.md](vulnerability-assessment-cheatsheet-professional.md) | VA workflow, Nessus/OpenVAS/Nikto, CVSS v3 scoring, false-positive triage |
| [host-network-auditing-fundamentals-cheatsheet-professional.md](host-network-auditing-fundamentals-cheatsheet-professional.md) | Baseline security auditing — CIS Benchmarks, Windows/Linux config checks, network baseline review |
| [gobuster-cheatsheet-professional.md](gobuster-cheatsheet-professional.md) | Directory/DNS/vhost brute-forcing |
| [dirb-cheatsheet-professional.md](dirb-cheatsheet-professional.md) | Web content brute-forcing with dirb |
| [web-http-protocol-fundamentals-cheatsheet-professional.md](web-http-protocol-fundamentals-cheatsheet-professional.md) | HTTP request/response anatomy, methods, headers, status codes, cookies, TLS basics |
| [web-enumeration-common-vulns-cheatsheet-professional.md](web-enumeration-common-vulns-cheatsheet-professional.md) | LFI/RFI, XSS, SSRF, command injection, file upload, IDOR |
| [burp-suite-cheatsheet-professional.md](burp-suite-cheatsheet-professional.md) | Proxy/Repeater/Intruder workflow for manual web testing |
| [sqlmap-cheatsheet-professional.md](sqlmap-cheatsheet-professional.md) | Automated SQL injection detection and exploitation |
| [network-based-attacks-cheatsheet-professional.md](network-based-attacks-cheatsheet-professional.md) | ARP spoofing, MITM, Responder/LLMNR-NBTNS poisoning, VLAN hopping, DHCP starvation |
| [active-directory-enumeration-cheatsheet-professional.md](active-directory-enumeration-cheatsheet-professional.md) | AD enumeration & attacks (BloodHound, Kerberoasting, etc.) |
| [smb-windows-enumeration-cheatsheet-professional.md](smb-windows-enumeration-cheatsheet-professional.md) | SMB/Windows host enumeration |
| [crackmapexec-cheatsheet-professional.md](crackmapexec-cheatsheet-professional.md) | SMB/AD enumeration + credential testing + execution in one tool |
| [hydra-cheatsheet-professional.md](hydra-cheatsheet-professional.md) | Online/network service brute-forcing |
| [john-the-ripper-cheatsheet-professional.md](john-the-ripper-cheatsheet-professional.md) | Offline hash cracking (CPU-focused) |
| [hashcat-cheatsheet-professional.md](hashcat-cheatsheet-professional.md) | Offline hash cracking (GPU-accelerated), hash-mode reference |
| [exploitation-techniques-cheatsheet-professional.md](exploitation-techniques-cheatsheet-professional.md) | Manual exploitation — searchsploit, adapting/compiling public exploits, exploit reliability triage |
| [metasploit-cheatsheet-professional.md](metasploit-cheatsheet-professional.md) | Framework basics, module usage, Meterpreter, msfvenom |
| [netcat-reverse-shell-cheatsheet-professional.md](netcat-reverse-shell-cheatsheet-professional.md) | Catching/stabilizing shells, file transfer, pivoting |
| [linux-windows-pentest-cheatsheet-professional.md](linux-windows-pentest-cheatsheet-professional.md) | Host-level privilege escalation on Linux & Windows |
| [post-exploitation-cheatsheet-professional.md](post-exploitation-cheatsheet-professional.md) | Situational awareness, loot/credential collection, persistence, pivoting, cleanup |
| [social-engineering-set-cheatsheet-professional.md](social-engineering-set-cheatsheet-professional.md) | Social-Engineer Toolkit (SET), pretexting |
| [ai-enhanced-pentesting-cheatsheet-professional.md](ai-enhanced-pentesting-cheatsheet-professional.md) | Practical, risk-aware use of generative AI across the pentest workflow |

> `assessment-methodology-report-writing-cheatsheet-professional.md` is shared between red and blue team work and lives one level up, in the repo root.
>
> `ejpt-roadmap.md` (already in the repo root) is a study roadmap rather than a technical cheat sheet — left as-is, not duplicated here.

*All techniques should only be used within written authorization (scope/RoE).*
