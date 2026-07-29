# Phishing Analysis Cheat Sheet — BTL1

A quick-reference guide for the **Phishing Analysis** module of Security Blue Team's **Blue Team Level 1 (BTL1)** certification. Covers email header reading, interpreting SPF/DKIM/DMARC, red-flag spotting, IOC extraction, and the triage workflow — all on one page.

---

## Table of Contents

1. [Types of Phishing](#1-types-of-phishing)
2. [Email Header Anatomy](#2-email-header-anatomy)
3. [SPF / DKIM / DMARC](#3-spf--dkim--dmarc)
4. [Red Flag Checklist](#4-red-flag-checklist)
5. [Analyst Toolkit](#5-analyst-toolkit)
6. [Triage Workflow](#6-triage-workflow)
7. [IOC Extraction & Defanging](#7-ioc-extraction--defanging)
8. [Attachment / Malware Analysis](#8-attachment--malware-analysis)
9. [URL & Domain Analysis](#9-url--domain-analysis)
10. [Verdict & Reporting Template](#10-verdict--reporting-template)
11. [Quick Command / Regex Reference](#11-quick-command--regex-reference)
12. [BTL1 Exam Tips](#12-btl1-exam-tips)

---

## 1. Types of Phishing

Knowing which variant you're looking at helps you gauge the attacker's likely sophistication and target, and strengthens your justification when writing up a verdict.

| Type | Definition | Target |
|---|---|---|
| **Phishing** | A generic, mass-distributed fraudulent email attack sent to a broad audience. | Random users |
| **Spear Phishing** | A researched, personalized attack crafted for a specific individual or organization. | A targeted individual |
| **Whaling** | Spear phishing aimed specifically at senior executives (CEO, CFO, etc.). | Senior management |
| **BEC** (Business Email Compromise) | Often follows a whaling attack; a fraudulent payment/transfer request sent from a compromised or spoofed executive account. | Finance/accounting staff |
| **Clone Phishing** | A previously delivered legitimate email is duplicated, with its links/attachments swapped for malicious ones. | Previous recipients |
| **Angler Phishing** | Phishing conducted via social media (e.g. a fake customer-support account). | Social media users |
| **Smishing** | Phishing carried out over SMS/text message. | Mobile users |
| **Vishing** | Voice-call-based social engineering. | Phone users |
| **Pharming** | DNS poisoning / hosts-file manipulation that redirects users to a fake site — no email required. | All users at the DNS/host level |
| **Watering Hole** | Compromising a legitimate site the target group frequently visits and injecting malicious content. | A specific sector/group |

> **Exam note:** In BTL1 scenarios you'll most often see classic phishing, spear phishing, and BEC. The question is rarely "what type of attack is this" — it's usually "is this email malicious, and what are the IOCs" — but knowing the type still helps you justify your verdict in the write-up.

---

## 2. Email Header Anatomy

When examining an `.eml` file, don't just read top to bottom — understand the logic first. The single most important rule: the **Received** chain is read **bottom to top** (the bottom-most entry is the first hop; the top-most is the last hop / the server closest to you).

| Header | Purpose | What the analyst checks |
|---|---|---|
| `From` | The displayed sender name + address | Does the display name match the actual domain? (spoofing check) |
| `Reply-To` | The address a reply is actually sent to | If different from `From` — a **strong red flag**, the attacker may be redirecting replies elsewhere |
| `Return-Path` | Where bounce (non-delivery) messages go; the real SMTP `MAIL FROM` | A mismatch with the `From` domain suggests spoofing |
| `Received` | A hop record added by every mail server the message passed through | Read bottom-to-top; the first (bottom-most) hop = the sender's real IP/server |
| `Message-ID` | A unique identifier for the email | Does the domain portion match the claimed sending infrastructure? Useful for OSINT/correlation |
| `X-Originating-IP` | The sender's real IP, added by some mail clients | Not always present, but a direct pivot point when it is |
| `X-Mailer` / `User-Agent` | The software that generated the message | An unexpected mail client in a corporate environment can itself be suspicious |
| `Subject` | The subject line | Urgency/fear language ("Account Suspended", "Invoice Due") is a social-engineering indicator |
| `Content-Type` / `boundary` | The MIME structure of the message (multipart, attachment boundaries) | Used to isolate and hash attachments |

> **Practical tip:** Rather than scanning headers by hand in the BTL1 lab/exam environment, load the message into **PhishTool** or **EmlAnalyzer** — it automatically flags From/Reply-To/Return-Path mismatches, gives you the SPF/DKIM/DMARC result, and lists embedded URLs/attachments.

---

## 3. SPF / DKIM / DMARC

These three DNS-based mechanisms are what let a receiving mail server tell whether an email genuinely originated from the domain it claims to be from.

**SPF (Sender Policy Framework)** — A DNS TXT record on the sending domain that lists which IPs/servers are authorized to send mail on its behalf. The receiving server checks the sending server's IP against this list.

```
v=spf1 include:_spf.google.com ~all
```

**DKIM (DomainKeys Identified Mail)** — The outgoing message is digitally signed with the sender's private key. The recipient verifies the signature against the public key published in the domain's DNS — proving the message wasn't altered in transit.

```
DKIM-Signature: d=example.com; ...
```

**DMARC** — Combines the SPF and DKIM results and tells the receiving server what to do on failure: `none` (monitor only), `quarantine` (send to spam), or `reject` (bounce it).

```
v=DMARC1; p=reject; rua=mailto:...
```

### Reading the Authentication-Results header

```
Authentication-Results: mx.recipient.com;
    spf=fail (sender IP is 203.0.113.9) smtp.mailfrom=example.com;
    dkim=none (message not signed);
    dmarc=fail action=quarantine header.from=example.com
```

| Result | Meaning |
|---|---|
| `pass` | Check succeeded — more likely legitimate (not sufficient evidence on its own!) |
| `fail` | Check failed — a strong spoofing indicator |
| `softfail` (`~all`) | Likely an unauthorized sender, but the domain owner isn't explicitly rejecting it — suspicious, worth monitoring |
| `none` | No SPF/DKIM/DMARC record exists at all — the domain isn't protecting itself |
| `neutral` | The domain owner doesn't explicitly assert pass or fail |

> ⚠️ **Common trap:** SPF/DKIM/DMARC can all show "pass" and the message can still be phishing — because the attacker is using their own domain, which legitimately authenticates (e.g. a phishing email sent from a real `gmail.com` address). Auth results alone are **not** a verdict; they must be weighed together with the other indicators.

---

## 4. Red Flag Checklist

BTL1 questions typically ask you to justify "why is this suspicious/malicious" — use the list below as your write-up's supporting evidence.

- [ ] **Display name ↔ real address mismatch** — shows "IT Support" but the address is `billing@random-domain.ru`
- [ ] **Reply-To ≠ From** — replies are redirected to a different domain
- [ ] **Typosquatting / homograph domains** — `micros0ft.com`, `paypa1.com`, use of Cyrillic characters (punycode `xn--`)
- [ ] **Urgency / fear language** — "Account will be suspended in 24 hours", "Immediate action required"
- [ ] **Generic greeting** — "Dear Customer" / "Dear User", no personalization
- [ ] **Spelling/grammar errors** — especially inconsistent for a supposedly corporate sender
- [ ] **Link text vs. actual destination mismatch** — displayed text reads `https://bank.com` but hovering reveals `https://bank-secure-login.xyz`
- [ ] **Unexpected/risky attachment types** — `.iso`, `.js`, `.hta`, macro-enabled `.docm`/`.xlsm`, password-protected zip
- [ ] **Zero-font / hidden text** — HTML using `font-size:0` or white-on-white text to hide keywords from spam filters
- [ ] **URL shorteners** — bit.ly, tinyurl, etc., conceal the real destination
- [ ] **SPF/DKIM/DMARC fail or none**
- [ ] **An unexpected country/ISP as the first hop** in the Received chain
- [ ] **An unexpected invoice/payment/transfer request** out of context (BEC indicator)

---

## 5. Analyst Toolkit

The toolset below covers everything from manual header parsing to automated sandboxing, and most triage workflows will touch several of these in a single case.

| Tool | What it's for | Typical use in BTL1 |
|---|---|---|
| **PhishTool** | Automated + manual artifact extraction, email analysis, reporting | Upload the `.eml` → get a summary of headers/URLs/attachments |
| **EmlAnalyzer** | Parses `.eml` files into headers, body, and attachments | Quickly viewing header fields |
| **CyberChef** | Base64/URL decoding, defanging/fanging, hashing, regex extraction | Decoding obfuscated/embedded links, formatting IOCs |
| **VirusTotal** | Hash, URL, domain, and IP reputation lookups (multi-engine AV) | Confirming whether an attachment hash or URL is malicious or clean |
| **URLScan.io** | Opens a URL in a sandbox and captures a screenshot + network traffic + DOM | Safely "visiting" a suspicious link to see its behavior |
| **Hybrid Analysis / Any.Run** | Dynamic sandbox analysis for attachments/files (behavior, network, dropped files) | Seeing what a macro-laden Office file or EXE actually does |
| **Talos Intelligence** | Domain/IP reputation and mail-sender reputation | Checking the sending IP's historical reputation |
| **MXToolbox** | Querying SPF/DKIM/DMARC DNS records, blacklist checks | Viewing the sending domain's actual SPF policy |
| **WHOIS** | Domain registration info (registration date, registrar, registrant) | A recently registered domain (days/weeks old) is a strong phishing indicator |
| **Passive DNS** | A domain/IP's historical DNS records | Checking whether the same IP hosts other known-bad domains (infrastructure pivoting) |
| **oledump.py / olevba** | Static analysis of VBA macros in Office documents | Spotting `AutoOpen`, `Shell()`, and PowerShell commands inside a macro |

---

## 6. Triage Workflow

The structure BTL1 expects:

```
Headers → Indicators → Sandbox / VT Lookups → Verdict → Recommendations
```

1. **Headers** — Compare From/Reply-To/Return-Path, read the Received chain, check the SPF/DKIM/DMARC result.
2. **Indicators** — Extract URLs, attachments, IPs, and domains — these become your IOC list.
3. **Sandbox/VT Lookups** — Query every IOC against VirusTotal/URLScan/Hybrid Analysis and record the results.
4. **Verdict** — Based on the evidence gathered, decide **Benign / Suspicious / Malicious** — write your justification point by point.
5. **Recommendations** — Block the sender/domain, quarantine the message, isolate affected accounts, and recommend user awareness training.

> You're racing the clock in the exam — always apply these 5 steps **in the same order**. Jumping randomly between tools instead of following a checklist is what causes you to miss steps under pressure.

---

## 7. IOC Extraction & Defanging

When writing up your findings, IOCs (URLs, domains, IPs) should be written in **defanged** form so they can't be accidentally clicked or turned into an active link inside the report.

| Original | Defanged |
|---|---|
| `http://evil-domain.com` | `hxxp://evil-domain[.]com` |
| `https://192.0.2.10/payload.exe` | `hxxps://192[.]0[.]2[.]10/payload.exe` |
| `attacker@evil.com` | `attacker[@]evil[.]com` |

> CyberChef's "Defang URL" / "Defang IP Addresses" recipes do this automatically.

### IOC types you should be collecting

- Sender's email address + IP (from the Received chain)
- Embedded URLs (displayed text + actual href)
- Attachment filename + `MD5` / `SHA1` / `SHA256` hash
- Any C2 domains/IPs surfaced by sandbox analysis
- Message-ID, Subject (for correlation)

---

## 8. Attachment / Malware Analysis

Attachments are the payload-delivery stage of a phishing attack, and hashing them plus inspecting any macros is how you determine what they actually do.

### Hash types

| Hash | Length | Note |
|---|---|---|
| MD5 | 32 hex chars | Fast but collision-prone — for lookup/identification only |
| SHA1 | 40 hex chars | Stronger than MD5 but now considered weak |
| SHA256 | 64 hex chars | The standard for reporting/sharing IOCs, the most reliable for VT lookups |

### Static macro analysis (Office attachments)

```bash
oledump.py suspicious.doc          # list streams + which stream contains the macro
olevba suspicious.doc              # extract VBA code + scan for suspicious keywords
```

In the `olevba` output, look for: `AutoOpen`, `Document_Open` (auto-execution), `Shell`, `CreateObject`, `powershell -enc` (obfuscated command).

> ⚠️ **Warning:** Never open suspicious files on your host machine. In the BTL1 lab environment — and in the real world — always use an isolated sandbox (Any.Run, Hybrid Analysis) or offline static-analysis tools.

---

## 9. URL & Domain Analysis

Malicious links rarely look malicious at first glance, so verifying the actual destination and its history is as important as reading the visible text.

- **Hover before you click** — always compare the displayed text against the actual `href` target.
- **URL shorteners** (bit.ly, tinyurl, t.co) hide the real destination — expand with CyberChef's "Expand URL" or an online unshortener.
- **Redirect chains** — URLScan.io's "behavior"/"HTTP transactions" tab shows how many redirects occurred and the final destination.
- **IP-literal URLs** (`hxxp://185.220.101.5/login`) — almost never seen on legitimate corporate sites, a strong red flag.
- **Punycode / homograph attacks** — brand impersonation via Unicode characters, e.g. `xn--pple-43d.com`.
- **WHOIS registration date** — if the domain was registered only days/weeks ago, especially for a site posing as a "bank/enterprise", it's a very strong phishing indicator.
- **Passive DNS pivoting** — check whether the same IP/registrar hosts other known-bad domains; this can reveal a broader campaign.

---

## 10. Verdict & Reporting Template

The format of the report you submit in the BTL1 practical exam directly affects your score. Use this structure:

**1. Executive Summary** — Verdict: **Malicious / Suspicious / Benign**. State what it is in one sentence (e.g. "A phishing email redirecting to a domain impersonating a legitimate bank login page").

**2. Evidence** — Header mismatches, SPF/DKIM/DMARC result, red-flag list, sandbox/VT results — as a bullet list.

**3. IOC List** — In defanged format: sender address/IP, URLs, attachment hashes.

**4. Recommendations** — Block the sender/domain, quarantine/delete the message, reset affected user accounts, recommend user awareness training.

> ✅ **Habit that earns marks:** Always answer "why did you call this malicious?" with *at least 2–3 independent pieces of evidence* (e.g. "SPF fail" alone isn't enough — add the display-name mismatch, the recently registered domain, and the VirusTotal malicious verdict too).

---

## 11. Quick Command / Regex Reference

A single-page lookup for the CyberChef recipes and regex patterns used throughout the workflow above.

| Need | CyberChef Recipe / Command |
|---|---|
| Base64 decode | `From Base64` |
| URL decode | `URL Decode` |
| Defang URL/IP | `Defang URL` → `Defang IP Addresses` |
| Compute a hash | `Hash → MD5 / SHA1 / SHA256` |
| Extract all URLs from headers | `Extract URLs` |
| Extract email addresses from headers | `Extract Email Addresses` |
| Separate attachments out of a `.eml` | PhishTool / EmlAnalyzer does this automatically |

### Useful regex

```
IP:      \b(?:\d{1,3}\.){3}\d{1,3}\b
Domain:  \b[a-zA-Z0-9-]+\.[a-zA-Z]{2,}\b
SHA256:  \b[A-Fa-f0-9]{64}\b
```

---

## 12. BTL1 Exam Tips

Beyond the technical steps, these are the exam-specific habits that separate a passing report from a failing one.

- **Format** — The exam is a 24-hour practical plus a report submission — time management is critical, stick to your checklist.
- **Question style** — Expect direct, evidence-based questions like *"What is the sender's IP address?"*, *"What is the SPF result?"*, *"What is the SHA256 hash of the attachment?"*, *"Is this email malicious — justify your answer."*
- **Received chain** — don't get it backwards. Always read bottom-to-top; the first hop is the true source.
- **One piece of evidence isn't enough** — always back up your verdict with multiple indicators.
- **Don't forget to defang** — never leave a live (clickable) link or IP in your report.
- **Tool order** — do the manual header review first, then confirm with automated tools (PhishTool/VT); don't rely on the tool and skip the manual read.
- **Terminology** — know SPF/DKIM/DMARC, Received, Reply-To, Return-Path, IOC, defang, and verdict — the exam and the report template are entirely in English.

---

*Prepared as a study reference for Security Blue Team's BTL1 Phishing Analysis module. For the most current module content, refer to the official Security Blue Team course materials.*
