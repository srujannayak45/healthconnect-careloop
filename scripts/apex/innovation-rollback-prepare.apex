// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): prepare a rollback
// =====================================================================================
// Run this ONLY if you decide to remove the innovation. It clears everything that would block
// Salesforce from deleting the new metadata:
//   1. aborts the "CareLoop Sentinel Daily Scan" scheduled job (a scheduled class cannot be deleted)
//   2. removes the Sentinel permission set assignments (an assigned permission set cannot be deleted)
//   3. deletes all Community Signal records and the "Sentinel demo" visits and doses
// Phase 1-7 data and permission sets are not touched. Next steps are in README-INNOVATION.md (Rollback).
//   sf apex run --file scripts/apex/innovation-rollback-prepare.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'ROLLBACK ' + line);
}
Integer jobs = 0;
for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'CareLoop Sentinel Daily Scan']) {
    System.abortJob(ct.Id);
    jobs++;
}
say('1 | ' + jobs + ' scheduled Sentinel job(s) aborted');
List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment
    WHERE PermissionSet.Name IN ('CareLoop_Sentinel_Manager', 'CareLoop_Sentinel_Viewer')];
delete assignments;
say('2 | ' + assignments.size() + ' Sentinel permission set assignment(s) removed');
List<Health_Visit__c> visits = new List<Health_Visit__c>();
for (Health_Visit__c v : [SELECT Id, Observations__c FROM Health_Visit__c
                          WHERE Patient__r.Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur')
                            AND Visit_Date__c = LAST_N_DAYS:120]) {
    if (v.Observations__c == 'Sentinel demo') {
        visits.add(v);
    }
}
List<Care_Activity__c> doses = [SELECT Id FROM Care_Activity__c WHERE Name LIKE 'Sentinel demo%'];
List<Community_Signal__c> signals = [SELECT Id FROM Community_Signal__c];
delete visits;
delete doses;
delete signals;
say('3 | ' + visits.size() + ' demo visits, ' + doses.size() + ' demo doses, ' + signals.size() + ' signals deleted');
say('READY | Now restore the CareLoop app from Git and run the destructive deploy (README-INNOVATION.md)');
