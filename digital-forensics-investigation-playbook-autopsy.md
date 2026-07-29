# Digital Forensics Investigation Playbook (Autopsy)

A scenario-driven walkthrough of an actual disk-forensics case in Autopsy — for the tool mechanics themselves (module names, menu locations, ingestion settings), see [`volatility-autopsy-forensics-cheatsheet-professional.md`](volatility-autopsy-forensics-cheatsheet-professional.md). This document is about **which investigative question you're answering, and where to look for it**, once a disk image lands on your desk.

---

## Phase 0 — Case Setup (Every Investigation)

1. Create a **New Case**, add the disk image as a data source, and let the standard ingestion modules run fully before drawing conclusions (hash lookup, keyword search, recent activity, web artifacts, EXIF, embedded file extraction) — partial ingestion results can be misleading.
2. Note the specific question you were asked to answer **before** you start browsing the image — "was there data theft," "was malware executed," "what did the user do and when" are different investigations with different starting points, even on the same image.
3. Open the **Timeline** view early regardless of the specific question — it's the fastest way to orient yourself around the window that actually matters, rather than browsing the filesystem cold.

---

## Playbook 1 — "Did the User Exfiltrate Data via USB / Removable Media?"

**Trigger:** Insider-threat concern, or an employee departure investigation, involves suspected data theft to removable media.

1. Check the **Registry Viewer** (`SYSTEM` hive) `USBSTOR` key for every USB device ever connected, and cross-reference against connection timestamps to narrow to the relevant window.
2. Check **Recent Documents** and **Shellbags**/`TypedPaths` (`NTUSER.DAT`) for evidence of the user browsing to the USB drive letter and interacting with files around the same time.
3. Check **LNK files** (shortcut files, auto-created when a user opens a document) for references to files that existed on the removable device — these often survive even if the original file/device is gone.
4. Check **Recycle Bin** contents and file-system metadata (MAC times — Modified/Accessed/Created) for evidence of files being copied, moved, or deleted around the connection window.
5. **Escalate if:** LNK/Recent-Documents evidence shows sensitive files being accessed at the same time an unfamiliar/unauthorized USB device was connected.
6. **Close as benign if:** USB activity corresponds to an approved, documented use case (backup process, authorized data transfer) with no sensitive-file access pattern.

---

## Playbook 2 — "Was Malware Executed on This Host?"

**Trigger:** Suspected malware execution, often as a follow-up to an EDR/AV alert where a memory image wasn't available or additional disk-side confirmation is needed.

1. Check **Shimcache/AmCache** (via the registry or `C:\Windows\AppCompat\Programs\Amcache.hve`) for evidence the suspect file was executed, even if it was later deleted — this is often the single most valuable artifact for "did this file run."
2. Check **Prefetch** files for execution count and last-run timestamps corroborating the suspected timeframe.
3. Run **Keyword Search** against known IOCs from the alert (filename, hash, any known strings from the sample) directly against the image, including unallocated space if the file may have been deleted.
4. Check **Deleted Files** module specifically — attackers/malware frequently delete their own dropper after execution; recovering it (or at least confirming it existed) is high-value.
5. Check persistence locations (Run keys, scheduled tasks, services — see the Registry Quick Hits table in [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md)) for anything tied to the same timeframe.
6. **Escalate if:** Shimcache/AmCache/Prefetch confirms execution and persistence artifacts are found.
7. **Close as benign if:** the file was present but no execution artifact (Shimcache/Prefetch) confirms it actually ran.

---

## Playbook 3 — "What Did the User Do, and When?" (General Activity Reconstruction)

**Trigger:** HR/insider-threat case, or building a timeline to corroborate/refute a user's account of events.

1. Build the **Timeline** view around the window in question first — this is the backbone the rest of the investigation hangs off of.
2. Check **Web Artifacts** (browser history, downloads, cookies) if the question involves web activity — searches performed, sites visited, files downloaded.
3. Check **UserAssist** (ROT13-encoded, `NTUSER.DAT`) for GUI program execution history — useful for establishing "the user ran this program at this time" even for programs with no other logging.
4. Check **Recent Documents** and **Jump Lists** for a picture of which files the user actually opened, in what order.
5. Cross-reference every artifact against the same timeline — a coherent story across multiple independent artifact types (web history + UserAssist + recent docs all agreeing) is far stronger evidence than any single artifact alone.
6. **Escalate/report findings** once the timeline is internally consistent and answers the specific question you were asked — don't over-scope into unrelated activity not covered by the investigation's authorization.

---

## Phase Closing — Reporting Discipline

- Every claim in the final report should point to a specific artifact (registry key, file path, timestamp) — "the user accessed the file" is not evidence on its own, the Shellbag/LNK/timestamp backing it up is.
- State explicitly where artifacts are **absent** as well as where they're present — "no execution artifact was found for this file" is itself a meaningful finding, not a gap to gloss over.
- Keep the MAC-time caveats in mind — filesystem timestamps can be altered by normal system activity (backups, AV scans, file copies); corroborate with a second artifact type before treating a timestamp as definitive.

---

*Tool mechanics: [`volatility-autopsy-forensics-cheatsheet-professional.md`](volatility-autopsy-forensics-cheatsheet-professional.md). Memory-side companion: [`memory-and-disk-forensics-quickref.md`](memory-and-disk-forensics-quickref.md). Linux-side equivalent: [`linux-forensics-and-artifact-analysis-cheatsheet.md`](linux-forensics-and-artifact-analysis-cheatsheet.md). BTL1 exam methodology: [`btl1-incident-response-exam-checklist.md`](btl1-incident-response-exam-checklist.md).*
