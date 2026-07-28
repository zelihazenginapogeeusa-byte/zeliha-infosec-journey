# Vulnerability Assessment Cheat Sheet

A Vulnerability Assessment (VA) is the bridge between enumeration and exploitation in the eJPT host/network pentest module — it takes the services identified during scanning and turns them into a scored, prioritized list of known weaknesses before any exploit is attempted; this document covers the VA workflow, Nessus/OpenVAS/Nikto usage, CVSS scoring, and false-positive triage, and it builds directly on target data gathered with `nmap-cheatsheet-professional.md` and `osint-cheatsheet.md`, feeding its output into `penetration-testing-methodology-cheatsheet-professional.md` for the exploitation phase that follows.

---

## Table of Contents

1. [What a Vulnerability Assessment Is](#1-what-a-vulnerability-assessment-is)
2. [The VA Workflow](#2-the-va-workflow)
3. [Nessus Basics](#3-nessus-basics)
4. [OpenVAS/Greenbone — The Open-Source Alternative](#4-openvasgreenbone--the-open-source-alternative)
5. [Nikto — Web Server Vulnerability Scanning](#5-nikto--web-server-vulnerability-scanning)
6. [CVSS v3 Scoring & Prioritization](#6-cvss-v3-scoring--prioritization)
7. [False Positive Triage](#7-false-positive-triage)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. What a Vulnerability Assessment Is

A Vulnerability Assessment identifies and scores weaknesses in scope without ever exploiting them, which is the single defining line between VA and a full penetration test.

| Aspect | Vulnerability Assessment | Penetration Test |
|---|---|---|
| Goal | Identify, verify, and score known vulnerabilities | Prove exploitability and business impact |
| Exploitation | None — scanning and manual confirmation only | Core activity — exploits are run, footholds established |
| Tooling | Nessus, OpenVAS, Nikto, `nmap --script vuln` | Metasploit, manual exploit development, post-exploitation tooling |
| Output | Prioritized findings list with CVSS scores | Narrative report with proof-of-exploit evidence and remediation |
| Depth | Breadth-first — covers everything in scope | Depth-first on the most promising findings |
| Typical duration | Hours to a few days | Days to weeks |

> **Note:** eJPT's practical exam blends both — you are expected to run VA-style scans to build the target's vulnerability picture, then move into actual exploitation, unlike a pure VA engagement which stops at the scored list.

---

## 2. The VA Workflow

Every VA engagement follows the same five-stage loop regardless of which scanner is used, and skipping a stage is the most common source of an unreliable report.

```
1. Scope     — confirm exact hosts/ranges/ports covered by written authorization
2. Scan      — run automated scanners against the in-scope targets
3. Validate  — manually confirm each finding to rule out false positives
4. Score     — assign/confirm a CVSS score to prioritize what matters
5. Report    — deliver a ranked list of confirmed vulnerabilities with remediation notes
```

- **Scope:** re-check the target list against the RoE before scanning — the same discipline covered for nmap targeting in `nmap-cheatsheet-professional.md` applies here.
- **Scan:** run one or more scanners (Nessus, OpenVAS, Nikto, NSE vuln scripts) against every in-scope host/service discovered during enumeration.
- **Validate:** manually confirm high/critical findings before trusting them — see Section 7.
- **Score:** apply or verify CVSS v3 scores so remediation effort maps to actual risk, not scanner noise.
- **Report:** hand off a ranked findings list — this is the artifact that decides what gets exploited first in the next phase.

> Enumeration results (open ports, service banners, versions) from `nmap-cheatsheet-professional.md` are the direct input to this stage — a VA scan without prior enumeration wastes time re-discovering what a targeted `-sV -sC` scan already found.

---

## 3. Nessus Basics

Nessus is the industry-standard commercial vulnerability scanner and the tool most eJPT/INE material demonstrates first — it ships prebuilt scan policies so a useful scan can be configured in minutes.

| Policy Type | Use Case |
|---|---|
| **Basic Network Scan** | General-purpose default — good starting point for most in-scope hosts |
| **Advanced Scan** | Full manual control over every plugin family and setting |
| **Credentialed Patch Audit** | Logs in with supplied credentials to check patch levels directly (fewer false positives, deeper results) |
| **Web Application Tests** | Focused plugin set for web app vulnerabilities |
| **Malware Scan** | Checks hosts for known malware indicators |

**Running a basic scan:**

1. Log in to the Nessus web UI (`https://localhost:8834` by default on a local install).
2. **New Scan → Basic Network Scan.**
3. Set **Name**, **Targets** (single IP, range, CIDR, or a targets file — same conventions as nmap targeting).
4. Leave default plugin settings for a first pass; tighten scope (specific plugin families) for a faster re-scan.
5. **Save**, then **Launch** to run immediately.

**Reading the report:**

- Findings are grouped by host, then listed by **severity** (Critical/High/Medium/Low/Info) — Nessus computes this from the underlying CVSS score.
- Each finding includes: plugin name, CVSS score/vector, affected port/service, a description of the issue, and suggested remediation.
- Export via **Report → Export** (HTML, CSV, or Nessus native `.nessus` XML) for hand-off into a report or for re-import into another tool.

> **Note:** a **credentialed** scan (supplying valid host credentials) produces far more accurate, lower-noise results than an unauthenticated scan, because Nessus can directly query installed package/patch versions instead of inferring them from network responses.

---

## 4. OpenVAS/Greenbone — The Open-Source Alternative

OpenVAS (now packaged as Greenbone Vulnerability Management / GVM) is the free, open-source equivalent to Nessus and a common substitute in labs where a Nessus license isn't available.

| Aspect | OpenVAS/Greenbone |
|---|---|
| Cost | Free / open-source |
| Interface | Greenbone Security Assistant (web UI), similar workflow to Nessus |
| Feed | Community NVT (Network Vulnerability Test) feed, updated regularly |
| Scan config equivalents | "Full and fast", "Full and fast ultimate", "Discovery", "Host Discovery" — roughly map to Nessus's Basic/Advanced/Discovery policies |
| Typical setup | Runs as a service stack (`gvm-setup` / `gvm-start` on Kali-based installs) |

```bash
sudo gvm-setup      # First-time install/build of the NVT feed and database
sudo gvm-start      # Start the Greenbone services (web UI on https://127.0.0.1:9392)
sudo gvm-check-setup # Verify the install is healthy before scanning
```

- Create a **Target** (host/range) and a **Task** (target + scan config) from the web UI, then start the task the same way a Nessus scan is launched.
- Results follow the same severity/CVSS-driven structure as Nessus, so triage and prioritization work identically regardless of which scanner produced the finding.

> OpenVAS's community feed updates on a slightly different cadence than Nessus's commercial feed — cross-check a critical finding against a second source (vendor advisory, `nmap --script vuln`) before treating it as fully confirmed.

---

## 5. Nikto — Web Server Vulnerability Scanning

Nikto is a lightweight, fast command-line scanner purpose-built for web servers, useful either as a quick first pass or to complement a full Nessus/OpenVAS sweep on HTTP(S) targets.

```bash
nikto -h target-ip                          # Basic scan against a host
nikto -h target-ip -p 80,443                # Scan specific ports
nikto -h https://target-ip -ssl             # Force SSL/TLS scanning
nikto -h target-ip -o report.html -Format html   # Save output as an HTML report
nikto -h target-ip -Tuning 9                # Tuning option 9 = reverse against dangerous file checks
nikto -h target-ip -evasion 1               # Basic IDS evasion technique
nikto -h target-ip -useproxy http://127.0.0.1:8080  # Route scan through Burp/proxy for inspection
```

Nikto flags outdated server software, dangerous default files/scripts, missing security headers, and known-vulnerable CGI/plugin paths — treat every hit as a **lead to verify**, not a confirmed finding.

> **Note:** Nikto is intentionally noisy (unencrypted, unthrottled by default) and easily logged/blocked by a WAF — it is a triage tool for a quick web-server picture, not a stealth tool.

---

## 6. CVSS v3 Scoring & Prioritization

CVSS (Common Vulnerability Scoring System) v3 gives every vulnerability a 0.0–10.0 numeric score so findings from different scanners and sources can be ranked on the same scale.

| Score Range | Severity |
|---|---|
| 0.0 | None |
| 0.1 – 3.9 | Low |
| 4.0 – 6.9 | Medium |
| 7.0 – 8.9 | High |
| 9.0 – 10.0 | Critical |

- The score is derived from **Base metrics** (Attack Vector, Attack Complexity, Privileges Required, User Interaction, Scope, and Confidentiality/Integrity/Availability impact) that describe the vulnerability itself, independent of any specific environment.
- Optional **Temporal** and **Environmental** metric groups adjust the base score for exploit maturity/availability and for the specific target environment — most scanner reports show the Base score unless explicitly configured otherwise.
- **Prioritization in practice:** work Critical and High findings first, especially anything remotely exploitable with no authentication required (low Attack Complexity, no Privileges Required) — those combine the highest impact with the lowest barrier to exploitation.
- A high CVSS score does not automatically mean "exploit this first" — a Critical finding on a host outside the actual attack path is lower practical priority than a High finding on a host that pivots toward the objective.

> **Note:** CVSS measures the *vulnerability's* severity, not the finding's *confidence* — a Critical-scored result that turns out to be a false positive (see Section 7) has zero real priority regardless of its number.

---

## 7. False Positive Triage

Automated scanners over-report by design — they favor flagging anything that *might* be a match over silently missing a real vulnerability, which pushes the burden of confirmation onto the tester.

**Why scanners over-report:**

- Version/banner-based detection flags a vulnerable *version string* even when the vendor backported a patch without bumping the displayed version.
- Unauthenticated scans infer patch level from network behavior instead of querying the host directly, which is inherently less reliable than a credentialed check.
- Generic plugin signatures (e.g., a header pattern or response length) can match innocuous configurations that happen to look similar.

**How to manually confirm before trusting a finding:**

- [ ] Cross-reference the flagged CVE/version against the vendor's changelog or security advisory to confirm the patch status.
- [ ] Re-check with a **credentialed** scan where possible — authenticated results are far more reliable than banner-based inference.
- [ ] Cross-check the same host/service with a second tool (e.g., confirm a Nessus finding with `nmap --script vuln` or a manual version check) — agreement across independent tools raises confidence.
- [ ] For a specific well-known issue, run a targeted NSE script rather than relying on the generic `vuln` category sweep, e.g. `nmap --script smb-vuln-ms17-010 -p 445 target-ip` (see `nmap-cheatsheet-professional.md` for the full NSE section).
- [ ] Where safe and in-scope, attempt a minimal proof-of-concept check that confirms the condition without causing impact (e.g., a harmless request that only a vulnerable configuration would answer a specific way).
- [ ] Document *how* each finding was validated (or why it was downgraded/dismissed) — an unvalidated Critical finding left in a report undermines the credibility of the whole assessment.

> Treat `nmap --script vuln` as a lightweight, fast first pass rather than a replacement for a full scanner — it's convenient because it runs in the same tool already used for enumeration, but its NSE vuln script coverage is narrower than a dedicated Nessus/OpenVAS plugin feed.

---

## 8. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Start Greenbone/OpenVAS services | `sudo gvm-start` |
| Verify OpenVAS install health | `sudo gvm-check-setup` |
| Basic Nikto scan | `nikto -h target-ip` |
| Nikto on specific ports | `nikto -h target-ip -p 80,443` |
| Nikto forced SSL scan | `nikto -h https://target-ip -ssl` |
| Save Nikto report as HTML | `nikto -h target-ip -o report.html -Format html` |
| Nikto through a proxy (e.g. Burp) | `nikto -h target-ip -useproxy http://127.0.0.1:8080` |
| Full nmap vuln-category sweep | `nmap --script vuln target-ip` |
| Targeted NSE vuln check (example) | `nmap --script smb-vuln-ms17-010 -p 445 target-ip` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
