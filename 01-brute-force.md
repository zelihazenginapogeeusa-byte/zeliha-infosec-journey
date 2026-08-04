# Live Attack 1 — Brute Force Attack

In this lab, we simulate a brute-force attack from Kali Linux against Windows 10 and detect it in Splunk SIEM.

## Flow

```
Kali Linux (Attacker) → Hydra (Brute Force) → Windows 10 (Target)
    → Windows Security Log (Event ID 4625) → Sysmon → Splunk SIEM (Detection) → SOC Alert
```

## 1. Launch the Attack from Kali Linux with Hydra

```bash
hydra -l testuser -P /usr/share/wordlists/rockyou.txt rdp://<windows_ip>
```

Hydra tries passwords from the wordlist one after another against the `testuser` account.

## 2. Windows 10 — Login Attempts

The Windows 10 screen shows failed login attempts (as `testuser`).

## 3. Windows Security Log — Event Viewer

Every failed login attempt generates an **Event ID 4625**.

## 4. Sysmon Event (Event ID 3 — Network Connection)

The network connection from the attacker's machine is logged by Sysmon.

## 5. Splunk — Failed Login Detection

```spl
index=windows EventCode=4625
```
You'll see a timeline of failed login events in Splunk.

## 6. Splunk — Attack Source IP

```spl
index=windows EventCode=4625
| stats count by src_ip
| sort -count
```

## What Is a Brute Force Attack?

A brute-force attack is where the attacker systematically tries a large number of username/password combinations until one works.

## Why Do Attackers Use It?

- Weak passwords
- No account lockout policy
- Default credentials
- Easy and effective to automate

## Key Indicators (IOCs)

- Multiple failed login events (4625) from the same source
- High failure rate in a short time
- Targeted usernames (e.g. `testuser`, `admin`)

## MITRE ATT&CK

- **Technique:** T1110 — Brute Force
- **Tactic:** Credential Access

## Splunk Timeline

```spl
index=windows EventCode=4625
| timechart span=1m count
```
A large number of failed logins in a short window reads as "brute force activity".

## Severity: Medium

Multiple login attempts may indicate active password-guessing activity.

## Recommended Action

- Isolate/investigate the source IP
- Collect evidence and check for signs of compromise
- Flag if repeated failures continue for the same account

## SOC Analyst Tip

Always correlate the Windows Security Log with Sysmon and the source IP — this gives you full visibility for a real brute-force detection.

## Next Step

We'll investigate this alert (Event ID 4625) as a real SOC analyst would in the investigation section → see [`../investigation-workflow.md`](../investigation-workflow.md)
