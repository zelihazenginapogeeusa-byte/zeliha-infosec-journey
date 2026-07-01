# Wireshark Advanced Cheat Sheet

A comprehensive reference guide for network analysis and traffic investigation using Wireshark. Designed for SOC analysts, Blue Team Level 1, and penetration testers.

## Table of Contents

1. [Display Filters Basics](#display-filters-basics)
2. [Suspicious Traffic Detection](#suspicious-traffic-detection)
3. [Beaconing Detection](#beaconing-detection)
4. [DNS Exfiltration](#dns-exfiltration)
5. [HTTP Hunting](#http-hunting)
6. [TLS/SSL Analysis](#tlsssl-analysis)
7. [File Download Detection](#file-download-detection)
8. [Lateral Movement Detection](#lateral-movement-detection)
9. [Credential Hunting](#credential-hunting)
10. [Noise Reduction](#noise-reduction)
11. [Golden Combo Filters](#golden-combo-filters)
12. [Protocol Analysis](#protocol-analysis)
13. [Quick Tips](#quick-tips)

---

## Display Filters Basics

### Filter Operators

| Operator | Meaning | Example |
|----------|---------|---------|
| `==` | Equal | `ip.addr == 192.168.1.1` |
| `!=` | Not Equal | `ip.addr != 192.168.1.1` |
| `>` | Greater Than | `tcp.len > 100` |
| `<` | Less Than | `tcp.len < 50` |
| `>=` | Greater or Equal | `frame.len >= 200` |
| `<=` | Less or Equal | `tcp.window_size <= 1024` |
| `&&` | AND | `ip.src == 10.0.0.1 && tcp.port == 80` |
| `\|\|` | OR | `tcp.port == 80 \|\| tcp.port == 443` |
| `!` | NOT | `!dns` |
| `contains` | Contains Text | `http contains "password"` |
| `matches` | Regex | `dns.qry.name matches "\.exe"` |
| `in` | In Range | `tcp.port in (80, 443, 8080)` |

### Basic Filters

| Filter | Purpose |
|--------|---------|
| `ip.addr == 192.168.1.1` | Show traffic from/to specific IP |
| `tcp.port == 80` | Show HTTP traffic |
| `udp.port == 53` | Show DNS traffic |
| `tcp.port in (80, 443)` | Show traffic on multiple ports |
| `ip.src == 10.0.0.0/24` | Show traffic from subnet |
| `tcp.flags.syn == 1` | Show SYN packets |
| `tcp.flags.fin == 1` | Show FIN packets |
| `tcp.flags.reset == 1` | Show RESET packets |

---

## Suspicious Traffic Detection

### SYN Scans

```
tcp.flags.syn == 1 && !(tcp.flags.ack == 1)
```

**What it detects:**
- SYN packets without ACK flag
- Indicates port scanning activity
- Common in network reconnaissance

**Usage:**
- Identify network scanners
- Detect unauthorized reconnaissance
- Monitor for active scanning

---

### TCP Resets

```
tcp.flags.reset == 1
```

**What it detects:**
- TCP RST (Reset) packets
- Indicates connection termination
- May indicate blocking or firewall activity

**Usage:**
- Monitor for blocked connections
- Detect firewall interference
- Identify connection problems

---

### Retransmissions

```
tcp.analysis.retransmission
```

**What it detects:**
- Duplicate TCP segments
- Network instability or congestion
- Possible packet loss

**Usage:**
- Diagnose network issues
- Identify unstable connections
- Monitor packet loss

**Alternative:**
```
tcp.analysis.fast_retransmission
tcp.analysis.duplicate_ack
```

---

## Beaconing Detection

### Regular Interval Traffic

```
frame.time_delta > 5 && ip.addr == 10.10.10.5
```

**What it detects:**
- Traffic at regular intervals
- Possible C2 (Command & Control) beaconing
- Malware check-in activity

**Configuration:**
- `frame.time_delta > 5` - Packets sent more than 5 seconds apart
- Adjust the threshold based on normal traffic patterns
- Look for consistent intervals

---

### TCP Beaconing

```
tcp.time_delta > 5
```

**What it detects:**
- Regular TCP connections at set intervals
- C2 beacon activity
- Botnet check-ins

**Usage:**
```
tcp.time_delta > 10 && tcp.dstport == 443
```
- Monitor for HTTPS C2 communication
- Detect encrypted beaconing

---

### Combine with Port Analysis

```
ip.dst == 203.0.113.10 && tcp.dstport == 8080
```

**What it shows:**
- Outbound connections to suspicious port
- Consistent beacon pattern
- Potential C2 communication

---

## DNS Exfiltration

### Long Domain Names

```
dns && strlen(dns.qry.name) > 50
```

**What it detects:**
- DNS queries with unusually long domain names
- Data encoding in domain names
- DNS tunnel traffic

**Variations:**
```
dns.qry.name contains "xxxxxxxxxxxx"
```

---

### Base64 Encoded DNS

```
dns.qry.name contains "=="
```

**What it detects:**
- Base64 encoded data in DNS queries
- Common exfiltration method
- Data encoded as domain names

**Other encodings:**
```
dns.qry.name contains "%"  // URL encoding
dns.qry.name matches "[A-Z0-9]{20,}"  // Long random strings
```

---

### Suspicious DNS Queries

```
dns && !(dns.qry.name contains ".com" || dns.qry.name contains ".org" || dns.qry.name contains ".net")
```

**What it detects:**
- Unusual TLDs
- Suspicious domain structures
- Potential data exfiltration

---

### DNS Tunneling Detection

```
dns && dns.flags.response == 0
```

**What it detects:**
- DNS queries (not responses)
- Potential DNS tunneling
- Unusual DNS traffic patterns

---

## HTTP Hunting

### POST Requests

```
http.request.method == "POST"
```

**What it detects:**
- POST requests (often carry data/commands)
- Possible credential submission
- Command upload activity

**Combined:**
```
http.request.method == "POST" && http.request.uri contains "upload"
```

---

### Credential Detection

```
http contains "password"
http contains "username"
http contains "auth"
http contains "login"
```

**What it detects:**
- Plaintext credentials in HTTP traffic
- Login attempts
- Authentication requests

**More specific:**
```
http.response contains "password="
http.request.full_uri contains "password"
```

---

### Suspicious User Agents

```
http.user_agent contains "curl"
http.user_agent contains "wget"
http.user_agent contains "python"
http.user_agent contains "powershell"
http.user_agent contains "sqlmap"
```

**What it detects:**
- Automation tools
- Command-line clients
- Penetration testing tools
- Non-browser requests

---

### File Uploads

```
http.request.method == "POST" && http.content_type contains "multipart"
```

**What it detects:**
- File upload requests
- Potential malware upload
- Data exfiltration

---

### Suspicious HTTP Status Codes

```
http.response.code == 404
http.response.code == 500
http.response.code == 403
```

**What each indicates:**
- `404` - Not Found (may indicate probing)
- `500` - Server Error (possible exploitation)
- `403` - Forbidden (access attempts)

---

### GET Parameters

```
http.request.uri contains "="
http.request.uri contains "cmd="
http.request.uri contains "exec="
```

**What it detects:**
- URL parameters (possible command injection)
- Command execution attempts
- SQL injection attempts

---

## TLS/SSL Analysis

### Client Hello (Handshake)

```
tls.handshake.type == 1
```

**What it detects:**
- TLS handshake initiation
- Client certificate requests
- Protocol negotiation

---

### TLS Version Check

```
tls.record.version == 0x0301
tls.record.version == 0x0302
tls.record.version == 0x0303
```

**TLS Versions:**
- `0x0301` - TLS 1.0 (deprecated)
- `0x0302` - TLS 1.1 (deprecated)
- `0x0303` - TLS 1.2 (current standard)
- `0x0304` - TLS 1.3 (modern)

**Detect outdated TLS:**
```
tls.record.version < 0x0303
```

---

### Self-Signed Certificates

```
ssl.handshake.certificate
```

**Analyze:**
- Check certificate validity
- Look for self-signed certs
- Monitor for suspicious CAs

---

### Certificate Issuer Analysis

```
x509sat.commonName contains "localhost"
x509sat.commonName contains "test"
```

**What it detects:**
- Self-signed or test certificates
- Potentially malicious certificates
- Internal communication

---

## File Download Detection

### EXE Downloads

```
http.response.code == 200 && tcp contains ".exe"
```

**What it detects:**
- Successful executable downloads
- Malware downloads
- Suspicious file transfers

---

### Generic File Download Detection

```
http.content_type contains "application"
http.content_type contains "application/octet-stream"
http.content_type contains "application/x-msdownload"
```

**Common malicious MIME types:**
- `application/octet-stream` - Binary file
- `application/x-msdownload` - Windows executable
- `application/x-sh` - Shell script
- `application/java-archive` - JAR file

---

### File Transfer Protocols

```
ftp && ftp.request.command == "STOR"
ftp && ftp.request.command == "RETR"
```

**What it detects:**
- FTP uploads (STOR)
- FTP downloads (RETR)
- Unencrypted file transfer

---

### Large Files

```
http && tcp.len > 1000000
```

**What it detects:**
- Large file transfers
- Potential data exfiltration
- Unusual data movements

---

## Lateral Movement Detection

### SMB Traffic (Port 445)

```
ip.src == 10.0.0.0/24 && ip.dst == 10.0.0.0/24 && tcp.port == 445
```

**What it detects:**
- SMB traffic within network
- Lateral movement attempts
- Share access

**Extended:**
```
smb && !(ip.src == 192.168.1.0/24 && ip.dst == 192.168.1.0/24)
```

---

### RDP Traffic (Port 3389)

```
tcp.dstport == 3389
```

**What it detects:**
- Remote Desktop Protocol connections
- Lateral movement
- Interactive remote access

**With source restriction:**
```
tcp.dstport == 3389 && !(ip.src == 192.168.1.0/24)
```

---

### WinRM Traffic (Port 5985/5986)

```
tcp.port == 5985 || tcp.port == 5986
```

**What it detects:**
- Windows Remote Management
- PowerShell remoting
- Remote command execution

---

### SMB Named Pipes

```
smb.pipe contains "\\pipe\\"
```

**Common pipes:**
- `\pipe\svcctl` - Service control
- `\pipe\lsarpc` - Local Security Authority
- `\pipe\winreg` - Registry access

---

## Credential Hunting

### FTP Credentials

```
ftp.request.command == "USER"
ftp.request.command == "PASS"
```

**What it shows:**
- FTP login attempts
- Plaintext credentials
- Unencrypted authentication

**Combined:**
```
ftp && (ftp.request.command == "USER" || ftp.request.command == "PASS")
```

---

### HTTP Basic Auth

```
http.authorization
http contains "Authorization: Basic"
```

**What it detects:**
- HTTP Basic Authentication
- Base64 encoded credentials
- Login attempts

---

### Telnet Credentials

```
telnet
```

**What it detects:**
- Telnet protocol (all plaintext)
- Login credentials visible
- Passwords in clear text

---

### LDAP Credentials

```
ldap && ldap.bindRequest
```

**What it detects:**
- LDAP bind requests
- Authentication attempts
- Directory service access

---

### SMTP Credentials

```
smtp && smtp.request.command == "AUTH"
```

**What it detects:**
- SMTP authentication
- Email server access
- Credential submission

---

## Noise Reduction

### Exclude Common Protocols

```
!(arp or dns or icmp)
```

**What it does:**
- Removes ARP requests
- Removes DNS queries
- Removes ICMP packets
- Focuses on suspicious traffic

---

### Exclude Common Ports

```
tcp.port != 443 && tcp.port != 80
```

**What it does:**
- Removes HTTPS traffic
- Removes HTTP traffic
- Shows non-standard ports

**Exclude multiple:**
```
!(tcp.port in (80, 443, 22, 3306))
```

---

### Exclude Broadcast/Multicast

```
!frame.is_multicast && !frame.is_broadcast
```

**What it does:**
- Removes multicast traffic
- Removes broadcast traffic
- Shows unicast only

---

### Exclude Local Traffic

```
!(ip.src == 192.168.1.0/24 && ip.dst == 192.168.1.0/24)
```

**What it does:**
- Removes internal network traffic
- Shows external connections
- Highlights outbound suspicious traffic

---

## Golden Combo Filters

### Filter 1: Single IP Analysis

```
ip.addr == 10.10.10.5 && http
```

**Use case:**
- Analyze specific host's HTTP traffic
- Investigate compromised system
- Monitor suspicious activity

---

### Filter 2: DNS Filtering

```
dns && !(icmp)
```

**Use case:**
- Focus on DNS queries
- Remove ICMP noise
- Quick DNS analysis

---

### Filter 3: SYN Scan Detection

```
tcp.flags.syn == 1 && !(tcp.flags.ack == 1)
```

**Use case:**
- Detect port scans
- Identify reconnaissance
- Monitor network probing

---

### Filter 4: 404 Errors

```
http.response.code == 404
```

**Use case:**
- Find directory scanning
- Detect fuzzing attempts
- Identify web reconnaissance

---

### Filter 5: Exfiltration Detection

```
(tcp.dstport > 1024 && tcp.dstport < 65535) && tcp.len > 10000
```

**Use case:**
- Find data exfiltration
- Monitor large data transfers
- Detect suspicious uploads

---

### Filter 6: SSL/TLS Warnings

```
ssl.alert_message.type == 21
```

**What it detects:**
- SSL/TLS alerts
- Certificate errors
- Handshake failures

---

### Filter 7: Suspicious Outbound

```
ip.dst != 192.168.0.0/16 && tcp.dstport > 1024
```

**Use case:**
- Monitor external connections
- Detect C2 communication
- Find unauthorized outbound traffic

---

## Protocol Analysis

### FTP Analysis

```
ftp
ftp.request.command == "RETR"
ftp.request.command == "STOR"
ftp.request.arg contains "password"
```

**FTP Commands:**
- `USER` - Username
- `PASS` - Password
- `RETR` - Download
- `STOR` - Upload
- `LIST` - Directory listing

---

### SMTP Analysis

```
smtp
smtp.request.command == "AUTH"
smtp.request.command == "MAIL"
smtp.data contains "Subject"
```

**Common SMTP Commands:**
- `AUTH` - Authenticate
- `MAIL` - Sender
- `RCPT` - Recipient
- `DATA` - Email content

---

### SSH Analysis

```
ssh
ssh.protocol
ssh.payload
```

**What to look for:**
- SSH version
- Brute force attempts
- Key exchange methods
- Encryption algorithms

---

### DNS Analysis

```
dns
dns.flags.response == 0  // Queries
dns.flags.response == 1  // Responses
dns.resp.type == 1  // A records
dns.resp.type == 5  // CNAME records
```

**DNS Record Types:**
- `1` - A record (IPv4)
- `28` - AAAA record (IPv6)
- `5` - CNAME
- `15` - MX record
- `16` - TXT record

---

### ICMP Analysis

```
icmp
icmp.type == 8  // Echo request (ping)
icmp.type == 0  // Echo reply
icmp.type == 3  // Destination unreachable
```

**ICMP Types:**
- `0` - Echo Reply
- `3` - Destination Unreachable
- `8` - Echo Request
- `11` - Time Exceeded
- `30` - Traceroute

---

## Quick Tips

### Tip 1: Coloring Rules

Create custom color rules for:
- Malicious IPs
- Suspicious protocols
- Potential threats
- Network anomalies

**Analyze → Colorize Packet List**

---

### Tip 2: Follow Streams

Right-click packet → Follow → TCP/UDP/HTTP Stream
- See complete conversation
- Analyze request/response pairs
- Export application data

---

### Tip 3: Export Objects

File → Export Objects → HTTP/SMB/FTP
- Extract files from traffic
- Recover transferred documents
- Analyze malware samples

---

### Tip 4: Statistics

Statistics menu:
- Conversations
- Endpoints
- Protocol Hierarchy
- Packet Lengths
- I/O Graphs

---

### Tip 5: Time Analysis

```
frame.time_delta > 1
frame.time_relative
tcp.analysis.ack_rtt
```

- Analyze timing patterns
- Detect beaconing
- Calculate latency

---

### Tip 6: Packet Size Analysis

```
frame.len > 1500
tcp.len > 10000
```

- Detect fragmentation
- Find large transfers
- Identify exfiltration

---

### Tip 7: Save Custom Filters

Manage Filters → Save As Profile
- Save frequently used filters
- Reuse in investigations
- Share with team

---

### Tip 8: Use Bookmarks

Packet Details → Bookmark Packet
- Mark suspicious packets
- Review later
- Navigate quickly

---

## Advanced Techniques

### Combining Multiple Conditions

```
(http.request.method == "POST" || http.request.method == "GET") && 
http contains "password" && 
!(ip.src == 192.168.1.5)
```

### Nested Filters

```
(tcp.dstport == 80 || tcp.dstport == 8080) && 
tcp.len > 100 && 
http.request.uri contains "admin"
```

### Regex Patterns

```
dns.qry.name matches "[a-z]{20,}\\.com"
http.host matches ".*\\.pw$"
```

---

## Common Investigation Workflows

### 1. Identify Compromised Host

```
1. Filter for outbound connections to suspicious IPs
2. Look for beaconing patterns
3. Check for file transfers
4. Analyze HTTP requests
5. Export suspicious files
```

### 2. Find Data Exfiltration

```
1. Filter for large data transfers
2. Check DNS tunneling
3. Monitor encrypted tunnels
4. Analyze uncommon ports
5. Review authentication failures
```

### 3. Detect Lateral Movement

```
1. Filter SMB/RDP traffic
2. Check internal communications
3. Identify unusual port access
4. Monitor share access
5. Review error codes
```

### 4. Hunt for Malware C2

```
1. Look for beaconing patterns
2. Check DNS queries
3. Analyze HTTPS traffic
4. Monitor outbound connections
5. Check failed DNS lookups
```

---

## Important Notes

⚠️ **Legal Warning**: Network analysis should only be performed on networks you own or have explicit written permission to analyze. Unauthorized network monitoring is illegal.

✅ **Best Practices**:
- Always capture traffic properly
- Document your findings
- Use appropriate filters
- Maintain chain of custody
- Report suspicious activity
- Keep analysis confidential
- Follow incident response procedures

---

## Resources

- [Wireshark Official Documentation](https://www.wireshark.org/docs/)
- [Wireshark Display Filter Reference](https://www.wireshark.org/docs/dfref/)
- [Wireshark User Guide](https://www.wireshark.org/download/docs/)
- [Wireshark Wiki](https://wiki.wireshark.org/)
- [TryHackMe Wireshark Room](https://tryhackme.com/)
- [Blue Team Level 1 Resources](https://www.securityblue.team/)

---

**Last Updated**: 2024  
**Status**: Active  
**Designed For**: SOC Analysts, Blue Team Level 1, Security Professionals  
**Contributions**: Welcome

