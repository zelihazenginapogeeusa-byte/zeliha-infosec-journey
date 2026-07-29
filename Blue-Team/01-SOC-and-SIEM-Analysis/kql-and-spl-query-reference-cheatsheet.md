# KQL & SPL Query Reference Cheat Sheet

Side-by-side syntax for the two query languages you'll actually touch in a SOC — **KQL** (Microsoft Sentinel / Defender) and **SPL** (Splunk) — plus the query patterns that come up constantly during BTL1-style triage.

> Prepared as a reference for BTL1 and general SOC operations.

---

## 1. Core Syntax Side-by-Side

| Task | KQL (Sentinel/Defender) | SPL (Splunk) |
|---|---|---|
| Pick a data source | `SecurityEvent` | `index=security` |
| Filter | `\| where EventID == 4625` | `EventID=4625` |
| Filter on time | `\| where TimeGenerated > ago(24h)` | `earliest=-24h` |
| Select fields | `\| project TimeGenerated, Account, Computer` | `\| table _time, user, host` |
| Sort | `\| sort by TimeGenerated desc` | `\| sort -_time` |
| Limit results | `\| take 50` | `\| head 50` |
| Count | `\| summarize count()` | `\| stats count` |
| Group by | `\| summarize count() by Account` | `\| stats count by user` |
| Distinct values | `\| distinct Account` | `\| dedup user` |
| String contains | `\| where Account contains "admin"` | `\| search user="*admin*"` |
| Regex match | `\| where Account matches regex "^adm.*"` | `\| regex user="^adm.*"` |
| Join | `\| join kind=inner (OtherTable) on Computer` | `\| join host [search index=other]` |
| Time-bucket / bin | `\| summarize count() by bin(TimeGenerated, 1h)` | `\| bucket _time span=1h \| stats count by _time` |

---

## 2. Common Triage Queries — KQL

**Failed logon spike (brute-force / spray candidate):**
```kql
SecurityEvent
| where EventID == 4625
| summarize FailCount = count() by Account, bin(TimeGenerated, 10m)
| where FailCount > 10
| order by FailCount desc
```

**Password spray pattern (many accounts, one source IP):**
```kql
SecurityEvent
| where EventID == 4625
| summarize DistinctAccounts = dcount(Account) by IpAddress, bin(TimeGenerated, 15m)
| where DistinctAccounts > 15
```

**Kerberoasting indicator (bursts of 4769 requests):**
```kql
SecurityEvent
| where EventID == 4769
| summarize TicketRequests = count() by Account, bin(TimeGenerated, 5m)
| where TicketRequests > 20
```

**Suspicious PowerShell (encoded command):**
```kql
DeviceProcessEvents
| where FileName =~ "powershell.exe"
| where ProcessCommandLine contains "-enc" or ProcessCommandLine contains "-EncodedCommand"
```

**Impossible travel / new-location sign-in:**
```kql
SigninLogs
| where ResultType == 0
| summarize Countries = make_set(LocationDetails.countryOrRegion) by UserPrincipalName, bin(TimeGenerated, 1h)
| where array_length(Countries) > 1
```

---

## 3. Common Triage Queries — SPL

**Failed logon spike:**
```spl
index=security EventCode=4625
| bucket _time span=10m
| stats count as fail_count by user, _time
| where fail_count > 10
| sort -fail_count
```

**Password spray pattern:**
```spl
index=security EventCode=4625
| bucket _time span=15m
| stats dc(user) as distinct_accounts by src_ip, _time
| where distinct_accounts > 15
```

**Suspicious PowerShell (encoded command):**
```spl
index=endpoint process_name="powershell.exe"
| search process="*-enc*" OR process="*-EncodedCommand*"
```

**Beaconing detection (regular-interval outbound connections):**
```spl
index=network
| stats count by src_ip, dest_ip
| eventstats avg(count) as avg_conn by src_ip, dest_ip
| where count > (avg_conn * 3)
```

**Top talkers by bytes transferred:**
```spl
index=network
| stats sum(bytes) as total_bytes by src_ip, dest_ip
| sort -total_bytes
| head 20
```

---

## 4. Field-Naming Cheat Sheet (Where Things Differ)

| Concept | KQL common field | SPL common field |
|---|---|---|
| Timestamp | `TimeGenerated` | `_time` |
| Source IP | `IpAddress` / `SrcIpAddr` | `src_ip` / `src` |
| Destination IP | `DestinationIpAddress` | `dest_ip` / `dest` |
| Username | `Account` / `UserPrincipalName` | `user` |
| Hostname | `Computer` / `DeviceName` | `host` |
| Process name | `FileName` | `process_name` |
| Full command line | `ProcessCommandLine` | `process` / `CommandLine` |
| Event/Windows Event ID | `EventID` | `EventCode` |

---

## 5. Useful Operators Reference

| Operator | KQL | SPL |
|---|---|---|
| Logical AND | `and` | (implicit space, or `AND`) |
| Logical OR | `or` | `OR` |
| NOT | `not` / `!=` | `NOT` |
| Wildcard | `*` inside `contains`/`has` | `*` directly in search terms |
| Case-insensitive equals | `=~` | search is case-insensitive by default |
| Time range shorthand | `ago(1h)`, `ago(7d)` | `earliest=-1h`, `earliest=-7d@d` |

---

## 6. Quick Tips

- In KQL, prefer `has` over `contains` when matching whole words — `has` is indexed and much faster on large tables.
- In SPL, always put your most selective filters **first** (before any `\|` pipes) — Splunk applies index-time filtering before the pipeline, so `index=x sourcetype=y EventCode=4625` beats filtering EventCode later with a `search` pipe.
- Both languages support saved queries/alerts — once you've built a working detection query, save it as a scheduled analytic rule (Sentinel) or a saved search / correlation search (Splunk ES) rather than re-running it manually.

---

*Companion to [`siem-splunk-elk-cheatsheet-professional.md`](siem-splunk-elk-cheatsheet-professional.md) and [`threat-intelligence-mitre-attack-cheatsheet-professional.md`](threat-intelligence-mitre-attack-cheatsheet-professional.md) in this folder.*

*Prepared as a reference for BTL1 and general SOC operations.*
