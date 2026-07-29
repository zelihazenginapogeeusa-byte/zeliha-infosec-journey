# Phishing Investigation Playbook

Scenario-driven response procedures — for header analysis syntax, SPF/DKIM/DMARC mechanics, and IOC-extraction technique itself, see [`phishing-cheatsheet.md`](phishing-cheatsheet.md) and [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md). This document is about **what to do, in order**, once a suspected phishing email lands in the queue.

> All techniques below are for use in **authorized environments only** — this playbook assumes an authorized SOC/IR context, and any IOC lookups should use sanitized/defanged values or an isolated analysis environment.

---

## Playbook 1 — User-Reported Suspicious Email (Most Common Path)

**Trigger:** A user forwards/reports an email via the "Report Phishing" button or to the SOC mailbox.

1. Pull the **full original headers** (not the forwarded copy's headers) — request the `.eml`/full-headers version if it wasn't captured automatically.
2. Check **SPF/DKIM/DMARC** results in the `Authentication-Results` header — a hard fail on a domain claiming to be internal/trusted is an immediate red flag.
3. Check the **`Return-Path`/envelope-from vs. the displayed "From" name** — a mismatch (display name says "IT Support," return-path is an unrelated free-mail domain) is one of the most common tells.
4. Extract every IOC: sender address/domain, links (do not click — extract the raw URL from the HTML source), attachment name + hash.
5. Check link/domain and attachment hash reputation (see reputation-lookup cheat sheet) using sanitized values only.
6. Check whether the same sender/subject/link has hit **other mailboxes** — a single report is often the tip of a wider campaign.
7. **Escalate if:** authentication fails on a spoofed-trusted domain, the link/hash comes back malicious, or multiple mailboxes received the same message.
8. **Close as benign if:** authentication passes, sender/domain reputation is clean, and no malicious link/attachment is present (legitimate marketing/spam, not phishing).

---

## Playbook 2 — Confirmed Malicious Link Clicked

**Trigger:** Investigation (via Playbook 1 or an EDR/proxy alert) confirms a user clicked a malicious link.

1. Identify **who clicked** and **when** — check proxy/EDR logs for the outbound request to the malicious URL from that user's host.
2. Determine what the link actually did: credential-harvesting page (fake login portal) vs. drive-by download vs. redirect chain to an exploit kit — check the URL's landing behavior via a sandboxed/isolated browsing tool, never directly from a corporate endpoint.
3. If it's a **credential-harvesting page:** assume the account is compromised until proven otherwise — check for a subsequent form submission in the proxy logs (POST request following the page load is the strongest indicator credentials were actually entered).
4. If it's a **download:** identify the downloaded file, get its hash, and check EDR/AV for detection or execution on the host.
5. Check the affected host/account for any post-click anomalous activity (new mailbox rules, unusual sign-ins, unexpected process execution) — cross-reference [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md) Playbooks 3–4 if sign-in or PowerShell anomalies are found.
6. **Escalate if:** credential submission is confirmed, a file was downloaded and executed, or any post-click anomalous activity is found.
7. **Containment:** force password reset + session revocation on the account, isolate the host if a file executed, block the malicious domain/IP at the proxy/firewall.

---

## Playbook 3 — Confirmed Malicious Attachment Opened / Executed

**Trigger:** A user opened an attachment from a phishing email, and it's suspected or confirmed to have executed something.

1. Get the attachment's hash and check reputation/prior detonation results (VirusTotal, Any.Run — see reputation cheat sheet) before doing anything else locally.
2. Check EDR/AV logs on the host for the file's execution — was it auto-quarantined, or did it run?
3. If it ran: pull the process tree spawned from the document/executable (e.g., `WINWORD.EXE` → `powershell.exe` is a classic macro-dropper pattern) — cross-reference [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md) Playbook 4 for the PowerShell-specific triage steps.
4. Check for persistence artifacts created around the execution time (run keys, scheduled tasks, new services) — see [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md).
5. Check for outbound network connections initiated by the spawned process (C2 check-in) — cross-reference [`wireshark-pcap-threat-hunting-playbook.md`](wireshark-pcap-threat-hunting-playbook.md) Playbook 2 if a live capture is available.
6. **Escalate if:** the file executed (wasn't auto-quarantined), spawned a suspicious child process, or created persistence.
7. **Containment:** isolate the host without powering it off (preserve memory-resident evidence), capture a memory image if forensically warranted, remove persistence artifacts as part of remediation.

---

## Playbook 4 — Suspected Campaign / Multiple Recipients (BEC / Mass Phish)

**Trigger:** The same or a closely related phishing email is confirmed hitting more than a handful of mailboxes, or the pattern looks like Business Email Compromise (BEC) — e.g., a spoofed/compromised internal account requesting a wire transfer or credential re-entry.

1. Search the mail gateway/SIEM for every message matching the shared indicators (sender, subject line pattern, link domain, attachment hash) to scope the full blast radius.
2. For suspected **BEC from a genuinely compromised internal account** (not just spoofed): check that account's sign-in history for anomalies (see [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md) Playbook 3 — Impossible Travel) and mailbox rules for auto-forwarding/deletion rules an attacker may have added to hide their tracks.
3. Coordinate a bulk remediation: purge the message from all mailboxes still holding it (mail-gateway/M365 "search and purge"), block the sender/domain/link at the gateway, and block the attachment hash at the EDR/AV level.
4. Notify affected users with clear, specific guidance (what the email looked like, what to do if they already interacted with it) — don't rely on a generic "be careful with phishing" notice.
5. **Escalate if:** the compromised-account variant is confirmed, any recipient is confirmed to have interacted with the payload, or the campaign is targeting a specific high-value group (finance, executives — a strong BEC indicator).
6. **Containment:** see Playbooks 2/3 for any user who interacted with the link/attachment; for BEC, additionally reset credentials and review financial transaction requests sent from the compromised account during the window.

---

## General Escalation Criteria (Applies Across All Playbooks)

Escalate to incident response / management immediately, regardless of the specific playbook, if any of the following are true:
- A privileged/admin or finance-department account is involved.
- Credential submission or malware execution is confirmed (not just a click on a link).
- The email is part of a multi-recipient campaign, not an isolated report.
- Any evidence of lateral movement, persistence, or data staging following the initial phish — treat it as an incident, not a single alert.

---

*Header/IOC analysis syntax: [`phishing-cheatsheet.md`](phishing-cheatsheet.md) · [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md). Category reference: [`attack-types-detection-cheatsheet-professional.md`](attack-types-detection-cheatsheet-professional.md). Follow-on host/network investigation: [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md) · [`wireshark-pcap-threat-hunting-playbook.md`](wireshark-pcap-threat-hunting-playbook.md).*
