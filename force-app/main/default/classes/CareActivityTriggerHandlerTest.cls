@IsTest
private class CareActivityTriggerHandlerTest {

    private static Contact setUpPatient() {
        CareLoopTestFactory.useRealToday();
        TriggerHandler.bypass('ContactTriggerHandler');
        return CareLoopTestFactory.insertPatient(Date.today().addYears(-40));
    }

    private static Care_Activity__c reload(Id activityId) {
        return [
            SELECT Status__c, Days_Overdue__c, Source__c, Assigned_To__c, Escalation_Level__c, Reminders_Sent__c,
                   Next_Action__c, Escalation_Paused_Until__c
            FROM Care_Activity__c WHERE Id = :activityId
        ];
    }

    @IsTest
    static void newActivitiesTakeTheirStatusFromTheDueDate() {
        Contact patient = setUpPatient();
        Integer window = CareRules.dueWindowDays();
        Care_Activity__c overdue = CareLoopTestFactory.newActivity(patient.Id, Date.today().addDays(-5));
        Care_Activity__c due = CareLoopTestFactory.newActivity(patient.Id, Date.today());
        Care_Activity__c later = CareLoopTestFactory.newActivity(patient.Id, Date.today().addDays(window + 10));

        insert new List<Care_Activity__c>{ overdue, due, later };

        Care_Activity__c savedOverdue = reload(overdue.Id);
        Assert.areEqual('Overdue', savedOverdue.Status__c);
        Assert.isTrue(savedOverdue.Days_Overdue__c == 5);
        Assert.areEqual('Manual', savedOverdue.Source__c);
        Assert.areEqual(UserInfo.getUserId(), savedOverdue.Assigned_To__c, 'Assigned to the patient\'s health worker');
        Assert.isTrue(savedOverdue.Escalation_Level__c == 0);
        Assert.isTrue(savedOverdue.Reminders_Sent__c == 0);
        Assert.areEqual('Due', reload(due.Id).Status__c);
        Assert.areEqual('Scheduled', reload(later.Id).Status__c);
        Assert.isTrue(reload(later.Id).Days_Overdue__c == 0);
    }

    @IsTest
    static void completingAnActivityResetsEscalationAndClosesItsTasks() {
        Contact patient = setUpPatient();
        Care_Activity__c activity = CareLoopTestFactory.newActivity(patient.Id, Date.today().addDays(-10));
        insert activity;
        update new Care_Activity__c(Id = activity.Id, Next_Action__c = 'Visit the household',
            Escalation_Paused_Until__c = Date.today().addDays(2));
        Task followUp = new Task(WhatId = activity.Id, Subject = 'Follow up overdue care', Status = 'Not Started',
            OwnerId = UserInfo.getUserId(), ActivityDate = Date.today());
        insert followUp;

        Test.startTest();
        update new Care_Activity__c(Id = activity.Id, Status__c = 'Completed', Completed_Date__c = Date.today());
        Test.stopTest();

        Care_Activity__c saved = reload(activity.Id);
        Assert.areEqual('Completed', saved.Status__c);
        Assert.isTrue(saved.Days_Overdue__c == 0);
        Assert.isNull(saved.Next_Action__c);
        Assert.isNull(saved.Escalation_Paused_Until__c);
        Assert.isTrue([SELECT IsClosed FROM Task WHERE Id = :followUp.Id].IsClosed, 'Open follow-up task is closed');
    }

    @IsTest
    static void reschedulingRecalculatesTheStatus() {
        Contact patient = setUpPatient();
        Care_Activity__c activity = CareLoopTestFactory.newActivity(patient.Id, Date.today().addDays(-3));
        insert activity;
        Assert.areEqual('Overdue', reload(activity.Id).Status__c);

        update new Care_Activity__c(Id = activity.Id, Due_Date__c = Date.today().addDays(30));

        Care_Activity__c saved = reload(activity.Id);
        Assert.areEqual('Scheduled', saved.Status__c);
        Assert.isTrue(saved.Days_Overdue__c == 0);
    }

    @IsTest
    static void reopeningAClosedActivityRecalculatesTheStatus() {
        Contact patient = setUpPatient();
        Care_Activity__c activity = CareLoopTestFactory.newActivity(patient.Id, Date.today().addDays(-4));
        insert activity;
        update new Care_Activity__c(Id = activity.Id, Status__c = 'Completed', Completed_Date__c = Date.today());

        update new Care_Activity__c(Id = activity.Id, Status__c = 'Scheduled', Completed_Date__c = null);

        Care_Activity__c saved = reload(activity.Id);
        Assert.areEqual('Overdue', saved.Status__c, 'Re-opened activity is still overdue');
        Assert.isTrue(saved.Days_Overdue__c == 4);
    }

    @IsTest
    static void explicitAssigneeIsKept() {
        Contact patient = setUpPatient();
        List<User> others = [
            SELECT Id FROM User
            WHERE IsActive = true AND UserType = 'Standard' AND Id != :UserInfo.getUserId()
            LIMIT 1
        ];
        Id chosen = others.isEmpty() ? UserInfo.getUserId() : others[0].Id;
        Care_Activity__c activity = CareLoopTestFactory.newActivity(patient.Id, Date.today().addDays(20));
        activity.Assigned_To__c = chosen;

        insert activity;

        Assert.areEqual(chosen, reload(activity.Id).Assigned_To__c);
    }
}
