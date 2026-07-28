# 🔵 DeepBlue CLI - Windows Event Log Analysis Complete Cheat Sheet

> **A Comprehensive Guide to DeepBlue for Windows Security Event Log Analysis and Threat Detection**

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [DeepBlue Basics](#deepblue-basics)
3. [Event Log Analysis](#event-log-analysis)
4. [Threat Detection](#threat-detection)
5. [Advanced Analysis](#advanced-analysis)
6. [Output Formats](#output-formats)
7. [Real-World Scenarios](#real-world-scenarios)
8. [Performance Optimization](#performance-optimization)
9. [Troubleshooting](#troubleshooting)

---

## Installation & Setup

### Requirements

```
- Windows 7 or later
- PowerShell 3.0 or higher
- Administrator privileges (recommended)
- .NET Framework 3.5+
```

### Check PowerShell Version

```powershell
# Check current PowerShell version
$PSVersionTable.PSVersion

# Output should be 3.0 or higher
# Version    Name                       Platform         PSCompatibleVersions
# -------    ----                       --------         --------------------
# 5.1.19041  PowerShell                 Win32NT          {1.0, 2.0, 3.0, 4.0...}
```

### Download DeepBlue

```powershell
# Clone from GitHub
git clone https://github.com/sans-blue-team/deepbluecli.git

# Or download manually
# https://github.com/sans-blue-team/deepbluecli

cd deepbluecli
```

### Set Execution Policy

```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set to allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify change
Get-ExecutionPolicy
```

### Verify Installation

```powershell
# Navigate to DeepBlue directory
cd C:\path\to\deepbluecli

# List available scripts
dir *.ps1

# Check for DeepBlue.ps1
ls DeepBlue.ps1
```

---

## DeepBlue Basics

### Basic Syntax

```powershell
# Syntax
.\DeepBlue.ps1 -Path <event_log_file> [-OutputFormat <format>]

# Simple usage
.\DeepBlue.ps1 -Path C:\Windows\System32\winevt\Logs\System.evtx

# With output format
.\DeepBlue.ps1 -Path C:\Windows\System32\winevt\Logs\Security.evtx -OutputFormat JSON
```

### Common Log File Locations

```powershell
# System logs (local)
C:\Windows\System32\winevt\Logs\System.evtx

# Security logs (local)
C:\Windows\System32\winevt\Logs\Security.evtx

# Application logs (local)
C:\Windows\System32\winevt\Logs\Application.evtx

# PowerShell logs
C:\Windows\System32\winevt\Logs\Windows PowerShell.evtx

# PowerShell Operational logs
C:\Windows\System32\winevt\Logs\Microsoft-Windows-PowerShell/Operational.evtx

# Sysmon logs (if installed)
C:\Windows\System32\winevt\Logs\Microsoft-Windows-Sysmon/Operational.evtx
```

### Export Event Logs

```powershell
# Export Security log
wevtutil export-log Security C:\Logs\Security.evtx /overwrite:true

# Export System log
wevtutil export-log System C:\Logs\System.evtx /overwrite:true

# Export Application log
wevtutil export-log Application C:\Logs\Application.evtx /overwrite:true

# Export PowerShell log
wevtutil export-log "Windows PowerShell" C:\Logs\PowerShell.evtx /overwrite:true

# Export Sysmon log
wevtutil export-log "Microsoft-Windows-Sysmon/Operational" C:\Logs\Sysmon.evtx /overwrite:true

# Export all logs
Get-WinEvent -ListLog * | ForEach-Object {
  wevtutil export-log $_.LogName "C:\Logs\$($_.LogName).evtx"
}
```

---

## Event Log Analysis

### Analyzing Local Logs

```powershell
# Analyze local Security log
.\DeepBlue.ps1

# Analyze specific local log type
.\DeepBlue.ps1 -Local Security

# Analyze System log
.\DeepBlue.ps1 -Local System

# Analyze Application log
.\DeepBlue.ps1 -Local Application

# Analyze PowerShell log
.\DeepBlue.ps1 -Local "Windows PowerShell"
```

### Analyzing Exported Logs

```powershell
# Analyze single exported log
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx

# Analyze System log file
.\DeepBlue.ps1 -Path C:\Logs\System.evtx

# Analyze PowerShell log file
.\DeepBlue.ps1 -Path C:\Logs\PowerShell.evtx

# Analyze Sysmon log file
.\DeepBlue.ps1 -Path C:\Logs\Sysmon.evtx
```

### Analyzing Remote Logs

```powershell
# Analyze remote computer logs
.\DeepBlue.ps1 -ComputerName remote-server

# With explicit credentials
.\DeepBlue.ps1 -ComputerName remote-server -Credential domain\username

# Analyze specific remote log
.\DeepBlue.ps1 -ComputerName remote-server -LogName Security
```

---

## Threat Detection

### Detection Capabilities

DeepBlue detects:

```
✅ Brute force attacks
✅ Clearing of Event Logs
✅ Disabled security features
✅ Lateral movement
✅ Privilege escalation
✅ Suspicious PowerShell usage
✅ Service installation anomalies
✅ Account creation/modification
✅ File share access anomalies
✅ Kerberos attacks
✅ Metasploit artifacts
✅ Mimikatz usage
```

### Security Log Analysis

```powershell
# Analyze for failed logins
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Select-String "logon failed"

# Analyze for account lockouts
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Select-String "lockout"

# Analyze for privilege escalation
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Select-String "privilege"

# Analyze for lateral movement
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Select-String "network"
```

### PowerShell Analysis

```powershell
# Analyze PowerShell logs for obfuscation
.\DeepBlue.ps1 -Path "C:\Logs\Windows PowerShell.evtx"

# Search for encoded commands
.\DeepBlue.ps1 -Path "C:\Logs\Windows PowerShell.evtx" | Select-String "encoded"

# Search for suspicious invocations
.\DeepBlue.ps1 -Path "C:\Logs\Windows PowerShell.evtx" | Select-String "invoke"

# Analysis for downloadstring (download execution)
.\DeepBlue.ps1 -Path "C:\Logs\Windows PowerShell.evtx" | Select-String "downloadstring"
```

### System Log Analysis

```powershell
# Analyze for service installation
.\DeepBlue.ps1 -Path C:\Logs\System.evtx | Select-String "service installed"

# Analyze for driver installation
.\DeepBlue.ps1 -Path C:\Logs\System.evtx | Select-String "driver"

# Analyze for system shutdown
.\DeepBlue.ps1 -Path C:\Logs\System.evtx | Select-String "shutdown"

# Analyze for critical errors
.\DeepBlue.ps1 -Path C:\Logs\System.evtx | Select-String "critical"
```

---

## Advanced Analysis

### Combining Multiple Logs

```powershell
# Create array of log files
$logs = @(
  "C:\Logs\Security.evtx",
  "C:\Logs\System.evtx",
  "C:\Logs\Application.evtx"
)

# Analyze each log
foreach ($log in $logs) {
  Write-Host "Analyzing $log..."
  .\DeepBlue.ps1 -Path $log
}
```

### Filtering Results

```powershell
# Save results to variable
$results = .\DeepBlue.ps1 -Path C:\Logs\Security.evtx

# Filter for specific events
$results | Where-Object { $_.EventID -eq 4625 }

# Filter for timestamp
$results | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-1) }

# Filter for username
$results | Where-Object { $_.UserID -like "*admin*" }
```

### Timeline Analysis

```powershell
# Get events in chronological order
$events = Get-WinEvent -Path C:\Logs\Security.evtx | Sort-Object TimeCreated

# Show events from last 24 hours
$events | Where-Object { $_.TimeCreated -gt (Get-Date).AddDays(-1) }

# Show events from specific time range
$startTime = (Get-Date).AddDays(-7)
$endTime = (Get-Date)
$events | Where-Object { $_.TimeCreated -ge $startTime -and $_.TimeCreated -le $endTime }
```

### Threat Scoring

```powershell
# DeepBlue provides threat scores (0-10)
# Run analysis and review threat levels

$results = .\DeepBlue.ps1 -Path C:\Logs\Security.evtx

# Filter for high-threat events (score 7+)
$results | Where-Object { $_.ThreatScore -ge 7 }

# Filter for critical (score 9-10)
$results | Where-Object { $_.ThreatScore -eq 10 }
```

---

## Output Formats

### Standard Output

```powershell
# Default text output
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx

# Output displays:
# [Timestamp] [Alert Level] [Event ID] [Details]
# EXAMPLE: [2024-01-15 14:32:10] [HIGH] [4625] Multiple failed logon attempts
```

### JSON Output

```powershell
# Export results to JSON
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx -OutputFormat JSON | Out-File results.json

# View JSON results
$json = Get-Content results.json | ConvertFrom-Json
$json | Format-Table
```

### CSV Output

```powershell
# Export results to CSV
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Export-Csv -Path results.csv -NoTypeInformation

# Read CSV file
$csv = Import-Csv results.csv
$csv | Format-Table
```

### HTML Report

```powershell
# Export to HTML
$results = .\DeepBlue.ps1 -Path C:\Logs\Security.evtx
$results | ConvertTo-Html -Title "DeepBlue Analysis Report" | Out-File report.html

# Open report
Start-Process report.html
```

### Saving to File

```powershell
# Save text output
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Out-File analysis.txt

# Save with timestamp
$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Out-File "analysis_$timestamp.txt"

# Append to existing file
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Out-File analysis.txt -Append
```

---

## Real-World Scenarios

### Scenario 1: Investigate Brute Force Attack

```powershell
# Step 1: Export Security log
wevtutil export-log Security C:\Logs\Security.evtx /overwrite:true

# Step 2: Run DeepBlue analysis
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx | Tee-Object -FilePath brute_force_analysis.txt

# Step 3: Filter for failed logins (Event ID 4625)
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4625 } | 
  Format-Table TimeCreated, @{Label="Username";Expression={$_.Properties[5].Value}}, 
  @{Label="WorkstationName";Expression={$_.Properties[13].Value}} -AutoSize

# Step 4: Count failures per user
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4625 } | 
  Group-Object -Property {$_.Properties[5].Value} | Sort-Object Count -Descending

# Step 5: Identify attack source
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4625 } | 
  Group-Object -Property {$_.Properties[13].Value} | Sort-Object Count -Descending
```

### Scenario 2: Detect Privilege Escalation

```powershell
# Step 1: Export Security log
wevtutil export-log Security C:\Logs\Security.evtx /overwrite:true

# Step 2: Run DeepBlue analysis
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx

# Step 3: Look for Token Elevation (Event ID 4672)
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4672 } | 
  Format-Table TimeCreated, @{Label="Account";Expression={$_.Properties[1].Value}} -AutoSize

# Step 4: Look for Privileged Service Called (Event ID 4673)
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4673 }

# Step 5: Investigate timing correlation
$escalations = Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4672 }
$escalations | Select-Object TimeCreated | Sort-Object TimeCreated
```

### Scenario 3: Identify Suspicious PowerShell Usage

```powershell
# Step 1: Export PowerShell log
wevtutil export-log "Windows PowerShell" C:\Logs\PowerShell.evtx /overwrite:true

# Step 2: Run DeepBlue analysis
.\DeepBlue.ps1 -Path C:\Logs\PowerShell.evtx

# Step 3: Look for encoded commands
Get-WinEvent -Path C:\Logs\PowerShell.evtx | Select-String -Pattern "EncodedCommand|FromBase64"

# Step 4: Look for suspicious invocations
Get-WinEvent -Path C:\Logs\PowerShell.evtx | Select-String -Pattern "Invoke-|IEX|DownloadString"

# Step 5: Check execution policy bypass
Get-WinEvent -Path C:\Logs\PowerShell.evtx | Select-String -Pattern "ExecutionPolicy|Bypass"

# Step 6: Analyze script block logs (Event ID 4104)
Get-WinEvent -Path C:\Logs\PowerShell.evtx | Where-Object { $_.ID -eq 4104 }
```

### Scenario 4: Track Lateral Movement

```powershell
# Step 1: Export Security log from multiple systems
# (Or use -ComputerName parameter for remote analysis)

# Step 2: Look for network logons (Event ID 4624 Type 3)
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4624 } | 
  Where-Object { $_.Properties[8].Value -eq 3 } | 
  Format-Table TimeCreated, @{Label="Username";Expression={$_.Properties[5].Value}} -AutoSize

# Step 3: Identify source IPs
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4624 } | 
  Where-Object { $_.Properties[8].Value -eq 3 } | 
  Group-Object -Property {$_.Properties[18].Value} | Sort-Object Count -Descending

# Step 4: Look for share access (Event ID 5140)
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 5140 }

# Step 5: Timeline lateral movement
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4624 -or $_.ID -eq 5140 } | 
  Sort-Object TimeCreated | Format-Table TimeCreated, ID, Message -AutoSize
```

### Scenario 5: Detect Event Log Tampering

```powershell
# Step 1: Check for cleared logs (Event ID 104)
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 104 }

# Step 2: Look for suspicious log deletions
Get-WinEvent -ListLog * | ForEach-Object {
  try {
    Get-WinEvent -LogName $_.LogName | Where-Object { $_.ID -eq 104 }
  } catch {}
}

# Step 3: Check for disabled audit policies (Event ID 4719)
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4719 }

# Step 4: Look for WMI event binding (Event ID 5859) - Potential persistence
Get-WinEvent -Path C:\Logs\System.evtx | Where-Object { $_.ID -eq 5859 }

# Step 5: Run full DeepBlue analysis
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx
```

---

## Performance Optimization

### Large Log File Analysis

```powershell
# For very large log files (>1GB)
# DeepBlue may take a while - be patient

# Check file size
(Get-Item C:\Logs\Security.evtx).Length / 1GB

# Run with verbose output (see progress)
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx -Verbose

# Increase PowerShell memory limit
$PSDefaultParameterValues['Out-GridView:Title'] = 'DeepBlue Results'
```

### Archive Old Logs

```powershell
# Archive logs older than 30 days
$cutoffDate = (Get-Date).AddDays(-30)
$logFiles = Get-ChildItem C:\Logs\*.evtx | Where-Object { $_.LastWriteTime -lt $cutoffDate }

foreach ($file in $logFiles) {
  # Compress to zip
  Compress-Archive -Path $file.FullName -DestinationPath "$($file.FullName).zip" -Force
  
  # Delete original
  Remove-Item $file.FullName -Force
}
```

### Batch Processing

```powershell
# Process multiple log files in batch
$logDirectory = "C:\Logs\"
$logFiles = Get-ChildItem "$logDirectory*.evtx"

foreach ($logFile in $logFiles) {
  Write-Host "Analyzing $($logFile.Name)..."
  $timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
  .\DeepBlue.ps1 -Path $logFile.FullName | Out-File "$logDirectory\analysis_$($logFile.BaseName)_$timestamp.txt"
}
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Cannot find file" | Verify log file path, ensure file exists |
| "Access Denied" | Run PowerShell as Administrator |
| "Execution Policy" | Set-ExecutionPolicy -ExecutionPolicy RemoteSigned |
| "No results" | Check if log file has events, try different log |
| "Timeout" | Large log file - be patient, or analyze older logs first |

### Debug Commands

```powershell
# Check if log file is valid
Test-Path C:\Logs\Security.evtx

# Get log file size
(Get-Item C:\Logs\Security.evtx).Length

# Test event log reading
Get-WinEvent -Path C:\Logs\Security.evtx | Measure-Object

# Enable verbose logging
Set-PSDebug -Trace 1
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx
Set-PSDebug -Trace 0
```

### Fix Corrupted Logs

```powershell
# Export and reimport to repair
wevtutil export-log Security C:\Logs\Security_backup.evtx /overwrite:true

# Clear corrupted log
Clear-EventLog -LogName Security

# Re-import events
wevtutil import-log C:\Logs\Security_backup.evtx /lf:true
```

---

## Quick Reference Commands

### Most Used Commands

```powershell
# Analyze local Security log
.\DeepBlue.ps1 -Local Security

# Analyze exported log file
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx

# Export Security log
wevtutil export-log Security C:\Logs\Security.evtx /overwrite:true

# Get Windows PowerShell log location
Get-WinEvent -ListLog "Windows PowerShell"

# View recent events
Get-WinEvent -LogName Security -MaxEvents 100

# Clear event log (requires admin)
Clear-EventLog -LogName Security
```

---

## BTL1 Exam Tips

### Key Concepts for BTL1

✅ Understanding Windows Event Log structure  
✅ Event ID significance (4625, 4672, 4719, etc.)  
✅ Threat detection patterns  
✅ Log analysis techniques  
✅ Incident response based on event logs  
✅ Timeline reconstruction  
✅ Evidence preservation  

### Study Preparation

```powershell
# 1. Set up test environment
# Create sample log files

# 2. Practice exports
wevtutil export-log Security C:\Logs\Security.evtx /overwrite:true

# 3. Run DeepBlue analysis
.\DeepBlue.ps1 -Path C:\Logs\Security.evtx

# 4. Practice filtering results
Get-WinEvent -Path C:\Logs\Security.evtx | Where-Object { $_.ID -eq 4625 }

# 5. Document findings
# Create incident report templates

# 6. Understand alert levels
# Review what constitutes HIGH/MEDIUM/LOW severity
```

---

## Resources

### Official Documentation
- [DeepBlue GitHub](https://github.com/sans-blue-team/deepbluecli)
- [Microsoft Event Log Reference](https://docs.microsoft.com/en-us/windows/security/threat-protection/auditing/audit-events)
- [Windows Event ID Reference](https://www.ultimatewindowssecurity.com/securitylog/encyclopedia/)

### Learning Resources
- [SANS Blue Team](https://www.sans.org/blue-team/)
- [TryHackMe Blue Team](https://tryhackme.com/)
- [HackTheBox Defensive Labs](https://www.hackthebox.com/)

### Related Tools
- **Event Viewer** - Built-in Windows log viewer
- **Sysmon** - Advanced system monitoring
- **Splunk** - Enterprise log analysis
- **ELK Stack** - Log aggregation and analysis

---

## BTL1 Checklist

### Before Exam

- [ ] Install DeepBlue on test system
- [ ] Practice exporting event logs
- [ ] Understand major event IDs (4625, 4672, 4719, 4103, 4104)
- [ ] Practice timeline reconstruction
- [ ] Learn threat detection patterns
- [ ] Master filtering and sorting
- [ ] Understand JSON/CSV export
- [ ] Practice on HTB/TryHackMe blue team challenges
- [ ] Review incident response procedures
- [ ] Document sample findings

### Key Event IDs to Know

```
4624 - Successful logon
4625 - Failed logon
4672 - Special privileges assigned
4673 - Privileged service called
4688 - New process created
4698 - Scheduled task created
4719 - Audit policy changed
4728 - User added to security group
5140 - Network share accessed
104  - Event log cleared
```

---

## Quick Reference Table

| Task | Command |
|------|---------|
| Export Security log | `wevtutil export-log Security C:\Logs\Security.evtx` |
| Analyze local log | `.\DeepBlue.ps1 -Local Security` |
| Analyze exported log | `.\DeepBlue.ps1 -Path C:\Logs\Security.evtx` |
| View failed logins | `Get-WinEvent -LogName Security \| Where-Object { $_.ID -eq 4625 }` |
| Export to JSON | `.\DeepBlue.ps1 -Path C:\Logs\Security.evtx \| ConvertTo-Json` |
| Export to CSV | `... \| Export-Csv -Path results.csv` |
| Clear event log | `Clear-EventLog -LogName Security` |
| Get log statistics | `Get-WinEvent -LogName Security \| Measure-Object` |
| Timeline events | `Get-WinEvent -LogName Security \| Sort-Object TimeCreated` |

---

## Conclusion

DeepBlue CLI is an essential tool for Blue Team professionals. It:

✅ Analyzes Windows event logs efficiently  
✅ Detects threat indicators automatically  
✅ Supports multiple output formats  
✅ Integrates into incident response workflows  
✅ Critical for BTL1 certification  

Master DeepBlue and you'll be able to quickly identify and respond to security incidents!

---

<div align="center">

### Master DeepBlue. Master Blue Team. 🔵

**Good luck with BTL1! 💪**

</div>

---

**Last Updated:** June 2026  
**Status:** Production Ready  
**Format:** eJPT v2 Style Professional Documentation

---

© 2026 | DeepBlue CLI Cheat Sheet | Educational Purpose
