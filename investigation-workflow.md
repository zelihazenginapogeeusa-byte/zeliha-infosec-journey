# SOC Analyst L1 — Investigation Workflow

When an alert fires, a SOC Analyst L1 follows a structured process to validate, investigate, collect evidence, and decide on final action.

## SOC Investigation Workflow (10 Steps)

1. **Alert Generated** — an alert fires, a rule threshold is crossed
2. **Validate Alert** — check whether the alert is genuine
3. **Check Alert Rule** — review the rule, its conditions, and logic
4. **Check Source IP** — identify the source IP's reputation
5. **Check User** — verify the user, is this normal activity?
6. **Verify Host** — check host health and activity
7. **Review Event Timeline** — analyze events around the alert
8. **Correlate Logs** — check process, network, and registry logs
9. **Determine Severity** — Low / Medium / High / Critical
10. **Collect Evidence & Decide** — gather evidence, then close or escalate to L2

## Key Places an L1 Analyst Investigates

- **Alert Search** — `index=windows EventCode=4625 | stats count by src_ip, user`
- **Windows Event Viewer — Security Log** — relevant Event IDs (4625, 4688, etc.)
- **Sysmon — Process Creation (Event ID 1)** — process details, command line
- **Splunk Timeline View** — event density over time (especially around the alert window)
- **Source IP Investigation** — verify with IP reputation services (IPVoid, AbuseIPDB, VirusTotal, etc.)

## What an L1 Analyst Checks

- Source IP address
- Username
- Hostname
- Event ID
- Logon type
- Command line
- IOC / IOA
- System impact

## Investigation Guide (Quick Reference)

| Step | What to do |
|---|---|
| Validate | Determine whether the alert is genuine |
| Investigate | Review all related logs and data |
| Correlate | Cross-check events from multiple sources |
| Document | Record findings and decisions made |
| Close or Escalate | Close if a false positive, escalate to L2 if a real threat |

## Collecting Evidence

- Screenshots from Splunk / Event Viewer
- Export logs as CSV/JSON
- Process tree
- Command line
- Source IP details
- Timeline
- User verification (if needed)

## Severity Matrix

| Impact | Likelihood | Severity | Action |
|---|---|---|---|
| Low | Low | Low | Monitor |
| Medium | Medium | Medium | Investigate |
| High | High | High | Escalate |
| Critical | Critical | Critical | Immediate response |

## False Positive vs True Positive

- **True Positive:** confirmed malicious activity — a real threat or attack attempt.
- **False Positive:** legitimate process or user activity — no action needed.

## Golden Rule

A good investigation is about accuracy, not speed.

**Validate → Investigate → Correlate → Document → Decide (Close or Escalate)**

## Analyst Mindset

- Stay curious
- Think like the attacker
- Verify everything
- Keep learning
- Document and share

## Next Step

We'll apply this workflow to two sample incidents → [`incident-reports/example-1-closed-alert.md`](./incident-reports/example-1-closed-alert.md) and [`incident-reports/example-2-escalated-to-l2.md`](./incident-reports/example-2-escalated-to-l2.md)
