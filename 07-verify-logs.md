# 7. Verifying Logs in Splunk (First Success 🎉)

Windows 10 is now shipping logs via Sysmon and the Splunk Universal Forwarder. Let's confirm our environment is actually working.

## Log Flow Summary

```
Windows 10 (Endpoint) → Sysmon (Event Generation)
        → Splunk Universal Forwarder (Log Forwarding)
        → Splunk Enterprise (SIEM / Log Collector)
        → SOC Analyst (You)
```

Steps:
1. Windows 10 (endpoint) generates events via Sysmon
2. Sysmon logs are collected
3. The forwarder ships logs to Splunk SIEM
4. Splunk indexes the logs and raises alerts
5. The host (WIN10) is actively sending logs

## What You'll Verify

- Windows Event Logs are reaching Splunk
- Sysmon logs are reaching Splunk
- Host (WIN10) is actively sending logs
- Events are being indexed in near real time
- You can search and analyze the data

## SOC Tip

Always verify log flow first. A SOC analyst's first step is validation, not investigation.

## Verification Queries

### 1. Search all Windows Event Logs
```spl
index=windows
```
**Expected result:** you should see Windows Event Logs arriving successfully.

### 2. Search for failed login events (Event ID 4625)
```spl
index=windows EventCode=4625
```
**Expected result:** failed login events are visible (if any occurred).

### 3. Search all Sysmon logs
```spl
index=sysmon
```
**Expected result:** Sysmon events are being received successfully.

### 4. Verify a specific host is sending logs
```spl
host=WIN10
```
**Expected result:** WIN10 is actively sending logs.

## Key Takeaways

- Windows Event Logs are coming in (Security, System, Application)
- Sysmon is generating detailed process, network, and file activity
- Host WIN10 is successfully forwarding logs to Splunk
- You can now monitor and investigate real-world attack simulations
- Your SOC home lab is ready for attack simulations 🚀

## Common Issues

| Issue | What to check |
|---|---|
| No logs | Are `outputs.conf` and `inputs.conf` correct? |
| Empty index | Is `index=windows` / `index=sysmon` correctly defined? |
| Time sync | Is the Splunk time range set correctly? |
| Host not showing | Is the firewall/port 9997 open? Wait a few minutes and refresh |

## Useful Splunk Commands

```spl
index=windows
index=sysmon
index=windows EventCode=4625
EventCode=4688
host=WIN10
sourcetype=WinEventLog:Security
```
