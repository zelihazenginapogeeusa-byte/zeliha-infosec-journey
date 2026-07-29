# Memory & Disk Forensics Quick Reference

A condensed, command-first companion to `volatility-autopsy-forensics-cheatsheet-professional.md` — this one skips the explanations and gives you the plugin/command to run, in order, when you're under time pressure.

---

## 1. Volatility 3 — Standard Run Order

```bash
# Identify the profile/OS info first
vol -f memory.dmp windows.info

# Process listing (start here every time)
vol -f memory.dmp windows.pslist
vol -f memory.dmp windows.pstree      # parent/child relationships — look for odd lineage

# Hidden/unlinked processes
vol -f memory.dmp windows.psscan

# Network connections
vol -f memory.dmp windows.netscan

# Injected code / suspicious memory regions
vol -f memory.dmp windows.malfind

# Command-line arguments per process
vol -f memory.dmp windows.cmdline

# DLLs loaded per process
vol -f memory.dmp windows.dlllist

# Registry hives in memory
vol -f memory.dmp windows.registry.hivelist

# Dump a specific process for further analysis
vol -f memory.dmp windows.pslist --pid <pid> --dump
```

**What to look for in each:** `pslist` vs `psscan` mismatches (hidden process indicator) → `pstree` for a process with an unexpected parent (e.g., `winword.exe` spawning `cmd.exe`) → `malfind` for RWX memory regions with no backing file → `netscan` for connections to unfamiliar external IPs → `cmdline` for encoded/obfuscated command lines (cross-reference `command-line-obfuscation-evasion-cheatsheet.md`).

---

## 2. Volatility 2 (Legacy Syntax, Still Seen in Older Labs)

```bash
volatility -f memory.dmp --profile=<Profile> pslist
volatility -f memory.dmp --profile=<Profile> psscan
volatility -f memory.dmp --profile=<Profile> pstree
volatility -f memory.dmp --profile=<Profile> netscan
volatility -f memory.dmp --profile=<Profile> malfind
volatility -f memory.dmp --profile=<Profile> hivelist
```

---

## 3. Autopsy — Quick Workflow

1. **New Case** → add the disk image as a data source → let ingestion modules run (hash lookup, keyword search, recent activity, web artifacts).
2. **Timeline** view first — orient yourself around the time window that matters.
3. **Deleted Files** module — check for anti-forensic activity (evidence deletion attempts).
4. **Web Artifacts** — browser history, downloads, cookies, if user activity is in scope.
5. **Keyword Search** — search for known IOCs (filenames, strings from the incident) directly against the image.
6. **Registry Viewer** (via ingested `NTUSER.DAT`/`SYSTEM` hives) — run keys, USB history (`USBSTOR`), recently opened files (`RecentDocs`).

---

## 4. Windows Registry Quick Hits (Live or via Autopsy)

| Artifact | Registry path | Tells you |
|---|---|---|
| Run keys (persistence) | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` | Auto-starting programs |
| USB device history | `HKLM\SYSTEM\CurrentControlSet\Enum\USBSTOR` | Connected removable media |
| Recently opened files | `NTUSER.DAT\...\RecentDocs` | User file access history |
| Typed paths in Explorer | `NTUSER.DAT\...\TypedPaths` | Manually navigated folders |
| Shimcache/AmCache | `SYSTEM` hive / `C:\Windows\AppCompat\Programs\Amcache.hve` | Evidence of program execution, even if later deleted |
| UserAssist | `NTUSER.DAT\...\UserAssist` (ROT13-encoded) | GUI program execution history |

---

## 5. Quick Triage Order (When Time Is Short)

1. `pslist` + `pstree` — anything with a weird parent-child relationship or unfamiliar name.
2. `netscan` — anything connecting somewhere it shouldn't.
3. `malfind` — injected/unbacked memory.
4. Registry run keys + scheduled tasks (persistence).
5. Only then go deep on a specific process (dump + strings/YARA).

---

*Full-detail companion: [`volatility-autopsy-forensics-cheatsheet-professional.md`](volatility-autopsy-forensics-cheatsheet-professional.md) in this folder. Linux-side equivalent: [`linux-forensics-and-artifact-analysis-cheatsheet.md`](linux-forensics-and-artifact-analysis-cheatsheet.md).*
