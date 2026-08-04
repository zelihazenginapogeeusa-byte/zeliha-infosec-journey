# Incident Report Example 1 — Alert Closed

**Scenario:** A user triggered multiple failed login attempts while trying to remember their password.

## Overview

| Field | Value |
|---|---|
| Incident Name | Multiple Failed Login |
| Severity | Medium |
| Detection Date | 2026-05-21 10:22:31 |
| Analyst | SOC Analyst L1 |
| Status | **CLOSED** |

## Investigation Flow

1. **Alert Received** (Event ID 4625)
2. **Contacted the User** (phone verification)
3. **User Confirmed:** forgot their password and mistyped it a few times
4. **No Malicious Activity**
5. **Alert Closed** — genuine user activity

## 1. Alert Details (Splunk)

```spl
index=windows EventCode=4625 | stats count by src_ip, user, host
```
Result: 12 failed logins recorded for `testuser` from host WIN10.

## 2. Windows Event Viewer

- Event ID: 4625 (Failed Logon)
- Source: Microsoft Windows Security Auditing
- Failed logins observed: 12

## 3. Timeline (Around Alert Time)

| Time | Event |
|---|---|
| 10:15 AM | User attempted to log in |
| 10:16–10:22 AM | Multiple failed logins (4625 × 12) |
| 10:22 AM | Alert triggered |
| 10:24 AM | User successfully logged in |

## 4. User Verification

**Analyst:** Hi, we detected multiple failed login attempts on your account. Were you trying to log in recently?
**User:** Yes, I forgot my password and mistyped it a few times.
**Analyst:** Understood, thanks. We'll confirm this as genuine activity and close the alert.

## 5. Evidence Summary

- Splunk screenshot — failed logins
- Event Viewer — Event ID 4625
- Post-success login activity verified
- User verification (phone call)

## IOC Check

No indicators of compromise — no malicious IP, host, or URL found.

## Root Cause

The user mistyped their password multiple times in a short window.

## Analyst Notes

The user confirmed this was genuine activity. No IOC found. No further action required.

## Final Decision

**ALERT CLOSED**

**Reason:** Genuine user activity confirmed.

## Golden Rule

Never assume. Verify and document every step.
