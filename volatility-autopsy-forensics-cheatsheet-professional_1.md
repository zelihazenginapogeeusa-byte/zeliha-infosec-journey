# Digital Forensics: Volatility & Autopsy Cheat Sheet

The two workhorse tools of BTL1's **Digital Forensics & Incident Response (DFIR)** module: **Volatility** (memory forensics) and **Autopsy** (disk forensics). This document covers the core workflow for both.

---

## Table of Contents

1. [Memory vs Disk Forensics](#1-memory-vs-disk-forensics)
2. [Volatility3 Basics](#2-volatility3-basics)
3. [Volatility: Process Analysis](#3-volatility-process-analysis)
4. [Volatility: Network & Malware Detection](#4-volatility-network--malware-detection)
5. [Volatility: Credentials & Registry](#5-volatility-credentials--registry)
6. [Autopsy Basics](#6-autopsy-basics)
7. [Autopsy: Investigation Workflow](#7-autopsy-investigation-workflow)
8. [Chain of Custody](#8-chain-of-custody)
9. [Quick Command Reference](#9-quick-command-reference)

---

## 1. Memory vs Disk Forensics

| | Memory (Volatility) | Disk (Autopsy) |
|---|---|---|
| **What it captures** | Currently running processes, network connections, encryption keys, injected code | Deleted files, filesystem metadata, browser history, registry hives |
| **When it's collected** | While the system is still running (**volatile** — lost on shutdown) | While the system is off / after an image has been taken |
| **Typical finding** | Fileless malware, injected code, an active C2 connection | Persistent malware, user activity history, deleted evidence |

> **Order matters:** In an incident response, always collect **volatile** data (RAM) first, then image the disk — RAM changes every second, disk doesn't.

---

## 2. Volatility3 Basics

```bash
# Identify the memory image's profile/OS info
vol -f memory.dmp windows.info

# General usage pattern
vol -f memory.dmp <plugin_name> [options]
```

| Plugin prefix | For |
|---|---|
| `windows.*` | Windows memory images |
| `linux.*` | Linux memory images |

---

## 3. Volatility: Process Analysis

```bash
vol -f memory.dmp windows.pslist        # Running process list (linked-list based)
vol -f memory.dmp windows.psscan        # Pool-scanning that also finds hidden/terminated processes
vol -f memory.dmp windows.pstree        # Parent-child process tree — critical for spotting anomalous parents
vol -f memory.dmp windows.cmdline       # Command lines processes were launched with
vol -f memory.dmp windows.dlllist --pid 1234   # DLLs loaded by a specific process
```

> **`pslist` vs `psscan`:** `pslist` only shows the processes the OS itself knows about (i.e. present in the linked list) — malware can manipulate this list (DKOM — Direct Kernel Object Manipulation). `psscan` scans memory pools directly and finds hidden/unlinked processes too. The gap between the two is the key to **process hiding** detection.

**Examples of suspicious parent-child relationships:**
- `winword.exe` → `powershell.exe` (macro-based attack)
- `svchost.exe` running from an unexpected parent (should normally be `services.exe`)
- An unknown process accessing `lsass.exe` (credential dumping)

---

## 4. Volatility: Network & Malware Detection

```bash
vol -f memory.dmp windows.netscan       # Active/historical network connections
vol -f memory.dmp windows.netstat       # netstat-like output

vol -f memory.dmp windows.malfind       # Detects injected/suspicious memory regions
vol -f memory.dmp windows.ldrmodules    # Detects hidden/unlinked DLLs

vol -f memory.dmp windows.filescan | grep -i ".exe"   # Search for files referenced in memory
```

> `malfind` flags RWX (read-write-execute) memory regions that legitimate processes normally don't have — a classic indicator of process injection/hollowing.

---

## 5. Volatility: Credentials & Registry

```bash
vol -f memory.dmp windows.hashdump        # Extract NTLM hashes from the SAM
vol -f memory.dmp windows.cachedump       # Cached domain credentials
vol -f memory.dmp windows.registry.printkey --key "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"  # Persistence detection
```

> Registry `Run`/`RunOnce` keys are a classic **persistence** mechanism — always checked in DFIR.

---

## 6. Autopsy Basics

Autopsy is the GUI for **The Sleuth Kit** — it performs filesystem, deleted-file, and timeline analysis on a disk image (E01, DD, RAW).

**New case workflow:**
1. `New Case` → set a case name and directory
2. `Add Data Source` → add the disk image (`.E01`, `.dd`, `.001`) or a live disk
3. Select analysis modules: `Recent Activity`, `Hash Lookup`, `Keyword Search`, `Timeline`

---

## 7. Autopsy: Investigation Workflow

| Section | What you find there |
|---|---|
| **Data Sources / File System** | Folder structure, deleted files (flagged in red) |
| **Deleted Files** | Filesystem-level recoverable deleted files |
| **Timeline** | A chronological view of every filesystem + registry event — answers "what happened when" |
| **Keyword Search** | String/regex search across the whole image (an email address, an IP, a filename) |
| **Web Artifacts** | Browser history, downloads, cookies |
| **Registry Hive Analysis** | User activity (RecentDocs, UserAssist), installed software, USB history |
| **Email/Attachments** | Email extraction from .pst/.ost files |

> **Timeline** is especially important: it's used to cross-verify an Event ID/log finding (like the ones in the Windows Event ID Reference sheet) against filesystem events (file creation/modification).

---

## 8. Chain of Custody

For preserving the evidence's validity through the forensic process/report:

- [ ] Log **who, when, where, and how** accessed the evidence from the moment you collected it.
- [ ] **Never** work directly on the original disk/RAM image — always work on a hashed (MD5/SHA256) copy.
- [ ] Use a **write-blocker** (hardware or software) when imaging — to avoid altering the original media.
- [ ] Document every step (tool, version, command, timestamp) to ensure repeatability.

```bash
# Verify image integrity
md5sum evidence.dd
sha256sum evidence.dd
```

---

## 9. Quick Command Reference

| Need | Command |
|---|---|
| OS/profile detection | `vol -f memory.dmp windows.info` |
| Process list | `vol -f memory.dmp windows.pslist` |
| Hidden process scan | `vol -f memory.dmp windows.psscan` |
| Process tree | `vol -f memory.dmp windows.pstree` |
| Command lines | `vol -f memory.dmp windows.cmdline` |
| Network connections | `vol -f memory.dmp windows.netscan` |
| Injection detection | `vol -f memory.dmp windows.malfind` |
| Hash dump (SAM) | `vol -f memory.dmp windows.hashdump` |
| Registry Run key | `vol -f memory.dmp windows.registry.printkey --key "...\Run"` |
| Image hash verification | `sha256sum evidence.dd` |

---

*Prepared as a reference for the BTL1 Digital Forensics & Incident Response module.*
