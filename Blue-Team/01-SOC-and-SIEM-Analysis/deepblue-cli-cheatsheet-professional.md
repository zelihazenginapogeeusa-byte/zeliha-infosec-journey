# DeepBlueCLI Cheat Sheet

**DeepBlueCLI** is a PowerShell-based hunting module (by Eric Conrad) that automates the search through Windows Event Logs for patterns attackers leave behind, turning manual Event ID lookups into a single scripted pass. It belongs to BTL1's Digital Forensics & Incident Response module, and it matters because it compresses hours of manual log review into seconds of automated triage on a suspect host.

---

## Table of Contents

1. [What DeepBlueCLI Is](#1-what-deepbluecli-is)
2. [Installation & Basic Usage](#2-installation--basic-usage)
3. [What It Detects](#3-what-it-detects)
4. [Running Against Live Logs vs Saved .evtx Files](#4-running-against-live-logs-vs-saved-evtx-files)
5. [Interpreting Output](#5-interpreting-output)
6. [Where It Fits in DFIR Workflow](#6-where-it-fits-in-dfir-workflow)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. What DeepBlueCLI Is

DeepBlueCLI doesn't introduce new detection knowledge — it's the automation layer built on top of already knowing which Event IDs matter, applying that knowledge programmatically to a log file so an analyst doesn't have to eyeball thousands of records by hand.

- Written in PowerShell, open-sourced by Eric Conrad (SANS instructor, co-author of the BTL1-relevant *CISSP Study Guide*)
- Parses `.evtx` files (or the live Security/System/Application logs) and flags entries matching known-bad or suspicious patterns
- Designed to be run first, fast, on a single host — not a replacement for a SIEM, but a lightweight companion to one
- Effectively a scripted, offline expression of everything in `windows-event-id-reference-cheatsheet-professional.md` — it knows which Event IDs matter and checks their contents for you

---

## 2. Installation & Basic Usage

DeepBlueCLI ships as a PowerShell script with no external dependencies beyond PowerShell itself, so getting it running takes only a clone and a single command.

```powershell
# Clone the repository
git clone https://github.com/sans-blue-team/DeepBlueCLI.git
cd DeepBlueCLI

# Run against a saved .evtx file
.\DeepBlue.ps1 <path-to-evtx-file>

# Example: analyzing an exported Security log
.\DeepBlue.ps1 .\evtx\new-user-security.evtx
```

> Requires Windows PowerShell (5.1) or PowerShell Core — some environments require `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process` to allow the unsigned script to run.

---

## 3. What It Detects

DeepBlueCLI's detection logic maps directly onto a small set of high-value Event IDs; each category below corresponds to entries you'd otherwise be hunting for manually in `windows-event-id-reference-cheatsheet-professional.md`.

| Detection Category | What Gets Flagged | Underlying Event ID(s) |
|---|---|---|
| Obfuscated/encoded PowerShell | `-enc`, `-EncodedCommand`, `IEX`, `DownloadString`, Base64-encoded blobs | 4104 (Script Block Logging) |
| Suspicious command lines | Long, unusual, or high-entropy command lines; known LOLBin patterns | 4688 (process creation) |
| Account creation/lockouts | New accounts, accounts added to privileged groups, lockout bursts | 4720, 4732, 4740 |
| Service creation | New services installed (a common persistence/lateral-movement technique, e.g. PsExec) | 7045 |
| Mimikatz-style keywords | Known credential-dumping tool strings and command-line artifacts | 4688 / 4104 |
| PowerShell downloads | `Net.WebClient`, `Invoke-WebRequest`, `DownloadString`/`DownloadFile` calls | 4104 |

---

## 4. Running Against Live Logs vs Saved .evtx Files

DeepBlueCLI can either analyze an exported log file offline or hunt directly against a live host's current log — which mode to use depends on whether you're doing remote triage or working hands-on-keyboard.

```powershell
# Export the Security log to a portable .evtx file first (for offline analysis or evidence preservation)
wevtutil epl Security C:\triage\security.evtx

# Then feed the exported file into DeepBlueCLI
.\DeepBlue.ps1 C:\triage\security.evtx

# Alternatively, run live against the current Security log on the local host
.\DeepBlue.ps1 -log security

# Or against the System log, for service-creation hunting
.\DeepBlue.ps1 -log system
```

> Exporting first with `wevtutil` preserves the log as evidence and lets you run DeepBlueCLI against a copy on your analysis workstation rather than the live host — preferred during a real incident to avoid disturbing the source machine.

---

## 5. Interpreting Output

A flagged result is a starting point for investigation, not a verdict — DeepBlueCLI surfaces pattern matches, and every hit still needs manual context to determine if it's actually malicious.

```
Date : 3/15/2024 2:47:11 PM
Log : Security
EventID : 4688
Command : powershell.exe -enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQA...
Message : Encoded command
Results : Base64-encoded, decodes to: IEX (New-Object Net.WebClient).DownloadString(...)
Decoded : IEX (New-Object Net.WebClient).DownloadString('http://...')
```

- [ ] Decode any Base64 blob DeepBlueCLI flags and read the underlying command
- [ ] Check whether the parent process (from 4688 or Sysmon 1) is expected for that user/host
- [ ] Cross-reference the account and timestamp against known admin activity or change tickets
- [ ] Remember: legitimate sysadmin scripts and software deployment tools (e.g. SCCM, Chef, Ansible remoting) routinely use encoded PowerShell — a flag is not automatically an incident

---

## 6. Where It Fits in DFIR Workflow

DeepBlueCLI's role is speed: run it first on a suspect host's exported logs to triage quickly, then escalate to manual Event ID hunting or full SIEM correlation only once it points you somewhere specific.

1. Suspect host identified → export relevant logs with `wevtutil`
2. Run DeepBlueCLI against the export for a fast first pass
3. Manually verify flagged entries using the Event ID meanings in `windows-event-id-reference-cheatsheet-professional.md`
4. If the incident spans multiple hosts, pivot to `siem-splunk-elk-cheatsheet-professional.md` to write correlation queries across the whole environment
5. Feed confirmed findings into the containment/eradication phase described in `incident-response-lifecycle-cheatsheet-professional.md`

---

## 7. Quick Command Reference

The commands you'll reach for most often when running DeepBlueCLI during triage.

| Command | Purpose |
|---|---|
| `git clone https://github.com/sans-blue-team/DeepBlueCLI.git` | Download the tool |
| `.\DeepBlue.ps1 <file.evtx>` | Analyze a saved/exported .evtx file |
| `.\DeepBlue.ps1 -log security` | Analyze the live local Security log |
| `.\DeepBlue.ps1 -log system` | Analyze the live local System log (service creation) |
| `wevtutil epl Security C:\triage\security.evtx` | Export a log to .evtx before analysis |
| `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process` | Allow the unsigned script to run in the current session |

---

*Prepared as a reference for the BTL1 Digital Forensics & Incident Response module.*
