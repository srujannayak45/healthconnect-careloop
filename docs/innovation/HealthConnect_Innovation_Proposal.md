# HealthConnect CareLoop — Innovation Proposal

**Prepared:** 10 November 2026 · **Baseline:** commit `5ef9d6a` (Phases 1–7: 123 Apex tests passing, 89% coverage, 7 verify scripts green)
**Status of this document:** evaluation and recommendation. **Decision: Sentinel approved on 10 Nov 2026, 14:44 IST.**

> **Changes after approval (v2 package):**
> - Review statuses are now *New / Investigating / Closed / Dismissed*. "Confirmed" was removed so that nothing can read as "outbreak confirmed".
> - A missing-history safeguard was added (`Min_History_Weeks__c`): a village with no recorded data is "not assessed", not flagged.
> - Added a Sentinel dashboard and 2 more reports, 14 tests in place of 7, and a 10-check verify script.

---

## 1. Executive summary

| | |
|---|---|
| **Recommended innovation** | **CareLoop Sentinel — Community Health Early Warning** (your idea 4), with an *immunisation-delay* signal folded in |
| **One-line pitch** | Every morning CareLoop compares this week's fever, breathing-problem, missed-visit and late-vaccine counts in every village with *that same village's own last four weeks*, and raises a **Watch** or **Alert** with a plain-language reason when something is unusually high — so a programme manager hears about a fever cluster in Moinabad days before it shows up in a monthly report. |
| **Why this one** | It is the only shortlisted idea that (a) answers the challenge's own words — *"actionable insights into regional health trends"* — directly, (b) uses data CareLoop already captures but **no Phase 1–7 code reads** (`Symptoms__c`, `Temperature__c`, `SpO2__c`, unsuccessful visit outcomes as a trend), (c) is 100% Salesforce-native with no paid API, and (d) produces a demo moment the panel will remember. |
| **Alternative** | **Referral Closure Intelligence** (idea 2). It is the safest strong option: `Medical_Recommendation__c.Referral_Required__c` exists but nothing tracks whether the referral was completed. |
| **Avoid** | Free-text multilingual NLU / LLM chat, IVR, offline mobile, live resource integrations, and combining three ideas at once with 1½ days left. |
| **Honest timing** | Building Sentinel from the provided source is about **4–6 hours of your time** including deploy errors and the demo dry-run. 10 Nov is your last build day. **Decision rule:** if all tests are not green by **12:00 on 11 Nov**, present Sentinel as *designed and partly built* (this proposal + architecture + the parts that deployed) and do not demo unfinished screens. |

---

## 2. What I found when I inspected your repository

I unpacked the uploaded `healthconnect-careloop-master.zip` and read the metadata, classes and scripts rather than relying on your summary.

| Area | What actually exists | What it means for "innovation" |
|---|---|---|
| Data model | Village → Household (Account) → Patient (Contact); Health_Visit__c with vitals, `Symptoms__c` (multi-select: Fever, Cough, Breathlessness, Chest Pain…), `Visit_Outcome__c` (Completed / Patient Not Available / Patient Refused); Care_Activity__c with due/completed dates; Medical_Recommendation__c with `Referral_Required__c` | Rich, structured data already captured at the point of care |
| Automation | Red-flag rules (custom metadata), care schedules, nightly sweep, escalation ladder, priority scoring, platform-event alerts, SMS dispatch with consent ledger | Patient-level automation is mature |
| Phase 6 Navigator | Household-bundled daily visit planner with measured baseline | **Already an innovation** — your summary undersells it. Do not rebuild anything near it. |
| Reports | 8 reports (care gaps, coverage, overdue care, red flags, reminders, responses, priority, navigator impact) | Static, monthly-style views. None compares a village with its *own* normal. |
| **Never read by any class** | `Symptoms__c` (confirmed: zero references in `classes/` and `lwc/`), and Temperature/SpO2 are only used for single-patient red flags | **Community-level signal hidden in existing data — this is the gap Sentinel fills** |
| `Referral_Required__c` | Field exists on Medical_Recommendation__c and in 5 permission sets, no automation, no report | Gap for the alternative idea |
| README | Still the Phase 1 version | Update before submission regardless of innovation |

**Key insight:** Phases 1–7 look *down* at one patient at a time (red flags, priority, care gaps). Nothing looks *across* patients to notice that something is happening to a **community**. That is a genuine, non-duplicating step up, and it is exactly what the challenge statement's "regional health trends" asks for.

---

## 3. Evaluation of your five ideas (15 aspects each)

Scoring scale used in the narrative: ✅ strong · ⚠️ caution · ❌ weak.

### Idea 1 — Smart Multilingual Outreach

| # | Aspect | Assessment |
|---|---|---|
| 1 | Problem addressed | Patients who read Telugu/Hindi miss English reminders; free-text replies are not understood |
| 2 | Already in Phases 1–7? | ⚠️ **Largely yes.** `Preferred_Language__c`, language-specific templates, consent ledger, structured replies (Will Attend / Completed Elsewhere / Need Help) and escalation already exist |
| 3 | What would be genuinely new | Understanding *free-text* replies in Telugu/Hindi and auto-translating |
| 4 | Who benefits | Patients, health workers |
| 5 | Data needed / available | Reply texts — but SMS replies are simulated in the Developer org, so there is little real data |
| 6 | Salesforce-native approach | Einstein language features are not available in a Developer Edition at no cost; keyword matching is possible but brittle |
| 7 | Metadata impact | Small (fields + templates) |
| 8 | Automation complexity | High if NLU, low if keyword lists |
| 9 | Privacy & consent | ❌ Sending patient replies to an external LLM/translation API is a data-sharing decision the programme has not consented to |
| 10 | Role/region access | Unaffected |
| 11 | Clinical/claim risk | ⚠️ Mis-reading "I have fever" as "OK" is a safety issue |
| 12 | Effort for you | 8–12 h for anything real; needs a paid API for quality |
| 13 | Demo-ability | Medium — easy to show, hard to show *reliably* |
| 14 | Measurable outcome | Reply understanding rate (no real data to measure) |
| 15 | **Verdict** | **Do not pick.** Mostly duplicates Phase 5; the new part needs a paid AI service and adds privacy risk. "AI for marketing" in the panel's eyes. |

### Idea 2 — Referral Closure Intelligence

| # | Aspect | Assessment |
|---|---|---|
| 1 | Problem addressed | Doctors refer patients to a PHC/CHC; nobody knows if the patient went. Referral drop-off is a known weakness of community programmes |
| 2 | Already in Phases 1–7? | ✅ No. `Referral_Required__c` exists but nothing uses it |
| 3 | What would be genuinely new | A referral lifecycle (Referred → Appointment → Attended / Not attended), closure deadline, escalation and a "referral leakage" metric |
| 4 | Who benefits | Doctors, health workers, programme manager |
| 5 | Data needed / available | Recommendation data exists; attendance would be entered by the worker or patient portal |
| 6 | Salesforce-native approach | ✅ New object + record-triggered automation + reuse of the escalation ladder |
| 7 | Metadata impact | 1 object, ~10 fields, 1 report |
| 8 | Automation complexity | Medium (reuse EscalationService patterns) |
| 9 | Privacy & consent | ✅ Stays inside existing sharing; SMS to patient uses existing consent ledger |
| 10 | Role/region access | ✅ Child of patient → inherits sharing |
| 11 | Clinical/claim risk | ✅ Low — tracks a process, not a diagnosis |
| 12 | Effort for you | 4–6 h |
| 13 | Demo-ability | Good but similar in *shape* to Phase 4 escalation, so it feels familiar |
| 14 | Measurable outcome | % referrals closed within N days |
| 15 | **Verdict** | **Strong alternative.** Very sensible, low risk, but less distinctive: a judge may see it as "another tracking workflow". |

### Idea 3 — Resource Availability-Aware Outreach

| # | Aspect | Assessment |
|---|---|---|
| 1 | Problem addressed | Calling patients for a vaccine session when the vaccine or doctor is not available |
| 2 | Already in Phases 1–7? | No |
| 3 | What would be genuinely new | Schedule outreach against stock/staff availability |
| 4 | Who benefits | Patients, PHC |
| 5 | Data needed / available | ❌ **No source.** No stock, cold-chain or roster data exists; real data lives in eVIN/U-WIN, which you cannot integrate |
| 6 | Salesforce-native approach | Possible only with manually typed stock — which is fake data in a demo |
| 7 | Metadata impact | 2–3 objects |
| 8 | Automation complexity | Medium–high |
| 9 | Privacy & consent | Low risk |
| 10 | Role/region access | Needs new sharing for facility data |
| 11 | Clinical/claim risk | Low |
| 12 | Effort for you | 8–10 h |
| 13 | Demo-ability | Medium; panel will ask "where does the stock come from?" |
| 14 | Measurable outcome | Wasted trips avoided (unmeasurable here) |
| 15 | **Verdict** | **Avoid.** It would be built on invented integrations, which you asked me not to do. |

### Idea 4 — Community Health Early Warning (recommended → "CareLoop Sentinel")

| # | Aspect | Assessment |
|---|---|---|
| 1 | Problem addressed | Clusters (fever, respiratory illness, many households unreachable, vaccine doses slipping) are noticed late — usually in a monthly review |
| 2 | Already in Phases 1–7? | ✅ **No.** No code reads `Symptoms__c`; red flags are per-patient; reports are absolute counts with no "normal for this village" |
| 3 | What would be genuinely new | Village-by-village comparison with the village's own recent baseline, daily, with Watch/Alert levels, plain-language explanation, a human review workflow and evidence drill-down |
| 4 | Who benefits | Programme manager (primary), doctors, health workers (see their region) |
| 5 | Data needed / available | ✅ All already captured: symptoms, temperature, SpO2, visit outcome, immunisation due/completed dates |
| 6 | Salesforce-native approach | ✅ Custom metadata (signal definitions), Apex service, Schedulable job, LWC, custom notifications, report |
| 7 | Metadata impact | 2 new objects (1 custom metadata type), 4 signal records, 5 classes, 1 LWC, 2 tabs, 2 permission sets, 3 reports + 1 dashboard (v2); **1 existing metadata file modified** (CareLoop app, two tab entries) plus the project README |
| 8 | Automation complexity | Medium; the statistics are deliberately simple (mean, standard deviation) |
| 9 | Privacy & consent | ✅ Signals store **counts only**; drill-down to patients re-applies the viewer's sharing; no SMS is sent to patients, so no new consent needed |
| 10 | Role/region access | ✅ Counts are computed under the viewer's sharing; evidence is read in user mode; only managers can run scans or change status |
| 11 | Clinical/claim risk | ⚠️ Must be worded as *"unusual increase for investigation"*, never "outbreak" or "diagnosis". The design and UI do this |
| 12 | Effort for you | 4–6 h with the provided source |
| 13 | Demo-ability | ✅ Excellent: a coloured village × signal grid, a weekly bar chart that visibly spikes, a bell notification, a reviewer closing the loop |
| 14 | Measurable outcome | Days from first cases to review (time-to-detection); number of signals reviewed vs dismissed (false-alarm rate) |
| 15 | **Verdict** | **Pick this.** Highest innovation and differentiation with acceptable feasibility. Main risks are small-number false alarms (mitigated) and time. |

### Idea 5 — Outreach Impact Attribution

| # | Aspect | Assessment |
|---|---|---|
| 1 | Problem addressed | Which reminders/visits actually led to care being completed? |
| 2 | Already in Phases 1–7? | ⚠️ **Partly.** "Reminder Outcomes by Channel", "Patient Responses to Reminders" and "Navigator Impact by Plan" reports exist |
| 3 | What would be genuinely new | Attribution of completion to a specific touch |
| 4 | Who benefits | Programme manager |
| 5 | Data needed / available | Data exists but is small, synthetic and not randomised |
| 6 | Salesforce-native approach | Reports/Apex roll-ups |
| 7 | Metadata impact | Small |
| 8 | Automation complexity | Low–medium |
| 9 | Privacy & consent | Low risk |
| 10 | Role/region access | Unaffected |
| 11 | Clinical/claim risk | ❌ **Causal claims risk.** "SMS caused 30% more vaccinations" cannot be supported from observational demo data; a sharp judge will challenge it |
| 12 | Effort for you | 3–5 h |
| 13 | Demo-ability | Weak — it is another report |
| 14 | Measurable outcome | Needs a randomised experiment over weeks (see N9) |
| 15 | **Verdict** | **Do not pick now.** Mostly extends existing reports, and the honest version needs weeks of randomised data. |

---

## 4. Additional ideas (12)

| ID | Idea | What it is | Honest note |
|---|---|---|---|
| N1 | Zero-dose & dropout finder | Children who started immunisation (e.g. Penta-1) but never got later doses, by village | Valuable; **folded into Sentinel** as the `Immunisation_Delay` signal so you get it without a second build |
| N2 | Best-time-to-visit insight | Learn from `Visit_Outcome__c` by weekday/time which households are usually not at home | Useful but would need to change the Navigator → touches Phase 6 |
| N3 | Chronic-care control cascade | Screened → diagnosed → on treatment → controlled, for BP and sugar | Good public-health framing; close to existing care-gap reports |
| N4 | Data-quality sentinel | Detect copy-pasted vitals, round-number readings, visits logged at impossible speed | Strong programme value, weak demo |
| N5 | Caseload balancer | Compare each worker's load and priority mix | Near Navigator; risk of duplication |
| N6 | De-identified analytics extract | Aggregated, anonymised data for district officers | Needs governance decisions you cannot make |
| N7 | Immunisation session micro-planner | Plan session sites and dose counts per village | Needs vaccine stock data (same problem as idea 3) |
| N8 | ANC high-risk pregnancy tracker | Flag high-risk pregnancies from vitals/history | ❌ Clinical risk classification = unsupported clinical claims |
| N9 | Randomised reminder experiment | Randomly vary reminder timing/channel and measure | The honest way to do idea 5, but needs weeks |
| N10 | IVR / voice-call reminders | Voice calls for low-literacy patients | Needs paid telephony |
| N11 | Offline mobile capture | Capture visits without signal | Mobile offline setup is beyond the remaining time |
| N12 | LLM note summariser / chatbot | Summarise visit notes or chat with patients | Paid/External AI, privacy risk, "AI for marketing" |

---

## 5. Weighted scoring matrix

Weights you set: **Innovation 20% · Impact 20% · Feasibility 20% · Demo 15% · Differentiation 15% · Effort/Risk 10%** (for Effort/Risk, *higher = lower effort and risk*). Scores are 1–10. Weighted total = Σ(score × weight).

| Rank | Idea | Innov. | Impact | Feas. | Demo | Diff. | Effort/Risk | **Weighted** |
|---|---|---|---|---|---|---|---|---|
| 1 | **U4 Community Health Early Warning (Sentinel)** | 9 | 8 | 7 | 9 | 9 | 6 | **8.10** |
| 2 | U2 Referral Closure Intelligence | 6 | 8 | 8 | 7 | 6 | 7 | 7.05 |
| 3 | N1 Zero-dose & dropout finder | 6 | 8 | 8 | 6 | 6 | 8 | 7.00 |
| 4 | N3 Chronic-care control cascade | 6 | 7 | 7 | 6 | 6 | 6 | 6.40 |
| 5 | N2 Best-time-to-visit insight | 6 | 6 | 7 | 6 | 6 | 7 | 6.30 |
| 6 | N4 Data-quality sentinel | 5 | 6 | 8 | 5 | 5 | 8 | 6.10 |
| 7 | N9 Randomised reminder experiment | 7 | 6 | 6 | 4 | 7 | 6 | 6.05 |
| 8 | N7 Immunisation session micro-planner | 6 | 7 | 5 | 6 | 6 | 5 | 5.90 |
| 9 | N8 ANC high-risk tracker | 5 | 8 | 6 | 6 | 4 | 4 | 5.70 |
| 10 | U5 Outreach Impact Attribution | 6 | 6 | 6 | 5 | 5 | 5 | 5.60 |
| 11 | N5 Caseload balancer | 5 | 6 | 6 | 5 | 4 | 6 | 5.35 |
| 12 | U3 Resource Availability-Aware Outreach | 7 | 6 | 3 | 5 | 6 | 3 | 5.15 |
| 13 | N6 De-identified analytics extract | 5 | 5 | 6 | 3 | 5 | 6 | 5.00 |
| 14 | N10 IVR reminders | 5 | 7 | 2 | 5 | 4 | 2 | 4.35 |
| 15 | U1 Smart Multilingual Outreach (as proposed) | 4 | 5 | 4 | 6 | 3 | 3 | 4.25 |
| 16 | N12 LLM summariser / chatbot | 5 | 4 | 4 | 7 | 2 | 2 | 4.15 |
| 17 | N11 Offline mobile capture | 4 | 8 | 2 | 4 | 3 | 2 | 4.05 |

**Critical reading of the matrix**

- Sentinel wins mainly on Innovation, Demo and Differentiation. Its **Feasibility (7) and Effort/Risk (6) are not top scores**: it is more code than Referral Closure and has statistical edge cases. If you weighted Feasibility at 40%, Referral Closure would win. The ranking is sensitive to your weights.
- Referral Closure and Zero-dose are within 0.05 of each other; the difference is noise. Zero-dose is absorbed into Sentinel, which is why Referral stays the alternative.
- Scores are my judgement, not measurements. They are useful for comparing, not as proof.

---

## 6. Panel perspective (how five likely judges will react)

| Judge lens | Likely reaction to Sentinel | What you must be ready to say |
|---|---|---|
| **Business / programme** | "This answers *regional health trends* in our problem statement — good." | Who acts on an Alert (programme manager → PHC Medical Officer), and how the review is recorded |
| **Salesforce architect** | "Is this just a report with colours?" | No: it is baseline-relative per village, scheduled, idempotent (one record per open investigation), has a status workflow, notifications and configurable rules in custom metadata. A report cannot compare each village with its own previous 4 weeks |
| **Security / privacy** | "Can a health worker in North see South's patients through this?" | No. Counts are computed under the viewer's sharing; signal records hold counts and record Ids only; drill-down queries run in user mode |
| **Public-health / domain** | "Isn't this outbreak prediction? On small numbers?" | It is **aberration detection**, the same idea as CDC EARS and India's IDSP weekly syndromic (S-form) reporting. It flags an unusual increase for a human to investigate. Minimum counts and a floor on the spread stop "1 → 2 cases" from alerting |
| **Demo / innovation judge** | Remembers the grid turning red and the bell arriving | Keep the demo to one story: Moinabad fever cluster |

**Strongest criticism to pre-empt:** "Your demo data is synthetic, so of course it finds the cluster you planted." Answer honestly: *"Yes, the data is synthetic and the cluster is planted to show the workflow. The proof that it is not rigged is the unit tests: a village with steady counts stays Normal, tiny counts never alert, and a dismissed signal is not raised again. The thresholds are in custom metadata, so a real programme would tune them on its own history."*

---

## 7. Final recommendation

1. **Build: CareLoop Sentinel** with four signals — Fever cluster, Respiratory cluster (cough/breathlessness or SpO2 < 94), Households not reachable (failed visits), Vaccine doses delayed (zero-dose/dropout early warning).
2. **Alternative if you prefer lower risk: Referral Closure Intelligence.** Pick it if the Sentinel check-only validation fails twice and you cannot see why.
3. **Sensible combinations:** Sentinel + N1 (already included). Later (not now): feed open Sentinel signals into Navigator priority so workers visit flagged villages first — this is a *future roadmap* slide, not a build item.
4. **Avoid:** LLM/NLU features, IVR, offline, resource integrations, causal "impact" claims, and building two innovations in the remaining time.
5. **Implemented vs proposed (be precise on stage):** Today, only Phases 1–7 are implemented. Sentinel is *proposed source*; once you deploy and the tests pass you may call it implemented. Navigator priority integration remains *proposed*.

**Approved: Sentinel.** Implementation follows `HealthConnect_Innovation_Implementation_Handbook.md`, starting with a Git checkpoint and a **check-only** validation. Nothing is changed in the org until that passes.
