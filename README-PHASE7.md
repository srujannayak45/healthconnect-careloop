# HealthConnect CareLoop – Phase 7: Workflows, Approvals and Programme Intelligence

Guided screen flows (Register Patient on a Household; Request Closure on a Care Activity), the supervisor approval process the Phase 1 validation rule already requires, a record-triggered flow (new households belong to the village health worker), reporting formula fields, 5 report types, 8 reports and the dynamic CareLoop Programme Intelligence dashboard. Full regression runner.

## Prerequisites

Phase 6 completed and committed. Org alias `careloop`. Salesforce CLI logged in.

## Files

**New:**
* `force-app/main/default/flows/: CareLoop_Register_Patient, CareLoop_Request_Activity_Closure, CareLoop_Household_Default_Owner`
* `force-app/main/default/approvalProcesses/Care_Activity__c.Care_Activity_Closure`
* `force-app/main/default/workflows/Care_Activity__c (4 field updates)`
* `force-app/main/default/quickActions/: Care_Activity__c.Request_Closure, Account.Register_Patient`
* `force-app/main/default/objects/*/fields: 10 reporting formula fields`
* `force-app/main/default/reportTypes/ (5)`
* `force-app/main/default/reports/CareLoop_Reports (8) + folder`
* `force-app/main/default/dashboards/CareLoop_Dashboards/CareLoop_Programme_Intelligence + folder`
* `force-app/main/default/classes/: ConsentInvocable, Phase7AutomationTest`
* `scripts/apex/phase7-verify.apex`
* `scripts/run-all-verifications.ps1`

**Replaced (complete updated versions of existing files):**
* `force-app/main/default/classes/CareActivityTriggerHandler.cls (approval outcome)`
* `force-app/main/default/layouts/Care_Activity__c-Care Activity Layout (Request Closure action; Escalation and Closure section)`
* `force-app/main/default/permissionsets/CareLoop_Admin, CareLoop_Doctor, CareLoop_Health_Worker, CareLoop_Programme_Manager`

## Install (Windows PowerShell, from the project folder)

```powershell
cd C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop
git status                      # must say "nothing to commit, working tree clean"
Expand-Archive -Path "$HOME\Downloads\healthconnect-careloop-phase7-incremental.zip" -DestinationPath . -Force
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
  --source-dir force-app/main/default/objects/Care_Activity__c/fields `
  --source-dir force-app/main/default/objects/Health_Visit__c/fields `
  --source-dir force-app/main/default/objects/Notification__c/fields `
  --source-dir force-app/main/default/objects/Contact/fields `
  --source-dir force-app/main/default/classes `
  --source-dir force-app/main/default/flows `
  --source-dir force-app/main/default/workflows `
  --source-dir force-app/main/default/approvalProcesses `
  --source-dir force-app/main/default/quickActions `
  --source-dir force-app/main/default/layouts `
  --source-dir force-app/main/default/reportTypes `
  --source-dir force-app/main/default/reports `
  --source-dir force-app/main/default/dashboards `
  --source-dir force-app/main/default/permissionsets
sf project deploy quick --use-most-recent --target-org careloop
```

## Manual Setup steps

1. **P7-4** Object Manager → Household (Account) → Page Layouts → *Account Layout* → Mobile & Lightning Actions → drag **Register Patient** → Save.
2. **P7-5** Reports tab → All Folders → *CareLoop Reports* → Share → *All Internal Users* → View; same for Dashboards → *CareLoop Dashboards*.

## Run, verify, demo

```powershell
sf apex run --file scripts/apex/phase7-verify.apex --target-org careloop | Select-String "USER_DEBUG"
powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications.ps1
```
Expected: `PHASE 7 VERIFY PASSED`; the regression prints one green verdict per phase.

## Known limitations

* Dynamic dashboards: Developer Edition allows a small number; this package uses one.
* The approval sets Missed for *Refused/Other* and Cancelled for every other reason.

## Rollback

Nothing changes in the org until `deploy quick`. After deployment: restore the replaced files with `git checkout`, delete the new
files, and redeploy the restored files; or delete new triggers with `sf project delete source --metadata ApexTrigger:<Name> --target-org careloop`.
Details: handbook section 8.
