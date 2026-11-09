// =====================================================================================
// HealthConnect CareLoop - Phase 6: verify the Care Navigator (rolls everything back)
// =====================================================================================
// Builds a small synthetic world assigned to YOU (the admin, who has no real patients): two households
// in one village (one with three generations of care due) and one household 25 km away.
// With capacity 2 the Navigator must:
//   1. pick the three-generation household first and stay in the same village for the second visit
//   2. reach more care gaps than the due-date list, with less walking
//   3. save the plan with its stops, owned by the worker
//   4. turn a recorded visit + a completed vaccine into "Visited" and "1 gap closed" automatically
//   5. keep a started plan when re-planned; refuse "Skipped" without a reason
//   6. log no errors
// (Your real plans are not touched: the test uses its own synthetic patients and rolls back.)
//
// Run:
//   sf apex run --file scripts/apex/phase6-verify.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'PHASE6 ' + line);
}

Integer mark(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}

Integer runChecks() {
    Integer failures = 0;
    Integer logsBefore = [SELECT COUNT() FROM Error_Log__c];
    Id worker = UserInfo.getUserId();   // you are the synthetic worker for this check
    Date today = CareLoopClock.today();
    if ([SELECT COUNT() FROM Care_Activity__c WHERE Assigned_To__c = :worker AND Status__c IN ('Due', 'Overdue')] > 0) {
        say('INFO  Your user has real open care assigned; the checks below still use only the synthetic households.');
    }
    TriggerHandler.bypass('ContactTriggerHandler');
    Village__c near = new Village__c(Name = 'Verify Near', Region__c = 'North', District__c = 'D', State__c = 'Telangana',
        Location__Latitude__s = 17.46, Location__Longitude__s = 78.36);
    Village__c far = new Village__c(Name = 'Verify Far', Region__c = 'North', District__c = 'D', State__c = 'Telangana',
        Location__Latitude__s = 17.25, Location__Longitude__s = 78.50);
    insert new List<Village__c>{ near, far };
    Account family = new Account(Name = 'Verify Three Generations', Village__c = near.Id, OwnerId = worker);
    Account single = new Account(Name = 'Verify Neighbour', Village__c = near.Id, OwnerId = worker);
    Account distant = new Account(Name = 'Verify Distant', Village__c = far.Id, OwnerId = worker);
    insert new List<Account>{ family, single, distant };
    List<Contact> people = new List<Contact>{
        new Contact(FirstName = 'V', LastName = 'Baby', AccountId = family.Id, Birthdate = today.addDays(-90), Gender__c = 'Female', Assigned_Health_Worker__c = worker),
        new Contact(FirstName = 'V', LastName = 'Mother', AccountId = family.Id, Birthdate = today.addYears(-25), Gender__c = 'Female', Assigned_Health_Worker__c = worker),
        new Contact(FirstName = 'V', LastName = 'Grandfather', AccountId = family.Id, Birthdate = today.addYears(-66), Gender__c = 'Male', Assigned_Health_Worker__c = worker),
        new Contact(FirstName = 'V', LastName = 'Neighbour', AccountId = single.Id, Birthdate = today.addYears(-50), Gender__c = 'Male', Assigned_Health_Worker__c = worker),
        new Contact(FirstName = 'V', LastName = 'Distant', AccountId = distant.Id, Birthdate = today.addYears(-55), Gender__c = 'Male', Assigned_Health_Worker__c = worker)
    };
    insert people;
    insert new List<Care_Activity__c>{
        new Care_Activity__c(Name = 'V distant check', Patient__c = people[4].Id, Activity_Type__c = 'Routine Check-up', Due_Date__c = today.addDays(-40)),
        new Care_Activity__c(Name = 'V neighbour check', Patient__c = people[3].Id, Activity_Type__c = 'Routine Check-up', Due_Date__c = today.addDays(-35)),
        new Care_Activity__c(Name = 'V OPV', Patient__c = people[0].Id, Activity_Type__c = 'Immunization', Due_Date__c = today.addDays(-10)),
        new Care_Activity__c(Name = 'V Penta', Patient__c = people[0].Id, Activity_Type__c = 'Immunization', Due_Date__c = today.addDays(-10)),
        new Care_Activity__c(Name = 'V ANC', Patient__c = people[1].Id, Activity_Type__c = 'Antenatal Check-up', Due_Date__c = today.addDays(2)),
        new Care_Activity__c(Name = 'V BP', Patient__c = people[2].Id, Activity_Type__c = 'Routine Check-up', Due_Date__c = today.addDays(-5))
    };

    NavigatorPlanner.Plan plan = NavigatorPlanner.plan(worker, today, 2);
    NavigatorPlanner.Stop fam = plan.stops.isEmpty() ? null : plan.stops[0];
    failures += mark(fam != null && fam.householdId == family.Id && fam.gaps == 4,
        '1a First stop: the three-generation household, 4 gaps in one visit');
    failures += mark(plan.stops.size() == 2 && plan.stops[1].householdId == single.Id && plan.distanceKm == 0,
        '1b Second stop: the neighbour in the same village (0 km), not the far household');
    say('INFO  Why the family: ' + (fam == null ? '' : String.join(fam.reasons, ' | ')));
    failures += mark(plan.gapsTargeted == 5 && plan.baselineGaps == 2 && plan.baselineDistanceKm > 20,
        '2  Plan reaches ' + plan.gapsTargeted + ' gaps in 2 visits and 0 km; the due-date list reaches '
        + plan.baselineGaps + ' and walks ' + plan.baselineDistanceKm + ' km');

    Map<Id, Id> saved = NavigatorService.generate(new Set<Id>{ worker }, today);
    Visit_Plan__c p = [SELECT Id, OwnerId, Planned_Stops__c, (SELECT Id, Household__c FROM Stops__r) FROM Visit_Plan__c WHERE Id = :saved.get(worker)];
    failures += mark(p.OwnerId == worker && p.Planned_Stops__c > 0, '3  Plan saved with ' + p.Planned_Stops__c + ' stops, owned by the worker');

    Visit_Plan_Stop__c famStop;
    for (Visit_Plan_Stop__c s : p.Stops__r) {
        if (s.Household__c == family.Id) { famStop = s; }
    }
    if (famStop != null) {
        insert new Health_Visit__c(Patient__c = people[0].Id, Visit_Date__c = System.now(), Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed');
        Care_Activity__c opv = [SELECT Id FROM Care_Activity__c WHERE Name = 'V OPV'];
        update new Care_Activity__c(Id = opv.Id, Status__c = 'Completed', Completed_Date__c = today);
        NavigatorService.refreshProgress(new Set<Id>{ p.Id });
        Visit_Plan_Stop__c after = [SELECT Status__c, Gaps_Closed__c FROM Visit_Plan_Stop__c WHERE Id = :famStop.Id];
        failures += mark(after.Status__c == 'Visited' && after.Gaps_Closed__c == 1, '4  Visit + vaccine recorded -> stop Visited, 1 gap closed');
    } else {
        failures += mark(false, '4  The family household was not in the saved plan');
    }
    NavigatorService.generate(new Set<Id>{ worker }, today);
    failures += mark([SELECT COUNT() FROM Visit_Plan_Stop__c WHERE Plan__c = :p.Id] == p.Stops__r.size(), '5a Started plan kept when re-planned');
    Boolean refused = false;
    try {
        NavigatorService.setStopStatus(p.Stops__r[0].Id, 'Skipped', '');
    } catch (NavigatorService.NavigatorException e) {
        refused = true;
    }
    failures += mark(refused, '5b Skipping without a reason is refused');
    Integer newLogs = [SELECT COUNT() FROM Error_Log__c] - logsBefore;
    failures += mark(newLogs == 0, '6  No Error Log entries (' + newLogs + ')');
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
say(failures == 0 ? 'PHASE 6 VERIFY PASSED (all test data rolled back)' : 'PHASE 6 VERIFY: ' + failures + ' FAILURE(S) (rolled back)');
