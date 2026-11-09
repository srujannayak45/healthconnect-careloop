@IsTest
private class NavigatorPlannerTest {

    private static Village__c village(String name, Decimal lat, Decimal lng) {
        Village__c v = new Village__c(Name = name, Region__c = 'North', District__c = 'D', State__c = 'Telangana',
            Location__Latitude__s = lat, Location__Longitude__s = lng);
        insert v;
        return v;
    }

    private static Contact member(Id householdId, Id villageId, String first, Date birthdate, Id worker) {
        Contact c = CareLoopTestFactory.newPatient(householdId, villageId, birthdate);
        c.FirstName = first;
        c.Assigned_Health_Worker__c = worker;
        return c;
    }

    /**
     * Village A (near): household "Family" with a baby (2 overdue vaccines) and a mother (ANC due);
     *                   household "Single" with one overdue check-up.
     * Village B (25 km away): household "Far" with one overdue check-up.
     * Capacity 2.
     */
    private static Id setUpWorld() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.usePriorityRules();
        Id me = UserInfo.getUserId();
        Village__c a = village('Near Village', 17.46, 78.36);
        Village__c b = village('Far Village', 17.25, 78.50);
        Account family = new Account(Name = 'Family Household', Village__c = a.Id);
        Account single = new Account(Name = 'Single Household', Village__c = a.Id);
        Account far = new Account(Name = 'Far Household', Village__c = b.Id);
        insert new List<Account>{ family, single, far };
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact baby = member(family.Id, a.Id, 'Baby', Date.today().addDays(-90), me);
        Contact mother = member(family.Id, a.Id, 'Mother', Date.today().addYears(-25), me);
        Contact alone = member(single.Id, a.Id, 'Alone', Date.today().addYears(-50), me);
        Contact distant = member(far.Id, b.Id, 'Distant', Date.today().addYears(-55), me);
        insert new List<Contact>{ baby, mother, alone, distant };
        TriggerHandler.clearBypass('ContactTriggerHandler');
        insert new List<Care_Activity__c>{
            CareLoopPhase4TestData.activity(distant.Id, 'Routine Check-up', 'Distant check', Date.today().addDays(-40)),
            CareLoopPhase4TestData.activity(alone.Id, 'Routine Check-up', 'Alone check', Date.today().addDays(-35)),
            CareLoopPhase4TestData.activity(baby.Id, 'Immunization', 'OPV - dose 1', Date.today().addDays(-10)),
            CareLoopPhase4TestData.activity(baby.Id, 'Immunization', 'Penta - dose 1', Date.today().addDays(-10)),
            CareLoopPhase4TestData.activity(mother.Id, 'Antenatal Check-up', 'ANC 1', Date.today().addDays(4)),
            CareLoopPhase4TestData.activity(mother.Id, 'Antenatal Check-up', 'ANC 2', Date.today().addDays(60))
        };
        return me;
    }

    @IsTest
    static void bundlesHouseholdsAndBeatsTheDueDateList() {
        Id me = setUpWorld();
        NavigatorPlanner.Plan plan = NavigatorPlanner.plan(me, Date.today(), 2);

        Assert.areEqual(3, plan.candidateHouseholds);
        Assert.areEqual(2, plan.stops.size());
        Assert.areEqual('Family Household', plan.stops[0].householdName, 'most urgent household first');
        Assert.areEqual(3, plan.stops[0].gaps, 'two vaccines + one ANC within the look-ahead; ANC 2 is too far ahead');
        Assert.areEqual('Single Household', plan.stops[1].householdName, 'stays in the same village');
        Assert.isTrue(plan.stops[1].distanceFromPrevious == 0);
        Assert.areEqual(4, plan.gapsTargeted);
        Assert.areEqual(2, plan.baselineGaps, 'due-date order visits Distant and Alone, one gap each');
        Assert.isTrue(plan.baselineDistanceKm > 20, 'the due-date list walks to the far village: ' + plan.baselineDistanceKm);
        Assert.isTrue(plan.distanceKm == 0);
        Assert.isTrue(plan.stops[0].reasons[0].startsWith('+'), plan.stops[0].reasons[0]);
    }

    @IsTest
    static void emptyWhenNothingIsDue() {
        CareLoopTestFactory.useRealToday();
        NavigatorPlanner.Plan plan = NavigatorPlanner.plan(UserInfo.getUserId(), Date.today(), 8);
        Assert.areEqual(0, plan.stops.size());
        Assert.areEqual(0, plan.gapsTargeted);
        Assert.areEqual(NavigatorPlanner.DEFAULT_CAPACITY, NavigatorPlanner.capacity(), 'tests ignore the org setting');
    }

    @IsTest
    static void serviceSavesTracksAndProtectsProgress() {
        Id me = setUpWorld();
        Map<Id, Id> plans = NavigatorService.generate(new Set<Id>{ me }, Date.today());
        Id planId = plans.get(me);
        Visit_Plan__c saved = [SELECT Planned_Stops__c, Gaps_Targeted__c, Baseline_Gaps__c, Gap_Gain_Percent__c, OwnerId,
                                      (SELECT Id, Household__c, Status__c, Sequence__c FROM Stops__r ORDER BY Sequence__c)
                               FROM Visit_Plan__c WHERE Id = :planId];
        Assert.isTrue(saved.Planned_Stops__c == 8 || saved.Planned_Stops__c == 3, 'capacity from settings; 3 candidates');
        Assert.areEqual(me, saved.OwnerId);
        Assert.isTrue(saved.Gap_Gain_Percent__c != null);

        // A completed visit to the family + one vaccine given => stop Visited, 1 gap closed.
        Visit_Plan_Stop__c first = saved.Stops__r[0];
        Contact baby = [SELECT Id FROM Contact WHERE FirstName = 'Baby' LIMIT 1];
        insert CareLoopTestFactory.newVisit(baby.Id);
        Care_Activity__c opv = [SELECT Id FROM Care_Activity__c WHERE Name = 'OPV - dose 1'];
        update new Care_Activity__c(Id = opv.Id, Status__c = 'Completed', Completed_Date__c = Date.today());

        NavigatorController.PlanView view = NavigatorController.getPlan(null);
        Assert.areEqual(1, view.gapsClosed);
        Assert.areEqual(1, view.visited);
        Assert.areEqual('Visited', view.stops[0].status);
        Assert.isTrue(view.isMine);
        Assert.isFalse(view.stops[0].members.isEmpty());

        // Progress exists, so re-planning keeps the same plan and stops.
        NavigatorController.planMyDay();
        Assert.areEqual(saved.Stops__r.size(), [SELECT COUNT() FROM Visit_Plan_Stop__c WHERE Plan__c = :planId]);
        Assert.areEqual(1, [SELECT COUNT() FROM Visit_Plan__c]);

        // Skipping needs a reason.
        Visit_Plan_Stop__c second = saved.Stops__r[1];
        try {
            NavigatorController.updateStop(second.Id, 'Skipped', null);
            Assert.fail('A reason is required');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        view = NavigatorController.updateStop(second.Id, 'Skipped', 'Family travelling');
        Assert.areEqual('Skipped', view.stops[1].status);
        Assert.areEqual(1, NavigatorController.getTeamPlans().size());
    }

    @IsTest
    static void untouchedPlansAreRegenerated() {
        Id me = setUpWorld();
        Id first = NavigatorService.generate(new Set<Id>{ me }, Date.today()).get(me);
        Id second = NavigatorService.generate(new Set<Id>{ me }, Date.today()).get(me);
        Assert.areEqual(first, second, 'same plan record (unique key)');
        Assert.areEqual(1, [SELECT COUNT() FROM Visit_Plan__c]);
    }

    @IsTest
    static void morningJobPlansEveryWorkerWithCareDue() {
        Id me = setUpWorld();
        Test.startTest();
        Id cron = NavigatorNightlyJob.scheduleDaily();
        Assert.areEqual(cron, NavigatorNightlyJob.scheduleDaily());
        new NavigatorNightlyJob().execute(null);
        Test.stopTest();
        Assert.areEqual(1, [SELECT COUNT() FROM Visit_Plan__c WHERE Health_Worker__c = :me]);
        Assert.isTrue(NavigatorService.workersWithOpenCare(Date.today()).contains(me));
    }

    @IsTest
    static void visitedCannotBeSetByHand() {
        try {
            NavigatorService.setStopStatus(null, 'Visited', null);
            Assert.fail('Visited comes from the visit record');
        } catch (NavigatorService.NavigatorException e) {
            Assert.isTrue(e.getMessage().contains('automatically'));
        }
    }
}
