# HealthConnect CareLoop – Phase 6: CareLoop Navigator (the innovation)

Household-bundled, travel-aware daily visit plans. For each health worker the Navigator groups due and overdue care by household, values each household by the explainable priority of its members, and builds a route within her daily capacity that finishes one village before walking to the next. Every plan stores what a due-date list would have achieved, so the improvement is measured on real data; recorded visits and completed care update the plan automatically.

## Prerequisites

Phase 5 completed and committed. Org alias `careloop`. Salesforce CLI logged in.

## Files

**New:**
* `force-app/main/default/objects/Visit_Plan__c (+20 fields incl. 3 formulas), Visit_Plan_Stop__c (+14 fields)`
* `force-app/main/default/objects/CareLoop_Setting__mdt/fields/: Daily_Visit_Capacity__c, Travel_Penalty_Per_Km__c, Plan_Lookahead_Days__c`
* `force-app/main/default/classes/: NavigatorPlanner, NavigatorService, NavigatorController, NavigatorPlanQueueable, NavigatorNightlyJob, NavigatorPlannerTest`
* `force-app/main/default/lwc/careNavigator`
* `force-app/main/default/flexipages/Care_Navigator`
* `force-app/main/default/tabs/Care_Navigator, Visit_Plan__c`
* `scripts/apex/phase6-plan-now.apex, phase6-schedule-navigator.apex, phase6-verify.apex`

**Replaced (complete updated versions of existing files):**
* `force-app/main/default/permissionsets/CareLoop_Admin, CareLoop_Health_Worker, CareLoop_Programme_Manager`
* `force-app/main/default/applications/CareLoop.app-meta.xml (Care Navigator, Visit Plans tabs)`

## Install (Windows PowerShell, from the project folder)

```powershell
cd C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop
git status                      # must say "nothing to commit, working tree clean"
Expand-Archive -Path "$HOME\Downloads\healthconnect-careloop-phase6-incremental.zip" -DestinationPath . -Force
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
  --source-dir force-app/main/default/objects/Visit_Plan__c `
  --source-dir force-app/main/default/objects/Visit_Plan_Stop__c `
  --source-dir force-app/main/default/objects/CareLoop_Setting__mdt/fields `
  --source-dir force-app/main/default/classes `
  --source-dir force-app/main/default/lwc `
  --source-dir force-app/main/default/flexipages `
  --source-dir force-app/main/default/tabs `
  --source-dir force-app/main/default/permissionsets `
  --source-dir force-app/main/default/applications
sf project deploy quick --use-most-recent --target-org careloop
```

## Manual Setup steps

None. Optional: CareLoop Setting → Default → Daily Visit Capacity / Travel Penalty Per Km / Plan Look-ahead Days (defaults 8 / 0.5 / 7).

## Run, verify, demo

```powershell
sf apex run --file scripts/apex/phase6-verify.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase6-plan-now.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase6-schedule-navigator.apex --target-org careloop | Select-String "USER_DEBUG"
```
Expected: `PHASE 6 VERIFY PASSED`; plan lines for Lakshmi and Sunita with gaps vs due-date list.

## Known limitations

* Distances are straight lines between village centres (no road routing); households in one village count as 0 km.
* Weights are expert-set configuration, not learned (no historical outcome data exists to learn from).

## Rollback

Nothing changes in the org until `deploy quick`. After deployment: restore the replaced files with `git checkout`, delete the new
files, and redeploy the restored files; or delete new triggers with `sf project delete source --metadata ApexTrigger:<Name> --target-org careloop`.
Details: handbook section 8.
