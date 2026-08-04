# Live Attack 2 — Phishing Email Simulation

In this lab, we simulate a phishing email with a malicious attachment. When the user opens it, an obfuscated PowerShell command runs — captured by Sysmon and detected in Splunk.

## Flow

```
1. Phishing Email Received → 2. User Opens Attachment
    → 3. PowerShell Execution → 4. Sysmon Event → 5. Splunk SIEM Detection → 6. SOC Alert Generated
```

## 1. Phishing Email (Simulated)

The user receives a fake "IT Support" email with a malicious attachment (e.g. a file called "Document_Update", under the pretext of account verification).

## 2. User Opens the Attachment

The user opens the attached file from their Downloads folder.

## 3. PowerShell Execution (Malicious)

Opening the attachment runs an encoded PowerShell command:
```
powershell -nop -w hidden -enc <base64_encoded_payload>
```

## 4. Sysmon Process Capture (Event ID 1)

Sysmon captures the PowerShell process creation event, including the parent/child relationship.

## 5. Splunk Detection — PowerShell Execution

```spl
index=sysmon EventID=1 Image="*powershell.exe"
```

## 6. Splunk Alert — Phishing Activity Detected

Splunk raises a medium-severity alert for suspicious PowerShell execution spawned from a downloaded file.

## What Is Phishing?

Phishing is a social engineering attack where attackers pose as a legitimate source to trick users into clicking malicious links or opening attachments without exercising caution.

## Why Do Attackers Use It?

- Easy to create and deliver
- High success rate (relies on human error)
- Can lead to credential theft, initial access, or malware delivery
- Often the first step in a larger attack

## Key Indicators (IOCs)

- Suspicious sender email address
- Unexpected file extensions (.exe, .js, .vbs, .hta disguised as something else)
- Executables launched from the Downloads folder
- Encoded PowerShell commands

## MITRE ATT&CK

- **T1566** — Initial Access: Phishing
- **T1059.001** — Execution: PowerShell
- **T1027** — Defense Evasion: Obfuscated Files or Information
- **T1003** — Credential Access: Credential Dumping (if applicable)

## Splunk Timeline

```spl
index=sysmon (EventID=1 OR EventID=3) host=WIN10
| timechart span=1m count by EventID
```

## Sample Event Detail (Sysmon Event ID 1)

| Field | Value (example) |
|---|---|
| Image | `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` |
| ParentImage | `Document_Update.exe` |
| CommandLine | `powershell -nop -w hidden -enc SQBFAFgA...` |
| User | testuser |
| IntegrityLevel | Medium |
| Hash (SHA256) | `1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c...` |

## Severity: Medium

## Recommended Action

- Treat the alert as a real phishing/malware attempt
- Collect evidence (email headers, file hash, process tree)
- Reach out to the user to confirm
- Monitor the host, isolate if necessary

## SOC Analyst Tip

Always check the command line and the parent/child process relationship — if present, correlate it against file monitoring too.

## Next Step

Next we'll look at how to investigate a suspicious PowerShell execution → [`03-powershell-execution.md`](./03-powershell-execution.md)
