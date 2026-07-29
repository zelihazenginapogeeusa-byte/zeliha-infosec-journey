# eJPT Exam Checklist & Methodology

A run-through-it-in-order checklist for exam day itself — less "how does nmap work," more "what do I do in what sequence so I don't run out of time or miss a flag."

> All techniques below are for use in **authorized environments only** — this checklist assumes an authorized exam/lab environment.

---

## 1. Before You Start the Clock

- [ ] Confirm VPN connectivity to the exam network and that you can ping the target range.
- [ ] Open a notes file/template immediately — structure it **before** you start (one section per host: recon, enumeration, exploitation, privesc, loot/flags).
- [ ] Set up a screenshots folder, named/numbered as you go (`01-nmap-scan.png`, `02-...`) — don't rely on retroactively remembering what a screenshot was of.
- [ ] Start a running list of every credential/hash you find, regardless of whether you've cracked/used it yet — you'll often need it again later against a different host.
- [ ] Note the exam's actual objectives/questions before touching a single machine — know what you're being asked to prove, not just "get root."

---

## 2. Per-Host Methodology (Repeat for Every Target)

Work this loop identically on every machine — consistency is what keeps you from missing steps under time pressure.

1. **Scan** — full port scan first (`nmap -p- -T4 <ip>`), then a targeted service/version scan on the open ports (`nmap -sV -sC -p<ports> <ip>`).
2. **Enumerate every open service**, no exceptions — even ones that "look boring." A misconfigured, unassuming service is a common way eJPT boxes are solved.
3. **Identify the exploitation path** before firing anything — match findings against known CVEs/misconfigurations (see `attack-types-identification-cheatsheet-professional.md`).
4. **Get a shell.** Document exactly how (exploit name/CVE, exact command/payload used).
5. **Stabilize the shell** immediately (see `netcat-reverse-shell-cheatsheet-professional.md` §4) — an unstable shell wastes far more time than the 30 seconds stabilizing costs.
6. **Enumerate for privesc** (see `privilege-escalation-linux-windows-cheatsheet.md`) — run the 60-second manual checklist before reaching for an automated script.
7. **Escalate.** Document the exact technique and command.
8. **Loot:** grab flags, additional credentials, config files, anything that might be needed against another host on the network (this is where lateral movement clues usually live).
9. **Screenshot proof** at each major milestone: initial shell, privilege confirmation (`id`/`whoami`), and every flag.

---

## 3. Time Management

- Budget time **per host**, not just for the exam overall — if a box is eating more than ~20% of your remaining time with no progress, step back, re-enumerate from scratch, and consider moving to another target if the exam structure allows it.
- Re-enumeration beats guessing. If stuck, the answer is almost always "go back to step 2 and look harder at something you dismissed," not "try increasingly exotic exploits."
- Don't let report-writing pile up until the very end — write up each host as you finish it, while the details are fresh.

---

## 4. Common Pitfalls

| Pitfall | Fix |
|---|---|
| Forgetting to re-scan after a VPN reconnect/VM revert | Always re-verify connectivity and re-run at least a quick scan after any interruption |
| Cracking a hash and forgetting which host/service it belongs to | Log source alongside every credential the moment you find it |
| Spending 45 minutes on privesc before checking `sudo -l` | Always run the fast, cheap checks first (see privesc cheat sheet's priority order) |
| Losing track of which shell is stabilized vs. raw | Label terminal tabs/windows by host + shell type |
| Waiting until the end to start the report | Write each section immediately after completing that host |

---

## 5. Report / Submission Checklist

- [ ] Every objective/question explicitly answered, in the order asked.
- [ ] Every claim backed by a screenshot or command output — "I got root" isn't evidence, the `whoami`/`id` output is.
- [ ] Exploitation steps are reproducible from your notes alone — write it as if someone else has to redo your work from scratch.
- [ ] IP addresses, hostnames, and credentials in the report match what's actually in your screenshots (easy to typo under time pressure — proofread before submitting).
- [ ] Executive summary / methodology section present if the exam report template calls for one (see `assessment-methodology-report-writing-cheatsheet-professional.md` in the repo root).

---

*Exam-day companion to the full [`ejpt-roadmap.md`](../ejpt-roadmap.md) study plan — that one is for building the skills, this one is for the day you actually sit the exam.*
