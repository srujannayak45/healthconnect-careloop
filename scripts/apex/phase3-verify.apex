// =====================================================================================
// HealthConnect CareLoop - Phase 3: verify the Care Activity engine (rolls everything back)
// =====================================================================================
// Runs the whole Phase 3 workflow with synthetic records, checks each result, and then
// rolls back every change, so nothing is left in your org.
//   1. Newborn, pregnant mother and hypertensive elder -> care schedules generated
//   2. Generation run twice -> no duplicates
//   3. Visit with BP 186/112 -> red flag + Pending Review
//   4. Unsuccessful visit -> failed outreach attempts counted
//   5. Doctor finalises a recommendation -> follow-up + care-plan activities, visit Reviewed
//   6. Completing an activity -> status, Days Overdue and open Task closed
//   7. No errors logged during the run
//
// Run:
//   sf apex run --file scripts/apex/phase3-verify.apex --target-org careloop | Select-String "USER_DEBUG"
// The last line is "PHASE 3 VERIFY PASSED" or lists the failures.
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'PHASE3 ' + line);
}

Integer mark(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}

Integer configured(String eligibility) {
    Integer total = 0;
    for (Care_Schedule__mdt s : Care_Schedule__mdt.getAll().values()) {
        if (s.Active__c && s.Eligibility__c == eligibility) {
            total += (s.Occurrences__c == null || s.Occurrences__c < 1) ? 1 : s.Occurrences__c.intValue();
        }
    }
    return total;
}

Integer countFor(Id patientId) {
    return [SELECT COUNT() FROM Care_Activity__c WHERE Patient__c = :patientId];
}

Integer runChecks() {
    Integer failures = 0;
    Date today = CareLoopClock.today();
    say('INFO  CareLoop clock today = ' + today + (CareLoopClock.isSimulated() ? ' (SIMULATED demo date)' : ' (real date)'));
    Integer logsBefore = [SELECT COUNT() FROM Error_Log__c];

    // The patient trigger would queue a background job; here we call the service directly
    // instead, because a queued job would outlive the rollback at the end.
    TriggerHandler.bypass('ContactTriggerHandler');

    Village__c village = new Village__c(Name = 'Phase 3 Verify Village', District__c = 'Rangareddy',
        State__c = 'Telangana', Region__c = 'North');
    insert village;
    Account household = new Account(Name = 'Phase 3 Verify Household', Village__c = village.Id);
    insert household;
    Contact baby = new Contact(FirstName = 'Verify', LastName = 'Baby', AccountId = household.Id, Village__c = village.Id,
        Birthdate = Date.today().addDays(-75), Gender__c = 'Female', Assigned_Health_Worker__c = UserInfo.getUserId());
    Contact mother = new Contact(FirstName = 'Verify', LastName = 'Mother', AccountId = household.Id, Village__c = village.Id,
        Birthdate = Date.today().addYears(-26), Gender__c = 'Female', Is_Pregnant__c = true,
        Assigned_Health_Worker__c = UserInfo.getUserId());
    Contact elder = new Contact(FirstName = 'Verify', LastName = 'Elder', AccountId = household.Id, Village__c = village.Id,
        Birthdate = Date.today().addYears(-62), Gender__c = 'Male', Chronic_Conditions__c = 'Hypertension',
        Assigned_Health_Worker__c = UserInfo.getUserId());
    insert new List<Contact>{ baby, mother, elder };

    // 1. Schedule generation
    Set<Id> patientIds = new Set<Id>{ baby.Id, mother.Id, elder.Id };
    Integer created = CareScheduleService.generate(patientIds);
    Integer expectedBaby = configured('Child Under 2');
    Integer expectedMother = configured('Pregnant');
    Integer expectedElder = configured('Hypertension') + configured('Adult 30 Plus');
    failures += mark(countFor(baby.Id) == expectedBaby, '1a Newborn received ' + countFor(baby.Id) + ' vaccine doses (expected ' + expectedBaby + ')');
    Integer babyOverdue = [SELECT COUNT() FROM Care_Activity__c WHERE Patient__c = :baby.Id AND Status__c = 'Overdue'];
    failures += mark(babyOverdue > 0, '1b 75-day-old has ' + babyOverdue + ' overdue catch-up dose(s)');
    failures += mark(countFor(mother.Id) == expectedMother, '1c Pregnant mother received ' + countFor(mother.Id) + ' antenatal check-ups (expected ' + expectedMother + ')');
    failures += mark(countFor(elder.Id) == expectedElder, '1d Hypertensive elder received ' + countFor(elder.Id) + ' activities (expected ' + expectedElder + ')');
    Care_Activity__c sample = [SELECT Name, Status__c, Due_Date__c, Assigned_To__c, Source__c FROM Care_Activity__c
                               WHERE Patient__c = :baby.Id ORDER BY Due_Date__c LIMIT 1];
    say('INFO  Example: "' + sample.Name + '" due ' + sample.Due_Date__c + ' is ' + sample.Status__c);
    failures += mark(sample.Source__c == 'Care Schedule' && sample.Assigned_To__c == UserInfo.getUserId(),
        '1e Generated activities carry their source and the assigned health worker');

    // 2. Idempotency
    Integer second = CareScheduleService.generate(patientIds);
    failures += mark(second == 0, '2  Running generation again created ' + second + ' activities (expected 0)');

    // 3. Red flag
    Health_Visit__c redVisit = new Health_Visit__c(Patient__c = elder.Id, Visit_Date__c = System.now(),
        Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed', BP_Systolic__c = 186, BP_Diastolic__c = 112, SpO2__c = 96);
    insert redVisit;
    redVisit = [SELECT Red_Flag__c, Red_Flag_Reason__c, Review_Status__c FROM Health_Visit__c WHERE Id = :redVisit.Id];
    failures += mark(redVisit.Red_Flag__c && redVisit.Review_Status__c == 'Pending Review',
        '3  BP 186/112 is red-flagged: "' + redVisit.Red_Flag_Reason__c + '" -> ' + redVisit.Review_Status__c);

    // 4. Unsuccessful visit
    insert new Health_Visit__c(Patient__c = mother.Id, Visit_Date__c = System.now(), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = 'Patient Not Available');
    Contact motherHistory = [SELECT Failed_Outreach_Attempts__c, Last_Successful_Contact__c FROM Contact WHERE Id = :mother.Id];
    Contact elderHistory = [SELECT Last_Successful_Contact__c FROM Contact WHERE Id = :elder.Id];
    failures += mark(motherHistory.Failed_Outreach_Attempts__c == 1 && motherHistory.Last_Successful_Contact__c == null,
        '4a Unsuccessful visit counted as a failed outreach attempt');
    failures += mark(elderHistory.Last_Successful_Contact__c == Date.today(), '4b Completed visit recorded as last successful contact');

    // 5. Doctor recommendation -> care plan
    Medical_Recommendation__c rec = new Medical_Recommendation__c(Outreach_Visit__c = redVisit.Id, Status__c = 'Final',
        Assessment__c = 'Stage 2 hypertension (synthetic test).', Advice__c = 'Reduce salt; daily tablet; re-check in one week.',
        Follow_Up_In_Days__c = 7, Check_Up_Interval_Days__c = 30, Check_Up_Occurrences__c = 3);
    insert rec;
    Integer planned = [SELECT COUNT() FROM Care_Activity__c WHERE Recommendation__c = :rec.Id];
    Health_Visit__c reviewed = [SELECT Review_Status__c FROM Health_Visit__c WHERE Id = :redVisit.Id];
    Medical_Recommendation__c finalRec = [SELECT Doctor__c, Finalized_On__c FROM Medical_Recommendation__c WHERE Id = :rec.Id];
    failures += mark(planned == 4, '5a Final recommendation created ' + planned + ' care-plan activities (expected 4)');
    failures += mark(reviewed.Review_Status__c == 'Reviewed', '5b Visit is now Reviewed');
    failures += mark(finalRec.Doctor__c == UserInfo.getUserId() && finalRec.Finalized_On__c != null, '5c Doctor and time stamped');

    // 6. Completing an activity
    Care_Activity__c overdue = [SELECT Id FROM Care_Activity__c WHERE Patient__c = :baby.Id AND Status__c = 'Overdue' LIMIT 1];
    Task followUp = new Task(WhatId = overdue.Id, Subject = 'Verify follow-up task', Status = 'Not Started', OwnerId = UserInfo.getUserId());
    insert followUp;
    update new Care_Activity__c(Id = overdue.Id, Status__c = 'Completed', Completed_Date__c = Date.today());
    Care_Activity__c done = [SELECT Status__c, Days_Overdue__c FROM Care_Activity__c WHERE Id = :overdue.Id];
    Boolean taskClosed = [SELECT IsClosed FROM Task WHERE Id = :followUp.Id].IsClosed;
    failures += mark(done.Status__c == 'Completed' && done.Days_Overdue__c == 0 && taskClosed,
        '6  Completed activity reset Days Overdue and closed its open task');

    // 7. No errors
    Integer newLogs = [SELECT COUNT() FROM Error_Log__c] - logsBefore;
    failures += mark(newLogs == 0, '7  No Error Log entries were created (' + newLogs + ')');
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
say(failures == 0
    ? 'PHASE 3 VERIFY PASSED (all test data rolled back)'
    : 'PHASE 3 VERIFY: ' + failures + ' FAILURE(S) (all test data rolled back)');
