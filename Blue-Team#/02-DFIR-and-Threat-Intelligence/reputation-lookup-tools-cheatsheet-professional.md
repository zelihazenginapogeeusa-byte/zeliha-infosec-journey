# Reputation & Threat Intel Lookup Tools Cheat Sheet

The "paste an indicator, get a verdict" toolkit for BTL1-style triage. Once `phishing-cheatsheet.md` gives you a suspicious sender/link, or `malware-analysis-yara-cheatsheet-professional.md` gives you a hash, this is where you check whether it's actually malicious. Same tools apply during the Identification phase of `incident-response-lifecycle-cheatsheet-professional.md`.

---

## Table of Contents

1. [How to Use This Sheet](#1-how-to-use-this-sheet)
2. [File Hash & Sandbox Analysis](#2-file-hash--sandbox-analysis)
3. [IP & Network Reputation](#3-ip--network-reputation)
4. [Email, DNS & Domain Reputation](#4-email-dns--domain-reputation)
5. [URL Scanning](#5-url-scanning)
6. [Threat Intel Aggregators](#6-threat-intel-aggregators)
7. [OPSEC Note](#7-opsec-note)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. How to Use This Sheet

An indicator (hash, IP, domain, URL, email) rarely gets a confident verdict from one source alone — cross-check across 2-3 tools before writing a conclusion into an incident report.

```
Indicator found (phishing email, malware sample, SIEM alert)
        ↓
Check reputation (sections 2-4 below)
        ↓
Detonate/sandbox if still ambiguous (section 2)
        ↓
Pivot to related IOCs (section 6)
        ↓
Document verdict + evidence in the incident report
```

> **Zero detections ≠ clean.** Brand-new or custom-written malware often shows 0/70 on a first VirusTotal check. If context (sender, behavior, delivery method) is still suspicious, escalate to sandbox analysis rather than closing the alert.

---

## 2. File Hash & Sandbox Analysis

Once you have a suspicious file or hash in hand, these are the services to check reputation against and, if needed, safely detonate the sample.

| Tool | Link | Used for |
|---|---|---|
| **VirusTotal** | [virustotal.com](https://www.virustotal.com/) | The universal first stop — paste a hash/file/URL/domain/IP and get a verdict from 70+ AV engines at once, plus community comments and relationship graphs (which domains a file talked to, which files share a hash) |
| **Any.Run** | [any.run](https://any.run/) | Interactive sandbox — watch the process tree, network calls, and dropped files live as the sample runs, and click through the VM yourself. Best for malware that needs user interaction to detonate (macro prompts, CAPTCHAs) |
| **Hybrid Analysis** (CrowdStrike) | [hybrid-analysis.com](https://www.hybrid-analysis.com/) | Free automated sandbox report — similar to Any.Run but non-interactive; good for a quick static+dynamic report without watching it run |
| **Joe Sandbox** | [joesandbox.com](https://www.joesandbox.com/) | Deep behavioral sandbox reports (free Cloud Basic tier available) — more thorough evasion detection than the free tools |
| **MetaDefender Cloud** (OPSWAT) | [metadefender.com](https://metadefender.com/) | Multi-engine scan for files, URLs, IPs, and hashes — a good VirusTotal alternative/second opinion, also checks for hidden/embedded files inside documents |
| **Intezer Analyze** | [analyze.intezer.com](https://analyze.intezer.com/) | Code-reuse ("genetic") analysis — identifies malware family/threat actor attribution by comparing code to a database of known malware, rather than just signature matching |

> Pairs directly with `malware-analysis-yara-cheatsheet-professional.md` section 2 (hash triage) and section 7 (dynamic analysis) — this table is the fuller tool list behind that workflow.

---

## 3. IP & Network Reputation

For a suspicious source or destination IP, these tools tell you whether it's a known-bad actor, background internet noise, or something worth deeper investigation.

| Tool | Link | Used for |
|---|---|---|
| **AbuseIPDB** | [abuseipdb.com](https://www.abuseipdb.com/) | Community-reported abuse database for an IP — shows how many times it's been reported, for what (brute force, spam, port scan), and a confidence-of-abuse score |
| **GreyNoise** | [greynoise.io](https://www.greynoise.io/) | Tells you whether an IP hitting your logs is "internet background noise" (mass scanners, research bots) vs. a targeted attacker — cuts down alert fatigue during SOC triage |
| **Talos Intelligence** (Cisco) | [talosintelligence.com](https://talosintelligence.com/) | IP/domain/file reputation with a spam/malware score — also useful for checking a mail server's sending reputation |
| **IPVoid** | [ipvoid.com](https://www.ipvoid.com/) | Aggregates blacklist-check results for an IP across dozens of DNSBL/RBL lists in one query |
| **Shodan / Censys** | [shodan.io](https://www.shodan.io/) · [censys.com](https://censys.com/) | Look up what an attacker IP is actually running/exposing — useful context beyond a pure reputation score |

> **Alert triage workflow:** a SIEM alert fires on an unfamiliar source IP → check AbuseIPDB first (is this a known-bad IP) → check GreyNoise (is this just internet-wide scanning noise, safe to deprioritize) → escalate only what's left.

---

## 4. Email, DNS & Domain Reputation

These services validate a sending domain's authentication posture and registration history — key evidence when building a phishing verdict.

| Tool | Link | Used for |
|---|---|---|
| **MXToolbox** | [mxtoolbox.com](https://mxtoolbox.com/) | Blacklist check across major DNSBLs, an SPF/DKIM/DMARC record validator, and a header analyzer — the go-to for validating a phishing email's sender authentication results |
| **DomainTools WHOIS** | [whois.domaintools.com](https://whois.domaintools.com/) | Deeper WHOIS/registration history than a plain `whois` command — useful for checking how recently a suspicious domain was registered (freshly registered = red flag) |
| **DNSChecker** | [dnschecker.org](https://dnschecker.org/) | DNS propagation check across global servers, plus generic A/MX/TXT/NS record lookup |

> Pairs directly with `phishing-cheatsheet.md`'s header analysis section — MXToolbox's header analyzer parses the same `Received`/`Authentication-Results` fields you'd otherwise read by hand.

---

## 5. URL Scanning

Rather than clicking a suspicious link yourself, run it through one of these to see where it actually leads and what it loads.

| Tool | Link | Used for |
|---|---|---|
| **urlscan.io** | [urlscan.io](https://urlscan.io/) | Sandboxed URL scan — takes a screenshot, records the full request/response chain and every domain contacted, without you having to visit the link yourself |
| **VirusTotal** (URL mode) | [virustotal.com/gui/home/url](https://www.virustotal.com/gui/home/url) | Same engine as the file-hash lookup, applied to a URL/domain — multi-vendor verdict on whether a link is phishing/malicious |

> **Never click a suspicious link directly** — always resolve it through one of these first so the detonation happens in their sandbox, not your browser.

---

## 6. Threat Intel Aggregators

Once an indicator is confirmed malicious, these aggregators help you pivot from a single IOC to the broader campaign or threat actor it belongs to.

| Tool | Link | Used for |
|---|---|---|
| **AlienVault OTX** | [otx.alienvault.com](https://otx.alienvault.com/) | Open Threat Exchange — community-shared IOC "pulses" tied to specific campaigns/threat actors, free account required |
| **ThreatMiner** | [threatminer.org](https://www.threatminer.org/) | Free threat intel data mining — pivot from a hash/domain/IP to related samples, passive DNS, and reports |
| **Pulsedive** | [pulsedive.com](https://pulsedive.com/) | Free threat intel search engine — aggregates and risk-scores IOCs from multiple open feeds |

> Feeds directly into `threat-intelligence-mitre-attack-cheatsheet-professional.md` — once an aggregator ties an IOC to a known campaign/actor, map that actor's known TTPs against MITRE ATT&CK.

---

## 7. OPSEC Note

Uploading indicators to public multi-vendor scanners can itself leak information about an ongoing investigation, so a few precautions are worth building into habit.

- [ ] **Public multi-AV scanners share your submission** — files/URLs uploaded to VirusTotal and similar tools become visible to other users/vendors on many plans. Don't upload confidential or client-identifying samples without checking the engagement's data-handling rules.
- [ ] **Prefer non-public/private scanning options** where the engagement requires confidentiality (VirusTotal Enterprise private scanning, an internal sandbox, or an isolated offline VM) instead of the free public tier.

---

## 8. Quick Command Reference

A single-page lookup for every tool covered above.

| Need | Link |
|---|---|
| File/hash reputation | [virustotal.com](https://www.virustotal.com/) |
| Interactive malware sandbox | [any.run](https://any.run/) |
| Free automated sandbox | [hybrid-analysis.com](https://www.hybrid-analysis.com/) |
| Code-reuse/family attribution | [analyze.intezer.com](https://analyze.intezer.com/) |
| IP abuse/blacklist check | [abuseipdb.com](https://www.abuseipdb.com/) · [ipvoid.com](https://www.ipvoid.com/) |
| Scanner-noise vs. targeted IP | [greynoise.io](https://www.greynoise.io/) |
| Mail/DNS blacklist + SPF/DKIM/DMARC | [mxtoolbox.com](https://mxtoolbox.com/) |
| URL sandbox scan | [urlscan.io](https://urlscan.io/) |
| Domain registration history | [whois.domaintools.com](https://whois.domaintools.com/) |
| Threat intel IOC pivoting | [otx.alienvault.com](https://otx.alienvault.com/) · [threatminer.org](https://www.threatminer.org/) · [pulsedive.com](https://pulsedive.com/) |

---

*Prepared as a reference for BTL1 phishing/malware triage and general SOC operations.*
