# AI-Enhanced Pentesting Cheat Sheet

AI-enhanced pentesting refers to the practical use of large language models (LLMs) and other generative AI tools as a productivity layer wrapped around the standard penetration testing workflow — not a new methodology and not a replacement for the hands-on skills covered elsewhere in this collection. This document covers where generative AI genuinely speeds up a pentester's day-to-day work (triage, code review, scripting, report drafting) and where it introduces real risk (hallucinated output, prompt injection, data exposure); it is written as general, tool-agnostic practitioner guidance rather than exam-specific content tied to any particular course or product. For the underlying methodology this layer sits on top of, see `penetration-testing-methodology-cheatsheet-professional.md`; for the report structure AI-assisted drafts still have to conform to, see `assessment-methodology-report-writing-cheatsheet-professional.md`.

---

## Table of Contents

1. [What "AI-Enhanced Pentesting" Actually Means](#1-what-ai-enhanced-pentesting-actually-means)
2. [Recon & Enumeration Triage](#2-recon--enumeration-triage)
3. [Exploitation Support & Scripting Assistance](#3-exploitation-support--scripting-assistance)
4. [Report Writing Support](#4-report-writing-support)
5. [Risks: Prompt Injection, Hallucination & Data Exposure](#5-risks-prompt-injection-hallucination--data-exposure)
6. [Practical Checklist for Responsible AI Use](#6-practical-checklist-for-responsible-ai-use)
7. [Quick Reference](#7-quick-reference)

---

## 1. What "AI-Enhanced Pentesting" Actually Means

This section frames what "AI-enhanced pentesting" realistically means in 2025-2026 — a set of workflow accelerants layered on top of the standard methodology, not a new attack technique or a substitute for hands-on skill.

| Aspect | Realistic 2025-2026 Picture |
|---|---|
| **What it is** | A productivity layer: faster triage, drafting, and explanation on top of the tools and methodology you already use |
| **What it isn't** | A replacement for enumeration, manual verification, exploit development skill, or the tester's own judgment |
| **Where it helps most** | High-volume, low-judgment tasks — summarizing scan output, drafting boilerplate, explaining unfamiliar syntax |
| **Where it helps least (or hurts)** | Live target interaction, novel exploit development, scope/legal judgment calls, anything requiring ground-truth accuracy |
| **Skill relationship** | Layered on top of the core methodology (`penetration-testing-methodology-cheatsheet-professional.md`) — it speeds up someone who already knows the fundamentals and offers little to someone who doesn't |

> **Note:** Treat AI output the same way you'd treat a junior analyst's first draft — a useful starting point, never a final answer accepted without your own verification. Every use case below assumes that habit.

---

## 2. Recon & Enumeration Triage

This section covers using AI to triage large volumes of recon and enumeration output — deciding what's worth investigating first — rather than to run the recon itself.

| Use Case | Example | Caution |
|---|---|---|
| Summarizing a large `nmap` sweep | Ask what looks most interesting across dozens of hosts/ports before deciding where to dig in first — see `nmap-cheatsheet-professional.md` for the scans themselves | The summary can miss or misrank a service; skim the raw output yourself for anything scoped as high-value |
| Triaging `gobuster`/directory-brute output | Flag likely-interesting paths (admin panels, backup files, config dumps) out of hundreds of hits | Wordlist hits are just candidates — every flagged path still needs manual confirmation |
| Parsing verbose vulnerability scanner output | Cluster findings by likely severity/exploitability to decide manual verification order | The AI is prioritizing, not validating — a "low priority" flag doesn't mean "not exploitable" |
| Making sense of an unfamiliar service banner | Ask what a banner/version string typically indicates before deciding how to enumerate further | Banners can be spoofed or outdated; confirm the actual version with direct interaction where safe |

> **Risk:** Enumeration output routinely contains attacker-influenced or arbitrary strings — HTTP headers, page titles, banners, filenames — that could be crafted to manipulate an AI summarizer ("prompt injection"). Treat scanned or scraped content as untrusted input, and don't let an AI-generated summary silently steer your next command without your own sanity check against the raw output.

---

## 3. Exploitation Support & Scripting Assistance

This section covers using AI to explain unfamiliar exploit code, services, or protocols before touching a live target, and to draft or review small automation and parsing scripts — not to generate novel exploits or run unverified code against real systems.

| Use Case | Appropriate | Not Appropriate |
|---|---|---|
| Understanding a PoC before running it | Ask for a line-by-line explanation of what an unfamiliar exploit script does before executing it | Running a PoC because "the AI said it should work," without reading it yourself first |
| Learning an unfamiliar protocol/service | Ask for a plain-language explanation of an obscure protocol before you start enumerating/interacting with it live | Asking AI to interact with the live target directly on your behalf |
| Drafting a one-off script | Draft/review a quick Python script to parse tool output, dedupe a host list, or automate a repetitive step | Deploying an AI-generated script against a target without reading and testing it first |
| Exploit development | Use AI to explain a known, public exploit technique or CVE write-up | Asking AI to "write a zero-day" or invent a novel exploit chain — this is not a reliable use of the tool and isn't what "AI-enhanced" means here |

> **Risk:** LLMs regularly produce plausible-looking but wrong commands, flags, or exploit parameters — a hallucinated `nmap` flag, a nonexistent Metasploit module option, a subtly wrong offset in a buffer-overflow PoC. Always verify against the tool's actual `--help`/man page, official docs, or source before running anything against a live target — an authorized engagement window is not the place to debug a hallucinated flag.

---

## 4. Report Writing Support

This section covers using AI to draft finding descriptions and remediation language from your own already-verified raw notes and evidence, never as a source of new facts — see `assessment-methodology-report-writing-cheatsheet-professional.md` for the template and severity rules any AI-assisted draft still has to follow.

| Use Case | Do | Don't |
|---|---|---|
| Finding description drafts | Feed your own verified command output, screenshots, and notes in, and ask for a clean first-draft description | Ask AI to "write a finding about X" without giving it your actual evidence as the source |
| Remediation language | Ask for standard remediation phrasing for a known issue type, then check it fits the specific configuration observed | Accept generic remediation text that doesn't match what you actually found |
| Clarity/grammar pass | Use AI to tighten wording, fix grammar, or improve readability of a draft you already wrote | Let stylistic edits quietly change the technical meaning of a sentence |
| Executive summary drafting | Draft a plain-language summary from your own finding list and severity counts | Let the AI infer business impact you haven't actually assessed |

> **Risk:** An AI-drafted finding can sound confident and well-written while being factually wrong or overstated relative to your actual evidence. Fact-check every AI-drafted sentence against your own raw notes, command output, and screenshots before it goes into a report a client will read — the report is the one artifact most clients actually judge the engagement by.

---

## 5. Risks: Prompt Injection, Hallucination & Data Exposure

This section consolidates the three risk categories that matter most when using AI tools on a live engagement, beyond the workflow-specific cautions already noted above.

| Risk | What It Looks Like | Mitigation |
|---|---|---|
| **Prompt injection** | Scanned/scraped content (page text, headers, filenames) contains text crafted to manipulate an AI summarizer's output or instructions | Treat all scanned/scraped content as untrusted input; review AI summaries before acting on them, don't let them drive commands unchecked |
| **Hallucinated commands/output** | Plausible-looking but incorrect flags, module names, syntax, or "facts" about a tool or protocol | Verify every AI-suggested command against the tool's own `--help`/man page or official docs before running it |
| **Confidential data exposure** | Pasting scope details, live credentials, internal hostnames/IPs, or other target data into a public or hosted AI tool | Never do this without an explicit, written data-handling agreement that specifically covers that use — see below |
| **Over-reliance / skill atrophy** | Using AI to substitute for actually understanding a technique, rather than to explain or accelerate it | Use AI to explain and speed up techniques you already understand or are actively learning, not to skip learning them |

> **Risk:** The hard rule: never paste client-confidential scope details, live credentials, internal hostnames/IPs, or any other target-identifying data into a public or hosted AI tool unless there is an explicit, written data-handling agreement in place that specifically covers that use. If there's any doubt, don't paste it — describe the situation generically (e.g., "a Windows host with an outdated SMB service") instead of using real identifiers.

---

## 6. Practical Checklist for Responsible AI Use

This section is a short, engagement-ready checklist for using AI tools without creating unnecessary risk or shipping unverified content.

- [ ] Confirm the engagement's RoE/data-handling agreement explicitly permits AI tool use before pasting anything target-related into one.
- [ ] Strip or redact hostnames, IPs, credentials, and client names before pasting any output into a public AI tool.
- [ ] Treat every AI-suggested command or flag as unverified until checked against the tool's own docs.
- [ ] Treat AI summaries of scanned/scraped content as a starting point, not ground truth — spot-check against the raw output.
- [ ] Never let AI-drafted report language ship without cross-checking it against your own verified evidence.
- [ ] Note in your own working notes where AI assistance was used, in case a client or reviewer asks about your process.
- [ ] Use AI to go faster at a technique you already understand — don't use it to skip learning the technique in the first place.

---

## 7. Quick Reference

A single summary of the Do/Don't boundary for each workflow stage AI tools realistically touch on an engagement.

| Use Case | Do | Don't |
|---|---|---|
| **Recon/Enumeration Triage** | Use AI to summarize/prioritize large scan output and decide what to check first | Trust a summary without spot-checking the raw output yourself |
| **Exploitation Support** | Use AI to explain unfamiliar exploit code, services, or protocols before touching a live target | Ask AI to generate novel exploits or run its suggested payloads unverified against a live target |
| **Scripting Assistance** | Use AI to draft/review small parsing or automation scripts | Run AI-generated scripts against a target without reading and testing them first |
| **Report Writing** | Use AI to draft finding/remediation language from your own verified notes and evidence | Let AI invent details, impact, or evidence not present in your raw notes |
| **Data Handling** | Redact/strip target-identifying data before using any public or hosted AI tool | Paste scope, credentials, or hostnames/IPs into a public AI tool without an explicit data-handling agreement |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
