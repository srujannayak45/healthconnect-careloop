@IsTest
private class PatientPriorityBatchTest {

    @IsTest
    static void batchStoresPriorityOnPatients() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.usePriorityRules();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addDays(-100), 'English', 'Portal Inbox', true);
        insert CareLoopPhase4TestData.activity(p.Id, 'Immunization', 'OPV - dose 1', Date.today().addDays(-10));

        Test.startTest();
        Database.executeBatch(new PatientPriorityBatch(), PatientPriorityBatch.DEFAULT_SCOPE);
        Test.stopTest();

        Contact stored = [SELECT Priority_Score__c, Priority_Level__c, Next_Best_Action__c FROM Contact WHERE Id = :p.Id];
        Assert.isTrue(stored.Priority_Score__c == 5, 'overdue dose (4) + infant (1)');
        Assert.areEqual('Medium', stored.Priority_Level__c);
        Assert.isTrue(stored.Next_Best_Action__c.contains('OPV - dose 1'));
    }

    @IsTest
    static void nightlyJobSchedulesOnceAndRuns() {
        CareLoopTestFactory.useRealToday();
        Test.startTest();
        Id first = CareLoopNightlyJob.scheduleDaily();
        Id second = CareLoopNightlyJob.scheduleDaily();
        Test.stopTest();
        Assert.areEqual(first, second, 'scheduling twice keeps one job');
        Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'CareSweepBatch']);
        Assert.areEqual(1, [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = :CareLoopNightlyJob.JOB_NAME]);
    }
}
