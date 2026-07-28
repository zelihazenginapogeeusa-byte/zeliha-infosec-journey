# Gobuster Cheat Sheet

**Gobuster** is a fast, Go-based brute-forcing tool used throughout eJPT's web application module to discover hidden directories, files, subdomains, and virtual hosts on a target. It's the natural next step after `dirb` when speed and additional discovery modes (DNS, vhost, S3) are needed.

---

## Table of Contents

1. [What Gobuster Is & Modes Overview](#1-what-gobuster-is--modes-overview)
2. [`dir` Mode](#2-dir-mode)
3. [`dns` Mode](#3-dns-mode)
4. [`vhost` Mode](#4-vhost-mode)
5. [Wordlists](#5-wordlists)
6. [Filtering Output](#6-filtering-output)
7. [Gobuster vs Dirb](#7-gobuster-vs-dirb)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. What Gobuster Is & Modes Overview

Gobuster is invoked as `gobuster <mode> [options]` — the mode determines what kind of brute-force it performs, and each has its own flag set.

| Mode | Purpose |
|---|---|
| `dir` | Brute-force directories and files on a web server |
| `dns` | Brute-force subdomains of a target domain |
| `vhost` | Discover virtual hosts served by the same IP (Host header brute-forcing) |
| `fuzz` | Generic fuzzing — replace a `FUZZ` keyword anywhere in a request (URL, headers, body) |
| `s3` | Enumerate open/misconfigured AWS S3 buckets |

```bash
gobuster dir -u http://target-ip -w wordlist.txt
gobuster dns -d target.com -w wordlist.txt
gobuster vhost -u http://target.com -w wordlist.txt
```

---

## 2. `dir` Mode

The most commonly used mode in eJPT labs — brute-forces directories and files against a URL.

```bash
gobuster dir -u http://target-ip -w /usr/share/wordlists/dirb/common.txt
```

| Flag | Purpose |
|---|---|
| `-u` | Target URL |
| `-w` | Wordlist path |
| `-x` | Comma-separated extensions to append (e.g. `-x php,txt,bak`) |
| `-t` | Number of concurrent threads (default 10 — bump up for speed) |
| `-k` | Skip TLS certificate verification (self-signed certs) |
| `-c` | Set a cookie (for scanning behind a login) |
| `-U` / `-P` | Username/password for HTTP Basic Auth |

```bash
gobuster dir -u http://target-ip -w /usr/share/wordlists/dirb/big.txt -x php,bak,txt -t 50
gobuster dir -u https://target-ip -w wordlist.txt -k -c "PHPSESSID=abc123"
```

---

## 3. `dns` Mode

Brute-forces subdomains by prepending wordlist entries to the target domain and checking for a resolvable DNS record.

```bash
gobuster dns -d target.com -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
```

| Flag | Purpose |
|---|---|
| `-d` | Target base domain |
| `-w` | Wordlist of subdomain candidates |
| `-i` | Show IP addresses for discovered subdomains |
| `--wildcard` | Explicitly allow scanning targets with wildcard DNS configured |

> **Wildcard DNS handling:** if `*.target.com` resolves to something (wildcard record), every guessed subdomain will appear to "exist." Gobuster detects this automatically and warns — use `--wildcard` to force the scan anyway, but manually verify every hit.

---

## 4. `vhost` Mode

Discovers virtual hosts hosted on the same IP by brute-forcing the `Host:` header rather than the URL path — useful when a single server answers for multiple domains/subdomains.

```bash
gobuster vhost -u http://target.com -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
```

| Flag | Purpose |
|---|---|
| `-u` | Base URL (IP or domain) to send requests to |
| `-w` | Wordlist of vhost candidates |
| `--append-domain` | Append the base domain to each wordlist word automatically |

> Combine findings here with an `/etc/hosts` entry so the browser/curl actually requests the discovered vhost by name — many misconfigured vhosts only reveal their real content when the correct `Host` header is sent.

---

## 5. Wordlists

Wordlist choice is the single biggest factor in gobuster's hit rate and runtime.

| Wordlist | Path | Use case |
|---|---|---|
| `common.txt` | `/usr/share/wordlists/dirb/common.txt` | Fast first pass, ~4.6k entries |
| `directory-list-2.3-medium.txt` | `/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt` | Thorough general-purpose directory list, ~220k entries |
| `raft-medium-directories.txt` | `/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt` | Good middle ground, curated from real-world crawls |
| `subdomains-top1million-5000.txt` | `/usr/share/seclists/Discovery/DNS/` | Standard for `dns`/`vhost` modes |

> SecLists (`/usr/share/seclists/`) is the default go-to wordlist collection across nearly every tool in this collection — install it if it's not already present (`apt install seclists`).

---

## 6. Filtering Output

Controlling which status codes get reported (and where results go) keeps output usable on noisy targets.

| Flag | Purpose |
|---|---|
| `-b` | Blacklist status codes to hide (default blacklists `404`) |
| `-s` | Whitelist — only show these status codes |
| `-o` | Save output to a file |
| `-q` | Quiet mode — suppress the banner |
| `-e` | Print full URLs instead of relative paths |

```bash
gobuster dir -u http://target-ip -w wordlist.txt -b 404,403          # Hide noise
gobuster dir -u http://target-ip -w wordlist.txt -s 200,204,301,302  # Only show likely-real hits
gobuster dir -u http://target-ip -w wordlist.txt -o gobuster_out.txt # Save for the report
```

---

## 7. Gobuster vs Dirb

A quick comparison to decide which brute-forcer to reach for first — see `dirb-cheatsheet-professional.md` for dirb's full syntax.

| | Gobuster | Dirb |
|---|---|---|
| **Language** | Go | C |
| **Speed** | Fast, multi-threaded by default | Slower, effectively single-threaded |
| **Modes** | dir, dns, vhost, fuzz, s3 | Directory/file brute-forcing only |
| **Recursion** | Manual (re-run gobuster on discovered directories) | Automatic |
| **Soft-404 handling** | Less reliable out of the box | Better default detection |

> Common practice: run gobuster first for speed and breadth (and its extra modes), then cross-check interesting hits with dirb's recursive scan for anything gobuster's flat scan might miss.

---

## 8. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Directory brute-force | `gobuster dir -u http://target-ip -w wordlist.txt` |
| Directory scan with extensions | `gobuster dir -u http://target-ip -w wordlist.txt -x php,bak,txt` |
| Faster scan (more threads) | `gobuster dir -u http://target-ip -w wordlist.txt -t 50` |
| Subdomain brute-force | `gobuster dns -d target.com -w subdomains.txt` |
| Vhost discovery | `gobuster vhost -u http://target.com -w subdomains.txt` |
| Behind a login (cookie) | `gobuster dir -u http://target-ip -w wordlist.txt -c "PHPSESSID=abc"` |
| Hide noisy status codes | `gobuster dir -u http://target-ip -w wordlist.txt -b 404,403` |
| Whitelist only real hits | `gobuster dir -u http://target-ip -w wordlist.txt -s 200,301,302` |
| Save results to file | `gobuster dir -u http://target-ip -w wordlist.txt -o out.txt` |

---

*Prepared as a reference for the eJPT web application module. All techniques should only be used within written authorization (scope/RoE).*
