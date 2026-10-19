# INE eJPT — Assessment Methodologies: Information Gathering CTF 1

**Course:** INE / eJPT — Assessment Methodologies  
**Lab:** Information Gathering CTF 1  
**Author:** Zeliha Zengin

---

## Lab Environment

A website is accessible at `http://target.ine.local`. Perform reconnaissance and capture the flags.

- **Flag 1:** This tells search engines what to avoid.
- **Flag 2:** What website is running on the target, and what version?
- **Flag 3:** Directory browsing might reveal where files are stored.
- **Flag 4:** An overlooked backup file in the webroot can leak sensitive configuration.
- **Flag 5:** Certain files reveal something interesting when mirrored.

**Tools used:** Firefox · Curl · HTTrack · Nmap · dirb

> **Note:** Flag format is `FLAG1{MD5Hash}` or `FL@G1{MD5Hash}` — submit only the hash.

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — robots.txt

`robots.txt` tells search engines which paths to avoid — a classic recon starting point:

```bash
http://target.ine.local/robots.txt
```

> 🏁 **FLAG 1:** `c6d59eb8105741259e8c4258e6f9d5a8`

## Flag 2 — Server / CMS version

Fingerprint the web application and its version with an aggressive Nmap scan:

```bash
nmap -sV -Pn -A -p- target.ine.local
```

| Flag | Meaning |
| --- | --- |
| `-sV` | Service/version detection |
| `-Pn` | Skip host discovery |
| `-A` | Aggressive (OS, version, scripts, traceroute) |
| `-p-` | All 65,535 ports |

> **Note:** You can also right-click → Inspect and check the Network tab for server headers.

> 🏁 **FLAG 2:** `a5a8dcf9f5224bbd9c841e615e6a979c`

## Flag 3 — Directory browsing

```bash
dirb http://target.ine.local
```

The flag lives in the WordPress uploads directory:

```bash
http://target.ine.local/wp-content/uploads/   → flag.txt
```

> 🏁 **FLAG 3:** `9eb244427daf40f7b2d53531de775831`

## Flag 4 — Backup file in the webroot

Hunt for backup extensions with dirb's `-X` option:

```bash
dirb http://target.ine.local -w /usr/share/dirb/wordlists/big.txt -X .bak,.tar.gz,.zip,.sql,.bak.zip
```

This reveals `wp-config.bak`. Read it with curl:

```bash
curl http://target.ine.local/wp-config.bak
```

> 🏁 **FLAG 4:** `c6ddc0afaab14ea7a13d1a80ebe1b1ef`

## Flag 5 — Mirror the site with HTTrack

HTTrack downloads a full offline copy of the site, exposing files not obvious while browsing:

```bash
httrack http://target.ine.local -O mirror.html
cd mirror.html/target.ine.local
ls
cat xmlrpc*.php
```

> 🏁 **FLAG 5:** `68f9d174fd1246d29ed69ca090d91631`

## Summary

| Flag | Technique |
| --- | --- |
| 1 | robots.txt disclosure |
| 2 | Version fingerprinting (Nmap / headers) |
| 3 | Directory browsing → wp-content/uploads |
| 4 | Backup file (wp-config.bak) via dirb -X + curl |
| 5 | Full site mirror with HTTrack |

### Key Takeaways

- `robots.txt` and server headers are the first things to read in web recon.
- Always fuzz for backup extensions (`.bak`, `.zip`, `.sql`) in the webroot.
- Mirroring with HTTrack surfaces files you'd miss by clicking around.

---

*Write-up by Zeliha Zengin · eJPT preparation*
