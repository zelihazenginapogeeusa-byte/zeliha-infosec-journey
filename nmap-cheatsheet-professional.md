# 🔍 Nmap - The Network Mapper Complete Cheat Sheet

> **A Comprehensive Guide to Nmap for Network Reconnaissance and Vulnerability Assessment**

## Table of Contents

1. [Installation & Setup](#installation--setup)
2. [Nmap Basics](#nmap-basics)
3. [Host Discovery](#host-discovery)
4. [Port Scanning Techniques](#port-scanning-techniques)
5. [Service & OS Detection](#service--os-detection)
6. [Nmap Scripting Engine (NSE)](#nmap-scripting-engine-nse)
7. [Output Formats](#output-formats)
8. [Firewall & IDS Evasion](#firewall--ids-evasion)
9. [Performance Optimization](#performance-optimization)
10. [Advanced Techniques](#advanced-techniques)
11. [Practical Workflows](#practical-workflows)
12. [Troubleshooting](#troubleshooting)

---

## Installation & Setup

### Linux Installation (Debian/Ubuntu)

```bash
# Update package list
sudo apt-get update

# Install Nmap
sudo apt-get install nmap

# Verify installation
nmap --version

# Install development tools (for NSE development)
sudo apt-get install build-essential

# Install lua (for NSE scripts)
sudo apt-get install liblua5.1-dev
```

### Linux Installation (RedHat/CentOS)

```bash
# Install EPEL repository
sudo yum install epel-release

# Install Nmap
sudo yum install nmap

# Verify installation
nmap --version
```

### macOS Installation

```bash
# Using Homebrew (recommended)
brew install nmap

# Verify installation
nmap --version

# Update Nmap scripts
nmap --script-updatedb
```

### Windows Installation

```powershell
# Using Chocolatey
choco install nmap

# Or download installer
# https://nmap.org/download.html

# Verify installation
nmap --version
```

### Kali Linux

```bash
# Already installed on Kali
nmap --version

# Update scripts
sudo nmap --script-updatedb

# Install additional tools
sudo apt-get install zenmap
```

### Docker Installation

```bash
# Pull official image
docker pull instrumentisto/nmap

# Run scan in container
docker run --rm instrumentisto/nmap nmap -p 80,443 example.com
```

---

## Nmap Basics

### Basic Syntax

```bash
# Syntax
nmap [Scan Type] [Options] [Target]

# Simple scan
nmap 192.168.1.1
nmap example.com

# Scan range
nmap 192.168.1.1-254
nmap 192.168.1.0/24

# Multiple targets
nmap 192.168.1.1 192.168.1.2 192.168.1.3
nmap 192.168.1.1,2,3,4,5

# From file
nmap -iL targets.txt

# Target variables
nmap -iR 10                 # Random 10 hosts
nmap --exclude 192.168.1.1
nmap --exclude-file exclude.txt
```

### Help & Version

```bash
# Full help
nmap -h
nmap --help

# Man page
man nmap

# Version
nmap --version

# Example usage
nmap --example

# Interactive GUI (Zenmap)
zenmap
```

### Target Specification

```bash
# Single host
nmap 192.168.1.100
nmap example.com

# IP range (CIDR notation)
nmap 192.168.1.0/24
nmap 10.0.0.0/8

# IP range (dash notation)
nmap 192.168.1.1-254
nmap 192.168.1-3.1

# Multiple targets
nmap target1 target2 target3

# From file
nmap -iL targets.txt

# Random targets
nmap -iR 0              # Scan random internet hosts
nmap -iR 100            # Scan 100 random hosts

# Exclude targets
nmap 192.168.1.0/24 --exclude 192.168.1.1
nmap 192.168.1.0/24 --exclude-file exclude.txt
```

---

## Host Discovery

### Ping Scanning (Host Discovery)

```bash
# Simple ping
nmap -sn 192.168.1.0/24

# Ping scan with traceroute
nmap -sn --traceroute 192.168.1.0/24

# No ping (treat all as up)
nmap -Pn 192.168.1.0/24

# Ping types
nmap -PP 192.168.1.0/24         # ICMP timestamp
nmap -PM 192.168.1.0/24         # ICMP address mask
nmap -PU 192.168.1.0/24         # UDP ping
nmap -PA 192.168.1.0/24         # TCP ACK ping
nmap -PS 192.168.1.0/24         # TCP SYN ping
nmap -PE 192.168.1.0/24         # ICMP echo
```

### Advanced Host Discovery

```bash
# TCP SYN ping (port 80)
nmap -PS80 192.168.1.0/24

# TCP SYN ping (multiple ports)
nmap -PS22,80,443 192.168.1.0/24

# TCP ACK ping
nmap -PA80 192.168.1.0/24

# UDP ping
nmap -PU53 192.168.1.0/24

# ARP ping (local network)
nmap -PR 192.168.1.0/24

# ICMP echo
nmap -PE 192.168.1.0/24

# Reverse DNS lookup only
nmap -sL 192.168.1.0/24
```

---

## Port Scanning Techniques

### Scan Type Overview

| Scan Type | Syntax | Description | Privilege | Speed |
|-----------|--------|-------------|-----------|-------|
| TCP Connect | `-sT` | Full connection | User | Slow |
| SYN Stealth | `-sS` | Half-open | Root | Fast |
| UDP | `-sU` | UDP scan | Root | Very Slow |
| ACK | `-sA` | Firewall mapping | Root | Fast |
| NULL | `-sN` | No flags set | Root | Slow |
| FIN | `-sF` | FIN flag | Root | Slow |
| Xmas | `-sX` | FIN/PSH/URG | Root | Slow |
| Maimon | `-sM` | FIN/ACK | Root | Slow |

### TCP Scans

```bash
# SYN scan (stealth, fast) - DEFAULT
nmap -sS 192.168.1.100
nmap -sS -p 80,443 192.168.1.100

# TCP connect scan (no privilege needed)
nmap -sT 192.168.1.100
nmap -sT -p 1-1000 192.168.1.100

# ACK scan (firewall mapping)
nmap -sA 192.168.1.100
nmap -sA -p 1-65535 192.168.1.100

# Null scan (RFC compliance)
nmap -sN 192.168.1.100

# FIN scan
nmap -sF 192.168.1.100

# Xmas scan (FIN/PSH/URG)
nmap -sX 192.168.1.100

# Maimon scan (FIN/ACK)
nmap -sM 192.168.1.100
```

### UDP Scans

```bash
# UDP scan
nmap -sU 192.168.1.100

# UDP specific ports
nmap -sU -p 53,123,161 192.168.1.100

# Combined TCP and UDP
nmap -sS -sU 192.168.1.100

# UDP common ports
nmap -sU -p 53,67,68,69,123,161,162,389,514 192.168.1.100
```

### Port Specification

```bash
# All ports
nmap -p- 192.168.1.100
nmap -p 0-65535 192.168.1.100

# Specific ports
nmap -p 22,80,443 192.168.1.100
nmap -p 22,80-443 192.168.1.100

# Common ports
nmap -p 1-1000 192.168.1.100
nmap -p 1-10000 192.168.1.100

# Port by service
nmap -p http,https,ssh 192.168.1.100

# Exclude ports
nmap -p 1-65535 --exclude-ports 22,25,80 192.168.1.100

# Top ports
nmap --top-ports 100 192.168.1.100
nmap --top-ports 1000 192.168.1.100
```

---

## Service & OS Detection

### Service Version Detection

```bash
# Service version detection
nmap -sV 192.168.1.100

# Service version + intensity
nmap -sV --version-intensity 5 192.168.1.100
nmap -sV --version-intensity 9 192.168.1.100

# Combined with SYN scan
nmap -sS -sV 192.168.1.100

# All ports with version
nmap -p- -sV 192.168.1.100

# Service version + script detection
nmap -sV --script smb-enum-shares 192.168.1.100
```

### OS Detection

```bash
# OS detection
nmap -O 192.168.1.100

# Aggressive OS detection
nmap -O --osscan-guess 192.168.1.100

# OS detection with timing
nmap -O -T4 192.168.1.100

# Combined with version detection
nmap -O -sV 192.168.1.100

# Full aggressive scan
nmap -A 192.168.1.100
```

### Aggressive Scanning

```bash
# Aggressive scan (OS + Version + Scripts + Traceroute)
nmap -A 192.168.1.100

# Aggressive with specific ports
nmap -A -p 1-1000 192.168.1.100

# Very aggressive
nmap -A -T4 192.168.1.100

# Equivalent to -A
nmap -sV -O --script=default --traceroute 192.168.1.100
```

### Service Enumeration

```bash
# Service detection
nmap -sV --script service-nmap 192.168.1.100

# Kerberos enumeration
nmap -p 88 --script krb5-enum-users 192.168.1.100

# LDAP enumeration
nmap -p 389 --script ldap-search 192.168.1.100

# SMB enumeration
nmap -p 445 --script smb-enum-shares 192.168.1.100

# DNS enumeration
nmap -p 53 --script dns-brute 192.168.1.100

# SNMP enumeration
nmap -p 161 -sU --script snmp-enum 192.168.1.100
```

---

## Nmap Scripting Engine (NSE)

### Script Basics

```bash
# Run default scripts
nmap -sC 192.168.1.100
nmap --script=default 192.168.1.100

# Run all scripts
nmap --script=all 192.168.1.100

# Run specific script
nmap --script=http-enum 192.168.1.100

# Run multiple scripts
nmap --script=smb-enum-shares,smb-enum-users 192.168.1.100

# Run script category
nmap --script=vuln 192.168.1.100
nmap --script=exploit 192.168.1.100
```

### Script Categories

```bash
# Vulnerability scripts
nmap --script=vuln 192.168.1.100

# Exploitation scripts
nmap --script=exploit 192.168.1.100

# Discovery scripts
nmap --script=discovery 192.168.1.100

# Intrusion detection bypass
nmap --script=intrusive 192.168.1.100

# Safe scripts
nmap --script=safe 192.168.1.100

# Authentication scripts
nmap --script=auth 192.168.1.100

# Brute force scripts
nmap --script=brute 192.168.1.100

# Backdoor scripts
nmap --script=backdoor 192.168.1.100

# Malware scripts
nmap --script=malware 192.168.1.100
```

### Common Scripts

```bash
# HTTP enumeration
nmap -p 80 --script http-enum 192.168.1.100

# HTTP methods
nmap -p 80 --script http-methods 192.168.1.100

# HTTP title
nmap -p 80 --script http-title 192.168.1.100

# SMB shares
nmap -p 445 --script smb-enum-shares 192.168.1.100

# SMB users
nmap -p 445 --script smb-enum-users 192.168.1.100

# SMB vulnerabilities
nmap -p 445 --script smb-vuln-* 192.168.1.100

# SSH version
nmap -p 22 --script ssh-hostkey 192.168.1.100

# SSH brute force
nmap -p 22 --script ssh-brute 192.168.1.100

# FTP anonymous
nmap -p 21 --script ftp-anon 192.168.1.100

# DNS zone transfer
nmap -p 53 --script dns-zone-transfer 192.168.1.100

# SNMP enumeration
nmap -p 161 -sU --script snmp-sysdescr 192.168.1.100

# LDAP enumeration
nmap -p 389 --script ldap-search 192.168.1.100

# MySQL info
nmap -p 3306 --script mysql-info 192.168.1.100

# MSSQL info
nmap -p 1433 --script mssql-info 192.168.1.100

# Oracle SID
nmap -p 1521 --script oracle-sid-brute 192.168.1.100
```

### Script Arguments

```bash
# Pass script arguments
nmap --script smb-enum-shares --script-args smbusername=admin 192.168.1.100

# Multiple arguments
nmap --script ssh-brute --script-args userdb=users.txt,passdb=pass.txt 192.168.1.100

# Show script help
nmap --script-help http-enum

# List available scripts
ls -la /usr/share/nmap/scripts/

# Update script database
sudo nmap --script-updatedb
```

---

## Output Formats

### Screen Output

```bash
# Normal output
nmap 192.168.1.100

# Verbose output
nmap -v 192.168.1.100
nmap -vv 192.168.1.100

# Debug output
nmap -d 192.168.1.100
nmap -dd 192.168.1.100

# Quiet output
nmap -q 192.168.1.100

# No reverse DNS
nmap -n 192.168.1.100

# No ping
nmap -Pn 192.168.1.100
```

### File Output

```bash
# Normal output file
nmap -oN output.txt 192.168.1.100

# XML output file
nmap -oX output.xml 192.168.1.100

# Grepable output
nmap -oG output.grep 192.168.1.100

# All formats
nmap -oA output 192.168.1.100
# Creates: output.nmap, output.xml, output.gnmap

# Combined output
nmap -oN output.txt -oX output.xml 192.168.1.100

# Append to file
nmap -oN output.txt --append-output 192.168.1.100
```

### Output Parsing

```bash
# Grep open ports
grep "open" output.gnmap

# Extract IPs
grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" output.gnmap | sort -u

# Parse XML with xmllint
xmllint --xpath "//port[@protocol='tcp' and state[@state='open']]" output.xml

# Parse with Nmap::Scanner (Perl)
nmap -oX output.xml
# Parse with Perl XML parser
```

---

## Firewall & IDS Evasion

### Fragmentation

```bash
# Fragment packets
nmap -f 192.168.1.100

# Specify MTU (must be multiple of 8)
nmap --mtu 16 192.168.1.100
nmap --mtu 32 192.168.1.100
nmap --mtu 8 192.168.1.100

# Combined with decoy
nmap -f --decoy 192.168.1.50 192.168.1.100
```

### Decoy Scanning

```bash
# Use decoys
nmap -D 192.168.1.50,192.168.1.51,ME 192.168.1.100

# Multiple decoys
nmap -D 192.168.1.1,192.168.1.2,192.168.1.3,ME 192.168.1.100

# Random decoys
nmap -D RND:10,ME 192.168.1.100
nmap -D RND,RND,RND,ME 192.168.1.100

# Decoy with port
nmap -D 192.168.1.50,ME -p 80 192.168.1.100
```

### Source Port Spoofing

```bash
# Specify source port
nmap --source-port 53 192.168.1.100
nmap --source-port 88 192.168.1.100
nmap --source-port 389 192.168.1.100

# Common bypass ports
nmap --source-port 53 -p 80,443 192.168.1.100
```

### IP Spoofing

```bash
# Spoof source IP
nmap -S 192.168.1.50 192.168.1.100

# Decoy and spoof combined
nmap -S 192.168.1.50 -D 192.168.1.51,ME 192.168.1.100

# Note: Requires raw socket access
sudo nmap -S 192.168.1.50 192.168.1.100
```

### Timing Options

```bash
# Paranoid (slow)
nmap -T0 192.168.1.100

# Sneaky (very slow)
nmap -T1 192.168.1.100

# Polite (slow)
nmap -T2 192.168.1.100

# Normal (default)
nmap -T3 192.168.1.100

# Aggressive (fast)
nmap -T4 192.168.1.100

# Insane (very fast)
nmap -T5 192.168.1.100
```

### Proxy/Relay

```bash
# Use socks4 proxy
nmap --proxies socks4://127.0.0.1:9050 192.168.1.100

# Multiple proxies
nmap --proxies socks4://proxy1:9050,http://proxy2:3128 192.168.1.100
```

---

## Performance Optimization

### Timing & Performance

```bash
# Fast scan with timing
nmap -T4 192.168.1.100

# Aggressive scanning
nmap -T4 --min-rate 1000 192.168.1.100

# Set minimum packet rate
nmap --min-rate 100 192.168.1.100

# Set maximum packet rate
nmap --max-rate 10000 192.168.1.100

# Parallel host scan
nmap --min-hostgroup 256 192.168.1.0/24

# Set probes
nmap --min-parallelism 100 192.168.1.100
```

### Connection Options

```bash
# Timeout per host (milliseconds)
nmap --host-timeout 30m 192.168.1.0/24

# Initial timeout
nmap --initial-rtt-timeout 100ms 192.168.1.100

# Max retries
nmap --max-retries 2 192.168.1.100

# Max scan delay
nmap --max-scan-delay 100ms 192.168.1.100

# Min scan delay
nmap --min-scan-delay 10ms 192.168.1.100
```

### Large Scale Scanning

```bash
# Scan network efficiently
nmap -p 80,443 --top-ports 100 -T4 192.168.1.0/24

# Distributed scan
nmap -p 80,443 -sS -T4 --max-rate 10000 192.168.1.0/24

# Scan with rate limiting
nmap --min-rate 1000 --max-rate 5000 192.168.1.0/24
```

---

## Advanced Techniques

### Traceroute

```bash
# Enable traceroute
nmap --traceroute 192.168.1.100

# Traceroute with detailed info
nmap -A --traceroute 192.168.1.100

# Traceroute only
nmap --traceroute -Pn 192.168.1.0/24
```

### Idle/Zombie Scan

```bash
# Idle scan (requires zombie host)
nmap -sI <zombie_ip> 192.168.1.100

# Example with specific zombie
nmap -sI 192.168.1.50:139 -p 80,443 192.168.1.100
```

### NSE Script Development

```bash
# Load custom script
nmap --script=/path/to/custom-script.nse 192.168.1.100

# Script location
/usr/share/nmap/scripts/

# Create custom script
cat > custom-script.nse << 'EOF'
description = "Custom Script"
categories = {"discovery"}
portrule = function(host, port)
  return port.number == 80 and port.state == "open"
end
action = function(host, port)
  return "Custom output"
end
EOF

# Update script database
sudo nmap --script-updatedb
```

### Version Detection Advanced

```bash
# Light version detection
nmap -sV --version-light 192.168.1.100

# Intensity 9 (slowest)
nmap -sV --version-intensity 9 192.168.1.100

# Rarity 5 (comprehensive)
nmap -sV --version-all 192.168.1.100
```

### Data Length

```bash
# Append random data
nmap --data-length 1000 192.168.1.100

# Append hex data
nmap --data-string "GET / HTTP/1.0\r\n\r\n" 192.168.1.100

# Raw hex data
nmap --data 0x0123 192.168.1.100
```

---

## Practical Workflows

### Quick Network Assessment

```bash
# 1. Network discovery
nmap -sn 192.168.1.0/24

# 2. Quick port scan
nmap -p- -T4 192.168.1.100

# 3. Service detection
nmap -sV -p- 192.168.1.100

# 4. OS detection
nmap -O -sV 192.168.1.100

# 5. Vulnerability scan
nmap --script=vuln -p- 192.168.1.100

# 6. All in one
nmap -A -p- -T4 --script=vuln 192.168.1.100
```

### Penetration Testing Workflow

```bash
# 1. Host discovery
nmap -sn -oG hosts.gnmap 192.168.1.0/24

# 2. Extract live hosts
grep "Status: Up" hosts.gnmap | cut -d' ' -f2 > live_hosts.txt

# 3. Full scan on live hosts
nmap -iL live_hosts.txt -p- -sV -O -A -oA full_scan

# 4. Vulnerability assessment
nmap -iL live_hosts.txt --script=vuln -oX vulns.xml

# 5. Parse results
grep -E "open|filtered" full_scan.gnmap
```

### Web Application Scanning

```bash
# Identify web servers
nmap -p 80,443,8080,8443 -sV 192.168.1.0/24

# Enumerate HTTP
nmap -p 80 --script http-enum 192.168.1.100

# Get HTTP headers
nmap -p 80 --script http-headers 192.168.1.100

# SSL certificate info
nmap -p 443 --script ssl-cert 192.168.1.100

# All HTTP scripts
nmap -p 80,443 --script http-* 192.168.1.100
```

### Database Scanning

```bash
# MySQL detection
nmap -p 3306 -sV 192.168.1.100

# MSSQL detection
nmap -p 1433 -sV 192.168.1.100

# PostgreSQL detection
nmap -p 5432 -sV 192.168.1.100

# Oracle detection
nmap -p 1521 -sV 192.168.1.100

# Enumerate all databases
nmap -p 3306,1433,5432,1521 --script=*-info 192.168.1.0/24
```

### Windows Enumeration

```bash
# SMB enumeration
nmap -p 445 --script smb-enum-* 192.168.1.100

# All SMB scripts
nmap -p 445 --script smb-* 192.168.1.100

# Get NetBIOS names
nmap -p 137 -sU --script=nbstat 192.168.1.100

# WinRM enumeration
nmap -p 5985,5986 -sV 192.168.1.100

# RDP enumeration
nmap -p 3389 --script rdp-* 192.168.1.100
```

### Linux Enumeration

```bash
# SSH enumeration
nmap -p 22 --script ssh-* 192.168.1.100

# Get SSH key
nmap -p 22 --script ssh-hostkey 192.168.1.100

# X11 detection
nmap -p 6000 192.168.1.100

# Mail enumeration
nmap -p 25,110,143,587,993 -sV 192.168.1.100

# LDAP enumeration
nmap -p 389 --script ldap-* 192.168.1.100
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "No route to host" | Check network connectivity, firewall rules |
| "Refused/Filtered ports" | Host may have firewall, try -Pn |
| "No results" | Increase timeout: `--host-timeout 30m` |
| "Slow scans" | Use aggressive timing: `-T5` or `--max-rate` |
| "Permission denied" | Some scans need root: `sudo nmap` |
| "Script errors" | Update scripts: `sudo nmap --script-updatedb` |

### Debug Mode

```bash
# Enable debugging
nmap -d 192.168.1.100

# Very verbose debugging
nmap -dd 192.168.1.100

# Save debug output
nmap -d 192.168.1.100 -oN debug.txt

# Packet capture with tcpdump
sudo tcpdump -i eth0 -w capture.pcap host 192.168.1.100
# Then analyze with Wireshark
```

### Network Issues

```bash
# Test network connectivity
ping 192.168.1.100

# Test with no ping
nmap -Pn 192.168.1.100

# Increase timeouts
nmap --initial-rtt-timeout 1000ms --max-retries 5 192.168.1.100

# Check routing
traceroute 192.168.1.100

# Verbose network info
nmap -n -v 192.168.1.100
```

---

## Quick Reference Card

### Most Used Commands

```bash
# Ping sweep
nmap -sn 192.168.1.0/24

# Quick scan
nmap -p- -T4 192.168.1.100

# Service detection
nmap -sV 192.168.1.100

# Full scan
nmap -A 192.168.1.100

# Vulnerability scan
nmap --script=vuln 192.168.1.100

# OS detection
nmap -O 192.168.1.100

# SMB enumeration
nmap -p 445 --script smb-* 192.168.1.100

# HTTP enumeration
nmap -p 80 --script http-* 192.168.1.100
```

### Command Cheat Sheet

```
┌───────────────────────────────────────────────────┐
│ NMAP QUICK REFERENCE                              │
├───────────────────────────────────────────────────┤
│ PING:     nmap -sn <target>                       │
│ SYN:      nmap -sS <target>                       │
│ CONNECT:  nmap -sT <target>                       │
│ VERSION:  nmap -sV <target>                       │
│ OS:       nmap -O <target>                        │
│ FULL:     nmap -A <target>                        │
│ SCRIPTS:  nmap --script=vuln <target>             │
│ OUTPUT:   nmap -oA output <target>                │
│ TIMING:   nmap -T4 <target>                       │
│ EVASION:  nmap -f -D RND:10,ME <target>          │
└───────────────────────────────────────────────────┘
```

---

## Common Scans by Purpose

### Reconnaissance

```bash
# Light reconnaissance
nmap -sn -T4 192.168.1.0/24

# Heavy reconnaissance
nmap -sV -O -A -T4 192.168.1.0/24
```

### Vulnerability Assessment

```bash
# Quick vuln check
nmap --script=vuln 192.168.1.100

# Comprehensive vuln scan
nmap -p- -sV --script=vuln,exploit 192.168.1.100
```

### Firewall Mapping

```bash
# ACK scan
nmap -sA 192.168.1.100

# Detect firewall
nmap -sA -p 1-65535 192.168.1.100
```

### Evasion

```bash
# Stealth scan
nmap -sS -T1 -f --data-length 1000 -D RND:10,ME 192.168.1.100

# Decoy scan
nmap -D 192.168.1.50,192.168.1.51,ME 192.168.1.100
```

---

## Nmap + Scripting

### Bash Script Example

```bash
#!/bin/bash
# Scan hosts from file

while IFS= read -r host; do
  echo "Scanning $host..."
  nmap -sV -O -p- "$host" -oN "${host}.nmap"
done < targets.txt
```

### One-liners

```bash
# Get all open ports
nmap -p- --min-rate 1000 192.168.1.100 | grep "open"

# Save IPs of live hosts
nmap -sn -T4 192.168.1.0/24 | grep "Nmap scan" | awk '{print $5}'

# Parallel scanning
for i in {1..254}; do nmap -p 80 -T4 192.168.1.$i & done

# Extract open ports
nmap -p- 192.168.1.100 -oG - | grep "Ports:" | cut -d' ' -f2 | tr ',' '\n'
```

---

## Resources

### Official Documentation

- [Nmap Official Website](https://nmap.org/)
- [Nmap Manual](https://nmap.org/book/man.html)
- [NSE Scripts](https://nmap.org/nsedoc/)

### Learning Resources

- [Nmap Network Scanning](https://nmap.org/book/)
- [HackTheBox](https://www.hackthebox.com/)
- [TryHackMe](https://tryhackme.com/)

### Related Tools

- Zenmap (GUI)
- Wireshark (Packet analysis)
- Metasploit (Exploitation)
- Nessus (Vulnerability scanner)

---

## Tips & Best Practices

✅ **Do's**

- Start with ping sweep to identify hosts
- Use appropriate timing levels (-T3 is default)
- Save results in multiple formats
- Use scripts cautiously on production systems
- Update NSE scripts regularly: `sudo nmap --script-updatedb`

❌ **Don'ts**

- Don't scan without permission
- Don't use aggressive scans on unstable networks
- Don't rely only on Nmap results
- Don't ignore false positives/negatives
- Don't run insane timing (-T5) on slow networks

---

## Changelog

- **v1.0** - Initial comprehensive cheat sheet
- **Last Updated** - June 2026
- **Status** - Production Ready
- **Format** - eJPT v2 Style Professional Documentation

---

**Created for penetration testers, network administrators, and security professionals.**

**Scan responsibly. Verify thoroughly. Document findings.**

---

© 2026 | Nmap Cheat Sheet | Educational Purpose
