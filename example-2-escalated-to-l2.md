# Incident Report Example 2 — Escalated to L2

**Scenario:** A suspicious PowerShell command with a downloaded payload was executed and attempted persistence — pointing to possible malware activity. Escalated to L2.

## Attack Summary

```
1. PowerShell Executed → 2. File Downloaded (External) → 3. Encoded Command
    → 4. Persistence Attempt → 5. Escalated to L2
```

## Overview

| Field | Value |
|---|---|
| Incident Name | Encoded PowerShell Execution |
| Severity | **High** |
| Detection Date | 2026-05-21 02:15:31 PM |
| Hostname | WIN10 |
| User | testuser |
| Source IP | 192.168.56.105 (External) |
| Destination IP | 192.168.56.105 |
| Event ID | 4688, Sysmon ID 1 (PowerShell) |
| MITRE ATT&CK | T1059.001 |
| Alert Type | Potential Malware Execution |
| Status | **ESCALATED TO L2** |

## 1. Sysmon Event (Event ID 1 — Process Create)

An encoded PowerShell command was executed from WINWORD.EXE.

## 2. Network Activity (File Download)

- Destination IP: 192.168.56.105 (External)
- Destination Port: 80 (HTTP)
- URL: `http://192.168.56.105/payload.ps1`
- User-Agent: Mozilla/HostSvc AgentX
- Bytes downloaded: 62 KB

## 3. Process Tree (via Sysmon)

```
WINWORD.EXE (PID 4120)
   └── powershell.exe (PID 3568) -enc SQBFAFgA...
          └── cmd.exe (PID 3620)
                 └── conhost.exe (PID 2760)
```
The suspicious child process was spawned from WINWORD.EXE.

## 4. Event Timeline

| Time | Event |
|---|---|
| 02:11 PM | PowerShell executed |
| 02:12 PM | File downloaded from external source |
| 02:15 PM | Encoded command detected |
| 02:15 PM | Persistence attempt observed |
| 02:01 PM | Escalated to L2 |

## Indicators of Compromise (IOCs)

| Type | Value | Note |
|---|---|---|
| IP Address | 192.168.56.105 | Malicious / suspicious |
| URL | `http://192.168.56.105/payload.ps1` | C2 / payload URL |
| File Hash | `a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6` | Malicious PS1 |
| Command Line | `powershell.exe -enc SQBFAFgA...` | Encoded PowerShell script |

## Evidence Collected

- Splunk events
- Sysmon logs
- Process tree (visualized)
- Network log
- Windows Security Log

## L1 Analyst Notes

This activity — encoded PowerShell execution combined with external communication — points to potential malware execution. Escalated to L2 for deeper analysis and containment.

## Reason for Escalation

- Possible malware execution
- Requires advanced analysis and containment

## What L1 Did

- ✅ Detected and validated the alert
- ✅ Collected all relevant evidence
- ✅ Mapped it to MITRE ATT&CK
- ✅ Documented the investigation
- ✅ Escalated to L2 for deeper analysis

## Severity Matrix

| Impact | Likelihood | Severity |
|---|---|---|
| High | High | **HIGH** |

## SOC Tip

Don't hesitate to escalate complex incidents. A timely, well-documented escalation beats missing a real breach.

## Golden Rule

When in doubt, escalate. Documenting the investigation process is always worth it.
