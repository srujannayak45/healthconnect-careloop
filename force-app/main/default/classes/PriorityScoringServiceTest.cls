@IsTest
private class PriorityScoringServiceTest {

    private static Care_Activity__c open(String type, String name, String status, Date due) {
        return new Care_Activity__c(Name = name, Activity_Type__c = type, Status__c = status, Due_Date__c = due,
            Escalation_Level__c = 0);
    }

    @IsTest
    static void infantWithOverdueVaccinesIsHighWithReasons() {
        CareLoopPhase4TestData.usePriorityRules();
        Date today = Date.newInstance(2026, 11, 9);
        Contact baby = new Contact(FirstName = 'Ananya', LastName = 'Rao', Birthdate = today.addDays(-75));
        List<Care_Activity__c> items = new List<Care_Activity__c>{
            open('Immunization', 'BCG - dose 1', 'Overdue', today.addDays(-20)),
            open('Immunization', 'OPV - dose 1', 'Overdue', today.addDays(-5)),
            open('Immunization', 'Penta - dose 2', 'Scheduled', today.addDays(20))
        };
        PriorityScoringService.PatientScore s = PriorityScoringService.evaluate(baby, items, false, false, today);

        Assert.areEqual(9, s.score, 'two overdue doses (2 x 4) + infant (1)');
        Assert.areEqual('High', s.level);
        Assert.areEqual(2, s.overdue);
        Assert.areEqual(2, s.openGaps, 'Scheduled items are not gaps yet');
        Assert.areEqual('OVERDUE_IMMUNIZATION', s.reasons[0].ruleKey, 'largest reason first');
        Assert.areEqual('2 overdue vaccine dose(s)', s.reasons[0].text);
        Assert.isTrue(s.nextBestAction.contains('BCG - dose 1'), s.nextBestAction);
        Assert.isTrue(s.explanation().startsWith('+8  2 overdue vaccine dose(s)'), s.explanation());
    }

    @IsTest
    static void countingRulesAreCappedAndLongOverdueAdds() {
        CareLoopPhase4TestData.usePriorityRules();
        Date today = Date.newInstance(2026, 11, 9);
        Contact adult = new Contact(FirstName = 'Venkat', LastName = 'Rao', Birthdate = today.addYears(-62));
        List<Care_Activity__c> items = new List<Care_Activity__c>();
        for (Integer i = 1; i <= 5; i++) {
            items.add(open('Routine Check-up', 'BP check ' + i, 'Overdue', today.addDays(-40 - i)));
        }
        PriorityScoringService.PatientScore s = PriorityScoringService.evaluate(adult, items, false, false, today);
        // 3 items capped x 3 points + 3 capped x 2 points (more than 30 days) = 15
        Assert.areEqual(15, s.score);
        Assert.areEqual('Critical', s.level);
        Assert.areEqual(5, s.overdue);
    }

    @IsTest
    static void redFlagAndHelpRequestDriveTheNextBestAction() {
        CareLoopPhase4TestData.usePriorityRules();
        Date today = Date.newInstance(2026, 11, 9);
        Contact p = new Contact(FirstName = 'Kavya', LastName = 'Rao', Birthdate = today.addYears(-26), Is_Pregnant__c = true);
        Care_Activity__c anc = open('Antenatal Check-up', 'ANC 2', 'Due', today.addDays(2));
        anc.Patient_Response__c = 'Need Help';
        PriorityScoringService.PatientScore withFlag = PriorityScoringService.evaluate(p, new List<Care_Activity__c>{ anc }, true, true, today);
        Assert.areEqual(6 + 4 + 3 + 2, withFlag.score, 'red flag + pending review + needs help + pregnancy');
        Assert.isTrue(withFlag.nextBestAction.startsWith('Red-flag visit'), withFlag.nextBestAction);

        PriorityScoringService.PatientScore helpOnly = PriorityScoringService.evaluate(p, new List<Care_Activity__c>{ anc }, false, false, today);
        Assert.isTrue(helpOnly.nextBestAction.startsWith('Call the patient back'), helpOnly.nextBestAction);
    }

    @IsTest
    static void patientWithoutGapsIsLow() {
        CareLoopPhase4TestData.usePriorityRules();
        Date today = Date.newInstance(2026, 11, 9);
        Contact p = new Contact(FirstName = 'Asha', LastName = 'K', Birthdate = today.addYears(-40),
            Last_Successful_Contact__c = today.addDays(-10));
        PriorityScoringService.PatientScore s = PriorityScoringService.evaluate(p, new List<Care_Activity__c>(), false, false, today);
        Assert.areEqual(0, s.score);
        Assert.areEqual('Low', s.level);
        Assert.areEqual('No action needed today', s.nextBestAction);
        Assert.areEqual('No open care gaps.', s.explanation());
    }

    @IsTest
    static void noRecentContactAndFailedAttemptsCount() {
        CareLoopPhase4TestData.usePriorityRules();
        Date today = Date.newInstance(2026, 11, 9);
        Contact p = new Contact(FirstName = 'Ravi', LastName = 'K', Birthdate = today.addYears(-50),
            Last_Successful_Contact__c = today.addDays(-90), Failed_Outreach_Attempts__c = 2);
        PriorityScoringService.PatientScore s = PriorityScoringService.evaluate(p, new List<Care_Activity__c>(), false, false, today);
        Assert.areEqual(3 + 4, s.score, 'no contact for 90 days (3) + 2 failed attempts (2 x 2)');
        Assert.isTrue(s.explanation().contains('No successful contact for 90 days'), s.explanation());
    }

    @IsTest
    static void scoresStoredPatientsFromTheDatabase() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.usePriorityRules();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-35), 'English', 'Portal Inbox', true);
        insert new List<Care_Activity__c>{
            CareLoopPhase4TestData.activity(p.Id, 'Follow-up', 'Follow-up after BP review', Date.today().addDays(-4)),
            CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Annual screening', Date.today().addDays(30))
        };
        Health_Visit__c visit = CareLoopTestFactory.newVisit(p.Id);
        visit.BP_Systolic__c = 190;
        visit.BP_Diastolic__c = 100;
        insert visit;

        Test.startTest();
        PriorityScoringService.PatientScore s = PriorityScoringService.score(new Set<Id>{ p.Id }).get(p.Id);
        Integer failed = PatientPriorityBatch.store(new Set<Id>{ p.Id });
        Test.stopTest();

        Assert.areEqual(6 + 5 + 4, s.score, 'red flag + overdue follow-up + pending review');
        Assert.areEqual('Critical', s.level);
        Assert.areEqual(0, failed);
        Contact stored = [SELECT Priority_Score__c, Priority_Level__c, Priority_Explanation__c, Next_Best_Action__c,
                                 Open_Care_Gaps__c, Overdue_Activities__c, Priority_Calculated_On__c
                          FROM Contact WHERE Id = :p.Id];
        Assert.isTrue(stored.Priority_Score__c == 15);
        Assert.areEqual('Critical', stored.Priority_Level__c);
        Assert.isTrue(stored.Open_Care_Gaps__c == 1);
        Assert.isTrue(stored.Overdue_Activities__c == 1);
        Assert.isNotNull(stored.Priority_Calculated_On__c);
        Assert.isTrue(stored.Priority_Explanation__c.contains('Red-flag visit'), stored.Priority_Explanation__c);
    }

    @IsTest
    static void levelThresholds() {
        CareLoopPhase4TestData.usePriorityRules();
        Assert.areEqual('Low', PriorityScoringService.levelFor(3));
        Assert.areEqual('Medium', PriorityScoringService.levelFor(4));
        Assert.areEqual('High', PriorityScoringService.levelFor(9));
        Assert.areEqual('Critical', PriorityScoringService.levelFor(15));
        Assert.isTrue(PriorityScoringService.score(new Set<Id>()).isEmpty());
    }
}
