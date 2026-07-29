# Attack Types — Defensive Identification Cheat Sheet

How to look at an alert, a log line, or a user report and figure out **which attack type you're actually looking at** — the triage layer that sits between "something looks weird" and "here's the right playbook."

> Prepared as a reference for BTL1 and general SOC operations.

---

## 1. How to Think About This

Every attack type leaves a **signature** somewhere — a log source, a network pattern, an endpoint artifact. Triage is the process of matching what you're seeing to the right category *before* you pick a response playbook. Most real incidents involve more than one category chained together (e.g., phishing → credential theft → lateral movement).

---

## 2. Network-Based Attacks

| What you'll see | Attack type | Where to look |
|---|---|---|
| Duplicate/gratuitous ARP replies, MAC flapping | ARP spoofing / MITM | Switch logs, `arpwatch`, IDS ARP-spoof rules |
| Sudden spike in LLMNR/NBT-NS traffic | Responder-style credential capture | Network IDS, Zeek `dns.log` / broadcast traffic |
| Unexpected DHCP server on the segment | Rogue DHCP | DHCP server logs, switch port security alerts |
| Plaintext credentials visible in a packet capture | Credential sniffing (attacker already has network access) | Wireshark/Zeek review of affected segment |

**MITRE ATT&CK:** T1557 (Adversary-in-the-Middle), T1040 (Network Sniffing)

---

## 3. Web Application Attacks

| What you'll see | Attack type | Where to look |
|---|---|---|
| Requests with `' OR 1=1`, `UNION SELECT`, SQL error strings in responses | SQL Injection | WAF logs, web server access logs |
| `<script>` / `onerror=` payloads in request params | XSS attempt | WAF logs, app logs |
| Outbound requests from the app server to unusual internal/external IPs | SSRF | App logs, egress firewall logs |
| Requests containing `<!ENTITY` or DOCTYPE declarations | XXE attempt | WAF/app logs |
| Uploaded files with double extensions or executable content-types | Malicious upload attempt | Upload directory monitoring, AV/EDR on the web server |
| Sequential ID enumeration in short time window (`?id=1,2,3...`) | IDOR probing | App logs, rate-limiting alerts |
| Known-CVE exploit strings in user-agent or request path | Exploitation attempt against fingerprinted software | WAF/IDS signature hits |

**MITRE ATT&CK:** T1190 (Exploit Public-Facing Application)

---

## 4. Authentication Attacks

| What you'll see | Attack type | Where to look |
|---|---|---|
| Many failed logins, single account, short window | Brute-force | Auth logs (Windows 4625, SSH `auth.log`), SIEM correlation |
| Many failed logins, many accounts, one password pattern | Password spraying | Auth logs — look for **one bad password, many usernames**, spread over time to dodge lockout thresholds |
| Login success from new geography/impossible travel | Credential stuffing / account takeover | IdP logs (Azure AD sign-in logs, Okta) |
| NTLM/Kerberos hash requests without matching logon patterns | Pass-the-hash / pass-the-ticket | Windows Event ID 4624 (logon type 9/3 anomalies), Kerberos event IDs 4768/4769 |

**MITRE ATT&CK:** T1110 (Brute Force — including sub-techniques .003 Password Spraying), T1550 (Use Alternate Authentication Material)

---

## 5. Active Directory / Windows Domain Attacks

| What you'll see | Attack type | Where to look |
|---|---|---|
| Bursts of Kerberos service ticket requests (4769) for many SPNs | Kerberoasting | Domain Controller security logs |
| 4768 requests with pre-auth disabled flag | AS-REP Roasting | DC security logs |
| Unusual LDAP queries at high volume (from a non-admin host) | AD reconnaissance (BloodHound-style) | LDAP/DC logs, Sysmon Event ID 1 (process creation) |
| ACL/permission changes on sensitive objects | ACL abuse | DC audit logs (Event ID 5136) |
| TGT requests with delegation flags set | Delegation abuse | DC security logs, Event ID 4768/4769 with flag review |

**MITRE ATT&CK:** T1558 (Steal or Forge Kerberos Tickets), T1482 (Domain Trust Discovery)

---

## 6. Malware / Endpoint Attacks

| What you'll see | Attack type | Where to look |
|---|---|---|
| Office document spawning `cmd.exe`/`powershell.exe` | Macro-based malware execution | EDR process-tree, Sysmon Event ID 1 |
| Encoded/obfuscated PowerShell command lines | Payload execution, evasion attempt | Sysmon Event ID 1/4104 (PowerShell script block logging) |
| New scheduled task, run-key, or service created shortly after suspicious execution | Persistence | Sysmon Event ID 4698 (task), Event ID 13 (registry) |
| Known-bad hash or YARA rule match on a file | Malware present | AV/EDR alert, `DeepBlueCLI`/Velociraptor sweep |
| Beaconing pattern (regular-interval outbound connections) | C2 communication | Network flow logs, Zeek, Wireshark |

**MITRE ATT&CK:** T1059 (Command and Scripting Interpreter), T1547 (Boot or Logon Autostart Execution), T1071 (Application Layer Protocol — C2)

---

## 7. Social Engineering

| What you'll see | Attack type | Where to look |
|---|---|---|
| Lookalike domain, urgency language, spoofed sender | Phishing email | Email gateway logs, header analysis (SPF/DKIM/DMARC failures) |
| Credential-harvesting link reported by a user | Spear-phishing → credential theft | Email logs, proxy logs for the click-through |
| Multiple users report the same suspicious call | Vishing | User reports, help-desk ticket correlation |

**MITRE ATT&CK:** T1566 (Phishing)

> See [`phishing-cheatsheet.md`](../02-DFIR-and-Threat-Intelligence/phishing-cheatsheet.md) for the full triage workflow.

---

## 8. Denial of Service

| What you'll see | Attack type | Where to look |
|---|---|---|
| Sudden traffic spike, single endpoint saturated | Volumetric/application-layer DoS | Load balancer/WAF metrics, netflow |
| Resource exhaustion on a specific app function | Targeted application DoS | App performance monitoring, error-rate spikes |

**MITRE ATT&CK:** T1499 (Endpoint Denial of Service)

---

## 9. Wireless

| What you'll see | Attack type | Where to look |
|---|---|---|
| Duplicate SSID broadcasting nearby | Evil twin / rogue AP | Wireless IDS (WIDS), site survey tools |
| Deauth frames flooding a client | Deauth attack (handshake capture prep) | WIDS, `Kismet` |

**MITRE ATT&CK:** T1557.004 (Evil Twin)

---

## 10. Cloud / Misconfiguration

| What you'll see | Attack type | Where to look |
|---|---|---|
| Anonymous/public access to storage flagged by scanner | Public bucket exposure | Cloud config scanner (AWS Config, ScoutSuite), CloudTrail |
| Metadata service (`169.254.169.254`) accessed from unusual process | Instance metadata credential theft | CloudTrail, VPC flow logs |
| IAM policy change granting broad permissions | Cloud privilege escalation | CloudTrail `PutUserPolicy`/`AttachRolePolicy` events |

**MITRE ATT&CK:** T1552.005 (Cloud Instance Metadata API), T1078.004 (Valid Accounts — Cloud Accounts)

---

## 11. Quick Triage Flow

1. **Which log source lit up first?** (auth logs, WAF, EDR, email gateway, network) — that tells you which section above to open.
2. **Is this one signal or a chain?** Most real incidents span categories — a phishing click (§7) often leads into credential theft (§4) and then AD activity (§5). Don't close the ticket after explaining just the first signal.
3. **Map to MITRE ATT&CK early** — it standardizes how you describe the incident to others and tells you what to look for *next* in the kill chain.

---

*Companion to [`attack-types-identification-cheatsheet-professional.md`](../Red-Team/attack-types-identification-cheatsheet-professional.md) in Red-Team — same categories, viewed from the attacker's side.*
