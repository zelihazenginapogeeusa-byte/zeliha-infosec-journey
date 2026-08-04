# Purple Team Mapping

Most portfolios show either offensive work or defensive work. This folder exists to show both sides of the same coin: for a given attack technique, what does it look like from the **Red Team's** keyboard, and what does it look like from the **Blue Team's** SIEM — for the same ten minutes of activity.

That's the actual job of a purple team exercise: attackers and defenders comparing notes on the same technique so each side gets sharper. You don't need a title with "purple" in it to think this way — it's just what happens when you've spent time on both `Red-Team/` and `Blue-Team/` in the same repo.

## What's Here

[`attack-detection-map.md`](./attack-detection-map.md) walks through ten techniques spanning the attack lifecycle — from initial reconnaissance to exfiltration. Each one is broken into three parts:

- **Red Team** — how the technique is actually executed: the tools, the commands, what the attacker is trying to accomplish and why this technique instead of another.
- **Blue Team** — which log source captures it, the detection logic (SPL-style queries, Sysmon event IDs), and the specific indicators that separate this technique from normal activity.
- **Analyst Response** — what an L1 SOC analyst should actually *do* the moment this alert fires: what to check first, what would make it a false positive, and when it's a "close the ticket" versus an "escalate to L2" situation.

## Why This Exists

Interviewers on both sides of the table ask a version of the same question: *"walk me through what this looks like end to end."* A red-teamer who can describe the blue-team signature their technique leaves behind shows real operational maturity, not just tool proficiency. A blue-teamer who understands why an attacker chose a technique — not just which log field lights up — triages faster and with better judgment.

This document is meant to be read either direction: start from the attack and work down to the detection, or start from an alert and work back to what an attacker was actually doing.

## A Note on Scope and Ethics

Every technique below is described for educational and detection-engineering purposes. The commands and detection logic here mirror what's already documented in [`Blue-Team/soc-analyst-l1-home-lab/`](../Blue-Team/soc-analyst-l1-home-lab) and [`Red-Team/`](../Red-Team) — all of it built and tested against systems I own, inside an isolated lab network. None of this is a substitute for authorization: run these techniques only against systems you own or have explicit, documented permission to test.
