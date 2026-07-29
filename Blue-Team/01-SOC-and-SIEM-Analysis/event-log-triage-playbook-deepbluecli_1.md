# Event Log Triage Playbook (DeepBlueCLI)

A scenario-driven guide to what to do with DeepBlueCLI's output — for installation, syntax, and flags themselves, see [`deepblue-cli-cheatsheet-professional.md`](deepblue-cli-cheatsheet-professional.md). This document is about **triaging the findings it hands you**, since DeepBlueCLI surfaces candidate anomalies, it doesn't make the escalation decision for you.

---

## Phase 0 — Running It (When and On What)

1. Run DeepBlueCLI against `Security`, `System`, and `PowerShell/Operational` logs at minimum — a single-log run misses cross-log correlation that often matters most (e.g., a suspicious logon in `Security` paired with suspicious PowerShell in the `PowerShell/Operational` log around the same timestamp).
2. Run it as an **early triage pass**, not a final answer — treat every finding as a lead to manually verify, not a confirmed incident on its own.
3. If investigating a specific host as part of a broader incident, run it there first before deciding whether to widen the log-collection scope to other hosts.

---

## Playbook 1 — Flagged Suspicious Logon

**Trigger:** DeepBlueCLI flags an anomalous logon pattern (e.g., unusual logon type, an admin-equivalent logon from an unexpected source, or a burst of failures followed by a success).

1. Pull the full corresponding Event ID 4624/4625/4672 entries directly from the log (not just DeepBlueCLI's summarized line) to confirm logon type, source, and account.
2. Cross-reference the account and source IP/host against expected behavior — is this a known admin workstation, or something unfamiliar?
3. Check whether the flagged logon correlates with any other DeepBlueCLI finding on the same host around the same time (obfuscated command, new service, etc.) — DeepBlueCLI findings often cluster around the same incident.
4. **Escalate if:** the logon doesn't match expected behavior for that account/source, or it correlates with another suspicious finding.
5. **Close as benign if:** the account, source, and logon type all match a known, expected admin/service pattern.

---

## Playbook 2 — Flagged Suspicious/Obfuscated Command Line

**Trigger:** DeepBlueCLI's regex-based command-line detection flags an encoded, obfuscated, or otherwise suspicious PowerShell/command invocation.

1. Pull the full, decoded command line directly (DeepBlueCLI's own decoding output, or manually decode if it only flagged the pattern) — never triage from the truncated summary alone.
2. Cross-reference the decoded command against [`command-line-obfuscation-evasion-cheatsheet.md`](../../Red-Team/03-Exploitation-and-Post-Exploitation/command-line-obfuscation-evasion-cheatsheet.md) to identify the specific technique in use.
3. Identify the parent process for the flagged command — this is the same key question as in [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md) Playbook 4: an Office/browser/scheduled-task parent is far more concerning than an admin's interactive session.
4. **Escalate if:** the parent process is non-interactive, or the decoded command shows a download-cradle/C2 pattern.
5. **Close as benign if:** the command matches a known, legitimate admin script or scheduled automation, confirmed by checking with the responsible team.

---

## Playbook 3 — Flagged New Account Creation / Privilege Assignment

**Trigger:** DeepBlueCLI flags an Event ID 4720 (account created) or 4732/4728 (added to a privileged group) that its heuristics consider anomalous (e.g., off-hours, or performed by an unexpected account).

1. Confirm who performed the action (the "Subject" account in the underlying event) and whether that account normally performs user/group administration.
2. Check whether the timing correlates with any change-management ticket or known scheduled onboarding — a legitimate action will usually have a paper trail.
3. If no legitimate explanation is found quickly, treat this as a strong signal — unauthorized account creation or privilege escalation via legitimate admin tooling is a common persistence technique precisely because it doesn't look like malware.
4. **Escalate if:** no legitimate business justification is found, or the performing account itself is one already under suspicion from another finding.
5. **Containment:** disable the newly created/escalated account pending investigation; review what it was used for in the time since creation.

---

## Playbook 4 — Flagged Service Installation / Scheduled Task Creation

**Trigger:** DeepBlueCLI flags a new service (Event ID 7045) or scheduled task creation that its heuristics consider unusual (e.g., an unsigned binary path, a suspicious binary location like a temp/user-writable directory).

1. Pull the full event details — service/task name, binary path, and the account context it runs under.
2. Check the binary path itself — services/tasks pointing at `%TEMP%`, user profile directories, or unusual naming (randomized-looking names) are classic persistence indicators.
3. Check whether the binary has been seen before in the environment, and its hash reputation if available (see [`reputation-lookup-tools-cheatsheet-professional.md`](../02-DFIR-and-Threat-Intelligence/reputation-lookup-tools-cheatsheet-professional.md)).
4. **Escalate if:** the binary path or naming is anomalous and no legitimate software-deployment explanation is found.
5. **Containment:** disable/remove the service or scheduled task, and treat the host as needing a fuller persistence sweep (cross-reference [`memory-and-disk-forensics-quickref.md`](../02-DFIR-and-Threat-Intelligence/memory-and-disk-forensics-quickref.md)).

---

## General Escalation Criteria (Applies Across All Playbooks)

Escalate to incident response / management immediately, regardless of the specific playbook, if any of the following are true:
- Multiple DeepBlueCLI findings on the same host correlate in a plausible attack sequence (e.g., suspicious logon → obfuscated PowerShell → new scheduled task).
- A privileged/admin account is involved in any flagged finding.
- No legitimate explanation is found after reasonable verification effort.

---

*Tool syntax and flags: [`deepblue-cli-cheatsheet-professional.md`](deepblue-cli-cheatsheet-professional.md). Event ID reference: [`windows-event-id-reference-cheatsheet-professional.md`](windows-event-id-reference-cheatsheet-professional.md). Disk-side follow-up: [`digital-forensics-investigation-playbook-autopsy.md`](../02-DFIR-and-Threat-Intelligence/digital-forensics-investigation-playbook-autopsy.md).*
