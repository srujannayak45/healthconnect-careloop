@IsTest
private class Phase4ControllersTest {

    @IsTest
    static void doctorQueueListsRedFlagsFirst() {
        CareLoopTestFactory.useRealToday();
        CareRules.careRules = CareLoopTestFactory.redFlagRules();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-55), 'English', 'Portal Inbox', true);
        Health_Visit__c asked = CareLoopTestFactory.newVisit(p.Id);
        asked.Needs_Doctor_Review__c = true;
        Health_Visit__c red = CareLoopTestFactory.newVisit(p.Id);
        red.BP_Systolic__c = 200;
        red.BP_Diastolic__c = 120;
        red.SpO2__c = 90;
        insert new List<Health_Visit__c>{ asked, red };

        List<DoctorReviewController.ReviewItem> items = DoctorReviewController.getPendingReviews();
        Assert.areEqual(2, items.size());
        Assert.isTrue(items[0].redFlag);
        Assert.isTrue(items[0].vitals.contains('BP 200/120'), items[0].vitals);
        Assert.areEqual('Health worker requested a review', items[1].reason);
    }

    @IsTest
    static void priorityCardShowsLiveScoreAndSaves() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.usePriorityRules();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'Portal Inbox', true);
        insert CareLoopPhase4TestData.activity(p.Id, 'Follow-up', 'Follow-up', Date.today().addDays(-2));

        PatientPriorityController.PriorityView before = PatientPriorityController.getPriority(p.Id);
        Assert.areEqual(5, before.live.score);
        Assert.isNull(before.storedScore);
        PatientPriorityController.PriorityView after = PatientPriorityController.saveNow(p.Id);
        Assert.isTrue(after.storedScore == 5);
        Assert.areEqual('Medium', after.storedLevel);
    }

    @IsTest
    static void priorityCardRejectsInvisiblePatients() {
        Contact gone = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'Portal Inbox', true);
        Id goneId = gone.Id;
        delete gone;
        try {
            PatientPriorityController.getPriority(goneId);
            Assert.fail('Expected an AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
    }
}
