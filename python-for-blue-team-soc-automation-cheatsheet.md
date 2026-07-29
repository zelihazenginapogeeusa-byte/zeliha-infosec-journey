# Python for Blue Team / SOC Automation Cheat Sheet

Practical Python snippets for SOC/analyst work — log parsing, IOC extraction, and reputation-lookup automation. The defensive counterpart to [`python-for-pentesters-cheatsheet-professional.md`](../../Red-Team/02-Web-and-Network-Pentesting/python-for-pentesters-cheatsheet-professional.md); not a Python tutorial, a "I need this script right now" reference for repetitive analyst tasks.

---

## 1. Log Parsing with Regex

```python
import re

log_line = '2026-07-29 14:32:10 [WARN] Failed login for user admin from 203.0.113.55'

pattern = r'(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(?P<level>\w+)\] (?P<message>.*) from (?P<ip>\d+\.\d+\.\d+\.\d+)'
match = re.search(pattern, log_line)
if match:
    print(match.group('timestamp'), match.group('ip'), match.group('message'))
```

**Extracting all IPs from a large log file:**

```python
import re

ip_pattern = re.compile(r'\b(?:\d{1,3}\.){3}\d{1,3}\b')

with open('auth.log') as f:
    ips = ip_pattern.findall(f.read())

from collections import Counter
top_offenders = Counter(ips).most_common(10)
print(top_offenders)
```

Fast way to answer "which source IP shows up most in this log" without writing a SIEM query — useful when working from a raw log dump rather than a live SIEM.

---

## 2. IOC Extraction from Text (Email, Report, Paste)

```python
import re

text = open('suspicious_email.txt').read()

# IPv4 addresses
ips = re.findall(r'\b(?:\d{1,3}\.){3}\d{1,3}\b', text)

# Domains (basic pattern — will need refinement for edge cases)
domains = re.findall(r'\b[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b', text)

# MD5 / SHA1 / SHA256 hashes
md5 = re.findall(r'\b[a-fA-F0-9]{32}\b', text)
sha1 = re.findall(r'\b[a-fA-F0-9]{40}\b', text)
sha256 = re.findall(r'\b[a-fA-F0-9]{64}\b', text)

# URLs
urls = re.findall(r'https?://[^\s"\'<>]+', text)

print({"ips": set(ips), "domains": set(domains), "hashes": set(md5+sha1+sha256), "urls": set(urls)})
```

Cross-reference [`phishing-cheatsheet.md`](phishing-cheatsheet.md) and [`phishing-investigation-playbook.md`](phishing-investigation-playbook.md) for what to do with each IOC type once extracted.

---

## 3. VirusTotal API Query

```python
import requests

API_KEY = "your-api-key-here"  # never hardcode in a committed script — use an environment variable

def check_hash(file_hash):
    url = f"https://www.virustotal.com/api/v3/files/{file_hash}"
    headers = {"x-apikey": API_KEY}
    r = requests.get(url, headers=headers)
    if r.status_code == 200:
        data = r.json()
        stats = data["data"]["attributes"]["last_analysis_stats"]
        print(f"Malicious: {stats['malicious']} / Total engines: {sum(stats.values())}")
    else:
        print(f"Not found or error: {r.status_code}")

check_hash("d41d8cd98f00b204e9800998ecf8427e")
```

**Store the API key safely:**
```python
import os
API_KEY = os.environ.get("VT_API_KEY")
```

---

## 4. AbuseIPDB API Query

```python
import requests

API_KEY = "your-api-key-here"

def check_ip(ip):
    url = "https://api.abuseipdb.com/api/v2/check"
    headers = {"Key": API_KEY, "Accept": "application/json"}
    params = {"ipAddress": ip, "maxAgeInDays": 90}
    r = requests.get(url, headers=headers, params=params)
    data = r.json()["data"]
    print(f"{ip}: abuse score {data['abuseConfidenceScore']}%, reports: {data['totalReports']}")

check_ip("203.0.113.55")
```

Both of these are for one-off/scripted lookups — for the manual, browser-based workflow (and other tools like Any.Run, urlscan.io, MXToolbox), see [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md).

---

## 5. Simple Alert-Correlation Script

A minimal example correlating a list of known-bad IPs against a raw log file — the kind of quick script that's faster to write than to wait on a SIEM query when working against an ad hoc log dump:

```python
known_bad_ips = {"203.0.113.55", "198.51.100.23"}

matches = []
with open("firewall.log") as f:
    for line_num, line in enumerate(f, 1):
        for ip in known_bad_ips:
            if ip in line:
                matches.append((line_num, ip, line.strip()))

for line_num, ip, line in matches:
    print(f"[Line {line_num}] Match on {ip}: {line}")
```

---

## 6. Exporting Findings (CSV / JSON)

```python
import csv
import json

findings = [
    {"ioc": "203.0.113.55", "type": "ip", "context": "Brute-force source", "severity": "high"},
    {"ioc": "evil-domain.com", "type": "domain", "context": "Phishing link", "severity": "medium"},
]

# CSV
with open("findings.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["ioc", "type", "context", "severity"])
    writer.writeheader()
    writer.writerows(findings)

# JSON
with open("findings.json", "w") as f:
    json.dump(findings, f, indent=2)
```

Useful for handing structured IOC lists to a ticketing system, a threat-intel platform import, or an incident report appendix (see [`incident-response-exam-checklist.md`](incident-response-exam-checklist.md) for the report structure this feeds into).

---

## 7. Quick MITRE ATT&CK Technique Lookup

```python
import requests

def lookup_technique(technique_id):
    # Uses the public MITRE ATT&CK STIX data (cached locally is faster for repeated use)
    url = f"https://attack.mitre.org/techniques/{technique_id}/"
    print(f"Reference: {url}")  # fetch/parse as needed for automation; manual reference is often faster for one-off lookups

lookup_technique("T1566")  # Phishing
```

For the full manual mapping reference, see [`threat-intelligence-mitre-attack-cheatsheet-professional.md`](threat-intelligence-mitre-attack-cheatsheet-professional.md) — scripting this is only worth it if you're doing bulk/repeated lookups.

---

*Reputation lookups (manual/browser-based): [`reputation-lookup-tools-cheatsheet-professional.md`](reputation-lookup-tools-cheatsheet-professional.md). Phishing-specific IOC handling: [`phishing-cheatsheet.md`](phishing-cheatsheet.md) · [`phishing-investigation-playbook.md`](phishing-investigation-playbook.md). SIEM query syntax if the correlation belongs in a real SIEM instead of a script: [`kql-and-spl-query-reference-cheatsheet.md`](kql-and-spl-query-reference-cheatsheet.md). Offensive counterpart: [`python-for-pentesters-cheatsheet-professional.md`](../../Red-Team/02-Web-and-Network-Pentesting/python-for-pentesters-cheatsheet-professional.md).*
