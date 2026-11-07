// =====================================================================================
// HealthConnect CareLoop - Phase 4: remove the multi-village demo data (recovery only)
// =====================================================================================
// Deletes the "Demo - ..." households (their patients, visits, care activities, notifications
// and tasks go with them) and the villages Moinabad, Shamshabad and Kandukur if nothing else uses
// them. The Rao Household and Kondapur are kept. Recreate with phase4-demo-data.apex.
//
// Run:
//   sf apex run --file scripts/apex/phase4-remove-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
List<Account> households = [SELECT Id FROM Account WHERE Name LIKE 'Demo - %'];
Set<Id> patientIds = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId IN :households]).keySet();
delete [SELECT Id FROM Task WHERE WhoId IN :patientIds];
delete households;
List<Village__c> villages = [SELECT Id, Name FROM Village__c WHERE Name IN ('Moinabad', 'Shamshabad', 'Kandukur')
                             AND Id NOT IN (SELECT Village__c FROM Account WHERE Village__c != null)];
delete villages;
System.debug(LoggingLevel.ERROR, 'CLEANUP DONE | removed ' + households.size() + ' households and ' + villages.size() + ' villages');
