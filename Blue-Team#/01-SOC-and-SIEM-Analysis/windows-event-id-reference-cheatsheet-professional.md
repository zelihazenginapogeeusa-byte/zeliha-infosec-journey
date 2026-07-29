# Windows Event ID Reference Cheat Sheet

A companion to your `deepblue-cli-cheatsheet-professional.md`: DeepBlueCLI automates *which* Event IDs to look at — this document is a quick-lookup reference for *what each Event ID actually means*. It comes up constantly in BTL1's DFIR and Security Operations modules.

---

## Table of Contents

1. [Authentication / Logon Events](#1-authentication--logon-events)
2. [Account Management Events](#2-account-management-events)
3. [Process & Object Access Events](#3-process--object-access-events)
4. [Kerberos Events](#4-kerberos-events)
5. [Sysmon Event IDs](#5-sysmon-event-ids)
6. [PowerShell Logging](#6-powershell-logging)
7. [Logon Type Reference](#7-logon-type-reference)
8. [Attack → Event ID Mapping Table](#8-attack--event-id-mapping-table)
9. [Quick Reference](#9-quick-reference)

---

## 1. Authentication / Logon Events

The Event IDs you'll check first when investigating any logon-related incident — brute force, password spraying, or lateral movement.

| Event ID | Meaning |
|---|---|
| **4624** | Successful logon |
| **4625** | Failed logon — the foundation of brute-force/password-spray detection |
| **4634** | Logoff |
| **4647** | User-initiated logoff |
| **4648** | Logon using explicit credentials (runas, connecting as a different user) — can indicate lateral movement |
| **4778 / 4779** | RDP session reconnected / disconnected |

---

## 2. Account Management Events

These IDs reveal account creation and group membership changes — the classic footprint of an attacker establishing persistence or escalating privileges.

| Event ID | Meaning |
|---|---|
| **4720** | New user account created |
| **4722** | User account enabled |
| **4724** | Password reset attempt |
| **4728** | User added to a **global** security group |
| **4732** | User added to a **local** security group (e.g. Administrators) — a critical privesc indicator |
| **4756** | User added to a **universal** security group |
| **4738** | User account changed |
| **4740** | Account locked out |

---

## 3. Process & Object Access Events

Tracks what actually ran and what got touched — command-line-level process creation and file/registry access are core to reconstructing an attacker's actions on a host.

| Event ID | Meaning |
|---|---|
| **4688** | A new process was created — with command-line logging enabled (`Include command line`), it shows the exact command run |
| **4689** | Process exited |
| **4663** | An attempt to access an object (file, registry) |
| **4662** | Directory service object access — critical for **DCSync detection** (`Replicating Directory Changes` permission) |
| **5140** | A network share was accessed |
| **5145** | Detailed access check on a shared file/folder |

---

## 4. Kerberos Events

These IDs surface abuse of Kerberos authentication itself — the pattern of tickets requested is what exposes Kerberoasting and AS-REP Roasting.

| Event ID | Meaning |
|---|---|
| **4768** | TGT (Ticket Granting Ticket) request — initial authentication |
| **4769** | TGS (Ticket Granting Service) request — the foundation of **Kerberoasting detection** |
| **4771** | Kerberos pre-authentication failed — can be tied to **AS-REP Roasting** |
| **4776** | An NTLM credential validation attempt |

---

## 5. Sysmon Event IDs

Sysmon provides far richer telemetry than Windows' built-in logging — the gold standard in DFIR.

| Event ID | Meaning |
|---|---|
| **1** | Process creation (with parent/child relationship + full command line) |
| **3** | Network connection |
| **5** | Process terminated |
| **7** | Image/DLL loaded |
| **8** | CreateRemoteThread — an indicator of process injection |
| **10** | Process access (e.g. access to `lsass.exe` — a credential-dumping indicator) |
| **11** | File created |
| **12/13/14** | Registry created/modified/deleted |
| **22** | DNS query |

> **Event ID 10 accessing `lsass.exe`** is the classic signature of Mimikatz-style credential-dumping tools.

---

## 6. PowerShell Logging

PowerShell is the attacker's tool of choice for living-off-the-land — these logs are where you catch it, even through obfuscation.

| Log Source | Event ID | Note |
|---|---|---|
| PowerShell Operational | **4104** | Script Block Logging — logs the full PowerShell code executed (deobfuscated, even if the attacker tried to obfuscate it) |
| PowerShell Operational | **4103** | Module logging |
| Windows PowerShell (legacy log) | **400/403** | Engine start/stop |

```
Keywords to search for (inside 4104):
-enc / -EncodedCommand / IEX / DownloadString / FromBase64String / Invoke-Expression
```

---

## 7. Logon Type Reference

The **Logon Type** field inside Event ID 4624/4625 is critical for understanding the attack vector:

| Logon Type | Meaning |
|---|---|
| **2** | Interactive — logon at the physical console |
| **3** | Network — SMB/share access, commonly seen with pass-the-hash |
| **4** | Batch — a scheduled task |
| **5** | Service — a service account starting up |
| **7** | Unlock — unlocking the workstation |
| **8** | NetworkCleartext — the password crossed the network in plaintext (e.g. IIS basic auth) |
| **9** | NewCredentials — `runas /netonly` |
| **10** | RemoteInteractive — RDP |
| **11** | CachedInteractive — logon using cached credentials when the DC is unreachable |

---

## 8. Attack → Event ID Mapping Table

The corresponding logs for the attack techniques in `active-directory-enumeration-cheatsheet-professional.md`:

| Attack | Related Event ID(s) |
|---|---|
| Password spraying | 4625 (many different users, single IP) |
| Brute force (single account) | 4625 (single user, many attempts) |
| Kerberoasting | 4769 (many different SPNs, short time window) |
| AS-REP Roasting | 4768/4771 (TGT requested without pre-auth) |
| Pass-the-Hash | 4624 Logon Type 3 + NTLM, from an unusual source |
| DCSync | 4662 (Replicating Directory Changes, from a non-DC source) |
| Golden/Silver Ticket | 4768/4769 anomalies (e.g. unusually long ticket lifetime) |
| Lateral movement (PsExec, etc.) | 4688 (new process) + 5140 (share access) + 4624 Type 3 |
| Credential dumping (lsass) | Sysmon 10 (lsass.exe process access) |
| Adding to the local admin group | 4732 |

---

## 9. Quick Reference

A single-page lookup for everything covered above.

| Need | Event ID |
|---|---|
| Successful/failed logon | 4624 / 4625 |
| New process | 4688 (Sysmon: 1) |
| New user/group added | 4720 / 4732 |
| Kerberos TGT/TGS request | 4768 / 4769 |
| PowerShell code executed | 4104 |
| DC replication access (DCSync) | 4662 |
| lsass process access | Sysmon 10 |
| Network connection (Sysmon) | Sysmon 3 |
| DNS query (Sysmon) | Sysmon 22 |

---

*Prepared as a reference for the BTL1 Digital Forensics & Incident Response and Security Operations modules. Recommended for use alongside `deepblue-cli-cheatsheet-professional.md`.*
