# Live Attack 3 — Suspicious PowerShell Command / Payload Download

Attackers frequently abuse PowerShell to run commands and download payloads. In this scenario we run an encoded PowerShell command from Windows 10 and detect it in Splunk.

## Flow

```
Windows 10 (Attacker Host) → PowerShell Encoded Command
    → Sysmon (Event ID 1) → Splunk SIEM (Detection) → SOC Alert
```

## 1. Run the Encoded PowerShell Command

```powershell
powershell -enc <base64_encoded_command>
```
This command is typically designed to download a payload from an external server and load it into memory (e.g. via `Net.WebClient`, `DownloadString`).

## 2. PowerShell Process Starts

Windows executes the encoded PowerShell command.

## 3. Windows Event Viewer — Event ID 4688

The process creation event is logged in the Windows Security Log.

## 4. Sysmon Event (Event ID 1 — Process Create)

Sysmon captures the full detail of the PowerShell process (command line, hash, parent process).

## 5. Splunk — PowerShell Detection

```spl
index=sysmon EventID=1 Image="*powershell.exe"
```

## 6. Process Tree (via Sysmon)

```
cmd.exe (PID 3240)
   └── powershell.exe (PID 3568) -enc SQBFAFgA...
          └── conhost.exe (PID 3620)
```
The parent/child relationship shows PowerShell was launched from cmd.exe — a pattern that can indicate an attack.

## What Is PowerShell Abuse?

Attackers use PowerShell to run commands, download files, establish persistence, and evade detection. Since it's built into Windows and capable of full scripting, it's a favorite tool for attackers.

## Why Do Attackers Use It?

- Built into Windows — no need to drop extra tools
- Powerful scripting capabilities
- Can execute entirely in memory — no trace left on disk
- Easy to obfuscate
- Can blend in with legitimate admin activity

## Key Indicators (IOCs)

- Suspicious command line flags (`-enc`, `-nop`, `-w hidden`)
- Unexpected parent process (PowerShell spawned from Word, Excel, cmd.exe)
- PowerShell opening a network connection (payload download)

## MITRE ATT&CK

- **T1059.001** — Execution: PowerShell
- **T1071.001** — Command and Control: Web Protocols
- **T1027** — Defense Evasion: Obfuscated/Encoded Files

## Severity: High

Encoded PowerShell execution is a strong indicator of malicious activity.

## Investigation Decision

This is assessed as a **Suspicious PowerShell Execution**.

**Action steps:**
- Investigate the command and its source
- Decode the command and determine its intent (payload URL, C2 domain, etc.)
- Verify host health
- Collect evidence (command line, process tree, network connection)

## Next Step

In the next section, we'll look at how a SOC L1 analyst investigates alerts like this end to end → [`../investigation-workflow.md`](../investigation-workflow.md)
