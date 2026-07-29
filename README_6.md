<p align="center">
  <img src="banner.png" alt="Zeliha's InfoSec Journey — Red / Blue Cybersecurity Learning Hub" width="100%">
</p>

<p align="center">
  <a href="https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/stargazers"><img src="https://img.shields.io/github/stars/zelihazenginapogeeusa-byte/zeliha-infosec-journey?style=flat-square&color=f85149&label=Stars" alt="Stars"></a>
  <a href="https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/network/members"><img src="https://img.shields.io/github/forks/zelihazenginapogeeusa-byte/zeliha-infosec-journey?style=flat-square&color=4a9eff&label=Forks" alt="Forks"></a>
  <a href="https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/watchers"><img src="https://img.shields.io/github/watchers/zelihazenginapogeeusa-byte/zeliha-infosec-journey?style=flat-square&color=a78bfa&label=Watching" alt="Watchers"></a>
  <a href="https://github.com/zelihazenginapogeeusa-byte/zeliha-infosec-journey/commits/cybersecurity-learning-hub"><img src="https://img.shields.io/github/last-commit/zelihazenginapogeeusa-byte/zeliha-infosec-journey?style=flat-square&color=8891a3&label=Last%20Commit" alt="Last Commit"></a>
  <img src="https://img.shields.io/github/repo-size/zelihazenginapogeeusa-byte/zeliha-infosec-journey?style=flat-square&color=4ade80&label=Repo%20Size" alt="Repo Size">
</p>

<p align="center">
  <b>A personal, continuously-updated cybersecurity study repo</b><br>
  Offensive-side notes for <b>eJPT</b> and defensive-side notes for <b>BTL1</b> — cheat sheets, an offline field toolkit, and a study roadmap.
</p>

<p align="center">
  <a href="https://zelihazenginapogeeusa-byte.github.io/zeliha-infosec-journey/field-toolkit_2.html"><b>🧰 Open the Field Toolkit (live)</b></a> ·
  <a href="ejpt-roadmap.md"><b>📄 Study Roadmap</b></a>
</p>

---

## 📖 What's in here

This repo collects everything gathered while studying for the **eJPT** (eLearnSecurity Junior Penetration Tester) and **BTL1** (Blue Team Level 1) certifications: practical, command-heavy cheat sheets — not theory dumps — each covering one tool or one concept, cross-referenced against its siblings.

|  | Folder | Focus |
|---|---|---|
| 🔴 | [`Red-Team/`](Red-Team/) | Recon, enumeration, exploitation, post-exploitation, reporting — eJPT-aligned |
| 🔵 | [`Blue-Team/`](Blue-Team/) | Detection, triage, forensics, incident response — BTL1-aligned |
| 🧰 | [`field-toolkit_2.html`](https://zelihazenginapogeeusa-byte.github.io/zeliha-infosec-journey/field-toolkit_2.html) | Offline, single-file interactive reference — calculators + quick-lookup cards, no install needed (link opens the live version) |
| 🗺️ | [`ejpt-roadmap.md`](ejpt-roadmap.md) | Study roadmap / progress tracker |

> **Note:** if `Red-Team/` and `Blue-Team/` don't show up yet in the file list above, they haven't been uploaded to this repo yet — see [Getting the folders in](#-getting-the-folders-in) below.

---

## 🚀 Getting the folders in

If the cheat sheets are still sitting flat in the repo root instead of split into `Red-Team/` and `Blue-Team/`:

1. Download the organized `cheatsheet-repo-structure.zip` (already generated).
2. Unzip it locally — you'll get `Red-Team/`, `Blue-Team/`, plus a shared root file.
3. On GitHub: **Add file → Upload files**, then drag in the `Red-Team` and `Blue-Team` folders (GitHub preserves the folder structure automatically).
4. Commit directly to `cybersecurity-learning-hub` (this repo's default branch).

---

## 🧰 Try the field toolkit

`field-toolkit_2.html` is a single, self-contained file — calculators (Base64, hash identifier, subnet/CIDR, Hydra command builder, reverse shell generator, and more) plus quick-reference cards for both red and blue team work, filterable by category. No server, no dependencies, no accounts, works fully offline.

**View it live** — GitHub Pages is already enabled on this repo's default branch (`cybersecurity-learning-hub`), so it's reachable right now at:

```
https://zelihazenginapogeeusa-byte.github.io/zeliha-infosec-journey/field-toolkit_2.html
```

*(optional: rename `field-toolkit_2.html` to `index.html` at the repo root if you'd rather the short root URL — `.../zeliha-infosec-journey/` — load it directly)*

---

## 🗂️ Repo structure

```
zeliha-infosec-journey/
├── README.md
├── banner.png
├── field-toolkit_2.html
├── ejpt-roadmap.md
├── assessment-methodology-report-writing-cheatsheet-professional.md   (shared)
├── Red-Team/
│   ├── README.md
│   ├── penetration-testing-methodology-cheatsheet-professional.md
│   ├── nmap-cheatsheet-professional.md
│   ├── active-directory-enumeration-cheatsheet-professional.md
│   ├── metasploit-cheatsheet-professional.md
│   └── ... (23 more)
└── Blue-Team/
    ├── README.md
    ├── incident-response-lifecycle-cheatsheet-professional.md
    ├── siem-splunk-elk-cheatsheet-professional.md
    ├── volatility-autopsy-forensics-cheatsheet-professional.md
    └── ... (7 more)
```

---

## ⚠️ Scope

All techniques documented here are for use in **authorized environments only** — personal labs, CTFs, and engagements covered by written authorization (RoE). Nothing in this repo should be used against systems without explicit permission.

---

<p align="center"><sub>Built while studying — updated as new modules get covered.</sub></p>
