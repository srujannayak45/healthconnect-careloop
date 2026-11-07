// =====================================================================================
// HealthConnect CareLoop - Phase 5: verify patient engagement (rolls everything back)
// =====================================================================================
//   1. Consent ledger: grant + withdraw chain correctly and verify intact
//   2. Edits to the ledger are blocked; a bypassed edit is detected by verification
//   3. A patient's "Need Help" reply creates a high-priority task for the health worker
//   4. Configuration: portal profile, Kavya's portal user + permission set, live site, Named Credential
//   5. No Error Log entries
//
// Run:
//   sf apex run --file scripts/apex/phase5-verify.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'PHASE5 ' + line);
}

Integer mark(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}

Integer info(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'TODO  ') + label);
    return ok ? 0 : 1;
}

Integer runChecks() {
    Integer failures = 0;
    Integer logsBefore = [SELECT COUNT() FROM Error_Log__c];
    TriggerHandler.bypass('ContactTriggerHandler');
    Village__c village = new Village__c(Name = 'Phase 5 Verify Village', Region__c = 'North', District__c = 'Rangareddy', State__c = 'Telangana');
    insert village;
    Account household = new Account(Name = 'Phase 5 Verify Household', Village__c = village.Id);
    insert household;
    Contact p = new Contact(FirstName = 'Verify', LastName = 'Patient', AccountId = household.Id, Village__c = village.Id,
        Birthdate = Date.today().addYears(-30), Gender__c = 'Female', Assigned_Health_Worker__c = UserInfo.getUserId());
    insert p;

    ConsentService.record(new List<ConsentService.ConsentRequest>{
        new ConsentService.ConsentRequest(p.Id, 'Reminders and Communication', true, 'Paper Form', 'Signed at registration')
    });
    ConsentService.record(new List<ConsentService.ConsentRequest>{
        new ConsentService.ConsentRequest(p.Id, 'Reminders and Communication', false, 'Verbal (Witnessed)', 'Asked to stop')
    });
    ConsentService.VerifyResult ok = ConsentService.verify(p.Id);
    Contact mirrored = [SELECT Reminder_Consent__c FROM Contact WHERE Id = :p.Id];
    failures += mark(ok.intact && ok.events == 2 && mirrored.Reminder_Consent__c == false, '1  Ledger: 2 chained events, intact, patient now opted out');

    Consent_Event__c first = [SELECT Id FROM Consent_Event__c WHERE Patient__c = :p.Id AND Sequence__c = 1];
    Boolean blocked = false;
    try {
        update new Consent_Event__c(Id = first.Id, Reason__c = 'changed');
    } catch (DmlException e) {
        blocked = e.getMessage().contains('append-only');
    }
    TriggerHandler.bypass('ConsentEventTriggerHandler');
    update new Consent_Event__c(Id = first.Id, Reason__c = 'changed behind the system\'s back');
    TriggerHandler.clearBypass('ConsentEventTriggerHandler');
    ConsentService.VerifyResult tampered = ConsentService.verify(p.Id);
    failures += mark(blocked && !tampered.intact, '2  Edit blocked; forced edit detected: ' + tampered.message);

    Care_Activity__c a = new Care_Activity__c(Name = 'Verify check-up', Patient__c = p.Id, Activity_Type__c = 'Routine Check-up',
        Due_Date__c = Date.today().addDays(1));
    insert a;
    a = [SELECT Id, Name, Patient__c, Assigned_To__c, Patient__r.Name, Status__c FROM Care_Activity__c WHERE Id = :a.Id];
    PatientResponseService.followUp(a, 'Need Help', null, 'Cannot travel this week');
    failures += mark([SELECT COUNT() FROM Task WHERE WhatId = :a.Id AND Priority = 'High'] == 1, '3  "Need Help" reply -> high-priority task for the health worker');

    Integer newLogs = [SELECT COUNT() FROM Error_Log__c] - logsBefore;
    failures += mark(newLogs == 0, '5  No Error Log entries (' + newLogs + ')');
    return failures;
}

Integer configChecks() {
    Integer todo = 0;
    todo += info([SELECT COUNT() FROM Profile WHERE Name = 'CareLoop Patient Portal User'] == 1, '4a Portal profile "CareLoop Patient Portal User" exists');
    String username = ('kavya.rao.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
    List<User> kavya = [SELECT Id, IsActive, ContactId FROM User WHERE Username = :username];
    todo += info(!kavya.isEmpty() && kavya[0].IsActive && kavya[0].ContactId != null, '4b Kavya Rao has an active portal user');
    todo += info(!kavya.isEmpty() && [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :kavya[0].Id AND PermissionSet.Name = 'CareLoop_Patient'] == 1,
        '4c Kavya has the CareLoop_Patient permission set');
    List<Network> sites = [SELECT Name, Status FROM Network WHERE Status = 'Live'];
    todo += info(!sites.isEmpty(), '4d A live Experience Cloud site exists' + (sites.isEmpty() ? '' : ' (' + sites[0].Name + ')'));
    todo += info([SELECT COUNT() FROM NamedCredential WHERE DeveloperName = 'CareLoop_SMS'] == 1, '4e Named Credential CareLoop_SMS exists');
    say('INFO  SMS provider class = ' + CareRules.setting().SMS_Provider_Class__c);
    return todo;
}

Savepoint beforeTest = Database.setSavepoint();
Integer failures = 1;
try {
    failures = runChecks();
} catch (Exception e) {
    say('ERROR ' + e.getTypeName() + ': ' + e.getMessage() + ' | ' + e.getStackTraceString());
} finally {
    Database.rollback(beforeTest);
}
Integer todo = configChecks();
say(failures == 0 && todo == 0 ? 'PHASE 5 VERIFY PASSED'
    : (failures == 0 ? 'PHASE 5 LOGIC OK - ' + todo + ' setup item(s) still TODO' : 'PHASE 5 VERIFY: ' + failures + ' FAILURE(S)'));
