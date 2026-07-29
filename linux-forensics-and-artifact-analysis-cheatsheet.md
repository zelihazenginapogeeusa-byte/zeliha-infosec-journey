# Linux Forensics & Artifact Analysis Cheat Sheet

Where the evidence actually lives on a Linux host, and the commands to pull it — the Linux-side companion to the Volatility/Autopsy (largely Windows-memory-focused) workflow already in this folder.

> Prepared as a reference for BTL1 and general SOC operations.

---

## 1. First Things First — Order of Volatility

Capture in this order; each step below destroys less-volatile evidence less if done first:

1. RAM (`/proc`, running processes, network state)
2. Network connections & routing state
3. Running processes
4. Disk (filesystem, logs)
5. Archived logs / backups

---

## 2. Live System Triage (Before You Touch Disk)

```bash
w; who; last -a                          # who's logged in, and who was
ps auxef                                 # full process tree
netstat -tulpn   # or: ss -tulpn         # listening ports & established connections
lsof -i                                  # processes with open network sockets
lsmod                                    # loaded kernel modules (rootkit check)
crontab -l -u <user>; cat /etc/crontab   # scheduled persistence
```

---

## 3. Key Log Locations

| Log | Path | What it tells you |
|---|---|---|
| Auth log (Debian/Ubuntu) | `/var/log/auth.log` | SSH logins, sudo usage, auth failures |
| Auth log (RHEL/CentOS) | `/var/log/secure` | Same as above, different distro |
| System log | `/var/log/syslog` (Debian) / `/var/log/messages` (RHEL) | General system events |
| Cron log | `/var/log/cron.log` | Scheduled task execution |
| Bash history | `~/.bash_history` (and check `HISTFILE`, `HISTCONTROL` for tampering) | Command history — attackers often clear or disable this |
| Package manager log | `/var/log/apt/history.log` (Debian) / `/var/log/yum.log` (RHEL) | Software installed/removed |
| Web server logs | `/var/log/apache2/access.log`, `/var/log/nginx/access.log` | Web-layer attacker activity |
| Audit log (if `auditd` running) | `/var/log/audit/audit.log` | Detailed syscall-level auditing |
| Last logins (binary) | `/var/log/wtmp`, `/var/log/btmp` (read with `last`/`lastb`) | Successful/failed login history |

**Watch for:** truncated or zero-byte log files, timestamps that don't match `stat` on neighboring files, and gaps in sequential log entries — all signs of log tampering.

---

## 4. Auditd Quick Reference

```bash
ausearch -m EXECVE -ts today            # commands executed today
ausearch -ua <uid>                      # actions by a specific user id
aureport --summary                      # quick summary report
```

If `auditd` isn't installed/running, note that as a finding — it means you're relying entirely on shell history and application logs, which are far easier for an attacker to tamper with.

---

## 5. Timeline Building

```bash
find / -newer /reference_file -type f 2>/dev/null       # files modified after a known-good point in time
find / -mtime -1 -type f 2>/dev/null                     # files modified in the last day
stat <file>                                              # MAC times (Modify/Access/Change) for one file
```

For a full filesystem timeline, use `mactime` (from The Sleuth Kit) against a `fls`-generated bodyfile, or run Autopsy against a disk image for a GUI timeline.

---

## 6. Persistence Mechanism Checklist

```bash
cat /etc/crontab; ls /etc/cron.d /etc/cron.daily /etc/cron.hourly
systemctl list-unit-files --type=service | grep enabled     # enabled services
cat /etc/rc.local                                            # legacy startup script
ls -la /etc/init.d/
cat ~/.bashrc ~/.bash_profile ~/.profile /etc/profile.d/*    # shell startup hooks
find / -perm -4000 -type f 2>/dev/null                        # SUID backdoors
```

---

## 7. Network Artifact Review

```bash
ss -tulpn                                # current listeners
cat /etc/hosts                           # DNS hijack check
iptables -L -n -v                        # firewall rules an attacker may have added/removed
arp -a                                   # ARP cache — check for spoofing indicators
```

---

## 8. Memory Acquisition (for Volatility Analysis)

```bash
# LiME (Linux Memory Extractor) kernel module — the standard tool for live Linux memory capture
insmod lime.ko "path=/mnt/evidence/mem.lime format=lime"
```
Once captured, analyze with Volatility 3 using a matching Linux profile — see [`volatility-autopsy-forensics-cheatsheet-professional.md`](volatility-autopsy-forensics-cheatsheet-professional.md) in this folder for the Volatility workflow itself (largely OS-agnostic once you have the profile).

---

## 9. Disk Imaging (Before Deep Analysis)

```bash
dd if=/dev/sdX of=/mnt/evidence/disk.img bs=4M status=progress
# or, preferred for forensic soundness:
dc3dd if=/dev/sdX hash=sha256 log=/mnt/evidence/dc3dd.log of=/mnt/evidence/disk.img
```
Always hash the source and the image, and document chain of custody before analysis begins.

---

## 10. Quick Decision Flow

1. **Is the system still live?** → run section 2 (live triage) before anything else touches the disk.
2. **What time window matters?** → use section 5 to build a timeline around it.
3. **What's persisting?** → section 6, every single time — attackers that got in once will try to survive a reboot.
4. **Do you need memory, disk, or both?** → sections 8–9 for acquisition; hand off to Volatility/Autopsy for deep analysis.

---

*Companion to [`volatility-autopsy-forensics-cheatsheet-professional.md`](volatility-autopsy-forensics-cheatsheet-professional.md) in this folder — that one leans Windows/memory-forensics, this one is the Linux/disk-and-log side.*

*Prepared as a reference for BTL1 and general SOC operations.*
