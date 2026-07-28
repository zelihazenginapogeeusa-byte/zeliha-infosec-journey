# Dirb Cheat Sheet

`dirb` is one of the oldest and most straightforward web content brute-forcers — a classic first-pass tool for finding hidden directories and files on a web server before moving to something faster like Gobuster. This document covers its syntax, options, wordlists, and how to read its output.

---

## Table of Contents

1. [What Dirb Is & When to Use It](#1-what-dirb-is--when-to-use-it)
2. [Basic Syntax](#2-basic-syntax)
3. [Core Options](#3-core-options)
4. [Wordlists](#4-wordlists)
5. [Extensions & File Type Discovery](#5-extensions--file-type-discovery)
6. [Authentication & Headers](#6-authentication--headers)
7. [Output & Reporting](#7-output--reporting)
8. [Reading Dirb's Output](#8-reading-dirbs-output)
9. [Dirb vs Gobuster](#9-dirb-vs-gobuster)
10. [Practical Workflow](#10-practical-workflow)
11. [Quick Command Reference](#11-quick-command-reference)

---

## 1. What Dirb Is & When to Use It

Dirb works by sending an HTTP request for every word in a wordlist appended to a target URL, and reporting which ones return a "real" response (not a 404). It's used early in web enumeration — right after confirming a web server is up — to discover:

- Hidden admin panels, login pages, backup files
- Directories not linked anywhere in the site's navigation
- Configuration files, install scripts, leftover development artifacts

> This is exactly the tool used against DC-1's Drupal install to surface `/user/login/` and confirm `admin` as a valid username before moving to exploitation — dirb's output is often the first real lead in a web-focused engagement.

---

## 2. Basic Syntax

The minimal command structure needed to point dirb at a target.

```bash
dirb <url> [wordlist] [options]

# Simplest form — uses dirb's default wordlist (common.txt)
dirb http://target-ip

# With an explicit wordlist
dirb http://target-ip /usr/share/wordlists/dirb/big.txt
```

If no wordlist is specified, dirb defaults to `/usr/share/dirb/wordlists/common.txt`.

---

## 3. Core Options

The flags that control how aggressively and quietly dirb scans.

| Flag | Purpose |
|---|---|
| `-r` | Non-recursive — don't scan discovered subdirectories automatically |
| `-R` | Interactive recursive scanning (asks before descending into a new directory) |
| `-X <ext>` | Append a specific extension to every word (e.g. `-X .php`) |
| `-w` | Don't stop on warning messages (keep scanning through connection issues) |
| `-S` | Silent mode — only show discovered items, suppress the banner/progress noise |
| `-z <ms>` | Add a delay (in milliseconds) between requests — useful to avoid tripping rate limits/WAFs |
| `-i` | Case-insensitive search |
| `-N <code>` | Ignore responses with a specific HTTP status code |
| `-p <proxy>` | Route requests through a proxy (e.g. Burp Suite for further manual inspection) |

```bash
dirb http://target-ip -X .php,.bak -z 200
dirb http://target-ip -p 127.0.0.1:8080     # Route through Burp
```

---

## 4. Wordlists

Dirb ships with its own wordlist set, typically under `/usr/share/dirb/wordlists/`:

| Wordlist | Use case |
|---|---|
| `common.txt` | Default — fast, broad first-pass coverage |
| `big.txt` | Larger, more thorough — better hit rate, slower |
| `small.txt` | Minimal, for quick sanity checks |
| `vulns/` (subdirectory) | Wordlists targeting specific known vulnerable paths |

```bash
# Point dirb at a custom wordlist (e.g. SecLists)
dirb http://target-ip /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
```

> **Wordlist choice trades off speed vs coverage.** Start with `common.txt` for a quick pass, then re-run with `big.txt` or a SecLists wordlist if the target looks worth deeper enumeration.

---

## 5. Extensions & File Type Discovery

Appending extensions to wordlist entries turns up files a plain directory scan would miss.

```bash
# Check for common backup/source file extensions
dirb http://target-ip -X .bak,.old,.zip,.txt,.php.bak

# Target a specific technology's file extension
dirb http://target-ip -X .php      # PHP apps
dirb http://target-ip -X .aspx     # ASP.NET apps
```

> Backup extensions (`.bak`, `.old`, `.orig`, `~`) left behind by editors or manual backups are a classic way to read source code that would otherwise execute server-side (e.g. `config.php.bak` returns the raw PHP instead of running it).

---

## 6. Authentication & Headers

Scanning targets that sit behind a login or expect specific request headers.

```bash
# HTTP Basic Auth
dirb http://target-ip -u username:password

# Custom cookie (for scanning behind a login)
dirb http://target-ip -c "PHPSESSID=abc123"

# Custom User-Agent
dirb http://target-ip -a "Mozilla/5.0 (custom)"
```

---

## 7. Output & Reporting

Capture results to a file so they can be referenced later without re-running the scan.

```bash
dirb http://target-ip -o dirb_output.txt     # Save results to a file
dirb http://target-ip -o dirb_output.txt -S  # Silent mode + save to file (clean report output)
```

> Always save output to a file during an engagement — you'll want it later for the report's evidence/appendix section (see `assessment-methodology-report-writing-cheatsheet-professional.md`).

---

## 8. Reading Dirb's Output

What dirb's raw console output actually means, line by line.

```
---- Scanning URL: http://target-ip/ ----
==> DIRECTORY: http://target-ip/admin/
+ http://target-ip/CHANGELOG.txt (CODE:200|SIZE:1234)
+ http://target-ip/robots.txt (CODE:200|SIZE:145)
```

| Marker | Meaning |
|---|---|
| `==> DIRECTORY:` | A directory was found — dirb will recurse into it by default |
| `+ URL (CODE:200\|SIZE:...)` | A file/page was found and returned a 200; the size can hint at whether it's a real page or a generic error page disguised as 200 |
| `CODE:403` | Found but forbidden — still worth noting, may be bypassable |
| `CODE:301/302` | A redirect — worth following manually to see the real destination |

> **Watch for false positives on size:** if a site returns HTTP 200 for every path (a soft-404), dirb will report everything as "found." Compare returned page sizes — if they're all identical, the server likely isn't giving real 404s, and results need manual verification.

---

## 9. Dirb vs Gobuster

A quick comparison to help decide which tool to reach for first.

| | Dirb | Gobuster |
|---|---|---|
| **Language** | C | Go |
| **Speed** | Slower, single-threaded by default | Much faster, multi-threaded |
| **Recursion** | Built-in, automatic | Manual (needs to be re-run per directory) |
| **Best for** | Thorough first pass, detecting soft-404s reliably | Fast, high-volume brute-forcing (also does DNS/vhost/S3 bucket modes) |

> Common practice: run both. Dirb's automatic recursion and default soft-404 handling catch things a raw Gobuster run might miss, while Gobuster covers more ground faster with a bigger wordlist.

---

## 10. Practical Workflow

A suggested order of operations for combining everything above on a real target.

```bash
# 1. Quick first pass with the default wordlist
dirb http://target-ip

# 2. Cross-check with Gobuster and a larger wordlist
gobuster dir -u http://target-ip -w /usr/share/wordlists/dirb/big.txt

# 3. Manually verify every interesting hit
curl -I http://target-ip/found-path

# 4. Look for backup/source-disclosure extensions on interesting directories
dirb http://target-ip/admin -X .bak,.old,.txt
```

---

## 11. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Basic scan | `dirb http://target-ip` |
| Custom wordlist | `dirb http://target-ip wordlist.txt` |
| Non-recursive | `dirb http://target-ip -r` |
| Add extensions | `dirb http://target-ip -X .php,.bak` |
| Silent + save output | `dirb http://target-ip -o out.txt -S` |
| Through a proxy (Burp) | `dirb http://target-ip -p 127.0.0.1:8080` |
| With delay between requests | `dirb http://target-ip -z 200` |
| Basic auth | `dirb http://target-ip -u user:pass` |

---

*Prepared as a reference for eJPT web enumeration and general pentest engagements. All techniques should only be used within written authorization (scope/RoE).*
