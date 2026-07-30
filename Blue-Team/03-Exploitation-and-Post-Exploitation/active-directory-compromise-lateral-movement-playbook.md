# Active Directory Compromise & Lateral Movement Playbook

Scenario-driven detection & response procedures — for AD attack technique syntax and tooling itself (Kerberoasting, AS-REP Roasting, BloodHound, DCSync, Pass-the-Hash), see [`active-directory-enumeration-cheatsheet-professional.md`](../Red-Team/active-directory-enumeration-cheatsheet-professional.md) (offensive reference) and [`windows-event-id-reference-cheatsheet-professional.md`](windows-event-id-reference-cheatsheet-professional.md). This document is about **what to do, in order**, once an AD-attack alert fires on the defensive side.

> Written from the defender's seat: each scenario below is the mirror image of a real attack technique — knowing the offensive steps (see the cross-referenced Red-Team file) is what makes the detection logic make sense.

---

## Playbook 1 — Suspected Kerberoasting

**Trigger:** Alert on abnormal volume of Kerberos service ticket requests (Event ID 4769) using RC4 encryption, especially from a single account against many service principal names (SPNs) in a short window.

1. Confirm the pattern: one requesting account, many distinct SPNs, RC4 (`0x17`) encryption type — modern/patched environments should mostly show AES (`0x12`/`0x11`); a burst of RC4 requests is the classic tell.
2. Identify the requesting account — is it a service account, an admin account, or a regular user account that has no business enumerating SPNs?
3. Check whether the requesting account's own recent activity looks scripted (rapid-fire requests, off-hours timing, unusual source host) vs. normal admin tooling.
4. Check for a follow-up authentication using any of the targeted service accounts shortly after — this indicates a cracked ticket was actually used.
5. **Escalate if:** the requesting account is not a legitimate admin/enumeration tool, or any targeted service account authenticates somewhere unusual afterward.
6. **Containment:** reset the password of every targeted service account (moving them to long, random passwords defeats offline cracking), disable/investigate the requesting account, and review SPN hygiene (remove SPNs from accounts that don't need them) as a longer-term fix.

---

## Playbook 2 — Suspected AS-REP Roasting

**Trigger:** Alert on Kerberos AS-REQ activity targeting accounts with "Do not require Kerberos preauthentication" enabled, or a scan pattern probing many accounts for this setting.

1. Identify which accounts in the domain actually have preauthentication disabled (this is a configuration audit as much as an incident check) — any account with this flag is a standing risk, alert or not.
2. If an alert fired: identify the source of the enumeration/request burst and whether it targeted a single known-vulnerable account or scanned broadly across many accounts.
3. Check for a follow-up authentication from any targeted account shortly after the requests — same logic as Kerberoasting, a successful crack leads to actual use.
4. **Escalate if:** a follow-up authentication is observed from a targeted account, or the scanning source is unrecognized/unauthorized.
5. **Containment:** disable "Do not require preauthentication" on every account where it isn't operationally required, reset passwords on any account confirmed targeted, investigate the source host/account that ran the enumeration.

---

## Playbook 3 — Suspected DCSync

**Trigger:** Alert on a non-Domain-Controller account performing directory replication requests (Event ID 4662 with the `DS-Replication-Get-Changes` / `DS-Replication-Get-Changes-All` extended rights, or a SIEM rule specifically built for this).

1. Confirm the requesting account is **not** a Domain Controller computer account and does not legitimately need replication rights (Domain Admins, some backup/AD-sync service accounts are legitimate — everything else is not).
2. Treat this as **high severity by default** — a successful DCSync means the attacker can pull password hashes for any account in the domain, including `krbtgt`, without ever touching a Domain Controller's disk.
3. Check what the requesting account's privileges actually are and how it obtained replication rights — was it granted legitimately, or was it a privilege-escalation/ACL-abuse path (e.g., a misconfigured ACL granting `GenericAll`/`WriteDacl` on the domain object)?
4. Check for any subsequent authentication using accounts that could plausibly have been extracted (especially high-privilege accounts) — assume compromise of every credential in scope until ruled out.
5. **Escalate immediately** — this is a domain-compromise-level event, not a routine alert. Loop in incident response/management without delay.
6. **Containment:** this typically warrants a `krbtgt` password reset (**twice**, per Microsoft guidance, to fully invalidate Golden Tickets forged with the old key), a full credential-reset campaign for any account confirmed or suspected exposed, and an ACL audit to close the path that allowed replication rights in the first place.

---

## Playbook 4 — Suspected Golden / Silver Ticket Use

**Trigger:** Anomalies suggesting a forged Kerberos ticket — e.g., a ticket with an implausibly long lifetime, a TGT for an account that doesn't correspond to a real, recent authentication event, or access patterns inconsistent with the account's normal behavior.

1. Look for the classic indicators: Kerberos ticket activity with no corresponding logon event, or a ticket lifetime exceeding domain policy (default Golden Tickets are often forged with unusually long or non-standard lifetimes).
2. Check whether the account in question authenticated normally around the ticket's issuance time — a forged ticket has no matching legitimate logon.
3. Cross-reference with Playbook 3 (DCSync) — Golden Tickets are typically only possible after the `krbtgt` hash has already been obtained, so treat this as evidence a prior DCSync (successful or not yet detected) may have occurred.
4. Check the scope of access used with the suspect ticket — what resources were touched, and does that match what the account should have access to?
5. **Escalate immediately** — same severity tier as DCSync; this typically indicates the domain's Kerberos trust has already been broken.
6. **Containment:** reset the `krbtgt` password twice, reset credentials broadly for any account with elevated access, and treat the entire domain as needing a trust-rebuild review, not just the one flagged ticket.

---

## Playbook 5 — Suspected Pass-the-Hash / Pass-the-Ticket Lateral Movement

**Trigger:** Alert on a single account authenticating to multiple hosts in rapid succession, or NTLM authentication patterns inconsistent with normal interactive logon (e.g., Logon Type 3/9 network logons at high frequency across the environment).

1. Map the authentication chain: which host did the activity originate from, which account was used, and which hosts were subsequently accessed, in what order and how quickly?
2. Check whether the source account's normal behavior includes remote administration of multiple hosts (an actual admin/deployment tool) vs. an account that has never touched more than one or two hosts before.
3. Check for tooling artifacts on the originating host consistent with credential-dumping (LSASS access alerts, known credential-dumping tool signatures) — cross-reference [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md) if a memory image is available.
4. Check each newly-accessed host for follow-on activity (new processes, further credential access, persistence) — lateral movement chains rarely stop at one hop.
5. **Escalate if:** the account's lateral pattern doesn't match its normal role, or credential-dumping artifacts are found on the originating host.
6. **Containment:** reset the compromised account's credentials domain-wide (a hash reused via Pass-the-Hash is invalidated by a password reset), isolate every host confirmed touched, and hunt for the same technique against other accounts that share local admin credentials with the originating host.

---

## General Escalation Criteria (Applies Across All Playbooks)

Escalate to incident response / management immediately, regardless of the specific playbook, if any of the following are true:
- Any indication that `krbtgt` or another Domain Controller-level credential may be exposed.
- Confirmed lateral movement touching more than one host.
- A privileged/admin or service account is confirmed compromised.
- Any two of the above playbooks correlate in sequence (e.g., Kerberoasting → lateral movement → DCSync) — this is a single domain-compromise incident, not several unrelated alerts.

---

*Offensive-side technique reference: [`active-directory-enumeration-cheatsheet-professional.md`](../Red-Team/active-directory-enumeration-cheatsheet-professional.md) · attack-chain walkthrough: [`active-directory-attack-chain-playbook.md`](../Red-Team/active-directory-attack-chain-playbook.md). Event ID lookups: [`windows-event-id-reference-cheatsheet-professional.md`](windows-event-id-reference-cheatsheet-professional.md). Host-side follow-up: [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md).*
