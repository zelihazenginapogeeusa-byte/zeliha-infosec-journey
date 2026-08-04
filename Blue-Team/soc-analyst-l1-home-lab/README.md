# SOC Analyst L1 Home Lab

**Build your own SOC (Security Operations Center) environment from scratch, simulate realistic attacks, detect them with Splunk, and investigate them like an L1 SOC analyst.**

This repo is a **home lab guide** for anyone getting started in cybersecurity — especially the SOC / Blue Team side — built entirely on free tools. You'll set up an attacker machine (Kali Linux), a victim endpoint (Windows 10), and a SIEM server (Ubuntu + Splunk Enterprise) inside VirtualBox, then run three real-world attack scenarios (brute force, phishing, malicious PowerShell) end to end — simulating, detecting in Splunk, investigating, and writing up the incident.

> ⚠️ **For educational purposes only.** Never use the techniques covered in this lab against any system you don't own or don't have explicit permission to test.

---

## Table of Contents

1. [What This Lab Teaches](#what-this-lab-teaches)
2. [Architecture](#architecture)
3. [Requirements](#requirements)
4. [Setup Steps](#setup-steps)
5. [Attack Simulations](#attack-simulations)
6. [SOC Investigation Workflow](#soc-investigation-workflow)
7. [Sample Incident Reports](#sample-incident-reports)
8. [Quick Reference / Cheat Sheet](#quick-reference--cheat-sheet)
9. [Troubleshooting](#troubleshooting)
10. [Folder Structure](#folder-structure)
11. [Contributing](#contributing)

---

## What This Lab Teaches

A **SOC (Security Operations Center)** is the team that monitors, detects, investigates, and responds to security threats around the clock. A **SOC Analyst L1**'s day-to-day usually looks like:

- Monitoring alerts from security tooling
- Investigating suspicious activity
- Validating and triaging incidents
- Documenting findings
- Escalating critical issues to L2
- Closing false positives

By the end of this lab you'll be able to:

- Build your own SOC environment from scratch in VirtualBox
- Collect and analyze logs with Splunk SIEM
- Simulate real-world attacks (brute force, phishing, PowerShell abuse)
- Investigate alerts and make a decision (close / escalate)
- Write a professional incident report

**Difficulty level:** Beginner

---

## Architecture

```
                     ATTACK                                       DEFENSE
                 ┌──────────────┐                     ┌──────────────────────┐
                 │  Kali Linux   │  ── attacks ────▶   │  Windows 10 Endpoint │
                 │  (Attacker)   │                     │  (Victim + Sysmon)   │
                 └──────────────┘                     └──────────┬───────────┘
                                                                   │ Splunk Universal
                                                                   │ Forwarder (log shipping)
                                                                   ▼
                                                        ┌──────────────────────┐
                                                        │   Ubuntu Server       │
                                                        │   Splunk Enterprise   │
                                                        │   (SIEM / Log Collector)
                                                        └──────────┬───────────┘
                                                                   │
                                                                   ▼
                                                        ┌──────────────────────┐
                                                        │   SOC Analyst (You)  │
                                                        │   Alert triage,       │
                                                        │   investigation,      │
                                                        │   decision            │
                                                        └──────────────────────┘
```

**Log flow:**

1. Windows 10 (endpoint) generates detailed system events (process, network, file) via Sysmon.
2. Splunk Universal Forwarder collects those logs.
3. The forwarder ships logs to the Splunk SIEM server.
4. Splunk indexes the logs and raises alerts based on rules.
5. The SOC analyst investigates alerts and takes action.

---

## Requirements

### Hardware (minimum / recommended)

| Component | Minimum | Recommended |
|---|---|---|
| CPU | 2 cores | 4 cores or more |
| RAM | 8 GB | 16 GB or more |
| Storage | 100 GB free | 200 GB+ SSD |
| Virtualization | Enabled in BIOS (VT-x/AMD-V) | Enabled |
| Internet | Required | Required |

### Software

| Tool | Purpose | Source |
|---|---|---|
| Oracle VM VirtualBox | Virtualization platform | [virtualbox.org](https://www.virtualbox.org/) |
| Windows 10 ISO | Victim / endpoint machine | Official Microsoft site |
| Kali Linux ISO | Attacker machine | [kali.org](https://www.kali.org/get-kali/) |
| Ubuntu Server ISO | For the Splunk install | [ubuntu.com](https://ubuntu.com/download/server) |
| Splunk Enterprise | SIEM / log analysis | [splunk.com](https://www.splunk.com/en_us/download/splunk-enterprise.html) (free tier is fine for a lab) |
| Sysmon (Sysinternals) | Windows logging | [Microsoft Sysinternals](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon) |
| Splunk Universal Forwarder | Log-shipping agent | [splunk.com](https://www.splunk.com/en_us/download/universal-forwarder.html) |
| Python 3 (optional) | Tooling/scripting | — |

> Keeping your downloads in separate folders (VirtualBox / Windows ISO / Kali ISO / Sysmon / Splunk & Forwarder) makes setup a lot easier to follow.

**Common pitfalls:**

- Virtualization may be disabled in BIOS (enable VT-x/AMD-V)
- VMs may not have enough RAM allocated
- Make sure all VMs are on the same Internal Network
- UF (Universal Forwarder) routing misconfigured (check `outputs.conf`/`inputs.conf`)

---

## Setup Steps

For the detailed, step-by-step walkthrough, see [`docs/`](./docs). Summary flow:

### 1. Install VirtualBox
Download and install VirtualBox, keeping all default components selected. After installation, create an **Internal Network** — all VMs (Windows, Kali, Ubuntu) need to be on the same internal network so they can talk to each other.

### 2. Windows 10 VM (Victim / Endpoint)
- New VM → Name: `Windows10`, Type: Microsoft Windows, Version: 64-bit
- RAM: at least 4096 MB, Disk: at least 50 GB (dynamically allocated VDI)
- Network: set to **Internal Network**
- Complete the install using the Windows 10 ISO

### 3. Splunk Enterprise Install (on Ubuntu Server)
```bash
sudo apt update
# Download the Splunk .deb package and install it
sudo dpkg -i splunk-*.deb
sudo /opt/splunk/bin/splunk start --accept-license
sudo /opt/splunk/bin/splunk enable boot-start
```
Once installed, access the Splunk Web UI at `http://<ubuntu_ip>:8000` and change the default admin password.

### 4. Sysmon + Splunk Universal Forwarder (on Windows 10)
- Download and install Sysmon: `sysmon64.exe -accepteula -i sysmonconfig.xml`
- Install the Splunk Universal Forwarder
- In `inputs.conf`, define the Windows Event Logs (Security/System/Application) and the Sysmon operational log
- In `outputs.conf`, define the Splunk server IP and port 9997 (sample files: [`configs/`](./configs))
- Restart the forwarder service

### 5. Verify Log Flow
In Splunk's Search & Reporting, run these queries to confirm logs are arriving:
```spl
index=windows
index=sysmon
host=WIN10
index=windows EventCode=4625
```

See [`scripts/`](./scripts) for automation script examples.

---

## Attack Simulations

This lab includes three realistic attack scenarios. Each one follows: **launch the attack → see it land in Sysmon/Windows Event Log → detect it in Splunk → investigate**.

### 1️⃣ Brute Force Attack
Password-guessing attack from Kali Linux against Windows 10 using Hydra:
```bash
hydra -l testuser -P /usr/share/wordlists/rockyou.txt rdp://<windows_ip>
```
**Detection:** repeated `Event ID 4625` (failed logon) in the Windows Security Log. In Splunk:
```spl
index=windows EventCode=4625
| stats count by src_ip, user
| where count > 5
```
**MITRE ATT&CK:** T1110 – Brute Force

### 2️⃣ Phishing Simulation
A simulated malicious-attachment email scenario; when the user opens the attachment, an obfuscated PowerShell command runs. Captured via Sysmon Event ID 1 (process creation).
```spl
index=sysmon EventID=1 Image="*powershell.exe"
```
**MITRE ATT&CK:** T1566 (Phishing), T1059.001 (PowerShell), T1027 (Obfuscated Files)

### 3️⃣ Suspicious PowerShell Execution
A payload-download simulation using an encoded PowerShell command:
```powershell
powershell -enc <base64_encoded_command>
```
**Detection:** Sysmon Event ID 1 + Windows Event ID 4688 (process creation), process tree analysis (parent/child relationships).
```spl
index=sysmon EventID=1 ParentImage="*cmd.exe" Image="*powershell.exe"
```
**MITRE ATT&CK:** T1059.001, T1071.001 (Web Protocols), T1027

---

## SOC Investigation Workflow

The standard 10-step process followed for every alert:

1. **Alert Generated** — Splunk fires a rule-based alert
2. **Alert Search** — review the alert details
3. **Validate Alert** — real, or false positive?
4. **Check Source IP** — check the source IP's reputation
5. **Check User** — is the user's behavior normal?
6. **Verify Host** — host health and status
7. **Review Event Timeline** — walk through the surrounding timeline
8. **Correlate Logs** — cross-reference process, network, and registry logs
9. **Determine Severity** — Low / Medium / High / Critical
10. **Collect Evidence & Decide** — gather evidence, then close or escalate to L2

**Golden rule:** a good investigation is about accuracy, not speed — validate → investigate → correlate → document → decide.

---

## Sample Incident Reports

The `docs/incident-reports/` folder contains two sample incident report templates:

- **Example 1 — Alert Closed:** a user forgot their password and triggered multiple failed login attempts (genuine user activity, no malicious intent) → **Closed**
- **Example 2 — Escalated to L2:** an encoded PowerShell command downloaded from an external IP, attempting persistence → **Escalated to L2**

These reports model a professional SOC ticket format — alert summary, timeline, evidence collected, IOC list, and final disposition.

---

## Quick Reference / Cheat Sheet

### Common Windows Event IDs

| Event ID | Description |
|---|---|
| 4624 | Successful logon |
| 4625 | Failed logon (brute force indicator) |
| 4688 | Process creation |
| 4720 | User account created |
| 4726 | User account deleted |
| 4732 | Member added to group (privilege escalation) |
| 1102 | Log cleared (suspicious) |

### Common Sysmon Event IDs

| Event ID | Description |
|---|---|
| 1 | Process creation |
| 3 | Network connection |
| 7 | Image loaded (DLL/driver) |
| 11 | File creation |
| 13 | Registry value set |
| 22 | DNS query |

### Useful SPL queries

```spl
index=windows EventCode=4625                       # failed logons
index=sysmon EventID=1 Image="*powershell.exe"       # PowerShell execution
index=sysmon EventID=3                               # network connections
| stats count by src_ip | sort -count               # top source IPs
```

### False Positive vs True Positive

- **True Positive:** confirmed malicious activity, a real threat
- **False Positive:** legitimate process/user activity, no action needed

---

## Troubleshooting

| Issue | Possible Fix |
|---|---|
| VM won't start / "VT-x not available" | Enable virtualization in BIOS |
| VMs can't see each other | Confirm they're all on the same Internal Network |
| Splunk Web UI (port 8000) not loading | Check the service: `sudo systemctl status splunk` |
| Logs not showing up in Splunk | Check `outputs.conf` (IP/port) and `inputs.conf` (log paths) |
| Forwarder can't connect | Confirm port 9997 is open, check firewall rules |
| No Sysmon logs | Confirm `sysmonconfig.xml` installed correctly and the service is running |

---

## Folder Structure

```
soc-analyst-l1-home-lab/
├── README.md                     # This file
├── docs/
│   ├── 01-what-is-soc-home-lab.md
│   ├── 02-hardware-software-requirements.md
│   ├── 03-install-virtualbox.md
│   ├── 04-create-windows10-vm.md
│   ├── 05-install-splunk-siem.md
│   ├── 06-install-sysmon-forwarder.md
│   ├── 07-verify-logs.md
│   ├── attacks/
│   │   ├── 01-brute-force.md
│   │   ├── 02-phishing-simulation.md
│   │   └── 03-powershell-execution.md
│   ├── investigation-workflow.md
│   ├── incident-reports/
│   │   ├── example-1-closed-alert.md
│   │   └── example-2-escalated-to-l2.md
│   └── cheat-sheet.md
├── scripts/
│   ├── install-splunk-enterprise.sh
│   ├── install-sysmon.ps1
│   ├── install-universal-forwarder.ps1
│   └── verify-log-flow.spl
├── configs/
│   ├── inputs.conf
│   ├── outputs.conf
│   └── sysmonconfig-sample.xml
└── screenshots/
    └── (add screenshots from your own lab build here)
```

---

## Contributing

This project is for educational use and open to contributions. Feel free to open a pull request for new attack scenarios, additional SPL queries, integrations with other SIEMs (Wazuh, ELK, etc.), or fixes.

## License

Free to share for educational purposes. Only use the techniques covered in this lab in your own authorized environments.
