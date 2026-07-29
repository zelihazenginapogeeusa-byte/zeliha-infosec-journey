# Exploitation Techniques Cheat Sheet

This document covers the **manual exploitation workflow** used in eJPT's host/network pentest module when there is no ready-made Metasploit module (or when using one would be overkill): finding public exploits with `searchsploit`, reading and adapting someone else's exploit code safely, compiling it, and manually confirming a vulnerability with `curl`/`nc` before running any tooling at all. For the framework-driven path use `metasploit-cheatsheet-professional.md`, and remember that everything here depends on accurate service/version data gathered per `nmap-cheatsheet-professional.md`.

---

## Table of Contents

1. [Finding Exploits with searchsploit](#1-finding-exploits-with-searchsploit)
2. [Reading & Vetting a Public Exploit](#2-reading--vetting-a-public-exploit)
3. [Compiling Exploit Code](#3-compiling-exploit-code)
4. [Manual Vulnerability Confirmation](#4-manual-vulnerability-confirmation)
5. [Exploit Reliability Triage](#5-exploit-reliability-triage)
6. [Decision Flow: Metasploit vs Manual vs Custom](#6-decision-flow-metasploit-vs-manual-vs-custom)
7. [Practical eJPT Workflow](#7-practical-ejpt-workflow)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. Finding Exploits with searchsploit

`searchsploit` is the offline command-line interface to the Exploit-DB archive, letting you match an identified service and version to a known exploit without touching the internet.

```bash
searchsploit apache 2.4.49            # Search by product + version string
searchsploit -t "openssh 7.2"         # Restrict search to the title field only
searchsploit --colour vsftpd 2.3.4    # Highlight matched terms in output

searchsploit -w apache 2.4.49         # Show the Exploit-DB web URL instead of local path
searchsploit -j apache 2.4.49         # JSON output (useful for scripting/parsing)

searchsploit -m 50383                 # Copy (mirror) an exploit by EDB-ID into ./ locally
searchsploit -m php/webapps/50383.py  # Copy by path instead of ID

searchsploit -x 50383                 # Examine an exploit's source without copying it
searchsploit -p 50383                 # Show full path + associated CVE/OSVDB references

searchsploit -u                       # Update the local Exploit-DB database (do this often)
```

> **Note:** `searchsploit` matches on the exploit title, which is often noisy. Trim the search terms down to product + major version (`apache 2.4.49` rather than a full banner string) and cross-check candidate hits with `-x` before committing to one.

---

## 2. Reading & Vetting a Public Exploit

Never run someone else's exploit code blind — a few minutes reading the script before execution prevents wasted time, false negatives, and unwanted damage to the target.

| Check | Why it matters |
|---|---|
| Target OS/distro and exact version in header comments | Many exploits are tied to one specific build (offsets, paths, patch level) and silently fail or crash the service on a mismatch |
| Hardcoded offsets/addresses/return addresses | Common in binary exploits (buffer overflows) — usually only valid for one specific OS build/patch/architecture |
| Hardcoded IPs, ports, file paths, or usernames | Must be edited to match the actual lab/target environment before running |
| Required libraries/interpreter version (Python 2 vs 3, Perl, Ruby) | Script may need porting or a specific interpreter installed to even parse |
| Whether it needs compiling | C/C++ source needs `gcc`/`cc`; check for a `Makefile` or compile comment in the header |
| Exploit type (RCE, DoS, PoC-only, local privesc) | A "PoC" often just proves a crash — it may not grant code execution at all |
| Read the full source, not just the top comment block | Payload/shellcode embedded further down can reveal intent, staging behavior, or clearly malicious extras |

```bash
searchsploit -x 50383                 # Read the exploit inline before deciding to copy/run it
file exploit_downloaded                # Confirm what you actually pulled down
head -n 40 exploit.py                  # Skim header comments for target/version notes
```

> **Note:** Treat every public exploit as untrusted code until reviewed — it is running with your privileges against your target. Run it inside an isolated VM/lab snapshot when the source or the author is unfamiliar.

---

## 3. Compiling Exploit Code

Many older or lower-level exploits (especially memory-corruption PoCs) ship as C source and must be compiled for the target's OS and CPU architecture before use.

```bash
gcc exploit.c -o exploit               # Standard compile on a matching Linux build
gcc -m32 exploit.c -o exploit           # Force 32-bit output on a 64-bit compiler host
gcc -static exploit.c -o exploit        # Static link — avoids missing shared-library issues on target

# Cross-compiling for a different target architecture (e.g. ARM target from an x86 attacker box)
arm-linux-gnueabi-gcc exploit.c -o exploit_arm
mipsel-linux-gnu-gcc exploit.c -o exploit_mips

chmod +x exploit                        # Don't forget execute permissions after compiling
./exploit target-ip target-port
```

> Compiler errors referencing missing headers or deprecated syntax usually mean the exploit targets an older toolchain — check the exploit comments for the compiler/OS version it was written against rather than patching blindly.

---

## 4. Manual Vulnerability Confirmation

Before reaching for any framework, a raw request crafted with `curl` or `nc` is often the fastest way to confirm a suspected CVE actually applies to the target.

```bash
# Confirm a web service's version/behavior directly
curl -s -I http://target-ip/                      # Grab headers (Server, X-Powered-By banners)
curl -s http://target-ip/vulnerable/path           # Request a known-vulnerable endpoint/path
curl -s -X POST -d "param=value" http://target-ip/endpoint   # Trigger with a crafted POST body

# Path traversal / LFI style probe
curl -s "http://target-ip/app?file=../../../../etc/passwd"

# Raw protocol interaction for a non-HTTP service
nc -nv target-ip port                              # Open a raw connection, grab a banner
nc -nv target-ip port < payload.txt                # Send a crafted payload/request file

# Send a manually crafted HTTP request over a raw socket (full control of headers/CRLFs)
printf 'GET /vulnerable/path HTTP/1.1\r\nHost: target-ip\r\nConnection: close\r\n\r\n' | nc -nv target-ip 80
```

> **Note:** A manual confirmation step tells you *whether the vulnerability exists* before you spend time adapting or compiling a full exploit for it — a 200 OK with the expected leaked content/behavior is a much stronger green light than a version banner alone.

---

## 5. Exploit Reliability Triage

Not every result returned by `searchsploit` (or found on Exploit-DB) is a working weaponized exploit — knowing how to sort the good from the unreliable saves an engagement from stalling on a dead end.

| Signal | What it tells you |
|---|---|
| Exploit-DB "verified" flag | Maintainers have re-tested the PoC and confirmed it functions as described |
| Title contains "DoS" / "Denial of Service" | Crashes the service — does **not** grant code execution or access, even if it "works" |
| Title contains "PoC" | Proves the flaw exists but may need real work to turn into a functioning exploit |
| Comments/README in the exploit noting exact vulnerable build/patch level | Higher confidence it will work if your target matches exactly |
| No target OS/version specified anywhere | Treat with caution — likely to require adaptation or simply fail |
| Multiple exploits for the same CVE | Compare all of them — one PoC often works where another fails on a given build |

```bash
searchsploit -j apache 2.4.49 | grep -i verified   # Filter JSON output for verified entries
```

> If the only available exploit is DoS-only or unverified, that is still useful signal for a report (the service is vulnerable/unpatched) even without full RCE — document it as such rather than forcing it into something it isn't.

---

## 6. Decision Flow: Metasploit vs Manual vs Custom

Choosing the right exploitation path up front avoids wasted effort — this is a rough decision order to run through once a vulnerable service/version is identified.

| Situation | Recommended path |
|---|---|
| A stable, well-tested Metasploit module exists for the exact CVE | Use Metasploit (`metasploit-cheatsheet-professional.md`) — fastest, includes payload handling |
| No Metasploit module, but a verified Exploit-DB PoC matches the exact version | Use `searchsploit -m` / `-x`, adapt and run manually |
| Exploit-DB has only a DoS or unverified PoC | Manually confirm the flaw first (`curl`/`nc`), then decide if weaponizing is worth the time |
| Vulnerability is simple enough to trigger with a raw request | Skip exploit code entirely — craft the request by hand with `curl`/`nc` |
| No public exploit exists at all, or the target diverges significantly from known PoCs | Write a custom script based on the vulnerability advisory/CVE writeup |
| Same vulnerability class needed repeatedly across many hosts | Adapt into a reusable script/module rather than manual one-offs each time |

---

## 7. Practical eJPT Workflow

A typical exploitation sequence chains enumeration output straight into a manual exploit attempt before ever falling back to a framework.

```bash
# 1. Confirm exact service/version from nmap-cheatsheet-professional.md output
nmap -sV -p80,443 target-ip

# 2. Search Exploit-DB offline for a matching exploit
searchsploit apache 2.4.49

# 3. Examine before touching it
searchsploit -x 50383

# 4. Copy it locally and review/adapt hardcoded values
searchsploit -m 50383
head -n 40 50383.py

# 5. Manually confirm the flaw first, independent of the exploit script
curl -s "http://target-ip/vulnerable/path"

# 6. Compile if needed, then run against the target
gcc exploit.c -o exploit && ./exploit target-ip target-port
```

> This manual pipeline (enumerate → search → vet → confirm → run) is the fallback to reach for whenever `metasploit-cheatsheet-professional.md` doesn't have a matching module — always test against a non-critical/lab target first when one is available, since public exploit code can be unstable or crash the target service.

---

## 8. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Search Exploit-DB by product/version | `searchsploit apache 2.4.49` |
| Restrict search to title field | `searchsploit -t "openssh 7.2"` |
| Show Exploit-DB web URL | `searchsploit -w apache 2.4.49` |
| JSON output for scripting | `searchsploit -j apache 2.4.49` |
| Copy exploit locally | `searchsploit -m 50383` |
| Examine exploit without copying | `searchsploit -x 50383` |
| Show path + CVE/OSVDB refs | `searchsploit -p 50383` |
| Update local Exploit-DB copy | `searchsploit -u` |
| Compile C exploit | `gcc exploit.c -o exploit` |
| Force 32-bit compile | `gcc -m32 exploit.c -o exploit` |
| Cross-compile for ARM target | `arm-linux-gnueabi-gcc exploit.c -o exploit_arm` |
| Grab HTTP headers manually | `curl -s -I http://target-ip/` |
| Trigger endpoint with POST body | `curl -s -X POST -d "param=value" http://target-ip/endpoint` |
| Raw protocol banner/connection | `nc -nv target-ip port` |
| Craft raw HTTP request by hand | `printf 'GET / HTTP/1.1\r\nHost: target-ip\r\n\r\n' \| nc -nv target-ip 80` |
| Filter verified exploits only | `searchsploit -j apache 2.4.49 \| grep -i verified` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
