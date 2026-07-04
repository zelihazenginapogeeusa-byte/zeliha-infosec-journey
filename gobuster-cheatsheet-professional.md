# 🔓 Gobuster - Directory & Subdomain Scanning Complete Cheat Sheet

## Installation

```bash
sudo apt-get install gobuster
# Or go get github.com/OJ/gobuster/v3@latest
```

## Directory Scanning

```bash
# Basic directory scan
gobuster dir -u http://192.168.1.100 -w wordlist.txt

# Common wordlist
gobuster dir -u http://192.168.1.100 -w /usr/share/wordlists/dirb/common.txt

# Extensions
gobuster dir -u http://192.168.1.100 -w wordlist.txt -x php,html,txt

# Status codes to show
gobuster dir -u http://192.168.1.100 -w wordlist.txt -s 200,301,302

# Threads
gobuster dir -u http://192.168.1.100 -w wordlist.txt -t 50

# Recursive
gobuster dir -u http://192.168.1.100 -w wordlist.txt -r

# Output
gobuster dir -u http://192.168.1.100 -w wordlist.txt -o output.txt

# Verbose
gobuster dir -u http://192.168.1.100 -w wordlist.txt -v
```

## Subdomain Scanning

```bash
# Basic subdomain scan
gobuster dns -d example.com -w wordlist.txt

# Large wordlist
gobuster dns -d example.com -w /usr/share/wordlists/seclists/subdomains.txt

# Show IPs
gobuster dns -d example.com -w wordlist.txt -i

# Threads
gobuster dns -d example.com -w wordlist.txt -t 100

# Resolver
gobuster dns -d example.com -w wordlist.txt -r 8.8.8.8

# Output
gobuster dns -d example.com -w wordlist.txt -o subdomains.txt
```

## Virtual Host Scanning

```bash
# VHost scanning
gobuster vhost -u http://192.168.1.100 -w wordlist.txt

# With custom User-Agent
gobuster vhost -u http://192.168.1.100 -w wordlist.txt -a "Mozilla/5.0"

# Specific status code
gobuster vhost -u http://192.168.1.100 -w wordlist.txt -s 200
```

## Advanced Options

```bash
# Custom headers
gobuster dir -u http://192.168.1.100 -w wordlist.txt -H "User-Agent: Custom" -H "Cookie: admin=1"

# Proxy
gobuster dir -u http://192.168.1.100 -w wordlist.txt -p http://127.0.0.1:8080

# Basic auth
gobuster dir -u http://192.168.1.100 -w wordlist.txt -U admin -P password

# Timeout
gobuster dir -u http://192.168.1.100 -w wordlist.txt --timeout 10s

# Follow redirects
gobuster dir -u http://192.168.1.100 -w wordlist.txt -r

# No status
gobuster dir -u http://192.168.1.100 -w wordlist.txt -n
```

## Quick Commands

```bash
# Directory with common extensions
gobuster dir -u http://target.com -w /usr/share/wordlists/dirb/common.txt -x php,html,txt

# Subdomain scan
gobuster dns -d target.com -w subdomains.txt -t 50

# VHost enumeration
gobuster vhost -u http://target.com -w wordlist.txt

# Output to file
gobuster dir -u http://target.com -w wordlist.txt -o found.txt
```

---

© 2026 | Gobuster Cheat Sheet | Educational Purpose
