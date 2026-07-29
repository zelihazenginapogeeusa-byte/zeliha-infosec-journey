# Incident Response Lifecycle (PICERL) Cheat Sheet

The framework that ties all of BTL1's technical modules (phishing, SIEM, DFIR, threat intel) together into a single process: the **NIST-based Incident Response lifecycle**. Every piece of evidence you gather in the exam ultimately lands in one phase of this process.

---

## Table of Contents

1. [What Is PICERL](#1-what-is-picerl)
2. [1. Preparation](#2-1-preparation)
3. [2. Identification](#3-2-identification)
4. [3. Containment](#4-3-containment)
5. [4. Eradication](#5-4-eradication)
6. [5. Recovery](#6-5-recovery)
7. [6. Lessons Learned](#7-6-lessons-learned)
8. [Phase → Tool Mapping](#8-phase--tool-mapping)
9. [Incident Report Template](#9-incident-report-template)
10. [Quick Reference](#10-quick-reference)

---

## 1. What Is PICERL

Based on NIST SP 800-61, a 6-phase process for tracking a security incident from start to finish:

```
Preparation → Identification → Containment → Eradication → Recovery → Lessons Learned
```

> The process is **cyclical** — findings from the Lessons Learned phase feed back into the next round of Preparation.

---

## 2. 1. Preparation

The work done **before** an incident occurs — the phase that saves the most time once an incident hits.

- [ ] Is the IR plan and communication tree (who to call, in what order) ready?
- [ ] Are log sources (SIEM, endpoint, firewall) being collected correctly?
- [ ] Are playbooks (for phishing, ransomware, data breach scenarios) written down?
- [ ] Is the forensic toolkit (Volatility, Autopsy, write-blocker) ready and tested?
- [ ] Does the team run tabletop exercises?

---

## 3. 2. Identification

Confirming whether something is actually an **incident**.

- [ ] What's the detection source? (a SIEM alert, a user report, a third-party notification)
- [ ] **Distinguish event from incident** — not every alert is an incident, it might be a false positive.
- [ ] What's the scope of impact? (how many systems, what data, which users)
- [ ] Establish an initial timeline — when did the initial compromise occur?
- [ ] Assign severity/priority.

> **The triage workflow in `phishing-cheatsheet.md`** (Headers → Indicators → Sandbox/VT → Verdict) is essentially a subset of this phase.

---

## 4. 3. Containment

Stopping the incident from **spreading** — without destroying evidence yet.

| Type | Example |
|---|---|
| **Short-term** | Isolating the affected system from the network, adding a firewall rule, disabling an account |
| **Long-term** | Temporary access restrictions on unaffected systems, improved segmentation |

- [ ] **Collect evidence first, then isolate** where possible — avoid losing RAM/log data.
- [ ] Prefer **isolating from the network** over shutting the system down (so memory evidence isn't lost).
- [ ] Contain quietly where possible, so the attacker doesn't notice and take destructive action.

---

## 5. 4. Eradication

Completely removing the **root cause** of the threat from the environment.

- [ ] Clean the malware/backdoor, or re-image the system (usually the safest option).
- [ ] Patch the exploited vulnerability (e.g. update Drupal, close an open SMB share).
- [ ] Reset all compromised credentials (not just the obviously affected ones — every potentially affected account).
- [ ] Remove persistence mechanisms (Run keys, scheduled tasks, newly created accounts).
- [ ] **Eradication isn't complete until the root cause is found** — cleaning only the symptom leads to reinfection.

---

## 6. 5. Recovery

Bringing systems back to normal operation **safely**.

- [ ] Bring systems back onto the network gradually, with heightened monitoring.
- [ ] Confirm the system is clean (re-scan, verify hashes).
- [ ] Set a phased return timeline — not everything at once, prioritized.
- [ ] Monitor closely for signs of reinfection for a **defined period** (e.g. 30 days).

---

## 7. 6. Lessons Learned

The phase for improving the process **after** the incident closes.

- [ ] Hold a **Post-Incident Review (PIR)** meeting — with all stakeholders.
- [ ] Review the timeline: how long did detection take (MTTD), how long did containment take (MTTC)?
- [ ] What went well, what didn't? Was there a gap in the playbook?
- [ ] Feed findings back into the **Preparation** phase — a new detection rule, an updated playbook, additional training.
- [ ] Publish a formal **Incident Report** (see the template below).

> Skipping this phase means the team starts from scratch the next time a similar incident occurs — it's the most overlooked but most valuable phase of the IR process.

---

## 8. Phase → Tool Mapping

Ties back to your own cheat sheet collection:

| Phase | Related tool/cheat sheet |
|---|---|
| Identification | `siem-splunk-elk-cheatsheet-professional.md`, `phishing-cheatsheet.md`, `windows-event-id-reference-cheatsheet-professional.md` |
| Containment/Eradication | `deepblue-cli-cheatsheet-professional.md`, `wireshark-advanced-cheatsheet.md` |
| Evidence collection (every phase) | `volatility-autopsy-forensics-cheatsheet-professional.md` |
| Root cause analysis | `malware-analysis-yara-cheatsheet-professional.md`, `threat-intelligence-mitre-attack-cheatsheet-professional.md` |

---

## 9. Incident Report Template

A ready-to-fill skeleton for the incident report you'd submit at the close of the Lessons Learned phase.

```markdown
## Incident Summary
- Incident ID / Date:
- Severity:
- Affected systems/users:

## Timeline
| Time | Event |
|---|---|
| ... | Initial compromise |
| ... | Detection |
| ... | Containment began |
| ... | Eradication completed |
| ... | Recovery completed |

## Root Cause
[Root cause — which vulnerability/mistake/missing control was exploited]

## Actions Taken
[Steps taken during containment, eradication, and recovery]

## Indicators of Compromise (IOC)
[IOC list, in defanged format]

## Lessons Learned & Recommendations
[Process/technology/training improvement recommendations]
```

---

## 10. Quick Reference

A single-page lookup for every phase covered above.

| Phase | One-line summary | Key metric |
|---|---|---|
| Preparation | Pre-incident readiness | — |
| Identification | Is it an incident, what's the scope | **MTTD** (Mean Time to Detect) |
| Containment | Stop the spread | **MTTC** (Mean Time to Contain) |
| Eradication | Remove the root cause | — |
| Recovery | Return to normal, safely | **MTTR** (Mean Time to Recover) |
| Lessons Learned | Improve the process | Post-Incident Review |

---

*Prepared as a reference for BTL1 Incident Response and general SOC operations (based on NIST SP 800-61).*
