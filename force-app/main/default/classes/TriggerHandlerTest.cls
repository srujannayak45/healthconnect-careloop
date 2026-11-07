@IsTest
private class TriggerHandlerTest {

    @IsTest
    static void handlerNameIsTheClassName() {
        Assert.areEqual('ContactTriggerHandler', new ContactTriggerHandler().getHandlerName());
        Assert.areEqual('TriggerHandler', new TriggerHandler().getHandlerName());
    }

    @IsTest
    static void runOutsideATriggerDoesNothing() {
        new TriggerHandler().run();
        Assert.areEqual(0, Limits.getDmlStatements(), 'No work is done outside a trigger');
    }

    @IsTest
    static void bypassSwitchesAHandlerOffAndOn() {
        Village__c village = CareLoopTestFactory.insertVillage(null);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);

        TriggerHandler.bypass('ContactTriggerHandler');
        Assert.isTrue(TriggerHandler.isBypassed('ContactTriggerHandler'));
        Contact first = CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addYears(-40));
        first.Assigned_Health_Worker__c = null;
        insert first;
        Assert.isNull([SELECT Assigned_Health_Worker__c FROM Contact WHERE Id = :first.Id].Assigned_Health_Worker__c,
            'Bypassed handler did not assign a worker');
        Assert.areEqual(0, Limits.getQueueableJobs(), 'Bypassed handler queued no work');

        TriggerHandler.clearBypass('ContactTriggerHandler');
        Assert.isFalse(TriggerHandler.isBypassed('ContactTriggerHandler'));
        Contact second = CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addYears(-40));
        second.Assigned_Health_Worker__c = null;
        insert second;
        Assert.areEqual(UserInfo.getUserId(),
            [SELECT Assigned_Health_Worker__c FROM Contact WHERE Id = :second.Id].Assigned_Health_Worker__c,
            'Active handler assigned the registering user');
    }
}
