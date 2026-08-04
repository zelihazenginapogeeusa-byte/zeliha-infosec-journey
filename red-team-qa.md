# Red Team / Offensive Security — Interview Prep

This guide focuses on the offensive practitioner's side of security interviews: methodology, tools, exploitation concepts, and professional practice for penetration testing and red team roles. It assumes familiarity with core networking, operating system, and cryptography fundamentals (covered separately), and it deliberately does not duplicate detection/SOC content covered in the blue-team guide. Everything here is written for use in **authorized, legally scoped engagements only** — see the closing note at the bottom.

---

## Table of Contents

1. [Methodology & Engagement Types](#methodology--engagement-types)
2. [Reconnaissance & OSINT](#reconnaissance--osint)
3. [Scanning & Enumeration](#scanning--enumeration)
4. [Vulnerability Assessment & Exploitation](#vulnerability-assessment--exploitation)
5. [Post-Exploitation & Privilege Escalation](#post-exploitation--privilege-escalation)
6. [Lateral Movement, Pivoting & Persistence](#lateral-movement-pivoting--persistence)
7. [Reporting & Professional Practice](#reporting--professional-practice)
8. [Quick Reference Tables](#quick-reference-tables)

---

## 🎯 Methodology & Engagement Types


<details>
<summary><b>❓ Walk me through the phases of a typical penetration test.</b></summary>

Most penetration tests follow a broadly consistent lifecycle, even though naming varies by framework (PTES, OSSTMM, NIST SP 800-115, or a vendor's internal methodology). It generally looks like: **pre-engagement** (scoping, rules of engagement, authorization, defining objectives and constraints), **reconnaissance/information gathering** (passive and active discovery of the target's footprint), **scanning and enumeration** (identifying live hosts, open ports, services, and versions), **vulnerability analysis** (mapping discovered services to known weaknesses, both via automated scanning and manual analysis), **exploitation** (proving impact by actually gaining access or demonstrating the flaw is exploitable, not just theoretical), **post-exploitation** (privilege escalation, lateral movement, data access, establishing the real-world business impact), and finally **reporting and remediation support** (documenting findings with evidence, risk ratings, and actionable fixes, and often a follow-up retest). I'd emphasize in an interview that this is a cycle, not a strict waterfall — exploitation often reveals new information that sends you back into enumeration on a newly discovered host or service, so experienced testers move fluidly between phases rather than treating them as rigid gates.

</details>

<details>
<summary><b>❓ What's the difference between a vulnerability assessment, a penetration test, a red team engagement, and a bug bounty?</b></summary>

These are frequently confused, and being able to draw clean lines between them is a strong interview signal. A **vulnerability assessment** is primarily about breadth and identification: scanning an environment, cataloguing weaknesses, and prioritizing them by severity, usually without actively exploiting them to prove impact. A **penetration test** goes further — it validates that vulnerabilities are actually exploitable, chains them together where possible, and demonstrates real impact within an agreed scope and timeframe, but it's still typically time-boxed and the target organization usually knows testing is happening. A **red team engagement** shifts the goal from "find as many vulnerabilities as possible" to "achieve a specific adversarial objective (e.g., reach domain admin, exfiltrate a specific data type, compromise a crown-jewel system) while evading detection," and it often tests the defensive team's (blue team's) detection and response capability as much as it tests the technical environment — frequently only a small group within the organization (white cell) knows it's happening. A **bug bounty** is an ongoing, crowdsourced, scope-defined program where independent researchers submit individual vulnerabilities for a reward, without the structured timeline, narrative reporting, or holistic risk-based approach of a formal pentest — it's optimized for finding discrete bugs at scale rather than assessing an organization's overall security posture.

</details>

<details>
<summary><b>❓ What is the difference between black box, white box, and grey box testing?</b></summary>

This describes how much information and access the tester is given up front. **Black box** testing simulates an external attacker with no prior knowledge — the tester starts from just a company name or URL and has to do full reconnaissance, which is realistic but time-consuming and can miss issues simply due to time constraints. **White box** (or "crystal box") testing gives the tester full information up front — source code, architecture diagrams, credentials, network maps — which allows for much deeper, more efficient coverage and is common in application security reviews or when the client wants maximum depth in a limited timeframe. **Grey box** testing sits in between: the tester might be given standard user credentials, a general network diagram, or limited documentation, simulating an insider threat or a compromised low-privilege account, and it's often considered the best value for a standard engagement because it balances realism with efficient time usage. In an interview I'd note that the choice between these isn't about which is "better" in the abstract — it depends entirely on what question the client is trying to answer.

</details>

<details>
<summary><b>❓ How do you scope an engagement, and why does scope matter so much?</b></summary>

Scoping means precisely defining what is and isn't authorized before any technical work begins: which IP ranges, domains, applications, or physical locations are in scope; which are explicitly excluded; what testing types are allowed (e.g., is denial-of-service testing permitted, is social engineering permitted, is testing against production allowed or only staging); what time windows testing may occur in; and who the emergency points of contact are on both sides. Scope matters because anything done outside it is, legally and ethically, unauthorized computer access — even if done with good intentions, testing a system that wasn't explicitly authorized can expose the tester and their employer to civil or criminal liability, and it can also cause real operational harm to a system nobody agreed to have tested (e.g., a shared hosting IP that also serves a third party's production traffic). A precise scope also protects the client, ensuring testing doesn't touch systems or data they didn't intend to expose.

</details>

<details>
<summary><b>❓ What are "rules of engagement" (RoE) and why do they matter?</b></summary>

The rules of engagement is the formal document that governs how testing will actually be conducted within the agreed scope: permitted attack techniques, blackout windows or maintenance periods to avoid, explicit handling instructions for sensitive data encountered, escalation procedures if something goes wrong (e.g., a service crashes or a critical live issue is found), communication cadence, and — critically — a "get out of jail" clause referencing the signed authorization. The RoE is what separates a penetration test from a crime: it's the documented, mutually agreed proof that the target organization consented to specific testing activities. In an interview, I'd stress that no competent tester begins any technical work — not even a passive Nmap scan — without a signed authorization letter or contract in hand, because good intent is not a legal defense for unauthorized access under most computer misuse laws.

</details>

<details>
<summary><b>❓ If you discover a system or asset during testing that appears to be out of scope, what do you do?</b></summary>

Stop testing against that asset immediately and do not interact with it further beyond what's needed to confirm it's genuinely out of scope. Document what was observed (how it was discovered, e.g., it resolved from an in-scope domain, or appeared in a routing table) and report it to the client point of contact promptly, asking whether they want it added to scope via a documented scope-change/change-control process. The core principle is that authorization is asset-specific and testers don't get to expand it unilaterally just because they stumbled onto something interesting — even a good-faith curiosity click can create legal exposure for both the tester and the client if that system belongs to a third party (e.g., a shared cloud IP or CDN edge).

</details>

<details>
<summary><b>❓ What would you do if, mid-engagement, you found a critical vulnerability that's actively being exploited or poses immediate danger to production (e.g., a live active breach, or a change that could take down production)?</b></summary>

This calls for immediate out-of-band communication rather than waiting for the final report. Most engagement contracts include an emergency escalation clause for exactly this scenario, so I'd stop further testing against that specific finding to avoid making things worse, and immediately contact the client's designated emergency point of contact (phone/direct message, not just an email that might sit unread) with a concise description of the issue, evidence, and potential impact. If I discover indicators that suggest an actual ongoing compromise by a third party (not something I caused), that's treated as a suspected active incident and gets escalated immediately, since the organization's ability to respond to a real breach takes priority over the schedule of the engagement. Everything is then documented — what was found, when, who was notified, and what was recommended — both for the final report and to protect all parties involved.

</details>

---


## 🔍 Reconnaissance & OSINT


<details>
<summary><b>❓ What's the difference between passive and active reconnaissance, and why does the distinction matter?</b></summary>

Passive reconnaissance gathers information about a target without directly interacting with their systems in a way that would appear in their logs — think WHOIS lookups, DNS history databases, search engine dorking, certificate transparency logs, social media, job postings, and public code repositories. Active reconnaissance involves direct interaction with the target's infrastructure — port scanning, banner grabbing, DNS zone transfer attempts — which can potentially be detected and logged by the target. The distinction matters practically (passive recon can often be done before authorization is finalized or scope is fully locked down, since it touches third-party sources rather than the target directly) and tactically (a stealthier engagement, especially a red team simulation, will lean much more heavily on passive techniques to build a target profile before ever touching the client's network, minimizing the chance of early detection).

</details>

<details>
<summary><b>❓ What OSINT techniques and sources do you use early in an engagement?</b></summary>

I'd describe a layered approach. For **organizational footprinting**: WHOIS records for registration and contact details, certificate transparency logs (crt.sh and similar) to enumerate subdomains from issued TLS certificates, DNS records (MX, TXT/SPF records revealing mail and cloud providers, historical DNS via passive DNS databases), and search engine dorking (`site:`, `filetype:`, `intitle:` operators) to find exposed documents, login portals, or misconfigured directories indexed by search engines. For **people and social engineering prep**: LinkedIn and other professional networks to map org structure and identify likely usernames/naming conventions, job postings (which often leak internal technology stack details — "must have experience with X VPN and Y ticketing system"), and breach/credential exposure databases to check whether employee credentials have appeared in past breaches (useful for password spraying likelihood, not for directly reusing found passwords without authorization). For **technical footprinting**: GitHub/GitLab searches for leaked API keys, internal hostnames, or config files accidentally committed by employees, and Shodan/Censys-style internet-wide scan databases to see what the organization already exposes without touching it directly myself. The unifying theme is: build as complete a picture as possible using only sources that don't require touching the target's own infrastructure.

</details>

<details>
<summary><b>❓ How would you enumerate an organization's subdomains and external attack surface?</b></summary>

I'd combine several complementary techniques since no single source is complete. Certificate transparency logs are extremely effective because every publicly trusted TLS certificate is logged publicly, often revealing subdomains before they're even linked anywhere. DNS brute-forcing with common subdomain wordlists against the target's authoritative nameservers can reveal additional names not present in certificate logs. Search engine and public-repository dorking can surface subdomains referenced in code, documentation, or cached pages. Passive DNS aggregators (services that log historical DNS resolutions across the internet) can reveal subdomains that existed in the past, which is useful for finding forgotten or decommissioned assets that might still be live and unpatched. Once a subdomain list is built, I'd resolve them all to check which are actually live, then fingerprint the web technology stack on each (server headers, JS frameworks, CMS signatures) to prioritize which look most interesting or most likely to be outdated. This whole surface-mapping step is what turns "example.com" into a concrete list of hosts to scan and enumerate next.

</details>

<details>
<summary><b>❓ Why is username/email enumeration valuable to an attacker, and how might it be done?</b></summary>

Valid usernames are often the single biggest force-multiplier for later attacks, because most authentication-based attacks (password spraying, credential stuffing, phishing) are far more efficient against a confirmed list of valid accounts than a guess-everything approach. Emails and usernames can be harvested from company websites (staff directories), LinkedIn (name to standard corporate-format inference, e.g., first.last@domain), breach databases, document metadata (author fields in PDFs/Office docs revealing internal usernames), and sometimes directly from service login pages or APIs that behave differently for valid vs. invalid accounts (a classic user-enumeration vulnerability, e.g., "invalid password" vs. "no such user" error messages, or timing differences between the two). Interviewers often want to hear that you understand this as a chained technique: recon produces a candidate username list, which then feeds into a carefully rate-limited, low-and-slow password spray (a small number of common passwords tried against many accounts, staying under lockout thresholds) rather than a noisy brute force against one account, since a slow spray is both more effective and much less likely to trigger lockouts or alerting.

</details>

---


## 📡 Scanning & Enumeration


<details>
<summary><b>❓ What are the main Nmap scan types and when would you use each?</b></summary>

Nmap's scan types trade off speed, stealth, and accuracy differently, and knowing when to reach for each shows practical experience rather than memorized flags.

| Flag | Scan type | Notes |
|---|---|---|
| `-sS` | TCP SYN scan ("half-open") | Default for privileged users; fast, doesn't complete the full TCP handshake, relatively stealthy against basic logging |
| `-sT` | TCP connect scan | Completes full handshake; used when raw socket privileges aren't available; noisier, shows up in application-level logs |
| `-sU` | UDP scan | Much slower and less reliable (no handshake, relies on ICMP unreachable responses); essential for DNS, SNMP, DHCP discovery |
| `-sV` | Version detection | Probes open ports to identify service and version banners |
| `-sC` | Default script scan | Runs a curated set of safe NSE scripts for extra enumeration |
| `-sN`/`-sF`/`-sX` | Null/FIN/Xmas scans | Manipulate TCP flags to try to evade simple stateless filtering; unreliable against modern stacks |
| `-A` | Aggressive | Combines OS detection, version detection, script scanning, and traceroute |
| `-p-` | All 65535 ports | Full port sweep instead of the default top-1000 |
| `-O` | OS detection | Fingerprints the target's TCP/IP stack behavior |
| `-T0`–`T5` | Timing templates | Controls scan speed/aggressiveness, from paranoid (`-T0`, very slow, IDS-evasive) to insane (`-T5`) |

In practice, I'd typically start with a fast SYN scan across all ports to find what's open (`-sS -p- -T4`), then run a targeted, deeper scan (`-sV -sC`) against just the discovered open ports to get service and version detail without wasting time re-scanning everything at full depth. UDP scanning gets its own pass since it's slow and would bottleneck a combined scan. I'd also mention that on an authorized internal engagement I generally don't worry heavily about scan stealth flags (`-T0`, decoys, fragmentation) unless the objective specifically calls for evading detection — for a standard pentest, speed and completeness usually matter more than stealth, whereas a red team engagement flips that priority.

</details>

<details>
<summary><b>❓ How do you enumerate an SMB service, and what are you looking for?</b></summary>

SMB enumeration is one of the highest-value targets on an internal Windows-heavy network because misconfigurations there routinely lead directly to credentials or code execution. I'd start by checking the SMB version and whether null sessions or guest access are permitted (older or misconfigured servers sometimes allow anonymous connections that reveal share names, user lists, and even password policy). Next, I'd enumerate available shares and their permissions, looking for shares that are readable/writable by low-privileged or anonymous users — these often contain scripts, configuration files, or backups with embedded credentials, or, if writable, offer a path to plant a malicious file an administrator might execute. I'd also check for known SMB-level vulnerabilities relevant to the detected version (SMB signing disabled is notable because it enables relay attacks), enumerate domain users and groups if the server is domain-joined and enumeration is permitted, and check the OS/patch level implied by the SMB dialect and any exposed version banners against known critical vulnerabilities. Tools that come up here include `smbclient` for interactive share browsing, `enum4linux`/`enum4linux-ng` for consolidated null-session enumeration, and Nmap's SMB NSE scripts for a quick automated pass.

</details>

<details>
<summary><b>❓ How do you enumerate an FTP service?</b></summary>

FTP enumeration starts with checking whether anonymous login is permitted (a surprisingly common finding, since `anonymous`/blank-password access is sometimes left enabled on internal file servers), and if so, browsing the directory tree for sensitive files, backups, or credentials left behind. I'd note the FTP server software and version from the banner and check it against known vulnerabilities for that specific build. I'd also check whether the server supports active vs. passive mode oddities that matter for scanning through firewalls, and whether it's plaintext FTP vs. FTPS/SFTP, since plaintext FTP transmitting credentials is itself a finding worth reporting even without a specific exploit. Beyond anonymous access, weak or default credentials are common enough on FTP services that a careful, rate-limited credential check against a small list of common defaults is often worthwhile if in scope.

</details>

<details>
<summary><b>❓ What's your general approach to enumerating a web application before attempting any exploitation?</b></summary>

Before touching anything resembling an attack, I map the application's structure and technology as thoroughly as possible. That includes identifying the web server, framework, and CMS in use (via headers, error pages, and telltale file paths), discovering the directory/file structure through crawling and directory brute-forcing (looking for admin panels, backup files, exposed `.git` directories, or forgotten debug endpoints), and enumerating input surfaces — every form, URL parameter, API endpoint, header, and cookie that accepts user-controlled input, since each of those is a potential injection point later. I'd also review client-side code (JavaScript bundles) for hardcoded API keys, hidden endpoints, or comments revealing internal logic, check for exposed version-control artifacts or backup files that might leak source code, and identify the authentication and session-management mechanism in use (cookie-based sessions, JWTs, OAuth flows) since that shapes which attack classes are relevant later. Only once I have a solid map of the application's surface do I start layering in actual attack testing against specific inputs, because testing blindly without this mapping wastes time and risks missing entire sections of functionality.

</details>

<details>
<summary><b>❓ What's the difference between running a vulnerability scanner and doing manual testing, and why do you need both?</b></summary>

An automated vulnerability scanner is extremely good at breadth and consistency: it can check a huge number of hosts against a huge signature/plugin database quickly, catching known CVEs, missing patches, default credentials, and common misconfigurations far faster than a human could. But scanners are pattern-matchers — they're weak at understanding business logic, chaining multiple low-severity issues into a high-impact attack path, and adapting to anything nonstandard, and they produce both false positives (flagging something that isn't actually exploitable in context) and false negatives (missing logic flaws or novel issues that don't match a known signature). Manual testing is what a human tester adds: understanding what the application is actually trying to do and finding ways to abuse that logic (e.g., an authorization check that works correctly on the page you're shown but can be bypassed by directly calling an API endpoint), chaining a "low" finding with another "low" finding to produce a "critical" impact, and validating that a scanner's finding is a real, exploitable issue rather than noise. In practice, a good engagement uses scanning to efficiently cover breadth and free up time, then applies manual expertise where it adds the most value — this is also a common interview trap question, since saying "the scanner does everything" is a red flag for hiring managers, while overstating "scanners are useless" ignores their real efficiency value.

</details>

<details>
<summary><b>❓ How do you enumerate a database service you find exposed (e.g., MySQL, MSSQL, Redis) during a scan?</b></summary>

I'd first confirm the service and version via banner/handshake, then check whether authentication is required at all — exposed databases with no authentication, or with default/blank credentials, are a very common and severe finding, especially for services like Redis or MongoDB that historically shipped without authentication enabled by default. If credentials are required, I'd check for default vendor credentials before attempting anything more aggressive, since scope and rules of engagement typically limit how much active brute-forcing is appropriate. Once any access is available (even low-privilege), I'd enumerate accessible databases/schemas, look at stored procedures or extended functionality that might allow command execution (e.g., certain MSSQL configurations allow executing OS commands through extended stored procedures if enabled), and evaluate the network exposure itself as a finding — a database that should only be reachable from an application server but is instead reachable from the broader network or the internet is a significant misconfiguration worth reporting even before any credential issue is considered.

</details>

---


## 💥 Vulnerability Assessment & Exploitation


<details>
<summary><b>❓ How do you decide which vulnerability to attempt to exploit first when a scan returns many findings?</b></summary>

I prioritize by realistic impact and likelihood rather than raw scanner severity scores alone, since CVSS base scores don't account for context like network exposure or compensating controls. Practically, I'd weigh: exploitability (is there a public, reliable proof-of-concept, or does the attack require unusual conditions), impact if successful (does it lead to remote code execution or just information disclosure), exposure (is the vulnerable service internet-facing or only reachable internally, and is it a stepping stone toward a high-value target like a domain controller), and engagement time constraints (a reliable, quick win that establishes initial foothold is often worth more early in a time-boxed engagement than chasing a more severe but unreliable exploit that might burn hours without success). I'd also mention that in a real engagement, I'd rather have one confirmed, cleanly demonstrated critical finding with solid evidence than several unconfirmed "maybe" findings, because reproducibility and clear proof are what make a report actionable and credible to the client.

</details>

<details>
<summary><b>❓ From an offensive tester's practical workflow, how do you actually go about testing for common web vulnerability classes like injection, broken access control, and SSRF, rather than just naming them?</b></summary>

Rather than re-deriving each vulnerability class from scratch, I'd frame this as workflow: for **injection** (SQL, command, template, etc.), the process is to identify every input that reaches a backend interpreter, then send controlled probing payloads (a single quote, a boolean-altering condition, a deliberate syntax break) and observe whether the application's behavior, error output, or response timing changes in a way that indicates the input reached an interpreter unsafely — from there it's a matter of confirming with a safe proof (e.g., a time-delay payload proving blind injection, or extracting a single, low-sensitivity piece of data) rather than immediately going for maximum extraction, since the goal in an authorized test is proof of impact, not data exfiltration for its own sake. For **broken access control**, the core technique is comparing what the UI presents to a given role against what the backend actually enforces — testing whether a lower-privileged user's token/session can access another user's resource (horizontal privilege escalation, e.g., changing an ID parameter) or an admin-only function (vertical privilege escalation) by directly calling the API rather than going through the UI that would normally hide that option. For **SSRF**, it's about finding any feature where the server itself fetches a URL supplied fully or partially by the user (webhooks, PDF generators, image-from-URL uploaders, link previewers) and testing whether that fetch can be redirected to internal-only addresses, cloud metadata endpoints, or other backend services the attacker couldn't otherwise reach directly. Across all of these, the common thread I'd want to convey is that exploitation is really a structured, hypothesis-driven process — form a hypothesis about what the backend does with an input, test it with the minimum payload needed to confirm or refute it, then escalate the proof only as far as needed to demonstrate real impact.

</details>

<details>
<summary><b>❓ What's the difference between a CVE, a CVSS score, and an exploit/PoC, and how do they relate during an assessment?</b></summary>

A **CVE** (Common Vulnerabilities and Exposures) is simply a standardized identifier for a specific, publicly disclosed vulnerability, giving everyone a shared reference number instead of ambiguous descriptions. **CVSS** (Common Vulnerability Scoring System) is a scoring framework that produces a numeric severity rating (roughly 0–10) based on metrics like attack vector, complexity, privileges required, and impact on confidentiality/integrity/availability — it's meant to communicate relative severity, not to replace contextual judgment, which is why a CVSS 9.8 finding on an isolated, non-critical test server might be reported with a lower business risk rating than the raw score suggests. An **exploit or proof-of-concept (PoC)** is the actual code or technique that demonstrates the vulnerability can be triggered — some CVEs have public, reliable exploits available (making them low-effort/high-value targets), while others are only theoretically described with no working exploit publicly available, requiring the tester to develop or adapt one, which is a meaningfully higher-effort undertaking. In an assessment I'd use the CVE to research the issue, the CVSS score as a starting point for prioritization (adjusted with environmental context), and the availability/reliability of a PoC as a major factor in deciding how much time to invest in confirming exploitability.

</details>

<details>
<summary><b>❓ What's the difference between exploiting a vulnerability and simply identifying it, and why does that distinction matter to a client?</b></summary>

Identifying a vulnerability means recognizing that a weakness exists — for instance, noticing a service is running a version with a known critical CVE. Exploiting it means actually demonstrating that the weakness can be leveraged to achieve real impact — gaining code execution, extracting data, or bypassing a control — under the actual conditions of that specific environment. The distinction matters enormously to a client because many "vulnerable version" findings turn out to be non-exploitable in practice due to compensating controls, configuration differences, or the environment simply not meeting the exploit's prerequisites, and a report that treats every identified-but-unconfirmed issue as equally urgent wastes the client's remediation effort on false urgency while potentially under-communicating the real, confirmed critical issues. A mature tester is explicit in the report about which findings were actually exploited and proven, versus which are identified-but-unconfirmed (often due to being risky to test against production, e.g., a potential denial-of-service condition) and marked as such with reasoning for why they're still worth fixing.

</details>

<details>
<summary><b>❓ How do you approach testing for weak or default credentials responsibly?</b></summary>

Credential testing needs to be scoped and rate-limited carefully because it's one of the easiest ways to accidentally cause harm — a fast, unthrottled brute force can lock out real user accounts (a self-inflicted denial of service) or trip alerting/lockout thresholds that generate noise for the client's operations team without producing much testing value. My approach is to first check documented or well-known default credentials for the specific product/version identified, since those are the highest-value, lowest-risk checks. If a broader password spray is in scope, I'd use a small, curated list of very common passwords against a wide set of usernames (rather than many passwords against one account), spaced out to stay well under typical lockout thresholds, since spraying trades speed for safety and is both stealthier and less disruptive. I'd always confirm the rules of engagement specifically address whether account lockout/credential testing is permitted and against which systems, since testing against an authentication system tied to a production SSO or a system with a strict lockout policy can have real business impact if done carelessly.

</details>

---


## ⬆️ Post-Exploitation & Privilege Escalation


<details>
<summary><b>❓ What's the general goal and mindset shift once you have initial access to a system?</b></summary>

Initial access — landing a low-privilege shell or foothold — is rarely the end goal; the mindset shifts to establishing situational awareness and determining what that access is actually worth. That means enumerating the compromised host thoroughly (user context, privileges, running processes, installed software, network connections, stored credentials, and how the host relates to the rest of the environment), and evaluating it against the engagement's actual objectives — is this host a dead end, or does it provide a path toward a higher-value target (a domain controller, a database with sensitive records, an admin workstation)? I'd also stress operational care here: post-exploitation activity is where a tester can do real, unintended damage if careless (crashing a service, modifying production data, degrading performance on a shared/critical system), so every subsequent action should be deliberate, minimally invasive, and clearly tied to demonstrating impact for the report rather than "seeing how far I can go" for its own sake.

</details>

<details>
<summary><b>❓ Conceptually, what are the main categories of Windows privilege escalation techniques?</b></summary>

At a conceptual level, Windows privilege escalation techniques generally fall into a few buckets. **Missing patches / kernel exploits** — an unpatched OS build vulnerable to a known local privilege escalation flaw in the kernel or a core OS component, discovered by comparing the patch level against a database of known local-privesc CVEs. **Misconfigured services** — services running as SYSTEM but with weak file/folder permissions on their executable or configuration (allowing a low-privileged user to replace the binary the service runs), or services with unquoted paths containing spaces (e.g., `C:\Program Files\My App\service.exe`, which Windows may try to resolve segment-by-segment, allowing a maliciously placed `C:\Program.exe` to be executed instead if the tester has write access to an intermediate directory) — both ultimately trick a higher-privileged service into running attacker-controlled code. **Weak permissions on registry keys or scheduled tasks** that run with elevated privileges, similarly allowing substitution of what gets executed. **Excessive user privileges/token abuse** — certain Windows privileges assigned to a service or user account (such as ones allowing impersonation of other tokens) can be abused to escalate to SYSTEM if the account holding them is compromised. **Credential exposure** — plaintext or recoverable credentials sitting in configuration files, scripts, registry autologon entries, or memory, which may belong to a higher-privileged account. And **AlwaysInstallElevated** or similar policy misconfigurations that let any user install packages with SYSTEM-level privileges. In an interview, I'd emphasize that the actual workflow is running structured enumeration (checking service permissions, scheduled tasks, installed software versions, stored credentials, current user's group memberships and rights) rather than guessing, since privilege escalation is fundamentally a systematic enumeration problem before it's an exploitation problem.

</details>

<details>
<summary><b>❓ Conceptually, what are the main categories of Linux privilege escalation techniques?</b></summary>

Similarly, Linux privesc breaks down into recognizable categories. **Kernel exploits** — an outdated kernel vulnerable to a known local privilege escalation CVE. **SUID/SGID binaries** — executables that run with the file owner's (often root's) privileges regardless of who runs them; if such a binary can be manipulated to execute arbitrary commands (either because the binary itself is known to be exploitable for this purpose, or because it can be pointed at an unintended input/output), it can yield a root shell — this is why checking for unusual SUID binaries against a known list of GTFOBins-style abusable binaries is a standard early step. **Misconfigured sudo permissions** — a user allowed to run specific commands as root via `sudo` without a password, where that command (or a flaw in how it's invoked, such as a wildcard or an editor with shell-escape capability) can be leveraged to gain a full root shell rather than just the intended narrow function. **Writable/weak file permissions** on sensitive files — a world-writable `/etc/passwd`, cron job scripts owned by root but writable by a lower-privileged user, or writable systemd service files, all of which let an attacker inject code that will later run as root. **Exposed credentials** — SSH private keys, database credentials, or API tokens left in world-readable config files, shell history, or environment variables. **Path manipulation** — if a script run by a privileged cron job or process calls a binary without a fully qualified path and the attacker can influence the `PATH` variable or write to a directory earlier in the search path, they can substitute a malicious binary. As with Windows, the practical approach is running a structured enumeration pass (checking `sudo -l`, SUID binaries, cron jobs, writable files owned by root, kernel/OS version) rather than trying exploits blindly.

</details>

<details>
<summary><b>❓ What's the difference between vertical and horizontal privilege escalation?</b></summary>

Vertical privilege escalation means moving from a lower privilege level to a higher one on the same system or within the same trust boundary — for example, going from a standard user to root/SYSTEM, or from a regular application user to an admin role within a web app. Horizontal privilege escalation means gaining access to resources or capabilities belonging to a different user or account at the same privilege level — for example, one standard user accessing another standard user's files or data without authorization. Both matter in an assessment: vertical escalation is usually the headline finding on a host-based engagement (full system compromise), while horizontal escalation is extremely common and impactful in web application testing (e.g., user A viewing user B's private data by manipulating an ID parameter), and reports should be precise about which type a given finding represents since the risk narrative differs.

</details>

<details>
<summary><b>❓ What is credential dumping, and why is it such a high-value post-exploitation technique?</b></summary>

Credential dumping refers to extracting authentication material — password hashes, plaintext passwords, cached credentials, session tokens, or Kerberos tickets — from a compromised system's memory, disk, or configuration, typically from the operating system's credential storage mechanisms or from applications that retain credentials for convenience. It's high-value because credentials are directly reusable: a set of dumped hashes or tickets from one compromised host can often be used to authenticate to other systems in the environment (sometimes even without cracking the hash, via pass-the-hash or similar techniques where the hash itself functions as the credential to the protocol), turning a single foothold into access across many systems, especially in Windows/Active Directory environments where credential and privilege reuse across machines is extremely common. From a defensive-implication standpoint (relevant even in an offensive interview), this is exactly why practices like unique local administrator passwords per machine and privileged access workstations exist — to prevent one dumped credential set from cascading into a full environment compromise.

</details>

---


## 🔄 Lateral Movement, Pivoting & Persistence


<details>
<summary><b>❓ What is pivoting, and how does it differ from simple lateral movement?</b></summary>

Pivoting is the technique of using a compromised host as a relay point to reach other systems that aren't directly reachable from the tester's original attacking position — for example, a compromised web server sitting in a DMZ might have network access to an internal segment that the tester's own machine can't route to directly, so traffic is tunneled or proxied through the compromised host to reach that internal network. Lateral movement is the broader concept of moving from one compromised system to another within an environment, regardless of whether network routing/tunneling is involved — pivoting is really a specific technical mechanism (routing traffic through a compromised host) that enables lateral movement into network segments that would otherwise be unreachable. In practice they're closely related: after gaining initial access, a tester often needs to pivot just to be able to scan and enumerate the next network segment at all, and only once that traffic path exists does further lateral movement into that segment become possible.

</details>

<details>
<summary><b>❓ What techniques are commonly used to move laterally within a Windows/Active Directory environment?</b></summary>

Common techniques include reusing harvested or dumped credentials against other hosts (since credential reuse across machines is extremely common in poorly segmented environments), pass-the-hash style techniques where a captured password hash is used to authenticate to other systems without ever needing the plaintext password, abusing legitimate remote administration protocols (remote service management, remote scheduled task creation, WMI, PowerShell remoting) with valid or harvested credentials to execute code on other hosts, and exploiting trust relationships within Active Directory itself (for example, a service account with excessive privileges across multiple systems, or delegation misconfigurations that allow impersonating other users' access). A key theme I'd raise in an interview is that a huge proportion of real-world lateral movement in Windows environments relies on legitimate, built-in administrative functionality rather than exotic exploits — it's less about "hacking" the next machine and more about the attacker now holding credentials or tokens that are already trusted by that machine, which is exactly why detecting lateral movement is hard for defenders and why least-privilege and credential hygiene matter so much.

</details>

<details>
<summary><b>❓ What does "maintaining access" / persistence mean in an offensive context, and what techniques achieve it?</b></summary>

Persistence refers to establishing a way to regain access to a compromised system without having to repeat the initial exploitation, which matters for red team engagements simulating an adversary who needs reliable long-term access, and for demonstrating to a client what a real attacker's dwell time might look like. Conceptually, common mechanisms include: scheduled tasks/cron jobs that periodically re-establish a connection back to the tester, modified startup items or services that launch automatically on boot, added or modified user accounts (or added SSH keys/authorized credentials), registry run keys or startup folder entries on Windows, and web shells left on compromised web servers for continued access. In an interview, I'd note the important caveat that persistence mechanisms should only be used when explicitly scoped into the engagement (this is standard for red team engagements but not typical for a straightforward penetration test), and that anything installed for persistence must be tracked meticulously and fully removed/documented at the end of the engagement — leaving a backdoor behind, even an authorized test one, that isn't properly cleaned up is a serious professional failure.

</details>

<details>
<summary><b>❓ What is "clearing tracks" / anti-forensics, and why is it usually NOT appropriate in a standard authorized engagement?</b></summary>

Clearing tracks refers to techniques a genuine malicious attacker uses to remove or manipulate log data, timestamps, and other forensic evidence of their activity to evade detection and complicate incident response. In a standard authorized penetration test, this is almost always inappropriate and often explicitly prohibited by the rules of engagement, for a few concrete reasons: the client needs accurate logs to evaluate their own detection and response capability as part of the engagement's value (deleting evidence defeats that purpose), tampering with production logs can have legal and operational consequences the client didn't consent to, and it removes the client's ability to distinguish tester activity from a genuine concurrent attacker if one happens to be active in the environment at the same time. The one context where deliberate evasion of detection is a legitimate, in-scope objective is a red team engagement specifically designed to test detection and response capability — but even there, the objective is to avoid detection during the test, not to destroy the evidence trail afterward, and testers still maintain their own detailed internal activity log throughout, and any log manipulation performed as a demonstrated technique is explicitly disclosed and reversed/documented at the end. The overarching principle: authorized testing is meant to improve the client's security, and destroying the evidence of what happened works directly against that goal.

</details>

---


## 📝 Reporting & Professional Practice


<details>
<summary><b>❓ What makes a good penetration test report, and how do you write for both a technical and an executive audience?</b></summary>

A good report serves two very different readers, and trying to write one section that satisfies both usually satisfies neither. The **executive summary** is written for decision-makers — often non-technical — and should communicate business risk in plain language: what was tested, what the overall security posture looks like, the most critical risks in terms of what they mean for the business (financial loss, data exposure, regulatory exposure, reputational harm) rather than technical jargon, and a high-level view of how many findings fell into each severity category. The **technical findings section** is written for the engineers and administrators who will actually fix the issues, and needs to be precise and reproducible: a clear title and severity rating, a description of the vulnerability, the specific affected asset/endpoint, step-by-step reproduction instructions, supporting evidence (screenshots, request/response captures, command output), a CVSS score with the vector string for transparency, and — critically — a specific, actionable remediation recommendation rather than a generic "patch your systems" statement. I'd emphasize that a report's real value is measured by how easily it lets the client's team reproduce and fix the issue without needing the tester to explain it verbally afterward, and that vague or unreproducible findings undermine the credibility of the whole report.

</details>

<details>
<summary><b>❓ How do you determine and communicate severity/risk ratings for findings?</b></summary>

I use CVSS as a structured, defensible starting point since it standardizes the conversation around a consistent set of metrics (attack vector, attack complexity, privileges required, user interaction, and impact on confidentiality/integrity/availability), but I always adjust the final reported risk rating with real environmental context rather than reporting the raw base score blindly — a finding with a high CVSS base score on an isolated, non-critical internal test system might carry a genuinely lower risk to the business than a moderate-CVSS finding on an internet-facing system handling regulated customer data. I'd also factor in exploitability in practice (was it actually demonstrated, or is it theoretical based on version alone), ease of exploitation (does it require an authenticated insider or is it reachable from the internet with no prerequisites), and potential business impact specific to that client (what does this system actually do for them). Being explicit about this adjustment process in the report — showing the CVSS score alongside the contextual reasoning for the final rating — builds credibility with technical readers who might otherwise just check the score against their own judgment.

</details>

<details>
<summary><b>❓ How do you write remediation recommendations that are actually useful to a client?</b></summary>

Effective remediation guidance is specific, prioritized, and grounded in what's realistically achievable, not just "apply best practices." For each finding, I'd give a concrete recommended fix (the specific patch/version to update to, the specific configuration setting to change, the specific code-level fix pattern for an application flaw) rather than a vague directive, and where there are multiple valid approaches, I'd note a quick tactical mitigation (e.g., a WAF rule or access restriction as an immediate stopgap) separately from the proper long-term fix (e.g., a code change) since clients often need to reduce risk immediately while a full fix goes through their normal change-management process. I'd also group related findings and point out root causes where relevant — if five findings all stem from the same underlying issue (e.g., a shared, outdated framework, or an absent input-validation layer), calling that out explicitly is far more valuable to the client than five isolated tickets that each get fixed in a way that doesn't address the systemic problem. Good remediation advice ultimately treats the client as a partner trying to reduce risk efficiently, not just a scoreboard of findings to close out.

</details>

<details>
<summary><b>❓ Why does written authorization matter so much before conducting any offensive security testing?</b></summary>

Written authorization is the single thing that separates lawful penetration testing from criminal computer intrusion under most jurisdictions' computer misuse and unauthorized access laws — intent and good faith are generally not a legal defense if the access itself wasn't authorized by someone with the legitimate authority to grant it. A signed authorization/statement of work needs to clearly define scope (exactly what systems/networks/apps), the authorized testing window, the specific individual(s) with authority to grant that permission (ideally someone who actually owns or has clear authority over the systems in question, not just anyone at the company), and it typically includes a "get out of jail free" clause the tester can produce if law enforcement or a third party questions the activity mid-engagement. Beyond the legal necessity, written authorization also protects the client by forcing an explicit, deliberate conversation about scope and risk tolerance before testing begins, rather than leaving those decisions ambiguous. In an interview, stating plainly that you'd never begin testing — not even passive recon against a live target's infrastructure — without this in hand is one of the clearest signals of professional maturity a hiring panel is listening for.

</details>

<details>
<summary><b>❓ How do you handle sensitive data you encounter during an engagement (e.g., customer PII, financial records, credentials)?</b></summary>

Sensitive data encountered during testing is handled with minimal necessary interaction and strict confidentiality: I'd only access enough of it to confirm and document the vulnerability (proof of access/impact) rather than exfiltrating, copying, or reviewing more than necessary, since the goal is to demonstrate risk, not to actually violate the privacy the vulnerability threatens. Screenshots or evidence captured for the report get sensitive fields redacted or use clearly synthetic/sample records where possible rather than including full real records. Any credentials discovered during testing are handled carefully — not reused beyond what's needed to demonstrate the specific finding, and reported to the client promptly rather than sat on. All engagement data (findings, evidence, credentials, client information) is stored and transmitted securely (encrypted storage, secure delivery channels for the final report) and disposed of according to the data handling terms agreed in the contract, often including a formal data-destruction confirmation once the engagement and any retest period are complete. This is also a topic where I'd reference the underlying principle rather than memorized steps: proportionality — access and retain only what's needed to prove the point, nothing more.

</details>

<details>
<summary><b>❓ What's the difference between a finding being "theoretical" versus "confirmed/exploited," and why should a report distinguish them?</b></summary>

A theoretical finding is one identified through indicators like a version banner matching a known vulnerable release, without the tester actually triggering or proving the vulnerability in that specific environment — it's a strong hypothesis, not a demonstrated fact. A confirmed finding is one the tester has actually exploited or otherwise concretely validated in that environment, with evidence to show for it. This distinction should always be explicit in a report because it changes both the confidence a client should place in the finding and, often, its prioritization — while both may warrant fixing, a client's remediation team benefits from knowing which findings have concrete proof driving their urgency versus which are prioritized based on inferred risk, especially since compensating controls or environmental differences sometimes mean a theoretically vulnerable version isn't actually exploitable in that specific deployment. Reporting both with equal false certainty erodes trust the first time a client's team investigates a "critical" finding and discovers it wasn't actually exploitable as described.

</details>

<details>
<summary><b>❓ How do you stay current and keep building offensive security skills outside of formal engagements?</b></summary>

I'd point to a mix of hands-on practice and structured learning: working through intentionally vulnerable practice environments and lab platforms to build and refresh technical muscle memory in a fully legal setting, following vulnerability disclosures and technical write-ups to understand how new classes of bugs are found and exploited, contributing to or reading open-source security tooling to understand how techniques are actually implemented under the hood rather than just knowing tool names, and — where personally authorized — participating in bug bounty programs against explicitly in-scope targets as a way to apply skills against real-world systems under clear legal terms. I'd also mention pursuing structured certifications (which demonstrate a baseline of validated, tested knowledge to employers) alongside self-directed lab work, since certifications alone tend to reward methodology and tool familiarity while hands-on practice against varied, unpredictable environments is what actually builds the adaptive problem-solving skill the job requires day to day.

</details>

<details>
<summary><b>❓ What separates a junior penetration tester from a more senior one, in your view?</b></summary>

Technically, a junior tester tends to be tool-driven — running a known checklist of scanners and scripts and reporting what they output — while a senior tester is methodology-driven, using tools as one input into a broader hypothesis-and-verification process, and is comfortable when a tool doesn't have a ready answer and manual analysis is required. Seniority also shows in judgment: knowing when a finding needs deeper investigation versus when it's genuinely low-risk in context, understanding second-order consequences of an action before taking it (will this crash a production service, will this trip a lockout that impacts real users), and communicating findings in a way that's calibrated to actual business risk rather than technical severity alone. Professionally, seniority shows in how someone handles scope and ethics under pressure — for instance, correctly stopping and escalating instead of pushing further when something looks like it might be out of scope or might cause real harm, even when technically "just one more step" would have been possible. I'd frame this as: junior testers find vulnerabilities, senior testers manage risk and communicate it effectively — the technical skill is necessary but the professional judgment is what actually differentiates experience level.

</details>

---


## 📌 Quick Reference Tables


**Nmap scan types (quick recall)**

| Flag | Purpose |
|---|---|
| `-sS` | SYN ("half-open") scan, fast and default for privileged scans |
| `-sT` | Full TCP connect scan, no raw socket privileges needed |
| `-sU` | UDP scan, slow, needed for DNS/SNMP/DHCP-type services |
| `-sV` | Service/version detection |
| `-sC` | Default NSE script scan |
| `-O` | OS fingerprinting |
| `-A` | Aggressive (OS + version + scripts + traceroute) |
| `-p-` | Scan all 65535 ports |
| `-T0`–`T5` | Timing template, paranoid to insane |

**Penetration test phases (quick recall)**

Pre-engagement/scoping → Reconnaissance (passive + active) → Scanning/enumeration → Vulnerability analysis → Exploitation → Post-exploitation (privesc, lateral movement) → Reporting and retest.

**Engagement type comparison (quick recall)**

| Type | Primary goal | Typical awareness within client org |
|---|---|---|
| Vulnerability assessment | Identify and prioritize weaknesses, breadth-focused | Usually full |
| Penetration test | Prove exploitability and impact within scope/time | Usually full technical team |
| Red team | Achieve a defined adversarial objective, test detection/response | Often only a small white cell |
| Bug bounty | Ongoing crowdsourced discovery of discrete bugs | Public/semi-public program |

**Common Windows privilege escalation vectors (quick recall)**

Unpatched kernel/local exploits; misconfigured service permissions; unquoted service paths; weak registry/scheduled task permissions; token/impersonation privilege abuse; stored/plaintext credentials; AlwaysInstallElevated-style policy misconfigurations.

**Common Linux privilege escalation vectors (quick recall)**

Unpatched kernel exploits; abusable SUID/SGID binaries; misconfigured `sudo` rules; writable files/scripts run by root (cron, systemd units); exposed credentials/SSH keys; PATH manipulation against privileged scripts.

**Report finding checklist (quick recall)**

Title and severity (CVSS + contextual risk rating) → affected asset/endpoint → description → reproduction steps → evidence → business impact → specific remediation recommendation → confirmed vs. theoretical status.

---

## Closing Note

Every technique, tool, and concept described in this guide is intended strictly for **authorized, legally scoped security testing** — with explicit written permission from someone who has legitimate authority over the systems involved, conducted within a clearly defined scope and rules of engagement. Using these techniques against any system without that explicit authorization is illegal in most jurisdictions and unethical regardless of intent. Practice these skills only in legal environments: authorized lab platforms, intentionally vulnerable practice systems you own or are licensed to test, and bug bounty programs with clearly published, explicit scope. Professional credibility in this field is built on demonstrating not just technical skill, but consistently sound judgment about when — and when not — to act.
