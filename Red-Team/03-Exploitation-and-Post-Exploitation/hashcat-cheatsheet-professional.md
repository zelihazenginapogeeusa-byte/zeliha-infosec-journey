# Hashcat Cheat Sheet

**Hashcat** is a GPU-accelerated offline password cracker and the tool to reach for once a job outgrows John the Ripper's CPU throughput — it's central to eJPT's host/network module for cracking NTLM dumps, Kerberoast/AS-REP hashes, and anything else pulled from a compromised Active Directory environment. This document covers hash-mode selection, attack modes, mask syntax, and the exact commands used against common hash types.

---

## Table of Contents

1. [What Hashcat Does & Why It's Faster](#1-what-hashcat-does--why-its-faster)
2. [Hash Mode Reference](#2-hash-mode-reference)
3. [Attack Modes](#3-attack-modes)
4. [Basic Syntax & Rules](#4-basic-syntax--rules)
5. [Common Commands](#5-common-commands)
6. [Quick Command Reference](#6-quick-command-reference)

---

## 1. What Hashcat Does & Why It's Faster

Hashcat offloads the hashing workload to the GPU, which can compute massively more hash candidates per second than a CPU for most hash types — the practical effect is that wordlist and mask attacks that would take John hours can finish in minutes.

- **CPU (John the Ripper):** better for oddball formats and small jobs — see `john-the-ripper-cheatsheet-professional.md`.
- **GPU (Hashcat):** better for high-volume, well-supported hash types — NTLM, Kerberos tickets, common web app hashes — where raw throughput matters most.

> Rule of thumb: convert files with `*2john` and reach for John first on archives/SSH keys; switch to Hashcat once you're cracking a large dump (NTDS.dit, SAM) or a Kerberos-derived hash.

---

## 2. Hash Mode Reference

Every hash type has a numeric `-m` mode — picking the wrong one silently fails to crack anything, so identify the hash format before running.

| Mode (`-m`) | Hash Type |
|---|---|
| `0` | MD5 |
| `100` | SHA1 |
| `1000` | NTLM |
| `1800` | sha512crypt (`/etc/shadow`, Linux) |
| `13100` | Kerberos 5, TGS-REP etype 23 (**Kerberoasting**) |
| `18200` | Kerberos 5, AS-REP etype 23 (**AS-REP Roasting**) |

```bash
# Identify a hash's likely mode
hashcat --identify hash.txt
```

> Modes `13100` and `18200` are the same ones referenced in `active-directory-enumeration-cheatsheet-professional.md`'s Kerberoasting and AS-REP Roasting sections — this file is the fuller cracking reference those sections point back to.

---

## 3. Attack Modes

The `-a` flag selects the strategy Hashcat uses to generate password candidates.

| Mode (`-a`) | Name | Description |
|---|---|---|
| `0` | Straight | Standard wordlist attack |
| `1` | Combinator | Combines two wordlists, word + word |
| `3` | Brute-force / Mask | Generates candidates from a character-set mask |
| `6` | Hybrid (wordlist + mask) | Wordlist entries with a mask appended |
| `7` | Hybrid (mask + wordlist) | Mask prepended to wordlist entries |

```bash
# Mask attack: uppercase letter, 3 lowercase letters, 4 digits (e.g. "Pass1234")
hashcat -m 1000 -a 3 hash.txt ?u?l?l?l?d?d?d?d
```

| Mask charset | Meaning |
|---|---|
| `?l` | Lowercase a-z |
| `?u` | Uppercase A-Z |
| `?d` | Digit 0-9 |
| `?s` | Special characters |
| `?a` | All of the above |

---

## 4. Basic Syntax & Rules

Every Hashcat run follows the same base structure: hash mode, attack mode, hash file, then the wordlist/mask.

```bash
hashcat -m <hash-mode> -a <attack-mode> hash.txt wordlist.txt

# Apply mangling rules on top of a wordlist attack (leet-speak, case swaps, appended digits)
hashcat -m 1000 -a 0 hash.txt rockyou.txt -r /usr/share/hashcat/rules/best64.rule
```

| Flag | Purpose |
|---|---|
| `-m` | Hash mode (see table above) |
| `-a` | Attack mode (see table above) |
| `-r` | Rule file to apply against wordlist candidates |
| `-o` | Output file for cracked results |
| `--show` | Show already-cracked hashes from the potfile without re-running |

---

## 5. Common Commands

Real end-to-end examples for the scenarios that come up most in engagements and in the exam.

```bash
# Crack a dumped NTLM hash list (e.g. from secretsdump.py)
hashcat -m 1000 -a 0 ntlm-hashes.txt rockyou.txt

# Crack a Kerberoast hash (TGS-REP)
hashcat -m 13100 -a 0 kerberoast-hashes.txt rockyou.txt

# Crack an AS-REP hash
hashcat -m 18200 -a 0 asrep-hashes.txt rockyou.txt

# Resume an interrupted session
hashcat --restore

# Show cracked results without re-running the attack
hashcat -m 1000 --show ntlm-hashes.txt
```

> Hashcat writes session state automatically — a long mask or wordlist run that's interrupted (Ctrl+C, reboot, disconnect) can be picked up exactly where it left off with `--restore` instead of starting over.

---

## 6. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Identify hash type | `hashcat --identify hash.txt` |
| Wordlist attack | `hashcat -m 1000 -a 0 hash.txt rockyou.txt` |
| Mask/brute-force attack | `hashcat -m 1000 -a 3 hash.txt ?u?l?l?l?d?d?d?d` |
| Wordlist + rules | `hashcat -m 1000 -a 0 hash.txt rockyou.txt -r best64.rule` |
| Crack NTLM dump | `hashcat -m 1000 -a 0 ntlm-hashes.txt rockyou.txt` |
| Crack Kerberoast hash | `hashcat -m 13100 -a 0 kerberoast-hashes.txt rockyou.txt` |
| Crack AS-REP hash | `hashcat -m 18200 -a 0 asrep-hashes.txt rockyou.txt` |
| Resume interrupted session | `hashcat --restore` |
| Show cracked results | `hashcat -m 1000 --show hash.txt` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
