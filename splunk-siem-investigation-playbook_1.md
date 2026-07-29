# Splunk / SIEM Investigation Playbook

Scenario-driven response procedures — for query syntax itself, see [`siem-splunk-elk-cheatsheet-professional.md`](siem-splunk-elk-cheatsheet-professional.md) and [`kql-and-spl-query-reference-cheatsheet.md`](kql-and-spl-query-reference-cheatsheet.md). This document is about **what to do, in order**, once an alert fires.

---

## Playbook 1 — Brute Force / Failed Login Spike

**Trigger:** Alert on repeated authentication failures against a single account.

1. Confirm the pattern: single account, many failures, from one or few source IPs, in a short window.
2. Check whether any of the failed attempts succeeded — a single success following many failures is the highest-priority signal.
3. Pull the source IP's history — is it internal or external? Has it touched other accounts?
4. Check for a follow-on successful login from the same IP/session shortly after.
5. **Escalate if:** a success followed the failure pattern, or the source IP is external and unrecognized.
6. **Close as benign if:** the account owner confirms a forgotten-password lockout and no success followed from an unrecognized source.

---

## Playbook 2 — Password Spray

**Trigger:** Alert on one/few passwords tried across many distinct accounts.

1. Confirm the spray shape: low failure count *per account*, but high distinct-account count from one source in a short window (see the `dcount`/`dc()` query pattern in the query reference sheet).
2. Identify every account that had a **successful** login within the spray window — these are your priority.
3. For each successful account, check for anomalous post-login activity (new mailbox rules, unusual resource access, MFA registration changes).
4. **Escalate immediately if** any account shows a success — treat every one as potentially compromised until ruled out.
5. **Containment:** force password reset + session revocation on every compromised account; block the source IP/ASN if external.

---

## Playbook 3 — Impossible Travel / Anomalous Sign-In

**Trigger:** Same account, sign-ins from geographically distant locations within a timeframe that makes physical travel impossible.

1. Confirm it isn't a VPN/corporate proxy artifact first — check if the "distant" location is a known corporate egress point.
2. Check MFA status on both sign-ins — an MFA-satisfied anomalous sign-in is more concerning than one that failed MFA.
3. Review what the session actually did post-login (mailbox access, file downloads, forwarding rule changes, admin actions).
4. **Escalate if:** MFA was satisfied (or absent) and the session performed sensitive actions.
5. **Containment:** revoke active sessions, force re-authentication + MFA re-registration, review mailbox rules created during the session.

---

## Playbook 4 — Suspicious PowerShell Execution

**Trigger:** EDR/endpoint alert on encoded, obfuscated, or download-cradle PowerShell.

1. Pull the full (decoded, if `-EncodedCommand`) command line — never triage from a truncated preview.
2. Identify the parent process — Office app, browser, or scheduled task spawning PowerShell is a strong indicator vs. an admin's interactive session.
3. Check for outbound network connections initiated by the PowerShell process around the same timestamp.
4. Cross-reference the decoded command against [`command-line-obfuscation-evasion-cheatsheet.md`](../../Red-Team/03-Exploitation-and-Post-Exploitation/command-line-obfuscation-evasion-cheatsheet.md) patterns.
5. **Escalate if:** parent process is non-interactive (Office/browser/scheduled task) or a download/C2 pattern is present.
6. **Containment:** isolate the host, capture a memory image before further remediation if the host is still live.

---

## Playbook 5 — Possible Data Exfiltration

**Trigger:** Alert on abnormally large outbound transfer, or transfer to an unfamiliar destination.

1. Identify source host, destination, protocol, volume, and duration.
2. Check whether the source host/account had any preceding suspicious activity (phishing click, PowerShell alert, lateral movement) — exfil is rarely the first stage.
3. Determine what data the source host had access to — scope the potential exposure before anything else.
4. **Escalate if:** destination is external/unfamiliar and preceded by any other suspicious activity on the same host.
5. **Containment:** block the destination at the firewall/proxy, isolate the source host, preserve logs/pcap for the affected window before they roll off retention.

---

## Playbook 6 — Malware / EDR Detection Alert

**Trigger:** AV/EDR flags a file or process as malicious.

1. Confirm the alert wasn't already auto-remediated (quarantined) — check current process/file state.
2. Pull the process tree — what spawned it, what it spawned.
3. Check for persistence artifacts created around the same time (run keys, scheduled tasks, services) — see [`memory-and-disk-forensics-quickref.md`](../02-DFIR-and-Threat-Intelligence/memory-and-disk-forensics-quickref.md).
4. Extract any available hash/IOC and check reputation (see [`reputation-lookup-tools-cheatsheet-professional.md`](../02-DFIR-and-Threat-Intelligence/reputation-lookup-tools-cheatsheet-professional.md)).
5. **Escalate if:** the detection wasn't auto-quarantined, or persistence/lateral movement artifacts are found.
6. **Containment:** isolate the host from the network while preserving it for forensic collection; don't power off (loses memory-resident evidence).

---

## General Escalation Criteria (Applies Across All Playbooks)

Escalate to incident response / management immediately, regardless of the specific playbook, if any of the following are true:
- A privileged/admin account is involved.
- Evidence of successful lateral movement between hosts.
- Evidence of data staging or exfiltration.
- Multiple playbooks are triggering in a correlated pattern (e.g., phishing → PowerShell → exfil) — this is a single incident, not several unrelated alerts.

---

*Tool/query syntax: [`siem-splunk-elk-cheatsheet-professional.md`](siem-splunk-elk-cheatsheet-professional.md) · [`kql-and-spl-query-reference-cheatsheet.md`](kql-and-spl-query-reference-cheatsheet.md). Category reference: [`attack-types-detection-cheatsheet-professional.md`](attack-types-detection-cheatsheet-professional.md).*
