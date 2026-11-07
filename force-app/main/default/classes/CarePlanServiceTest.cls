@IsTest
private class CarePlanServiceTest {

    private static Health_Visit__c setUpVisit() {
        CareLoopTestFactory.useRealToday();
        CareRules.careRules = CareLoopTestFactory.redFlagRules();
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact patient = CareLoopTestFactory.insertPatient(Date.today().addYears(-50));
        Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
        visit.BP_Systolic__c = 186;
        visit.BP_Diastolic__c = 112;
        insert visit;
        return [SELECT Id, Patient__c, Visit_Date__c, Review_Status__c FROM Health_Visit__c WHERE Id = :visit.Id];
    }

    private static Medical_Recommendation__c recommendation(Id visitId, String status) {
        return new Medical_Recommendation__c(
            Outreach_Visit__c = visitId,
            Status__c = status,
            Assessment__c = 'Stage 2 hypertension.',
            Advice__c = 'Reduce salt, take the prescribed tablet daily, re-check in one week.'
        );
    }

    @IsTest
    static void finalRecommendationCreatesFollowUpAndCarePlan() {
        Health_Visit__c visit = setUpVisit();
        Assert.areEqual('Pending Review', visit.Review_Status__c, 'Red-flag visit waits for a doctor');
        Medical_Recommendation__c rec = recommendation(visit.Id, 'Final');
        rec.Follow_Up_In_Days__c = 7;
        rec.Check_Up_Interval_Days__c = 30;
        rec.Check_Up_Occurrences__c = 3;

        insert rec;

        Medical_Recommendation__c saved = [SELECT Doctor__c, Finalized_On__c FROM Medical_Recommendation__c WHERE Id = :rec.Id];
        Assert.areEqual(UserInfo.getUserId(), saved.Doctor__c, 'Finalising doctor is stamped');
        Assert.isNotNull(saved.Finalized_On__c);

        List<Care_Activity__c> plan = [
            SELECT Name, Activity_Type__c, Due_Date__c, Source__c, Schedule_Key__c, Patient__c, Status__c
            FROM Care_Activity__c WHERE Recommendation__c = :rec.Id ORDER BY Due_Date__c
        ];
        Date base = visit.Visit_Date__c.date();
        Assert.areEqual(4, plan.size(), '1 follow-up + 3 check-ups');
        Assert.areEqual('Follow-up', plan[0].Activity_Type__c);
        Assert.areEqual(base.addDays(7), plan[0].Due_Date__c);
        Assert.areEqual(String.valueOf(rec.Id) + '-FU', plan[0].Schedule_Key__c);
        Assert.areEqual('Doctor Recommendation', plan[0].Source__c);
        Assert.areEqual(visit.Patient__c, plan[0].Patient__c);
        Assert.areEqual('Routine Check-up', plan[1].Activity_Type__c);
        Assert.areEqual(base.addDays(30), plan[1].Due_Date__c);
        Assert.areEqual('Care plan check-up (1 of 3)', plan[1].Name);
        Assert.areEqual(base.addDays(90), plan[3].Due_Date__c);
        Assert.areEqual(String.valueOf(rec.Id) + '-CU-3', plan[3].Schedule_Key__c);

        Health_Visit__c reviewed = [SELECT Review_Status__c, Reviewed_By__c, Reviewed_On__c FROM Health_Visit__c WHERE Id = :visit.Id];
        Assert.areEqual('Reviewed', reviewed.Review_Status__c);
        Assert.areEqual(UserInfo.getUserId(), reviewed.Reviewed_By__c);
        Assert.isNotNull(reviewed.Reviewed_On__c);
    }

    @IsTest
    static void draftCreatesNothingUntilItIsFinalised() {
        Health_Visit__c visit = setUpVisit();
        Medical_Recommendation__c rec = recommendation(visit.Id, 'Draft');
        rec.Follow_Up_In_Days__c = 14;
        insert rec;

        Assert.areEqual(0, [SELECT COUNT() FROM Care_Activity__c WHERE Recommendation__c = :rec.Id]);
        Assert.areEqual('Pending Review', [SELECT Review_Status__c FROM Health_Visit__c WHERE Id = :visit.Id].Review_Status__c);
        Assert.isNull([SELECT Doctor__c FROM Medical_Recommendation__c WHERE Id = :rec.Id].Doctor__c);

        rec.Status__c = 'Final';
        update rec;

        Assert.areEqual(1, [SELECT COUNT() FROM Care_Activity__c WHERE Recommendation__c = :rec.Id]);
        Assert.areEqual('Reviewed', [SELECT Review_Status__c FROM Health_Visit__c WHERE Id = :visit.Id].Review_Status__c);
        Assert.areEqual(UserInfo.getUserId(), [SELECT Doctor__c FROM Medical_Recommendation__c WHERE Id = :rec.Id].Doctor__c);
    }

    @IsTest
    static void adviceOnlyRecommendationMarksTheVisitReviewed() {
        Health_Visit__c visit = setUpVisit();
        Medical_Recommendation__c rec = recommendation(visit.Id, 'Final');

        insert rec;

        Assert.areEqual(0, [SELECT COUNT() FROM Care_Activity__c WHERE Recommendation__c = :rec.Id]);
        Assert.areEqual('Reviewed', [SELECT Review_Status__c FROM Health_Visit__c WHERE Id = :visit.Id].Review_Status__c);
    }

    @IsTest
    static void finalisingManyRecommendationsAtOnceIsBulkSafe() {
        CareLoopTestFactory.useRealToday();
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact patient = CareLoopTestFactory.insertPatient(Date.today().addYears(-50));
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer i = 0; i < 50; i++) {
            Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
            visit.Visit_Date__c = System.now().addMinutes(-i);
            visit.Needs_Doctor_Review__c = true;
            visits.add(visit);
        }
        insert visits;
        List<Medical_Recommendation__c> recs = new List<Medical_Recommendation__c>();
        for (Health_Visit__c visit : visits) {
            Medical_Recommendation__c rec = recommendation(visit.Id, 'Final');
            rec.Follow_Up_In_Days__c = 7;
            rec.Check_Up_Interval_Days__c = 30;
            rec.Check_Up_Occurrences__c = 2;
            recs.add(rec);
        }

        Test.startTest();
        insert recs;
        Test.stopTest();

        Assert.areEqual(150, [SELECT COUNT() FROM Care_Activity__c WHERE Source__c = 'Doctor Recommendation']);
        Assert.areEqual(50, [SELECT COUNT() FROM Health_Visit__c WHERE Review_Status__c = 'Reviewed']);
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c]);
    }
}
