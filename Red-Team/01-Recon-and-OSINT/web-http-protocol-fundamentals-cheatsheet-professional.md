# Web & HTTP Protocol Fundamentals Cheat Sheet

This document covers the raw mechanics of HTTP — request/response anatomy, methods, headers, status codes, cookies, and TLS basics — that everything else in web application testing is built on top of, mapping to eJPT's "Introduction to the Web & HTTP Protocol" module. It's the prerequisite layer beneath `web-enumeration-common-vulns-cheatsheet-professional.md` (which assumes you already read a request/response) and `burp-suite-cheatsheet-professional.md` (which is the tool that lets you intercept and edit what's described here).

---

## Table of Contents

1. [Anatomy of an HTTP Request/Response](#1-anatomy-of-an-http-requestresponse)
2. [HTTP Methods](#2-http-methods)
3. [Security-Relevant Headers](#3-security-relevant-headers)
4. [HTTP Status Codes](#4-http-status-codes)
5. [Cookies & Session Management](#5-cookies--session-management)
6. [Intercepting Traffic (Concept)](#6-intercepting-traffic-concept)
7. [HTTPS/TLS Basics for Testers](#7-httpstls-basics-for-testers)
8. [Manual Testing with curl](#8-manual-testing-with-curl)
9. [Quick Command Reference](#9-quick-command-reference)

---

## 1. Anatomy of an HTTP Request/Response

Every HTTP exchange follows the same four-part structure — a start line, headers, a blank line, and an optional body — and being able to read this by eye is the single most fundamental skill for web testing.

```http
POST /login HTTP/1.1
Host: target.example.com
User-Agent: Mozilla/5.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 29
Cookie: session=abc123

username=admin&password=test
```

- **Request/status line** — method + path + HTTP version (`POST /login HTTP/1.1`), or for a response, version + status code + reason phrase (`HTTP/1.1 200 OK`)
- **Headers** — key: value pairs, one per line, carrying metadata about the request/response
- **Blank line** — a single `\r\n` that separates headers from the body; its absence/presence is what tells a parser where headers end
- **Body** — optional payload (form data, JSON, file upload) — present on `POST`/`PUT`, normally absent on `GET`

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1256
Set-Cookie: session=xyz789; HttpOnly; Secure

<html>...</html>
```

> **Note:** the response mirrors the same structure — status line, headers, blank line, body — which is why learning to read one half makes the other half trivial.

---

## 2. HTTP Methods

Each HTTP method signals a different intended action on the target resource, and knowing what each is *supposed* to do is what lets a tester spot when the server does something it shouldn't.

| Method | Purpose | Testing relevance |
|---|---|---|
| **GET** | Retrieve a resource, no body expected | Most common attack surface — parameters live in the URL, easy to fuzz/log |
| **POST** | Submit data to be processed (forms, API calls) | Body-based injection points; not logged in browser history/URLs |
| **PUT** | Create/replace a resource at a given URI | If enabled and unauthenticated, can allow arbitrary file upload/overwrite |
| **DELETE** | Remove a resource | If enabled without auth checks, can allow unauthorized data destruction |
| **HEAD** | Same as GET but returns headers only, no body | Useful for quickly checking status/headers without downloading content |
| **OPTIONS** | Ask the server which methods are allowed on a resource | First check for verb tampering — reveals the attack surface for that endpoint |

```bash
# Ask the server what it will accept on this endpoint
curl -i -X OPTIONS http://target/api/users
```

> **Verb tampering / method override:** an endpoint that only checks auth on `GET` but not on `POST`/`PUT`/`DELETE` for the same path is a classic authorization bypass — always re-test a blocked action with a different method (or `X-HTTP-Method-Override` header) before ruling it out.

---

## 3. Security-Relevant Headers

Headers carry most of the metadata an attacker can read, spoof, or abuse, so a handful of them are worth checking on every single request.

| Header | Direction | Security relevance |
|---|---|---|
| `Host` | Request | Determines routing/vhost selection — spoofable for host header injection, password-reset poisoning, vhost/cache-based attacks |
| `Cookie` | Request | Carries session tokens — theft/prediction leads directly to session hijacking |
| `Authorization` | Request | Carries credentials (Basic/Bearer/JWT) — check for weak encoding, missing expiry, algorithm confusion |
| `Content-Type` | Both | Declares body format — mismatched/spoofed values can bypass upload filters or trigger different parsers server-side |
| `User-Agent` | Request | Client fingerprint string — attacker-controlled, sometimes reflected/logged unsanitized (XSS/log injection) |
| `X-Forwarded-For` | Request | Client IP as seen by a proxy — often trusted blindly, making it a common IP allowlist/rate-limit bypass vector |
| `Referer` | Request | Prior page URL — can leak sensitive tokens in URLs, sometimes checked (weakly) for CSRF protection |

```http
GET /admin HTTP/1.1
Host: internal-panel.target.local
X-Forwarded-For: 127.0.0.1
User-Agent: <script>alert(1)</script>
```

> **Note:** `X-Forwarded-For: 127.0.0.1` is a standard first move against IP-based access controls — many applications trust this header without verifying it came from an actual upstream proxy.

---

## 4. HTTP Status Codes

Status codes are grouped into five classes by their first digit, and testers develop a reflex for which specific codes are worth a second look.

| Code | Meaning | Why it matters for testing |
|---|---|---|
| **200 OK** | Request succeeded | Baseline for comparison — confirm this is what a legitimate response looks like |
| **301/302** | Redirect (permanent/temporary) | Follow to see final destination — open redirects and post-login redirect logic live here |
| **401 Unauthorized** | Authentication required/failed | No valid credentials presented at all — different from 403, matters for distinguishing "who are you" vs "you can't" |
| **403 Forbidden** | Authenticated but not permitted | Server recognizes the request but denies it — a prime target for authorization-bypass testing (IDOR, forced browsing, method tampering) |
| **404 Not Found** | Resource doesn't exist | Baseline for "nothing here" — useful for diffing against 403 to enumerate hidden paths |
| **500 Internal Server Error** | Unhandled server-side error | Often leaks stack traces, file paths, or SQL syntax — a strong signal that malformed input reached vulnerable code |

> **401 vs 403:** 401 means "I don't know who you are" (no/invalid credentials); 403 means "I know who you are, and you're still not allowed." A 403 on a resource you can't reach as an authenticated low-privilege user is exactly the kind of finding IDOR/auth-bypass testing targets (see `web-enumeration-common-vulns-cheatsheet-professional.md`).

---

## 5. Cookies & Session Management

Cookies are how a stateless protocol fakes a persistent login session, and the `Set-Cookie` attributes attached to them determine how much an attacker can do if they get near that cookie.

```http
Set-Cookie: session=xyz789; Secure; HttpOnly; SameSite=Strict
```

| Attribute | What it does | Risk if missing |
|---|---|---|
| **Secure** | Cookie only sent over HTTPS | Cookie can be sniffed in plaintext over HTTP (e.g. on shared/untrusted networks) |
| **HttpOnly** | Cookie inaccessible to JavaScript (`document.cookie`) | An XSS finding becomes full session-token theft instead of just DOM manipulation |
| **SameSite** | Controls whether the cookie is sent on cross-site requests (`Strict`/`Lax`/`None`) | Missing/`None` makes the application more exposed to CSRF |

```bash
# Quickly check a target's cookie attributes
curl -i https://target/login | grep -i set-cookie
```

> **Note:** finding all three attributes present doesn't mean session management is fully secure — also check session token entropy/predictability and whether the token rotates on privilege change (e.g. after login).

---

## 6. Intercepting Traffic (Concept)

Everything above — request lines, headers, status codes, `Set-Cookie` — is exactly what an intercepting proxy shows and lets you edit, which is why this file is the conceptual groundwork for proxy-based testing.

```
Browser → Proxy (127.0.0.1:8080) → Target server
        ←                        ←
```

- The proxy sits in the middle of the TCP connection, terminating TLS on both sides so it can read/modify plaintext HTTP even over HTTPS
- Every field covered in this document (method, headers, cookies, body) becomes directly editable once traffic is routed through the proxy
- Full proxy setup, Repeater/Intruder workflows, and certificate trust steps are covered in `burp-suite-cheatsheet-professional.md` — this section is only the "why" behind that tool

> **Note:** understanding the raw request/response format first makes Burp's Proxy/Repeater tabs far less confusing — they're just a GUI over the exact text shown in Section 1.

---

## 7. HTTPS/TLS Basics for Testers

HTTPS wraps HTTP inside an encrypted TLS tunnel, and a tester mainly needs to know how that encryption gets in the way of — and gets deliberately bypassed for — inspection.

- TLS encrypts data in transit and validates server identity via a certificate chain rooted in a trusted Certificate Authority (CA)
- Certificate validation checks: is it signed by a trusted CA, is it for the correct hostname, and is it within its validity dates — any failure should normally cause the browser to warn/block
- To inspect HTTPS traffic with a proxy, the proxy performs its own TLS termination and re-encryption (a controlled man-in-the-middle) — this only works cleanly if the client trusts the proxy's own CA certificate
- Without importing that CA cert into the browser/OS trust store, every intercepted HTTPS request throws a certificate warning or fails outright

```bash
# Quick command-line look at a target's certificate details
curl -vI https://target 2>&1 | grep -i -A2 "subject\|issuer\|SSL certificate"
```

> **Note:** self-signed/expired/mismatched-hostname certs on a target itself (not the proxy) are also worth flagging as findings — they indicate weak TLS hygiene even outside interception setup.

---

## 8. Manual Testing with curl

`curl` gives quick, scriptable HTTP access without spinning up a browser or proxy — ideal for one-off header checks, method tests, and redirect tracing.

```bash
curl -i https://target/                        # -i: include response headers in output
curl -s https://target/ -o /dev/null -w "%{http_code}\n"   # print only the status code
curl -L https://target/old-page                 # -L: follow redirects (301/302) to final destination
curl -X PUT https://target/api/file -d @payload # -X: set a custom/non-default HTTP method
curl -X OPTIONS -i https://target/api/users     # enumerate allowed methods on an endpoint
curl -H "X-Forwarded-For: 127.0.0.1" https://target/admin   # inject a custom header
curl -b "session=abc123" https://target/profile # -b: send a cookie with the request
curl -A "custom-agent-string" https://target/    # -A: set a custom User-Agent
curl -k https://target/                          # -k: ignore TLS cert validation (self-signed lab targets only)
```

> **Note:** `curl` is not a replacement for a proxy — it doesn't save history or let you replay/diff requests — but it's faster for a single sanity check like "does this endpoint accept PUT" or "does this redirect chain end where I expect."

---

## 9. Quick Command Reference

A single-page lookup for every command/header covered above.

| Need | Command/Header |
|---|---|
| Show response headers | `curl -i https://target/` |
| Print only the HTTP status code | `curl -s -o /dev/null -w "%{http_code}\n" https://target/` |
| Follow redirects to final destination | `curl -L https://target/old-page` |
| Send a custom/non-default method | `curl -X PUT https://target/api/file -d @payload` |
| Enumerate allowed methods (verb tampering recon) | `curl -X OPTIONS -i https://target/api/users` |
| Spoof source IP for access-control bypass attempts | `curl -H "X-Forwarded-For: 127.0.0.1" https://target/admin` |
| Send a cookie manually | `curl -b "session=abc123" https://target/profile` |
| Set a custom User-Agent | `curl -A "custom-agent-string" https://target/` |
| Skip TLS cert validation (lab targets only) | `curl -k https://target/` |
| Inspect a target's TLS certificate | `curl -vI https://target 2>&1 \| grep -i -A2 "subject\|issuer"` |
| Check cookie security attributes | `curl -i https://target/login \| grep -i set-cookie` |

---

*Prepared as a reference for the eJPT web application pentest module. All techniques should only be used within written authorization (scope/RoE).*
