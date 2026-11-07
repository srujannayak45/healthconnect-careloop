@IsTest
private class PatientPortalServiceTest {

    private static Contact mother;
    private static Contact baby;
    private static Contact stranger;

    private static void setUpFamily() {
        CareLoopTestFactory.useRealToday();
        mother = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-26), 'Telugu', 'Portal Inbox', true);
        TriggerHandler.bypass('ContactTriggerHandler');
        baby = CareLoopTestFactory.newPatient(mother.AccountId, null, Date.today().addDays(-70));
        baby.FirstName = 'Ananya';
        baby.MobilePhone = null;
        baby.Caregiver__c = mother.Id;
        insert baby;
        TriggerHandler.clearBypass('ContactTriggerHandler');
        stranger = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-40), 'English', 'Portal Inbox', true);
    }

    @IsTest
    static void homeShowsOwnAndDependantCareOnly() {
        setUpFamily();
        insert new List<Care_Activity__c>{
            CareLoopPhase4TestData.activity(baby.Id, 'Immunization', 'BCG - dose 1', Date.today().addDays(-3)),
            CareLoopPhase4TestData.activity(mother.Id, 'Antenatal Check-up', 'ANC 2', Date.today().addDays(5)),
            CareLoopPhase4TestData.activity(stranger.Id, 'Routine Check-up', 'Stranger check', Date.today().addDays(1))
        };
        insert new Notification__c(Patient__c = mother.Id, Subject__c = 'Reminder', Message__c = 'Namaste', Status__c = 'Sent',
            Channel__c = 'Portal Inbox', Notification_Key__c = 'test-key-1');
        insert new Notification__c(Patient__c = stranger.Id, Subject__c = 'Other', Message__c = 'Other', Status__c = 'Sent',
            Channel__c = 'Portal Inbox', Notification_Key__c = 'test-key-2');

        PatientPortalService.contactOverride = mother.Id;
        PatientPortalService.Home home = PatientPortalController.getHome();

        Assert.areEqual(2, home.people.size(), 'mother and her baby');
        Assert.areEqual('You', home.people[0].relation);
        Integer items = 0;
        for (PatientPortalService.Person person : home.people) {
            for (PatientPortalService.CareItem item : person.care) {
                items++;
                Assert.areNotEqual('Stranger check', item.name);
            }
        }
        Assert.areEqual(2, items);
        Assert.areEqual(1, home.inbox.size());
        Assert.areEqual(1, home.unread);
    }

    @IsTest
    static void needHelpCreatesTaskAndCannotAnswerOthers() {
        setUpFamily();
        Care_Activity__c bcg = CareLoopPhase4TestData.activity(baby.Id, 'Immunization', 'BCG - dose 1', Date.today().addDays(-3));
        Care_Activity__c other = CareLoopPhase4TestData.activity(stranger.Id, 'Routine Check-up', 'Stranger check', Date.today().addDays(1));
        insert new List<Care_Activity__c>{ bcg, other };
        PatientPortalService.contactOverride = mother.Id;

        PatientPortalController.respond(bcg.Id, 'Need Help', null, 'Baby has fever, cannot travel');
        Care_Activity__c answered = [SELECT Patient_Response__c, Patient_Response_Date__c FROM Care_Activity__c WHERE Id = :bcg.Id];
        Assert.areEqual('Need Help', answered.Patient_Response__c);
        Assert.areEqual(Date.today(), answered.Patient_Response_Date__c);
        Task t = [SELECT Priority, Subject, Description FROM Task WHERE WhatId = :bcg.Id];
        Assert.areEqual('High', t.Priority);
        Assert.isTrue(t.Description.contains('fever'));

        try {
            PatientPortalController.respond(other.Id, 'Will Attend', null, null);
            Assert.fail('A patient must not answer another patient\'s care');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('not yours'), e.getMessage());
        }
        Assert.isNull([SELECT Patient_Response__c FROM Care_Activity__c WHERE Id = :other.Id].Patient_Response__c);
    }

    @IsTest
    static void proposedDateIsValidatedAndTasked() {
        setUpFamily();
        Care_Activity__c anc = CareLoopPhase4TestData.activity(mother.Id, 'Antenatal Check-up', 'ANC 2', Date.today().addDays(2));
        insert anc;
        PatientPortalService.contactOverride = mother.Id;
        try {
            PatientPortalController.respond(anc.Id, 'Will Attend', Date.today().addDays(200), null);
            Assert.fail('Dates far in the future are rejected');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('90 days'));
        }
        PatientPortalController.respond(anc.Id, 'Will Attend', Date.today().addDays(6), null);
        Assert.areEqual(Date.today().addDays(6), [SELECT Proposed_Date__c FROM Care_Activity__c WHERE Id = :anc.Id].Proposed_Date__c);
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :anc.Id]);
    }

    @IsTest
    static void messagesAndConsent() {
        setUpFamily();
        Notification__c mine = new Notification__c(Patient__c = mother.Id, Subject__c = 'S', Message__c = 'M', Status__c = 'Sent',
            Channel__c = 'Portal Inbox', Notification_Key__c = 'test-key-3');
        Notification__c theirs = new Notification__c(Patient__c = stranger.Id, Subject__c = 'S', Message__c = 'M', Status__c = 'Sent',
            Channel__c = 'Portal Inbox', Notification_Key__c = 'test-key-4');
        insert new List<Notification__c>{ mine, theirs };
        PatientPortalService.contactOverride = mother.Id;

        PatientPortalService.Home home = PatientPortalController.markRead(mine.Id);
        Assert.areEqual(0, home.unread);
        Assert.areEqual('Read', [SELECT Status__c FROM Notification__c WHERE Id = :mine.Id].Status__c);
        try {
            PatientPortalController.markRead(theirs.Id);
            Assert.fail('Cannot read another patient\'s message');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('not yours'));
        }

        home = PatientPortalController.setReminderConsent(false);
        Assert.isFalse(home.reminderConsent);
        Consent_Event__c e = [SELECT Channel__c, Action__c FROM Consent_Event__c WHERE Patient__c = :mother.Id];
        Assert.areEqual('Patient Portal', e.Channel__c);
        Assert.areEqual('Withdrawn', e.Action__c);
    }

    @IsTest
    static void nonPortalUsersAreTurnedAway() {
        try {
            PatientPortalController.getHome();
            Assert.fail('An internal user has no ContactId');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('registered patients'), e.getMessage());
        }
    }
}
