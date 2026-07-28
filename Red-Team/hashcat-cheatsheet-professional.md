# ⚡ Hashcat - Advanced Password Cracker Complete Cheat Sheet

> **A Comprehensive Guide to Hashcat for GPU-Accelerated Password Cracking**

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Hash Modes](#hash-modes)
3. [Attack Modes](#attack-modes)
4. [Basic Usage](#basic-usage)
5. [Wordlist & Rules](#wordlist--rules)
6. [Mask Attack](#mask-attack)
7. [Hybrid Attack](#hybrid-attack)
8. [GPU Configuration](#gpu-configuration)
9. [Performance Optimization](#performance-optimization)
10. [Practical Examples](#practical-examples)
11. [Troubleshooting](#troubleshooting)

---

## Installation & Setup

### Linux Installation

```bash
# Debian/Ubuntu
sudo apt-get install hashcat

# RedHat/CentOS
sudo yum install hashcat

# Install NVIDIA drivers (for CUDA)
sudo apt-get install nvidia-driver-xxx nvidia-cuda-toolkit

# Install AMD drivers (for HIP)
sudo apt-get install rocm-dkms

# Kali Linux
hashcat --version
```

### Building from Source

```bash
# Clone repository
git clone https://github.com/hashcat/hashcat.git
cd hashcat

# Build
make

# Install
sudo make install

# Verify
hashcat --version
```

### Windows Installation

```powershell
# Download from official website
# https://hashcat.net/hashcat/

# Or use Chocolatey
choco install hashcat

# Verify
hashcat.exe --version
```

---

## Hash Modes

### Hash Type Numbers

| Mode | Hash Type | Example |
|------|-----------|---------|
| 0 | MD5 | 5f4dcc3b5aa765d61d8327deb882cf99 |
| 100 | SHA1 | 5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8 |
| 1400 | SHA2-256 | 5e884898da28047151d0e56f8dc6292... |
| 1700 | SHA2-512 | a665a45920422f9d417e4867efdc4fb... |
| 1000 | NTLM | 8846f7eaee8fb117ad06bdd830b7586c |
| 3200 | bcrypt | $2b$12$R9h/cIPz0gi.URNN3kh2OPST9/... |
| 5500 | NetNTLMv2 | admin::DOMAIN:nonce:response... |
| 22000 | WPA-PBKDF2 | (WiFi hashes) |
| 23500 | Bitwarden | (Password manager) |
| 13100 | Kerberos 5 | $krb5$... |

### List Available Modes

```bash
# List all hash modes
hashcat --list-hash-types

# Search for specific hash
hashcat --list-hash-types | grep -i ntlm
hashcat --list-hash-types | grep -i bcrypt
hashcat --list-hash-types | grep -i wifi

# Count modes
hashcat --list-hash-types | wc -l
```

---

## Attack Modes

### Attack Mode Numbers

```bash
# -a 0 = Straight (Dictionary)
# -a 1 = Combination (wordlist1 + wordlist2)
# -a 3 = Brute-Force (mask)
# -a 6 = Hybrid (wordlist + mask)
# -a 7 = Hybrid (mask + wordlist)
```

### Straight Attack (Dictionary)

```bash
# Basic dictionary attack
hashcat -m 0 hashes.txt wordlist.txt

# Verbose
hashcat -m 0 -v hashes.txt wordlist.txt

# Show progress
hashcat -m 0 --status hashes.txt wordlist.txt

# Save output
hashcat -m 0 -o results.txt hashes.txt wordlist.txt
```

---

## Basic Usage

### Simple Cracking

```bash
# MD5 cracking
hashcat -m 0 hash.txt wordlist.txt

# NTLM cracking
hashcat -m 1000 hash.txt wordlist.txt

# SHA256 cracking
hashcat -m 1400 hash.txt wordlist.txt

# bcrypt cracking
hashcat -m 3200 hash.txt wordlist.txt

# Multiple hashes
hashcat -m 0 hashes.txt wordlist.txt
```

### Hash File Formats

```bash
# MD5
5f4dcc3b5aa765d61d8327deb882cf99

# NTLM
admin:500:8846f7eaee8fb117ad06bdd830b7586c:31d6cfe0d16ae931b73c59d7e0c089c0:::

# Salted SHA1
5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8:salt

# One hash per line
```

---

## Wordlist & Rules

### Dictionary Attacks

```bash
# Standard wordlist
hashcat -m 0 -a 0 hashes.txt /usr/share/wordlists/rockyou.txt

# Multiple wordlists
cat list1.txt list2.txt > combined.txt
hashcat -m 0 -a 0 hashes.txt combined.txt

# Sorted wordlist
sort -u wordlist.txt > sorted.txt
hashcat -m 0 -a 0 hashes.txt sorted.txt
```

### Rules

```bash
# Apply rules
hashcat -m 0 -a 0 -r rules/best64.rule hashes.txt wordlist.txt

# List available rules
ls /usr/share/hashcat/rules/

# Common rules
# best64.rule
# d3ad0ne.rule
# dive.rule
# leetspeak.rule
# T0XlC.rule

hashcat -m 0 -a 0 -r /usr/share/hashcat/rules/best64.rule hashes.txt wordlist.txt
```

---

## Mask Attack

### Mask Basics

```bash
# Mask characters
# ?l = lowercase (a-z)
# ?u = uppercase (A-Z)
# ?d = digit (0-9)
# ?s = special (space !"#$%&'()*+,-./...:;<=>?@[\]^_`{|}~)
# ?a = all (?l?u?d?s)
# ?b = custom charset

# Examples
?d?d?d?d          # 4 digits (0000-9999)
?l?l?l?l?l        # 5 lowercase
?u?l?l?l?l        # Uppercase first, then 4 lowercase
Password?d?d?d    # Password + 3 digits
```

### Brute Force with Masks

```bash
# 4-digit brute force
hashcat -m 0 -a 3 hashes.txt ?d?d?d?d

# 5-character lowercase
hashcat -m 0 -a 3 hashes.txt ?l?l?l?l?l

# All printable characters (slower)
hashcat -m 0 -a 3 hashes.txt ?a?a?a?a

# Custom pattern
hashcat -m 0 -a 3 hashes.txt Password?d?d?d

# Range (min-max length)
hashcat -m 0 -a 3 -i hashes.txt ?l?l?l?l  # Incremental mode
```

### Custom Charsets

```bash
# Custom charset
# -1 = custom set 1
# -2 = custom set 2
# -3 = custom set 3
# -4 = custom set 4

# Example: digits + special
hashcat -m 0 -a 3 -1 "!@#$%^&*()" hashes.txt ?d?1?d

# Only vowels + numbers
hashcat -m 0 -a 3 -1 "aeiouAEIOU" hashes.txt ?1?d?1?d

# Specific characters
hashcat -m 0 -a 3 -1 "Pp" hashes.txt ?1assword
```

---

## Hybrid Attack

### Hybrid Modes

```bash
# Mode 6: Wordlist + Mask (append mask to wordlist)
hashcat -m 0 -a 6 hashes.txt wordlist.txt ?d?d?d

# Mode 7: Mask + Wordlist (prepend mask to wordlist)
hashcat -m 0 -a 7 hashes.txt ?d?d?d wordlist.txt

# Examples
# List: password, admin, user
# Mask: ?d?d?d?d

# Mode 6 generates: password0000, password1234, password9999, etc
# Mode 7 generates: 0000password, 1234password, 9999password, etc
```

---

## GPU Configuration

### NVIDIA GPU

```bash
# List NVIDIA devices
hashcat -I

# Use specific GPU
hashcat -m 0 -d 1 hashes.txt wordlist.txt

# Use multiple GPUs
hashcat -m 0 -d 1,2,3 hashes.txt wordlist.txt

# CUDA optimization
hashcat -m 0 -O hashes.txt wordlist.txt  # Optimized kernels
```

### AMD GPU

```bash
# List AMD devices
hashcat -I

# Use specific GPU
hashcat -m 0 -d 2 hashes.txt wordlist.txt

# ROCm support
# Requires ROCm drivers installed
```

### CPU Mode

```bash
# Force CPU
hashcat -m 0 -d 1 --workload-profile=3 hashes.txt wordlist.txt

# CPU threading
-n <threads>
# Default: auto
# Adjust for performance
```

---

## Performance Optimization

### Speed Tuning

```bash
# Workload profile (1=low, 2=default, 3=high, 4=nightmare)
hashcat -m 0 -w 4 hashes.txt wordlist.txt

# Optimize for speed
hashcat -m 0 -O hashes.txt wordlist.txt

# Specify kernel
hashcat -m 0 -k hashes.txt wordlist.txt

# Skip warmup
hashcat -m 0 --skip-warmup hashes.txt wordlist.txt
```

### Memory Usage

```bash
# Limit memory
hashcat -m 0 --limit-memory-use=2048 hashes.txt wordlist.txt

# Adjust kernel
-n <blocks>        # Number of GPU blocks

# Custom speed/memory trade-off
hashcat -m 0 -n 32 -u 256 hashes.txt wordlist.txt
```

---

## Practical Examples

### Linux Shadow File

```bash
# Unshadow
unshadow /etc/passwd /etc/shadow > unshadowed.txt

# Crack with Hashcat
hashcat -m 1800 unshadowed.txt /usr/share/wordlists/rockyou.txt

# Show results
hashcat -m 1800 unshadowed.txt --show
```

### Windows NTLM

```bash
# Extract hashes
# From: mimikatz, hashcat, metasploit

# Crack NTLM (very fast)
hashcat -m 1000 ntlm_hashes.txt /usr/share/wordlists/rockyou.txt

# With rules
hashcat -m 1000 -r rules/best64.rule ntlm_hashes.txt wordlist.txt

# Show results
hashcat -m 1000 ntlm_hashes.txt --show
```

### WiFi (WPA-PBKDF2)

```bash
# Extract from .cap file
# Use aircrack-ng to convert

hashcat -m 22000 wifi_hashes.txt wordlist.txt -w 4

# Or WPA2
hashcat -m 2500 wifi_hashes.txt wordlist.txt
```

### Database Hashes

```bash
# bcrypt (WordPress, etc)
hashcat -m 3200 wordpress_hashes.txt wordlist.txt

# phpass (WordPress alternative)
hashcat -m 400 phpass_hashes.txt wordlist.txt

# MySQL
hashcat -m 300 mysql_hashes.txt wordlist.txt
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "No device found" | Check GPU drivers, use CPU with -d 1 |
| "Kernel not found" | Try different kernel: -k |
| "Out of memory" | Reduce wordlist, use -w 1, limit memory |
| "Slow speed" | Enable -O, increase -w, use -n,-u |
| "Wrong hash format" | Verify hash type and mode number |

### Debug & Info

```bash
# Show devices
hashcat -I

# Benchmark
hashcat -m 0 -b

# Verbose
hashcat -m 0 -v hashes.txt wordlist.txt

# Quiet
hashcat -m 0 -q hashes.txt wordlist.txt

# Status
hashcat -m 0 --status hashes.txt wordlist.txt
```

---

## Quick Reference

```bash
# MD5
hashcat -m 0 hash.txt wordlist.txt

# NTLM  
hashcat -m 1000 hash.txt wordlist.txt

# SHA256
hashcat -m 1400 hash.txt wordlist.txt

# bcrypt
hashcat -m 3200 hash.txt wordlist.txt

# Brute force
hashcat -m 0 -a 3 hash.txt ?d?d?d?d

# With rules
hashcat -m 0 -r rules/best64.rule hash.txt wordlist.txt

# GPU acceleration
hashcat -m 0 -O -w 4 hash.txt wordlist.txt

# Show results
hashcat -m 0 hash.txt --show
```

---

## Resources

- [Hashcat Official](https://hashcat.net/)
- [Hash Types](https://hashcat.net/wiki/doku.php?id=hashcat)
- [Rules](https://github.com/hashcat/hashcat/tree/master/rules)
- [Wordlists](https://github.com/danielmiessler/SecLists)

---

© 2026 | Hashcat Cheat Sheet | Educational Purpose
