// =====================================================================================
// HealthConnect CareLoop - Phase 4: verify the proactive care engine (rolls everything back)
// =====================================================================================
// Uses Lakshmi Devi (worker) and Meena Iyer (her supervisor) from Phase 2 and synthetic patients:
//   1. Sweep moves statuses and climbs the ladder: reminder (-3 days), worker task (+3), supervisor (+10)
//   2. Reminders are combined per person, in the caregiver's language for a child
//   3. No consent -> reminder stored as Skipped with the reason
//   4. Running the sweep again creates nothing new (idempotent)
//   5. Explainable priority: score, level, reasons, next best action stored on the patient
//   6. A red-flag visit appears in the Doctor Review queue
//   7. No Error Log entries during the run
// Everything is rolled back. Alerts are published only after a transaction commits, so the test
// red-flag visit does not notify the doctors. (The sweep's bell to Lakshmi and Meena is not part of the
// database transaction, so they may see one "overdue care" bell from this check.)
//
// Run:
//   sf apex run --file scripts/apex/phase4-verify.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'PHASE4 ' + line);
}

Integer mark(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}

User userFor(String first, String last) {
    String username = (first + '.' + last + '.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
    List<User> users = [SELECT Id, ManagerId FROM User WHERE Username = :username AND IsActive = true];
    return users.isEmpty() ? null : users[0];
}

Integer runChecks() {
    Integer failures = 0;
    User lakshmi = userFor('Lakshmi', 'Devi');
    User meena = userFor('Meena', 'Iyer');
    if (lakshmi == null || meena == null || lakshmi.ManagerId != meena.Id) {
        say('STOP  Lakshmi Devi must exist and report to Meena Iyer (Phase 2).');
        return 1;
    }
    Date today = CareLoopClock.today();
    say('INFO  CareLoop clock today = ' + today + (CareLoopClock.isSimulated() ? ' (SIMULATED)' : ' (real date)'));
    Integer logsBefore = [SELECT COUNT() FROM Error_Log__c];
    TriggerHandler.bypass('ContactTriggerHandler');

    Village__c village = new Village__c(Name = 'Phase 4 Verify Village', Region__c = 'North', District__c = 'Rangareddy',
        State__c = 'Telangana', Health_Worker__c = lakshmi.Id);
    insert village;
    Account household = new Account(Name = 'Phase 4 Verify Household', Village__c = village.Id, OwnerId = lakshmi.Id);
    insert household;
    Contact mother = new Contact(FirstName = 'Verify', LastName = 'Mother', AccountId = household.Id, Village__c = village.Id,
        Birthdate = today.addYears(-27), Gender__c = 'Female', Assigned_Health_Worker__c = lakshmi.Id,
        Preferred_Language__c = 'Telugu', Preferred_Channel__c = 'Portal Inbox', Reminder_Consent__c = true, MobilePhone = '9000000201');
    Contact elder = new Contact(FirstName = 'Verify', LastName = 'Elder', AccountId = household.Id, Village__c = village.Id,
        Birthdate = today.addYears(-66), Gender__c = 'Male', Assigned_Health_Worker__c = lakshmi.Id,
        Preferred_Language__c = 'English', Preferred_Channel__c = 'SMS', Reminder_Consent__c = false, MobilePhone = '9000000202');
    insert new List<Contact>{ mother, elder };
    Contact baby = new Contact(FirstName = 'Verify', LastName = 'Baby', AccountId = household.Id, Village__c = village.Id,
        Birthdate = today.addDays(-80), Gender__c = 'Female', Assigned_Health_Worker__c = lakshmi.Id, Caregiver__c = mother.Id,
        Preferred_Language__c = 'English', Preferred_Channel__c = 'Portal Inbox');
    insert baby;

    Care_Activity__c upcoming = new Care_Activity__c(Name = 'Verify OPV - dose 3', Patient__c = baby.Id, Activity_Type__c = 'Immunization', Due_Date__c = today.addDays(2));
    Care_Activity__c late = new Care_Activity__c(Name = 'Verify BCG - dose 1', Patient__c = baby.Id, Activity_Type__c = 'Immunization', Due_Date__c = today.addDays(-5));
    Care_Activity__c veryLate = new Care_Activity__c(Name = 'Verify BP check', Patient__c = elder.Id, Activity_Type__c = 'Routine Check-up', Due_Date__c = today.addDays(-15));
    insert new List<Care_Activity__c>{ upcoming, late, veryLate };

    Set<Id> ids = new Set<Id>{ mother.Id, elder.Id, baby.Id };
    new CareSweepBatch(false).run(ids);

    Set<Id> activityIds = new Set<Id>{ upcoming.Id, late.Id, veryLate.Id };
    Map<Id, Care_Activity__c> acts = new Map<Id, Care_Activity__c>([SELECT Id, Status__c, Escalation_Level__c FROM Care_Activity__c WHERE Id IN :activityIds]);
    failures += mark(acts.get(upcoming.Id).Status__c == 'Due' && acts.get(upcoming.Id).Escalation_Level__c == 1, '1a Due in 2 days -> Due, level 1 (patient reminder)');
    failures += mark(acts.get(late.Id).Status__c == 'Overdue' && acts.get(late.Id).Escalation_Level__c == 2, '1b 5 days late -> Overdue, level 2 (worker task)');
    failures += mark(acts.get(veryLate.Id).Escalation_Level__c == 3, '1c 15 days late -> level 3 (supervisor)');
    failures += mark([SELECT COUNT() FROM Task WHERE WhatId = :late.Id AND OwnerId = :lakshmi.Id] == 1, '1d Lakshmi has a follow-up task');
    failures += mark([SELECT COUNT() FROM Task WHERE WhatId = :veryLate.Id AND OwnerId = :meena.Id AND Priority = 'High'] == 1, '1e Meena has the escalation task');

    List<Notification__c> motherNotes = [SELECT Language__c, Status__c, Message__c FROM Notification__c WHERE Patient__c = :mother.Id];
    failures += mark(motherNotes.size() == 2, '2a Two reminders to the mother (upcoming + overdue), none to the baby record');
    Boolean telugu = !motherNotes.isEmpty() && motherNotes[0].Language__c == 'Telugu' && motherNotes[0].Status__c == 'Sent';
    failures += mark(telugu, '2b In Telugu, delivered to the portal inbox');
    if (!motherNotes.isEmpty()) {
        say('INFO  Example reminder: ' + motherNotes[0].Message__c);
    }
    Notification__c elderNote = [SELECT Status__c, Skip_Reason__c FROM Notification__c WHERE Patient__c = :elder.Id LIMIT 1];
    failures += mark(elderNote.Status__c == 'Skipped' && elderNote.Skip_Reason__c == 'No reminder consent recorded', '3  No consent -> Skipped with reason');

    Integer notesBefore = [SELECT COUNT() FROM Notification__c WHERE Patient__c IN :ids];
    Integer tasksBefore = [SELECT COUNT() FROM Task WHERE WhoId IN :ids];
    new CareSweepBatch(false).run(ids);
    failures += mark([SELECT COUNT() FROM Notification__c WHERE Patient__c IN :ids] == notesBefore
        && [SELECT COUNT() FROM Task WHERE WhoId IN :ids] == tasksBefore, '4  Second sweep created nothing new');

    PatientPriorityBatch.store(ids);
    Contact scored = [SELECT Priority_Score__c, Priority_Level__c, Next_Best_Action__c, Priority_Explanation__c FROM Contact WHERE Id = :baby.Id];
    failures += mark(scored.Priority_Score__c != null && scored.Priority_Score__c > 0 && scored.Next_Best_Action__c.contains('BCG'),
        '5  Baby scored ' + scored.Priority_Score__c + ' (' + scored.Priority_Level__c + '): ' + scored.Next_Best_Action__c);
    say('INFO  Why: ' + scored.Priority_Explanation__c.replace('\n', ' | '));

    Health_Visit__c red = new Health_Visit__c(Patient__c = elder.Id, Visit_Date__c = System.now(), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = 'Completed', BP_Systolic__c = 188, BP_Diastolic__c = 116);
    insert red;
    Boolean inQueue = false;
    for (DoctorReviewController.ReviewItem item : DoctorReviewController.getPendingReviews()) {
        if (item.visitId == red.Id && item.redFlag) {
            inQueue = true;
        }
    }
    failures += mark(inQueue, '6  Red-flag visit is in the Doctor Review queue');

    Integer newLogs = [SELECT COUNT() FROM Error_Log__c] - logsBefore;
    failures += mark(newLogs == 0, '7  No Error Log entries (' + newLogs + ')');
    return failures;
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
say(failures == 0 ? 'PHASE 4 VERIFY PASSED (all test data rolled back)' : 'PHASE 4 VERIFY: ' + failures + ' FAILURE(S) (rolled back)');
