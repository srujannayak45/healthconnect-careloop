@IsTest
private class CareScheduleServiceTest {

    /** A small, fixed schedule so expected numbers never depend on Setup changes. */
    private static void useTestSchedules() {
        CareRules.schedules = new List<Care_Schedule__mdt>{
            CareLoopTestFactory.schedule('T_BCG', 'Immunization', 'BCG', 1, 0, 'Birthdate', 'Child Under 2', null, 1),
            CareLoopTestFactory.schedule('T_Penta_1', 'Immunization', 'Pentavalent', 1, 42, 'Birthdate', 'Child Under 2', null, 1),
            CareLoopTestFactory.schedule('T_MR_1', 'Immunization', 'Measles-Rubella', 1, 270, 'Birthdate', 'Child Under 2', null, 1),
            CareLoopTestFactory.schedule('T_ANC', 'Antenatal Check-up', 'Antenatal check-up', null, 7, 'Registration Date', 'Pregnant', 30, 4),
            CareLoopTestFactory.schedule('T_BP', 'Routine Check-up', 'BP monitoring', null, 30, 'Registration Date', 'Hypertension', 30, 3),
            CareLoopTestFactory.schedule('T_Adult', 'Routine Check-up', 'Annual health screening', null, 14, 'Registration Date', 'Adult 30 Plus', null, 1)
        };
    }

    private static Map<String, Care_Activity__c> activitiesByKey(Id patientId) {
        Map<String, Care_Activity__c> result = new Map<String, Care_Activity__c>();
        for (Care_Activity__c a : [
            SELECT Name, Activity_Type__c, Status__c, Due_Date__c, Days_Overdue__c, Source__c, Schedule_Key__c,
                   Dose_Number__c, Assigned_To__c
            FROM Care_Activity__c WHERE Patient__c = :patientId
        ]) {
            result.put(a.Schedule_Key__c, a);
        }
        return result;
    }

    @IsTest
    static void infantGetsImmunisationsWithCatchUpStatuses() {
        CareLoopTestFactory.useRealToday();
        useTestSchedules();
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact baby = CareLoopTestFactory.insertPatient(Date.today().addDays(-60));

        Integer created = CareScheduleService.generate(new Set<Id>{ baby.Id });

        Assert.areEqual(3, created, 'Three test vaccine doses for a 2-month-old');
        Map<String, Care_Activity__c> byKey = activitiesByKey(baby.Id);
        Care_Activity__c bcg = byKey.get(String.valueOf(baby.Id) + '-T_BCG-1');
        Assert.areEqual('Overdue', bcg.Status__c, 'Birth dose is 60 days overdue');
        Assert.isTrue(bcg.Days_Overdue__c == 60, 'Days overdue counted from the birth date');
        Assert.areEqual(Date.today().addDays(-60), bcg.Due_Date__c);
        Assert.areEqual('Immunization', bcg.Activity_Type__c);
        Assert.areEqual('Care Schedule', bcg.Source__c);
        Assert.areEqual('BCG - dose 1', bcg.Name);
        Assert.isTrue(bcg.Dose_Number__c == 1);
        Assert.areEqual(UserInfo.getUserId(), bcg.Assigned_To__c, 'Assigned to the patient\'s health worker');

        Assert.areEqual('Overdue', byKey.get(String.valueOf(baby.Id) + '-T_Penta_1-1').Status__c, 'Day-42 dose is overdue at day 60');
        Care_Activity__c mr = byKey.get(String.valueOf(baby.Id) + '-T_MR_1-1');
        Assert.areEqual('Scheduled', mr.Status__c, 'Day-270 dose is in the future');
        Assert.areEqual(Date.today().addDays(210), mr.Due_Date__c);
    }

    @IsTest
    static void runningTwiceCreatesNoDuplicates() {
        CareLoopTestFactory.useRealToday();
        useTestSchedules();
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact baby = CareLoopTestFactory.insertPatient(Date.today().addDays(-10));

        Integer first = CareScheduleService.generate(new Set<Id>{ baby.Id });
        Integer second = CareScheduleService.generate(new Set<Id>{ baby.Id });

        Assert.areEqual(3, first);
        Assert.areEqual(0, second, 'Second run finds every key already present');
        Assert.areEqual(3, [SELECT COUNT() FROM Care_Activity__c WHERE Patient__c = :baby.Id]);
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c], 'Skipping existing keys is not an error');
    }

    @IsTest
    static void adultsGetPregnancyAndConditionCare() {
        CareLoopTestFactory.useRealToday();
        useTestSchedules();
        TriggerHandler.bypass('ContactTriggerHandler');
        Village__c village = CareLoopTestFactory.insertVillage(null);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);
        Contact mother = CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addYears(-26));
        mother.Is_Pregnant__c = true;
        Contact elder = CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addYears(-62));
        elder.Gender__c = 'Male';
        elder.Chronic_Conditions__c = 'Hypertension;Diabetes';
        insert new List<Contact>{ mother, elder };

        CareScheduleService.generate(new Set<Id>{ mother.Id, elder.Id });

        Map<String, Care_Activity__c> motherActivities = activitiesByKey(mother.Id);
        Assert.areEqual(4, motherActivities.size(), '4 antenatal check-ups; 26 is too young for adult screening');
        Care_Activity__c firstAnc = motherActivities.get(String.valueOf(mother.Id) + '-T_ANC-1');
        Care_Activity__c lastAnc = motherActivities.get(String.valueOf(mother.Id) + '-T_ANC-4');
        Assert.areEqual(Date.today().addDays(7), firstAnc.Due_Date__c);
        Assert.areEqual(Date.today().addDays(97), lastAnc.Due_Date__c, '7 + 3 x 30 days');
        Assert.areEqual('Antenatal check-up (1 of 4)', firstAnc.Name);
        Assert.areEqual('Scheduled', firstAnc.Status__c);

        Map<String, Care_Activity__c> elderActivities = activitiesByKey(elder.Id);
        Assert.areEqual(4, elderActivities.size(), '3 BP check-ups + 1 adult screening (no diabetes rule in the test schedule)');
        Assert.isTrue(elderActivities.containsKey(String.valueOf(elder.Id) + '-T_BP-3'));
        Assert.isTrue(elderActivities.containsKey(String.valueOf(elder.Id) + '-T_Adult-1'));
    }

    @IsTest
    static void childOverTwoGetsNoImmunisations() {
        CareLoopTestFactory.useRealToday();
        useTestSchedules();
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact child = CareLoopTestFactory.insertPatient(Date.today().addYears(-3));

        Assert.areEqual(0, CareScheduleService.generate(new Set<Id>{ child.Id }));
        Assert.areEqual(0, CareScheduleService.generate(null), 'Null input is ignored');
    }

    @IsTest
    static void generatesForTwoHundredPatientsInOneCall() {
        CareLoopTestFactory.useRealToday();
        useTestSchedules();
        TriggerHandler.bypass('ContactTriggerHandler');
        Village__c village = CareLoopTestFactory.insertVillage(null);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);
        List<Contact> babies = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            babies.add(CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addDays(-30)));
        }
        insert babies;

        Test.startTest();
        Integer created = CareScheduleService.generate(new Map<Id, Contact>(babies).keySet());
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        Assert.areEqual(600, created, '3 doses x 200 babies');
        Assert.isTrue(queriesUsed <= 4, 'Bulk-safe: a fixed number of queries, not one per patient (used ' + queriesUsed + ')');
    }

    @IsTest
    static void registeringAChildQueuesGenerationFromTheRealSchedule() {
        Village__c village = CareLoopTestFactory.insertVillage(null);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);
        Integer expected = CareLoopTestFactory.configuredOccurrences('Child Under 2');

        Test.startTest();
        insert CareLoopTestFactory.newPatient(household.Id, village.Id, Date.today().addDays(-10));
        Test.stopTest();

        Assert.areEqual(expected, [SELECT COUNT() FROM Care_Activity__c],
            'The background job created every active Child Under 2 dose from Care Schedule metadata');
    }

    @IsTest
    static void queueableCanBeRunDirectly() {
        CareLoopTestFactory.useRealToday();
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact baby = CareLoopTestFactory.insertPatient(Date.today().addDays(-5));
        Integer expected = CareLoopTestFactory.configuredOccurrences('Child Under 2');

        Test.startTest();
        System.enqueueJob(new CareScheduleQueueable(new Set<Id>{ baby.Id }));
        CareScheduleQueueable.schedule(new Set<Id>());
        Test.stopTest();

        Assert.areEqual(expected, [SELECT COUNT() FROM Care_Activity__c WHERE Patient__c = :baby.Id]);
    }
}
