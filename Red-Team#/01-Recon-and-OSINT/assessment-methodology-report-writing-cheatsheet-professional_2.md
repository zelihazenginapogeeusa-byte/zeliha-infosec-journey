# Assessment Methodology & Report Writing Cheat Sheet

No matter how good the technical work is, the **report** is the one artifact the client/assessor actually sees. This document covers PTES methodology and the report structure expected in eJPT/BTL1.

---

## Table of Contents

1. [PTES (Penetration Testing Execution Standard) Phases](#1-ptes-penetration-testing-execution-standard-phases)
2. [Scoping & Rules of Engagement](#2-scoping--rules-of-engagement)
3. [Finding Write-Up Template](#3-finding-write-up-template)
4. [Severity / Risk Rating](#4-severity--risk-rating)
5. [Executive Summary Template](#5-executive-summary-template)
6. [Full Report Skeleton](#6-full-report-skeleton)
7. [eJPT vs BTL1 Report Differences](#7-ejpt-vs-btl1-report-differences)
8. [Common Mistakes](#8-common-mistakes)

---

## 1. PTES (Penetration Testing Execution Standard) Phases

```
Pre-Engagement → Intelligence Gathering → Threat Modeling →
Vulnerability Analysis → Exploitation → Post-Exploitation → Reporting
```

| Phase | Content |
|---|---|
| **Pre-Engagement** | Scoping, signing the RoE, communication plan, emergency procedure |
| **Intelligence Gathering** | OSINT (`osint-cheatsheet.md`), passive/active recon |
| **Threat Modeling** | Which asset is most critical, what's the most likely attacker/scenario |
| **Vulnerability Analysis** | Scanning (nmap, nikto, gobuster) + manual verification |
| **Exploitation** | Proving the vulnerability (Metasploit, manual exploit) |
| **Post-Exploitation** | Privesc, lateral movement, assessing data value — but **never** stepping outside scope |
| **Reporting** | Documenting findings, evidence, and recommendations |

---

## 2. Scoping & Rules of Engagement

What needs to be nailed down before an engagement starts:

- [ ] **Target IP/domain/application list** — which systems are in scope, which are explicitly excluded
- [ ] **Test type** — black box / grey box / white box
- [ ] **Allowed techniques** — is DoS testing permitted, is social engineering included, is physical testing included
- [ ] **Testing window** — which hours (to minimize impact on production)
- [ ] **Emergency contact** — who to call if you take down a critical system
- [ ] **Data handling rules** — how captured sensitive data is stored/destroyed

---

## 3. Finding Write-Up Template

Use a consistent format for every finding:

```markdown
### [Finding Title] — e.g. Outdated Drupal Installation Leads to Remote Code Execution

**Severity:** Critical
**CVSS Score:** 9.8 (if applicable)
**Affected Asset(s):** 10.0.2.4 (web.internal.local)

**Description:**
The target is running Drupal 7.x, which is vulnerable to CVE-2018-7600
(Drupalgeddon2). This vulnerability allows unauthenticated remote code
execution.

**Evidence:**
[Screenshot / command output / PoC]

**Impact:**
An attacker can execute code on the web server as www-data, which can
lead to database access and potential full system compromise.

**Recommendation:**
Upgrade the Drupal core to the latest security patch. As an interim
measure, add a WAF rule to block CVE-2018-7600 signatures.

**References:**
- CVE-2018-7600
- https://www.drupal.org/sa-core-2018-002
```

---

## 4. Severity / Risk Rating

| Level | Description | Example |
|---|---|---|
| **Critical** | Full system compromise without authentication | Unauthenticated RCE |
| **High** | Significant data/access loss, but requires one more step | SQL injection leading to data exfiltration |
| **Medium** | Not directly exploitable but widens the attack surface | Missing security headers, information disclosure |
| **Low** | Minimal impact, best-practice violation | Verbose error messages |
| **Informational** | Not a risk but worth noting | An old but non-exploitable version disclosure |

> If you're using a CVSS score (CVSS 3.1 Calculator), align the Base Score with the severity band: 9.0–10.0 Critical, 7.0–8.9 High, 4.0–6.9 Medium, 0.1–3.9 Low.

---

## 5. Executive Summary Template

For a management-level reader — minimal technical jargon, focused on business impact.

```markdown
## Executive Summary

During the penetration test conducted for [Company Name], [X] findings
were identified: [N] Critical, [N] High, [N] Medium, [N] Low. The most
critical finding is [summary of the core vulnerability and its
business impact].

If left unremediated, these findings could allow an attacker to
[risk summary, e.g. "access the customer database and exfiltrate
sensitive data"]. As a priority action, [summary of the top
recommendation] is advised.
```

---

## 6. Full Report Skeleton

```
1. Cover Page (date, version, confidentiality notice)
2. Executive Summary
3. Scope & Methodology (referencing the PTES phases)
4. Risk Summary (severity distribution chart/table)
5. Detailed Findings (ordered by severity, most critical first)
6. Appendices (raw scan output, tools used)
```

---

## 7. eJPT vs BTL1 Report Differences

| | eJPT | BTL1 |
|---|---|---|
| **Focus** | Attack chain: recon → exploit → privesc → proof | Analysis chain: evidence → IOC → verdict → recommendation |
| **Format** | Usually a Q&A-style practical exam, not a freeform report | A structured report submission is expected (24-hour practical + written write-up) |
| **Evidence type** | Flags, command output, screenshots | Log/header/hash evidence, defanged IOC list |
| **Tone/language** | Technical, step-by-step | Technical + justification written in a SOC-analyst voice |

---

## 8. Common Mistakes

- [ ] **Unsupported claims** — saying "there's a SQL injection" isn't enough, show the request/response.
- [ ] **Over/under-stating severity** — stay consistent with CVSS/impact analysis.
- [ ] **Skipping remediation** — every finding needs a concrete, actionable recommendation.
- [ ] **Including out-of-scope findings** — testing unauthorized systems can create legal exposure.
- [ ] **Pasting raw scan output into the report body** — that belongs in the appendix; the body should stay readable.

---

*Prepared as a reference for the methodology/reporting components of eJPT and BTL1.*
