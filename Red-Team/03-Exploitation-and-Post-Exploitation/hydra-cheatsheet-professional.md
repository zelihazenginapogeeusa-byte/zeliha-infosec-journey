# Hydra Cheat Sheet

**Hydra** is a fast, parallelized online login brute-forcer that comes up throughout eJPT's host/network pentest module whenever a service exposes an authentication prompt worth attacking. Unlike offline hash-cracking tools, Hydra sends real login attempts over the network against a live service, which makes speed, tuning, and lockout-avoidance central to using it safely and effectively.

---

## Table of Contents

1. [What Hydra Does & When to Use It](#1-what-hydra-does--when-to-use-it)
2. [Basic Syntax](#2-basic-syntax)
3. [Common Service Modules](#3-common-service-modules)
4. [Username/Password Combinations](#4-usernamepassword-combinations)
5. [Tuning & Avoiding Lockout](#5-tuning--avoiding-lockout)
6. [Reading Output](#6-reading-output)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. What Hydra Does & When to Use It

Hydra automates credential attacks against network services by submitting login attempts directly to the target and checking the response for success or failure — this is fundamentally different from offline cracking.

- **Hydra (online brute-force):** attacks a live service over the network — every guess is a real authentication attempt, rate-limited by the network and the target, and visible in the target's logs.
- **John the Ripper / Hashcat (offline cracking):** attack a hash you already possess, entirely locally, with no interaction with the target and no lockout risk (see `john-the-ripper-cheatsheet-professional.md` and `hashcat-cheatsheet-professional.md`).

Use Hydra when you have (or suspect) a login form/service but no credentials yet; move to offline cracking once you've captured a hash (e.g. via `Responder`, a Kerberoasting request, or a dumped `/etc/shadow`).

---

## 2. Basic Syntax

Hydra's command structure always follows the same shape: a username source, a password source, and a target service URL.

```bash
hydra [-l user | -L userlist] [-p pass | -P passlist] target service://

# Single username, password list
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://target-ip

# Username list, single password (e.g. password spraying)
hydra -L users.txt -p 'Summer2026!' ssh://target-ip
```

| Flag | Meaning |
|---|---|
| `-l` | Single username |
| `-L` | File containing a list of usernames |
| `-p` | Single password |
| `-P` | File containing a list of passwords |
| `-s` | Non-default port |
| `-v` / `-V` | Verbose — show each attempt as it happens |

---

## 3. Common Service Modules

Hydra supports dozens of protocol modules; these are the ones that show up most often in the exam and in real engagements.

```bash
# SSH
hydra -l root -P rockyou.txt ssh://target-ip

# FTP
hydra -l admin -P rockyou.txt ftp://target-ip

# SMB
hydra -l administrator -P rockyou.txt smb://target-ip

# RDP
hydra -l administrator -P rockyou.txt rdp://target-ip

# HTTP POST login form — field syntax is user^USER^:pass^PASS^:failure-string
hydra -l admin -P rockyou.txt target-ip http-post-form \
  "/login.php:username=^USER^&password=^PASS^:Invalid credentials"

# MySQL
hydra -l root -P rockyou.txt mysql://target-ip
```

> For `http-post-form`, the third field is the string that appears on a **failed** login — Hydra uses its absence to decide a guess succeeded, so grab the exact error text from the form first.

---

## 4. Username/Password Combinations

Beyond a straight username-list-against-password-list run, Hydra supports combo files and automatic password variations.

```bash
# Combo file — one "user:pass" pair per line, tried exactly as listed
hydra -C combo.txt ssh://target-ip

# -e n: also try a null password
# -e s: also try the username as its own password
# -e r: also try the username reversed as the password
hydra -l admin -P rockyou.txt -e nsr ssh://target-ip
```

| Option | Behavior |
|---|---|
| `-C file` | Combo mode — replaces `-L`/`-P`, reads `user:pass` pairs directly |
| `-e n` | Try empty/null password |
| `-e s` | Try username as password |
| `-e r` | Try reversed username as password |

---

## 5. Tuning & Avoiding Lockout

Hydra's default settings are aggressive enough to trip account lockout policies or crash unstable services — check the policy and throttle before running.

```bash
# Reduce parallel tasks (default is 16) to avoid overwhelming the service/tripping lockout
hydra -l admin -P rockyou.txt -t 4 ssh://target-ip

# Add a wait between reconnect attempts
hydra -l admin -P rockyou.txt -t 4 -W 5 ssh://target-ip

# Stop as soon as one valid pair is found (per host)
hydra -l admin -P rockyou.txt -f ssh://target-ip
```

| Flag | Purpose |
|---|---|
| `-t <n>` | Number of parallel connections/tasks (lower = stealthier, slower) |
| `-W <sec>` | Wait time between reconnects |
| `-f` | Exit after the first valid login found |
| `-M <file>` | Run against a list of targets (multi-host) |

> **Check the lockout policy before spraying.** The same warning from `active-directory-enumeration-cheatsheet-professional.md`'s password spraying section applies here: enumerate the account lockout threshold first (`crackmapexec smb target-ip --pass-pol`), then keep attempts-per-account well under it — one password across many users (`-L users.txt -p pass`) is far safer than many passwords against one user.

---

## 6. Reading Output

What a successful hit looks like in Hydra's console output, so it's not missed in a long-running scan.

```
[22][ssh] host: 10.10.10.5   login: admin   password: Summer2026!
1 of 1 target successfully completed, 1 valid password found
```

The bracketed number is the port, followed by the service name, target host, and the recovered `login`/`password` pair — this line is Hydra's only signal of success, so grep for `login:` when scripting or piping output to a file with `-o`.

---

## 7. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Basic SSH brute-force | `hydra -l admin -P rockyou.txt ssh://target-ip` |
| Password spray (one pass, many users) | `hydra -L users.txt -p 'Pass1' ssh://target-ip` |
| FTP | `hydra -l admin -P rockyou.txt ftp://target-ip` |
| SMB | `hydra -l administrator -P rockyou.txt smb://target-ip` |
| RDP | `hydra -l administrator -P rockyou.txt rdp://target-ip` |
| HTTP POST form | `hydra -l admin -P rockyou.txt target-ip http-post-form "/login.php:username=^USER^&password=^PASS^:Invalid credentials"` |
| Combo file | `hydra -C combo.txt ssh://target-ip` |
| Null/same-as-user/reversed | `hydra -l admin -P rockyou.txt -e nsr ssh://target-ip` |
| Throttle threads | `hydra -l admin -P rockyou.txt -t 4 ssh://target-ip` |
| Stop on first success | `hydra -l admin -P rockyou.txt -f ssh://target-ip` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
