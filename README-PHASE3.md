# HealthConnect CareLoop – Phase 3 incremental package (Care Activity engine)

Adds the Apex engine that turns the Phase 1 data model into a working care loop:
care schedules are generated for every eligible patient, visits are red-flagged against
configurable thresholds, doctors' final recommendations become care-plan activities, and
activity statuses / overdue days stay correct. **New files only**; nothing from Phase 0–2 is changed.
No permission-set changes are needed.

## What it contains

`force-app/main/default/classes/` (each `.cls` has a `.cls-meta.xml`, API 62.0)

| Class | Role |
|---|---|
| `TriggerHandler` | Base class: one trigger per object, bypass by handler name |
| `CareRules` | Reads custom metadata (rules, schedules, escalation ladder, setting) with no SOQL; status rules |
| `CareLoopClock` | "Today" for the engine; honours the demo date `Simulated_Today__c` |
| `ErrorLogger` | Writes `Error_Log__c` entries (never throws) |
| `DerivedFieldWriter` | Writes engine-owned fields in system mode with partial success + logging |
| `CareScheduleService` | Generates idempotent care activities from `Care_Schedule__mdt` |
| `CareScheduleQueueable` | Runs generation in the background after patients are registered or change |
| `CarePlanService` | Turns a Final doctor recommendation into follow-up and check-up activities |
| `ContactTriggerHandler` | Patient: default health worker, queue schedule generation |
| `HealthVisitTriggerHandler` | Visit: defaults, red flags, review status, last contact / failed attempts |
| `MedicalRecommendationTriggerHandler` | Recommendation: stamp doctor and time, create care plan |
| `CareActivityTriggerHandler` | Activity: status, overdue days, close open tasks on completion |
| `CareLoopTestFactory` + 10 `*Test` classes | 49 test methods, bulk tests of 200 records |

`force-app/main/default/triggers/`: `ContactTrigger`, `HealthVisitTrigger`, `MedicalRecommendationTrigger`, `CareActivityTrigger`.

`scripts/apex/phase3-verify.apex` – end-to-end check, **rolls everything back**. Last line `PHASE 3 VERIFY PASSED`.
`scripts/apex/phase3-demo-household.apex` – creates the demo village *Kondapur* and *Rao Household* (kept).

## Install (Windows PowerShell, from the project folder)

```powershell
cd C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop
Expand-Archive -Path "$HOME\Downloads\healthconnect-careloop-phase3-incremental.zip" -DestinationPath .
git status
```

## Deploy (check-only first)

```powershell
sf project deploy validate --source-dir force-app/main/default/classes --source-dir force-app/main/default/triggers --target-org careloop --test-level RunLocalTests --wait 30
sf project deploy quick --use-most-recent --target-org careloop
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 20 --target-org careloop
sf apex run --file scripts/apex/phase3-verify.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase3-demo-household.apex --target-org careloop | Select-String "USER_DEBUG"
```

`validate` compiles and runs all tests **without changing the org**. Only if it succeeds does `quick` deploy the validated package.
Phase 2 must be complete first (the demo household belongs to Lakshmi Devi).
Details, expected output, UI demo scenarios and troubleshooting: handbook section 3.
