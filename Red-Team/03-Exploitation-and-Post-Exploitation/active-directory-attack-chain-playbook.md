# Active Directory Attack Chain Playbook

A scenario/engagement-driven walkthrough of how an AD attack chain is actually strung together during an authorized assessment — for the syntax and tool commands themselves (BloodHound, Rubeus, Impacket, Mimikatz, etc.), see [`active-directory-enumeration-cheatsheet-professional.md`](active-directory-enumeration-cheatsheet-professional.md). This document is about **the order operations actually happen in**, from a foothold to Domain Admin, and why each step feeds the next.

> All techniques below are for use in **authorized environments only**, within written scope/Rules of Engagement. This mirrors the defensive counterpart: [`active-directory-compromise-lateral-movement-playbook.md`](../Blue-Team/active-directory-compromise-lateral-movement-playbook.md) — read both together to understand each move from both sides.

---

## Stage 1 — Unauthenticated / Low-Privilege Foothold Enumeration

**Starting point:** You have network access to the domain, with no credentials or only a low-privilege user account.

1. Establish domain basics first: domain name, domain controllers, and whether null/anonymous SMB sessions or LDAP binds are permitted (rarer in modern environments, but still worth the 30-second check).
2. If you have zero credentials: attempt username enumeration via Kerberos pre-authentication (AS-REQ) responses, and check for any accounts with pre-authentication disabled — these are worth flagging even before you have a foothold, since AS-REP Roasting doesn't require valid credentials.
3. As soon as you have **any** valid domain credential (even a low-privilege one — often from an earlier phishing/initial-access stage, or a weak/default password found during service enumeration): pull a full BloodHound collection. This single step reframes the rest of the engagement from "guessing" to "pathfinding."
4. Review BloodHound's shortest-path-to-Domain-Admin queries first — this tells you which of the next stages is actually worth pursuing for this specific environment, rather than running every technique blindly.

---

## Stage 2 — Credential Harvesting from the Domain Itself

**Goal:** Turn one low-privilege credential into more/better credentials, using the domain's own Kerberos behavior against it.

1. **Kerberoasting** — request service tickets for every account with a registered SPN, then attempt offline cracking. This works with any authenticated domain user and requires no special privileges — usually the first technique to try once you have a foothold.
2. **AS-REP Roasting** — for any account flagged (via Stage 1 or a fresh enumeration pass) as not requiring Kerberos pre-authentication, request and crack the AS-REP directly — this doesn't even require valid credentials if the target account is known.
3. Prioritize cracking attempts against **service accounts** first — they disproportionately have weak, old, or never-rotated passwords, and often carry elevated privileges by virtue of the service they run.
4. Any newly-cracked credential goes back into Stage 1 — re-run or re-review BloodHound with the new account's context; a new credential often opens new graph edges (group memberships, local admin rights on other hosts) that weren't visible before.

---

## Stage 3 — Lateral Movement

**Goal:** Use what Stage 2 produced to reach hosts/accounts the original foothold couldn't touch.

1. Check BloodHound for **local admin rights** — which hosts does your current credential set have admin access to? This is usually the most direct lateral-movement path, more reliable than exploiting a new vulnerability on each host.
2. Where local admin is confirmed, use it to extract additional credentials from that host's memory/SAM (Pass-the-Hash from there onward, or full credential extraction where authorized) — see the credential-dumping section of the enumeration cheat sheet for tooling.
3. Watch for **credential reuse across hosts** — a local admin password shared across many machines (common in poorly-managed environments) turns one compromised host into dozens.
4. Re-run BloodHound after each meaningful credential gain — this stage is iterative, not linear: foothold → crack → move → crack → move, until a path to a high-value target opens up.

---

## Stage 4 — Privilege Escalation to Domain Admin

**Goal:** Convert accumulated access into Domain Admin (or equivalent) rights, using whichever path Stage 1–3's BloodHound data actually surfaced.

1. Look for **ACL-abuse paths** first (`GenericAll`, `WriteDacl`, `ForceChangePassword`, `AddMember` edges in BloodHound) — these are often lower-noise than a straight credential-cracking path and are frequently the "shortest path" BloodHound highlights.
2. If a path leads through a **Domain Controller or an account with replication rights**, consider a **DCSync** — this alone yields every domain credential, including `krbtgt`, without needing further lateral movement.
3. If direct Domain Admin group membership is the path (rather than ACL abuse), confirm the specific account/group and the concrete technique (e.g., "Unconstrained Delegation" abuse, or a misconfigured GPO) rather than assuming brute-force cracking is required at this stage — by Stage 4, the path is usually structural, not password-guessing.
4. Document the exact chain used, step by step, with the specific BloodHound edge or technique at each hop — this is what makes the eventual report actionable rather than just "we got Domain Admin."

---

## Stage 5 — Post-Compromise Persistence & Reporting (Authorized Engagements Only)

1. If in scope: demonstrate persistence technique(s) the client has asked to be tested (e.g., a Golden Ticket forged from the `krbtgt` hash obtained via DCSync) — **only** if explicitly authorized in the Rules of Engagement, since this is one of the more intrusive techniques available.
2. Map every stage of the chain to MITRE ATT&CK technique IDs for the report.
3. For each stage, note the **specific misconfiguration or weakness** that enabled it (an SPN that shouldn't exist, a shared local admin password, an over-permissioned ACL, an account with preauth disabled) — the value of this playbook to the client is the fix list, not just the "we got in" narrative.
4. Clean up any artifacts created during testing per the engagement's cleanup requirements (test accounts, planted tickets, scheduled tasks) before closing out.

---

## Quick Reference — Stage-to-Technique Map

| Stage | Primary techniques | Blue-Team detection counterpart |
|---|---|---|
| 1. Foothold enumeration | BloodHound collection, AS-REP account discovery | Playbook 2 in the Blue-Team companion |
| 2. Credential harvesting | Kerberoasting, AS-REP Roasting | Playbooks 1 & 2 |
| 3. Lateral movement | Pass-the-Hash, credential reuse via local admin | Playbook 5 |
| 4. Domain Admin escalation | ACL abuse, DCSync, delegation abuse | Playbooks 3 & 4 |
| 5. Persistence | Golden/Silver Ticket | Playbook 4 |

---

*Tool/technique syntax: [`active-directory-enumeration-cheatsheet-professional.md`](active-directory-enumeration-cheatsheet-professional.md). Defensive mirror: [`active-directory-compromise-lateral-movement-playbook.md`](../Blue-Team/active-directory-compromise-lateral-movement-playbook.md). Exam-day methodology: [`ejpt-exam-checklist-and-methodology.md`](ejpt-exam-checklist-and-methodology.md).*
