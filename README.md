# HealthConnect CareLoop

Preventive-care outreach on Salesforce for community health programmes (Cognizant 2027 NPN Salesforce Hackathon, challenge *HealthConnect – Outreach Programme*).

Health workers register households and patients and record home visits. CareLoop then:
- turns every vaccine dose, check-up and doctor follow-up into a tracked **Care Activity**;
- ranks patients by explainable priority;
- sends reminders in the patient's own language, but only with recorded consent;
- escalates missed care to the health worker and then to the supervisor;
- plans each worker's day by household;
- **CareLoop Sentinel** watches every village for unusual rises in fever, respiratory illness, unreachable households and delayed vaccines.

> All data in this org is **synthetic**. Clinical thresholds, the immunisation schedule and the Sentinel thresholds are configurable samples. A clinician or public-health officer must set the real values. CareLoop supports decisions; it never diagnoses.

## Status

| Phase | Contents | State |
|---|---|---|
| 1 | Data model, validation rules, custom metadata, permission sets, tabs, app | Implemented and verified |
| 2 | Security: org-wide defaults, roles, 4 staff users, sharing, restricted staff profile | Implemented and verified |
| 3 | Apex care engine: care schedules, red flags, care plans, activity status | Implemented and verified |
| 4 | Nightly care sweep, escalation ladder, explainable priority, live doctor alerts | Implemented and verified |
| 5 | Patient portal (Experience Cloud), hash-chained consent ledger, SMS integration (echo gateway) | Implemented and verified |
| 6 | **CareLoop Navigator**: household-bundled, travel-aware daily visit plans | Implemented and verified |
| 7 | Flows, approval process, reports and the Programme Intelligence dashboard | Implemented and verified |
| Innovation | **CareLoop Sentinel**: community health early warning | **Package integrated; update this row only after deployment and tests pass in the org** |

Baseline before Sentinel: commit `5ef9d6a`, 123 Apex tests passing, 89% org-wide coverage, 7 verification scripts passing.
With Sentinel the **expected** count is 137 tests (123 + 14). That number is only a target until the org confirms it.

## Users (Developer Edition demo org, alias `careloop`)

| Person | Role | Main screens |
|---|---|---|
| Lakshmi Devi | Health worker, North (Kondapur, Moinabad) | Care Navigator, Households, Visits |
| Sunita Rao | Health worker, South (Shamshabad, Kandukur) | Care Navigator, Households, Visits |
| Arjun Reddy | Doctor | Doctor Review, Recommendations, Community Watch (read-only) |
| Meena Iyer | Programme manager / supervisor | Dashboards, approvals, **Community Watch (review signals)** |
| Kavya and Venkat Rao | Patient / caregiver (portal users) | HealthConnect portal |

## Architecture in one picture

```text
Health worker ──► Households, Patients, Visits ──► Care engine (Phase 3) ──► Care Activities
                                                     │                          │
                                       Red flags ──► Doctor Review (Phase 4)    ├─► Nightly sweep + escalation + reminders (Phase 4/5)
                                                                                ├─► Priority score ──► Navigator daily plan (Phase 6)
                                                                                └─► Reports + dashboard (Phase 7)
Visits + vaccine activities ──► CareLoop Sentinel (daily 06:30) ──► Community Signals ──► Community Watch + manager bells
Patient ◄──► Portal (reminders, one-tap replies, consent) ◄──► Consent ledger (Phase 5)
```

Full design: `docs/innovation/HealthConnect_CareLoop_Architecture.md`.

## Scheduled jobs (after setup)

| Time | Job | Phase |
|---|---|---|
| 05:30 | CareLoop nightly sweep (statuses, escalation, reminders, priority) | 4 |
| 06:15 | Navigator daily plans | 6 |
| 06:30 | CareLoop Sentinel community scan | Innovation |

## Repository layout

```text
force-app/main/default/   all metadata (objects, classes, triggers, LWCs, flows, permission sets, reports, dashboards)
manifest/package.xml      Phase 1 manifest (retrieve)
manifest/innovation-*.xml Sentinel deploy, validate and rollback manifests
scripts/apex/             set-up, demo-data, verification and clean-up scripts for every phase
scripts/run-all-verifications.ps1                  regression of Phases 1-7
scripts/run-all-verifications-with-sentinel.ps1    the same plus the Sentinel verify
README-PHASE2.md … README-PHASE7.md               per-phase install notes
README-INNOVATION.md                               Sentinel install, verify and rollback
docs/innovation/                                   proposal, architecture, handbook, tests, demo, Q&A, limitations
```

## Deploying

**Never deploy the whole `force-app` folder.** That would redeploy the CareLoop Setting custom-metadata record and reset what you set in Setup (the demo clock and the SMS provider). Each phase deploys only its own paths or manifest; see its README. Sentinel uses `manifest/innovation-package.xml` (README-INNOVATION.md).

## Regression

```powershell
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 30 --target-org careloop
powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications-with-sentinel.ps1
```

## Principles

- **Salesforce-native:** no paid APIs. The SMS gateway is an echo service, so callouts are real but no SMS reaches a phone.
- **Explainable rules instead of black-box AI:** priority points, red flags and Sentinel thresholds all live in custom metadata.
- **Least privilege:** one permission set per role; patient data follows region sharing; Sentinel signals hold village-level counts only.
- **Consent before contact:** consent is purpose-specific, and the ledger is append-only and hash-chained.
- **Tests and checks:** every phase has Apex tests and a verification script that checks the result and rolls back its own test data.

Known limitations and the roadmap are in `docs/innovation/HealthConnect_CareLoop_Limitations_and_Roadmap.md`.
