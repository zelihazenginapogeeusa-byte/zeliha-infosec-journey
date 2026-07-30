# Playbook Index — Quick Access by Scenario

A single jump-off point for every scenario-driven playbook in this repo — "which alert just fired / which stage of the engagement am I at, and which playbook do I open." For tool/syntax reference material, use each folder's own `README.md` instead; this page is playbooks only.

---

## 🔵 Blue-Team — When an Alert Fires

| Situation | Open this playbook | Location |
|---|---|---|
| Failed-login spike, password spray, impossible-travel sign-in, suspicious PowerShell execution, possible data exfiltration, or a malware/EDR detection alert | **Splunk/SIEM Investigation Playbook** | [`Blue-Team/01-SOC-and-SIEM-Analysis/splunk-siem-investigation-playbook.md`](Blue-Team/01-SOC-and-SIEM-Analysis/splunk-siem-investigation-playbook.md) |
| DeepBlueCLI flagged something — suspicious logon, obfuscated command line, new account/privilege change, rogue service or scheduled task | **Event Log Triage Playbook (DeepBlueCLI)** | [`Blue-Team/01-SOC-and-SIEM-Analysis/event-log-triage-playbook-deepbluecli.md`](Blue-Team/01-SOC-and-SIEM-Analysis/event-log-triage-playbook-deepbluecli.md) |
| User-reported phishing email, confirmed malicious link click, malicious attachment executed, or a suspected phishing campaign/BEC | **Phishing Investigation Playbook** | [`Blue-Team/02-DFIR-and-Threat-Intelligence/phishing-investigation-playbook.md`](Blue-Team/02-DFIR-and-Threat-Intelligence/phishing-investigation-playbook.md) |
| You have a PCAP/live capture to triage — general triage, suspected C2/beaconing, exfiltration over the wire, credential capture, or a port scan | **Wireshark/PCAP Threat-Hunting Playbook** | [`Blue-Team/02-DFIR-and-Threat-Intelligence/wireshark-pcap-threat-hunting-playbook.md`](Blue-Team/02-DFIR-and-Threat-Intelligence/wireshark-pcap-threat-hunting-playbook.md) |
| Ransomware confirmed or suspected active on a host/share — **time-critical, start here first** | **Ransomware Incident Response Playbook** | [`Blue-Team/02-DFIR-and-Threat-Intelligence/ransomware-incident-response-playbook.md`](Blue-Team/02-DFIR-and-Threat-Intelligence/ransomware-incident-response-playbook.md) |
| A disk image landed on your desk — suspected USB data theft, need to confirm malware execution, or reconstructing general user activity | **Digital Forensics Investigation Playbook (Autopsy)** | [`Blue-Team/02-DFIR-and-Threat-Intelligence/digital-forensics-investigation-playbook-autopsy.md`](Blue-Team/02-DFIR-and-Threat-Intelligence/digital-forensics-investigation-playbook-autopsy.md) |
| AD attack indicators — Kerberoasting, AS-REP Roasting, DCSync, Golden/Silver Ticket, or Pass-the-Hash lateral movement | **AD Compromise & Lateral Movement Playbook** | [`Blue-Team/02-DFIR-and-Threat-Intelligence/active-directory-compromise-lateral-movement-playbook.md`](Blue-Team/02-DFIR-and-Threat-Intelligence/active-directory-compromise-lateral-movement-playbook.md) |

---

## 🔴 Red-Team — During an Engagement

| Situation | Open this playbook | Location |
|---|---|---|
| A port just came back open on a scan and you need the enumeration → exploitation path for that specific service | **Port Enumeration & Exploitation Playbook** | [`Red-Team/02-Web-and-Network-Pentesting/port-enumeration-exploitation-playbook.md`](Red-Team/02-Web-and-Network-Pentesting/port-enumeration-exploitation-playbook.md) |
| You have a foothold in Active Directory and need the full chain to Domain Admin, in order | **AD Attack Chain Playbook** | [`Red-Team/03-Exploitation-and-Post-Exploitation/active-directory-attack-chain-playbook.md`](Red-Team/03-Exploitation-and-Post-Exploitation/active-directory-attack-chain-playbook.md) |

---

## How These Differ From Cheat Sheets

A **cheat sheet** answers "what's the command/syntax for X" — it's a reference you consult mid-task. A **playbook** answers "what do I do, in order, from the moment this specific situation starts" — trigger → numbered steps → escalate-if criteria → containment/close-as-benign. Every playbook above links back to the relevant cheat sheets for the actual command syntax rather than repeating it, so use the playbook to drive the sequence and the cheat sheet for the how.

---

*Full cheat sheet indexes: [`Red-Team/README.md`](Red-Team/README.md) · [`Blue-Team/README.md`](Blue-Team/README.md). Exam-day checklists (not scenario playbooks, but related): [`Red-Team/01-Recon-and-OSINT/ejpt-exam-checklist-and-methodology.md`](Red-Team/01-Recon-and-OSINT/ejpt-exam-checklist-and-methodology.md) · [`Blue-Team/02-DFIR-and-Threat-Intelligence/incident-response-exam-checklist.md`](Blue-Team/02-DFIR-and-Threat-Intelligence/incident-response-exam-checklist.md).*
