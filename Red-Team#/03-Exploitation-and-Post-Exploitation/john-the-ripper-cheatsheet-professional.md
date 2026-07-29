# John the Ripper Cheat Sheet

**John the Ripper** (often just "John") is a CPU-focused offline password cracker used throughout eJPT's host/network module whenever a captured hash — from `/etc/shadow`, a protected archive, an SSH key, or a Windows SAM dump — needs to be turned back into a plaintext password. It's a first-choice tool for smaller or CPU-friendly hash types before reaching for GPU-accelerated cracking.

---

## Table of Contents

1. [What John Does & Supported Hash Types](#1-what-john-does--supported-hash-types)
2. [Converting Files to a Crackable Format](#2-converting-files-to-a-crackable-format)
3. [Cracking Modes](#3-cracking-modes)
4. [Common Commands by Target Type](#4-common-commands-by-target-type)
5. [Viewing Cracked Passwords](#5-viewing-cracked-passwords)
6. [John vs Hashcat](#6-john-vs-hashcat)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. What John Does & Supported Hash Types

John takes a file of hashes and repeatedly guesses plaintext candidates, hashing each one and comparing it to the target — it auto-detects the hash format in most cases but can be told explicitly with `--format`.

- Unix `/etc/shadow` crypt formats (`md5crypt`, `sha256crypt`, `sha512crypt`)
- Windows NTLM / LM hashes
- Archive and document passwords (ZIP, RAR, Office, PDF)
- Private key passphrases (SSH, PGP)
- Raw hash types (`raw-md5`, `raw-sha1`, etc.)

```bash
# List every format John supports
john --list=formats

# Force a specific format instead of relying on auto-detection
john --format=raw-md5 hashes.txt
```

---

## 2. Converting Files to a Crackable Format

John can't read a `.zip`, `.rar`, or SSH private key directly — a `*2john` helper script extracts the embedded hash into a format John understands first.

```bash
# ZIP archive
zip2john protected.zip > zip.hash

# RAR archive
rar2john protected.rar > rar.hash

# SSH private key (passphrase-protected)
ssh2john id_rsa > ssh.hash

# Microsoft Office document (docx/xlsx/pptx)
office2john protected.docx > office.hash
```

> Every `*2john` tool writes its output to stdout — always redirect it to a file, then hand that file to `john` normally.

---

## 3. Cracking Modes

John supports several attack strategies, selectable per run and often chained together.

```bash
# Wordlist mode — try every word in a list (optionally with mangling rules)
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt

# Single-crack mode — derives guesses from the username/GECOS fields in the hash file itself
john --single hashes.txt

# Incremental mode — full brute-force, character by character (slow, exhaustive)
john --incremental hashes.txt

# Wordlist + mangling rules (leet-speak, capitalization, appended digits, etc.)
john --wordlist=rockyou.txt --rules hashes.txt
```

| Mode | Best for |
|---|---|
| `--single` | Fast first pass — usernames/fields often ARE the password |
| `--wordlist` | Standard dictionary attack |
| `--wordlist --rules` | Dictionary + common human password patterns |
| `--incremental` | Short/unknown passwords, last resort — very slow |

---

## 4. Common Commands by Target Type

Real end-to-end examples for the target types that come up most often.

```bash
# Linux /etc/shadow — combine with /etc/passwd first so John has usernames + hash together
unshadow /etc/passwd /etc/shadow > combined.txt
john --wordlist=rockyou.txt combined.txt

# ZIP file
zip2john secrets.zip > zip.hash
john --wordlist=rockyou.txt zip.hash

# SSH private key
ssh2john id_rsa > ssh.hash
john --wordlist=rockyou.txt ssh.hash
```

> `unshadow` matters because `/etc/shadow` alone has no usernames tied to readable context — merging it with `/etc/passwd` gives John the full picture and lets `--single` mode use the username as a candidate.

---

## 5. Viewing Cracked Passwords

John doesn't print cracked passwords to the console by default on every run — recovered plaintexts are stored in `~/.john/john.pot` and retrieved with `--show`.

```bash
# Show every password cracked so far for a given hash file
john --show combined.txt

# Show only cracked entries, with a count of how many hashes remain uncracked
john --show hashes.txt
```

---

## 6. John vs Hashcat

A quick comparison to help decide which cracker to reach for.

| | John the Ripper | Hashcat |
|---|---|---|
| **Primary engine** | CPU | GPU (much faster for supported hash types) |
| **Strengths** | Broad file-format support (`*2john` ecosystem), simple single-crack mode | Raw speed on hash-heavy workloads (NTLM dumps, Kerberoasting) |
| **Best for** | Archives, SSH keys, quick jobs on modest hardware | Large wordlists/mask attacks against NTLM, Kerberos, and other high-volume hash types |

> See `hashcat-cheatsheet-professional.md` for GPU-based cracking — in practice, use John for file/archive-derived hashes and switch to Hashcat once you have a large NTLM dump or a Kerberoast/AS-REP hash to burn through (both referenced in `active-directory-enumeration-cheatsheet-professional.md`).

---

## 7. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| List supported formats | `john --list=formats` |
| Convert ZIP | `zip2john protected.zip > zip.hash` |
| Convert RAR | `rar2john protected.rar > rar.hash` |
| Convert SSH key | `ssh2john id_rsa > ssh.hash` |
| Convert Office doc | `office2john protected.docx > office.hash` |
| Wordlist attack | `john --wordlist=rockyou.txt hashes.txt` |
| Single-crack mode | `john --single hashes.txt` |
| Wordlist + rules | `john --wordlist=rockyou.txt --rules hashes.txt` |
| Incremental (brute-force) | `john --incremental hashes.txt` |
| Merge shadow + passwd | `unshadow /etc/passwd /etc/shadow > combined.txt` |
| Show cracked passwords | `john --show combined.txt` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
