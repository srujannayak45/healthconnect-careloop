# HealthConnect CareLoop — CareLoop Sentinel File Structure

> Paths are relative to the project root. **NEW** = not in commit `5ef9d6a`. **MODIFIED** = replaces an existing file (2 files).
> Copy rule: the whole package is copied with `Copy-Item … -Force` **after** the collision check in handbook step I-1.4 shows only the two MODIFIED files.

Total files: **95** (93 new, 2 modified).

## 1. Every file

| File | Status | Lines |
|---|---|---|
| `README-INNOVATION.md` | NEW | 83 |
| `README.md` | **MODIFIED** | 96 |
| `docs/innovation/HealthConnect_CareLoop_Architecture.md` | NEW | 329 |
| `docs/innovation/HealthConnect_CareLoop_Final_Demo_Script.md` | NEW | 65 |
| `docs/innovation/HealthConnect_CareLoop_Limitations_and_Roadmap.md` | NEW | 45 |
| `docs/innovation/HealthConnect_CareLoop_Panel_QA.md` | NEW | 39 |
| `docs/innovation/HealthConnect_Innovation_File_Structure.md` | NEW | 139 |
| `docs/innovation/HealthConnect_Innovation_Implementation_Handbook.md` | NEW | 650 |
| `docs/innovation/HealthConnect_Innovation_Proposal.md` | NEW | 223 |
| `docs/innovation/HealthConnect_Innovation_Source_Listing.md` | NEW | 4213 |
| `docs/innovation/HealthConnect_Innovation_Test_Plan.md` | NEW | 112 |
| `force-app/main/default/applications/CareLoop.app-meta.xml` | **MODIFIED** | 40 |
| `force-app/main/default/classes/CommunityWatchController.cls` | NEW | 189 |
| `force-app/main/default/classes/CommunityWatchController.cls-meta.xml` | NEW | 5 |
| `force-app/main/default/classes/CommunityWatchControllerTest.cls` | NEW | 159 |
| `force-app/main/default/classes/CommunityWatchControllerTest.cls-meta.xml` | NEW | 5 |
| `force-app/main/default/classes/SentinelJob.cls` | NEW | 30 |
| `force-app/main/default/classes/SentinelJob.cls-meta.xml` | NEW | 5 |
| `force-app/main/default/classes/SentinelService.cls` | NEW | 510 |
| `force-app/main/default/classes/SentinelService.cls-meta.xml` | NEW | 5 |
| `force-app/main/default/classes/SentinelServiceTest.cls` | NEW | 400 |
| `force-app/main/default/classes/SentinelServiceTest.cls-meta.xml` | NEW | 5 |
| `force-app/main/default/customMetadata/Surveillance_Signal.Failed_Visit_Surge.md-meta.xml` | NEW | 61 |
| `force-app/main/default/customMetadata/Surveillance_Signal.Fever_Cluster.md-meta.xml` | NEW | 61 |
| `force-app/main/default/customMetadata/Surveillance_Signal.Immunisation_Delay.md-meta.xml` | NEW | 61 |
| `force-app/main/default/customMetadata/Surveillance_Signal.Respiratory_Cluster.md-meta.xml` | NEW | 61 |
| `force-app/main/default/customPermissions/CareLoop_Run_Sentinel.customPermission-meta.xml` | NEW | 6 |
| `force-app/main/default/dashboards/CareLoop_Dashboards/CareLoop_Sentinel.dashboard-meta.xml` | NEW | 81 |
| `force-app/main/default/flexipages/Community_Watch.flexipage-meta.xml` | NEW | 19 |
| `force-app/main/default/lwc/communityWatch/communityWatch.css` | NEW | 43 |
| `force-app/main/default/lwc/communityWatch/communityWatch.html` | NEW | 96 |
| `force-app/main/default/lwc/communityWatch/communityWatch.js` | NEW | 141 |
| `force-app/main/default/lwc/communityWatch/communityWatch.js-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/Community_Signal__c.object-meta.xml` | NEW | 22 |
| `force-app/main/default/objects/Community_Signal__c/fields/Alert_Key__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Evidence_Ids__c.field-meta.xml` | NEW | 8 |
| `force-app/main/default/objects/Community_Signal__c/fields/Expected__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Explanation__c.field-meta.xml` | NEW | 8 |
| `force-app/main/default/objects/Community_Signal__c/fields/Guidance__c.field-meta.xml` | NEW | 10 |
| `force-app/main/default/objects/Community_Signal__c/fields/Households__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Investigation_Notes__c.field-meta.xml` | NEW | 8 |
| `force-app/main/default/objects/Community_Signal__c/fields/Last_Scanned_On__c.field-meta.xml` | NEW | 7 |
| `force-app/main/default/objects/Community_Signal__c/fields/Observed__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Rate_Per_1000__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Region__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Reviewed_By__c.field-meta.xml` | NEW | 10 |
| `force-app/main/default/objects/Community_Signal__c/fields/Reviewed_On__c.field-meta.xml` | NEW | 7 |
| `force-app/main/default/objects/Community_Signal__c/fields/Severity__c.field-meta.xml` | NEW | 23 |
| `force-app/main/default/objects/Community_Signal__c/fields/Signal_Key__c.field-meta.xml` | NEW | 10 |
| `force-app/main/default/objects/Community_Signal__c/fields/Signal_Label__c.field-meta.xml` | NEW | 10 |
| `force-app/main/default/objects/Community_Signal__c/fields/Status__c.field-meta.xml` | NEW | 34 |
| `force-app/main/default/objects/Community_Signal__c/fields/Std_Dev__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Threshold__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Village__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/fields/Weekly_Counts__c.field-meta.xml` | NEW | 10 |
| `force-app/main/default/objects/Community_Signal__c/fields/Window_End__c.field-meta.xml` | NEW | 7 |
| `force-app/main/default/objects/Community_Signal__c/fields/Window_Start__c.field-meta.xml` | NEW | 7 |
| `force-app/main/default/objects/Community_Signal__c/fields/Z_Score__c.field-meta.xml` | NEW | 11 |
| `force-app/main/default/objects/Community_Signal__c/listViews/All.listView-meta.xml` | NEW | 14 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/Surveillance_Signal__mdt.object-meta.xml` | NEW | 7 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Active__c.field-meta.xml` | NEW | 9 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Activity_Types__c.field-meta.xml` | NEW | 12 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Alert_Z__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Baseline_Weeks__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Grace_Days__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Guidance__c.field-meta.xml` | NEW | 12 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Max_SpO2__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Min_Count__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Min_History_Weeks__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Min_Temperature__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Source__c.field-meta.xml` | NEW | 12 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Symptoms__c.field-meta.xml` | NEW | 12 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Visit_Outcomes__c.field-meta.xml` | NEW | 12 |
| `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Watch_Z__c.field-meta.xml` | NEW | 13 |
| `force-app/main/default/permissionsets/CareLoop_Sentinel_Manager.permissionset-meta.xml` | NEW | 151 |
| `force-app/main/default/permissionsets/CareLoop_Sentinel_Viewer.permissionset-meta.xml` | NEW | 147 |
| `force-app/main/default/reportTypes/CareLoop_Community_Signals.reportType-meta.xml` | NEW | 81 |
| `force-app/main/default/reports/CareLoop_Reports/Community_Signals_by_Region.report-meta.xml` | NEW | 50 |
| `force-app/main/default/reports/CareLoop_Reports/Community_Signals_by_Signal_Type.report-meta.xml` | NEW | 51 |
| `force-app/main/default/reports/CareLoop_Reports/Community_Signals_by_Village.report-meta.xml` | NEW | 51 |
| `force-app/main/default/tabs/Community_Signal__c.tab-meta.xml` | NEW | 5 |
| `force-app/main/default/tabs/Community_Watch.tab-meta.xml` | NEW | 7 |
| `manifest/innovation-1-data-model.xml` | NEW | 65 |
| `manifest/innovation-2-application.xml` | NEW | 48 |
| `manifest/innovation-package.xml` | NEW | 109 |
| `manifest/innovation-rollback/destructiveChanges.xml` | NEW | 60 |
| `manifest/innovation-rollback/package.xml` | NEW | 4 |
| `scripts/apex/innovation-assign-permissions.apex` | NEW | 48 |
| `scripts/apex/innovation-remove-demo-data.apex` | NEW | 26 |
| `scripts/apex/innovation-rollback-prepare.apex` | NEW | 39 |
| `scripts/apex/innovation-run-scan.apex` | NEW | 20 |
| `scripts/apex/innovation-schedule-sentinel.apex` | NEW | 9 |
| `scripts/apex/innovation-sentinel-demo-data.apex` | NEW | 146 |
| `scripts/apex/innovation-verify.apex` | NEW | 167 |
| `scripts/run-all-verifications-with-sentinel.ps1` | NEW | 27 |

## 2. Modified file 1: `CareLoop.app-meta.xml` (two lines added, none removed)

```diff
--- a/CareLoop.app-meta.xml
+++ b/CareLoop.app-meta.xml
@@ -23,2 +23,3 @@
     <tabs>Doctor_Review</tabs>
+    <tabs>Community_Watch</tabs>
     <tabs>Care_Activity__c</tabs>
@@ -30,2 +31,3 @@
     <tabs>Visit_Plan__c</tabs>
+    <tabs>Community_Signal__c</tabs>
     <tabs>Notification__c</tabs>
```

## 3. Modified file 2: `README.md`

The Phase 1 README (44 lines; its status table still says Phase 2 is "Next") is replaced by the full project README covering Phases 1–7 and Sentinel. Documentation only, so it has no effect on the org.

## 4. Existing components Sentinel depends on (unchanged, must exist)

| Component | Used for |
|---|---|
| `Health_Visit__c` fields Visit_Date, Symptoms, Temperature, SpO2, Visit_Outcome, Patient | Visit signals |
| `Care_Activity__c` fields Activity_Type, Due_Date, Status, Completed_Date, Patient | Vaccine-delay signal |
| `Village__c` Name, Region, Population, Active; `Contact.Village__c`, `Contact.AccountId`, `Account.Village__c` | Villages and households |
| `CareLoopClock`, `CareLoopAlertService` (notify, doctors, bellsSent), `ErrorLogger`, `CareRules.STATUS_CANCELLED`, `TriggerHandler` | Clock, bells, error log, constants, test bypass |
| `CareLoopTestFactory.newPatient/useRealToday`, `CareLoopPhase4TestData.newUser` | Tests |
| Custom notification type `CareLoop_Alert` | Bells |
| Report folder `CareLoop_Reports`, dashboard folder `CareLoop_Dashboards` | Reports, dashboard |
| Permission sets `CareLoop_Health_Worker` (test only), `CareLoop_Doctor` (via `doctors()`) | Tests, notification recipients |
| Profile `CareLoop Platform Staff` (falls back to `Standard Platform User`) | Viewer test |
