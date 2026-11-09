// =====================================================================================
// HealthConnect CareLoop - Phase 7: verify workflows, approvals and programme intelligence
// =====================================================================================
//   1. Flows active: Register Patient, Request Activity Closure, Household Default Owner
//   2. Approval process "Care Activity Closure" active
//   3. A new household is owned by its village's health worker (record-triggered flow)
//   4. An approved closure becomes Missed / Cancelled from the reason; a rejection keeps it open
//   5. 8 CareLoop reports and the Programme Intelligence dashboard exist
//   6. Reporting formulas work (Region / Village on care activities)
// Data checks are rolled back.
//
// Run:
//   sf apex run --file scripts/apex/phase7-verify.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'PHASE7 ' + line);
}

Integer mark(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}

Integer configChecks() {
    Integer failures = 0;
    Set<String> flows = new Set<String>{ 'CareLoop_Register_Patient', 'CareLoop_Request_Activity_Closure', 'CareLoop_Household_Default_Owner' };
    Integer active = [SELECT COUNT() FROM FlowDefinitionView WHERE ApiName IN :flows AND IsActive = true];
    failures += mark(active == 3, '1  ' + active + ' of 3 CareLoop flows active');
    failures += mark([SELECT COUNT() FROM ProcessDefinition WHERE DeveloperName = 'Care_Activity_Closure' AND State = 'Active'] == 1,
        '2  Approval process Care Activity Closure is active');
    Integer reports = [SELECT COUNT() FROM Report WHERE FolderName = 'CareLoop Reports'];
    Integer dashboards = [SELECT COUNT() FROM Dashboard WHERE Title = 'CareLoop Programme Intelligence'];
    failures += mark(reports == 8 && dashboards == 1, '5  ' + reports + ' CareLoop reports, ' + dashboards + ' Programme Intelligence dashboard');
    return failures;
}

Integer dataChecks() {
    Integer failures = 0;
    String username = ('lakshmi.devi.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
    List<User> lakshmi = [SELECT Id FROM User WHERE Username = :username];
    Village__c v = new Village__c(Name = 'Phase 7 Verify Village', Region__c = 'South', District__c = 'D', State__c = 'Telangana',
        Health_Worker__c = lakshmi.isEmpty() ? UserInfo.getUserId() : lakshmi[0].Id);
    insert v;
    Account hh = new Account(Name = 'Phase 7 Verify Household', Village__c = v.Id);
    insert hh;
    Id owner = [SELECT OwnerId FROM Account WHERE Id = :hh.Id].OwnerId;
    failures += mark(owner == v.Health_Worker__c, '3  New household owned by the village health worker');

    TriggerHandler.bypass('ContactTriggerHandler');
    Contact p = new Contact(FirstName = 'Verify', LastName = 'Closure', AccountId = hh.Id, Village__c = v.Id,
        Birthdate = Date.today().addYears(-40), Gender__c = 'Male', Assigned_Health_Worker__c = UserInfo.getUserId());
    insert p;
    Care_Activity__c refused = new Care_Activity__c(Name = 'Verify refused', Patient__c = p.Id, Activity_Type__c = 'Routine Check-up',
        Due_Date__c = Date.today().addDays(-5), Closure_Reason__c = 'Refused');
    Care_Activity__c moved = new Care_Activity__c(Name = 'Verify moved', Patient__c = p.Id, Activity_Type__c = 'Routine Check-up',
        Due_Date__c = Date.today().addDays(-5), Closure_Reason__c = 'Moved Away');
    insert new List<Care_Activity__c>{ refused, moved };
    update new List<Care_Activity__c>{
        new Care_Activity__c(Id = refused.Id, Approval_Status__c = 'Approved'),
        new Care_Activity__c(Id = moved.Id, Approval_Status__c = 'Rejected')
    };
    Map<Id, Care_Activity__c> after = new Map<Id, Care_Activity__c>([SELECT Id, Status__c, Next_Action__c, Region__c, Village_Name__c
                                                                      FROM Care_Activity__c WHERE Patient__c = :p.Id]);
    failures += mark(after.get(refused.Id).Status__c == 'Missed' && after.get(moved.Id).Status__c == 'Overdue',
        '4  Approved "Refused" -> Missed; rejected request stays open: ' + after.get(moved.Id).Next_Action__c);
    failures += mark(after.get(refused.Id).Region__c == 'South' && after.get(refused.Id).Village_Name__c == 'Phase 7 Verify Village',
        '6  Reporting formulas: Region and Village on care activities');
    return failures;
}

Integer failures = configChecks();
Savepoint sp = Database.setSavepoint();
try {
    failures += dataChecks();
} catch (Exception e) {
    failures++;
    say('ERROR ' + e.getTypeName() + ': ' + e.getMessage() + ' | ' + e.getStackTraceString());
} finally {
    Database.rollback(sp);
}
say(failures == 0 ? 'PHASE 7 VERIFY PASSED' : 'PHASE 7 VERIFY: ' + failures + ' FAILURE(S)');
