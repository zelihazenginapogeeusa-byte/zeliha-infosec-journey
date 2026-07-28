# Burp Suite Cheat Sheet

**Burp Suite** is the standard intercepting-proxy platform for manual web application testing in eJPT's web module — it sits between browser and server, letting you inspect, modify, and replay every HTTP request. This document covers the core components, proxy setup, and the Repeater/Intruder workflows used most in exam scenarios.

---

## Table of Contents

1. [Core Components Overview](#1-core-components-overview)
2. [Setting Up the Proxy](#2-setting-up-the-proxy)
3. [Proxy & Intercept Workflow](#3-proxy--intercept-workflow)
4. [Repeater](#4-repeater)
5. [Intruder](#5-intruder)
6. [Decoder & Comparer](#6-decoder--comparer)
7. [Extensions Worth Knowing](#7-extensions-worth-knowing)
8. [Quick Command/Workflow Reference](#8-quick-commandworkflow-reference)

---

## 1. Core Components Overview

Burp is organized into tabs, each handling a distinct part of the manual testing workflow — knowing which tab to reach for is half the skill.

| Component | Purpose |
|---|---|
| **Proxy** | Intercepts and logs all HTTP(S) traffic between browser and target |
| **Repeater** | Manually edit and resend individual requests, compare responses |
| **Intruder** | Automated payload injection across one or more request positions |
| **Decoder** | Encode/decode data (URL, Base64, HTML, hex...) |
| **Comparer** | Diff two pieces of data (e.g. two responses) byte-by-byte or word-by-word |
| **Target / Scope** | Defines and visualizes which hosts/URLs are in scope for the engagement |

---

## 2. Setting Up the Proxy

Before Burp can see any traffic, the browser needs to route through it — and HTTPS traffic needs Burp's CA certificate trusted, or every request will fail on a cert warning.

- Set the browser's proxy to `127.0.0.1:8080` (Burp's default listener) — or use FoxyProxy for a one-click toggle in Firefox
- Navigate to `http://burp` (or `http://burpsuite`) while proxying through Burp to download the CA certificate
- Import the certificate into the browser's trust store (Firefox: Settings > Certificates > Import; specify "Trust this CA to identify websites")
- Verify by browsing to any HTTPS site — no certificate warning should appear, and the request should show up in Proxy > HTTP History

> Without importing Burp's CA cert, HTTPS interception throws constant certificate errors — this is the single most common setup mistake early in a Burp-based engagement.

---

## 3. Proxy & Intercept Workflow

The Proxy tab is where live traffic is caught, inspected, and either allowed through or manipulated before it reaches the server.

- **Intercept is on** — every request pauses in Burp before being forwarded; edit headers/body/parameters, then click **Forward**
- **Intercept is off** — requests pass straight through but are still logged to **HTTP History** for later review
- **Drop** — discard a captured request entirely instead of forwarding it
- Right-click any captured request to send it directly to **Repeater**, **Intruder**, or **Comparer**

```
Typical flow:
1. Turn Intercept OFF while browsing normally to build up HTTP History
2. Browse the full application to populate Target > Site map
3. Turn Intercept ON only when you need to catch and modify a specific request live
4. Use HTTP History afterward to find interesting requests to send to Repeater
```

> Leaving Intercept ON while casually browsing is the most common beginner mistake — every single request (including images, CSS, analytics beacons) pauses and has to be manually forwarded, which is tedious and easy to lose track of.

---

## 4. Repeater

Repeater is for manually testing a single request over and over — editing one parameter at a time and observing exactly how the response changes.

- Send a request to Repeater via right-click ("Send to Repeater") from Proxy history or anywhere else in Burp
- Edit any part of the request — headers, cookies, body parameters, the URL itself
- Click **Send** to fire it and view the response side-by-side
- Use the response search/render tabs to check for reflected input, error messages, or behavioral differences

```
Example use case — manually testing a parameter for SQL injection:
1. Send GET /item.php?id=1 to Repeater
2. Change id=1 to id=1'  → observe if an SQL error appears in the response
3. Change to id=1' OR '1'='1  → observe if the response changes (more rows returned)
4. Once a lead is confirmed, hand the request off to sqlmap via -r (see sqlmap-cheatsheet-professional.md)
```

> Repeater is where manual injection/logic testing actually happens — it's the natural precursor to automating a confirmed lead with `sqlmap -r request.txt`.

---

## 5. Intruder

Intruder automates sending many variations of a request, substituting payloads into marked positions — useful for brute-forcing, fuzzing parameters, and testing payload lists at scale.

| Attack Type | Behavior |
|---|---|
| **Sniper** | One payload set, cycles through each marked position one at a time |
| **Battering ram** | One payload set, inserts the *same* payload into *all* positions simultaneously |
| **Pitchfork** | Multiple payload sets, iterates them in parallel (position 1 uses list 1, position 2 uses list 2, same index) |
| **Cluster bomb** | Multiple payload sets, tries every combination of all lists (e.g. every username × every password) |

```
Workflow:
1. Send a request to Intruder
2. In "Positions," mark injection points with §§ (e.g. username=§admin§&password=§test§)
3. Choose an attack type (Cluster bomb for username/password brute force is most common)
4. In "Payloads," load a wordlist per position
5. Start attack, sort results by response length/status code/time to spot the anomaly
```

> Cluster bomb is the standard choice for credential brute-forcing two independent fields (username list × password list); Pitchfork is used when the lists are already paired (e.g. known username:password combos from a breach list).

---

## 6. Decoder & Comparer

Two utility tabs that don't fit the intercept/replay workflow but come up constantly during analysis.

- **Decoder**: paste in a value and encode/decode it as URL, Base64, HTML entities, hex, ASCII hex, or hash it (MD5/SHA1) — useful for reading obfuscated tokens/cookies or crafting an encoded payload
- **Comparer**: send two responses (or requests) to Comparer and diff them word-by-word or byte-by-byte — useful for spotting subtle differences between a valid and invalid login response (a common indicator for username enumeration or blind injection)

```
Example: comparing login responses to find a username-enumeration oracle
1. Send response for a valid username / wrong password to Comparer (item 1)
2. Send response for an invalid username / wrong password to Comparer (item 2)
3. Click "Words" or "Bytes" diff — any difference in length/wording confirms enumeration is possible
```

---

## 7. Extensions Worth Knowing

The BApp Store (Extender tab, in Burp Community/Pro) adds specialized capability beyond Burp's core feature set.

- **Logger++** — enhanced, filterable request/response logging across all Burp tools, not just Proxy
- **Turbo Intruder** — a scriptable, much higher-throughput alternative to stock Intruder for race conditions and large-scale fuzzing
- **Autorize** — automates authorization testing by replaying captured requests under a lower-privileged session

> Extensions require Burp's bundled Jython/JRuby environment for non-Java extensions — install via Extender > BApp Store inside the Burp GUI.

---

## 8. Quick Command/Workflow Reference

A single-page lookup for the core workflows covered above (Burp is GUI-driven, so this is steps rather than shell commands).

| Need | Steps |
|---|---|
| Route browser traffic through Burp | Set browser proxy to `127.0.0.1:8080` |
| Trust HTTPS interception | Browse to `http://burp` → download CA cert → import into browser trust store |
| Pause and edit a live request | Proxy tab → Intercept **on** → edit → **Forward** |
| Review past traffic | Proxy tab → **HTTP History** |
| Manually test one parameter repeatedly | Right-click request → **Send to Repeater** → edit → **Send** |
| Brute-force login credentials | Right-click → **Send to Intruder** → mark `§§` positions → **Cluster bomb** → load payload lists → Start attack |
| Diff two responses | Send both to **Comparer** → **Words**/**Bytes** |
| Encode/decode a token | Paste value into **Decoder** → choose encoding |
| Hand a confirmed lead to sqlmap | Save request from Proxy/Repeater → `sqlmap -r request.txt --batch` |

---

*Prepared as a reference for the eJPT web application module. All techniques should only be used within written authorization (scope/RoE).*
