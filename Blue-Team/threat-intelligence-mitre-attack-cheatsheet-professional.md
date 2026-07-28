# Threat Intelligence & MITRE ATT&CK Cheat Sheet

A reference for BTL1's **Cyber Threat Intelligence** module: IOC/TTP concepts, the Pyramid of Pain, practical use of the MITRE ATT&CK framework, and threat intel platforms.

---

## Table of Contents

1. [Types of Threat Intelligence](#1-types-of-threat-intelligence)
2. [IOC vs TTP](#2-ioc-vs-ttp)
3. [Pyramid of Pain](#3-pyramid-of-pain)
4. [MITRE ATT&CK Framework](#4-mitre-attck-framework)
5. [Using the ATT&CK Navigator](#5-using-the-attck-navigator)
6. [Threat Intel Platforms](#6-threat-intel-platforms)
7. [Diamond Model](#7-diamond-model)
8. [Cyber Kill Chain](#8-cyber-kill-chain)
9. [Quick Reference](#9-quick-reference)

---

## 1. Types of Threat Intelligence

| Type | Focus | User |
|---|---|---|
| **Strategic** | High-level trends, business risk (management-facing) | C-level, risk management |
| **Tactical** | Attackers' TTPs (techniques) | SOC analyst, detection engineer |
| **Operational** | Details of a specific campaign/attack | Incident responder |
| **Technical** | Raw IOCs (hashes, IPs, domains) | SIEM/SOAR automation, automated blocking |

---

## 2. IOC vs TTP

| | IOC (Indicator of Compromise) | TTP (Tactics, Techniques, Procedures) |
|---|---|---|
| **What?** | Concrete, static evidence (hash, IP, domain) | A pattern of attacker behavior |
| **Example** | `185.220.101.5`, `evil-domain.com`, `SHA256: a1b2...` | "Running an encoded PowerShell command", "Kerberoasting" |
| **Lifespan** | Short — attackers rotate IPs/domains | Long — changing behavior is expensive for the attacker |
| **Detection value** | Single-use, ages quickly | Persistent, useful across multiple campaigns |

> This distinction is the foundation of the **Pyramid of Pain** — see the next section.

---

## 3. Pyramid of Pain

David Bianco's model — it shows how much you "hurt" an attacker by blocking a given type of indicator. The higher up the pyramid, the more it costs the attacker to route around your block:

```
        TTPs                (Top — changing behavior is the most expensive for the attacker)
   Tools
  Network/Host Artifacts
 Domain Names
IP Addresses
Hash Values             (Bottom — the attacker can change this in seconds)
```

| Level | Example | Cost to the attacker |
|---|---|---|
| Hash Values | A file hash | Trivial — change 1 byte, the hash changes |
| IP Addresses | A C2 server's IP | Easy — spin up a new VPS |
| Domain Names | A C2 domain | Moderate — register a new domain |
| Network/Host Artifacts | A registry key, a user-agent string | Hard — has to reconfigure the malware |
| Tools | The tool in use (Mimikatz, Cobalt Strike) | Very hard — has to develop/acquire a new tool |
| **TTPs** | "Obtaining credentials via Kerberoasting" | **Hardest — has to rethink the entire operational approach** |

> **Practical takeaway:** A SOC that only blocks hashes/IPs stops an attacker for seconds. TTP-based detection (e.g. "an abnormal number of TGS requests across many SPNs") genuinely forces the attacker to change how they operate.

---

## 4. MITRE ATT&CK Framework

A knowledge base compiled from real-world attacks, organized as a **Tactic → Technique → Sub-technique** hierarchy.

| Tactic (Why) | Example Technique (How) |
|---|---|
| **Reconnaissance** | T1595 — Active Scanning |
| **Initial Access** | T1566 — Phishing |
| **Execution** | T1059 — Command and Scripting Interpreter (includes a PowerShell sub-technique) |
| **Persistence** | T1547 — Boot or Logon Autostart Execution |
| **Privilege Escalation** | T1068 — Exploitation for Privilege Escalation |
| **Defense Evasion** | T1027 — Obfuscated Files or Information |
| **Credential Access** | T1558.003 — Kerberoasting |
| **Discovery** | T1087 — Account Discovery |
| **Lateral Movement** | T1021 — Remote Services (SMB, RDP, WinRM) |
| **Collection** | T1114 — Email Collection |
| **Command and Control** | T1071 — Application Layer Protocol |
| **Exfiltration** | T1041 — Exfiltration Over C2 Channel |
| **Impact** | T1486 — Data Encrypted for Impact (ransomware) |

> **Tying it back to DC-1/BTL1:** Drupalgeddon2 → **T1190 (Exploit Public-Facing Application)**; privesc via SUID `find` → **T1548.001 (Abuse Elevation Control Mechanism — Setuid/Setgid)**.

---

## 5. Using the ATT&CK Navigator

Via **attack.mitre.org/resources/navigator**:

1. Create a layer.
2. Mark/color the techniques covered by a given threat group (e.g. APT29) or by your own organization's detections.
3. Build a **heat map** to visualize "which techniques are we weak at detecting."

> In BTL1 scenarios, the typical flow is: review a log/event set → identify which ATT&CK technique it maps to → reference it in the report by its `T-number`.

---

## 6. Threat Intel Platforms

| Platform | Purpose |
|---|---|
| **MISP** (Malware Information Sharing Platform) | An open-source platform for IOC sharing and correlation — cross-organization sharing |
| **OpenCTI** | Structured threat intel data management (STIX format), integrated with ATT&CK |
| **VirusTotal / AlienVault OTX** | Community-sourced IOC reputation and sharing |
| **Recorded Future / ThreatConnect** | Commercial threat intel platforms (common in enterprise environments) |

```
STIX (Structured Threat Information eXpression) — a standard for expressing IOCs/TTPs in a machine-readable format
TAXII (Trusted Automated eXchange of Indicator Information) — a transport protocol for sharing STIX data
```

---

## 7. Diamond Model

A model for analyzing an attack through four core elements — useful for understanding relationships:

```
        Adversary
       /                    \
Capability (Tool/Malware) — Victim (Target)
       \                    /
        Infrastructure (C2, domain, IP)
```

Every event is examined through these four corners: **who** attacked, **what** they used, **who** they targeted, and **what infrastructure** was used.

---

## 8. Cyber Kill Chain

Lockheed Martin's classic model — similar to ATT&CK's "Tactic" level, but more linear:

```
Reconnaissance → Weaponization → Delivery → Exploitation →
Installation → Command & Control → Actions on Objectives
```

> Difference from ATT&CK: the Kill Chain is linear and one-directional, while ATT&CK better models cyclical/repeatable tactics (e.g. an attacker may perform Discovery/Lateral Movement multiple times).

---

## 9. Quick Reference

| Concept | One-line summary |
|---|---|
| IOC | Static, short-lived evidence (hash/IP/domain) |
| TTP | A long-lived pattern of attacker behavior |
| Pyramid of Pain | Which indicator, when blocked, hurts the attacker most |
| ATT&CK | A Tactic → Technique → Sub-technique hierarchy compiled from real attacks |
| MISP/OpenCTI | Platforms for sharing and managing IOCs/TTPs |
| STIX/TAXII | The format / transport protocol for threat intel data |
| Diamond Model | Adversary-Capability-Victim-Infrastructure relationship analysis |
| Kill Chain | A linear, 7-stage attack model |

---

*Prepared as a reference for the BTL1 Cyber Threat Intelligence module.*
