// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): remove the Sentinel demo data
// =====================================================================================
// Deletes ONLY: visits whose Observations are exactly "Sentinel demo", care activities whose Name starts
// with "Sentinel demo", and the Community Signal records of the four demo villages (recreated by the next scan).
// Phase 1-7 records (patients, households, other visits and activities) are not touched.
//   sf apex run --file scripts/apex/innovation-remove-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
// Observations__c is a long text field and cannot be used in a WHERE clause, so candidates are
// selected by village and date and the tag is checked in Apex.
List<Health_Visit__c> visits = new List<Health_Visit__c>();
for (Health_Visit__c v : [SELECT Id, Observations__c FROM Health_Visit__c
                          WHERE Patient__r.Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur')
                            AND Visit_Date__c = LAST_N_DAYS:120]) {
    if (v.Observations__c == 'Sentinel demo') {
        visits.add(v);
    }
}
List<Care_Activity__c> doses = [SELECT Id FROM Care_Activity__c WHERE Name LIKE 'Sentinel demo%'];
// Signals are produced by the Sentinel scan; only those for the four demo villages are removed.
List<Community_Signal__c> signals = [SELECT Id FROM Community_Signal__c
                                     WHERE Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur')];
delete visits;
delete doses;
delete signals;
System.debug(LoggingLevel.ERROR, 'SENTINEL CLEANUP | ' + visits.size() + ' visits, ' + doses.size() + ' doses, ' + signals.size() + ' signals removed');
