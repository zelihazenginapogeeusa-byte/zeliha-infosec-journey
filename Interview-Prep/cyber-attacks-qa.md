# SOC Analyst Interview Prep — Cyber Attacks

A study guide of the cyber-attack concepts most commonly asked about in SOC Analyst (L1/L2) interviews: what each attack is, how it works, how it's typically detected from a SOC seat, and how it's mitigated. Organized by category so you can review in blocks rather than as a flat Q&A list.

> Use this alongside a hands-on lab (packet captures, a SIEM, a vulnerable app like DVWA/Juice Shop) — recognizing these patterns in real logs is what actually gets tested in interviews and on the job.

---

## Table of Contents

1. [Core Concepts](#1-core-concepts)
2. [Credential & Password Attacks](#2-credential--password-attacks)
3. [Network & Reconnaissance Attacks](#3-network--reconnaissance-attacks)
4. [Social Engineering Attacks](#4-social-engineering-attacks)
5. [Malware](#5-malware)
6. [Web Application Attacks (OWASP)](#6-web-application-attacks-owasp)
7. [Quick Reference Table](#7-quick-reference-table)

---

## 🧩 1. Core Concepts


<details>
<summary><b>❓ What are TTPs?</b></summary>

**TTPs** — Tactics, Techniques, and Procedures — describe *how* a threat actor operates: the high-level goal (Tactic, e.g. Initial Access), the general method used to achieve it (Technique, e.g. Phishing), and the specific implementation a particular group uses (Procedure, e.g. a specific phishing kit and payload). TTPs are the backbone of frameworks like MITRE ATT&CK, and SOC teams use them to write detections that catch a *pattern of behavior* rather than a single indicator (which attackers can trivially change).

</details>

<details>
<summary><b>❓ What is the difference between an Exploit and a Payload?</b></summary>

- **Exploit** — the tool or code that takes advantage of a specific vulnerability to gain execution or access. Example: EternalBlue, which abused a flaw in the SMBv1 protocol.
- **Payload** — the actual malicious code that runs *after* the exploit succeeds — the part that does the damage (encrypting files, exfiltrating data, opening a backdoor, taking screenshots, etc.).

A useful way to remember it: the exploit gets you through the door, the payload is what you do once you're inside. WannaCry is the classic example — it used EternalBlue as its exploit and carried a ransomware payload that encrypted files and demanded payment.

</details>

---


## 🔑 2. Credential & Password Attacks


<details>
<summary><b>❓ Brute-Force Attack</b></summary>

A brute-force attack systematically tries many username/password combinations until one succeeds. It doesn't rely on any prior knowledge of the target — just persistence and computing power.

**SOC detection:** repeated authentication failures (Windows Event ID 4625, SSH `Failed password`, web app 401/403 responses) from a single source against one or more accounts in a short window.

**Mitigation:** account lockout after N failed attempts, CAPTCHA, rate limiting, and — most importantly — multi-factor authentication (MFA), which neutralizes a guessed password on its own.

</details>

<details>
<summary><b>❓ Dictionary Attack</b></summary>

A dictionary attack is a *targeted* form of brute-force: instead of trying every possible combination, it tries words from a wordlist (a dictionary, leaked password list, or a custom list built from the target's personal details — birthdate, pet's name, license plate, etc.). It's far faster than pure brute-force because it exploits the fact that most people choose predictable passwords.

**Mitigation:** same as brute-force, plus banning common/breached passwords at password-creation time (checking against a list like Have I Been Pwned's Pwned Passwords).

</details>

<details>
<summary><b>❓ Rainbow Table Attack</b></summary>

Rather than guessing plaintext passwords, a rainbow table attack works against *stolen password hashes*. The attacker precomputes hashes for large sets of possible passwords and looks up the stolen hash in that precomputed table instead of hashing candidate after candidate on the fly — trading storage for speed.

**Mitigation:** salting — appending random, unique data to each password before hashing so identical passwords never produce identical hashes, which makes precomputed tables useless. Modern adaptive hash functions (bcrypt, scrypt, Argon2) build salting in by default.

</details>

<details>
<summary><b>❓ Pass-the-Hash (PtH)</b></summary>

Pass-the-hash lets an attacker authenticate to a remote system using a stolen password *hash* directly, without ever cracking it back to plaintext. It's common in Windows/Active Directory environments where NTLM hashes can be reused for authentication.

**SOC detection:** authentication events where the logon type or protocol looks like NTLM being used unusually (e.g., a service account authenticating interactively from an unexpected host), or the same credential hash being used for lateral movement across many hosts in a short time.

**Mitigation:** restrict and tier privileged accounts (don't let domain admin credentials touch lower-trust machines), enforce local admin account restrictions, and use Windows Firewall to block unnecessary inbound lateral-movement paths between workstations.

</details>

---


## 🌐 3. Network & Reconnaissance Attacks


<details>
<summary><b>❓ Scanning</b></summary>

Scanning is the reconnaissance phase where an attacker probes a target to discover live hosts, open ports, running services, and known vulnerabilities — building a map of what's reachable and exploitable before launching an actual attack.

**SOC detection:** a single source IP touching many destination ports/hosts in a short time; IDS/IPS signatures for common scanners (Nmap, Masscan).

**Mitigation:** firewalls and IPS to restrict exposed surface, OS/service hardening, and honeypots to catch and flag scanning activity early.

</details>

<details>
<summary><b>❓ Sniffing</b></summary>

Sniffing is the interception of network traffic as it moves across a network — usually with a packet capture tool (Wireshark, tcpdump) — to steal data like credentials or session tokens travelling in the clear.

**Mitigation:** eliminate unencrypted protocols (HTTP, FTP, Telnet) in favor of their encrypted equivalents (HTTPS, SFTP, SSH), and encrypt data in transit wherever possible so captured traffic is useless without the key.

</details>

<details>
<summary><b>❓ Spoofing</b></summary>

Spoofing covers a family of techniques where an attacker fakes an identifier (an address, a domain, a sender) to make something appear trustworthy when it isn't.

| Type | What's faked | Primary mitigation |
|---|---|---|
| IP Spoofing | Source IP address | IPS / anti-spoofing filtering |
| MAC Address Spoofing | Device MAC address | Port-level security (802.1X) |
| Email Spoofing | "From" sender address | User education, SPF/DKIM/DMARC |
| DNS Spoofing | DNS responses | See DNS Poisoning below |

</details>

<details>
<summary><b>❓ ARP Poisoning (ARP Spoofing)</b></summary>

The attacker sends forged ARP messages on a local network to associate their own MAC address with the IP address of a legitimate host (often the default gateway). Once victim traffic is (mis)directed through the attacker's machine, it can be intercepted, modified, or dropped — the classic setup for a Man-in-the-Middle attack on a LAN.

**Mitigation:** static ARP entries for critical hosts, ARP-poisoning detection tools (e.g., XArp), packet filtering, and up-to-date endpoint protection.

</details>

<details>
<summary><b>❓ Man-in-the-Middle (MITM)</b></summary>

A MITM attack is when an attacker secretly sits between two communicating parties — relaying, and potentially altering, the traffic — while both sides believe they're talking directly to each other. ARP poisoning is one common way to set this up on a local network; a rogue Wi-Fi access point is another.

**Mitigation:** static ARP where feasible, strong end-to-end encryption (so intercepted traffic is unreadable), and IPS systems tuned to flag anomalous shifts in network performance/latency that can indicate traffic is being relayed.

</details>

<details>
<summary><b>❓ DNS Poisoning (DNS Spoofing)</b></summary>

DNS poisoning corrupts the data held in a DNS resolver's cache so that lookups for a legitimate domain return an attacker-controlled IP address instead — silently redirecting users to a fake site (often for credential phishing) even though they typed the correct URL.

**Mitigation:** regularly audit DNS zones, keep DNS server software patched, restrict zone transfers to trusted secondaries, limit recursive queries to trusted clients, and only cache data relevant to the requested domain (to prevent cache-poisoning side channels).

</details>

<details>
<summary><b>❓ DNS Tunneling</b></summary>

DNS tunneling encodes non-DNS data (arbitrary commands or exfiltrated data) inside DNS queries and responses. Because DNS traffic is almost always allowed through firewalls by default, it's an effective way to smuggle data out of a network without tripping typical outbound-traffic controls.

**SOC detection:** unusually long or high-entropy DNS query names, abnormally high query volume to a single domain, or DNS queries to domains with no legitimate business reason to be contacted.

**Mitigation:** IPS signatures tuned for tunneling patterns, DNS firewalls, blocking known exfiltration-associated domains/IPs, and dedicated DNS security platforms.

</details>

<details>
<summary><b>❓ Denial-of-Service (DoS) and Distributed Denial-of-Service (DDoS)</b></summary>

- **DoS** — a single source attempts to make a service or resource unavailable to legitimate users, typically by exhausting a resource (bandwidth, memory, connection table). Common forms: UDP floods, ICMP floods, SYN floods, fragmented packet attacks, Ping of Death.
- **DDoS** — the same goal, but the flood is launched from *many* sources simultaneously — usually a botnet of previously compromised machines — making it both larger in scale and harder to block by simply denying one IP.

**Mitigation:** dedicated anti-DDoS/scrubbing services (e.g., Arbor-class solutions), rate limiting per source, tighter connection timeouts, and load balancing across capacity.

</details>

<details>
<summary><b>❓ SYN Flood</b></summary>

A SYN flood is a specific DoS technique that abuses the TCP three-way handshake: the attacker sends a large volume of SYN (connection request) packets but never completes the handshake with the final ACK. The target server holds each half-open connection in memory waiting for a timeout, and enough of these exhaust the server's connection table — locking out legitimate users.

**Mitigation:** same DoS/DDoS toolkit above — SYN cookies, rate limiting, reduced connection wait times, load balancers, and anti-DDoS appliances.

</details>

---


## 🎭 4. Social Engineering Attacks


<details>
<summary><b>❓ Phishing</b></summary>

Phishing is a cyberattack that uses a disguised message — almost always email — as its weapon. The goal is to make the recipient believe the message is something they want or need (a bank notice, an internal company request), and to get them to click a malicious link or open a malicious attachment.

**Mitigation:** email security gateways to filter obvious phishing/spam, ongoing user education/simulated phishing training, and DMARC (Domain-based Message Authentication, Reporting and Conformance) so receiving mail servers can verify whether a message really came from an authorized sender.

</details>

<details>
<summary><b>❓ Spear Phishing</b></summary>

Spear phishing is phishing narrowed to a specific individual, team, or organization. The attacker uses reconnaissance (OSINT, social media, prior breaches) to personalize the message — a real name, a real project, a real vendor relationship — which makes it far more convincing than a generic phishing blast.

</details>

<details>
<summary><b>❓ Whaling</b></summary>

Whaling is spear phishing aimed specifically at senior leadership — executives, finance officers, board members — because a successful compromise or a convincing fraudulent request (e.g., a fake wire-transfer instruction from the "CEO") carries outsized impact.

</details>

<details>
<summary><b>❓ Vishing</b></summary>

Vishing ("voice phishing") applies the same social-engineering playbook over a phone call instead of email — the attacker impersonates a trusted party (IT support, a bank, a vendor) to talk the target into handing over sensitive information directly.

</details>

---


## 🦠 5. Malware


<details>
<summary><b>❓ What Is Malware?</b></summary>

Malware is software intentionally built to damage, disrupt, or gain unauthorized access to a computer or network. Its malicious activities range widely: deleting or encrypting files, granting remote access to the infected machine, exfiltrating sensitive data, stopping services, or forcing a shutdown.

**Mitigation:** antivirus/EDR with up-to-date signatures and behavioral detection, ad-blockers (many drive-by infections start through malvertising), and user education around not downloading from unknown sources.

</details>

<details>
<summary><b>❓ Types of Malware</b></summary>

| Type | Behavior |
|---|---|
| **Virus** | Attaches itself to clean files and infects other clean files when the infected file is executed. Requires user action to run. |
| **Trojan** | Disguises itself as legitimate, useful software; tricks the user into executing it, then opens a backdoor for further compromise. |
| **Worm** | Spreads across a network on its own — no user interaction needed — by exploiting network shares, external storage, or email (auto-mailing itself to a victim's contacts). |
| **Spyware** | Hides in the background collecting data on user activity: passwords, card numbers, browsing habits. |
| **Ransomware** | Locks down the system/files and demands payment (a ransom) to restore access. |
| **Adware** | Not always malicious by itself, but aggressive ad-serving software can weaken security posture, consume resources, and open the door for other malware. |
| **Botnet malware** | Turns infected machines into remotely controlled nodes ("bots") that act together under an attacker's command — commonly used for DDoS or spam campaigns. |
| **RAT (Remote Access Trojan)** | Grants an attacker unauthorized, ongoing remote control of the victim's machine. |

</details>

<details>
<summary><b>❓ Virus vs. Trojan vs. Worm — What's the Real Difference?</b></summary>

The distinction interviewers usually probe for is *how it spreads*:

- **Virus** — needs a host file and a user action (running the infected file) to activate and spread.
- **Trojan** — disguises itself as something legitimate to trick the user into executing it; it doesn't self-replicate the way a virus does.
- **Worm** — spreads on its own across a network with no user interaction at all, via open shares, removable media, or self-propagating email.

</details>

<details>
<summary><b>❓ Fileless Malware</b></summary>

Fileless malware skips the traditional "drop an executable to disk" step entirely. Instead, it lives in memory (RAM) and abuses trusted, already-installed system tools — PowerShell, WMI, and similar "living-off-the-land" utilities — to carry out its malicious actions. Because there's no file on disk for a signature-based antivirus to scan, fileless techniques are significantly harder to catch with traditional AV.

**Mitigation:** EDR tools that monitor behavior (not just file signatures), and disabling command-line/scripting interpreters like PowerShell and WMI wherever they aren't operationally needed.

</details>

<details>
<summary><b>❓ Drive-By Download</b></summary>

A drive-by download is malicious code that installs itself simply because a user visited a compromised or malicious webpage — no click, no download prompt, no explicit user action required. It typically exploits outdated or vulnerable browsers, plugins, or apps.

**Mitigation:** keep software patched, deploy AV/web gateways capable of scanning inbound traffic, use web-filtering to block known-bad sites, restrict risky browser add-ons, and educate users against visiting untrusted sites.

</details>

---


## 🕸️ 6. Web Application Attacks (OWASP)


<details>
<summary><b>❓ What Is OWASP?</b></summary>

The **Open Web Application Security Project (OWASP)** is an open community that produces freely available research, tools, and documentation on web application security. Its best-known output is the **OWASP Top 10** — a periodically updated ranking of the most critical web application security risks. As of the widely-referenced 2019/2021-era list, the top risks included: Injection, Broken Authentication, Sensitive Data Exposure, XML External Entities (XXE), Broken Access Control, Security Misconfiguration, Cross-Site Scripting, Insecure Deserialization, and Using Components with Known Vulnerabilities.

</details>

<details>
<summary><b>❓ SQL Injection</b></summary>

SQL injection inserts malicious SQL statements into an application's input field so they get executed by the backend database. If successful, the attacker can bypass authentication, and read, modify, or delete data they have no business touching. A classic example payload is `' OR '1'='1' --`, which manipulates a login query's logic to always evaluate true.

**Mitigation:** strict input validation, sanitizing all user input (stripping quotes/special characters, or better — using parameterized queries/prepared statements), deploying a WAF/IPS, and suppressing detailed database error messages on production systems (which otherwise hand attackers a roadmap).

</details>

<details>
<summary><b>❓ Cross-Site Scripting (XSS)</b></summary>

XSS is a client-side code injection attack where the attacker gets malicious script to execute in *another user's* browser by sneaking it into a legitimate page or application — commonly through any field that reflects or stores user input, like a comment box.

**Mitigation:** input validation, sanitizing all inputs, and — critically — encoding output so any injected script is rendered as inert text rather than executed as code.

</details>

<details>
<summary><b>❓ Cross-Site Request Forgery (CSRF)</b></summary>

Also called a "one-click attack" or "session riding." CSRF tricks a user who is already authenticated to a site into unknowingly submitting a request that performs an action on their behalf. Example: while User A is logged into `mybank.com`, they're tricked into loading a page that silently submits a funds-transfer request — which the bank honors because it appears to come from A's already-authenticated session.

**Mitigation:** the synchronizer token pattern (a unique, unpredictable token required on every state-changing request), cookie-to-header token verification, and double-submit cookies.

</details>

<details>
<summary><b>❓ Broken Authentication</b></summary>

Broken authentication covers weaknesses that let an attacker capture or bypass an application's login mechanism entirely — permitting credential stuffing (testing lists of known-valid username/password pairs), brute force, default/weak passwords ("Password1", "admin/admin"), weak account-recovery flows, or storage of passwords in plaintext/weak hashes.

**Mitigation:** multi-factor authentication wherever possible, never shipping default credentials (especially for admin accounts), checking new/changed passwords against known-breached password lists, and locking accounts after repeated failed attempts.

</details>

<details>
<summary><b>❓ Broken Access Control</b></summary>

Broken access control is a flaw that lets a user perform actions or view data beyond what they're authorized for — for example, User A being able to view User B's account details simply by changing an ID in a URL. It commonly leads to unauthorized data disclosure, unauthorized modification/deletion of data, or performing business functions outside the user's actual permission level.

**Mitigation:** deny access by default and explicitly grant it, enforce access control lists and role-based authorization on every request (never trust the client), and log and alert on access-control failures — especially repeated ones, which often signal probing.

</details>

---


## 📌 7. Quick Reference Table


| Category | Attack | One-line detection cue |
|---|---|---|
| Credentials | Brute-force | Many auth failures, one source, short window |
| Credentials | Dictionary attack | Failed logins using common/leaked words |
| Credentials | Rainbow table | Cracked hash reused for auth without salting |
| Credentials | Pass-the-hash | NTLM auth from unusual host/account pairing |
| Network | Scanning | One source touching many ports/hosts fast |
| Network | Sniffing | Cleartext protocol use on the wire |
| Network | Spoofing | Mismatched identity vs. expected source |
| Network | ARP poisoning | Duplicate/changing MAC-to-IP bindings |
| Network | MITM | Unexpected latency/route changes |
| Network | DNS poisoning | Legit domain resolving to unexpected IP |
| Network | DNS tunneling | High-entropy/long DNS query names |
| Network | DoS / DDoS | Resource exhaustion, many sources (DDoS) |
| Network | SYN flood | Large volume of half-open TCP connections |
| Social | Phishing / Spear phishing / Whaling | Suspicious sender, urgency, mismatched links |
| Social | Vishing | Unsolicited call requesting sensitive info |
| Malware | Virus / Trojan / Worm | Unexpected process/file creation, propagation pattern |
| Malware | Fileless malware | Malicious PowerShell/WMI activity, no dropped file |
| Malware | Drive-by download | Unexpected download after visiting a webpage |
| Web App | SQL injection | Suspicious characters/logic in query parameters |
| Web App | XSS | Script tags/payloads reflected in input fields |
| Web App | CSRF | State-changing request missing a valid token |
| Web App | Broken authentication | Credential stuffing / brute force patterns on login |
| Web App | Broken access control | Authorization bypass via ID/parameter manipulation |

---

*This guide is for educational and interview-preparation use. Practicing detection and mitigation for these techniques should always happen in an authorized lab or test environment — never against systems you don't own or have explicit permission to test.*
