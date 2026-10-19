# INE eJPT — Host & Network Penetration Testing: Network-Based Attacks CTF 1

**Course:** INE / eJPT — Host & Network Penetration Testing  
**Lab:** Network-Based Attacks CTF 1  
**Author:** Zeliha Zengin

---

## Lab Environment

GUI access to a Kali machine is provided, along with a packet capture, `test.pcap`. The whole challenge is network forensics — identify the infected host and reconstruct the attack entirely from the capture.

- **Flag 1:** The domain the infected user accessed that returned `200 OK`.
- **Flag 2:** The IP and MAC address of the infected Windows client.
- **Flag 3:** The victim's NetBIOS hostname.
- **Flag 4:** The user who ran `mystery_file.ps1`.
- **Flag 5:** The User-Agent string that indicates PowerShell traffic.
- **Flag 6:** The extension ID of the Coinbase wallet.

**Tools used:** Wireshark

> *All work is performed against an authorized INE training lab for eJPT exam preparation.*

## Flag 1 — Domain that returned 200 OK

Open `test.pcap` in Wireshark and hunt for suspicious traffic — connections to unfamiliar external hosts are the first indicator of compromise. Filter for successful HTTP responses:

```bash
http.response.code == 200
```

Select an `HTTP/1.1 200 OK` response, expand the **Hypertext Transfer Protocol** section, and follow the link back to its matching request to read the requested URL.

> 🏁 **FLAG 1:** `623start.site`

## Flag 2 — Infected client IP + MAC

Filter to HTTP and read the source addresses of the infected host's requests:

```bash
http
```

> 🏁 **FLAG 2:** `10.7.10.47 &nbsp;·&nbsp; 80:86:5b:ab:1e:c4`

## Flag 3 — NetBIOS hostname

NetBIOS Name Service runs over UDP port 137. Either filter isolates it:

```bash
nbns
udp.port == 137
```

The NBNS registration reveals the victim's hostname: **DESKTOP-9PEA63H**.

> 🏁 **FLAG 3:** `DESKTOP-9PEA63H`

## Flag 4 — Who ran `mystery_file.ps1`

Filter to HTTP, then use **Edit → Find Packet**, searching the packet bytes (as a *String*) for `mystery_file.` to locate the transfer:

```bash
http
```

Right-click the matching packet → **Copy → …Printable Text**, paste into a text editor, and search (Ctrl+F) for `Users` to recover the account path.

> 🏁 **FLAG 4:** `rwalters`

## Flag 5 — PowerShell User-Agent

Search the capture for `PowerShell`; the malicious download carries a PowerShell User-Agent string.

> 🏁 **FLAG 5:** `WindowsPowerShell`

## Flag 6 — Coinbase wallet extension ID

Search for `coinbase`, right-click the matching packet → **Follow → TCP Stream**, select all, copy, and paste into a text editor. Locate the Coinbase entry and read its Extension ID.

> 🏁 **FLAG 6:** `hnfanknocfeofbddgcijnmhnfnkdnaad`

## Summary

| Flag | Technique |
| --- | --- |
| 1 | `http.response.code == 200` → follow request |
| 2 | `http` filter → source IP/MAC |
| 3 | `nbns` / `udp.port == 137` |
| 4 | Find Packet (string) → Copy Printable Text → search `Users` |
| 5 | Search `PowerShell` → User-Agent |
| 6 | Search `coinbase` → Follow TCP Stream |

### Key Takeaways

- A single PCAP holds the whole story — start from an IoC (an odd external domain) and pivot.
- `http.response.code == 200` quickly surfaces what actually loaded.
- NBNS (UDP 137) is a reliable way to recover a Windows hostname from capture.
- **Follow TCP Stream** reassembles a conversation so you can read payloads end-to-end.

---

*Write-up by Zeliha Zengin · eJPT preparation*