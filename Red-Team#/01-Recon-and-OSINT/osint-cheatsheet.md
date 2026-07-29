# OSINT Cheat Sheet — Red Team Recon

Most red team engagements start before a single packet ever touches the target. **OSINT (Open Source Intelligence)** is the process of gathering information about a target from publicly available sources (search engines, social media, DNS records, breach databases, code repositories, etc.) — because it's entirely passive, it's usually the safest phase within the rules of engagement, and it directly feeds every phase that follows (phishing pretexting, initial access, wordlist generation).

---

## Table of Contents

1. [OSINT Methodology](#1-osint-methodology)
2. [Domain & DNS OSINT](#2-domain--dns-osint)
3. [Search Engine & Dorking](#3-search-engine--dorking)
4. [Email & Username OSINT](#4-email--username-osint)
5. [Social Media & Personnel OSINT](#5-social-media--personnel-osint)
6. [Image & Metadata OSINT](#6-image--metadata-osint)
7. [IP, Domain & Infrastructure Lookup Tools (Red Team)](#7-ip-domain--infrastructure-lookup-tools-red-team)
8. [Website / Infrastructure OSINT](#8-website--infrastructure-osint)
9. [Corporate OSINT](#9-corporate-osint)
10. [Automated OSINT Frameworks](#10-automated-osint-frameworks)
11. [OPSEC & Legal/Ethical Boundaries](#11-opsec--legalethical-boundaries)
12. [Quick Command Reference](#12-quick-command-reference)
13. [Integrating into a Red Team Engagement](#13-integrating-into-a-red-team-engagement)

---

## 1. OSINT Methodology

Rather than reaching for random tools, follow a standard flow:

```
Requirements → Source Identification → Collection → Processing → Analysis → Reporting
```

| Stage | What happens |
|---|---|
| **Requirements** | What do you actually need to learn? (employee list, tech stack, leaked credentials, subdomain map) |
| **Source Identification** | Which sources can provide this information? (LinkedIn, Shodan, GitHub, WHOIS...) |
| **Collection** | Gather the data with tools (covered in the sections below) |
| **Processing** | Normalize the raw data (extract email formats, dedupe subdomains) |
| **Analysis** | Find patterns/relationships in the data (does the same password appear in multiple breaches, which employee uses which technology) |
| **Reporting** | Turn findings into the red team report / pretexting scenario |

> **Passive vs Active Recon:** OSINT is fundamentally **passive** recon — you never send a packet/request directly to the target's infrastructure (you rely on third-party sources like WHOIS, archive sites, search engine queries). Querying the target's DNS server directly (`dig @target-ns`) or port scanning counts as **active** recon and usually requires separate scope/rules-of-engagement approval.

---

## 2. Domain & DNS OSINT

Where a target's domain and subdomain footprint gets mapped out without ever sending a packet to its infrastructure.

| Tool/Source | What it's for |
|---|---|
| `whois domain.com` | Domain registration date, registrar, registrant (if not privacy-protected) |
| **crt.sh** | Subdomain discovery via Certificate Transparency logs — passive, never touches the target |
| `subfinder -d domain.com` | Subdomain collection from passive sources (APIs) |
| `amass enum -passive -d domain.com` | Comprehensive subdomain enumeration across multiple sources (crt.sh, DNS, APIs) |
| `assetfinder domain.com` | Fast, simple list of subdomains/related domains |
| `dnsrecon -d domain.com` | Query DNS record types (MX, TXT, NS), attempt a zone transfer |
| **SecurityTrails / DNSDumpster** | Web-based passive DNS history, subdomain mapping |

```bash
# Passive subdomain discovery via Certificate Transparency
curl -s "https://crt.sh/?q=%25.domain.com&output=json" | jq -r '.[].name_value' | sort -u

# Subfinder + httpx to filter for live subdomains
subfinder -d domain.com -silent | httpx -silent -title -status-code
```

> **Why it matters:** every subdomain is a potential entry point. A forgotten `dev.domain.com` or `old-vpn.domain.com` is often far less protected than the main site.

---

## 3. Search Engine & Dorking

Advanced search operators and platform-specific queries for surfacing exposed files, pages, and devices that aren't linked from anywhere obvious.

### Google Dorking operators

| Operator | Use | Example |
|---|---|---|
| `site:` | Search within a specific domain | `site:domain.com filetype:pdf` |
| `filetype:` | Filter by file type | `filetype:xlsx "password"` |
| `intitle:` | Search the page title | `intitle:"index of" backup` |
| `inurl:` | Search within the URL | `inurl:admin site:domain.com` |
| `intext:` | Search the page content | `intext:"internal use only"` |
| `-` | Exclude from results | `site:domain.com -www` |
| `"..."` | Exact phrase search | `"confidential" site:domain.com` |

```
site:domain.com filetype:pdf OR filetype:docx OR filetype:xlsx
site:domain.com inurl:login OR inurl:admin OR inurl:portal
site:pastebin.com "domain.com"
site:github.com "domain.com" password OR api_key OR secret
```

### Shodan / Censys dorking

| Query | What it finds |
|---|---|
| `hostname:domain.com` | All indexed devices tied to the domain |
| `org:"Company Name"` | Devices in IP blocks registered to the company |
| `ssl:"domain.com"` | Every IP using the domain's SSL certificate (also useful for subdomain discovery) |
| `port:3389 country:"US"` | Open RDP ports in a specific country |
| `http.title:"Login"` | Systems with a specific login page title |

> **GHDB (Google Hacking Database)** — a ready-made dork collection on exploit-db.com; organized by category (login pages, sensitive files, open cameras, etc.).

---

## 4. Email & Username OSINT

Tools for turning a name into a working email address or tracking a single username across platforms.

| Tool | What it's for |
|---|---|
| `theHarvester -d domain.com -b all` | Collects emails/subdomains/names from search engines, PGP servers, Shodan, and similar sources |
| **Hunter.io** | Guesses and verifies a domain's email format (e.g. `first.last@domain.com`) |
| **Sherlock** (`sherlock username`) | Scans 300+ platforms (GitHub, Instagram, Reddit...) for a given username |
| **WhatsMyName** | Similar to Sherlock — web-based username enumeration |
| **Have I Been Pwned (HIBP)** | Checks which data breaches an email address has appeared in |
| **Dehashed** | Searches leaked credential databases (paid, for lawful use) |

```bash
theHarvester -d domain.com -b google,bing,linkedin,crtsh -f output

sherlock target_username --output results.txt
```

> **Guessing the email format:** if you find 2-3 real email addresses for a company (LinkedIn, press releases, GitHub commits), you can derive the format (e.g. `firstinitial.last@domain.com`) and, combined with an employee list (LinkedIn), generate the full email list for the organization — critical for a phishing target list.

---

## 5. Social Media & Personnel OSINT

Where employee-level detail — org structure, tech stack, personal habits — gets collected for use in a pretext.

- **LinkedIn** — employee list, org chart, technologies used (from job postings), executive names (for whaling/BEC targets).
- **X (Twitter) / Instagram / Facebook** — personal information leakage (birth date, pet name, location tags — useful for password guessing/security question answers).
- **GitHub** — API keys, internal hostnames, and config files accidentally committed to employees' personal repos.
- **Maltego** — visual link analysis; builds a relationship map through transform chains like email → social media → domain → IP.
- **social-analyzer** — a tool that automatically scans a person's presence across different platforms.

```
GitHub dorking examples:
"domain.com" password
"domain.com" api_key
org:company-name filename:.env
```

> **A goldmine for pretexting:** information from LinkedIn like "currently at Company X, previously at Company Y, graduated from University Z" is used directly to make a phishing scenario believable.

---

## 6. Image & Metadata OSINT

Photos carry more information than what's visible on screen, from embedded GPS coordinates to background clues.

| Tool | What it's for |
|---|---|
| `exiftool image.jpg` | Extracts a photo's EXIF data (GPS coordinates, capture date, device model) |
| **Google Images / TinEye / Yandex** | Reverse image search — find where else a photo has been used |
| **Google Earth / Street View** | Geolocation verification using background clues in a photo (signage, buildings) |

```bash
exiftool -gps:all photo.jpg     # Extract GPS coordinates
exiftool -all photo.jpg         # All metadata (camera model, software, date)
```

> **Office photos:** social media photos companies share of "our office" often show monitor screens, badges, and whiteboard writing in the background — useful for physical security/badge cloning scenarios.

---

## 7. IP, Domain & Infrastructure Lookup Tools (Red Team)

These are quick "look up an indicator" sites for recon — used to size up the target's infrastructure and email spoofing feasibility before you act, not to judge whether something is malicious (that's a defensive/triage job — see the note below).

| Tool | Link | Used for |
|---|---|---|
| **Shodan** | [shodan.io](https://www.shodan.io/) | Search engine for internet-connected devices — banner grabbing, exposed services/ports, ICS/IoT discovery for a given IP or organization (also see the dorking examples in section 3) |
| **Censys** | [censys.com](https://censys.com/) (formerly censys.io) | Similar to Shodan — internet-wide asset search, certificate data, exposed services; often cross-referenced with Shodan results |
| **IPinfo** | [ipinfo.io](https://ipinfo.io/) | Geolocation, ASN, and hosting-provider lookup for an IP — quick "who owns this and where is it" check, useful for mapping cloud vs. on-prem infrastructure |
| **DomainTools WHOIS** | [whois.domaintools.com](https://whois.domaintools.com/) | Deeper WHOIS/registration history than a plain `whois` command — historical ownership records |
| **MXToolbox** (SPF/DKIM/DMARC lookup) | [mxtoolbox.com](https://mxtoolbox.com/) | Pull the target domain's MX and SPF/DKIM/DMARC records — a weak or missing SPF/DMARC policy tells you the domain can likely be spoofed, directly informing a phishing pretexting plan |
| **crt.sh / DNSDumpster** | [crt.sh](https://crt.sh/) · [dnsdumpster.com](https://dnsdumpster.com/) | Already covered in section 2 — passive subdomain/DNS mapping |

> **Red vs. Blue split:** the tools above answer "what does the target's infrastructure look like, and is it spoofable" — a recon question. Once you (or a defender) have a *specific suspicious indicator* to judge — a hash, a sender IP, a link in an email — that's IOC triage, a blue team/SOC task. That full toolset (VirusTotal, Any.Run, Hybrid Analysis, AbuseIPDB, GreyNoise, urlscan.io, threat intel aggregators, etc.) now lives in `blue-team/reputation-lookup-tools-cheatsheet-professional.md`, alongside `phishing-cheatsheet.md` and `malware-analysis-yara-cheatsheet-professional.md`.

---

## 8. Website / Infrastructure OSINT

Historical and technical detail about the target's public-facing site, beyond whatever is live right now.

| Tool/Source | What it's for |
|---|---|
| **Wayback Machine** (web.archive.org) | View past versions of a site — removed pages, old admin panel links, leaked content |
| **BuiltWith / Wappalyzer** | Detects the site's tech stack — CMS, framework, analytics, CDN |
| `robots.txt` / `sitemap.xml` | Paths the site is "trying to hide" but actually lists out |
| **Netlas / FOFA** | Shodan alternatives — infrastructure/asset search engines |

```bash
# Pull every known URL from the Wayback Machine
curl -s "http://web.archive.org/cdx/search/cdx?url=domain.com/*&output=text&fl=original&collapse=urlkey"
```

> **Why the tech stack matters:** if you learn the target runs WordPress with an outdated plugin, you can go straight to that plugin's known CVEs (the same logic as identifying the Drupal version on DC-1 and going straight to Drupalgeddon2).

---

## 9. Corporate OSINT

Business-facing sources that reveal technology, structure, and people without needing a single technical tool.

- **Job postings** (LinkedIn, Indeed, the company's careers page) — listings like "5+ years Cisco ASA experience" or "manages AWS environment" directly reveal the technology/products in use.
- **Press releases / annual reports** — acquisitions, new offices, executive changes (current names for a whaling/BEC scenario).
- **SEC/corporate registry filings** — company structure, subsidiaries, executive names (for publicly traded companies).
- **Company blog/GitHub organization** — open-source contributions, internal tooling in use, developer names.

---

## 10. Automated OSINT Frameworks

Tools that automate and aggregate the manual collection covered in the sections above.

| Tool | What it's for |
|---|---|
| **SpiderFoot** | Automated OSINT collection across 200+ modules (domain, IP, email, person) — GUI/CLI, presents results as a graph |
| **Recon-ng** | Modular CLI OSINT framework with a Metasploit-like interface |
| **Maltego** | Visual transform-based relationship/graph analysis — the strongest tool for mapping people/organizations |
| **OSINT Framework** (osintframework.com) | Not a tool — a category-based directory of OSINT sources/tools, answering "where do I even start" |

```bash
spiderfoot -s domain.com -m sfp_dnsresolve,sfp_crt,sfp_hackertarget -o csv
```

---

## 11. OPSEC & Legal/Ethical Boundaries

Rules for keeping OSINT collection safe, legal, and traceable back to the engagement rather than to you personally.

- [ ] **Write down the scope and stick to it** — only gather information on domains/people you're authorized for; don't go outside the engagement's boundaries.
- [ ] **Use sock puppet accounts** — do social media/LinkedIn research with separate, untraceable accounts, never your real personal account.
- [ ] **Know the difference between passive and active recon** — using passive sources (crt.sh, WHOIS, archives) vs. sending requests directly to the target's infrastructure (port scans, DNS zone transfer attempts); the latter usually requires separate approval.
- [ ] **Handle personal data (PII) responsibly** — only use collected data within the scope of the report, avoid unnecessary retention.
- [ ] **Always get the Rules of Engagement (RoE)** document signed/read before the engagement starts.
- [ ] **Never upload your own payloads/tooling to public scanners** — a file or URL submitted to a public multi-AV scanner or sandbox becomes visible to other users/vendors on many of their plans; submitting your own C2 implant or phishing infrastructure burns it for the rest of the engagement (and future ones) and can tip off the target's defenders.

---

## 12. Quick Command Reference

A single-page lookup for every command/link covered above.

| Need | Command / Link |
|---|---|
| Subdomains (passive) | `subfinder -d domain.com -silent` |
| Subdomains (multi-source) | `amass enum -passive -d domain.com` |
| Filter for live subdomains | `httpx -l subs.txt -silent -title -status-code` |
| Email/name collection | `theHarvester -d domain.com -b all` |
| Username enumeration | `sherlock username` |
| WHOIS | `whois domain.com` |
| DNS records | `dnsrecon -d domain.com` |
| Certificate Transparency | `curl -s "https://crt.sh/?q=%25.domain.com&output=json"` |
| EXIF metadata | `exiftool image.jpg` |
| Wayback URL list | `curl "http://web.archive.org/cdx/search/cdx?url=domain.com/*&output=text"` |
| IP geolocation/ASN | [ipinfo.io](https://ipinfo.io/) |
| SPF/DKIM/DMARC (spoof feasibility) | [mxtoolbox.com](https://mxtoolbox.com/) |
| Internet device/asset search | [shodan.io](https://www.shodan.io/) · [censys.com](https://censys.com/) |

> IOC/reputation lookups (VirusTotal, Any.Run, AbuseIPDB, urlscan.io, etc.) are in `blue-team/reputation-lookup-tools-cheatsheet-professional.md`.

---

## 13. Integrating into a Red Team Engagement

OSINT isn't an end in itself — the data you collect feeds every phase that follows:

1. **Subdomain/technology map** → attack surface prioritization (which system is weakest/oldest).
2. **Employee list + email format** → phishing/spear phishing target list and pretexting scenario.
3. **Leaked credentials (HIBP/Dehashed)** → a starting point for password spraying / credential stuffing.
4. **Job postings/GitHub** → software stack in use → known CVE research (searchsploit, Exploit-DB).
5. **Physical/office photos** → badge cloning, tailgating scenarios — support for physical pentest engagements.
6. **Spoof feasibility check** (MXToolbox SPF/DMARC, section 7) → confirms whether the target domain can realistically be spoofed before committing to a phishing pretext.

> Just like starting with nmap/nikto on DC-1, finding the Drupal version, and going straight to Drupalgeddon2 — every piece of information gathered in the OSINT phase directly shapes the next step. A good OSINT report determines how efficient the rest of the red team engagement will be.

---

*Prepared as a reference for red team engagements and OSINT work. All techniques should only be used within written authorization (scope/RoE).*
