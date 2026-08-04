# Blue Team / SOC & Defense — Interview Prep

This guide is a companion to `cyber-attacks-qa.md` in this same folder. That file covers attack techniques, adversary TTPs, and specific threat types from a detection/mitigation angle. **This file covers the operational side of defensive security work** — how a SOC actually runs day to day: SIEM mechanics, log analysis, alert triage, incident response process, digital forensics basics, threat intelligence, and the metrics that measure whether a SOC is doing its job. It is written for someone studying for BTL1 (Blue Team Level 1) and preparing for SOC analyst interviews.

Where an attack technique comes up below, it's only in service of a detection or response question — for the deep dive on how that attack works, see the sibling file.

---

## Table of Contents

1. [SIEM & Log Management](#siem--log-management)
2. [SOC Operations & Alert Triage](#soc-operations--alert-triage)
3. [Incident Response Lifecycle](#incident-response-lifecycle)
4. [Digital Forensics Fundamentals](#digital-forensics-fundamentals)
5. [Threat Intelligence](#threat-intelligence)
6. [Detection Engineering & Metrics](#detection-engineering--metrics)
7. [Quick Reference](#quick-reference)

---

## 📊 SIEM & Log Management


<details>
<summary><b>❓ What does a SIEM actually do, end to end?</b></summary>

A SIEM (Security Information and Event Management platform) is a system that centralizes log and event data from across an environment so it can be searched, correlated, and alerted on in near real time. Conceptually it does four things in sequence: **collection** (agents, syslog, APIs, or forwarders pull logs from endpoints, network devices, cloud services, and applications), **normalization/parsing** (raw log formats, which vary wildly between vendors, get mapped into a common schema so a "source IP" field means the same thing whether it came from a firewall or a proxy), **correlation and enrichment** (the SIEM applies rules or analytics across normalized events — sometimes joining data from multiple sources, adding context like asset criticality or geolocation — to surface activity that looks meaningful), and **alerting/search** (when a correlation rule fires, it generates an alert for an analyst to triage, and analysts can also run ad hoc searches across historical log data during an investigation). A SIEM is as much a data pipeline problem as a security problem — its value is completely dependent on what log sources feed it and how well those logs are parsed and retained.

</details>

<details>
<summary><b>❓ What is the difference between a SIEM and a SOAR, and how do they work together?</b></summary>

A SIEM is primarily about visibility: aggregating and correlating log data to detect and surface security-relevant events. A SOAR (Security Orchestration, Automation, and Response) platform is about **action**: it takes alerts (often from the SIEM) and executes automated or semi-automated response workflows — enriching an alert with threat intel lookups, disabling a user account, isolating a host via EDR, opening a ticket, or notifying a team, all through a predefined playbook. The relationship is typically that the SIEM detects and the SOAR responds: an alert fires in the SIEM, gets forwarded to the SOAR, and the SOAR runs a playbook that might auto-close obvious false positives, auto-enrich real alerts with context so the analyst doesn't have to pivot across five tools, or even take containment action for high-confidence, low-risk scenarios. In smaller SOCs these functions sometimes live in one platform; in mature SOCs they are usually separate products integrated together, with SOAR reducing analyst toil on repetitive investigative and response steps.

</details>

<details>
<summary><b>❓ What does "log normalization" mean and why does it matter?</b></summary>

Different devices and applications log the same conceptual event in wildly different formats — a Windows Event Log entry, a firewall syslog line, and a cloud API audit log might all represent "a login happened" but use different field names, timestamp formats, and structures. Normalization is the process of parsing those varied raw formats into a consistent schema (common field names like `src_ip`, `user`, `event_time`, `action`) so that correlation rules and searches can operate uniformly across log sources instead of needing separate logic per vendor. It matters because without it, an analyst (or a detection rule) can't easily ask a cross-source question like "show me all failed logins from this IP across VPN, Windows, and the cloud console" — the data would be in three incompatible shapes. Poor normalization is one of the most common practical reasons detections silently fail: a new log source gets added but isn't mapped correctly, so a field the rule depends on comes through empty or mislabeled and the rule never fires even though the data is technically present.

</details>

<details>
<summary><b>❓ What is log correlation, and give an example of why a single log alone isn't enough?</b></summary>

Correlation is the process of connecting related events — often from different sources or spread across time — to recognize a pattern that no single log entry reveals on its own. A single failed login is meaningless; a single successful login after hours is only mildly interesting; but a correlation rule that ties together "20 failed logins for the same account within 2 minutes" followed immediately by "a successful login from that same account" followed by "that account then accessing a resource it's never touched before" tells a much more convincing story of a brute-force success and possible account takeover. Correlation is what turns a flood of individually low-value log lines into a small number of high-value alerts, and it's the core reason a SIEM is more useful than just grepping raw logs — it encodes the analyst's pattern-recognition into rules that run continuously across the full data set.

</details>

<details>
<summary><b>❓ What are the main categories of log sources in a typical environment, and what does each tell you?</b></summary>

A well-instrumented environment pulls from several complementary log source categories, each answering a different question:

- **Windows Event Logs** — authentication (Security log, event IDs like 4624/4625/4688), account and group changes, service installs, PowerShell execution logging. Good for host-level identity and process-launch visibility on Windows systems, though verbosity and what's captured by default is limited without additional auditing policy tuning.
- **Sysmon** — a much richer, free Microsoft tool that logs process creation with full command lines and parent-child relationships, network connections made by processes, file creation/modification of certain types, registry changes, and named pipe/WMI activity. It's the workhorse for detailed endpoint behavioral detection when a full EDR isn't deployed, and even alongside EDR it's often still valuable for its consistent, well-understood schema.
- **Firewall logs** — allowed/denied connections at the network perimeter or between segments: source/destination IP and port, protocol, and action. Good for spotting scanning, blocked lateral movement attempts, or unexpected outbound connections to suspicious destinations.
- **Proxy logs** — outbound web traffic, including full URLs, categories, user agents, and often the authenticated user who made the request. Extremely valuable for phishing follow-through (a user clicking a malicious link), C2 beaconing detection (regular outbound requests to a rare domain), and data exfiltration via web upload.
- **DNS logs** — every domain resolution request. Useful for catching C2 domain generation algorithm (DGA) patterns, newly registered/rare domains being queried, and DNS tunneling (unusually large or frequent TXT/NULL record queries).
- **EDR (Endpoint Detection and Response) telemetry** — a superset of what Sysmon gives you, plus behavioral detections, memory-level visibility, file hash reputation, and often the ability to take direct response action (isolate host, kill process). It's usually the richest single source for host-based investigation.

An experienced analyst treats these as complementary, not redundant — network logs tell you traffic happened, proxy/DNS tell you where it went and what it looked like at the application layer, and endpoint logs tell you what process and user actually caused it. Investigations usually require pivoting across at least two or three of these.

</details>

<details>
<summary><b>❓ What is log retention and why does it matter for an investigation?</b></summary>

Retention is how long raw or normalized log data stays searchable before it's archived or deleted. It matters because attackers often have long dwell times before detection — industry dwell-time figures have historically ranged from weeks to months — so if retention is too short, by the time an incident is discovered the earliest evidence of initial access may already be gone. Retention decisions are usually a tradeoff between storage cost and investigative value: high-fidelity, high-volume logs like full packet capture or verbose endpoint telemetry might only be kept "hot" (fast-searchable) for 30-90 days and then moved to cheaper "cold" storage for a year or more, while smaller but critical logs like authentication events might be kept hot much longer. In an interview, a good answer ties retention directly to incident scenarios: "if our retention is 30 days but this attacker had 60 days of dwell time, we may not be able to fully scope initial access" is the kind of practical reasoning that shows real understanding.

</details>

<details>
<summary><b>❓ What is the difference between a log, an event, and an alert?</b></summary>

A **log** is a raw record generated by a system — a line of text or structured data describing something that happened (a process started, a connection was made, a file was accessed). An **event** is typically a normalized, parsed version of one or more logs that the SIEM has structured into a common schema and can reason about. An **alert** is what happens when an event or combination of events matches a detection rule's logic and is judged worth a human's attention — it's a small, curated subset of the enormous volume of events, generated because someone decided that pattern was likely to represent risk. The distinction matters because analysts spend their time on alerts, but investigations often require going back down to the raw event or log level for full context that the alert summary doesn't include.

</details>

---


## 🚨 SOC Operations & Alert Triage


<details>
<summary><b>❓ Walk me through how you'd triage a queue of alerts at the start of a shift.</b></summary>

The goal of triage is to quickly separate signal from noise and work the highest-risk items first, not to work alerts strictly in the order they arrived. A practical approach: first, scan the whole queue for severity and asset criticality — an alert on a domain controller or a system holding sensitive data outranks the same alert type on a low-value workstation. Second, look for alerts that correlate with each other (multiple alerts on the same host or user in a short window are a strong signal of something real, versus isolated single alerts which are more often noise). Third, apply quick context checks before deep investigation: is this asset in a maintenance window, is this a known vulnerability scanner IP, has this exact alert fired repeatedly and been closed as benign before. Fourth, for each remaining alert, follow a repeatable investigation pattern — what triggered it, what happened immediately before and after on that host/user, is there corroborating evidence in another log source — rather than jumping straight to conclusions. Throughout, the analyst should document reasoning as they go, both so the decision is defensible later and so triage speeds up over time as patterns repeat. Prioritization frameworks vary by SOC, but the underlying logic is always "what's the realistic worst case if this is real, and how confident am I that it's real" — you triage by risk, not by ticket age.

</details>

<details>
<summary><b>❓ How do you decide whether an alert is a true positive or a false positive?</b></summary>

A true positive means the alert correctly identified activity that matches its intended detection logic and that activity is a genuine security concern; a false positive means the alert fired but the underlying activity was benign or expected. The decision process is really about gathering enough corroborating context to be confident either way: check whether the source/destination, user, and timing make sense for that environment (e.g., is this "impossible travel" alert actually just a VPN exit node skewing geolocation); check whether the activity is expected for that asset's role (a server that's supposed to run scheduled PowerShell scripts triggering a "suspicious PowerShell" alert isn't automatically malicious); check for corroboration across other log sources (does the proxy log show the same suspicious domain the EDR alert flagged); and check history (has this exact pattern been reviewed and confirmed benign before, ideally with a documented reason, not just "we've seen it, ignore it"). It's also worth explicitly considering a third bucket some SOCs track: **benign true positive** — the alert correctly detected the activity it was designed to detect, and that activity is technically what it says it is, but it's authorized (e.g., a pentest, an admin's legitimate use of a dual-use tool). This distinction matters because it's tracked differently from a false positive when tuning rules — you don't want to loosen a rule that's working correctly just because the activity happens to be authorized this time.

</details>

<details>
<summary><b>❓ What's the difference between a false positive and a false negative, and which is more dangerous?</b></summary>

A false positive is an alert that fired when it shouldn't have — benign activity flagged as suspicious. A false negative is the opposite and far more dangerous: malicious activity that occurred but generated no alert at all, so it goes completely unnoticed. False positives cost analyst time and, if excessive, cause alert fatigue that makes analysts more likely to miss or dismiss a real alert buried in noise — so they're a real operational problem. But false negatives are the ones that let an actual breach go undetected, which is a much worse outcome than wasted triage time. This is why detection tuning is a balancing act rather than a simple "reduce false positives" goal: tightening a rule's logic to cut down false positives always risks pushing some true positives into the false-negative bucket, so tuning decisions should be made deliberately, with an understanding of what detection coverage you're trading away, not just to make the queue quieter.

</details>

<details>
<summary><b>❓ What makes a detection rule "good"? What criteria would you use to judge one?</b></summary>

A good detection rule is specific enough to have an acceptably low false-positive rate for the analyst workload it creates, but not so narrow that it misses variations of the behavior it's meant to catch. Beyond that basic precision/recall tradeoff, a few concrete qualities matter in practice: it should be built around behavior that's hard for an attacker to trivially avoid (detecting on a specific malware hash is brittle since hashes change constantly; detecting on the behavioral pattern of "LSASS process memory being read by a non-standard process" is far more durable); it should have clear, actionable output so the analyst isn't left guessing what to investigate (a good alert tells you the who/what/where, not just "anomaly detected"); it should be mapped to a known technique or risk so its priority and expected response are clear (many SOCs tag rules to a technique framework for exactly this reason); and it should be maintained — reviewed periodically against current false-positive rates and evolving attacker behavior, not written once and left alone for years. A rule that technically "works" but generates so much noise that analysts tune it out in practice is not a good rule, regardless of its logical correctness.

</details>

<details>
<summary><b>❓ What is alert fatigue and how do SOCs mitigate it?</b></summary>

Alert fatigue is the desensitization that happens when analysts are exposed to a high volume of low-value or repetitive alerts, leading to slower response, more missed true positives, and higher analyst burnout/turnover. It's arguably one of the biggest practical risks in SOC operations, because a fatigued analyst can undermine even a well-built detection stack. Mitigations include disciplined detection tuning (killing or fixing rules with chronically high false-positive rates instead of just tolerating them), using SOAR automation to auto-triage or auto-close alerts that match known-benign patterns so a human never has to look at them, grouping/correlating related alerts into a single incident view instead of forcing an analyst to review ten separate alerts for one event, setting realistic staffing and rotation so no single analyst is drowning in queue volume, and building feedback loops where analyst triage decisions (true positive vs. false positive) feed back into rule tuning so the system actually gets quieter over time instead of staying static.

</details>

<details>
<summary><b>❓ What are the typical SOC analyst tiers (L1, L2, L3), and what does escalation actually look like in practice?</b></summary>

Most SOCs organize analysts into tiers by depth of investigation and decision authority, though the exact split varies by organization:

- **Tier 1 (L1)** analysts handle initial alert triage: monitoring the queue, performing first-pass investigation, applying documented playbooks/runbooks, and deciding whether an alert is a clear false positive to close, a confirmed benign true positive to document, or something that needs deeper investigation.
- **Tier 2 (L2)** analysts take escalated alerts that need deeper investigation — pivoting across multiple log sources, doing more open-ended analysis without a scripted playbook, confirming scope and impact, and often owning the incident once it's confirmed real, including coordinating initial containment.
- **Tier 3 (L3)** analysts/engineers handle the most complex cases — deep forensic investigation, malware analysis, threat hunting, and often also own detection engineering (writing and tuning the rules L1/L2 rely on) and mentoring.

Escalation in practice isn't just "pass the ticket up" — a good escalation includes a clear summary of what's been checked already, what evidence supports the concern, and what specifically the escalating analyst wants the next tier to look at, so the L2/L3 analyst isn't starting from zero. Poor escalations (just "this looks weird, can you check") waste time and are a common source of friction in real SOCs; interviewers often ask this question specifically to see whether a candidate understands that escalation is a communication skill, not just a technical handoff.

</details>

<details>
<summary><b>❓ A user reports their laptop is acting strangely and running slow. Walk me through how you'd investigate this as a SOC analyst.</b></summary>

This is a classic open-ended triage scenario, and the answer should show a structured thought process rather than jumping to "it's malware." Start by gathering context from the user: what changed recently (new software installed, a suspicious email or attachment opened, an unexpected pop-up), and get a rough timeline of when the symptoms started. In parallel, pull available telemetry for that host: EDR/Sysmon data for unusual process activity (high CPU/resource-consuming processes, unfamiliar process names or ones running from unusual paths like temp directories, unexpected child processes off common applications like Office or the browser), recent network connections (especially outbound to rare or newly-seen destinations, which could indicate C2 beaconing), and any AV/EDR detections that may have already fired but not been escalated. Check authentication logs for that user's account for anything unusual around the same timeframe, since "slow laptop" is sometimes a symptom of resource-hungry malware like a cryptominer or a bot performing local scanning. If findings point toward compromise, move into the containment phase (isolate the host from the network via EDR while preserving it for further analysis) rather than letting the user "just restart it," since a restart can lose volatile evidence and let malware persistence mechanisms simply relaunch anyway. If nothing suspicious turns up, it's reasonable to close as a benign performance issue and hand off to IT, but the investigative steps and reasoning should still be documented in the ticket either way.

</details>

---


## 🔁 Incident Response Lifecycle


<details>
<summary><b>❓ Describe the incident response lifecycle in your own words.</b></summary>

The lifecycle is commonly broken into six phases, and while different frameworks name them slightly differently, the logic is consistent:

1. **Preparation** — everything done before an incident happens: having monitoring and logging in place, documented playbooks/runbooks, a trained team with clear roles, tested communication and escalation paths, and access to the right tools (forensic imaging tools, EDR, isolation capability). This phase is where most of the difference between a well-handled and poorly-handled incident is actually decided, because you can't build capability in the middle of a crisis.
2. **Identification** — detecting and confirming that an incident is actually occurring: an alert fires, or a report comes in, and the analyst gathers enough evidence to determine this is a real security incident, not noise, and to get an initial sense of scope (what systems, what data, what timeframe).
3. **Containment** — limiting the damage and stopping the incident from getting worse, without (ideally) destroying evidence or tipping off the attacker prematurely if further investigation is needed. Containment is often split into short-term (immediate, like isolating a host) and long-term (more durable fixes, like rotating credentials or patching the exploited vulnerability while systems stay isolated).
4. **Eradication** — removing the actual cause: deleting malware, closing the vulnerability or misconfiguration that allowed access, removing attacker-created accounts or persistence mechanisms, and confirming the attacker no longer has a foothold anywhere in the environment (not just the first system found).
5. **Recovery** — restoring affected systems to normal operation carefully, verifying they're clean before reconnecting them to the network, monitoring closely afterward for any sign the attacker retained access, and only declaring the incident closed once there's confidence the threat is fully removed.
6. **Lessons Learned** (sometimes called post-incident review) — a retrospective after the dust settles: what happened, what worked, what didn't, what detection gaps let this happen or delayed detection, and what concrete changes (new detection rules, process fixes, tooling gaps) come out of it. Skipping this phase is one of the most common real-world mistakes — teams fix the immediate incident but don't feed what they learned back into prevention and detection.

A good interview answer doesn't just list these — it should show that the phases loop back on each other in reality (e.g., new findings during eradication can send you back to identification to check if there's a second, related incident) and that lessons learned should concretely update preparation for next time, closing the loop.

</details>

<details>
<summary><b>❓ What's the difference between containing a threat by isolating a host versus monitoring it, and how do you decide which to use?</b></summary>

Isolating a host means cutting off its network access (often via EDR network containment, or physically/logically disconnecting it) so the attacker loses the ability to communicate with it, move laterally from it, or exfiltrate further data — the priority is stopping the bleeding immediately. Monitoring instead of isolating means deliberately leaving a compromised host live and connected while watching it closely, usually because the investigation needs to observe the attacker's behavior further — to identify what other systems they're pivoting to, what tools/infrastructure they're using, or the scope of what they've already accessed — information that might be lost or become unobservable the moment they're cut off. The decision depends on weighing further damage risk against intelligence value: if the compromised asset holds highly sensitive data, has broad access to critical systems, or there's evidence of active exfiltration, immediate isolation usually wins because the cost of more damage outweighs the value of more observation. If the incident appears contained to a lower-value asset and the team has strong monitoring in place, deliberately watching a bit longer to fully scope a wider campaign (sometimes without the attacker realizing they've been noticed) can be worth it — but this is a judgment call that should involve more than a lone L1 analyst, since letting a live attacker continue operating always carries risk. In interviews, it's good to note that this decision is rarely made by one person unilaterally — it typically involves IR leadership or the incident commander given the tradeoffs involved.

</details>

<details>
<summary><b>❓ What is an "incident commander" or similar role, and why does incident response need clear roles during a live incident?</b></summary>

An incident commander (or equivalent lead role) is the person responsible for coordinating the overall response to a significant incident — making key decisions (like containment strategy), keeping track of what's been done and what's still open, coordinating communication between technical responders, management, and sometimes legal/PR, and making sure the incident doesn't stall because everyone assumed someone else was driving. Clear roles matter because incidents are chaotic and time-pressured by nature; without a defined lead, you get duplicated effort, contradictory actions (one person isolates a host while another is mid-investigation on it and loses live data), and slow decision-making because nobody has authority to make the call. Beyond the incident commander, larger incidents typically also define roles like technical lead(s) doing the hands-on investigation/containment, a communications lead managing stakeholder updates, and scribe/documentation duties to keep a timeline — because reconstructing "what happened and when" after the fact from memory is unreliable and often legally/contractually necessary.

</details>

<details>
<summary><b>❓ What should a good incident report or ticket include?</b></summary>

A good incident report should let someone who wasn't involved understand exactly what happened, what was done, and what should happen next, without needing to ask the author follow-up questions. At minimum it should include: a clear summary of the incident (what happened, in plain language, before the technical detail); a timeline of key events with timestamps (when the activity started, when it was detected, when key response actions were taken); the affected scope (which systems, accounts, and data, and how that scope was determined); the evidence and indicators that support the findings (log excerpts, IOCs, screenshots as appropriate); the actions taken and by whom (containment steps, eradication steps, and their outcomes); the current status and any remaining open items or follow-ups; and a root cause or contributing factors section once known. Good reports are written for two audiences at once — technical readers who need the detail to verify or continue the work, and non-technical stakeholders (management, sometimes legal) who need the plain-language summary and business impact without wading through log data. Vague language ("something suspicious happened on the server") is a common weakness — specificity (which server, what indicator, what timeframe) is what makes a report actually useful later, whether for a legal proceeding, an insurance claim, or simply the next analyst who picks up a related alert months later.

</details>

<details>
<summary><b>❓ What's the difference between an incident and an event, in IR terminology?</b></summary>

An event is any observable occurrence in a system — logging in, a file being modified, a network connection being made — most of which are entirely routine and benign. An incident is a specific subset: an event or set of events that represents an actual or likely violation of security policy, or a genuine threat to confidentiality, integrity, or availability of systems or data. In other words, all incidents are made up of events, but the overwhelming majority of events are not incidents. This distinction matters practically because it defines when the formal IR process (with its documentation, escalation, and possibly legal/regulatory obligations) actually kicks in — treating every anomalous event as a full incident would be unsustainable, but failing to recognize when a pattern of events has crossed into "this is a real incident" territory delays response at exactly the point where speed matters most.

</details>

---


## 🔬 Digital Forensics Fundamentals


<details>
<summary><b>❓ What is chain of custody and why does it matter?</b></summary>

Chain of custody is the documented, unbroken record of who collected a piece of evidence, when, how it was handled, where it was stored, and who accessed it at every point from collection to final use (whether that's an internal report, HR action, or legal proceeding). It matters because evidence is only as trustworthy as its documented handling — if there's a gap where it's unclear who had access to a piece of evidence or whether it could have been altered, the evidence's credibility (and sometimes its legal admissibility) is undermined, regardless of how technically sound the original collection was. In practice this means things like: taking cryptographic hashes of forensic images at collection time and re-verifying them before analysis to prove the data hasn't changed, logging every transfer of physical media or access to evidence storage, and keeping collection notes detailed enough that someone else could reproduce or verify the process. Even in incidents that never end up in a courtroom, maintaining chain of custody discipline is good practice because you often don't know at the outset of an investigation whether it will end up needing that level of rigor later.

</details>

<details>
<summary><b>❓ What is the "order of volatility" and why does it guide evidence collection?</b></summary>

Order of volatility is the principle that evidence should be collected starting with the data most likely to be lost or changed soonest, and working toward the most persistent/durable evidence last. The typical ordering, from most to least volatile, is roughly: CPU registers and cache, then RAM (memory contents), then network state (active connections, ARP cache, routing tables), then running processes, then disk/storage contents, then remote logging/monitoring data held elsewhere, and finally physical configuration and topology information. This matters because if you power off a running compromised machine before capturing memory, you permanently lose anything that existed only in RAM — encryption keys in use, malware that only exists in memory and never touched disk (fileless malware), active network connections, and command-line arguments of running processes — even though the disk (much less volatile) would still be recoverable hours or days later. A common interview trap is a scenario like "you find a compromised, still-running server — what's your first action?" where the wrong instinct is to immediately shut it down; the order-of-volatility-aware answer is to capture volatile evidence (memory, network state) first, then move to less volatile sources, and only power down/image the disk once the volatile evidence is safely preserved (and even then, considering whether the containment need — like an active exfiltration — outweighs finishing full volatile collection first).

</details>

<details>
<summary><b>❓ What's the difference between volatile and non-volatile evidence? Give examples of each.</b></summary>

Volatile evidence is data that is lost when a system loses power or is significantly altered by continued normal operation of the system — the classic example is RAM contents, but it also includes things like active network connections, the list of currently running processes, logged-in users, and the contents of the clipboard. Non-volatile evidence persists through a power cycle and generally doesn't disappear just from a reboot — disk contents, log files that have already been written to storage, registry hives, and configuration files are the standard examples. The practical implication is about collection order and urgency: volatile evidence needs to be captured live, while the system is still running, because it cannot be recovered afterward, whereas non-volatile evidence can typically be collected later via a forensic disk image without losing anything (as long as the disk itself isn't wiped or overwritten in the meantime). This is also why "just pull the network cable and power it off" is often bad first-response advice for a running compromised system — it guarantees loss of all volatile evidence — whereas it might be entirely appropriate once volatile capture is done, or if the containment risk (active exfiltration, ransomware still encrypting) is judged to outweigh that loss.

</details>

<details>
<summary><b>❓ What is a memory dump and what can an analyst do with it?</b></summary>

A memory dump (or memory capture/memory image) is a snapshot of a system's RAM contents captured at a point in time, typically taken with a dedicated forensic tool designed to minimize alteration of the system while capturing. Conceptually, RAM is where a huge amount of the "live" state of a compromised system lives — running processes and their loaded modules, network connections, decrypted data that only exists unencrypted in memory (like malware payloads that decrypt themselves at runtime and never write the plaintext to disk, or credentials cached by the OS), and command-line arguments that reveal exactly how a process was launched. An analyst working from a memory dump can identify malicious or injected processes that might not be visible from a live system (some malware actively hides from normal process listings but is still findable by examining raw memory structures), recover network connection state at the time of capture, and pull out artifacts like encryption keys or malware configuration that would otherwise be encrypted or absent from disk entirely. Memory analysis is a specialized skill (often involving dedicated memory forensics tooling) but knowing conceptually why it's collected and what unique value it has over disk analysis is a very common interview topic.

</details>

<details>
<summary><b>❓ What is a disk image, and why do forensic investigators image a disk rather than just copying files off it?</b></summary>

A disk image is a complete, bit-for-bit copy of a storage device — every sector, including deleted files that haven't been overwritten, file system metadata, slack space, and unallocated space — rather than a normal file copy which only captures the currently-visible, named files. Investigators image the whole disk rather than copying select files for two main reasons: first, a huge amount of forensically valuable data lives outside of what a normal file browse would show you — deleted files often remain fully or partially recoverable in unallocated space until overwritten, and file system metadata (timestamps, allocation records) can reveal activity like when a file was deleted or when a USB device was connected, none of which survives a simple file copy; second, working from a verified, hashed image (rather than the live original) preserves the original evidence untouched and lets analysis happen on a copy, so if something goes wrong during analysis or the analyst needs to start over, the original is unaffected and defensible. Best practice is to image using a write-blocker (hardware or software that prevents any write operation from reaching the source disk during imaging) and to hash both the source and the resulting image (commonly with something like SHA-256) so it can later be proven the image is an exact, unaltered copy.

</details>

<details>
<summary><b>❓ What's the difference between an Indicator of Compromise (IOC) and an Indicator of Attack (IOA)?</b></summary>

An IOC is evidence that a compromise has already happened — a static, after-the-fact artifact like a malicious file hash, a known-bad IP address or domain, a specific registry key created by malware, or a particular filename. IOCs are useful for confirming "was this specific known-bad thing present here" and for sharing threat intelligence (block this hash, alert on this domain), but they're inherently reactive and brittle — a hash changes the instant an attacker recompiles their tool, and a domain can be swapped out in minutes. An IOA, by contrast, describes the pattern of behavior or intent behind an attack in progress, independent of the specific tools used — for example, "a process is enumerating and dumping credentials from LSASS memory" or "a user account that normally only logs in from one region is authenticating from two geographically distant locations within an implausible timeframe." IOAs are focused on the "what is this actor trying to do" rather than "what specific artifact did they leave," which makes them much harder for an attacker to evade just by changing a hash or domain, since they'd have to fundamentally change their approach or objective. A mature detection strategy uses both: IOCs for fast, cheap matching against known threats (and for retroactive hunting once new intel arrives), and IOAs for catching novel or previously-unseen tooling based on behavior alone.

</details>

---


## 🌍 Threat Intelligence


<details>
<summary><b>❓ What are the four common levels/types of threat intelligence, and who consumes each?</b></summary>

Threat intelligence is usually categorized by the audience and timeframe it serves:

- **Strategic** — high-level, non-technical intelligence about trends, threat actor motivations, and the broader risk landscape (e.g., "ransomware targeting this industry sector has increased this year, driven by these factors"). Consumed by executives and leadership to inform budget, risk appetite, and overall security strategy.
- **Operational** — intelligence about specific planned or ongoing campaigns and the capabilities/intent of specific threat actors or groups relevant to the organization, often used to anticipate what might target the org next. Consumed by security management and IR leadership for planning and prioritization.
- **Tactical** — information about the tactics, techniques, and procedures (TTPs) adversaries use — the "how" of attacks, often mapped to a common technique framework, so defenders can build detections and adjust defenses around actual attacker behavior rather than guessing. Consumed by detection engineers and SOC analysts.
- **Technical** — the most granular level: specific technical indicators like IP addresses, file hashes, domains, and URLs associated with malicious activity. Consumed directly by security tools (for blocking/alerting) and analysts doing hands-on investigation, but has the shortest useful shelf life since these indicators change fastest.

A useful way to remember the distinction in an interview: strategic answers "why should we care," operational answers "what's likely coming for us," tactical answers "how do these attacks actually work so we can detect them," and technical answers "what specific things do I search/block for right now."

</details>

<details>
<summary><b>❓ Where does threat intelligence actually come from? Name some source categories.</b></summary>

Threat intel comes from a mix of source types, each with different strengths: **OSINT (open-source intelligence)** — publicly available information like security researcher blog posts, public vulnerability disclosures, threat actor reporting shared by the community, and even open forums/paste sites where leaked data or attacker chatter sometimes surfaces; it's free and broad but requires effort to vet quality and relevance. **ISACs/ISAOs (Information Sharing and Analysis Centers/Organizations)** — sector-specific information sharing bodies where organizations in the same industry share indicators and warnings about threats targeting their sector, valuable because the intel is pre-filtered for relevance to a specific industry's threat landscape. **Commercial threat intel feeds** — paid subscriptions that provide curated, often faster and higher-fidelity indicator feeds, sometimes with analyst-written context and campaign tracking, typically integrated directly into a SIEM or SOAR for automatic enrichment. **Internal telemetry** — an organization's own incident history and detection findings are themselves a threat intel source; what an org has actually been targeted by before is often the most directly relevant intelligence it has, and mature SOCs feed their own past incidents back into future detection tuning. A good threat intel program typically blends several of these rather than relying on just one, because each source has coverage gaps and different latency (community OSINT might be slower but broader, commercial feeds faster but narrower to what that vendor tracks).

</details>

<details>
<summary><b>❓ How does threat intelligence actually feed into detection and SOC operations in practice?</b></summary>

Threat intel is only valuable if it changes what the SOC actually does, and it plugs in at several concrete points: technical indicators (IPs, domains, hashes) get loaded into the SIEM, firewall, or EDR as watchlists or blocklists, so a match generates an automatic alert or is blocked outright — this is the fastest, most direct feedback loop. Tactical intelligence about TTPs informs detection engineering — if intel reporting says a threat actor targeting the org's sector is using a particular living-off-the-land technique, that becomes a driver for writing or prioritizing a new detection rule for that behavior, rather than waiting to be hit by it first. Operational intelligence about active or emerging campaigns can drive proactive threat hunting — an analyst deliberately searching historical logs for signs of a specific campaign's known indicators or behavior, rather than waiting for an alert. And strategic intelligence informs risk prioritization and resourcing decisions above the SOC floor level, like which asset classes get the most monitoring investment. The common failure mode worth mentioning in an interview is treating threat intel as a passive feed nobody actually reviews or acts on — the value only materializes when there's a defined process for turning intel into a new detection, a hunt, or a blocklist entry, not just a dashboard of indicators nobody looks at.

</details>

<details>
<summary><b>❓ What's the difference between threat intelligence and just having a list of "bad" IPs and hashes?</b></summary>

A raw list of malicious IPs and hashes is technical-level threat data — useful as an input, but on its own it's just indicators without context. Threat intelligence, properly defined, includes the analysis and context around that data: why is this indicator considered malicious, what threat actor or campaign is it associated with, what's the confidence level in the attribution, what TTPs typically accompany it, and what's the likely relevance to this specific organization. That context is what makes intelligence actionable rather than just noisy — knowing an IP is "bad" tells you to block it, but knowing it's associated with a specific ransomware affiliate's staging infrastructure tells you to also check for the specific precursor behaviors that group is known to use before deploying ransomware, which is a much more valuable, proactive response. This distinction — data versus intelligence, where intelligence implies analysis and context that supports a decision — is a common interview framing worth having ready.

</details>

---


## 📈 Detection Engineering & Metrics


<details>
<summary><b>❓ What is MTTD and MTTR, and why do they matter to a SOC?</b></summary>

MTTD (Mean Time to Detect) measures the average time between when a security incident actually begins (or when the first relevant evidence exists) and when it's actually detected/identified by the security team. MTTR (Mean Time to Respond, sometimes Mean Time to Resolve/Remediate) measures the average time from detection to the incident being contained/resolved. Both matter because they're direct proxies for how much damage an attacker can do — the longer detection takes, the more time an attacker has to move laterally, escalate privileges, and exfiltrate data before anyone notices (dwell time), and the longer response takes after detection, the longer that damage continues even once it's known. These metrics are useful for tracking whether SOC investments (better log coverage, better detection rules, more staffing, automation) are actually improving outcomes over time, and they're often reported to leadership as a proxy for overall security program maturity. A nuance worth mentioning in an interview: these numbers can be gamed or misleading if taken in isolation — a SOC could artificially lower MTTR by closing incidents prematurely before they're actually resolved, so mature programs pair MTTD/MTTR with quality metrics (like reopened-incident rate) rather than optimizing speed alone.

</details>

<details>
<summary><b>❓ What other SOC metrics matter besides MTTD/MTTR, and what does each tell you?</b></summary>

A few other commonly tracked metrics and what they reveal: **Alert volume** (total alerts generated, often broken down per rule or per source) helps identify which detections are noisy contributors versus quiet, high-value ones, and tracks overall load on the team. **False positive rate** (proportion of alerts that turn out to be benign) is a direct measure of detection quality and a leading indicator of alert fatigue risk if it's high. **Escalation rate** (proportion of L1-triaged alerts that get escalated to L2/L3) helps assess whether L1 playbooks and training are effective, and whether detections are well-tuned enough that most alerts really can be resolved at the first tier. **Time-to-triage** (how long an alert sits before an analyst first looks at it) is a leading indicator distinct from MTTD/MTTR that flags queue backlog problems before they become full-blown detection delays. **Coverage metrics** — often measured against a known technique framework — track what proportion of common attacker techniques the org actually has detection logic for, which is a more proactive, gap-focused metric than any of the reactive/after-the-fact numbers above. No single metric tells the whole story; a good SOC dashboard combines volume, quality (false positive rate), speed (MTTD/MTTR/time-to-triage), and coverage together, because optimizing any one of them in isolation can create bad incentives (e.g., minimizing false positives by writing extremely narrow rules that also raise false negatives).

</details>

<details>
<summary><b>❓ What is detection coverage, and how would you go about identifying gaps in it?</b></summary>

Detection coverage refers to how comprehensively an organization's detection rules and monitoring actually address the range of techniques a realistic adversary might use — as opposed to just having "a lot of alerts," which says nothing about whether the alerts that exist actually map to real attacker behavior. A common way to assess this is to map existing detections against a structured knowledge base of adversary tactics and techniques (many SOCs use a widely adopted public framework for this), which lets a team visualize, technique by technique, whether they have no coverage, partial coverage (e.g., only through EDR default detections with no custom tuning), or strong, tested coverage (validated through actual purple-team or detection-testing exercises, not just "we assume our EDR catches that"). Identifying gaps typically involves this kind of mapping exercise combined with intelligence about which techniques are actually most relevant to the organization's threat landscape (there's no need to over-invest in coverage for techniques irrelevant to your environment while ignoring ones your actual likely adversaries use), and then prioritizing new detection engineering work toward the highest-risk, currently-uncovered techniques rather than techniques that already have redundant coverage.

</details>

<details>
<summary><b>❓ What's the tradeoff between detection sensitivity and analyst workload, and how do you approach tuning a noisy rule?</b></summary>

Making a detection rule more sensitive (broader matching logic, lower thresholds) generally increases the chance of catching real malicious activity but also increases false positives and analyst workload; making it stricter reduces noise but risks missing real activity that doesn't fit the narrower pattern — this is the core precision/recall tradeoff every detection engineer has to manage. When tuning a chronically noisy rule, the right approach is not to just blanket-suppress it, but to first characterize *why* it's noisy: is it firing on a specific known-benign pattern (a particular admin tool, a specific scheduled task, a specific service account) that can be explicitly excluded without weakening the rule's coverage elsewhere, or is the underlying logic itself just too broad for the behavior it's trying to catch, in which case the detection logic needs to be reworked (e.g., adding an additional condition that better distinguishes malicious from benign instances of the same base behavior) rather than just excluded case by case. Blanket suppression (just telling the SIEM to stop alerting on a whole rule) should be a last resort, because it usually throws away the true positives along with the false positives; targeted exclusions and logic refinement preserve detection capability while cutting the noise. It's also worth tracking tuning changes over time and revisiting them, since an exclusion that was safe six months ago (e.g., excluding a specific admin account from a rule) can become a blind spot later if that account's usage pattern or risk profile changes.

</details>

<details>
<summary><b>❓ Why might a SOC choose to build a custom detection rule instead of relying only on out-of-the-box vendor detections?</b></summary>

Out-of-the-box detections from a SIEM or EDR vendor are built to work reasonably well across a huge range of different customer environments, which means they're necessarily somewhat generic — they can't be tuned to the specific normal behavior, business processes, or risk priorities of any one organization. A custom rule can incorporate context that only that organization has: which accounts are actually service accounts that legitimately behave in ways that would otherwise look suspicious, which assets are the organization's actual "crown jewels" that deserve tighter monitoring thresholds, and which specific techniques threat intelligence has flagged as relevant to that org's sector or past incident history. Custom detections are also how a SOC closes coverage gaps that out-of-the-box rules simply don't address — vendor detections tend to focus on broadly common attack patterns, but an organization's actual biggest risks might be more specific (a particular internal application's abuse patterns, for example). The tradeoff is that custom rules require ongoing engineering and maintenance effort that vendor-managed detections don't, so most mature SOCs use both — vendor detections as a baseline safety net, and custom detection engineering focused specifically on their own environment's context and known gaps.

</details>

---


## 📌 Quick Reference


### Incident Response Lifecycle

| Phase | Core Question | Example Activity |
|---|---|---|
| Preparation | Are we ready before anything happens? | Playbooks, logging coverage, trained team, tested tools |
| Identification | Is this actually an incident? | Alert triage, initial scoping, confirming it's real |
| Containment | How do we stop it from getting worse? | Isolate host, disable account, block IOC |
| Eradication | How do we remove the cause? | Delete malware, close vulnerability, remove persistence |
| Recovery | How do we safely get back to normal? | Restore from clean backup, verify, monitor closely |
| Lessons Learned | What do we fix for next time? | Post-incident review, new detections, process updates |

### Order of Volatility (most → least volatile)

| Order | Evidence Type |
|---|---|
| 1 | CPU registers / CPU cache |
| 2 | RAM (memory contents) |
| 3 | Network state (connections, ARP cache, routing tables) |
| 4 | Running processes |
| 5 | Disk / storage contents |
| 6 | Remote logging / monitoring data |
| 7 | Physical configuration / network topology |

### Common Log Sources

| Source | Best For |
|---|---|
| Windows Event Log | Authentication, account/group changes, service installs |
| Sysmon | Detailed process creation, parent-child chains, network/file/registry activity |
| Firewall | Allowed/denied network connections, scanning activity |
| Proxy | Outbound web traffic, phishing follow-through, exfil via web |
| DNS | Domain resolution patterns, C2 domains, DNS tunneling |
| EDR | Rich host telemetry, behavioral detections, direct response actions |

### SOC Analyst Tiers

| Tier | Focus |
|---|---|
| L1 | Initial triage, playbook-driven investigation, first-pass true/false positive calls |
| L2 | Deep investigation, cross-source pivoting, scoping, initial containment ownership |
| L3 | Complex forensics/malware analysis, threat hunting, detection engineering, mentoring |

### Threat Intelligence Levels

| Level | Audience | Answers |
|---|---|---|
| Strategic | Executives/leadership | Why should we care about this trend? |
| Operational | IR/security management | What's likely to target us next? |
| Tactical | Detection engineers/analysts | How do these attacks actually work? |
| Technical | Tools/analysts (hands-on) | What specific indicators do I act on now? |

### IOC vs. IOA

| | Indicator of Compromise (IOC) | Indicator of Attack (IOA) |
|---|---|---|
| Nature | Static artifact (hash, IP, domain) | Behavioral pattern / intent |
| Timing | After-the-fact evidence | Detects activity in progress |
| Durability | Brittle — changes easily | Harder to evade — tied to technique, not tool |

---

*Disclaimer: This document is for educational and interview-preparation purposes only and does not constitute professional, legal, or forensic guidance.*
