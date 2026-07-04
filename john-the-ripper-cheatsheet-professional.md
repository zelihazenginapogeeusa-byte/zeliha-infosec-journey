# 🔐 John The Ripper - Password Cracker Complete Cheat Sheet

> **A Comprehensive Guide to John The Ripper for Password Cracking and Hash Analysis**

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Hash Formats](#hash-formats)
3. [Basic Cracking](#basic-cracking)
4. [Dictionary Attacks](#dictionary-attacks)
5. [Brute Force](#brute-force)
6. [Rules & Wordlist Manipulation](#rules--wordlist-manipulation)
7. [GPU Acceleration](#gpu-acceleration)
8. [Unshadow & Password Files](#unshadow--password-files)
9. [John Formats](#john-formats)
10. [Advanced Techniques](#advanced-techniques)
11. [Performance & Optimization](#performance--optimization)
12. [Troubleshooting](#troubleshooting)

---

## Installation & Setup

### Linux Installation

```bash
# Debian/Ubuntu
sudo apt-get install john

# RedHat/CentOS
sudo yum install john

# Kali Linux (pre-installed)
john --version

# From source
git clone https://github.com/openwall/john.git
cd john/src
./configure
make
sudo make install
```

### macOS Installation

```bash
# Using Homebrew
brew install john-jumbo

# Verify
john --version
```

### Windows Installation

```powershell
# Using Chocolatey
choco install john

# Or download from GitHub
# https://www.openwall.com/john/
```

### John Jumbo (Extended Version)

```bash
# Install jumbo version (more formats)
git clone https://github.com/openwall/john.git
cd john/src
./configure
make -s clean && make -s
./john --version
```

---

## Hash Formats

### Common Hash Formats

```bash
# MD5
5f4dcc3b5aa765d61d8327deb882cf99  # password

# SHA1
5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8  # password

# SHA256
5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8  # password

# NTLM (Windows)
8846f7eaee8fb117ad06bdd830b7586c  # password

# bcrypt
$2b$12$R9h/cIPz0gi.URNN3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUga

# SHA512
a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3  # password

# PHPass (WordPress)
$P$8ohUEsVe8yMZe7VYrAkC0bnxrHd7/  # password

# PBKDF2
sha1$c000$1$1c1c395d1c11e93a36a1c4e5e6c3f4fe87f4c4be  # password
```

### Identify Hash Type

```bash
# Using john
john --list=formats | grep -i md5

# Manual identification
# 32 chars = MD5/NTLM
# 40 chars = SHA1
# 64 chars = SHA256
# 128 chars = SHA512
# $1$ = MD5 crypt
# $2a/b$ = bcrypt
# $5$ = SHA256 crypt
# $6$ = SHA512 crypt
```

---

## Basic Cracking

### Dictionary Attack

```bash
# Basic dictionary attack
john hashes.txt

# With specific wordlist
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt

# Single user
john --wordlist=wordlist.txt --user=admin hashes.txt

# Show progress
john --wordlist=wordlist.txt hashes.txt --progress=every=10000

# Verbose
john -v --wordlist=wordlist.txt hashes.txt
```

### Single Hash

```bash
# Crack single hash
echo "5f4dcc3b5aa765d61d8327deb882cf99" > hash.txt
john hash.txt

# Specify format
john --format=md5 hash.txt

# With wordlist
john --wordlist=wordlist.txt --format=md5 hash.txt
```

### Session Management

```bash
# Start named session
john hashes.txt -session=mysession

# Restore session
john --restore=mysession

# List sessions
john --status=mysession

# Kill session
john --dupes=hashes.txt
```

---

## Dictionary Attacks

### Wordlist Usage

```bash
# Default wordlist
john hashes.txt

# Custom wordlist
john --wordlist=/path/to/wordlist.txt hashes.txt

# Multiple wordlists
john --wordlist=list1.txt hashes.txt
john --wordlist=list2.txt hashes.txt

# Create wordlist
echo "password" > custom.txt
echo "123456" >> custom.txt
echo "admin" >> custom.txt

john --wordlist=custom.txt hashes.txt
```

### Common Wordlists

```bash
# Kali Linux
/usr/share/wordlists/rockyou.txt
/usr/share/wordlists/fasttrack.txt
/usr/share/wordlists/dirb/common.txt

# Downloaded
git clone https://github.com/danielmiessler/SecLists.git
/root/SecLists/Passwords/Common-Credentials/

# Passwords
/root/SecLists/Passwords/Common-Credentials/10-million-password-list-top-10000.txt
/root/SecLists/Passwords/Leaked-Databases/rockyou.txt
```

### Wordlist Manipulation

```bash
# Case variations (with rules)
john --wordlist=wordlist.txt --rules hashes.txt

# Remove duplicates
sort -u wordlist.txt > unique.txt

# By length
awk 'length>=6 && length<=10' wordlist.txt > filtered.txt

# Combine wordlists
cat list1.txt list2.txt | sort -u > combined.txt

# Count lines
wc -l wordlist.txt
```

---

## Brute Force

### Basic Brute Force

```bash
# Brute force (very slow)
john --incremental hashes.txt

# Brute force with time limit
john --incremental hashes.txt --max-run-time=3600

# Brute force specific charset
john --incremental=LowerCase hashes.txt
john --incremental=UpperCase hashes.txt
john --incremental=Digits hashes.txt
```

### Incremental Modes

```bash
# List available incremental modes
john --list=incremental

# Common charsets
# LowerCase: a-z
# UpperCase: A-Z
# Digits: 0-9
# Alnum: a-z, A-Z, 0-9
# LowerNumber: a-z, 0-9
# UpperNumber: A-Z, 0-9

john --incremental=LowerCase --max-run-time=3600 hashes.txt
john --incremental=Digits --max-run-time=7200 hashes.txt
```

---

## Rules & Wordlist Manipulation

### Using Rules

```bash
# Default rules
john --wordlist=wordlist.txt --rules hashes.txt

# Specific rule set
john --wordlist=wordlist.txt --rules=Single hashes.txt
john --wordlist=wordlist.txt --rules=Wordlist hashes.txt
john --wordlist=wordlist.txt --rules=Extra hashes.txt

# List available rules
john --list=rules

# Show rules
john --list=rules=Single
```

### Common Rules

```bash
# Uppercase first letter
# John's built-in rules include:
# - Capitalize first letter
# - Append numbers
# - Prepend numbers
# - Reverse strings
# - Substitute characters (l->1, e->3, etc)

# Example wordlist expansion with rules
# Input: password
# Output: Password, PASSWORD, password1, password12, etc.
```

### Create Custom Rules

```bash
# Edit /etc/john/john.conf or create custom.conf

cat > custom.conf << 'EOF'
[List.Rules:Custom]
# Capitalize
c
# Append digits
$1 $2 $3
# Append special chars
$! $@
# Reverse
r
EOF

john --config=custom.conf --rules=Custom --wordlist=wordlist.txt hashes.txt
```

---

## GPU Acceleration

### JohnTheRipper with GPU

```bash
# Install GPU support
# For NVIDIA (CUDA)
git clone https://github.com/openwall/john.git
cd john/src
./configure --enable-cuda
make

# For AMD (HIP)
./configure --enable-hip
make

# For OpenCL
./configure --enable-opencl
make
```

### Hashcat (Alternative GPU Cracker)

```bash
# Installation
sudo apt-get install hashcat

# Basic usage
hashcat -m 0 hashes.txt wordlist.txt

# Mode numbers
# 0 = MD5
# 1400 = SHA2-256
# 1700 = SHA2-512
# 1000 = NTLM
# 3200 = bcrypt
# 5500 = NetNTLMv2
```

---

## Unshadow & Password Files

### Linux Password Cracking

```bash
# Unshadow password files
# Extract from /etc/passwd and /etc/shadow
unshadow /etc/passwd /etc/shadow > hashes.txt

# Crack unshadowed hashes
john hashes.txt

# Wordlist
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt

# Show cracked passwords
john --show hashes.txt
```

### Windows Password Extraction

```bash
# Extract NTLM from SAM
# Use dumpsec or similar tools
# Import into text file

# Example NTLM hashes
administrator:500:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::

# Crack
john --format=NT hashes.txt

# With wordlist
john --wordlist=wordlist.txt --format=NT hashes.txt
```

### Displaying Results

```bash
# Show cracked passwords
john --show hashes.txt

# Show specific user
john --show=admin hashes.txt

# Verbose show
john --show hashes.txt -v

# Export results
john --show hashes.txt > cracked.txt
```

---

## John Formats

### Hash Format Specification

```bash
# List supported formats
john --list=formats

# Common formats
john --format=md5 hashes.txt
john --format=NT hashes.txt
john --format=sha512crypt hashes.txt
john --format=bcrypt hashes.txt
john --format=phpass hashes.txt

# WordPress
john --format=phpass hashes.txt --wordlist=wordlist.txt
```

### Detect Format Automatically

```bash
# John auto-detects in most cases
john hashes.txt

# Specify if detection fails
john --format=dynamic_1034 hashes.txt

# List dynamic formats
john --list=formats | grep dynamic
```

---

## Advanced Techniques

### Mask Attack (Like Hashcat)

```bash
# John doesn't have native mask, use Hashcat
hashcat -a 3 -m 0 hashes.txt ?d?d?d?d

# Mask help
# ?d = digit
# ?l = lowercase
# ?u = uppercase
# ?s = special
# ?a = all
```

### Hybrid Attack

```bash
# Dictionary + Brute force (with rules)
john --wordlist=wordlist.txt --rules --incremental=Digits hashes.txt --max-run-time=3600

# Combine multiple techniques
john --wordlist=list1.txt hashes.txt
john --wordlist=list2.txt --rules hashes.txt
```

### Markov Chains

```bash
# Generate Markov-based wordlist
# Requires generating stats first

# Some versions support Markov mode
# john --markov=1 hashes.txt

# Alternative: use crunch or hashcat
crunch 8 12 -o wordlist.txt
john --wordlist=wordlist.txt hashes.txt
```

### Preprocessing Hashes

```bash
# Extract usernames
cut -d: -f1 hashes.txt > usernames.txt

# Format conversion
cut -d: -f1,2 /etc/passwd > formatted.txt

# Unshadow
unshadow /etc/passwd /etc/shadow > unshadowed.txt
john unshadowed.txt
```

---

## Performance & Optimization

### Optimization Options

```bash
# Max runtime (seconds)
john --max-run-time=3600 hashes.txt

# Multiple CPU cores
john --fork=4 hashes.txt

# Skip broken hashes
john --skip-self-tests hashes.txt

# Quiet mode
john -q hashes.txt

# Verbose
john -v hashes.txt
```

### Speed Improvements

```bash
# Use GPU with Hashcat
hashcat -m 0 -a 0 hashes.txt wordlist.txt

# Optimize wordlist (remove duplicates)
sort -u wordlist.txt > opt.txt

# Use smaller, targeted wordlist
# Instead of rockyou.txt (140MB), use curated list

# Exclude already cracked
john --show hashes.txt > cracked.txt
john --restore=session2 hashes.txt
```

---

## Practical Workflows

### Linux Password Cracking

```bash
# 1. Extract hashes
unshadow /etc/passwd /etc/shadow > hashes.txt

# 2. Identify format
john --list=formats | grep crypt

# 3. Dictionary attack
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt

# 4. Show results
john --show hashes.txt
```

### Windows NTLM

```bash
# 1. Extract NTLM hashes (via Metasploit, etc)
# Copy hashes to file

# 2. Crack NTLM
john --format=NT hashes.txt

# 3. Or use Hashcat (faster)
hashcat -m 1000 hashes.txt /usr/share/wordlists/rockyou.txt

# 4. Display cracked
john --show --format=NT hashes.txt
```

### Web Application Hashes

```bash
# 1. Extract hashes
# From database dump or app logs

# 2. Identify type
# MD5, SHA1, bcrypt, phpass, etc.

# 3. Crack with appropriate format
john --format=phpass hashes.txt --wordlist=wordlist.txt

# 4. Verify against application
# Test with cracked credentials
```

### Multiple Hash Types

```bash
# 1. Separate hashes by type
grep '^\$1\$' all.txt > md5crypt.txt
grep '^\$2' all.txt > bcrypt.txt
grep -v '^\$' all.txt > ntlm.txt

# 2. Crack each type
john --format=md5crypt md5crypt.txt
john --format=bcrypt bcrypt.txt
john --format=NT ntlm.txt

# 3. Combine results
john --show md5crypt.txt > all_cracked.txt
john --show bcrypt.txt >> all_cracked.txt
john --show ntlm.txt >> all_cracked.txt
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Unsupported hash type" | Specify format with --format= |
| "No password hashes loaded" | Check hash format, try different format |
| "Very slow" | Use Hashcat with GPU, optimize wordlist |
| "Session not found" | Check session name, use --status |
| "Out of memory" | Reduce wordlist size, use GPU |

### Debug Mode

```bash
# Verbose output
john -v hashes.txt

# Very verbose
john -vv hashes.txt

# Test mode
john --test

# Benchmark
john --benchmark
john --benchmark=all
```

### Hash Verification

```bash
# Test with known password
echo "test" | md5sum
# Compare with hash

# Generate test hash
echo -n "password" | md5sum

# Verify cracked password
# Use password on original system/app
```

---

## Quick Reference

### Most Common Commands

```bash
# Dictionary attack
john --wordlist=wordlist.txt hashes.txt

# Linux unshadow
unshadow /etc/passwd /etc/shadow | john --stdin

# Show results
john --show hashes.txt

# NTLM hashes
john --format=NT hashes.txt

# bcrypt hashes
john --format=bcrypt hashes.txt
```

### Hash Type Reference

| Type | Format | Example |
|------|--------|---------|
| MD5 | md5 | 5f4dcc3b5aa765d61d8327deb882cf99 |
| SHA1 | raw-sha1 | 5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8 |
| SHA256 | raw-sha256 | 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8 |
| NTLM | nt | 8846f7eaee8fb117ad06bdd830b7586c |
| bcrypt | bcrypt | $2b$12$R9h/cIPz0gi.URNN3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUga |
| MD5 Crypt | md5crypt | $1$saltvalue$d9f829792622e5f...  |
| SHA512 Crypt | sha512crypt | $6$saltvalue$3... |

---

## Resources

- [John The Ripper Official](https://www.openwall.com/john/)
- [Hashcat](https://hashcat.net/)
- [Wordlists](https://github.com/danielmiessler/SecLists)
- [Hash Formats](https://openwall.info/wiki/people/solar/passwd-hashes)

---

## Legal & Ethical

⚠️ **Important**

- Only crack hashes you have permission to crack
- Unauthorized access is illegal
- Use in authorized penetration tests only
- Respect system policies

---

## Changelog

- **v1.0** - Initial comprehensive cheat sheet
- **Last Updated** - June 2026
- **Status** - Production Ready
- **Format** - eJPT v2 Style Professional Documentation

---

© 2026 | John The Ripper Cheat Sheet | Educational Purpose
