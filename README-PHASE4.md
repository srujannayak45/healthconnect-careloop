# HealthConnect CareLoop – Phase 4: Proactive Care Engine

Nightly care sweep (Batch + Schedulable): statuses move Scheduled → Due → Overdue every day; the escalation ladder sends reminders in the patient's or caregiver's language (consent-checked, one combined message per person), creates follow-up tasks for health workers and escalates to supervisors. Explainable patient priority (score, level, reasons, next best action). Event-driven doctor alerts: a red-flag visit publishes `CareLoop_Alert__e`; doctors get a bell and the Doctor Review page refreshes live. Multi-village demo data.

## Prerequisites

Phase 3 completed and committed. Org alias `careloop`. Salesforce CLI logged in.

## Files

**New:**
* `force-app/main/default/objects/Contact/fields/Caregiver__c.field-meta.xml`
* `force-app/main/default/objects/CareLoop_Alert__e/ (platform event + 7 fields)`
* `force-app/main/default/notificationtypes/CareLoop_Alert.notiftype-meta.xml`
* `force-app/main/default/classes/: PriorityScoringService, EscalationService, CareSweepBatch, PatientPriorityBatch, CareLoopNightlyJob, CareLoopAlertService, CareLoopAlertSubscriber, DoctorReviewController, PatientPriorityController + 6 test classes`
* `force-app/main/default/triggers/CareLoopAlertTrigger`
* `force-app/main/default/lwc/doctorReviewQueue, lwc/patientPriorityCard`
* `force-app/main/default/flexipages/Doctor_Review, CareLoop_Patient_Record_Page`
* `force-app/main/default/tabs/Doctor_Review`
* `scripts/apex/phase4-demo-data.apex, phase4-run-sweep-now.apex, phase4-schedule-nightly.apex, phase4-verify.apex, phase4-remove-demo-data.apex`

**Replaced (complete updated versions of existing files):**
* `force-app/main/default/classes/HealthVisitTriggerHandler.cls (+2 lines: alert doctors)`
* `force-app/main/default/permissionsets/CareLoop_Admin, CareLoop_Doctor, CareLoop_Health_Worker, CareLoop_Programme_Manager (class/tab/field access added)`
* `force-app/main/default/applications/CareLoop.app-meta.xml (Doctor Review tab; Patient page)`

## Install (Windows PowerShell, from the project folder)

```powershell
cd C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop
git status                      # must say "nothing to commit, working tree clean"
Expand-Archive -Path "$HOME\Downloads\healthconnect-careloop-phase4-incremental.zip" -DestinationPath . -Force
git status                      # new files (untracked) + the replaced files listed below (modified)
git diff --stat                 # review what changed in existing files
```
`-Force` is needed because this package replaces existing files (listed below). Because your tree was clean,
`git checkout -- <file>` restores any of them, and `git clean -n` lists the new files.

## Deploy (check-only first)

Deploy only these paths. **Do not deploy the whole `force-app` folder**: it would also redeploy the
CareLoop Setting custom-metadata record and reset what you set in Setup (demo clock, SMS provider).

```powershell
sf project deploy validate --target-org careloop --test-level RunLocalTests --wait 30 `
  --source-dir force-app/main/default/objects/Contact/fields/Caregiver__c.field-meta.xml `
  --source-dir force-app/main/default/objects/CareLoop_Alert__e `
  --source-dir force-app/main/default/notificationtypes `
  --source-dir force-app/main/default/classes `
  --source-dir force-app/main/default/triggers `
  --source-dir force-app/main/default/lwc `
  --source-dir force-app/main/default/flexipages `
  --source-dir force-app/main/default/tabs/Doctor_Review.tab-meta.xml `
  --source-dir force-app/main/default/permissionsets `
  --source-dir force-app/main/default/applications
sf project deploy quick --use-most-recent --target-org careloop
```

## Manual Setup steps

None. (Optional: the demo clock is Setup → Custom Metadata Types → CareLoop Setting → Manage Records → Default → Simulated Today.)

## Run, verify, demo

```powershell
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 20 --target-org careloop
sf apex run --file scripts/apex/phase4-verify.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase4-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase4-run-sweep-now.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase4-schedule-nightly.apex --target-org careloop | Select-String "USER_DEBUG"
```
Expected: verify ends `PHASE 4 VERIFY PASSED`; Apex Jobs shows CareSweepBatch and PatientPriorityBatch Completed.

## Known limitations

* SMS/Email reminders stay **Queued** until Phase 5 (Portal Inbox reminders are delivered at once).
* A reminder lost to a duplicate key on a second same-day sweep is not re-sent the same day (by design: one reminder per person per day).
* Bell notifications are not sent inside Apex tests (tests count them instead).

## Rollback

Nothing changes in the org until `deploy quick`. After deployment: restore the replaced files with `git checkout`, delete the new
files, and redeploy the restored files; or delete new triggers with `sf project delete source --metadata ApexTrigger:<Name> --target-org careloop`.
Details: handbook section 8.
