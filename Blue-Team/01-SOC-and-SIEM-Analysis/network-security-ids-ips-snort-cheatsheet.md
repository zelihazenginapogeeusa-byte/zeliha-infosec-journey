# Network Security & IDS/IPS (Snort) Cheat Sheet

Firewall and intrusion detection/prevention fundamentals, plus a practical introduction to writing Snort rules. Complements [`wireshark-advanced-cheatsheet.md`](../02-DFIR-and-Threat-Intelligence/wireshark-advanced-cheatsheet.md) (packet-level analysis) and [`attack-types-detection-cheatsheet-professional.md`](attack-types-detection-cheatsheet-professional.md) (what an alert means once it fires).

---

## 1. Firewall Fundamentals

| Concept | What it means |
|---|---|
| Stateless firewall | Filters each packet independently based on static rules (IP, port, protocol) — no awareness of connection state |
| Stateful firewall | Tracks connection state (SYN → SYN-ACK → ACK) — can distinguish a legitimate reply packet from an unsolicited one |
| Default-deny | Block everything by default, explicitly allow only what's needed — the correct baseline posture |
| Default-allow | Allow everything by default, explicitly block known-bad — weaker posture, higher risk, rarely appropriate |
| NGFW (Next-Gen Firewall) | Adds application-layer awareness (can distinguish "HTTPS to Netflix" from "HTTPS to a C2 server" on the same port) |
| Zone-based segmentation | Network divided into zones (e.g., DMZ, internal, guest) with explicit inter-zone rules — limits blast radius of a compromise |

---

## 2. IDS vs. IPS

| | IDS (Intrusion Detection System) | IPS (Intrusion Prevention System) |
|---|---|---|
| Position | Out-of-band (monitors a copy of traffic via TAP/SPAN port) | Inline (traffic physically passes through it) |
| Action on match | Alerts only | Can alert **and** block/drop the traffic |
| Risk of false positive | Annoying (extra alert to triage) | Can cause a self-inflicted outage if a legitimate connection is blocked |
| Typical placement | Anywhere visibility is useful, no risk to availability | Perimeter/critical segments only, after rules are well-tuned |

**Detection methods, both IDS and IPS:**
- **Signature-based** — matches traffic against a known-bad pattern (a specific byte sequence, a known exploit's structure). Fast, low false-positive rate for known threats, blind to anything novel.
- **Anomaly-based** — establishes a baseline of "normal" and alerts on deviation. Can catch unknown/novel attacks, but has a higher false-positive rate and requires a tuning period.

---

## 3. Snort — Modes of Operation

```bash
# Sniffer mode — just print packets to the console
snort -v

# Packet logger mode — log packets to disk
snort -l ./log -b

# NIDS mode (detection only, uses a rules file)
snort -c /etc/snort/snort.conf -i eth0

# Inline/IPS mode (requires DAQ/NFQ configuration, drops matched traffic)
snort -Q -c /etc/snort/snort.conf
```

---

## 4. Snort Rule Anatomy

```
alert tcp any any -> 192.168.1.0/24 80 (msg:"Possible SQLi attempt"; content:"UNION SELECT"; nocase; sid:1000001; rev:1;)
```

| Part | Meaning |
|---|---|
| `alert` | Rule action — `alert`, `log`, `pass`, `drop` (inline/IPS mode only) |
| `tcp` | Protocol — `tcp`, `udp`, `icmp`, `ip` |
| `any any` | Source IP and port — `any` matches everything |
| `->` | Direction operator — unidirectional; `<>` is bidirectional |
| `192.168.1.0/24 80` | Destination IP/CIDR and port |
| `(...)` | Rule options — everything that defines *what* to match and *how to describe* the alert |

**Common rule options:**

| Option | Purpose |
|---|---|
| `msg:"..."` | Human-readable alert description shown when the rule fires |
| `content:"..."` | The byte pattern/string to match in the packet payload |
| `nocase` | Makes the `content` match case-insensitive |
| `pcre:"/regex/"` | Regex matching for more flexible pattern detection |
| `flow:established,to_server` | Restricts matching to a specific point in a TCP connection's lifecycle |
| `sid:1000001` | Unique rule ID — custom rules should use `1000000+` to avoid colliding with official Snort/community rule IDs |
| `rev:1` | Rule revision number — increment when you edit an existing rule |
| `classtype:...` | Categorizes the alert (e.g., `web-application-attack`, `trojan-activity`) for downstream triage/SIEM correlation |

---

## 5. Example Rules

```
# Detect a plaintext FTP login attempt (cleartext credential exposure)
alert tcp any any -> any 21 (msg:"Cleartext FTP login attempt"; content:"USER"; sid:1000010; rev:1;)

# Detect a common web shell parameter pattern
alert tcp any any -> $HOME_NET 80 (msg:"Possible web shell command execution"; content:"cmd="; http_uri; sid:1000011; rev:1;)

# Detect ICMP-based ping sweep (simple anomaly-style rule)
alert icmp any any -> $HOME_NET any (msg:"ICMP Echo Request - possible recon sweep"; itype:8; sid:1000012; rev:1;)

# Detect a known malicious User-Agent string
alert tcp any any -> any 80 (msg:"Suspicious User-Agent detected"; content:"User-Agent|3A| sqlmap"; http_header; sid:1000013; rev:1;)
```

---

## 6. Tuning & False-Positive Management

- Start every new rule in `alert`-only mode, never straight to `drop` — validate it against real traffic before it can block anything.
- Track false-positive rate per rule; a rule that fires constantly on benign traffic gets ignored by analysts (alert fatigue) — tune the `content`/`pcre` match to be more specific, or add `flow`/protocol constraints to narrow it.
- Use `classtype` consistently so a SIEM (see [`siem-splunk-elk-cheatsheet-professional.md`](siem-splunk-elk-cheatsheet-professional.md)) can correlate Snort alerts with other log sources by category rather than by raw rule text.
- Keep custom SIDs in the `1000000+` range and document each one — an undocumented custom rule six months later is a mystery to whoever inherits it.

---

## 7. Suricata — Modern Alternative

Suricata uses largely Snort-compatible rule syntax (the examples above work with minimal or no changes) but adds multi-threading, native TLS/JA3 fingerprinting, and file extraction. Worth knowing the name exists and that migrating a Snort ruleset is usually straightforward — most environments choose one or the other, not both.

---

*Packet-level analysis and manual traffic review: [`wireshark-advanced-cheatsheet.md`](../02-DFIR-and-Threat-Intelligence/wireshark-advanced-cheatsheet.md) · [`wireshark-pcap-threat-hunting-playbook.md`](../02-DFIR-and-Threat-Intelligence/wireshark-pcap-threat-hunting-playbook.md). What a fired alert means and how to triage it: [`attack-types-detection-cheatsheet-professional.md`](attack-types-detection-cheatsheet-professional.md). SIEM correlation: [`siem-splunk-elk-cheatsheet-professional.md`](siem-splunk-elk-cheatsheet-professional.md).*
