# Penetration Testing Methodology Cheat Sheet

Before touching a single tool, an engagement needs to be classified — what **type** of assessment this is, what perspective the tester starts from, and which industry framework governs it. This document covers those higher-level engagement models for the eJPT host/network pentest module; for PTES's specific phases and the finding/report template, see `assessment-methodology-report-writing-cheatsheet-professional.md`.

---

## Table of Contents

1. [Types of Security Assessment](#1-types-of-security-assessment)
2. [Testing Perspectives / Box Models](#2-testing-perspectives--box-models)
3. [Industry Methodology Frameworks](#3-industry-methodology-frameworks)
4. [Structuring an eJPT Practical Exam Approach](#4-structuring-an-ejpt-practical-exam-approach)
5. [Common Methodology Mistakes](#5-common-methodology-mistakes)
6. [Quick Reference](#6-quick-reference)

---

## 1. Types of Security Assessment

"Penetration test" is often used loosely, but clients and certifications distinguish several distinct assessment types by goal, depth, and stealth requirement.

| Type | Goal | Stealth Level | Typical Duration | Deliverable |
|---|---|---|---|---|
| **Vulnerability Assessment (VA)** | Identify and list vulnerabilities, no exploitation | None — scanning is overt | 1-3 days | Scored/prioritized vulnerability list |
| **Penetration Test** | Prove exploitability and business impact of vulnerabilities | Low-to-moderate — some evasion, but not the focus | 1-2 weeks | Findings report with evidence + remediation (see report cheat sheet) |
| **Red Team Engagement** | Test detection/response capability end-to-end, emulate a real adversary | High — active evasion is a core objective | Weeks to months | Attack narrative + detection gap analysis |
| **Purple Team Exercise** | Collaboratively test and tune detections in real time | None — blue team is informed and watching live | Days | Joint report on detection coverage per technique |

> **eJPT maps most closely to the Penetration Test row** — the exam expects you to exploit and prove impact, not just scan and list findings, but stealth/evasion is not the graded objective the way it is in a red team engagement.

---

## 2. Testing Perspectives / Box Models

How much information the tester is given up front changes both the approach and how representative the results are of a real attacker.

| Model | Starting Information | When Used |
|---|---|---|
| **Black Box** | None — only a company name/target scope, as an external attacker would have | Most realistic simulation of an external threat actor; slower, more recon-heavy |
| **Grey Box** | Partial — e.g. a standard user account, network diagram, or internal IP range | Most common in practice; balances realism with efficient use of engagement time |
| **White Box** | Full — source code, credentials, architecture docs | Deep, thorough assessments (e.g. code review-driven testing); fastest to find issues, least realistic as an attack simulation |

> eJPT practical labs are effectively **grey box** — you're typically dropped directly onto a network segment with a defined target range, skipping the black-box OSINT/external-recon phase in favor of testing the internal exploitation and privesc skill set directly.

---

## 3. Industry Methodology Frameworks

A one-line orientation to the frameworks a pentester should recognize by name — which focus area each one owns, so the right one gets referenced in scoping conversations and reports.

| Framework | Focus Area |
|---|---|
| **PTES** (Penetration Testing Execution Standard) | End-to-end engagement lifecycle, pre-engagement through reporting — see `assessment-methodology-report-writing-cheatsheet-professional.md` for the full phase breakdown and report template |
| **OWASP Testing Guide** | Web application-specific testing methodology, organized by vulnerability category (injection, auth, session management) |
| **OSSTMM** (Open Source Security Testing Methodology Manual) | Metrics-driven, operational security testing across all channels (network, physical, human/social) |
| **NIST SP 800-115** | US government/enterprise-oriented technical guide to information security testing and assessment |

**Picking one in practice:**

- A web-heavy scope → lean on the **OWASP Testing Guide**'s category breakdown alongside whatever overall lifecycle framework (usually PTES) governs the engagement.
- A government/enterprise client with compliance requirements → **NIST SP 800-115** is often mandated by contract, not just chosen.
- A scope that includes physical/social channels alongside network testing → **OSSTMM**'s metrics-driven approach covers that breadth better than PTES alone.
- Most eJPT-style network/host engagements → **PTES** end to end, since it's the most widely adopted general-purpose framework and the one this collection's report cheat sheet is built around.

> This document only tracks *which framework applies when* — the actual phase-by-phase methodology and finding write-up template live in `assessment-methodology-report-writing-cheatsheet-professional.md`; don't duplicate that content here.

---

## 4. Structuring an eJPT Practical Exam Approach

Because eJPT is graded Q&A-style against flags/answers rather than a submitted report, the practical value of "methodology" here is staying organized enough to answer questions accurately under time pressure.

```
1. Recon           — nmap sweep of the whole range (see nmap-cheatsheet-professional.md)
2. Per-host enum    — service-specific enumeration (SMB, web, etc.) for every live host
3. Exploitation     — target the most promising vulnerability per host first
4. Post-exploitation — privesc, loot, pivot; keep notes as each step happens
5. Repeat per host  — move to the next target, same order
```

- **Recon:** a full-range `nmap` sweep first to map every live host and open port before diving deep on any single target.
- **Enumeration:** service-specific tools per host — SMB, web, FTP, etc. — feeding into the relevant cheat sheet for that service.
- **Exploitation:** establish a foothold, catching the callback with `netcat-reverse-shell-cheatsheet-professional.md` or a Metasploit handler.
- **Notes as you go:** record IP, open ports, service versions, credentials found, and flags captured *immediately* — not from memory afterward.

> Keep a running scratch file (even just a text file, one section per host) with IP/hostname, open ports, credentials found, and flag values as you go — eJPT questions frequently reference details from earlier steps, and re-enumerating a host to recover a detail you didn't record wastes exam time.

---

## 5. Common Methodology Mistakes

Patterns that cost time or produce false conclusions, regardless of how strong the individual tool skills are.

- [ ] **Skipping enumeration and jumping straight to exploitation** — running an exploit against an unconfirmed vulnerability wastes time and can alert defenses for nothing.
- [ ] **Not tracking scope** — testing an IP that looked reachable but wasn't actually in scope creates real legal/engagement risk, not just a wasted step.
- [ ] **Not taking notes as you go** — reconstructing "what did I find on host X" after the fact is slower and less accurate than recording it at discovery time, and makes any later write-up far harder.
- [ ] **Treating every engagement the same way** — running a red-team-style slow, stealthy approach on a time-boxed VA (or vice versa) wastes the engagement's actual objective.
- [ ] **Ignoring the box model** — over-relying on external-recon techniques in a grey-box internal test (or under-using provided credentials) burns time better spent elsewhere.

---

## 6. Quick Reference

A compact lookup mapping each assessment type to the situation it's actually used for.

| Assessment Type | Typical Use Case |
|---|---|
| Vulnerability Assessment | Routine compliance scanning, quarterly hygiene checks |
| Penetration Test (Black Box) | Simulate an external attacker with zero insider knowledge |
| Penetration Test (Grey Box) | Standard internal engagement — most eJPT-style labs |
| Penetration Test (White Box) | Deep source-available review, fastest path to thorough coverage |
| Red Team | Test detection/response maturity against a realistic adversary |
| Purple Team | Tune specific detections collaboratively with the blue team |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
