@IsTest
private class CareSweepBatchTest {

    private static Map<String, Care_Activity__c> byName(Id patientId) {
        Map<String, Care_Activity__c> result = new Map<String, Care_Activity__c>();
        for (Care_Activity__c a : [SELECT Name, Status__c, Days_Overdue__c, Escalation_Level__c, Reminders_Sent__c,
                                          Next_Action__c, Last_Escalated_On__c
                                   FROM Care_Activity__c WHERE Patient__c = :patientId]) {
            result.put(a.Name, a);
        }
        return result;
    }

    @IsTest
    static void climbsTheLadderOnceAndGroupsReminders() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.useLadder();
        List<User> staff = CareLoopPhase4TestData.insertWorkerAndSupervisor();
        User worker = staff[0];
        User supervisor = staff[1];
        Contact p = CareLoopPhase4TestData.insertPatient(worker.Id, Date.today().addYears(-30), 'English', 'Portal Inbox', true);
        Date today = Date.today();
        insert new List<Care_Activity__c>{
            CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Upcoming check', today.addDays(2)),
            CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Five days late', today.addDays(-5)),
            CareLoopPhase4TestData.activity(p.Id, 'Follow-up', 'Fifteen days late', today.addDays(-15)),
            CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Far future', today.addDays(40))
        };

        Test.startTest();
        new CareSweepBatch(false).run(new Set<Id>{ p.Id });
        Test.stopTest();

        Map<String, Care_Activity__c> acts = byName(p.Id);
        Assert.isTrue(acts.get('Upcoming check').Escalation_Level__c == 1);
        Assert.isTrue(acts.get('Five days late').Escalation_Level__c == 2);
        Assert.isTrue(acts.get('Fifteen days late').Escalation_Level__c == 3);
        Assert.isTrue(acts.get('Far future').Escalation_Level__c == 0);
        Assert.areEqual(today, acts.get('Fifteen days late').Last_Escalated_On__c);
        Assert.isTrue(acts.get('Upcoming check').Reminders_Sent__c == 1);

        List<Notification__c> notes = [SELECT Patient__c, Status__c, Channel__c, Subject__c, Message__c, Notification_Key__c,
                                              Care_Activity__c, Escalation_Level__c
                                       FROM Notification__c WHERE Patient__c = :p.Id ORDER BY Notification_Key__c];
        Assert.areEqual(2, notes.size(), 'one upcoming and one combined overdue reminder');
        for (Notification__c n : notes) {
            Assert.areEqual('Sent', n.Status__c, 'Portal Inbox reminders are delivered at once');
        }
        Notification__c overdue = notes[0].Notification_Key__c.endsWith('REMINDER_OVERDUE') ? notes[0] : notes[1];
        Assert.isTrue(overdue.Message__c.contains('Fifteen days late') && overdue.Message__c.contains('Five days late'),
            overdue.Message__c);

        Assert.areEqual(2, [SELECT COUNT() FROM Task WHERE OwnerId = :worker.Id], 'level 2 task for each overdue item');
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE OwnerId = :supervisor.Id AND Priority = 'High'], 'level 3 escalation');

        // Running again the same day changes nothing.
        new CareSweepBatch(false).run(new Set<Id>{ p.Id });
        Assert.areEqual(2, [SELECT COUNT() FROM Notification__c WHERE Patient__c = :p.Id]);
        Assert.areEqual(3, [SELECT COUNT() FROM Task WHERE WhoId = :p.Id]);
    }

    @IsTest
    static void movesStatusesForwardWithTheClock() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.useLadder();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-40), 'English', 'Portal Inbox', true);
        Care_Activity__c a = CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Check', Date.today().addDays(10));
        insert a;
        Assert.areEqual('Scheduled', [SELECT Status__c FROM Care_Activity__c WHERE Id = :a.Id].Status__c);

        CareLoopClock.testToday = Date.today().addDays(8);
        new CareSweepBatch(false).run(new Set<Id>{ p.Id });
        Assert.areEqual('Due', [SELECT Status__c FROM Care_Activity__c WHERE Id = :a.Id].Status__c);

        CareLoopClock.testToday = Date.today().addDays(12);
        new CareSweepBatch(false).run(new Set<Id>{ p.Id });
        Care_Activity__c after = [SELECT Status__c, Days_Overdue__c FROM Care_Activity__c WHERE Id = :a.Id];
        Assert.areEqual('Overdue', after.Status__c);
        Assert.isTrue(after.Days_Overdue__c == 2);
    }

    @IsTest
    static void childRemindersGoToTheCaregiverInHerLanguage() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.useLadder();
        Contact mother = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-25), 'Telugu', 'Portal Inbox', true);
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact baby = CareLoopTestFactory.newPatient(mother.AccountId, null, Date.today().addDays(-60));
        baby.FirstName = 'Ananya';
        baby.MobilePhone = null;
        baby.Caregiver__c = mother.Id;
        baby.Reminder_Consent__c = false;
        insert baby;
        TriggerHandler.clearBypass('ContactTriggerHandler');
        insert CareLoopPhase4TestData.activity(baby.Id, 'Immunization', 'BCG - dose 1', Date.today().addDays(-4));

        new CareSweepBatch(false).run(new Set<Id>{ baby.Id });

        List<Notification__c> notes = [SELECT Patient__c, Language__c, Message__c, Status__c FROM Notification__c];
        Assert.areEqual(1, notes.size());
        Assert.areEqual(mother.Id, notes[0].Patient__c, 'the caregiver receives the reminder');
        Assert.areEqual('Telugu', notes[0].Language__c);
        Assert.areEqual('Sent', notes[0].Status__c, 'the caregiver consented, even though the baby record has no consent');
        Assert.isTrue(notes[0].Message__c.contains('BCG - dose 1 (Ananya)'), notes[0].Message__c);
    }

    @IsTest
    static void respectsConsentPauseAndReminderLimit() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.useLadder();
        Contact noConsent = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'SMS', false);
        Contact paused = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'SMS', true);
        Contact limited = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'Hindi', 'SMS', true);
        Care_Activity__c a1 = CareLoopPhase4TestData.activity(noConsent.Id, 'Routine Check-up', 'Check A', Date.today().addDays(1));
        Care_Activity__c a2 = CareLoopPhase4TestData.activity(paused.Id, 'Routine Check-up', 'Check B', Date.today().addDays(-20));
        a2.Escalation_Paused_Until__c = Date.today().addDays(5);
        Care_Activity__c a3 = CareLoopPhase4TestData.activity(limited.Id, 'Routine Check-up', 'Check C', Date.today().addDays(-4));
        a3.Reminders_Sent__c = 3;
        insert new List<Care_Activity__c>{ a1, a2, a3 };

        new CareSweepBatch(false).run(new Set<Id>{ noConsent.Id, paused.Id, limited.Id });

        Notification__c skipped = [SELECT Status__c, Skip_Reason__c FROM Notification__c WHERE Patient__c = :noConsent.Id];
        Assert.areEqual('Skipped', skipped.Status__c);
        Assert.areEqual('No reminder consent recorded', skipped.Skip_Reason__c);
        Assert.areEqual(0, [SELECT COUNT() FROM Notification__c WHERE Patient__c = :paused.Id], 'paused: nothing');
        Assert.isTrue([SELECT Escalation_Level__c FROM Care_Activity__c WHERE Id = :a2.Id].Escalation_Level__c == 0);
        Assert.areEqual(0, [SELECT COUNT() FROM Notification__c WHERE Patient__c = :limited.Id], 'reminder limit reached');
        Assert.areEqual(1, [SELECT COUNT() FROM Task WHERE WhatId = :a3.Id], 'the worker still gets the task');
    }

    @IsTest
    static void smsWithoutMobileIsSkippedAndQueuedOtherwise() {
        Contact noMobile = new Contact(FirstName = 'A', LastName = 'B', Reminder_Consent__c = true);
        Assert.areEqual('SMS preferred but no mobile number', EscalationService.skipReason(noMobile, 'SMS'));
        Assert.areEqual('Email preferred but no email address', EscalationService.skipReason(noMobile, 'Email'));
        noMobile.MobilePhone = '9876543210';
        Assert.isNull(EscalationService.skipReason(noMobile, 'SMS'));
    }

    @IsTest
    static void batchRunsEndToEnd() {
        CareLoopTestFactory.useRealToday();
        CareLoopPhase4TestData.useLadder();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-45), 'English', 'Portal Inbox', true);
        insert CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Late check', Date.today().addDays(-6));
        CareSweepBatch job = new CareSweepBatch(true);
        Test.startTest();
        Database.executeBatch(job, CareSweepBatch.DEFAULT_SCOPE);
        Test.stopTest();
        Care_Activity__c a = [SELECT Escalation_Level__c FROM Care_Activity__c WHERE Patient__c = :p.Id];
        Assert.isTrue(a.Escalation_Level__c == 2);
        Assert.areEqual(1, [SELECT COUNT() FROM Notification__c WHERE Patient__c = :p.Id]);
    }
}
