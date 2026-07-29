# Wireshark Advanced Cheat Sheet

**Wireshark** is the standard GUI packet analyzer for deep-dive network traffic analysis, sitting at the center of BTL1's Network Security & Monitoring module. It matters because raw pcaps are where C2 beaconing, data exfiltration, and credential-in-the-clear incidents ultimately get proven or disproven.

---

## Table of Contents

1. [Capture Basics](#1-capture-basics)
2. [Essential Display Filter Syntax](#2-essential-display-filter-syntax)
3. [Filtering for Malicious/Suspicious Traffic](#3-filtering-for-malicioussuspicious-traffic)
4. [Following Streams](#4-following-streams)
5. [Statistics Menu](#5-statistics-menu)
6. [Exporting Objects](#6-exporting-objects)
7. [Detecting C2/Beaconing Patterns](#7-detecting-c2beaconing-patterns)
8. [tshark (CLI Wireshark) Basics](#8-tshark-cli-wireshark-basics)
9. [Quick Filter Reference](#9-quick-filter-reference)

---

## 1. Capture Basics

Before filtering anything, you need to pick the right interface and understand that Wireshark actually has two distinct filtering systems, applied at two different stages.

- Choose the capture interface under **Capture → Options** — pick the NIC actually seeing the traffic you care about (a VPN or virtual adapter can silently swallow packets on the wrong interface)
- **Capture filters** use BPF (Berkeley Packet Filter) syntax, are set *before* capture starts, and permanently discard non-matching packets (lighter on disk/memory)
- **Display filters** use Wireshark's own syntax, are applied *after* capture to a full pcap, and only hide packets from view — nothing is discarded, so you can always change your mind

```
# Capture filter (BPF syntax, set before capture)
host 203.0.113.9 and port 443

# Display filter (Wireshark syntax, applied after capture)
ip.addr == 203.0.113.9 && tcp.port == 443
```

---

## 2. Essential Display Filter Syntax

Display filters are what you'll live in during analysis — the operators below cover the overwhelming majority of filters you'll ever type.

| Operator | Meaning | Example |
|---|---|---|
| `==` | Equals | `ip.addr == 10.0.0.5` |
| `!=` | Not equal | `ip.addr != 10.0.0.5` |
| `&&` (or `and`) | Logical AND | `ip.addr==10.0.0.5 && tcp.port==443` |
| `\|\|` (or `or`) | Logical OR | `tcp.port==80 \|\| tcp.port==443` |
| `contains` | Substring match | `http.request.uri contains "login"` |
| `matches` | Regex match | `http.host matches "^[a-z0-9]{20,}\.com$"` |

```
ip.addr==192.168.1.10                     # Traffic to/from a specific host
tcp.port==4444                             # Traffic on a specific port (common Metasploit default)
http.request.method=="POST"                # HTTP POST requests only
dns.qry.name contains "evil"               # DNS queries containing a keyword
ip.addr==192.168.1.10 && tcp.port==445     # Combine host + port (SMB traffic from one host)
```

---

## 3. Filtering for Malicious/Suspicious Traffic

These are the filters you reach for when actively hunting for something bad in a pcap, rather than just browsing.

| Indicator | Filter / What to Look For |
|---|---|
| DNS tunneling | High volume of DNS queries to one domain, unusually long subdomains, high query frequency from a single host |
| Large DNS TXT responses | `dns.txt` combined with unusually large response sizes — TXT records are a common tunneling/C2 channel |
| Non-standard ports for known protocols | `http` filter shows traffic on a port other than 80/8080, or `tls` traffic not on 443 — protocol on the "wrong" port often signals evasion |
| Plaintext credentials | `http.request.method=="POST"` then Follow HTTP Stream to check the POST body for `username=`/`password=` fields |
| ARP spoofing | `arp.duplicate-address-detected` — Wireshark's built-in flag for conflicting MAC-to-IP mappings |

> A single host suddenly resolving hundreds of distinct, randomized-looking subdomains under one parent domain is a strong DNS tunneling/DGA indicator — cross-reference the parent domain in `reputation-lookup-tools-cheatsheet-professional.md`.

---

## 4. Following Streams

Individual packets rarely tell the whole story — reconstructing the full back-and-forth of a conversation is usually what actually answers "what happened."

- Right-click any packet → **Follow → TCP Stream** to reconstruct the entire TCP conversation in one readable view (client requests in one color, server responses in another)
- Right-click any packet → **Follow → HTTP Stream** to reconstruct a full HTTP request/response, including headers and body
- Streams are numbered (`tcp.stream eq 0`, `tcp.stream eq 1`, ...) so you can filter directly to a specific conversation once you know its stream index
- Use this to read exfiltrated data, recover a plaintext login, or see exactly what a malicious payload downloaded

---

## 5. Statistics Menu

The **Statistics** menu turns a pcap from a flat packet list into aggregate views that surface patterns no amount of manual scrolling would catch.

| Tool | Use |
|---|---|
| **Protocol Hierarchy** | Statistics → Protocol Hierarchy — a breakdown of every protocol present and its share of traffic; a fast way to spot something that shouldn't be there |
| **Conversations** | Statistics → Conversations — top talkers by bytes/packets, sortable by IP pair, TCP/UDP stream; find who's sending/receiving the most |
| **IO Graph** | Statistics → IO Graph — plots traffic volume over time; spikes indicate exfiltration or scanning, and *regular, evenly-spaced* intervals are a classic beaconing/C2 indicator |

---

## 6. Exporting Objects

Wireshark can pull a file transferred over the wire directly out of the pcap without you needing to manually reconstruct it byte-by-byte from a stream.

1. **File → Export Objects → HTTP** (or **SMB**, **DICOM**, etc., depending on the protocol carrying the file)
2. Review the list of transferred objects (filenames, content types, sizes)
3. Select the suspicious file and **Save** it to disk

> A file pulled out this way is your starting point for static analysis — hand it off to the workflow in `malware-analysis-yara-cheatsheet-professional.md` to scan it against YARA rules.

---

## 7. Detecting C2/Beaconing Patterns

Command-and-control traffic is designed to blend in, but its underlying automation usually leaves a statistical fingerprint that manual browsing traffic doesn't.

- [ ] Check the **IO Graph** for regular, evenly-spaced time intervals between connections to the same external host — a human doesn't check in every exact N seconds, malware does
- [ ] Check **Conversations** for small, consistent packet sizes repeating between the same host pair (heartbeat/check-in traffic is typically small and uniform)
- [ ] Note the destination IP/domain and look it up in `reputation-lookup-tools-cheatsheet-professional.md` before concluding anything — a regular interval alone isn't proof, but combined with a bad reputation hit it's a strong signal
- [ ] Watch for TLS connections to a destination with no legitimate business reason (new/rare domain, no prior DNS history) alongside the beaconing pattern

---

## 8. tshark (CLI Wireshark) Basics

`tshark` is Wireshark's command-line counterpart — same dissection engine, no GUI, which makes it the right tool for scripting or for pcaps too large for the GUI to handle comfortably.

```bash
tshark -r file.pcap -Y "http.request.method==POST"     # Read a file, apply a display filter
tshark -r file.pcap -Y "dns" -T fields -e dns.qry.name  # Extract just the DNS query names
tshark -r file.pcap -q -z conv,tcp                       # TCP conversation statistics (CLI Statistics menu)
tshark -i eth0 -f "port 443"                              # Live capture with a BPF capture filter
tshark -r file.pcap -Y "tcp.port==4444" -w filtered.pcap  # Filter and write out a smaller pcap
```

---

## 9. Quick Filter Reference

A single-page lookup for the filters and commands used most throughout this document.

| Need | Filter / Command |
|---|---|
| Traffic to/from a host | `ip.addr==<ip>` |
| Traffic on a specific port | `tcp.port==<port>` |
| HTTP POST requests | `http.request.method=="POST"` |
| ARP spoofing detection | `arp.duplicate-address-detected` |
| Reconstruct a conversation | Right-click → Follow → TCP/HTTP Stream |
| Traffic overview | Statistics → Protocol Hierarchy |
| Top talkers | Statistics → Conversations |
| Spot beaconing | Statistics → IO Graph |
| Pull a transferred file | File → Export Objects → HTTP/SMB |
| CLI filter + export | `tshark -r file.pcap -Y "<filter>" -w out.pcap` |

---

*Prepared as a reference for the BTL1 Network Security & Monitoring module.*
