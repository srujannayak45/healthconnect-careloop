@IsTest
private class HealthVisitTriggerHandlerTest {

    private static Contact setUpPatient() {
        CareLoopTestFactory.useRealToday();
        CareRules.careRules = CareLoopTestFactory.redFlagRules();
        TriggerHandler.bypass('ContactTriggerHandler');
        return CareLoopTestFactory.insertPatient(Date.today().addYears(-55));
    }

    private static Health_Visit__c reload(Id visitId) {
        return [
            SELECT Red_Flag__c, Red_Flag_Reason__c, Review_Status__c, Health_Worker__c, Visit_Outcome__c
            FROM Health_Visit__c WHERE Id = :visitId
        ];
    }

    @IsTest
    static void criticalBloodPressureRaisesARedFlagAndRequestsReview() {
        Contact patient = setUpPatient();
        Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
        visit.BP_Systolic__c = 186;
        visit.BP_Diastolic__c = 112;
        visit.SpO2__c = 97;

        insert visit;

        Health_Visit__c saved = reload(visit.Id);
        Assert.isTrue(saved.Red_Flag__c);
        Assert.isTrue(saved.Red_Flag_Reason__c.contains('Systolic BP 186 mmHg'), saved.Red_Flag_Reason__c);
        Assert.isTrue(saved.Red_Flag_Reason__c.contains('Diastolic BP 112 mmHg'), saved.Red_Flag_Reason__c);
        Assert.isFalse(saved.Red_Flag_Reason__c.contains('SpO2'), 'Normal oxygen is not a reason');
        Assert.areEqual('Pending Review', saved.Review_Status__c);
        Assert.areEqual(UserInfo.getUserId(), saved.Health_Worker__c);
    }

    @IsTest
    static void lowOxygenAndHighFeverAreRedFlags() {
        Contact patient = setUpPatient();
        Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
        visit.SpO2__c = 90;
        visit.Temperature__c = 40.2;

        insert visit;

        Health_Visit__c saved = reload(visit.Id);
        Assert.isTrue(saved.Red_Flag__c);
        Assert.isTrue(saved.Red_Flag_Reason__c.contains('SpO2 90%'), saved.Red_Flag_Reason__c);
        Assert.isTrue(saved.Red_Flag_Reason__c.contains('Temperature 40.2 C'), saved.Red_Flag_Reason__c);
    }

    @IsTest
    static void normalVitalsNeedNoReview() {
        Contact patient = setUpPatient();
        Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
        visit.BP_Systolic__c = 124;
        visit.BP_Diastolic__c = 82;
        visit.SpO2__c = 98;
        visit.Temperature__c = 36.8;
        visit.Blood_Sugar__c = 110;

        insert visit;

        Health_Visit__c saved = reload(visit.Id);
        Assert.isFalse(saved.Red_Flag__c);
        Assert.isNull(saved.Red_Flag_Reason__c);
        Assert.areEqual('Not Required', saved.Review_Status__c);
    }

    @IsTest
    static void workerCanAskForADoctorWithoutARedFlag() {
        Contact patient = setUpPatient();
        Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
        visit.Needs_Doctor_Review__c = true;

        insert visit;

        Assert.areEqual('Pending Review', reload(visit.Id).Review_Status__c);
    }

    @IsTest
    static void correctingAReadingClearsTheFlagButReviewedStaysReviewed() {
        Contact patient = setUpPatient();
        Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
        visit.BP_Systolic__c = 190;
        visit.BP_Diastolic__c = 100;
        insert visit;

        visit.BP_Systolic__c = 130;
        visit.BP_Diastolic__c = 85;
        update visit;
        Health_Visit__c corrected = reload(visit.Id);
        Assert.isFalse(corrected.Red_Flag__c, 'Corrected reading clears the flag');
        Assert.areEqual('Not Required', corrected.Review_Status__c);

        visit.BP_Systolic__c = 190;
        update visit;
        update new Health_Visit__c(Id = visit.Id, Review_Status__c = 'Reviewed');
        update new Health_Visit__c(Id = visit.Id, Observations__c = 'Follow-up note');
        Assert.areEqual('Reviewed', reload(visit.Id).Review_Status__c, 'Reviewed is never downgraded');
    }

    @IsTest
    static void unsuccessfulVisitsAreNotRedFlaggedAndOutcomeDefaultsToCompleted() {
        Contact patient = setUpPatient();
        Health_Visit__c missed = CareLoopTestFactory.newVisit(patient.Id);
        missed.Visit_Outcome__c = 'Patient Not Available';
        Health_Visit__c noOutcome = CareLoopTestFactory.newVisit(patient.Id);
        noOutcome.Visit_Outcome__c = null;

        insert new List<Health_Visit__c>{ missed, noOutcome };

        Assert.isFalse(reload(missed.Id).Red_Flag__c);
        Assert.areEqual('Completed', reload(noOutcome.Id).Visit_Outcome__c);
    }

    @IsTest
    static void visitsKeepThePatientsContactHistoryCurrent() {
        Contact patient = setUpPatient();
        Health_Visit__c notHome = CareLoopTestFactory.newVisit(patient.Id);
        notHome.Visit_Outcome__c = 'Patient Not Available';
        Health_Visit__c oldAttempt = CareLoopTestFactory.newVisit(patient.Id);
        oldAttempt.Visit_Outcome__c = 'Patient Refused';
        oldAttempt.Visit_Date__c = System.now().addDays(-120);
        insert new List<Health_Visit__c>{ notHome, oldAttempt };

        Contact afterFailures = [SELECT Last_Successful_Contact__c, Failed_Outreach_Attempts__c FROM Contact WHERE Id = :patient.Id];
        Assert.isTrue(afterFailures.Failed_Outreach_Attempts__c == 1, 'Only attempts in the last 90 days count');
        Assert.isNull(afterFailures.Last_Successful_Contact__c);

        insert CareLoopTestFactory.newVisit(patient.Id);
        Contact afterSuccess = [SELECT Last_Successful_Contact__c, Failed_Outreach_Attempts__c FROM Contact WHERE Id = :patient.Id];
        Assert.areEqual(Date.today(), afterSuccess.Last_Successful_Contact__c);
        Assert.isTrue(afterSuccess.Failed_Outreach_Attempts__c == 1);

        update new Health_Visit__c(Id = notHome.Id, Visit_Outcome__c = 'Completed');
        Contact afterCorrection = [SELECT Failed_Outreach_Attempts__c FROM Contact WHERE Id = :patient.Id];
        Assert.isTrue(afterCorrection.Failed_Outreach_Attempts__c == 0, 'Changing the outcome refreshes the count');
    }

    @IsTest
    static void twoHundredVisitsAreHandledInOneSave() {
        Contact patient = setUpPatient();
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer i = 0; i < 200; i++) {
            Health_Visit__c visit = CareLoopTestFactory.newVisit(patient.Id);
            visit.Visit_Date__c = System.now().addMinutes(-i);
            visit.BP_Systolic__c = 185;
            visit.BP_Diastolic__c = 100;
            visits.add(visit);
        }

        Test.startTest();
        insert visits;
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(200, [SELECT COUNT() FROM Health_Visit__c WHERE Red_Flag__c = true]);
        Assert.isTrue(queriesUsed <= 5, 'Bulk-safe (queries used: ' + queriesUsed + ')');
    }
}
