@IsTest
private class Phase7AutomationTest {

    @IsTest
    static void supervisorApprovalClosesTheActivityFromTheReason() {
        CareLoopTestFactory.useRealToday();
        List<User> staff = CareLoopPhase4TestData.insertWorkerAndSupervisor();
        User worker = staff[0];
        User supervisor = staff[1];
        Contact p = CareLoopPhase4TestData.insertPatient(worker.Id, Date.today().addYears(-30), 'English', 'Portal Inbox', true);
        Care_Activity__c a = CareLoopPhase4TestData.activity(p.Id, 'Routine Check-up', 'Check refused', Date.today().addDays(-5));
        insert a;

        System.runAs(worker) {
            update new Care_Activity__c(Id = a.Id, Closure_Reason__c = 'Refused');
            Approval.ProcessSubmitRequest submit = new Approval.ProcessSubmitRequest();
            submit.setObjectId(a.Id);
            submit.setProcessDefinitionNameOrId('Care_Activity_Closure');
            submit.setComments('Patient refused the check-up');
            Approval.ProcessResult result = Approval.process(submit);
            Assert.isTrue(result.isSuccess());
        }
        Assert.areEqual('Pending', [SELECT Approval_Status__c FROM Care_Activity__c WHERE Id = :a.Id].Approval_Status__c);

        ProcessInstanceWorkitem item = [SELECT Id, ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :a.Id];
        Assert.areEqual(supervisor.Id, item.ActorId, 'the worker\'s manager approves');
        System.runAs(supervisor) {
            Approval.ProcessWorkitemRequest approve = new Approval.ProcessWorkitemRequest();
            approve.setWorkitemId(item.Id);
            approve.setAction('Approve');
            Assert.isTrue(Approval.process(approve).isSuccess());
        }
        Care_Activity__c closed = [SELECT Status__c, Approval_Status__c, Days_Overdue__c FROM Care_Activity__c WHERE Id = :a.Id];
        Assert.areEqual('Approved', closed.Approval_Status__c);
        Assert.areEqual('Missed', closed.Status__c, 'Refused -> Missed');
        Assert.isTrue(closed.Days_Overdue__c == 0);
    }

    @IsTest
    static void rejectionKeepsTheActivityOpen() {
        CareLoopTestFactory.useRealToday();
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'Portal Inbox', true);
        Care_Activity__c a = CareLoopPhase4TestData.activity(p.Id, 'Immunization', 'Dose', Date.today().addDays(-5));
        a.Closure_Reason__c = 'Moved Away';
        insert a;
        update new Care_Activity__c(Id = a.Id, Approval_Status__c = 'Rejected');
        Care_Activity__c after = [SELECT Status__c, Next_Action__c FROM Care_Activity__c WHERE Id = :a.Id];
        Assert.areEqual('Overdue', after.Status__c);
        Assert.isTrue(after.Next_Action__c.startsWith('Closure rejected'));
        update new Care_Activity__c(Id = a.Id, Approval_Status__c = 'Approved');
        Assert.areEqual('Cancelled', [SELECT Status__c FROM Care_Activity__c WHERE Id = :a.Id].Status__c, 'Moved Away -> Cancelled');
        Assert.areEqual('Missed', CareActivityTriggerHandler.closedStatusFor(null));
    }

    @IsTest
    static void newHouseholdBelongsToTheVillageHealthWorker() {
        List<User> staff = CareLoopPhase4TestData.insertWorkerAndSupervisor();
        Village__c v = CareLoopTestFactory.insertVillage(staff[0].Id);
        Account household = new Account(Name = 'Flow Test Household', Village__c = v.Id);
        insert household;
        Assert.areEqual(staff[0].Id, [SELECT OwnerId FROM Account WHERE Id = :household.Id].OwnerId,
            'CareLoop Household Default Owner flow');
    }

    @IsTest
    static void flowActionRecordsConsentInTheLedger() {
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'Portal Inbox', false);
        ConsentInvocable.Request r = new ConsentInvocable.Request();
        r.patientId = p.Id;
        r.purpose = 'Reminders and Communication';
        r.grant = true;
        r.channel = 'Paper Form';
        r.reason = 'Signed at registration';
        ConsentInvocable.record(new List<ConsentInvocable.Request>{ r });
        Assert.isTrue([SELECT Reminder_Consent__c FROM Contact WHERE Id = :p.Id].Reminder_Consent__c);
        Assert.areEqual(1, [SELECT COUNT() FROM Consent_Event__c WHERE Patient__c = :p.Id]);
    }

    @IsTest
    static void registerPatientFlowCreatesThePatientAndConsent() {
        CareLoopTestFactory.useRealToday();
        Village__c v = CareLoopTestFactory.insertVillage(UserInfo.getUserId());
        Account household = CareLoopTestFactory.insertHousehold(v.Id);
        Map<String, Object> inputs = new Map<String, Object>{ 'recordId' => household.Id };
        Flow.Interview interview = Flow.Interview.createInterview('CareLoop_Register_Patient', inputs);
        Assert.isNotNull(interview, 'the flow exists and can be started');
    }
}
