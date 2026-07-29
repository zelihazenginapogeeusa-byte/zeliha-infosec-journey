# BTL1 Incident Response Exam Checklist

A run-through-it-in-order checklist for the BTL1 exam itself — the exam is a report-based investigation exercise, so the bar isn't "did you find the answer," it's "can you prove it and explain it clearly."

---

## 1. Before You Start

- [ ] Read the entire scenario/brief first, end to end, before touching any tool — note exactly what you're being asked to determine (initial access vector? scope of compromise? timeline? IOCs? containment recommendation?).
- [ ] Set up a findings document with a section per question/objective — structure it before you start digging.
- [ ] Note what tools/data sources you actually have access to (SIEM, PCAP, memory image, disk image, log bundle) — your investigation path depends entirely on what's provided.
- [ ] Start an IOC tracker immediately (IPs, hashes, domains, usernames, filenames) — you'll cross-reference these constantly across every tool.

---

## 2. Investigation Methodology

1. **Establish the timeline anchor** — find the first suspicious event (phishing email, alert trigger, anomalous login) and work outward from it in both directions (what led to it, what happened after).
2. **Identify initial access** — phishing? exposed service? valid credential misuse? Look at `phishing-cheatsheet.md` and `attack-types-detection-cheatsheet-professional.md` for the signal patterns.
3. **Trace lateral movement / escalation** — correlate authentication logs, process creation events, and network connections across hosts.
4. **Identify the full scope** — every host, account, and asset touched, not just the first one found. Exam grading rewards completeness, not just finding *an* answer.
5. **Extract IOCs** — hashes, IPs, domains, filenames, registry keys, mutexes — anything that could be used to detect this activity elsewhere.
6. **Map to MITRE ATT&CK** — tie each stage of the incident to a tactic/technique ID; this is usually an explicit grading criterion.
7. **Recommend containment/remediation** — specific and actionable ("isolate host X, reset credentials for account Y, block IOC Z at the firewall"), not generic advice.

---

## 3. Query & Tool Quick-Jumps

- SIEM correlation → [`kql-and-spl-query-reference-cheatsheet.md`](kql-and-spl-query-reference-cheatsheet.md)
- Windows Event ID lookups → [`windows-event-id-reference-cheatsheet-professional.md`](windows-event-id-reference-cheatsheet-professional.md)
- Memory/disk artifacts → [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md) and [`linux-forensics-and-artifact-analysis-cheatsheet.md`](linux-forensics-and-artifact-analysis-cheatsheet.md)
- Packet capture review → [`wireshark-advanced-cheatsheet.md`](wireshark-advanced-cheatsheet.md)
- IOC reputation checks → [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md)

---

## 4. Time Management

- Don't try to manually eyeball every log line — build a filtered/correlated view (SIEM query or timeline tool) as early as possible, then work from that.
- If a question is graded independently of the others, don't let getting stuck on one block progress on the rest — note your best working hypothesis and move on, come back if time allows.
- Reserve real time at the end purely for write-up and proofreading — a correct finding that's poorly explained loses points a clearly-written near-miss wouldn't.

---

## 5. Common Pitfalls

| Pitfall | Fix |
|---|---|
| Reporting the first suspicious thing found as "the answer" without confirming scope | Always ask "what else did this touch?" before finalizing |
| IOCs listed without context (just a raw IP with no explanation) | State what each IOC is, where it was found, and what it indicates |
| Skipping the MITRE ATT&CK mapping | Treat it as a required checklist item, not optional flavor |
| Vague remediation ("improve monitoring") | Always give a specific, actionable recommendation tied to what actually happened |

---

## 6. Report / Submission Checklist

- [ ] Every question in the scenario answered explicitly, in order.
- [ ] Every claim backed by a specific artifact (log line, query result, screenshot) — not just asserted.
- [ ] Timeline presented clearly (a simple table: timestamp → event → source is usually enough).
- [ ] IOC list is complete, deduplicated, and each entry has stated context.
- [ ] MITRE ATT&CK technique IDs included for each stage of the attack.
- [ ] Remediation/containment recommendations are specific to this incident, not generic boilerplate.

---

*Exam-day companion to the Blue-Team cheat sheets in this folder — this one is the "how to run the exam itself" checklist, the rest are the "how the tools/techniques work" reference.*
