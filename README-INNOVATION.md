# README — Innovation: CareLoop Sentinel (Community Health Early Warning)

**Approved:** 10 Nov 2026. **Package status:** source complete. It counts as implemented only after `sf project deploy validate` and the tests and verification pass **in the org**.

## What it does

Every morning (06:30) Sentinel compares, for each village, this week's:
- fever visits;
- respiratory visits (cough, breathlessness or SpO2 < 94);
- unreachable-household visits;
- late vaccine doses

with that village's own previous four weeks.

A clear rise becomes a **Watch**, a large one an **Alert**, with a plain-language reason. Programme managers and doctors get a bell notification. A manager reviews each signal: *Investigating → Closed* or *Dismissed*, always with a note.

Safeguards:
- minimum counts;
- a floor on the spread;
- a history check: no data does not mean zero cases;
- grace days for vaccines;
- no duplicate signals;
- reviewed signals are not raised again in the same week.

It flags unusual counts for a person to investigate. **It never diagnoses or confirms an outbreak.**

## New vs modified

| Kind | Files |
|---|---|
| **Modified (2)** | `force-app/main/default/applications/CareLoop.app-meta.xml` (+2 tab lines), `README.md` (project README, replaces the Phase 1 text) |
| **New** | everything else: 1 custom metadata type + 4 records, `Community_Signal__c`, 5 Apex classes, LWC `communityWatch`, page, 2 tabs, custom permission, 2 permission sets, report type, 3 reports, 1 dashboard, 5 manifest files, 7 Apex scripts, 1 PowerShell runner, docs |
| **Not touched** | every Phase 1–7 class, trigger, flow, object, field, permission set, report, dashboard and the CareLoop Setting record |

## Quick reference (full beginner steps: `docs/innovation/HealthConnect_Innovation_Implementation_Handbook.md`)

```powershell
# I-0 checkpoint (after baseline tests + verify scripts are green)
git tag -a phase7-complete -m "Phases 1-7 complete"; git push origin phase7-complete; git checkout -b innovation-sentinel
# I-1 integrate (staging folder, collision check, copy) -> I-2 inspect, commit locally
# I-3 check-only validation: org unchanged, all local tests (expected 137)
sf project deploy validate --manifest manifest/innovation-package.xml --test-level RunLocalTests --wait 60 --target-org careloop
# I-4 deploy exactly what was validated
sf project deploy quick --use-most-recent --target-org careloop --wait 30
# I-6 .. I-14
sf apex run --file scripts/apex/innovation-assign-permissions.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run test --class-names SentinelServiceTest --class-names CommunityWatchControllerTest --code-coverage --result-format human --wait 20 --target-org careloop
sf apex run --file scripts/apex/innovation-verify.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-sentinel-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-run-scan.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-schedule-sentinel.apex --target-org careloop | Select-String "USER_DEBUG"
# I-15 regression
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 30 --target-org careloop
powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications-with-sentinel.ps1
```

## Scripts

| Script | Changes data? | Purpose |
|---|---|---|
| `innovation-assign-permissions.apex` | Assignments only | Manager → admin and Meena; Viewer → Arjun, Lakshmi, Sunita (idempotent) |
| `innovation-verify.apex` | No (rolled back) | 10 checks |
| `innovation-sentinel-demo-data.apex` | Yes, tagged `Sentinel demo` | 6 weeks of history + 4 planted signals (Moinabad fever, Kondapur respiratory, Kandukur unreachable, Shamshabad vaccine delay) |
| `innovation-run-scan.apex` | Signals + bells | Scan now and print every signal |
| `innovation-schedule-sentinel.apex` | Scheduled job | 06:30 daily (idempotent) |
| `innovation-remove-demo-data.apex` | Deletes Sentinel demo data only | Tagged visits and doses, plus signals of the 4 demo villages |
| `innovation-rollback-prepare.apex` | Deletes Sentinel data only | Before a rollback: abort job, remove Sentinel assignments, signals and demo data |
| `scripts/run-all-verifications-with-sentinel.ps1` | No | 7 phase verifies + Sentinel verify |

## Rollback

- **Soft:** `innovation-rollback-prepare.apex`, then restore the app file from tag `phase7-complete` and deploy it.
- **Full:** the destructive manifest in `manifest/innovation-rollback/`.

Exact commands are in handbook section R.

## Principles kept

- Salesforce-native; no paid APIs, external services, LLM, IVR or offline components.
- `with sharing` throughout; evidence in `USER_MODE`; counts only in signals, reports and the dashboard.
- No patient messages, so no consent impact.
- Existing permission sets are unchanged.
- Cleanup scripts delete only Sentinel records.
