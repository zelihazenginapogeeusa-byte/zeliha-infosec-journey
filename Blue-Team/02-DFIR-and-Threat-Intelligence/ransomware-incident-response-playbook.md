# Ransomware Incident Response Playbook

A first-hour, time-critical response procedure — this is deliberately more rigid and checklist-like than the other playbooks, because ransomware is a race against encryption/spread speed, not a leisurely investigation. For general malware/EDR alert triage, see Playbook 6 in [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md); this playbook is specifically for **confirmed or suspected active ransomware**, where spread speed changes the calculus.

> All techniques below are for use in **authorized environments only** — this playbook assumes an authorized SOC/IR context.

---

## Phase 0 — First 5 Minutes (Stop the Bleeding)

**Trigger:** Any of: mass file-renaming/encryption activity detected, a ransom note appearing on multiple shares/hosts, an EDR alert explicitly tagged as ransomware behavior, or a user reporting files suddenly inaccessible with unfamiliar extensions.

1. **Do not investigate before containing.** Ransomware is the one scenario where speed of isolation matters more than initial root-cause clarity.
2. Identify every host currently showing active encryption behavior (high-rate file writes/renames, EDR behavioral alerts) — isolate each from the network **immediately** (network isolation via EDR/switch port, not shutdown — see the power note below).
3. **Do not power off affected hosts** if it can be avoided — powering off loses memory-resident evidence (including, sometimes, encryption keys still resident in memory) and can trigger anti-forensic cleanup routines built into some ransomware. Network-isolate instead.
4. Identify and isolate/disable any network shares actively being encrypted, even on hosts not yet directly confirmed compromised — shared storage is often the fastest spread vector.
5. Notify incident response leadership/management immediately — ransomware is never a solo-analyst, close-it-yourself event.

---

## Phase 1 — Scope the Blast Radius (Next 15–30 Minutes)

1. Identify **patient zero** if possible — the first host to show encryption activity — and work outward: what did it have access to, what shares did it mount, what other hosts could it reach?
2. Check backup infrastructure status **immediately** — many ransomware families specifically target backup systems and shadow copies first. Confirm whether backups are intact, isolated, and have not themselves been touched or deleted (`vssadmin`/Volume Shadow Copy deletion commands are a strong early indicator worth hunting for across the environment).
3. Identify the ransomware family/variant if possible — the ransom note, file extension, and any available samples can be checked against public ransomware-identification resources (e.g., ID Ransomware) and reputation/sandbox tools (see [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md)) — this matters because some families have known decryption tools or known behavior patterns (double-extortion/data theft before encryption).
4. Check for evidence of data exfiltration **preceding** the encryption — modern ransomware operations frequently steal data first ("double extortion"); treat this investigation as running in parallel with containment, not after it. Cross-reference [`wireshark-pcap-threat-hunting-playbook.md`](wireshark-pcap-threat-hunting-playbook.md) Playbook 3 if capture data is available, and [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md) Playbook 5.
5. Identify initial access if evidence is available — phishing (see [`phishing-investigation-playbook.md`](phishing-investigation-playbook.md)), exposed RDP/VPN, or a known exploited vulnerability are the most common vectors; this matters for both remediation and for closing the door the attacker used.

---

## Phase 2 — Full Containment

1. Confirm every affected host is isolated — re-check the list from Phase 0/1 as new hosts are identified; ransomware investigations often reveal additional affected hosts as scoping continues.
2. Disable or reset credentials for any account confirmed or suspected used by the attacker, prioritizing privileged/admin and service accounts.
3. Block any identified C2/exfiltration infrastructure at the firewall/proxy.
4. Preserve evidence before any remediation touches affected hosts: memory images where feasible, disk images of at least a representative sample of affected hosts, relevant logs before retention rolls them off, and a copy of the ransom note and any sample encrypted files.
5. Confirm backups are clean and restorable **before** relying on them for recovery — restoring from a backup that was itself compromised/backdoored re-introduces the incident.

---

## Phase 3 — Eradication & Recovery

1. Identify and close the initial access vector and any persistence mechanisms found (cross-reference [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md) for the artifact-hunting steps) — rebuilding from backup without closing the entry point invites immediate reinfection.
2. Rebuild affected hosts from known-clean images/backups rather than attempting to "clean" a compromised host in place, where feasible.
3. Reset credentials domain-wide if there's any indication of broad credential exposure (cross-reference [`active-directory-compromise-lateral-movement-playbook.md`](active-directory-compromise-lateral-movement-playbook.md) if AD-level compromise — e.g., DCSync — is suspected).
4. Restore data from verified-clean backups, prioritizing critical systems first per a pre-agreed (or now-agreed) business-criticality order.
5. Monitor restored/rebuilt hosts closely for a defined period post-recovery — reinfection from a missed foothold is common if eradication was incomplete.

---

## Phase 4 — Post-Incident

1. Determine and document the full timeline: initial access → dwell time → lateral movement → data theft (if any) → encryption trigger.
2. Extract every IOC (hashes, IPs, domains, ransom note text/wallet address if applicable) and map the attack to MITRE ATT&CK technique IDs.
3. Assess data exposure scope for any confirmed exfiltration — this drives legal/regulatory/breach-notification decisions, which sit with management/legal, not the SOC alone.
4. Conduct a lessons-learned review: how was initial access gained, why wasn't it detected sooner, what specifically will change (patching, MFA, backup isolation, network segmentation) as a result.

---

## Decision Point: To Pay or Not to Pay

This decision sits with leadership/legal, never with the SOC/IR team alone — but the SOC's job is to give leadership accurate inputs:
- Are clean, restorable backups actually available? (This is usually the single biggest factor.)
- Is there confirmed data theft, and if so, what data — does this change the calculus beyond "just" availability?
- Has the specific ransomware family been publicly confirmed to honor payment with a working decryptor, or is it known to not deliver even after payment?
- What are the legal/regulatory constraints (some jurisdictions and some sanctioned-entity ransomware groups carry legal restrictions on payment)?

---

## General Escalation Criteria

Every ransomware event is, by definition, escalated immediately to incident response leadership and management from the moment of Phase 0 — there is no "close as benign" outcome for confirmed ransomware activity. The only judgment calls are speed of containment and scope of the response, not whether to escalate.

---

*Malware/EDR alert triage for non-ransomware cases: [`splunk-siem-investigation-playbook.md`](splunk-siem-investigation-playbook.md) Playbook 6. Forensic artifact reference: [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md) · [`volatility-autopsy-forensics-cheatsheet-professional.md`](volatility-autopsy-forensics-cheatsheet-professional.md). IR lifecycle framework: [`incident-response-lifecycle-cheatsheet-professional.md`](incident-response-lifecycle-cheatsheet-professional.md).*
