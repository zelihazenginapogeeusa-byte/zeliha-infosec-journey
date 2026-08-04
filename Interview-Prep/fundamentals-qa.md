# Cybersecurity Fundamentals — Interview Prep

This guide covers the baseline knowledge every cybersecurity interview probes, regardless of whether the role leans offensive (penetration testing, red team) or defensive (SOC analyst, incident response, blue team). It is meant to sit alongside separate, more specialized Red-Team and Blue-Team Q&A files in this repo — this document intentionally stays at the foundational level: networking, operating systems, core security principles, and cryptography. Attack-technique detail and SIEM/SOC operational workflows are covered in the sibling files, not here.

Each entry is written as an interview-style question with a prose answer you could actually say out loud, not just a flashcard definition.

---

## Table of Contents

1. [Networking Fundamentals](#networking-fundamentals)
2. [Operating Systems](#operating-systems)
3. [Core Security Concepts & the CIA Triad](#core-security-concepts--the-cia-triad)
4. [Cryptography Basics](#cryptography-basics)
5. [Security Frameworks & Compliance Basics](#security-frameworks--compliance-basics)
6. [Quick Reference](#quick-reference)

---

## 🌐 Networking Fundamentals


<details>
<summary><b>❓ What is the OSI model, and why does a security professional need to know it?</b></summary>

The OSI (Open Systems Interconnection) model is a conceptual, seven-layer framework that describes how data moves from an application on one machine to an application on another. From bottom to top the layers are: Physical, Data Link, Network, Transport, Session, Presentation, and Application. A common mnemonic is "Please Do Not Throw Sausage Pizza Away." Each layer has a distinct job — for example, the Data Link layer handles MAC addressing and switching within a local segment, the Network layer handles IP addressing and routing between networks, and the Transport layer handles end-to-end delivery guarantees via TCP or UDP.

For security work, the OSI model is less about memorizing trivia and more about having a mental map for where a given attack, control, or piece of evidence lives. ARP spoofing is a Layer 2 problem; IP spoofing and routing attacks are Layer 3; port scanning and session hijacking touch Layer 4; and most web application attacks (SQLi, XSS) live at Layer 7. When you're asked "where would you look for this," the OSI model gives you a structured way to answer instead of guessing.

</details>

<details>
<summary><b>❓ How does the TCP/IP model differ from the OSI model?</b></summary>

TCP/IP is the practical, four-layer model that the real-world internet actually runs on: Network Access (sometimes split into Physical and Data Link), Internet, Transport, and Application. It collapses OSI's Session, Presentation, and Application layers into a single Application layer, and merges Physical and Data Link into one Network Access layer. OSI is more useful as a teaching and troubleshooting reference because of its granularity; TCP/IP is what's actually implemented in protocol stacks and documentation like RFCs.

In interviews, it helps to be able to map layers across both models on the fly — for instance, knowing that "Layer 3" in OSI terms corresponds to the Internet layer in TCP/IP terms, and that both describe the same IP addressing and routing functionality just at different levels of abstraction.

</details>

<details>
<summary><b>❓ What's the difference between TCP and UDP, and when would each be used?</b></summary>

TCP (Transmission Control Protocol) is connection-oriented: before any data is sent, the two endpoints perform a handshake to establish a session, and TCP guarantees ordered, reliable delivery through sequence numbers, acknowledgments, and retransmission of lost packets. This reliability comes at the cost of overhead and latency. UDP (User Datagram Protocol) is connectionless — packets ("datagrams") are just sent with no handshake, no guaranteed order, and no automatic retransmission. It's faster and lighter but the application itself has to handle any reliability it needs.

TCP is used where correctness matters more than speed: web browsing (HTTP/HTTPS), email (SMTP), file transfer (FTP), and remote administration (SSH). UDP is used where speed matters more than occasional loss: DNS lookups, VoIP calls, video streaming, and online gaming. From a security angle, UDP-based services are also attractive for reflection/amplification DDoS attacks (e.g., DNS or NTP amplification) precisely because there's no handshake to verify the source before a response is sent.

</details>

<details>
<summary><b>❓ Walk me through the TCP three-way handshake.</b></summary>

The three-way handshake establishes a reliable TCP connection between a client and server before any application data flows. First, the client sends a SYN (synchronize) packet to the server, proposing an initial sequence number. Second, the server responds with a SYN-ACK packet, acknowledging the client's sequence number and proposing its own. Third, the client responds with an ACK packet, acknowledging the server's sequence number, and the connection is now considered established (ESTABLISHED state on both sides).

This handshake matters for security interviews because it underlies two very common concepts: SYN scanning (a "half-open" scan where the scanner sends a SYN, gets a SYN-ACK back confirming the port is open, but never completes the handshake with a final ACK, making the scan stealthier and faster) and SYN flood attacks (a denial-of-service technique where an attacker sends a flood of SYN packets and never completes the handshake, exhausting the server's connection table with half-open sessions).

</details>

<details>
<summary><b>❓ What is DNS, and how does a domain name resolve into an IP address?</b></summary>

DNS (Domain Name System) is the distributed, hierarchical system that translates human-readable domain names (like `example.com`) into IP addresses that machines actually use to route traffic. When a client wants to resolve a name, it typically queries a recursive resolver (often provided by the ISP or a public resolver). If the resolver doesn't have the answer cached, it starts at the root DNS servers, which point it to the appropriate top-level domain (TLD) servers (e.g., for `.com`), which in turn point it to the authoritative name server for that specific domain. The authoritative server returns the actual IP address, which gets cached along the way (subject to a TTL) and returned to the client.

Security-relevant DNS record types include A (IPv4 address), AAAA (IPv6 address), MX (mail exchange), NS (name server), CNAME (alias), TXT (often used for SPF/DKIM/DMARC anti-spoofing records), and PTR (reverse lookup). DNS is also a frequent attack surface and detection signal: DNS tunneling can exfiltrate data or establish command-and-control channels through what looks like ordinary DNS traffic, cache poisoning can redirect victims to malicious IPs, and typosquatted or newly-registered lookalike domains are a classic phishing indicator.

</details>

<details>
<summary><b>❓ What are the most important ports and protocols to know, and why?</b></summary>

A short list of ports comes up constantly in both offensive and defensive interviews because they map directly to real attack surface and real detection use cases:

| Port | Protocol | Purpose |
|------|----------|---------|
| 20/21 | FTP | File transfer (data/control) |
| 22 | SSH | Encrypted remote shell/admin |
| 23 | Telnet | Unencrypted remote shell (legacy, risky) |
| 25 | SMTP | Email sending/relay |
| 53 | DNS | Name resolution |
| 80 | HTTP | Unencrypted web traffic |
| 110 | POP3 | Email retrieval (legacy) |
| 143 | IMAP | Email retrieval |
| 443 | HTTPS | Encrypted web traffic (TLS) |
| 445 | SMB | Windows file/printer sharing |
| 3389 | RDP | Windows remote desktop |
| 3306 | MySQL | Database access |

Knowing these isn't about trivia for its own sake — it's about being able to reason quickly. If port 23 (Telnet) or an unauthenticated port 445 (SMB) shows up on a scan, that's an immediate red flag for cleartext credentials or lateral-movement risk. If you see an unexpected listener on 4444 or 1337, those are commonly associated with reverse shells or exploitation frameworks. Recognizing "normal" ports for common services is what lets you spot the abnormal one.

</details>

<details>
<summary><b>❓ What is subnetting, and how do you quickly work out network size from a CIDR notation like /24?</b></summary>

Subnetting is the practice of dividing a larger IP network into smaller, logically separated sub-networks. It's done using a subnet mask, which determines how many bits of an IP address identify the network versus the host. CIDR (Classless Inter-Domain Routing) notation expresses this as a suffix like `/24`, meaning the first 24 bits are the network portion and the remaining 8 bits are available for host addresses.

For a quick mental calculation: the number of host bits is `32 - CIDR prefix`, and the number of usable hosts is `2^(host bits) - 2` (subtracting the network address and broadcast address). A `/24` has 8 host bits, giving 256 total addresses and 254 usable host addresses — this is the classic "255.255.255.0" home/office network. A `/30` has only 2 host bits (4 addresses, 2 usable), which is commonly used for point-to-point links between two routers because it wastes the fewest addresses. Being able to do this arithmetic quickly signals real hands-on networking experience, and it directly supports tasks like scoping a pentest engagement to a specific CIDR range or recognizing whether a "network" in a SIEM alert is a single host or an entire subnet.

</details>

<details>
<summary><b>❓ What's the difference between a stateless and a stateful firewall?</b></summary>

A stateless (packet-filtering) firewall evaluates each packet in isolation against a static rule set — checking things like source/destination IP, port, and protocol — without any awareness of whether that packet belongs to an existing, legitimate connection. It's fast and simple but relatively easy to trick, since an attacker can sometimes craft packets that individually match an allowed rule even if they don't belong to any real session. A stateful firewall, by contrast, tracks the state of active connections (using a state table) and makes decisions based on the context of the whole session — for instance, it allows inbound traffic on a high port automatically if it's a reply to an outbound connection the internal host initiated, and it drops orphaned packets that don't correspond to any tracked session.

Modern network security has moved further to next-generation firewalls (NGFWs), which add capabilities like deep packet inspection, application-awareness (identifying traffic by application rather than just port), integrated intrusion prevention, and TLS inspection. In an interview, being able to explain *why* statefulness matters (context and session awareness, not just filtering) is more valuable than reciting the definition.

</details>

<details>
<summary><b>❓ How does a VPN work, and how is it different from a proxy?</b></summary>

A VPN (Virtual Private Network) creates an encrypted tunnel between a client and a VPN gateway (or between two networks), so that all traffic passing through the tunnel is protected from eavesdropping and tampering on the underlying network, and the client typically appears to originate from the VPN's network/IP address. VPNs commonly use protocols like IPsec, OpenVPN, or WireGuard, and they operate at the network layer, meaning they protect *all* IP traffic from the device, not just one application.

A proxy, by contrast, sits between a client and a destination for specific traffic (often just a browser or a single application) and forwards requests on the client's behalf, potentially caching content or filtering it, but a plain HTTP proxy does not necessarily encrypt traffic end-to-end the way a VPN tunnel does. The key distinctions to articulate: scope (whole-device vs. single-application/protocol), and security posture (a VPN is fundamentally about confidentiality/integrity of the tunnel, while a proxy is more often about routing, filtering, caching, or anonymizing at the application layer — though it can be combined with TLS for encryption in transit).

</details>

<details>
<summary><b>❓ What is NAT, and why does it matter for security?</b></summary>

NAT (Network Address Translation) allows multiple devices on a private network (using private IP ranges like `10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16`) to share a single public IP address when communicating with the internet. The NAT device (usually a router or firewall) rewrites the source IP and port of outbound packets and keeps a translation table so return traffic can be routed back to the correct internal host.

From a security standpoint, NAT provides an incidental benefit: because internal hosts aren't directly addressable from the internet, unsolicited inbound connections generally can't reach them unless a port is explicitly forwarded. This is often mistaken for a firewall or a real security control — it isn't one by design, but it does meaningfully shrink the attack surface exposed to the internet. It's also worth being able to explain the difference between NAT and a VPN in interviews, since people sometimes conflate "my IP is hidden by my router" (NAT) with "my traffic is encrypted" (VPN) — they solve different problems.

</details>

<details>
<summary><b>❓ What is ARP, and what is ARP spoofing?</b></summary>

ARP (Address Resolution Protocol) operates at Layer 2 and is used to map a known IP address to the corresponding MAC address on a local network segment, since Ethernet switches forward frames based on MAC addresses, not IP addresses. When a device needs to send a packet to another device on the same subnet, it broadcasts an ARP request ("who has this IP?") and the owning device replies with its MAC address; that mapping is then cached in the sender's ARP table for a period of time.

ARP spoofing (or ARP cache poisoning) exploits the fact that ARP has no built-in authentication — a malicious device can send unsolicited, forged ARP replies claiming to own an IP address that belongs to someone else (commonly the default gateway). Other devices on the segment update their ARP tables with the attacker's MAC address, causing their traffic to be routed through the attacker, enabling a man-in-the-middle position where traffic can be intercepted, modified, or dropped. This is why interviewers on both the offensive and defensive side care about it — it's a classic technique to demonstrate hands-on and a classic thing to detect via ARP table monitoring or switch port security features like Dynamic ARP Inspection.

</details>

<details>
<summary><b>❓ What's the difference between a MAC address and an IP address?</b></summary>

A MAC (Media Access Control) address is a 48-bit hardware identifier burned into (or spoofable on) a network interface card, used for Layer 2 communication within a local network segment — it's how switches decide which physical port to forward a frame to. An IP address is a logical, Layer 3 address assigned to a device (statically or via DHCP) that's used for routing traffic across different networks, including the internet. MAC addresses are generally static per interface and only relevant locally, while IP addresses can change and are what actually gets used for end-to-end routing decisions across the internet.

A simple way to frame this in an interview: MAC addresses answer "which physical device on this segment," IP addresses answer "which network and which host, regardless of physical location." Both matter for security — MAC filtering and MAC-based detections (like spotting a spoofed or duplicate MAC) are local-segment controls, while IP-based controls (firewall rules, geoblocking, IP reputation) operate at a broader routing level.

</details>

---


## 💻 Operating Systems


<details>
<summary><b>❓ What are the fundamental differences between Windows and Linux security models?</b></summary>

Windows security is built around a centralized identity and access model: the Security Reference Monitor enforces access checks using Security Identifiers (SIDs), Access Control Lists (ACLs) attached to objects, and access tokens that represent a user's identity and group memberships whenever a process runs. Group Policy and Active Directory extend this into a centrally managed, domain-wide identity and permissions system used heavily in enterprise environments. Linux, by contrast, traditionally uses a simpler discretionary model based on user/group/other permissions (read/write/execute) on files, augmented in modern distributions by more granular mechanisms like POSIX ACLs, and mandatory access control frameworks like SELinux or AppArmor that can enforce policy-based restrictions even for the root user.

Both models support the same underlying goals — authentication, authorization, and auditing — but the practical implication for a SOC or pentest role is that Windows environments are usually assessed through the lens of Active Directory (domain trust relationships, Kerberos, group policy misconfigurations), while Linux environments are usually assessed through file permissions, SUID/SGID binaries, sudo configuration, and service hardening. Being able to speak to both, even at a conceptual level, shows breadth that a single-OS specialist won't have.

</details>

<details>
<summary><b>❓ Explain the difference between a process and a thread, and why it matters for security.</b></summary>

A process is an independent, isolated instance of a running program with its own allocated memory space, file handles, and security context (in Windows terms, its own access token; in Linux terms, its own UID/GID). A thread is a unit of execution *within* a process — multiple threads in the same process share that process's memory space and resources, which makes inter-thread communication fast but also means a vulnerability in one thread (like a buffer overflow) can potentially corrupt memory used by other threads in the same process.

This distinction matters in security because process isolation is a core defensive boundary — it's why a compromised browser tab (in a sandboxed process model) shouldn't be able to directly read another application's memory, and it's why malware analysis and endpoint detection tools focus heavily on process trees (parent-child relationships) to spot suspicious behavior, like `winword.exe` spawning `powershell.exe`, which is a strong indicator of a malicious macro rather than normal document editing.

</details>

<details>
<summary><b>❓ How do Linux file permissions work, and what do SUID/SGID/sticky bits do?</b></summary>

Every file and directory in Linux has an owning user, an owning group, and a permission set expressed as three triads — read, write, execute — for the owner, the group, and everyone else, often shown as a string like `rwxr-xr--` or as an octal number like `754`. `chmod` changes these permissions, `chown` changes ownership, and `chgrp` changes the group. Execute on a directory specifically means "can be entered/traversed," which is a subtlety that trips people up.

Beyond the basic triad, three special bits matter a lot for security assessments. The SUID (Set User ID) bit on an executable causes it to run with the privileges of the file's *owner* rather than the user who launched it — this is how a non-root user can run `passwd` and still modify `/etc/shadow`, but it's also a classic privilege escalation vector if a SUID binary can be manipulated to execute arbitrary commands. SGID works the same way but for the group, and on a directory it causes new files created inside to inherit the directory's group. The sticky bit, most commonly seen on `/tmp`, restricts deletion of a file to its owner (or root) even if the directory itself is world-writable, preventing users from deleting each other's temp files.

</details>

<details>
<summary><b>❓ How do Windows NTFS permissions and Access Control Lists work?</b></summary>

NTFS permissions are attached to files and folders as an Access Control List (ACL), which is an ordered list of Access Control Entries (ACEs). Each ACE specifies a security principal (a user or group, identified by a SID) and the specific rights granted or denied to them (e.g., Read, Write, Modify, Full Control). Unlike the simple owner/group/other model in traditional Linux permissions, NTFS ACLs allow arbitrarily fine-grained, per-principal permissions on a single object, and permissions can be inherited from parent folders down to child objects unless explicitly blocked.

An important nuance for interviews: explicit Deny entries generally take precedence over Allow entries, and permissions from multiple applicable groups are cumulative (a user gets the union of what all their group memberships allow, except where an explicit Deny overrides it). This granularity is powerful for enterprise access control but also creates a large attack surface for misconfiguration — overly permissive ACLs on sensitive files, shares, or Group Policy objects are a very common finding in both real assessments and CTF-style exercises, and tools like BloodHound exist specifically to map these permission relationships across an Active Directory environment to find privilege escalation paths.

</details>

<details>
<summary><b>❓ What happens during the Linux boot process, at a high level?</b></summary>

The boot process starts with the system firmware — either legacy BIOS or the more modern UEFI — performing hardware initialization (POST, or Power-On Self-Test) and then locating a bootable device. The firmware hands off to a bootloader (commonly GRUB), which presents boot options and loads the Linux kernel (and an initial RAM disk, initramfs, containing drivers needed before the real filesystem is mounted) into memory. The kernel initializes hardware, mounts the root filesystem, and then starts the first userspace process — historically `init` (PID 1), though most modern distributions use `systemd`, which reads unit files to bring up services in the correct order, respecting dependencies, until the system reaches its target runlevel (e.g., multi-user or graphical).

Security relevance here includes things like GRUB password protection (preventing boot-time tampering or single-user-mode privilege escalation), Secure Boot (a UEFI feature that cryptographically verifies each stage of the boot chain to prevent bootkits/rootkits), and understanding `systemd` service units well enough to recognize a persistence mechanism that a piece of malware might install as a fake or malicious service.

</details>

<details>
<summary><b>❓ What happens during the Windows boot process, at a high level?</b></summary>

Similar to Linux, Windows boot starts with firmware (BIOS or UEFI) performing POST and then loading a bootloader — on modern systems this is the Windows Boot Manager (`bootmgr`), which reads the Boot Configuration Data (BCD) store to determine what to boot. The bootloader loads `winload.exe`, which loads the Windows kernel (`ntoskrnl.exe`) along with the Hardware Abstraction Layer and core boot drivers. The kernel initializes, and eventually the Session Manager (`smss.exe`) starts the Windows subsystem, followed by `wininit.exe`, which launches critical system processes including the Service Control Manager (`services.exe`, responsible for starting Windows services), the Local Security Authority Subsystem (`lsass.exe`, central to authentication and credential handling), and eventually the logon process that presents the login screen.

`lsass.exe` in particular is worth knowing well for interviews on both sides of the fence: it's the process responsible for enforcing security policy and handling credentials in memory, which is exactly why it's such a common target for credential-dumping tools on the offensive side, and why LSASS access is one of the most heavily monitored and protected processes from a defensive/EDR standpoint (Credential Guard, Protected Process Light, and similar mitigations exist specifically to make LSASS harder to tamper with).

</details>

<details>
<summary><b>❓ What's the difference between kernel mode and user mode?</b></summary>

Modern CPUs support privilege levels (often called "rings," with Ring 0 being the most privileged) that the operating system uses to separate trusted and untrusted code. Kernel mode (Ring 0) has unrestricted access to hardware and memory — this is where the OS kernel, device drivers, and core system services run. User mode (Ring 3 on x86) is a restricted execution context where ordinary applications run; code in user mode cannot directly access hardware or arbitrary memory and must go through defined system calls to request the kernel perform privileged operations on its behalf.

This separation is a foundational security boundary: a bug or exploit in a user-mode application is generally contained to that process's own memory space, while a bug or exploit in kernel-mode code (like a vulnerable driver) can compromise the entire system, since kernel code isn't restricted by the same protections. This is exactly why kernel-level vulnerabilities and vulnerable/malicious drivers ("Bring Your Own Vulnerable Driver" attacks) are considered so serious, and why privilege escalation from user mode to kernel mode is one of the highest-impact outcomes an attacker can achieve on a single host.

</details>

<details>
<summary><b>❓ What is a service (or daemon), and why does it matter for attack surface?</b></summary>

A service on Windows (or a daemon on Linux) is a background process that runs independently of any interactively logged-in user, typically starting automatically at boot and often running with elevated privileges (SYSTEM on Windows, root on Linux) because it needs to perform system-level tasks. Examples include web servers, database engines, print spoolers, and remote access services like SSH or RDP.

Services matter enormously for attack surface because each one that's running and listening on a network port is a potential entry point, and because many services run with high privileges by default, a vulnerability in the service itself can lead directly to full system compromise rather than just user-level access. This is the core logic behind attack surface reduction as a defensive practice: disabling unnecessary services, ensuring services run with the least privilege actually required (rather than defaulting to SYSTEM/root), and keeping service software patched are all standard hardening steps that show up constantly in both CIS benchmarks and real-world incident postmortems.

</details>

<details>
<summary><b>❓ What is the Windows Registry, and why is it relevant to security?</b></summary>

The Windows Registry is a hierarchical database that stores low-level configuration settings for the operating system, installed applications, and per-user preferences. It's organized into root keys (hives) such as `HKEY_LOCAL_MACHINE` (system-wide settings) and `HKEY_CURRENT_USER` (settings for the currently logged-on user), each containing nested keys and values.

The Registry is security-relevant because it's a very common location for both legitimate configuration and malicious persistence. Autorun locations like `Run` and `RunOnce` keys under `HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion` are frequently abused by malware to automatically execute every time a user logs in, and Registry values also store things like installed services, scheduled task references, and security policy settings. On the defensive side, monitoring specific Registry keys for unexpected changes is a standard detection technique, and on the offensive side, Registry-based persistence is one of the most commonly used techniques after gaining initial access to a Windows host.

</details>

---


## 🛡️ Core Security Concepts & the CIA Triad


<details>
<summary><b>❓ What is the CIA triad, and can you give a real example of each principle being violated?</b></summary>

The CIA triad — Confidentiality, Integrity, and Availability — is the foundational model for what security is actually trying to protect. Confidentiality means ensuring information is only accessible to those authorized to see it; it's violated by things like a data breach exposing customer records, or an attacker eavesdropping on unencrypted traffic. Integrity means ensuring data is accurate and hasn't been tampered with, whether maliciously or accidentally; it's violated by an attacker modifying financial transaction records, or even non-malicious data corruption during a failed disk write. Availability means ensuring authorized users can access systems and data when they need to; it's violated by a denial-of-service attack, a ransomware attack that encrypts critical files, or even a non-malicious hardware failure that takes a service offline.

In interviews, it's worth being ready to explain that most security controls map onto one or more of these three — encryption primarily protects confidentiality (and can support integrity via authenticated encryption), hashing and digital signatures primarily protect integrity, and redundancy/backups/DDoS protection primarily protect availability — and that real-world security decisions are often about balancing tradeoffs between the three (for example, extremely strict access controls improve confidentiality but can hurt availability if legitimate users get locked out too easily).

</details>

<details>
<summary><b>❓ What is AAA in security, and how do authentication, authorization, and accounting differ?</b></summary>

AAA stands for Authentication, Authorization, and Accounting, and it describes three distinct but related functions in access control. Authentication answers "who are you?" — it's the process of verifying an identity claim, typically through something you know (a password), something you have (a hardware token or phone), or something you are (biometrics), often combined as multi-factor authentication (MFA). Authorization answers "what are you allowed to do?" — once identity is established, authorization determines what resources and actions that identity is permitted to access, usually enforced through mechanisms like role-based access control (RBAC) or access control lists. Accounting (sometimes called auditing) answers "what did you actually do?" — it's the logging and tracking of actions taken by an authenticated, authorized identity, which is essential for forensic investigation, compliance, and detecting misuse.

A concrete way to keep these straight: logging into a system with a username and password is authentication; being permitted to read a file but not delete it is authorization; and the log entry recording that you read that file at a specific timestamp is accounting. Interviewers often ask this specifically because candidates frequently conflate authentication and authorization, and being crisp about the distinction is an easy way to demonstrate fundamentals.

</details>

<details>
<summary><b>❓ What does "defense in depth" mean, and why is it preferred over relying on a single control?</b></summary>

Defense in depth is the principle of layering multiple, independent security controls so that if one layer fails or is bypassed, other layers still provide protection — rather than relying on any single control to be perfect. A practical example: a company might have a perimeter firewall, network segmentation, endpoint detection and response (EDR) on individual hosts, application-level input validation, encrypted data at rest, and a trained user base that can recognize phishing — all protecting the same underlying assets from different angles and against different failure modes.

The reasoning behind this principle is that no single control is foolproof — firewalls can be misconfigured, patches can be missed, users can be tricked — so the goal is to make a successful attack require compromising *multiple* independent layers rather than just one. This is also why interviewers often ask candidates to critique a "flat" network with only a perimeter firewall and no internal segmentation: without defense in depth, a single successful phishing email can lead directly to full internal network compromise because there's nothing to stop lateral movement once the perimeter is breached.

</details>

<details>
<summary><b>❓ What is the principle of least privilege, and how does it reduce risk?</b></summary>

The principle of least privilege states that a user, process, or system should be granted only the minimum access rights necessary to perform its function, and nothing more. In practice this means a standard user account shouldn't have local administrator rights unless their job actually requires it, a web application's database account should only have the permissions needed for the specific queries it runs (rather than full database owner rights), and a service should run under a dedicated low-privilege account rather than as SYSTEM or root by default.

The risk reduction comes from limiting the "blast radius" of any single compromise: if an attacker phishes a standard user with no admin rights, they get a foothold but can't immediately install software, dump credentials from other users, or disable security tooling — they need an additional privilege escalation step, which is both harder to pull off and creates additional opportunities for detection. Least privilege is one of the most consistently cited controls in both offensive assessments (because privilege escalation is such a common and necessary step in a real attack chain) and defensive hardening guidance (because it's one of the most effective, low-cost mitigations an organization can implement).

</details>

<details>
<summary><b>❓ What is zero trust, and how is it different from traditional perimeter-based security?</b></summary>

Traditional "castle and moat" security assumes that anything inside the network perimeter is relatively trustworthy and focuses defensive effort on the boundary — a strong firewall at the edge, but relatively loose controls once you're "inside." Zero trust rejects that assumption entirely, operating on the principle of "never trust, always verify": no user, device, or system is trusted by default, regardless of whether it's inside or outside the traditional network boundary, and every access request must be authenticated, authorized, and continuously validated based on context (identity, device health, location, behavior) before being granted.

In practice, zero trust architectures rely heavily on strong identity verification (MFA everywhere), micro-segmentation (so that even internal lateral movement is restricted rather than assumed safe), least-privilege access enforced per-request rather than per-session, and continuous monitoring rather than a one-time login check. The shift matters because modern environments — cloud services, remote work, mobile devices — have made the idea of a single defensible network perimeter mostly obsolete; an attacker who compromises one internal device in a traditional model often has broad internal access, whereas in a properly implemented zero trust model that same compromise should be tightly contained.

</details>

<details>
<summary><b>❓ What's the difference between a threat, a vulnerability, and a risk (and where does an exploit fit)?</b></summary>

These terms get used loosely in casual conversation but have precise, distinct meanings that interviewers specifically check for. A vulnerability is a weakness in a system — a flaw in software, a misconfiguration, a gap in a process — that could potentially be exploited (for example, an unpatched software version with a known bug). A threat is a potential source of harm — an actor or event that could exploit a vulnerability, such as a specific attacker group, an insider, or even a non-malicious event like a natural disaster. An exploit is the actual tool, technique, or piece of code used to take advantage of a specific vulnerability. Risk is the combination of all of these — conceptually, risk is a function of the likelihood that a threat will exploit a vulnerability, multiplied by the impact if it succeeds.

A concrete example ties it together well: an unpatched public-facing server (vulnerability) plus an opportunistic attacker scanning the internet for that exact flaw (threat) plus publicly available exploit code targeting that flaw (exploit) combine to produce a risk — and the actual risk level also depends on impact, so the same vulnerability on a test server with no real data is lower risk than on a production server holding sensitive customer records, even though the vulnerability and the threat are identical in both cases.

</details>

<details>
<summary><b>❓ What is an attack surface, and how do you reduce it?</b></summary>

The attack surface is the total sum of all points where an unauthorized user could potentially interact with a system to extract or insert data — this includes open network ports and exposed services, installed software (especially unnecessary or outdated software), web application input fields, physical access points, and even human factors like employees susceptible to social engineering. A larger attack surface doesn't automatically mean more actual vulnerabilities, but it does mean more places where a vulnerability *could* exist and more work required to secure everything thoroughly.

Reducing attack surface is a proactive, foundational defensive strategy: disabling unused services and ports, uninstalling unnecessary software, enforcing strict network segmentation so that not every host can reach every other host, limiting the number of user accounts with elevated privileges, and minimizing the amount of software directly exposed to the internet. This concept is closely tied to least privilege and defense in depth — all three are really different facets of the same underlying idea, which is minimizing unnecessary exposure and unnecessary trust wherever possible.

</details>

<details>
<summary><b>❓ What is non-repudiation, and why does it matter?</b></summary>

Non-repudiation is the security property that ensures an action or transaction cannot later be credibly denied by the party who performed it — in other words, there's sufficiently strong evidence tying a specific identity to a specific action that they can't plausibly claim "that wasn't me." It's often listed alongside the CIA triad as an important complementary concept rather than part of the triad itself.

Practically, non-repudiation is achieved through mechanisms like digital signatures (which cryptographically bind a specific private key holder to a specific piece of signed content), detailed audit logging with strong identity attribution, and secure timestamping. It matters most in contexts with legal or financial weight — for example, ensuring a signed contract or a financial transaction can be definitively traced to the individual who authorized it, or ensuring that logs used as evidence in an incident investigation can't be dismissed as ambiguous about who actually took an action.

</details>

<details>
<summary><b>❓ What is social engineering, and why is it considered one of the most effective attack vectors?</b></summary>

Social engineering is the manipulation of people, rather than technical systems, into performing actions or divulging information that compromises security — phishing emails, pretexting phone calls impersonating IT support, tailgating into a secure building behind an authorized employee, or baiting someone with an infected USB drive are all classic examples. It's considered so effective because it targets human psychology (urgency, authority, fear, curiosity, trust) rather than a technical flaw, and technical controls alone — no matter how well-configured a firewall or how patched a system is — can't fully prevent a user from being convinced to click a malicious link or hand over a password.

This is precisely why security awareness training, phishing simulations, and a strong reporting culture (where employees feel comfortable flagging a suspicious email rather than ignoring it or being embarrassed) are treated as legitimate, necessary security controls rather than a "nice to have," and why "the human element" shows up in almost every major breach report as either the initial access vector or a significant contributing factor.

</details>

<details>
<summary><b>❓ What is vulnerability management, and how does it relate to patch management?</b></summary>

Vulnerability management is the ongoing, cyclical process of identifying, classifying, prioritizing, remediating, and verifying the remediation of security weaknesses across an organization's systems. It typically involves regular scanning (using tools that check systems against known vulnerability databases), risk-based prioritization (not every vulnerability needs to be fixed immediately — severity, exploitability, and asset criticality all factor in, often using a scoring system like CVSS), remediation (which might mean applying a patch, but could also mean a configuration change or a compensating control), and verification that the fix actually worked.

Patch management is a specific and very common subset of remediation within that broader cycle — the process of identifying, testing, and deploying software updates that fix known vulnerabilities. The distinction matters because not every vulnerability has an available patch, and not every fix is a patch — sometimes the right remediation is disabling a feature, restricting network access to a vulnerable service, or applying a vendor-recommended workaround while waiting for an official fix. Being able to explain this distinction, and the general idea of risk-based prioritization rather than "patch everything immediately regardless of context," is a good signal of practical, real-world security maturity in an interview.

</details>

---


## 🔐 Cryptography Basics


<details>
<summary><b>❓ What's the difference between symmetric and asymmetric encryption?</b></summary>

Symmetric encryption uses a single shared secret key for both encrypting and decrypting data — both parties must have the same key, and that key must be exchanged securely beforehand. It's computationally fast and efficient, which is why it's used for encrypting bulk data, but the key distribution problem (securely getting the shared key to both parties without it being intercepted) is its main practical challenge. Common symmetric algorithms include AES (the current standard, used in modes like AES-256) and, historically, DES and 3DES (both now considered weak or deprecated).

Asymmetric encryption (public-key cryptography) uses a mathematically related key pair — a public key, which can be freely shared, and a private key, which must be kept secret. Data encrypted with the public key can only be decrypted with the corresponding private key (used for confidentiality), and data signed with the private key can be verified by anyone using the public key (used for authenticity/non-repudiation). It solves the key distribution problem elegantly since the public key doesn't need to be kept secret, but it's computationally much more expensive than symmetric encryption. Common asymmetric algorithms include RSA and elliptic-curve cryptography (ECC). In practice, real-world systems like TLS use both together — asymmetric cryptography to securely negotiate a shared secret, and then fast symmetric encryption for the actual bulk data transfer, getting the security benefits of asymmetric key exchange with the performance of symmetric encryption.

</details>

<details>
<summary><b>❓ What's the difference between encryption and hashing?</b></summary>

Encryption is a reversible transformation of data using a key — anyone with the correct key (symmetric) or the corresponding private key (asymmetric) can decrypt the ciphertext back into the original plaintext. It's designed to protect confidentiality: the data can always come back if you're authorized to have it. Hashing is a one-way transformation that takes an input of any size and produces a fixed-size output (a "digest" or "hash"), and it is deliberately designed to be irreversible — you cannot mathematically derive the original input from the hash output. A good cryptographic hash function is also deterministic (the same input always produces the same output) and exhibits the avalanche effect (a tiny change in input produces a drastically different output), and it should be computationally infeasible to find two different inputs that produce the same output (a "collision").

Hashing is used to protect integrity, not confidentiality — verifying a downloaded file's hash confirms it wasn't tampered with in transit, and storing password hashes (rather than plaintext passwords) means that even if a database is breached, the actual passwords aren't directly exposed (though they can still potentially be cracked offline, which is why salting matters). Common hash algorithms include SHA-256 (widely used and currently considered secure) and MD5/SHA-1 (both now considered broken for security-sensitive purposes due to demonstrated collision vulnerabilities, though they still see use in non-security contexts like checksums).

</details>

<details>
<summary><b>❓ What is salting, and why is it necessary for password storage?</b></summary>

A salt is a random, unique value generated for each individual password and combined with that password before it's hashed and stored, with the salt itself stored alongside the resulting hash (it doesn't need to be secret, just unique per user). Its purpose is to defeat precomputed attacks: without a salt, an attacker who steals a database of password hashes can use a rainbow table (a precomputed lookup table mapping common passwords to their hash values) to instantly reverse many of those hashes, and if two users happen to have chosen the same password, their hashes would also be identical, revealing that fact to the attacker.

With a unique salt per user, the same password produces a completely different hash for every user, which makes precomputed rainbow tables useless (the attacker would need a separate table for every possible salt value) and means even identical passwords across users hash differently. Modern password storage goes a step further by using purpose-built, deliberately slow hashing algorithms like bcrypt, scrypt, or Argon2, which incorporate salting automatically and are specifically designed to be computationally expensive (and in some cases memory-intensive) to slow down brute-force and dictionary attacks, unlike general-purpose fast hashes such as SHA-256 which are actually a poor choice for password storage precisely because their speed makes brute-forcing easier.

</details>

<details>
<summary><b>❓ What is PKI (Public Key Infrastructure), and what role does a digital certificate play in it?</b></summary>

PKI is the overall system of policies, roles, hardware, software, and procedures needed to create, distribute, manage, store, and revoke digital certificates and manage public-key encryption at scale. Its core problem to solve is trust: if you receive someone's public key, how do you know it actually belongs to them and hasn't been substituted by an attacker performing a man-in-the-middle attack? PKI answers this through a chain of trust rooted in Certificate Authorities (CAs) — trusted third parties that verify an entity's identity and then issue a digital certificate binding that entity's identity to their public key, digitally signed by the CA itself so that anyone who trusts the CA can trust the certificate.

A digital certificate (most commonly in X.509 format) contains the subject's public key, identifying information (like the domain name for a website certificate), the issuing CA's identity, a validity period, and the CA's digital signature over all of that content. When a browser connects to a website over HTTPS, it checks that the presented certificate is valid, unexpired, matches the domain being visited, and chains up to a CA that the browser already trusts (root CAs are pre-installed in operating systems and browsers) — often via one or more intermediate CAs. Certificate revocation (via CRLs or the more modern OCSP protocol) also matters because a certificate might need to be invalidated before its expiration date, for example if the associated private key was compromised.

</details>

<details>
<summary><b>❓ Can you walk through what happens during a TLS handshake at a conceptual level?</b></summary>

The TLS handshake is how a client and server establish a secure, encrypted connection before any application data (like an HTTP request) is exchanged. At a conceptual level, it starts with the client sending a "Client Hello," which includes the TLS versions and cipher suites it supports along with a random value. The server responds with a "Server Hello," selecting the TLS version and cipher suite to use, providing its own random value, and — critically — presenting its digital certificate, which contains its public key and is signed by a CA. The client validates that certificate against its trusted CA chain to confirm it's actually talking to the legitimate server (and not an attacker performing a man-in-the-middle attack).

Once the server's identity is validated, the client and server use asymmetric cryptography (historically RSA key exchange, though modern TLS strongly favors Diffie-Hellman-based key exchange for forward secrecy) to securely agree on a shared symmetric session key, without ever transmitting that key in a way an eavesdropper could directly capture. From that point forward, all actual application data is encrypted using fast symmetric encryption with that negotiated session key, which is why TLS gets the security benefit of asymmetric authentication and key exchange combined with the performance benefit of symmetric encryption for the bulk of the conversation. It's worth being able to mention that TLS 1.3, the current modern standard, streamlined this handshake to require fewer round trips than TLS 1.2 and removed support for several older, weaker cryptographic options by design.

</details>

<details>
<summary><b>❓ What is a digital signature, and how does it differ from just encrypting something with a private key?</b></summary>

A digital signature is created by taking a hash of a message and then encrypting that hash with the signer's private key; anyone with the signer's corresponding public key can decrypt the signature to recover the hash, independently compute the hash of the received message themselves, and confirm the two match. If they match, this proves two things simultaneously: the message actually came from the holder of that private key (authenticity), and the message wasn't altered after it was signed (integrity), since even a single-bit change to the message would produce a completely different hash.

It's worth being precise about this in an interview because people sometimes describe it loosely as "encrypting with your private key," which conflates signing with confidentiality — a digital signature doesn't hide the content of the message at all (the message itself is typically sent in plaintext alongside the signature), it only proves who sent it and that it's unmodified. This is exactly why digital signatures are the mechanism underlying code-signing (proving a piece of software actually came from the claimed vendor and hasn't been tampered with), signed emails, and the CA signatures that make the entire PKI trust chain work.

</details>

---


## 📋 Security Frameworks & Compliance Basics


<details>
<summary><b>❓ What is the NIST Cybersecurity Framework (CSF), and what are its core functions?</b></summary>

The NIST Cybersecurity Framework is a widely adopted, voluntary framework that provides organizations with a common structure and vocabulary for managing and reducing cybersecurity risk, rather than being a prescriptive checklist of specific technical controls. In its most recognized form it's organized around a set of core functions: Identify (understand the organization's assets, risks, and business context), Protect (implement safeguards to limit or contain the impact of a potential event), Detect (implement activities to identify the occurrence of a security event in a timely manner), Respond (take action once an incident has been detected, to contain and mitigate impact), and Recover (restore capabilities and services that were impaired, and learn from the event). Newer versions of the framework have also added a "Govern" function, emphasizing that cybersecurity risk management needs to be integrated into overall organizational governance and decision-making, not treated as a purely technical, bolted-on concern.

The value of knowing this framework in an interview isn't reciting the five or six function names — it's being able to use them as a mental structure to talk about where a specific control or activity fits. For example, a SOC's SIEM and alerting capability primarily supports Detect, an incident response plan supports Respond, regular backups support Recover, and patching supports Protect — being able to categorize security activities this way shows you understand security as a continuous lifecycle, not just a single point-in-time defense.

</details>

<details>
<summary><b>❓ What is ISO 27001, and how is it different from NIST CSF?</b></summary>

ISO/IEC 27001 is an international standard that specifies requirements for establishing, implementing, maintaining, and continually improving an Information Security Management System (ISMS) — essentially, a formal, documented, risk-based management system for how an organization handles information security, covering people, processes, and technology. Unlike NIST CSF, which is a voluntary, flexible framework you can adopt and adapt to your own risk posture, ISO 27001 is a certifiable standard — organizations can undergo a formal audit by an accredited third party and be certified as compliant, which is often used as a way to demonstrate security maturity to customers, partners, or regulators, particularly outside the United States.

A useful way to frame the distinction in an interview: NIST CSF is generally about *what* functions and outcomes a security program should achieve, described at a fairly high level and adaptable to any organization's context, while ISO 27001 is more about *how* to formally structure, document, and continuously manage a security program as a certifiable management system, complete with a specific control catalog (detailed in the companion standard ISO 27002) that auditors check against. Many organizations actually map their controls against both, since they're complementary rather than competing.

</details>

<details>
<summary><b>❓ What is MITRE ATT&CK, at a conceptual level (without going deep into specific techniques)?</b></summary>

MITRE ATT&CK is a publicly available, community-maintained knowledge base that catalogs real-world adversary tactics, techniques, and procedures (TTPs), organized into a matrix. "Tactics" represent the adversary's goal at a given stage of an attack (for example, Initial Access, Privilege Escalation, or Exfiltration), while "Techniques" (and more granular "Sub-techniques") represent the specific methods used to achieve that tactic. The value of the framework is that it gives defenders and attackers a shared, standardized vocabulary to describe adversary behavior, rather than everyone using inconsistent, informal terminology.

Conceptually, ATT&CK matters to both offensive and defensive roles for different reasons: on the offensive side, it provides a structured way to plan and document an attack chain during a penetration test or red team engagement in terms recognizable to the client and industry; on the defensive side, it's used to map existing detection coverage against known adversary behavior (identifying gaps — "we have no detection for this specific technique"), to structure threat-informed defense programs, and to describe observed incidents in a standardized way during and after an investigation. The specific technique IDs and detailed attacker methodology are covered in more depth in the sibling Red-Team and Blue-Team files in this repo — the key thing to understand at this foundational level is simply what the framework *is* and why it exists as a shared reference point across the industry.

</details>

<details>
<summary><b>❓ What is a CVE, and what does a CVSS score actually tell you?</b></summary>

A CVE (Common Vulnerabilities and Exposures) is a unique, standardized identifier assigned to a specific, publicly known security vulnerability, formatted like `CVE-2023-12345`. The CVE system exists so that the security industry — vendors, researchers, scanners, and defenders — can all refer to the exact same vulnerability using a consistent identifier, rather than each organization using its own inconsistent naming.

CVSS (Common Vulnerability Scoring System) is a standardized method for rating the severity of a given vulnerability on a scale from 0 to 10, calculated from a set of metrics that typically include things like the attack vector (can it be exploited remotely over the network, or does it require local/physical access), attack complexity, privileges required, user interaction required, and the potential impact to confidentiality, integrity, and availability if exploited. A high CVSS score (generally 9.0+ is considered "Critical") signals that a vulnerability is both easy to exploit and has severe potential impact, which is why CVSS scores are commonly used as one input (though not the only one — actual exploitability in the wild and asset criticality matter too) for prioritizing which vulnerabilities to patch first in a vulnerability management program.

</details>

<details>
<summary><b>❓ What are some common compliance and regulatory frameworks a security professional should at least recognize, even outside a specific specialization?</b></summary>

Even in a technical SOC or pentest-track role, it's worth being conversationally familiar with a handful of major compliance frameworks, since business and regulatory context regularly shapes what security teams are actually required to do. PCI DSS (Payment Card Industry Data Security Standard) sets security requirements for any organization that stores, processes, or transmits credit card data, covering things like network segmentation, encryption of cardholder data, and regular vulnerability scanning. HIPAA (Health Insurance Portability and Accountability Act) governs the protection of patient health information in the United States, requiring specific administrative, physical, and technical safeguards. GDPR (General Data Protection Regulation) is a broad European Union regulation governing the privacy and protection of personal data for EU residents, notable for its strict breach-notification timelines and significant potential fines. SOC 2 is an auditing framework, common among SaaS and technology companies, that evaluates an organization's controls related to security, availability, processing integrity, confidentiality, and privacy, typically requested by business customers as assurance during vendor evaluations.

The interview-relevant takeaway isn't memorizing every clause of these regulations — it's understanding that compliance requirements are often the actual business driver behind specific security controls (for example, why a company insists on encrypting a particular database, or why breach notification timelines matter so much operationally), and being able to recognize the name and general scope of each when it comes up in conversation demonstrates baseline business awareness that purely technical candidates sometimes lack.

</details>

---


## 📌 Quick Reference


### OSI Model (7 Layers)

| Layer # | Name | Examples / Concerns |
|---------|------|----------------------|
| 7 | Application | HTTP, DNS, SMTP; web app attacks |
| 6 | Presentation | Encryption, encoding, compression (TLS often mapped here) |
| 5 | Session | Session establishment/teardown |
| 4 | Transport | TCP, UDP; port scanning, session hijacking |
| 3 | Network | IP, routing; IP spoofing, subnetting |
| 2 | Data Link | Ethernet, MAC addresses, switches; ARP spoofing |
| 1 | Physical | Cables, radio signals, hardware |

### Common Ports

| Port | Protocol | Notes |
|------|----------|-------|
| 21 | FTP | Cleartext file transfer control |
| 22 | SSH | Encrypted remote admin |
| 23 | Telnet | Cleartext remote admin (legacy/risky) |
| 25 | SMTP | Mail sending |
| 53 | DNS | Name resolution (TCP + UDP) |
| 80 | HTTP | Unencrypted web |
| 110 | POP3 | Legacy mail retrieval |
| 143 | IMAP | Mail retrieval |
| 443 | HTTPS | TLS-encrypted web |
| 445 | SMB | Windows file/printer sharing |
| 3306 | MySQL | Database |
| 3389 | RDP | Windows remote desktop |

### CIA Triad + Extensions

| Principle | Protects Against | Common Controls |
|-----------|-------------------|------------------|
| Confidentiality | Unauthorized disclosure | Encryption, access control |
| Integrity | Unauthorized modification | Hashing, digital signatures |
| Availability | Denial of access | Redundancy, backups, DDoS protection |
| Non-repudiation | Denying an action occurred | Digital signatures, audit logs |

### Symmetric vs Asymmetric Crypto

| | Symmetric | Asymmetric |
|---|-----------|------------|
| Keys | One shared secret key | Public/private key pair |
| Speed | Fast | Slow (relatively) |
| Main use | Bulk data encryption | Key exchange, signatures, authentication |
| Examples | AES, 3DES | RSA, ECC |

### Risk Terminology

| Term | Definition |
|------|------------|
| Vulnerability | A weakness that could be exploited |
| Threat | A potential source of harm |
| Exploit | The actual tool/technique used against a vulnerability |
| Risk | Likelihood × Impact of a threat exploiting a vulnerability |

---

*Disclaimer: This document is provided for educational and interview-preparation purposes only and reflects general cybersecurity knowledge; it is not a substitute for official certification study materials, vendor documentation, or professional security advice.*
