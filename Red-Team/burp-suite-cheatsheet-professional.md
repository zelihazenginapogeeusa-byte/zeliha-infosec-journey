# 🔐 Burp Suite - Web Application Security Testing Complete Cheat Sheet

> **Comprehensive Guide to Burp Suite for Web Application Penetration Testing**

## Table of Contents
1. [Installation](#installation)
2. [Proxy Setup](#proxy-setup)
3. [Scanner](#scanner)
4. [Intruder](#intruder)
5. [Repeater](#repeater)
6. [Decoder](#decoder)
7. [Comparator](#comparator)
8. [Extensions](#extensions)

---

## Installation

```bash
# Linux
sudo apt-get install burpsuite
# Or download from https://portswigger.net/burp/releases

# macOS
brew install burpsuite

# Windows
# Download from https://portswigger.net/burp/
```

---

## Proxy Setup

### Configure Browser

```
Burp Proxy: 127.0.0.1:8080

Firefox:
1. Preferences → Network Settings
2. Manual proxy configuration
3. HTTP Proxy: 127.0.0.1, Port: 8080
4. Check "Use this proxy for all protocols"

Chrome:
1. Chrome Extensions → FoxyProxy
2. Add proxy: 127.0.0.1:8080
3. Enable FoxyProxy
```

### Basic Proxy

```
Burp → Proxy → Options
- Proxy listeners: 127.0.0.1:8080
- Intercept Client Requests: ON
- Intercept Server Responses: ON
```

---

## Scanner

### Automated Scanning

```
1. Open target site (through proxy)
2. Right-click request in Proxy
3. "Send to Scanner"
4. Scanner → Active Scanning
5. View Issues tab

Scan Types:
- Passive scanning (analyze traffic)
- Active scanning (test vulnerabilities)
```

### Scan Settings

```
Burp → Scanner → Settings:
- XSS (all kinds)
- SQL Injection
- XXE
- CSRF
- Path traversal
- Sensitive info disclosure
```

---

## Intruder

### Attack Types

```
1. Sniper (-): Single payload position
2. Battering Ram (=): Same payload all positions
3. Pitchfork (>>): Different payloads per position
4. Cluster Bomb (**): All payload combinations
```

### Simple Attack

```
1. Highlight parameter value
2. Right-click → "Send to Intruder"
3. Intruder → Positions (set positions)
4. Payloads (load wordlist)
5. Start Attack
```

### Payload Examples

```
# Usernames
admin
root
user
test

# Passwords
password
123456
admin123
letmein

# SQLi payloads
' or '1'='1
' union select null--
'; DROP TABLE users--

# XSS payloads
<script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>
```

---

## Repeater

### Using Repeater

```
1. Proxy → Intercepted request
2. Right-click → "Send to Repeater"
3. Repeater tab
4. Modify request
5. Send (Ctrl+U)
6. View response
```

### Common Tests

```
# Change parameter
GET /page.php?id=1 → id=2, id=3...

# Change methods
GET → POST, PUT, DELETE, PATCH

# Add headers
User-Agent: Custom
X-Admin: true
X-Forwarded-For: 127.0.0.1

# Bypass authentication
Remove Cookie
Remove Authorization header
```

---

## Decoder

### Encoding/Decoding

```
1. Decoder tab
2. Paste encoded data
3. Select encoding type

Types:
- URL
- HTML
- Base64
- JavaScript
- Hex
- ASCII
- MD5
- SHA-1
- SHA-256
```

### Examples

```
URL Encode: hello world → hello%20world
Base64: admin:pass → YWRtaW46cGFzcw==
Hex: ABC → 414243
HTML: <script> → &lt;script&gt;
```

---

## Extensions

### Popular Extensions

```
- SQLMap RCE
- Active Scan++
- Wsdler (WSDL parser)
- Logger++
- Collaborator Everywhere
- Autorize
- JWT Editor
- ParamSpider
```

### Install Extension

```
Burp → Extender → Extensions
1. Click "Add"
2. Select .jar file
3. Configure if needed
4. Use from Burp context menu
```

---

## Common Workflows

### Authentication Bypass

```
1. Intercept login request
2. Send to Repeater
3. Modify username/password
4. Try SQLi payloads: ' or '1'='1'-- 
5. Remove/modify authentication tokens
6. Try parameter pollution
```

### File Upload

```
1. Intercept upload request
2. Send to Repeater
3. Change filename to .php
4. Change Content-Type to text/plain
5. Bypass with MIME types
6. Try null byte injection: shell.php%00.jpg
```

### Parameter Tampering

```
1. Intercept request
2. Right-click → Send to Intruder
3. Mark parameters
4. Load wordlist
5. Analyze responses for changes
```

### SQL Injection Testing

```
1. Repeater → Request
2. Modify parameter: ' or '1'='1
3. Look for error messages
4. Try UNION: ' union select NULL--
5. Send to Scanner for automated testing
```

---

## Tips & Tricks

```
# Keyboard Shortcuts
Ctrl+U = Send request (Repeater)
Ctrl+Shift+U = URL encode/decode
Ctrl+Shift+B = Base64 encode/decode
Ctrl+Tab = Switch tabs
Ctrl+I = Intruder
Ctrl+R = Repeater

# Useful Features
- Macros (automate tasks)
- Sessions (save/load)
- Collaborator (out-of-band)
- Match/Replace rules
- Scope management
```

---

## Resources

- [Burp Official](https://portswigger.net/burp)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [WebSecurity Academy](https://portswigger.net/web-security)

---

© 2026 | Burp Suite Cheat Sheet | Educational Purpose
