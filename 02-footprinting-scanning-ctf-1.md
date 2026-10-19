# INE eJPT — Assessment Methodologies: Footprinting and Scanning CTF 1

**Course:** INE / eJPT — Assessment Methodologies  
**Lab:** Footprinting and Scanning CTF 1  
**Author:** Zeliha Zengin

---

## Lab Environment

GUI access to a Kali machine is provided. The target is at `http://target.ine.local`. Capture the hidden flags.

- **Flag 1:** The server announces its identity in every response — look closely.
- **Flag 2:** The gatekeeper's instructions reveal what should stay unseen (read between the lines).
- **Flag 3:** Anonymous access leads to forgotten treasures — connect and explore.
- **Flag 4:** A well-named database can be revealing — peek at the configurations.

**Tools used:** Nmap · FTP · MySQL

> **Note:** Flag format is `FLAG1_MD5Hash` — submit only the hash (no underscore).

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — Server banner

An aggressive scan surfaces the server's self-announced identity (banner):

```bash
nmap -sV -A -Pn -p- target.ine.local
```

> **Note:** You can also find it via the browser's Developer Tools → Network tab response headers.

> 🏁 **FLAG 1:** `d86409eba7ba48d9b0e3a168d0117cd7`

## Flag 2 — robots.txt hint

The scan reveals `robots.txt`, which points to a hidden directory:

```bash
http://target.ine.local/secret-info/
curl http://target.ine.local/secret-info/flag.txt
```

> 🏁 **FLAG 2:** `400b404fd1894701a37a456d67d9bf45`

## Flag 3 — Anonymous FTP

Nmap shows FTP allows anonymous login. Connect and download the files:

```bash
ftp target.ine.local
# username: anonymous
# password: anonymous
ftp> get creds.txt
ftp> get flag.txt
ftp> bye
cat creds.txt   # db_admin:password@123
cat flag.txt
```

> 🏁 **FLAG 3:** `9daf63f7dc394de493e481817853d500`

## Flag 4 — MySQL database

The FTP `creds.txt` gives valid DB credentials, and Nmap shows MySQL on port 3306. Connect and list databases:

```bash
mysql -u db_admin -p -h target.ine.local
# password: password@123
show databases;
```

> 🏁 **FLAG 4:** `fa068d2cfcdc48ac83b940b81985d303`

## Summary

| Flag | Technique |
| --- | --- |
| 1 | Banner grabbing (Nmap / response headers) |
| 2 | robots.txt → hidden directory |
| 3 | Anonymous FTP file download |
| 4 | MySQL login with leaked FTP credentials |

### Key Takeaways

- Server banners and `robots.txt` leak more than most admins realize.
- Anonymous FTP is a frequent source of credentials.
- Credentials found in one service (FTP) often unlock another (MySQL) — always try them everywhere.

---

*Write-up by Zeliha Zengin · eJPT preparation*