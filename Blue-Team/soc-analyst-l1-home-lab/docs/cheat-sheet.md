# SOC Analyst L1 — Quick Reference / Cheat Sheet

A quick reference guide for alerts, logs, searches, and investigations.

## Windows Event IDs (Security Log)

| Event ID | Description | Use Case |
|---|---|---|
| 4624 | Successful logon | Track user logins |
| 4625 | Failed logon | Brute-force detection |
| 4634 | Account logged off | Logoff tracking |
| 4688 | Process creation | New process execution |
| 4720 | User account created | New account monitoring |
| 4726 | User account deleted | Account removal monitoring |
| 4732 | Member added to group | Privilege escalation |
| 1102 | Log cleared | Log clearing (suspicious) |
| 4104 | PowerShell script block | PowerShell activity monitoring |
| 4689 | Process terminated | Process/service termination |

## Sysmon Event IDs (Core)

| Event ID | Description | Use Case |
|---|---|---|
| 1 | Process creation | Process monitoring |
| 3 | Network connection | Network activity |
| 6 | Driver loaded | Driver loading |
| 7 | Image loaded | DLL / driver loading |
| 11 | File create | File creation |
| 12/13/14 | Registry event | Registry value, creation, deletion |
| 22 | DNS query | DNS lookups |
| 25 | Process tampering | Process tampering |

**Tip:** Sysmon gives you deep visibility into process, network, and file changes.

## Common Splunk Searches (SPL)

```spl
index=windows EventCode=4625                          # Failed login attempts
index=windows EventCode=4624                           # Successful logins
index=sysmon EventID=1 Image="*powershell.exe"          # PowerShell execution
index=sysmon EventID=3                                  # Network connections
index=sysmon EventID=22                                 # DNS queries
index=windows EventCode=4688                            # Process creation
```

## Useful Filter Examples (Splunk)

```spl
src_ip="192.168.56.105"
user="testuser"
host="WIN10"
process="powershell.exe"
parent_image="*cmd.exe"
CommandLine="*enc*"
```

## Event Viewer Locations (Windows)

| Log | Location |
|---|---|
| Application | Windows Logs → Application |
| Security | Windows Logs → Security |
| System | Windows Logs → System |
| Setup | Windows Logs → Setup |
| Sysmon | Applications and Services Logs → Microsoft → Windows → Sysmon → Operational |

## MITRE ATT&CK Quick Reference

| Tactic | Technique | Description |
|---|---|---|
| Credential Access | T1110 | Brute Force |
| Initial Access | T1566 | Phishing |
| Execution | T1059.001 | PowerShell |
| Defense Evasion | T1027 | Obfuscated/Encoded Files |
| Command and Control | T1071.001 | Web Protocols |
| Persistence | T1547 | Boot or Logon Autostart Execution |

## IOC vs IOA

| Type | Description |
|---|---|
| **IOC** (Indicator of Compromise) | IP address, domain, file hash, malware — evidence a breach has already occurred |
| **IOA** (Indicator of Attack) | Unusual login time, multiple failed logins, suspicious network connection — evidence of an attack in progress |

## Severity Matrix

| Impact | Likelihood | Severity | Action |
|---|---|---|---|
| Low | Low | Low | Monitor |
| Medium | Medium | Medium | Investigate |
| High | High | High | Escalate |
| Critical | Critical | Critical | Immediate response |

## False Positive vs True Positive

| Type | Description |
|---|---|
| **True Positive** | Confirmed malicious activity — a real threat or attack indicator |
| **False Positive** | Legitimate process/user activity — no action needed |

## Investigation Checklist (L1)

- [ ] Confirm whether the alert is genuine
- [ ] Review all related logs and data
- [ ] Identify the source IP/domain
- [ ] Verify the user (is this normal?)
- [ ] Check the Event ID(s)
- [ ] Review the timeline
- [ ] Check the process tree (parent/child)
- [ ] Cross-check evidence with Sysmon/logs
- [ ] Determine severity
- [ ] Close the alert or escalate to L2
- [ ] Document all findings

## Evidence Collection

- Splunk / Event Viewer screenshots
- Log export (CSV/JSON)
- Process tree
- Command line
- Source IP details (AbuseIPDB, VirusTotal, etc.)
- Timeline
- User verification (if needed)

## Common Threat Patterns

| Pattern | Description |
|---|---|
| Brute Force | Multiple login attempts, single source IP |
| PowerShell Abuse | Encoded commands, suspicious parent process |
| Suspicious Download | Unknown/unexpected files downloaded |
| Persistence | Registry Run key, scheduled task addition |
| Log Clearing | Windows Security/System log cleared (Event ID 1102) |
| Privilege Escalation | A user added to the Administrators group (Event ID 4732) |

## Golden Rules

- Don't act on an alert alone — always investigate.
- Collect evidence before taking action without validation.
- Cross-verify with multiple sources.
- When in doubt, escalate.
- Security is a team effort — share and document your findings.

## SOC Analyst Mindset

- Stay curious
- Think like the attacker
- Verify everything
- Keep learning
- Document and share
