# Windows/Linux System Security & Access Control Cheat Sheet

Access-control models and hardening fundamentals for both operating systems — complements [`host-network-auditing-fundamentals-cheatsheet-professional.md`](host-network-auditing-fundamentals-cheatsheet-professional.md) (which covers CIS Benchmarks and baseline auditing as a checklist) by going one level deeper into *how* Windows and Linux permission models actually work. Understanding this side is also what makes [`privilege-escalation-linux-windows-cheatsheet.md`](../../Red-Team/03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md) make sense — privesc is almost always an access-control model being misconfigured or misused.

---

## 1. Windows Access Control — DACL/ACE Model

| Term | Meaning |
|---|---|
| **Security Descriptor** | The container attached to every securable object (file, registry key, service, AD object) holding its owner, group, and access control lists |
| **DACL** (Discretionary ACL) | The list of ACEs that determine who is allowed or denied access — this is "permissions" in everyday terms |
| **SACL** (System ACL) | Controls what gets **audited** (logged) when the object is accessed — separate from whether access is actually granted |
| **ACE** (Access Control Entry) | A single rule within a DACL/SACL: a security principal (user/group), an access mask (what rights), and Allow or Deny |
| **Inheritance** | Child objects (files in a folder) inherit ACEs from their parent by default — explicit ACEs on a child always override inherited ones |
| **Effective permissions** | The actual resulting access after evaluating every applicable ACE — an explicit Deny anywhere in the chain overrides any Allow |

**Checking effective permissions:**
```powershell
# View NTFS permissions on a file/folder
icacls "C:\path\to\file"

# View effective permissions for a specific user
icacls "C:\path\to\file" /findsid <username>

# PowerShell equivalent, more scriptable
Get-Acl "C:\path\to\file" | Format-List
```

**Common NTFS permission levels (simplified):** Full Control, Modify, Read & Execute, List Folder Contents, Read, Write — each maps to a more granular access mask under the hood (`icacls` shows the raw mask if needed).

---

## 2. Windows Group Policy Security Settings

| Setting area | Location (GPMC) | What it controls |
|---|---|---|
| Password Policy | Computer Config → Policies → Windows Settings → Security Settings → Account Policies | Min length, complexity, history, max age |
| Account Lockout Policy | Same path, Account Lockout Policy | Lockout threshold/duration after failed logons |
| Audit Policy | Security Settings → Local Policies → Audit Policy (or Advanced Audit Policy) | What gets logged (logon events, object access, privilege use) — directly determines what shows up in [`windows-event-id-reference-cheatsheet-professional.md`](windows-event-id-reference-cheatsheet-professional.md) |
| User Rights Assignment | Local Policies → User Rights Assignment | Who can log on locally/via RDP, who can shut down the system, who has `SeDebugPrivilege`, etc. — misconfiguration here is a direct privesc path |
| Security Options | Local Policies → Security Options | Dozens of individual hardening toggles (e.g., disabling LM hash storage, restricting anonymous SAM enumeration) |
| Security Templates / Security Compliance Toolkit | Imported `.inf` templates | Microsoft's baseline hardening configurations, applied in bulk rather than setting each option manually |

**Quick check of current local security policy:**
```powershell
secedit /export /cfg C:\policy_export.cfg
```

---

## 3. Linux Permission Model

```bash
# Standard rwx bits
ls -l file.txt
# -rw-r--r-- 1 owner group  size  date  file.txt
#  ^user ^group ^other

chmod 750 file.txt      # owner: rwx, group: r-x, other: none
chown user:group file.txt

# Special bits
chmod u+s file           # SUID — runs as file owner, not invoking user (see privesc cheat sheet for abuse cases)
chmod g+s directory      # SGID — new files inherit the directory's group
chmod +t /tmp            # Sticky bit — only the file owner can delete/rename within a shared-write directory

# umask — default permission mask for newly created files
umask                    # view current
umask 022                # set (new files: 755 for dirs, 644 for files by default)
```

**`sudoers` — controlled privilege elevation:**
```bash
visudo                          # always edit via visudo — validates syntax before saving

# Example entries
alice ALL=(ALL) ALL             # alice can run any command as any user, with password
bob ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx   # scoped, no-password exception

sudo -l                         # list what the current user is permitted to run — always check this first on any host
```

An overly broad `sudo -l` result (e.g., a binary listed in GTFOBins) is one of the single most common privilege-escalation paths — see [`privilege-escalation-linux-windows-cheatsheet.md`](../../Red-Team/03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md) for the offensive side of exactly this.

---

## 4. Linux Mandatory Access Control (Brief)

| System | Distros | Concept |
|---|---|---|
| SELinux | RHEL/CentOS/Fedora | Label-based (contexts) mandatory access control — even root can be constrained by policy |
| AppArmor | Ubuntu/Debian/SUSE | Path-based mandatory access control — profiles restrict what a specific application can do |

```bash
# SELinux quick status
getenforce                      # Enforcing / Permissive / Disabled
sestatus

# AppArmor quick status
aa-status
```

Both exist to constrain a compromised process even if the underlying Discretionary Access Control (standard rwx/sudoers) was bypassed — worth checking during hardening review, since a service running unconfined defeats the purpose.

---

## 5. Service Hardening Checklist

- [ ] Disable/remove services that aren't actually needed — the smallest attack surface is the one that isn't running at all.
- [ ] Run services under a dedicated low-privilege account, never as root/SYSTEM unless there's a specific, documented reason.
- [ ] Review `sudo -l` / Windows service account rights for every service account — least privilege applies to service accounts as much as human ones.
- [ ] Confirm audit policy (Windows) or auditd rules (Linux — see [`linux-forensics-and-artifact-analysis-cheatsheet.md`](../02-DFIR-and-Threat-Intelligence/linux-forensics-and-artifact-analysis-cheatsheet.md)) actually capture the events you'd need during an investigation, before an incident forces you to find out they don't.
- [ ] Check for world-writable files/directories owned by a privileged account — a common, easy-to-miss privesc path on Linux.
- [ ] Verify no unnecessary accounts have interactive logon rights on servers that don't need them.
- [ ] Apply a security baseline template (Microsoft Security Compliance Toolkit for Windows; CIS Benchmarks for both) rather than hardening from scratch — see [`host-network-auditing-fundamentals-cheatsheet-professional.md`](host-network-auditing-fundamentals-cheatsheet-professional.md).

---

*Baseline auditing and CIS Benchmark checklists: [`host-network-auditing-fundamentals-cheatsheet-professional.md`](host-network-auditing-fundamentals-cheatsheet-professional.md). Windows Event ID reference (what audit policy actually produces): [`windows-event-id-reference-cheatsheet-professional.md`](windows-event-id-reference-cheatsheet-professional.md). Linux artifact/log locations: [`linux-forensics-and-artifact-analysis-cheatsheet.md`](../02-DFIR-and-Threat-Intelligence/linux-forensics-and-artifact-analysis-cheatsheet.md). Offensive counterpart — how these misconfigurations get exploited: [`privilege-escalation-linux-windows-cheatsheet.md`](../../Red-Team/03-Exploitation-and-Post-Exploitation/privilege-escalation-linux-windows-cheatsheet.md).*
