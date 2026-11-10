# HealthConnect CareLoop — Final Presentation and Demo Script

**Target length:** 12 minutes plus Q&A. A 7-minute cut is in section 5.
**Rule:** say only numbers you have seen in your own org on the day. All data is synthetic, so say so once at the start.

## 1. Preparation (evening of 11 Nov and morning of 12 Nov)

| # | Task | Command / place |
|---|---|---|
| 1 | Demo clock empty (or today) | Setup → Custom Metadata → CareLoop Setting → Default |
| 2 | Fresh Phase 4–6 results | `phase4-run-sweep-now.apex`, then `phase6-plan-now.apex` |
| 3 | Fresh Sentinel data and scan | `innovation-remove-demo-data.apex` → `innovation-sentinel-demo-data.apex` → `innovation-run-scan.apex` |
| 4 | Leave the Moinabad fever signal in status **New** | Do not review it before the demo |
| 5 | Regression is green | `scripts/run-all-verifications-with-sentinel.ps1` (screenshot it for the slide) |
| 6 | Browser tabs ready | (a) CareLoop app as admin; (b) Login-As Lakshmi; (c) Login-As Meena; (d) portal as Kavya; (e) Programme Intelligence dashboard; (f) Sentinel dashboard |
| 7 | Zoom 110–125%, notifications on, phone silent | |

## 2. Storyline

> *"Lakshmi is a health worker in Kondapur and Moinabad. CareLoop makes sure every child, mother and chronic patient gets the right care at the right time, in their own language and with their consent. And with Sentinel, it now also watches the whole community for early signs of trouble."*

## 3. Full script (≈ 12 min)

| Time | Screen | Say (in your own words) | Show |
|---|---|---|---|
| 0:00–0:45 | Title + architecture slide | Problem: missed vaccines and follow-ups, workers with paper lists, no early view of community trends. Solution: one Salesforce platform for workers, doctors, managers and patients. | Architecture diagram |
| 0:45–2:00 | Household → **Register Patient** (Phase 7 flow) | Register a baby; CareLoop creates the immunisation schedule automatically from configuration (Phase 3). | New baby's Care Activities |
| 2:00–3:00 | Record a visit with high BP / low SpO2 | Red flag from configurable thresholds; Arjun gets a live bell and the Doctor Review queue refreshes (Phase 4). | Doctor Review tab |
| 3:00–3:45 | Doctor recommendation (Final) | The recommendation becomes follow-up activities: the care plan closes the loop. | Activities created |
| 3:45–4:45 | Patient priority card + nightly sweep results | Explainable priority: every point has a reason. Reminders go out in Telugu or English, only with consent; escalation goes to the worker, then the supervisor. | Priority card, Notifications |
| 4:45–5:30 | Portal as Kavya (Phase 5) | Kavya sees her child's care and replies with one tap; consent is recorded in a hash-chained ledger. | Portal home, consent ledger |
| 5:30–6:30 | **Care Navigator** (Phase 6) | Lakshmi's day planned by household and village, within her capacity, with the measured gain over a due-date list. | Navigator plan |
| 6:30–7:00 | Request Closure → approval (Phase 7) | Missed or cancelled care needs a reason and supervisor approval. | Approval |
| **7:00–7:40** | **Sentinel, the problem** | "Everything so far looks at **one patient**. But Meena also needs to know if **a village** is getting sick. That normally shows up in a monthly report: too late for a fever cluster." | Slide |
| **7:40–8:20** | **Method** slide | "Every morning at 6:30 Sentinel compares each village's week with **its own previous four weeks**: fever, breathing problems, unreachable households, delayed vaccines. Clearly higher is a **Watch**, far higher is an **Alert**. Minimum counts and a history check stop false alarms. It does not diagnose; it tells a person *where to look*." | Detection flowchart |
| **8:20–9:10** | **Community Watch** (as Meena) | Grid: Moinabad fever is red. Read the real numbers from the tooltip. Point out Kondapur respiratory, Kandukur unreachable and Shamshabad vaccine delay. Grey "no history yet" cells are never flagged. | Grid |
| **9:10–10:00** | Moinabad signal card → **Details and review** | Bars: quiet weeks, then a spike. Read the explanation. *Suggested verification* gives process steps (ASHA visit, inform the PHC Medical Officer). Evidence is sharing-aware. Click **Dismiss** without a note: blocked. Type a note → **Acknowledge (Investigating)**. | Review panel |
| **10:00–10:30** | Bell + **Run scan now** | "Meena and the doctor got a bell. Re-scanning updates the same signal, so there are no duplicates." | Toast |
| **10:30–11:00** | Lakshmi's view | Read-only, and counts only from her own region's records. No scan button. | Lakshmi tab |
| **11:00–11:30** | Sentinel dashboard / Programme Intelligence | Village-level counts only, never patient names. Shows confirmed vs dismissed for threshold tuning. | Dashboard |
| 11:30–12:00 | Close: quality slide | "Salesforce-native, no paid APIs, rules in custom metadata. **[N] Apex tests passing, [X]% coverage, 8 verification scripts green** (say only what you saw)." | Screenshot of results |

## 4. Hand-off lines between presenters (if a team)

- After the Navigator: *"Navigator helps one worker plan her day; Sentinel helps the programme see the whole district."*
- Before Q&A: *"Everything you saw is live in our Developer Edition org, and the data is synthetic."*

## 5. 7-minute cut

0:00 problem and architecture → 1:00 register patient and schedule → 2:00 red flag and doctor bell → 3:00 Navigator → 4:00 Sentinel method → 4:40 Community Watch and review → 6:00 Lakshmi read-only + dashboard → 6:30 quality slide.

## 6. Fallbacks

| Problem on stage | Do this |
|---|---|
| A page does not load | Switch to the pre-opened tab; say "this is the same screen from a minute ago" |
| Bell does not appear | Show the Community Signal record and the scan output screenshot |
| Sentinel is not deployed by 12:00 on 11 Nov | Demo Phases 1–7; one slide: "Next: CareLoop Sentinel, designed and source-complete, not yet deployed"; answer Q&A honestly |
| A judge asks for a live scan | Click **Run scan now**; it is safe to repeat |

## 7. Never say

"Predicts outbreaks", "detects disease", "AI-powered", "real patient data", any number you have not seen today, or "confirmed outbreak". The Sentinel statuses are deliberately *Investigating / Closed / Dismissed*, never "Confirmed".

Questions and answers: `HealthConnect_CareLoop_Panel_QA.md`.
