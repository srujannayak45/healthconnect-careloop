# HealthConnect CareLoop — Likely Technical-Panel Questions and Answers

Answer in your own words. Short, honest answers score better than long ones. Mark clearly what is **implemented** and what is **future**.

## A. CareLoop Sentinel

| # | Question | Strong answer |
|---|---|---|
| 1 | Isn't this just a report with colours? | A report shows totals. Sentinel compares every village with **its own** previous four weeks, runs daily on a schedule, explains each result in words, avoids duplicate alerts, and records a human review with notes. A standard report cannot do per-village, baseline-relative scoring. |
| 2 | How exactly is a signal decided? | Count this week; take the average and standard deviation of the previous four weeks, with a floor of 1 on the spread. z = (this week − average) / spread. Watch at z ≥ 2, Alert at z ≥ 3, and only if the count meets a minimum and the village has at least 2 weeks of history. |
| 3 | Small numbers — won't it cry wolf? | Four guards: minimum counts (3, or 4 for missed visits), the spread floor, the history check (missing data is not zero), and Watch before Alert. Unit tests prove 0 → 2 never alerts. Dismissals are tracked in the dashboard so a programme can tune thresholds. |
| 4 | What if a village has no data? | It is **not assessed**, and the grid shows "no history yet". A new or silent village is never compared against an imaginary zero. |
| 5 | Your data is synthetic; you planted the cluster. | Yes. The planted cluster demonstrates the workflow. The tests prove the negative cases: steady villages stay Normal, tiny counts and missing history are not flagged, and closed or dismissed signals are not repeated. |
| 6 | Is this outbreak prediction or diagnosis? | No. It is aberration detection, the same idea as the CDC's EARS methods and India's IDSP weekly syndromic reporting. It flags an unusual increase; the Medical Officer decides. There is deliberately no "Confirmed" status. |
| 7 | Why not machine learning? | No historical training data exists, a black box can't be explained to a health worker, and a model API would send patient data outside the org. Transparent statistics in custom metadata are auditable. |
| 8 | Can a South worker see North patients through Sentinel? | No. Grid counts are computed under the viewer's sharing, and the evidence list uses user-mode queries. Signal records contain only village counts and record Ids; opening a record still needs normal access. |
| 9 | Why is Community_Signal__c Public Read Only? | It holds aggregate, village-level data: no names, phone numbers or vitals. District staff need the full picture; patient-level access is still controlled. |
| 10 | Who gets notified? | Users with the Sentinel Manager permission set (programme manager, admin) and doctors, through the existing CareLoop bell notification. One bell per new signal, and again only if a Watch becomes an Alert. |
| 11 | What prevents duplicate signals? | Before inserting, the scan looks for a signal for the same village and signal in the current window. An open one is updated and keeps its status and notes. A Closed or Dismissed one is skipped. A unique Alert Key backs this up. |
| 12 | How do you change thresholds? | Setup → Custom Metadata → Surveillance Signal. Min count, Watch/Alert z, baseline weeks, history weeks, symptoms, outcomes and grace days are all configuration. No code or deployment is needed. |
| 13 | How does it scale? | One transaction handles hundreds of villages (queries limited to six weeks of data). For a district, the job becomes Batch Apex per group of villages. That is documented, not built. |
| 14 | What if the scheduled job fails? | It writes to the existing Error Log, and the manager can press "Run scan now". |
| 15 | Why vaccine delays in an "early warning" system? | Doses slipping across a village is an early sign of access problems and of zero-dose or drop-out children: a public-health signal, not an illness. |
| 16 | How is it tested? | 14 Apex test methods (all four signals, safeguards, duplicates, review, notifications, permissions, invalid input) and a 10-check verify script in the real org. All local tests and the 7 phase scripts are re-run for regression. *Quote only the numbers you saw.* |
| 17 | Does it change anything in Phases 1–7? | No Phase 1–7 class, flow or permission set changed. The only modified metadata file adds two tabs to the app. |
| 18 | Why custom notifications, not email or SMS? | Staff are in Salesforce daily, and bells need no consent or gateway. SMS is reserved for patients, under consent. |

## B. Phases 1–7

| # | Question | Strong answer |
|---|---|---|
| 19 | How do you stop health workers seeing other regions' patients? | Households are Private; patients, visits and activities are controlled by parent. A role hierarchy and region sharing open only what each role needs. The restricted *CareLoop Platform Staff* profile is used with one permission set per role. |
| 20 | Why one trigger per object? | Predictable order of execution and a single handler class per object, with a bypass for data loads and tests. |
| 21 | How is the priority explainable? | Every point comes from a Care Rule record with a reason text, so the card shows *why* a patient ranks high. |
| 22 | Consent? | Purpose-specific consent and an append-only, hash-chained Consent Event ledger. Reminders are only sent with consent. The ledger is tamper-evident (detects changes), not tamper-proof. |
| 23 | Is the SMS real? | The callout is real (Named Credential, Queueable), but it goes to an echo service. No SMS reaches a phone; production in India needs DLT registration. |
| 24 | What makes the Navigator innovative? | It bundles all due care per household, values each household by its members' priority, respects the worker's daily capacity, finishes one village before travelling to the next, and stores the gain against a plain due-date list. |
| 25 | How do you deploy safely? | Check-only validation with all local tests, then quick deploy of the validated package. Never deploy the whole force-app (it would reset the demo-clock setting). Git tags before each phase. |
| 26 | Biggest limitation? | Synthetic data and expert-set thresholds. Real deployment needs clinical sign-off and tuning on real history. |
