# Malware Analysis & YARA Rules Cheat Sheet

Takes the attachment-analysis section of `phishing-cheatsheet.md` a level further — static analysis fundamentals and YARA rule writing for BTL1's **Malware Analysis** module.

---

## Table of Contents

1. [Static vs Dynamic Analysis](#1-static-vs-dynamic-analysis)
2. [Initial Triage: Hash & Reputation](#2-initial-triage-hash--reputation)
3. [Static Analysis Tools](#3-static-analysis-tools)
4. [PE (Portable Executable) Analysis](#4-pe-portable-executable-analysis)
5. [Office Macro Analysis](#5-office-macro-analysis)
6. [YARA Rules](#6-yara-rules)
7. [Dynamic Analysis (Sandbox)](#7-dynamic-analysis-sandbox)
8. [Obfuscation Indicators](#8-obfuscation-indicators)
9. [Quick Command Reference](#9-quick-command-reference)

---

## 1. Static vs Dynamic Analysis

The first decision point for any suspicious file — whether to examine it without running it, or detonate it in an isolated sandbox.

| | Static Analysis | Dynamic Analysis |
|---|---|---|
| **How** | Examining the file **without executing** it (strings, disassembly, hashing) | **Running** the file in an isolated sandbox and observing its behavior |
| **Risk** | Low — the file never runs | High — isolation is mandatory |
| **Finding type** | Code structure, strings, signatures, embedded resources | Network traffic, filesystem changes, process behavior |
| **Tools** | `strings`, PEStudio, `oledump`/`olevba`, YARA | Any.Run, Hybrid Analysis, Cuckoo Sandbox |

> **Static always comes first, even for dynamic analysis:** an initial static look (is it packed, what language, what signatures) tells you what to look for once it's in the sandbox.

---

## 2. Initial Triage: Hash & Reputation

Hashing the sample first lets you check whether it's already a known, previously-analyzed threat before spending time on deeper analysis.

```bash
sha256sum suspicious.exe
md5sum suspicious.exe
```

Query the hash on **VirusTotal** — has it been seen before, how many AV engines flag it as malicious, what family is it classified as.

> **Zero AV detections doesn't mean clean.** New/custom-written malware often shows 0/70 in its first few days — in that case, continue with static/dynamic analysis regardless.

---

## 3. Static Analysis Tools

These tools let you pull strings, headers, and structural details out of a file without ever executing it.

```bash
file suspicious.exe                  # File type detection (real type vs. apparent extension)
strings suspicious.exe | less         # Extract readable strings
strings -n 8 suspicious.exe | grep -i "http\|cmd\|powershell"   # Search for URLs/commands

# PE header info
pefile / PEStudio (GUI) — import/export table, compile timestamp, section names
```

| String type to look for | What it indicates |
|---|---|
| URL/domain | C2 server, download location |
| Registry path | A persistence mechanism |
| File path (`C:\Users\...`) | Hints about the development environment |
| API name (`VirtualAlloc`, `WriteProcessMemory`) | An indicator of process injection |
| Base64 block | An obfuscated payload/command |

---

## 4. PE (Portable Executable) Analysis

What to check with **PEStudio** or `pefile`:

- [ ] **Import Table** — which Windows APIs are used (`CreateRemoteThread`, `VirtualAllocEx` = injection; `InternetOpenUrl` = network communication)
- [ ] **Compile Timestamp** — when the binary was compiled (can be forged, but still a first clue)
- [ ] **Section Names** — non-standard section names (outside `.text`, `.data`) indicate packing/obfuscation
- [ ] **Entropy** — high entropy (7.5+) usually indicates encryption/packing
- [ ] **Digital Signature** — is it signed, is the signature valid, who signed it

```bash
# Simple entropy calculation
python3 -c "
import math, collections
data = open('suspicious.exe','rb').read()
freq = collections.Counter(data)
entropy = -sum((c/len(data))*math.log2(c/len(data)) for c in freq.values())
print(f'Entropy: {entropy:.2f}')
"
```

---

## 5. Office Macro Analysis

Office documents remain one of the most common phishing delivery mechanisms, so extracting and reading embedded VBA macros is a core static-analysis skill.

```bash
oledump.py suspicious.doc            # Stream list + which stream has the macro (marked with M)
oledump.py suspicious.doc -s 7 -v    # Dump stream 7 as VBA

olevba suspicious.doc                # Automatic VBA extraction + suspicious-keyword scanning
olevba --deobf suspicious.doc        # With a deobfuscation attempt
```

**"AutoExec" and "Suspicious" flags to look for in olevba output:**

| Keyword | Meaning |
|---|---|
| `AutoOpen` / `Document_Open` | Auto-runs when the document is opened |
| `Shell` / `WScript.Shell` | Executes a system command |
| `CreateObject` | Creating a COM object (usually abused) |
| `URLDownloadToFile` | Downloading a second-stage payload |
| `Chr` / string concatenation chains | String obfuscation |

---

## 6. YARA Rules

YARA is a rule engine for finding **patterns (strings/bytes/conditions)** in files/memory — used to signature malware families or to search for a given campaign's IOCs across a SIEM/EDR.

### Basic rule structure

```yara
rule Suspicious_PowerShell_Encoded
{
    meta:
        author = "analyst"
        description = "Detects base64 encoded PowerShell commands"
        date = "2026-07-28"

    strings:
        $enc1 = "-enc" nocase
        $enc2 = "-EncodedCommand" nocase
        $b64  = /[A-Za-z0-9+\/]{100,}={0,2}/

    condition:
        (any of ($enc1, $enc2)) and $b64
}
```

```yara
rule Phishing_Macro_Dropper
{
    meta:
        description = "Flags Office documents with dropper-style macro indicators"

    strings:
        $auto1 = "AutoOpen" nocase
        $auto2 = "Document_Open" nocase
        $shell = "Shell(" nocase
        $dl    = "URLDownloadToFile" nocase

    condition:
        1 of ($auto1, $auto2) and 1 of ($shell, $dl)
}
```

| Section | Purpose |
|---|---|
| `meta` | The rule's description, author — purely documentation, doesn't drive detection |
| `strings` | The text/regex/hex byte patterns to search for (defined with `$name`) |
| `condition` | The logic for which/how many strings must match, and in what combination |

```bash
# Run a YARA rule against a file/directory
yara rule.yar suspicious.exe
yara -r rule.yar /path/to/samples/       # Recursive scan
```

---

## 7. Dynamic Analysis (Sandbox)

Use Any.Run/Hybrid Analysis (covered in `phishing-cheatsheet.md`) here with a focus on the malware's **behavior**:

- [ ] What processes did it spawn (process tree)
- [ ] What files did it create/modify (dropped files)
- [ ] What registry keys did it change (persistence)
- [ ] What network connections did it open (C2 domain/IP, protocol/port used)
- [ ] Any sandbox-detection/evasion behavior (VM checks, sleep timers)

> ⚠️ Never run this on a personal/corporate machine — always use an isolated, snapshottable VM or a cloud sandbox.

---

## 8. Obfuscation Indicators

These are the tell-tale signs that a sample is deliberately hiding its functionality from static analysis and signature-based detection.

| Indicator | Description |
|---|---|
| **High entropy** (7.5+) | Encryption/packing |
| **Few/meaningless imports** | May be loaded dynamically at runtime (via GetProcAddress) |
| **Base64/hex blocks** | An obfuscated command/payload |
| **String concatenation chains** | Simple signature evasion, e.g. `"po" + "wer" + "shell"` |
| **Packer signatures** (UPX, etc.) | The packer's name in `strings`, or non-standard section names |

---

## 9. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| File type detection | `file suspicious.exe` |
| Hash calculation | `sha256sum suspicious.exe` |
| String extraction | `strings -n 8 suspicious.exe` |
| Macro stream list | `oledump.py suspicious.doc` |
| Macro extraction | `olevba suspicious.doc` |
| Run a YARA rule | `yara rule.yar suspicious.exe` |
| Recursive YARA scan | `yara -r rule.yar /path/` |

---

*Prepared as a reference for the BTL1 Malware Analysis module. Always examine suspicious files in an isolated environment.*
