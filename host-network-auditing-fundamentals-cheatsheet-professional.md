# Host & Network Auditing Fundamentals Cheat Sheet

This document covers the eJPT "Host & Network Auditing" module — baseline security auditing of hosts and networks against a known configuration standard, a discipline distinct from active exploitation; it complements `linux-windows-pentest-cheatsheet-professional.md` (which exploits the weaknesses this document finds proactively) and `nmap-cheatsheet-professional.md` (whose scan output feeds the network-level baseline checks in Section 5).

---

## Table of Contents

1. [Auditing vs. Penetration Testing](#1-auditing-vs-penetration-testing)
2. [CIS Benchmarks](#2-cis-benchmarks)
3. [Windows Host Audit Checks](#3-windows-host-audit-checks)
4. [Linux Host Audit Checks](#4-linux-host-audit-checks)
5. [Network-Level Auditing Basics](#5-network-level-auditing-basics)
6. [Audit Workflow & Checklist](#6-audit-workflow--checklist)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. Auditing vs. Penetration Testing

Auditing, vulnerability assessment, and penetration testing are three related but distinct assessment types that eJPT expects candidates to tell apart before touching a single host.

| Assessment Type | Access Model | Goal | Adversarial? |
|---|---|---|---|
| **Security Audit** | Credentialed, full access (often admin/root) | Verify configuration matches a known standard/baseline (e.g. CIS Benchmark, internal policy) | No — cooperative, compliance-driven |
| **Vulnerability Assessment (VA)** | Usually unauthenticated or lightly authenticated scanning | Identify and rank known vulnerabilities (missing patches, CVEs) | No — passive/scan-based, no exploitation |
| **Penetration Test** | Starts unauthenticated (black/grey box) | Prove impact by actively exploiting weaknesses to gain access | Yes — adversarial simulation |

> **Note:** An audit answers "does this host comply with the standard?" A pentest answers "can an attacker actually break in, and how far can they get?" Both may surface the exact same misconfiguration — a weak password policy or an open SSH port with root login enabled — but the audit documents it as a compliance gap while the pentest chains it into a foothold.

Audits are typically performed *with* credentials and legitimate access provided by the client up front, since the objective is to inspect configuration, not to test whether an attacker could obtain that access in the first place.

---

## 2. CIS Benchmarks

The CIS (Center for Internet Security) Benchmarks are the most widely referenced configuration-hardening standard and the de facto baseline eJPT-style audit questions are built around.

| Concept | Description |
|---|---|
| **Profile** | Two standard profiles per benchmark — **Level 1** (basic hardening, minimal operational impact, safe for most environments) and **Level 2** (defense-in-depth, stricter, may affect functionality — used in high-security environments) |
| **Scope** | Benchmarks exist per platform/product: Windows Server, Windows 10/11, Ubuntu/RHEL Linux, Docker, AWS, Apache, etc. |
| **Format** | Each control lists: a description, rationale, the exact remediation steps (registry key, command, or config file setting), and an audit procedure to verify current state |
| **Delivery** | Free PDF benchmarks from cisecurity.org; automated scoring via **CIS-CAT Pro** or open tools that map to benchmark IDs |

Typical CIS control categories referenced during a host audit:

- **Account & password policies** — minimum length, complexity, lockout threshold, maximum age
- **Audit logging** — which event categories are logged (logon, object access, policy change)
- **Network configuration** — firewall state, disabled/unnecessary protocols (SMBv1, Telnet), listening services
- **OS/system hardening** — unnecessary services disabled, secure boot settings, patch management, file/registry permissions

> **Note:** A benchmark control is only useful if it maps to a verifiable command — every check in Sections 3-4 below is effectively a manual, single-host version of a CIS audit procedure.

---

## 3. Windows Host Audit Checks

These are the core commands used to manually verify a Windows host's configuration against CIS-style controls, without any exploitation involved.

```powershell
# Password & account lockout policy
net accounts

# Local Administrators group membership (who has admin rights?)
net localgroup Administrators

# Windows Firewall profile status (Domain/Private/Public)
netsh advfirewall show allprofiles state
Get-NetFirewallProfile | Select-Object Name, Enabled

# Installed patches / hotfix level
wmic qfe list brief /format:table
Get-HotFix | Sort-Object InstalledOn -Descending

# Audit policy — which event categories are actually being logged
auditpol /get /category:*

# Local user account list & status (enabled/disabled, password age)
net user
Get-LocalUser | Select-Object Name, Enabled, PasswordLastSet

# Installed software inventory
wmic product get name,version
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion
```

| Check | What "good" looks like |
|---|---|
| Password policy | Minimum length ≥ 14, lockout threshold set (typically ≤ 10 attempts), max age enforced |
| Local admin group | Small, known, documented list — no shared/generic accounts |
| Firewall status | Enabled on all profiles, default-deny inbound |
| Patch level | No missing critical/security hotfixes vs. vendor release cadence |
| Audit policy | Logon events, account management, and policy change categories all set to Success+Failure |

---

## 4. Linux Host Audit Checks

The Linux side of the same exercise — reviewing accounts, privilege delegation, SSH exposure, and running services against expected baselines.

```bash
# Account review — who exists, who has a login shell, who has UID 0
cat /etc/passwd
awk -F: '$3 == 0 {print $1}' /etc/passwd     # Should only ever list "root"

# Shadow file — hash presence, account lock state (only readable as root)
sudo cat /etc/shadow

# Sudoers review — who can run what as whom
sudo cat /etc/sudoers
sudo cat /etc/sudoers.d/*
sudo -l -U username

# SSH hardening — sshd_config review
grep -E "^(PermitRootLogin|PasswordAuthentication|PermitEmptyPasswords|Protocol|X11Forwarding)" /etc/ssh/sshd_config

# Running/enabled services
systemctl list-units --type=service --state=running
systemctl list-unit-files --state=enabled

# World-writable files (potential tamper/persistence risk)
find / -xdev -type f -perm -0002 2>/dev/null

# World-writable directories without the sticky bit set (higher risk than /tmp)
find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null
```

| Check | What "good" looks like |
|---|---|
| `/etc/passwd` | Only `root` has UID 0; no unexpected accounts with a valid login shell |
| Sudoers | Least-privilege entries (specific commands, not blanket `ALL=(ALL) NOPASSWD: ALL`) |
| `sshd_config` | `PermitRootLogin no`, `PasswordAuthentication no` (key-based only), empty passwords disallowed |
| Running services | Only expected/required services active — no leftover test or default services |
| World-writable files | None outside expected locations (`/tmp`, `/var/tmp` with sticky bit) |

> **Note:** `PermitRootLogin yes` combined with weak/reused passwords is one of the most common audit findings that later becomes the exact entry point exploited in a pentest — see `netcat-reverse-shell-cheatsheet-professional.md` and `hydra-cheatsheet-professional.md` for how that same misconfiguration gets abused offensively.

---

## 5. Network-Level Auditing Basics

Beyond individual hosts, an audit also validates that the network's actual state matches what's documented and expected — this is where `nmap-cheatsheet-professional.md` becomes a direct input.

```bash
# Baseline port scan of a host/subnet — compare results against the documented "expected open ports" list
nmap -sS -p- target-ip

# Service/version detection to confirm what's actually listening matches the change-management record
nmap -sV -p- target-ip

# Sweep a subnet for live hosts to catch unauthorized/rogue devices
nmap -sn 192.168.1.0/24

# Compare a scan's host list against an authorized asset inventory (manual diff)
nmap -sn 192.168.1.0/24 -oG - | grep Up | awk '{print $2}' > live_hosts.txt
diff live_hosts.txt authorized_assets.txt
```

| Check | Purpose |
|---|---|
| Open port baseline | Any port open beyond the documented baseline is a finding — flags forgotten services, shadow IT, or backdoors |
| Unauthorized device detection | A live host on the subnet not present in the asset inventory suggests rogue/unmanaged equipment |
| Firewall rule review | Manually walk the rule set (or `netsh`/`iptables`/`firewalld` output) for overly broad `ANY-ANY` allow rules |

```bash
# Linux firewall rule review
sudo iptables -L -n -v
sudo firewall-cmd --list-all
```

---

## 6. Audit Workflow & Checklist

In practice, a host/network audit follows a repeatable, checklist-driven sequence rather than the open-ended discovery loop used in a pentest.

```
Scope & obtain credentials → Select benchmark/standard → Run checks per host →
Record actual vs. expected state → Rate each deviation → Report findings & remediation
```

| Step | Practical action |
|---|---|
| **1. Scope & access** | Confirm which hosts/subnets are in scope and obtain the credentials/access needed to inspect configuration directly |
| **2. Select the standard** | Pick the applicable CIS Benchmark (or internal policy) and the target profile level (Level 1 vs. Level 2) |
| **3. Run checks** | Work through Sections 3-5 above per host, capturing command output as evidence |
| **4. Compare to baseline** | Mark each control as Pass / Fail / Not Applicable against the benchmark |
| **5. Rate deviations** | Assign a severity to each failed control based on impact and likelihood |
| **6. Report** | Document findings with the current state, the expected state, and the specific remediation command/setting — see `assessment-methodology-report-writing-cheatsheet-professional.md` for report structure |

> **Note:** Because the auditor already has credentials and legitimate access, the value of the engagement comes from thoroughness and accurate comparison against the standard — not from stealth or from proving exploitability.

---

## 7. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Windows password/lockout policy | `net accounts` |
| Windows local admin group | `net localgroup Administrators` |
| Windows firewall status | `Get-NetFirewallProfile \| Select-Object Name, Enabled` |
| Windows patch/hotfix level | `wmic qfe list brief /format:table` or `Get-HotFix` |
| Windows audit policy | `auditpol /get /category:*` |
| Windows local user list | `Get-LocalUser \| Select-Object Name, Enabled, PasswordLastSet` |
| Linux UID 0 accounts | `awk -F: '$3 == 0 {print $1}' /etc/passwd` |
| Linux sudoers review | `sudo cat /etc/sudoers` |
| Linux SSH hardening check | `grep -E "^(PermitRootLogin\|PasswordAuthentication)" /etc/ssh/sshd_config` |
| Linux running services | `systemctl list-units --type=service --state=running` |
| Linux world-writable files | `find / -xdev -type f -perm -0002 2>/dev/null` |
| Network baseline port scan | `nmap -sS -p- target-ip` |
| Subnet host sweep | `nmap -sn 192.168.1.0/24` |
| Linux firewall rule review | `sudo iptables -L -n -v` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
