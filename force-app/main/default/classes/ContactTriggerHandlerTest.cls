@IsTest
private class ContactTriggerHandlerTest {

    @IsTest
    static void newPatientIsAssignedToTheVillageHealthWorker() {
        List<User> others = [
            SELECT Id FROM User
            WHERE IsActive = true AND UserType = 'Standard' AND Id != :UserInfo.getUserId()
            LIMIT 1
        ];
        Id worker = others.isEmpty() ? UserInfo.getUserId() : others[0].Id;
        Village__c village = CareLoopTestFactory.insertVillage(worker);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);
        Contact patient = CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addYears(-35));
        patient.Assigned_Health_Worker__c = null;

        insert patient;

        Assert.areEqual(worker, [SELECT Assigned_Health_Worker__c FROM Contact WHERE Id = :patient.Id].Assigned_Health_Worker__c);
    }

    @IsTest
    static void villageWithoutWorkerFallsBackToTheRegisteringUser() {
        Village__c village = CareLoopTestFactory.insertVillage(null);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);
        Contact patient = CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addYears(-35));
        patient.Assigned_Health_Worker__c = null;

        insert patient;

        Assert.areEqual(UserInfo.getUserId(), [SELECT Assigned_Health_Worker__c FROM Contact WHERE Id = :patient.Id].Assigned_Health_Worker__c);
    }

    @IsTest
    static void explicitAssignmentIsKept() {
        List<User> others = [
            SELECT Id FROM User
            WHERE IsActive = true AND UserType = 'Standard' AND Id != :UserInfo.getUserId()
            LIMIT 1
        ];
        Id chosen = others.isEmpty() ? UserInfo.getUserId() : others[0].Id;
        Village__c village = CareLoopTestFactory.insertVillage(null);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);
        Contact patient = CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addYears(-35));
        patient.Assigned_Health_Worker__c = chosen;

        insert patient;

        Assert.areEqual(chosen, [SELECT Assigned_Health_Worker__c FROM Contact WHERE Id = :patient.Id].Assigned_Health_Worker__c);
    }

    @IsTest
    static void onlyEligibilityChangesQueueNewCare() {
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact patient = CareLoopTestFactory.insertPatient(Date.today().addYears(-25));
        TriggerHandler.clearBypass('ContactTriggerHandler');

        patient.MobilePhone = '9876543210';
        update patient;
        Assert.areEqual(0, Limits.getQueueableJobs(), 'A phone change does not change eligibility');

        patient.Is_Pregnant__c = true;
        update patient;
        Assert.areEqual(1, Limits.getQueueableJobs(), 'Recording a pregnancy queues schedule generation');
    }

    @IsTest
    static void recordingAPregnancyAddsAntenatalCare() {
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact patient = CareLoopTestFactory.insertPatient(Date.today().addYears(-25));
        TriggerHandler.clearBypass('ContactTriggerHandler');
        Integer expected = CareLoopTestFactory.configuredOccurrences('Pregnant');

        Test.startTest();
        patient.Is_Pregnant__c = true;
        update patient;
        Test.stopTest();

        Assert.areEqual(expected, [SELECT COUNT() FROM Care_Activity__c WHERE Patient__c = :patient.Id AND Activity_Type__c = 'Antenatal Check-up'],
            'Antenatal check-ups from Care Schedule metadata');
    }
}
