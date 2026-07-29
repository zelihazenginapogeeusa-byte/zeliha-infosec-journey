# Nmap Cheat Sheet

**Nmap** (Network Mapper) is the foundational tool of every eJPT host/network pentest engagement — it's almost always the very first command run against a target, mapping live hosts, open ports, running services, and often the underlying OS before any exploitation begins. This document covers scan types, targeting, timing, service/OS detection, the scripting engine, output formats, and evasion.

---

## Table of Contents

1. [Scan Types & Core Syntax](#1-scan-types--core-syntax)
2. [Target Specification](#2-target-specification)
3. [Port Specification & Timing](#3-port-specification--timing)
4. [Service/Version Detection & OS Fingerprinting](#4-serviceversion-detection--os-fingerprinting)
5. [NSE — Nmap Scripting Engine](#5-nse--nmap-scripting-engine)
6. [Output Formats](#6-output-formats)
7. [Firewall/IDS Evasion](#7-firewallids-evasion)
8. [Practical eJPT Workflow](#8-practical-ejpt-workflow)
9. [Quick Command Reference](#9-quick-command-reference)

---

## 1. Scan Types & Core Syntax

Each scan type probes ports differently — the choice affects speed, stealth, and what privilege level the scan requires.

| Flag | Scan Type | Notes |
|---|---|---|
| `-sS` | TCP SYN ("half-open") scan | Default when run as root; fast, doesn't complete the TCP handshake, harder to log |
| `-sT` | TCP Connect scan | Completes the full handshake; used when raw sockets aren't available (non-root) |
| `-sU` | UDP scan | Much slower — UDP has no handshake, relies on ICMP unreachable to infer closed ports |
| `-sV` | Service/version detection | Probes open ports to identify the running service and version |
| `-sC` | Default script scan | Runs the NSE `default` category against discovered ports |
| `-sn` | Ping scan (host discovery only) | No port scan — just determines which hosts are up |
| `-Pn` | Skip host discovery | Treats every target as online; needed when ICMP is blocked |
| `-A` | Aggressive scan | Combines `-sV -O -sC --traceroute` in one flag |

```bash
nmap -sS -sV -sC target-ip          # Common "first look" combo (root)
nmap -sT target-ip                  # Non-root fallback
nmap -sn 192.168.1.0/24             # Host discovery sweep across a subnet
nmap -Pn -sS target-ip              # When the host doesn't respond to ping
```

---

## 2. Target Specification

How targets are supplied to nmap dictates how broad or narrow a scan is.

```bash
nmap 192.168.1.10                          # Single IP
nmap 192.168.1.0/24                        # CIDR notation — entire subnet
nmap 192.168.1.10-50                       # IP range
nmap -iL targets.txt                       # Read target list from a file
nmap 192.168.1.0/24 --exclude 192.168.1.1  # Scan a range but skip specific hosts
nmap 192.168.1.10 192.168.1.20 scanme.nmap.org  # Multiple targets/hostnames in one command
```

> Always confirm the target list against the written scope/RoE before scanning a range — CIDR scans are easy to accidentally overreach with.

---

## 3. Port Specification & Timing

Controls which ports get probed and how fast — the two biggest levers for scan duration and noise.

| Flag | Purpose |
|---|---|
| `-p 80,443` | Scan specific ports |
| `-p 1-1000` | Scan a port range |
| `-p-` | Scan all 65535 TCP ports |
| `--top-ports 100` | Scan nmap's N most common ports (by frequency) |
| `-F` | Fast mode — scans the 100 most common ports only |

Timing templates trade scan speed against stealth and reliability:

| Template | Name | Trade-off |
|---|---|---|
| `-T0` | Paranoid | Extremely slow, IDS evasion, one probe every 5 min |
| `-T1` | Sneaky | Very slow, still evasion-focused |
| `-T2` | Polite | Slower than default, reduces network load |
| `-T3` | Normal | Default — balanced |
| `-T4` | Aggressive | Faster, assumes a reliable/fast network — common for eJPT labs |
| `-T5` | Insane | Fastest, sacrifices accuracy — risks dropped/missed results |

```bash
nmap -p- -T4 target-ip                 # Full TCP port sweep, fast timing
nmap --top-ports 20 -sU target-ip      # Quick UDP top-ports check
```

---

## 4. Service/Version Detection & OS Fingerprinting

Identifying exactly what's listening on a port (and what OS the host runs) turns an open-port list into an actionable target profile.

```bash
nmap -sV target-ip                        # Version detection on open ports
nmap -sV --version-intensity 9 target-ip  # Max intensity — more probes, more accurate, slower
nmap -sV --version-light target-ip        # Fewer probes — faster, less thorough
nmap -O target-ip                         # OS fingerprinting (TCP/IP stack behavior)
nmap -A target-ip                         # Version + OS + default scripts + traceroute in one pass
```

> `--version-intensity` ranges 0-9; the default is 7. Bump it to 9 when a service is misidentified or unclear, drop it for speed on a large sweep.

---

## 5. NSE — Nmap Scripting Engine

NSE extends nmap with Lua scripts for deeper enumeration, vulnerability detection, and even limited exploitation — this is where nmap goes from "port lister" to genuine recon tool.

| Category | Purpose |
|---|---|
| `default` (`-sC`) | Safe, commonly useful scripts — run automatically with `-A` |
| `safe` | Won't crash the target or cause a DoS |
| `vuln` | Checks for known CVEs/vulnerabilities |
| `discovery` | Broader service/network information gathering |
| `intrusive` | May be noisy, disruptive, or trigger IDS/lockouts — use with caution |

```bash
nmap --script default target-ip
nmap --script vuln target-ip                          # Full vuln-category sweep
nmap --script smb-vuln-ms17-010 -p 445 target-ip       # Targeted EternalBlue check
nmap --script http-enum -p 80 target-ip                # Enumerate common web paths
nmap --script "smb-enum-shares,smb-enum-users" -p 445 target-ip  # Multiple named scripts
```

> Scripts live under `/usr/share/nmap/scripts/` — use `--script-help <name>` to see exactly what a script does before running it against a production target.

---

## 6. Output Formats

Saving scan output in a parseable format matters for later automation and for report evidence.

| Flag | Format |
|---|---|
| `-oN <file>` | Normal — same as terminal output |
| `-oX <file>` | XML — machine-parseable, feeds tools like Metasploit's `db_import` |
| `-oG <file>` | Grepable — legacy format, easy to `grep`/`awk` |
| `-oA <basename>` | All three formats at once, sharing a base filename |

```bash
nmap -sS -sV -A -oA fullscan target-ip   # Produces fullscan.nmap, fullscan.xml, fullscan.gnmap
```

---

## 7. Firewall/IDS Evasion

Techniques to reduce the chance a scan is logged or blocked — relevant when an engagement's scope calls for stealth.

```bash
nmap -f target-ip                     # Fragment packets — split probes across smaller IP packets
nmap -D RND:5 target-ip               # 5 random decoy source IPs alongside the real one
nmap -D decoy1,decoy2,ME target-ip    # Specific decoy IPs, ME marks your real position
nmap -g 53 target-ip                  # Spoof source port (e.g. 53/DNS often trusted by firewalls)
nmap -T1 --scan-delay 5s target-ip    # Slow, spaced-out probes to stay under IDS thresholds
nmap --data-length 25 target-ip       # Pad packets to obscure the nmap fingerprint
```

> Evasion techniques increase scan time significantly and are not a substitute for authorization — use them only when the RoE explicitly calls for stealth/evasion testing.

---

## 8. Practical eJPT Workflow

A suggested scan order that balances speed with thoroughness on a fresh target.

```bash
# 1. Quick host discovery / top-ports sweep across the range
nmap -sn 192.168.1.0/24

# 2. Fast top-ports scan on the live target to get an early picture
nmap -T4 --top-ports 100 target-ip

# 3. Full TCP port sweep — don't assume the "interesting" ports are the only open ones
nmap -p- -T4 target-ip

# 4. UDP top-ports (often skipped, often where the interesting stuff hides)
nmap -sU --top-ports 20 target-ip

# 5. Version detection + default scripts on the confirmed open ports
nmap -sV -sC -p <open-ports> target-ip

# 6. Targeted NSE vuln scripts based on identified services
nmap --script vuln -p <open-ports> target-ip
```

> Findings here dictate the next tool: SMB/445 open feeds into `smb-windows-enumeration-cheatsheet-professional.md`, HTTP/HTTPS ports feed into `web-enumeration-common-vulns-cheatsheet-professional.md` and `gobuster-cheatsheet-professional.md`.

---

## 9. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Quick SYN + version + default scripts | `nmap -sS -sV -sC target-ip` |
| Host discovery sweep | `nmap -sn 192.168.1.0/24` |
| Full TCP port sweep | `nmap -p- -T4 target-ip` |
| UDP top ports | `nmap -sU --top-ports 20 target-ip` |
| OS fingerprint | `nmap -O target-ip` |
| Aggressive all-in-one | `nmap -A target-ip` |
| Run vuln scripts | `nmap --script vuln target-ip` |
| Targeted NSE script | `nmap --script smb-vuln-ms17-010 -p 445 target-ip` |
| Save all output formats | `nmap -sS -sV -A -oA fullscan target-ip` |
| Skip host discovery | `nmap -Pn -sS target-ip` |
| Fragment packets (evasion) | `nmap -f target-ip` |
| Decoy scan (evasion) | `nmap -D RND:5 target-ip` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
