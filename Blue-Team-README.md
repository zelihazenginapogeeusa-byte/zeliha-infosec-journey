# Blue Team Cheat Sheets
## 🧰 Interactive Tools (open live, don't click the raw file)

| Tool | Live Preview |
|---|---|
| blue-team-study-notes_1.html | [Open live ↗](https://htmlpreview.github.io/?https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/blob/cybersecurity-learning-hub/Blue-Team/blue-team-study-notes_1.html) |
| btl1-exam-tracker.html | [Open live ↗](https://htmlpreview.github.io/?https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/blob/cybersecurity-learning-hub/Blue-Team/btl1-exam-tracker.html) |

Defensive-side reference material, prepared primarily around the **BTL1** (Blue Team Level 1) exam objectives — detection, triage, forensics, and incident response. Organized by function: alert-facing SOC/SIEM work vs. deeper DFIR/threat-intel work.

---

## 📁 01-SOC-and-SIEM-Analysis

| File | Covers |
|---|---|
| [attack-types-detection-cheatsheet-professional.md](01-SOC-and-SIEM-Analysis/attack-types-detection-cheatsheet-professional.md) | How to read an alert/log line and identify which attack category it points to — network, web, auth, AD, malware, social engineering, DoS, wireless, cloud |
| [siem-splunk-elk-cheatsheet-professional.md](01-SOC-and-SIEM-Analysis/siem-splunk-elk-cheatsheet-professional.md) | SPL/KQL-style querying, Splunk & ELK basics |
| [kql-and-spl-query-reference-cheatsheet.md](01-SOC-and-SIEM-Analysis/kql-and-spl-query-reference-cheatsheet.md) | Side-by-side KQL (Sentinel/Defender) and SPL (Splunk) syntax, plus ready-to-run triage queries for both |
| [splunk-siem-investigation-playbook.md](01-SOC-and-SIEM-Analysis/splunk-siem-investigation-playbook.md) | Scenario playbooks (brute force, password spray, impossible travel, suspicious PowerShell, exfiltration, malware alert) — what to do, in order, when each fires |
| [windows-event-id-reference-cheatsheet-professional.md](01-SOC-and-SIEM-Analysis/windows-event-id-reference-cheatsheet-professional.md) | Key Windows Event IDs for detection |
| [deepblue-cli-cheatsheet-professional.md](01-SOC-and-SIEM-Analysis/deepblue-cli-cheatsheet-professional.md) | Automated Event Log triage — the tooling layer on top of the Event ID reference |
| [event-log-triage-playbook-deepbluecli.md](01-SOC-and-SIEM-Analysis/event-log-triage-playbook-deepbluecli.md) | Triaging DeepBlueCLI findings — suspicious logons, obfuscated commands, new accounts/privilege changes, rogue services/tasks |
| [host-network-auditing-fundamentals-cheatsheet-professional.md](01-SOC-and-SIEM-Analysis/host-network-auditing-fundamentals-cheatsheet-professional.md) | Baseline security auditing — CIS Benchmarks, Windows/Linux config checks, network baseline review (shared with Red-Team) |

## 📁 02-DFIR-and-Threat-Intelligence

| File | Covers |
|---|---|
| [phishing-cheatsheet.md](02-DFIR-and-Threat-Intelligence/phishing-cheatsheet.md) | Email header analysis, SPF/DKIM/DMARC, IOC extraction, triage workflow |
| [phishing-investigation-playbook.md](02-DFIR-and-Threat-Intelligence/phishing-investigation-playbook.md) | Scenario playbooks for phishing response — user-reported email, malicious link clicked, malicious attachment executed, campaign/BEC |
| [reputation-lookup-tools-cheatsheet-professional.md](02-DFIR-and-Threat-Intelligence/reputation-lookup-tools-cheatsheet-professional.md) | VirusTotal, Any.Run, AbuseIPDB, MXToolbox, urlscan.io and other IOC/reputation lookup tools |
| [wireshark-advanced-cheatsheet.md](02-DFIR-and-Threat-Intelligence/wireshark-advanced-cheatsheet.md) | Display filters, stream following, C2/beaconing detection, tshark |
| [wireshark-pcap-threat-hunting-playbook.md](02-DFIR-and-Threat-Intelligence/wireshark-pcap-threat-hunting-playbook.md) | Scenario playbooks for PCAP/live-capture triage — general triage, C2/beaconing, exfiltration over the wire, credential capture, port scans |
| [threat-intelligence-mitre-attack-cheatsheet-professional.md](02-DFIR-and-Threat-Intelligence/threat-intelligence-mitre-attack-cheatsheet-professional.md) | MITRE ATT&CK mapping, threat intel sources |
| [volatility-autopsy-forensics-cheatsheet-professional.md](02-DFIR-and-Threat-Intelligence/volatility-autopsy-forensics-cheatsheet-professional.md) | Memory forensics (Volatility) & disk forensics (Autopsy) |
| [digital-forensics-investigation-playbook-autopsy.md](02-DFIR-and-Threat-Intelligence/digital-forensics-investigation-playbook-autopsy.md) | Scenario-driven Autopsy walkthroughs — USB data theft, malware execution confirmation, user activity reconstruction |
| [memory-and-disk-forensics-quickref.md](02-DFIR-and-Threat-Intelligence/memory-and-disk-forensics-quickref.md) | Condensed, command-first Volatility 3/2 + Autopsy quick reference for time-pressured triage |
| [linux-forensics-and-artifact-analysis-cheatsheet.md](02-DFIR-and-Threat-Intelligence/linux-forensics-and-artifact-analysis-cheatsheet.md) | Linux-side forensics — log locations, auditd, timeline building, persistence checklist, memory/disk acquisition |
| [malware-analysis-yara-cheatsheet-professional.md](02-DFIR-and-Threat-Intelligence/malware-analysis-yara-cheatsheet-professional.md) | Static/dynamic malware analysis, YARA rule writing |
| [ransomware-incident-response-playbook.md](02-DFIR-and-Threat-Intelligence/ransomware-incident-response-playbook.md) | First-hour, time-critical ransomware response — containment, blast-radius scoping, eradication/recovery, pay-or-not decision inputs |
| [incident-response-lifecycle-cheatsheet-professional.md](02-DFIR-and-Threat-Intelligence/incident-response-lifecycle-cheatsheet-professional.md) | PICERL / NIST SP 800-61 incident response lifecycle |
| [incident-response-exam-checklist.md](02-DFIR-and-Threat-Intelligence/incident-response-exam-checklist.md) | BTL1 exam-day investigation checklist — methodology, time management, pitfalls, submission checklist |
| [active-directory-compromise-lateral-movement-playbook.md](02-DFIR-and-Threat-Intelligence/active-directory-compromise-lateral-movement-playbook.md) | Scenario playbooks for AD attacks — Kerberoasting, AS-REP Roasting, DCSync, Golden/Silver Ticket, Pass-the-Hash lateral movement — ⚠️ **confirm this is actually where you placed the file, path below may need adjusting** |

---

> `assessment-methodology-report-writing-cheatsheet-professional.md` is shared with Red-Team work and lives in `Red-Team/01-Recon-and-OSINT/`.

*Prepared as a reference for BTL1 and general SOC operations.*
