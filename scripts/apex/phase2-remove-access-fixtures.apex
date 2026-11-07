// =====================================================================================
// HealthConnect CareLoop - Phase 2: remove the access-test records
// =====================================================================================
// Deletes ONLY the synthetic records made by phase2-access-fixtures.apex:
//   households named "ZZ Access Test%" (their patients, visits and care activities are
//   deleted with them), the "ZZ Access Test Village", and error logs with source "ZZ Access Test".
// Then empties them from the Recycle Bin so they do not use your 5 MB of storage.
// Run it after you have finished the Login As checks.
//
// Run:
//   sf apex run --file scripts/apex/phase2-remove-access-fixtures.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'CLEANUP ' + line);
}

void run() {
    List<Account> households = [SELECT Id FROM Account WHERE Name LIKE 'ZZ Access Test%'];
    List<Village__c> villages = [SELECT Id FROM Village__c WHERE Name = 'ZZ Access Test Village'];
    List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c WHERE Source__c = 'ZZ Access Test'];
    say('FOUND | households=' + households.size() + ' villages=' + villages.size() + ' error logs=' + logs.size());

    List<SObject> deleted = new List<SObject>();
    try {
        // Households first: Salesforce deletes their patients, and the patients' visits and
        // care activities (master-detail), in the same operation.
        if (!households.isEmpty()) {
            delete households;
            deleted.addAll((List<SObject>) households);
        }
        if (!villages.isEmpty()) {
            delete villages;
            deleted.addAll((List<SObject>) villages);
        }
        if (!logs.isEmpty()) {
            delete logs;
            deleted.addAll((List<SObject>) logs);
        }
        if (!deleted.isEmpty()) {
            Database.emptyRecycleBin(deleted);
        }
    } catch (Exception e) {
        say('ERROR | ' + e.getTypeName() + ': ' + e.getMessage());
        return;
    }
    say('REMAINING | households=' + [SELECT COUNT() FROM Account WHERE Name LIKE 'ZZ Access Test%']
        + ' patients=' + [SELECT COUNT() FROM Contact WHERE LastName = 'Access Test Patient']
        + ' villages=' + [SELECT COUNT() FROM Village__c WHERE Name = 'ZZ Access Test Village']);
    say('FINISHED | Access-test records removed.');
}

run();
