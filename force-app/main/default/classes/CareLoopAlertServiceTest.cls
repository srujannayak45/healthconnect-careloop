@IsTest
private class CareLoopAlertServiceTest {

    private static User insertDoctor() {
        User doctor;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            doctor = CareLoopPhase4TestData.newUser('doc');
            insert doctor;
            insert new PermissionSetAssignment(AssigneeId = doctor.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'CareLoop_Doctor'].Id);
        }
        return doctor;
    }

    @IsTest
    static void redFlagVisitsPublishEventsAndOneBell() {
        CareLoopTestFactory.useRealToday();
        CareRules.careRules = CareLoopTestFactory.redFlagRules();
        User doctor = insertDoctor();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-60), 'English', 'Portal Inbox', true);
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer i = 0; i < 3; i++) {
            Health_Visit__c v = CareLoopTestFactory.newVisit(p.Id);
            v.BP_Systolic__c = 185;
            v.BP_Diastolic__c = 95;
            visits.add(v);
        }

        Test.startTest();
        insert visits;
        Assert.areEqual(3, CareLoopAlertService.lastPublished.size(), 'one live event per visit');
        Assert.areEqual(CareLoopAlertService.ALERT_RED_FLAG, CareLoopAlertService.lastPublished[0].Alert_Type__c);
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.isTrue(CareLoopAlertService.doctors().contains(doctor.Id));
        Assert.areEqual(1, CareLoopAlertService.bellsSent, 'the subscriber sends one bell for the whole batch');
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c]);
    }

    @IsTest
    static void reviewRequestedOnUpdateAlertsOnlyOnce() {
        CareLoopTestFactory.useRealToday();
        CareRules.careRules = CareLoopTestFactory.redFlagRules();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-60), 'English', 'Portal Inbox', true);
        Health_Visit__c v = CareLoopTestFactory.newVisit(p.Id);
        insert v;
        Assert.areEqual(0, CareLoopAlertService.lastPublished.size(), 'a normal visit does not alert');

        v.Needs_Doctor_Review__c = true;
        update v;
        Assert.areEqual(1, CareLoopAlertService.lastPublished.size());
        Assert.areEqual(CareLoopAlertService.ALERT_REVIEW, CareLoopAlertService.lastPublished[0].Alert_Type__c);

        CareLoopAlertService.lastPublished = new List<CareLoop_Alert__e>();
        v.Observations__c = 'Edited notes';
        update v;
        Assert.areEqual(0, CareLoopAlertService.lastPublished.size(), 'already pending: no second alert');
    }

    @IsTest
    static void patientHelpAlertsTheHealthWorker() {
        CareLoopTestFactory.useRealToday();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'Portal Inbox', true);
        Care_Activity__c a = CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Check', Date.today().addDays(1));
        insert a;
        Test.startTest();
        CareLoopAlertService.alertPatientNeedsHelp(a.Id, p.Id, 'Cannot travel');
        Test.getEventBus().deliver();
        Test.stopTest();
        Assert.areEqual(CareLoopAlertService.ALERT_PATIENT_HELP, CareLoopAlertService.lastPublished[0].Alert_Type__c);
        Assert.areEqual(1, CareLoopAlertService.bellsSent);
    }

    @IsTest
    static void notifyIgnoresEmptyInput() {
        Assert.isFalse(CareLoopAlertService.notify(new Set<Id>(), 'x', 'y', UserInfo.getUserId()));
        Assert.isFalse(CareLoopAlertService.notify(new Set<Id>{ UserInfo.getUserId() }, 'x', 'y', null));
        CareLoopAlertSubscriber.handle(new List<CareLoop_Alert__e>{ new CareLoop_Alert__e(Alert_Type__c = 'RED_FLAG') });
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c], 'an event without a record is ignored');
    }
}
