# SIEM / Splunk & ELK Query Cheat Sheet

The heart of BTL1's **Security Operations & Monitoring** module: turning a mountain of logs landing in a SIEM (Splunk or ELK/Kibana) into a meaningful threat signal with the right query.

---

## Table of Contents

1. [What a SIEM Is & Why It Exists](#1-what-a-siem-is--why-it-exists)
2. [Splunk SPL Basics](#2-splunk-spl-basics)
3. [Splunk: Common Detection Queries](#3-splunk-common-detection-queries)
4. [ELK / Kibana KQL Basics](#4-elk--kibana-kql-basics)
5. [ELK: Common Detection Queries](#5-elk-common-detection-queries)
6. [Dashboard & Alert Logic](#6-dashboard--alert-logic)
7. [Log Source Prioritization](#7-log-source-prioritization)
8. [Quick Command/Query Reference](#8-quick-commandquery-reference)

---

## 1. What a SIEM Is & Why It Exists

A **SIEM (Security Information and Event Management)** centrally collects logs from disparate sources (firewall, DC, endpoint, proxy), normalizes them, and generates meaningful alerts via correlation rules. A SOC analyst's day-to-day work is largely writing SIEM queries and triaging alerts.

```
Log Sources → Collection (Forwarder/Beats) → Indexing → Search/Correlation → Alert/Dashboard
```

---

## 2. Splunk SPL Basics

The core SPL syntax you'll type into Splunk's search bar dozens of times a shift — filter first, then pipe into `stats`/`eval`/`rex` to shape the output.

```spl
index=main sourcetype=WinEventLog                    # Basic index/sourcetype filter
index=main "failed password"                          # Free-text search
index=main EventCode=4625                              # Field-based filter

| stats count by src_ip                                 # Group + count
| sort -count                                           # Sort descending
| where count > 10                                      # Conditional filter
| table _time, src_ip, user, EventCode                  # Column selection
| rex field=_raw "user=(?<username>\w+)"                # Extract a field with regex
```

| Command | Purpose |
|---|---|
| `stats` | Grouping/aggregation (count, sum, avg, dc = distinct count) |
| `timechart` | Generating time-based chart data |
| `eval` | Computing/creating a new field |
| `rex` | Extracting a field from raw data with regex |
| `transaction` | Grouping related events into a single session/transaction |

---

## 3. Splunk: Common Detection Queries

Ready-to-adapt SPL queries for the detections you'll be asked to build in a SOC analyst role — brute force, password spray, and Kerberoasting.

```spl
# Burst of failed logins (brute force / password spray indicator)
index=main EventCode=4625
| stats count by src_ip, user
| where count > 10

# Many different users from the same IP (password spray signature)
index=main EventCode=4625
| stats dc(user) as unique_users by src_ip
| where unique_users > 5

# A successful logon right after failed attempts (brute force followed by a takeover)
index=main (EventCode=4625 OR EventCode=4624)
| transaction user maxspan=5m
| where eventcount > 5

# A new local admin account created (Event 4720 + 4732 for group addition)
index=main EventCode=4720 OR EventCode=4732

# Suspicious PowerShell command execution (encoded command indicator)
index=main sourcetype=WinEventLog:Microsoft-Windows-PowerShell/Operational
"-enc" OR "-EncodedCommand" OR "IEX" OR "DownloadString"

# Suspected Kerberoasting (many different SPNs requested in a short window via 4769)
index=main EventCode=4769
| stats dc(Service_Name) as unique_spns by Account_Name
| where unique_spns > 5
```

---

## 4. ELK / Kibana KQL Basics

KQL's filter syntax for Kibana's Discover tab, functionally equivalent to the SPL field filters covered above.

```
event.code: 4625                                       # Field-based filter
source.ip: "203.0.113.9"                                # IP filter
event.code: 4625 and source.ip: "203.0.113.9"           # AND combination
message: "failed password" and not source.ip: "10.0.0.*" # NOT/exclude
process.command_line: *powershell* and *-enc*            # Wildcard search
```

In Kibana, filter with KQL under **Discover**, chart with **Visualize/Lens**, and set up threshold-based automated alerts under **Alerting**.

---

## 5. ELK: Common Detection Queries

The same detection patterns from the Splunk section above, translated into KQL for an ELK/Kibana stack.

```
# Failed SSH logins
event.dataset: "system.auth" and event.outcome: "failure"

# Sysmon-based suspicious process creation (anomaly via process.parent)
event.code: 1 and process.parent.name: "winword.exe" and process.name: "powershell.exe"

# Suspicious outbound connection (unusual/unrecognized port or host)
event.category: "network" and destination.port: (4444 or 1337)
```

> **A Winword → PowerShell chain via Sysmon** is a textbook indicator of "a macro-laden Office document executed malicious code" — this ties directly into the attachment-analysis section of your phishing cheat sheet.

---

## 6. Dashboard & Alert Logic

Things to think about when writing a detection rule:

- [ ] **What's the baseline?** — what does normal behavior look like (average daily failed-login count)
- [ ] **Is the threshold reasonable?** — too low floods you with false positives, too high lets real attacks slip through
- [ ] **Is the time window right?** — 50 failed logins in 5 minutes vs. in 24 hours means very different things
- [ ] **What's the alert's priority?** — what should a SOC analyst do in the first 5 minutes after seeing this alert

---

## 7. Log Source Prioritization

Not every log source is equally valuable during an investigation — this is roughly the order you'd pull from when time is limited.

| Source | Why it's critical |
|---|---|
| **Domain Controller (Security log)** | Authentication, account management, Kerberos events |
| **Endpoint (Sysmon)** | Process creation, network connections, file/registry changes |
| **Firewall/Proxy** | Outbound traffic, C2 communication, blocked requests |
| **Email Gateway** | Phishing detection, attachment/URL scanning |
| **DNS Server logs** | DGA (domain generation algorithm) and C2 domain lookups |

---

## 8. Quick Command/Query Reference

A single-page lookup for everything covered above.

| Need | Splunk SPL | Kibana KQL |
|---|---|---|
| Filter by Event ID | `EventCode=4625` | `event.code: 4625` |
| Filter by IP | `src_ip="203.0.113.9"` | `source.ip: "203.0.113.9"` |
| Group + count | `\| stats count by src_ip` | Via Kibana Visualize/Lens |
| Time-based chart | `\| timechart count by EventCode` | Discover + histogram |
| Extract a field with regex | `\| rex field=_raw "user=(?<u>\w+)"` | Ingest pipeline / Grok |

---

*Prepared as a reference for the BTL1 Security Operations & Monitoring module.*
