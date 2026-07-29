# eJPT Curriculum → Penetration Testing Lifecycle

Every room/module, mapped to the lifecycle phase(s) it trains, with the actual attack-chain walkthrough spelled out step by step.

## Lifecycle Phases

| # | Phase |
|---|-------|
| 01 | Information Gathering |
| 02 | Scanning & Enumeration |
| 03 | Vulnerability Assessment |
| 04 | Exploitation |
| 05 | Post-Exploitation |
| 06 | Reporting |

---

## Progress Tracker

**0 / 25 rooms completed** — check a box as you finish a room, and update the count above.

- [ ] Hydra
- [ ] Crack the Hash
- [ ] Brute It
- [ ] Basic Pentesting
- [ ] Poster
- [ ] Simple CTF
- [ ] DC-1
- [ ] Lazyadmin
- [ ] WordPress CVE-2021-29447
- [ ] Blog
- [ ] Startup
- [ ] Anthem
- [ ] Blue
- [ ] Retro
- [ ] Blaster
- [ ] RootMe
- [ ] Ignite
- [ ] Chill Hack
- [ ] Colddbox: Easy
- [ ] Source
- [ ] Internal
- [ ] Wonderland
- [ ] GamingServer
- [ ] GoldenEye
- [ ] Brooklyn Nine Nine

---

## 1. Password Attacks & Hash Cracking — 5 rooms

### [Hydra](https://tryhackme.com/room/hydra)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

Nmap reveals which login services are open, then Hydra is run once per protocol — `ssh`, `ftp`, `http-post-form`, `smb`, `rdp` — each with its own module syntax, wordlist, and (for the web form) the correct field names. The point isn't memorizing one command, it's understanding how each module's parameters map to the protocol.

### [Crack the Hash](https://tryhackme.com/room/crackthehash)
![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

A set of raw hashes is given. Hash-Identifier or Name-That-Hash is used to guess the algorithm (MD5, SHA1, NTLM, bcrypt...), then the matching Hashcat mode number or John format is chosen and run against rockyou.txt until it cracks.

### [Brute It](https://tryhackme.com/room/bruteit)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

A web login form is brute-forced (Hydra/Burp), directory brute-forcing (gobuster) surfaces hidden pages, the recovered credentials get you into the app/system, and finally a SUID-permission binary is used to escalate to root.

### [Basic Pentesting](https://tryhackme.com/room/basicpentestingjt)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

Nmap maps the open services, SMB enumeration pulls a valid username list, Hydra brute-forces SSH/SMB with that list, and any recovered hash gets cracked with John the Ripper to get a working password.

### [Poster](https://tryhackme.com/room/poster)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

A PostgreSQL instance accepts default/weak credentials; once inside, data pointing to SMB shares and further credentials is leaked out of the database and used to move onto the host.

---

## 2. Web Vulnerabilities & CMS Security — 6 rooms

### [Simple CTF](https://tryhackme.com/room/easyctf)
![Vuln. Assessment](https://img.shields.io/badge/-Vuln.%20Assessment-a78bfa) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

Anonymous FTP hands over files, CMS Made Simple's known vulnerability (SQLi leaking an admin password hash) is exploited, the hash is cracked, you log in as admin, and a simple technique escalates to root from there.

### [DC-1](https://www.vulnhub.com/entry/dc-1-1,292/) <sub>(VulnHub, not a native THM room)</sub>
![Vuln. Assessment](https://img.shields.io/badge/-Vuln.%20Assessment-a78bfa) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

Web recon fingerprints the Drupal version, the Drupalgeddon vulnerability is exploited via its Metasploit module for an initial shell, and from there the database is reached directly to reset the admin password for full control.

### [Lazyadmin](https://tryhackme.com/room/lazyadmin)
![Vuln. Assessment](https://img.shields.io/badge/-Vuln.%20Assessment-a78bfa) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

Directory brute-forcing uncovers a SweetRice CMS install, a known file-upload flaw gets you a web shell, and sudo -l reveals a binary that GTFOBins turns into a root shell.

### [WordPress CVE-2021-29447](https://tryhackme.com/room/wordpresscve202129447)
![Vuln. Assessment](https://img.shields.io/badge/-Vuln.%20Assessment-a78bfa) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

A vulnerable WordPress media-library component is abused to trigger an XXE (XML External Entity) injection, which is then used to read arbitrary files off the server.

### [Blog](https://tryhackme.com/room/blog)
![Vuln. Assessment](https://img.shields.io/badge/-Vuln.%20Assessment-a78bfa) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

WPScan fingerprints the WordPress version and installed plugins, a matching public CVE is identified, and its exploit (manual or Metasploit) is run to land a shell.

### [Startup](https://tryhackme.com/room/startup)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

Gobuster/FFUF finds hidden directories, a file-upload flaw lets you drop a web shell, and once inside you notice a cron job running a writable script — editing that script gets you root on its next run.

---

## 3. Windows & Active Directory / RDP Recon — 4 rooms

### [Anthem](https://tryhackme.com/room/anthem)
![Info Gathering](https://img.shields.io/badge/-Info%20Gathering-4d9de0) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

SMB shares and exposed web directories on the Windows box are enumerated, credentials are found sitting in source code or a config file that was left behind, and those credentials are used to log in directly over RDP.

### [Blue](https://tryhackme.com/room/blue)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

The Nmap NSE script smb-vuln-ms17-010 confirms the box is vulnerable to EternalBlue; Metasploit's matching exploit module is fired to land a SYSTEM-level Meterpreter session directly.

### [Retro](https://tryhackme.com/room/retro)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

An open RDP port is found, initial access comes from a web-facing CVE or a weak password on a discovered account, and a Windows-specific privesc technique is then used to reach SYSTEM.

### [Blaster](https://tryhackme.com/room/blaster)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

Initial access comes from a Windows RCE vulnerability or RDP brute-force; once in, the AlwaysInstallElevated policy is found enabled, letting a crafted malicious MSI install with SYSTEM privileges.

---

## 4. Linux Privilege Escalation — 6 rooms

### [RootMe](https://tryhackme.com/room/rrootme)
![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

`find / -perm -4000` turns up a SUID-permission binary; GTFOBins shows exactly how that binary can be abused to spawn a root shell.

### [Ignite](https://tryhackme.com/room/ignite)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

A known Fuel CMS remote code execution vulnerability gets an initial shell, and a plaintext password sitting in a config file is then used to pivot into a more privileged account (or straight to root).

### [Chill Hack](https://tryhackme.com/room/chillhack)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

A command injection flaw in the web app gives the first shell; `sudo -l` then shows a Python script the user is allowed to run as another user, and abusing that script's logic (e.g. hijacking an imported module) escalates to root.

### [Colddbox: Easy](https://tryhackme.com/room/colddboxeasy)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

WPScan finds a valid username, Hydra brute-forces the WordPress login with it, the theme/plugin editor is used to get code execution, and a SUID misconfiguration on the box is then used to reach root.

### [Source](https://tryhackme.com/room/source)
![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

The Webmin panel's version is fingerprinted, and CVE-2019-15107 — a command injection in its password-reset form — is exploited to run commands directly as root, no separate privesc step needed.

### [Internal](https://tryhackme.com/room/internal)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

From the first compromised host, the internal network is enumerated to find other reachable hosts, and configuration files or notes on that host are searched for reusable passwords — this room is explicitly built as pivoting/lateral-movement prep.

---

## 5. Advanced Logic & Mixed Scenarios — 4 rooms

### [Wonderland](https://tryhackme.com/room/wonderland)
![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

A writable directory is found earlier in the PATH than the legitimate binaries; a malicious script/module dropped there hijacks something the system runs, which is then chained across multiple user accounts (privilege chaining) until a cron job run as root finishes the escalation.

### [GamingServer](https://tryhackme.com/room/gamingserver)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

Web directory brute-forcing turns up a hidden page that leaks an SSH private key; logging in with it, the user turns out to belong to the lxd/docker group, which is abused to mount a privileged container and reach the host's root filesystem.

### [GoldenEye](https://tryhackme.com/room/goldeneye)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Exploitation](https://img.shields.io/badge/-Exploitation-f4845f)

Nmap uncovers POP3/SMTP services, mailboxes are read over those protocols to collect leaked credentials, and those credentials get you into a web admin panel where a further vulnerability yields a shell.

### [Brooklyn Nine Nine](https://tryhackme.com/room/brooklynninenine)
![Enumeration](https://img.shields.io/badge/-Enumeration-2ec4b6) ![Post-Exploitation](https://img.shields.io/badge/-Post--Exploitation-e8544e)

Files pulled from anonymous FTP provide the material for a Hydra brute-force against SSH; once logged in, a simple misconfiguration (SUID or sudo) is enough to escalate to root.

---

## Suggested Study Order

1. **Tool fluency** — Hydra → Crack the Hash → Basic Pentesting → Brute It
2. **Entry-level boot2root** — Simple CTF → Blue → RootMe → Lazyadmin
3. **CMS & web exploitation** — DC-1 (Drupal) → Blog → WordPress CVE-2021-29447 → Ignite → Colddbox: Easy
4. **Windows-focused** — Anthem → Retro → Blaster → Poster
5. **Intermediate / mixed** — Startup → Chill Hack → Internal → Wonderland → GamingServer → GoldenEye

---

*eJPT prep reference — built to be revisited throughout study.*
