@IsTest
private class SentinelServiceTest {

    // ------------------------------------------------------------------ fixtures

    /** A signal definition built in memory (custom metadata cannot be inserted in tests). */
    private static Surveillance_Signal__mdt signal(String name, Map<String, Object> overrides) {
        Map<String, Object> f = new Map<String, Object>{
            'DeveloperName' => name, 'MasterLabel' => name.replace('_', ' '), 'Active__c' => true, 'Source__c' => 'Health Visit',
            'Grace_Days__c' => 7, 'Min_Count__c' => 3, 'Watch_Z__c' => 2, 'Alert_Z__c' => 3, 'Baseline_Weeks__c' => 4,
            'Min_History_Weeks__c' => 2, 'Guidance__c' => 'Verify with the health worker.'
        };
        f.putAll(overrides);
        return (Surveillance_Signal__mdt) JSON.deserialize(JSON.serialize(f), Surveillance_Signal__mdt.class);
    }

    /** The four shipped signals, defined in the test so the tests do not depend on org configuration. */
    private static void useSignals() {
        SentinelService.signalOverride = new List<Surveillance_Signal__mdt>{
            signal('Fever_Cluster', new Map<String, Object>{ 'Symptoms__c' => 'Fever', 'Min_Temperature__c' => 38.0 }),
            signal('Respiratory_Cluster', new Map<String, Object>{ 'Symptoms__c' => 'Cough;Breathlessness', 'Max_SpO2__c' => 94 }),
            signal('Failed_Visit_Surge', new Map<String, Object>{
                'Visit_Outcomes__c' => 'Patient Not Available;Patient Refused', 'Min_Count__c' => 4 }),
            signal('Immunisation_Delay', new Map<String, Object>{ 'Source__c' => 'Care Activity', 'Activity_Types__c' => 'Immunization' })
        };
    }

    /** A village (population 2000) with n households of one patient each. */
    private static List<Contact> village(String name, Integer households) {
        Village__c v = new Village__c(Name = name, Region__c = 'North', District__c = 'D', State__c = 'Telangana', Population__c = 2000);
        insert v;
        List<Account> hh = new List<Account>();
        for (Integer i = 0; i < households; i++) {
            hh.add(new Account(Name = name + ' household ' + i, Village__c = v.Id));
        }
        insert hh;
        TriggerHandler.bypass('ContactTriggerHandler');
        List<Contact> people = new List<Contact>();
        for (Account a : hh) {
            people.add(CareLoopTestFactory.newPatient(a.Id, v.Id, Date.today().addYears(-30)));
        }
        insert people;
        TriggerHandler.clearBypass('ContactTriggerHandler');
        return people;
    }

    private static Datetime daysAgo(Integer days) {
        return Datetime.newInstance(Date.today().addDays(-days), Time.newInstance(0, 5, 0, 0));
    }

    private static Health_Visit__c fever(Id patientId, Integer days) {
        return new Health_Visit__c(Patient__c = patientId, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed',
            Visit_Date__c = daysAgo(days), Symptoms__c = 'Fever;Headache', Temperature__c = 38.6);
    }

    private static Health_Visit__c routine(Id patientId, Integer days) {
        return new Health_Visit__c(Patient__c = patientId, Visit_Type__c = 'Routine Check-up', Visit_Outcome__c = 'Completed',
            Visit_Date__c = daysAgo(days));
    }

    private static Health_Visit__c notReached(Id patientId, Integer days) {
        return new Health_Visit__c(Patient__c = patientId, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Patient Not Available',
            Visit_Date__c = daysAgo(days));
    }

    /** One ordinary visit in each of the 5 previous weeks, so the village has a history to compare with. */
    private static List<Health_Visit__c> history(Id patientId) {
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer week = 1; week <= 5; week++) {
            visits.add(routine(patientId, week * 7 + 3));
        }
        return visits;
    }

    private static SentinelService.SignalResult find(Date asOf, String villageName, String signalKey) {
        for (SentinelService.SignalResult r : SentinelService.evaluate(asOf)) {
            if (r.villageName == villageName && r.signalKey == signalKey) {
                return r;
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ the four signals

    @IsTest
    static void feverSpikeIsAnAlertWithExplanation() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Spike Village', 5);
        List<Health_Visit__c> visits = new List<Health_Visit__c>{
            fever(people[0].Id, 10), fever(people[1].Id, 17), fever(people[2].Id, 30)   // baseline weeks: 1,1,0,1
        };
        for (Integer i = 0; i < 6; i++) {
            visits.add(fever(people[Math.mod(i, 4)].Id, Math.mod(i, 5)));                 // this week: 6 from 4 households
        }
        insert visits;

        SentinelService.SignalResult r = find(Date.today(), 'Spike Village', 'Fever_Cluster');
        Assert.areEqual(6, r.observed);
        Assert.areEqual(4, r.households);
        Assert.areEqual('Alert', r.severity, r.explanation);
        Assert.isFalse(r.insufficientHistory);
        Assert.isTrue(r.expected == 0.75, 'baseline 1,1,0,1 -> mean 0.75: ' + r.expected);
        Assert.areEqual(5, r.weekly.size());
        Assert.areEqual(6, r.weekly[4], 'current week last');
        Assert.isTrue(r.explanation.contains('from 4 household(s)'), r.explanation);
        Assert.isTrue(r.ratePer1000 == 3, 'six per 2,000 people');
        Assert.areEqual(6, r.evidenceIds.size());
    }

    @IsTest
    static void respiratoryClusterCountsCoughBreathlessnessOrLowSpO2() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Cough Village', 6);
        List<Health_Visit__c> visits = history(people[5].Id);
        visits.add(new Health_Visit__c(Patient__c = people[0].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(1), Symptoms__c = 'Cough'));
        visits.add(new Health_Visit__c(Patient__c = people[1].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(2), Symptoms__c = 'Cough;Fever'));
        visits.add(new Health_Visit__c(Patient__c = people[2].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(3), Symptoms__c = 'Breathlessness'));
        visits.add(new Health_Visit__c(Patient__c = people[3].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(4), SpO2__c = 93));
        // not respiratory: normal SpO2 and an unrelated symptom
        visits.add(new Health_Visit__c(Patient__c = people[4].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(1), SpO2__c = 97));
        visits.add(new Health_Visit__c(Patient__c = people[4].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(2), Symptoms__c = 'Headache'));
        insert visits;

        SentinelService.SignalResult r = find(Date.today(), 'Cough Village', 'Respiratory_Cluster');
        Assert.areEqual(4, r.observed, 'cough, cough+fever, breathlessness and SpO2 93 count; SpO2 97 and headache do not');
        Assert.areEqual('Alert', r.severity, r.explanation);
        Assert.areEqual(4, r.households);
    }

    @IsTest
    static void unreachableHouseholdsNeedAtLeastFourVisits() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> three = village('Three Missed', 4);
        List<Contact> five = village('Five Missed', 6);
        List<Health_Visit__c> visits = history(three[3].Id);
        visits.addAll(history(five[5].Id));
        for (Integer i = 0; i < 3; i++) {
            visits.add(notReached(three[i].Id, i));
        }
        for (Integer i = 0; i < 5; i++) {
            visits.add(notReached(five[i].Id, i));
        }
        visits.add(new Health_Visit__c(Patient__c = five[0].Id, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Patient Refused',
            Visit_Date__c = daysAgo(5)));
        insert visits;

        SentinelService.SignalResult small = find(Date.today(), 'Three Missed', 'Failed_Visit_Surge');
        Assert.areEqual(3, small.observed);
        Assert.areEqual('Normal', small.severity, 'below the minimum of 4: ' + small.explanation);
        SentinelService.SignalResult surge = find(Date.today(), 'Five Missed', 'Failed_Visit_Surge');
        Assert.areEqual(6, surge.observed, '"Patient Not Available" and "Patient Refused" both count');
        Assert.areEqual('Alert', surge.severity, surge.explanation);
    }

    @IsTest
    static void delayedVaccineDosesAreDetectedButGraceCancelledAndOnTimeAreNot() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Vaccine Village', 4);
        List<Care_Activity__c> doses = new List<Care_Activity__c>();
        // baseline weeks (due 15-36 days ago): given on time -> history, but not delays
        for (Integer i = 0; i < 4; i++) {
            Date due = Date.today().addDays(-15 - i * 7);
            doses.add(new Care_Activity__c(Name = 'On time ' + i, Patient__c = people[i].Id, Activity_Type__c = 'Immunization',
                Due_Date__c = due, Status__c = 'Completed', Completed_Date__c = due.addDays(2)));
        }
        // assessed window (due 8-13 days ago): five doses not given
        for (Integer i = 0; i < 5; i++) {
            doses.add(new Care_Activity__c(Name = 'Delayed ' + i, Patient__c = people[Math.mod(i, 4)].Id,
                Activity_Type__c = 'Immunization', Due_Date__c = Date.today().addDays(-8 - i)));
        }
        // not counted: still inside the 7-day grace period, given within grace, approved cancellation, other type
        doses.add(new Care_Activity__c(Name = 'In grace', Patient__c = people[0].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = Date.today().addDays(-3)));
        doses.add(new Care_Activity__c(Name = 'Given in grace', Patient__c = people[1].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = Date.today().addDays(-9), Status__c = 'Completed', Completed_Date__c = Date.today().addDays(-4)));
        doses.add(new Care_Activity__c(Name = 'Moved away', Patient__c = people[2].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = Date.today().addDays(-10), Status__c = 'Cancelled', Approval_Status__c = 'Approved',
            Closure_Reason__c = 'Moved Away'));
        doses.add(new Care_Activity__c(Name = 'Check-up', Patient__c = people[3].Id, Activity_Type__c = 'Routine Check-up',
            Due_Date__c = Date.today().addDays(-11)));
        insert doses;

        SentinelService.SignalResult r = find(Date.today(), 'Vaccine Village', 'Immunisation_Delay');
        Assert.areEqual(5, r.observed, r.explanation);
        Assert.areEqual('Alert', r.severity, r.explanation);
        Assert.isTrue(r.explanation.contains('not given within 7 days'), r.explanation);
        Assert.areEqual(Date.today().addDays(-7), r.windowEnd, 'vaccine window ends after the grace period');
    }

    // ------------------------------------------------------------------ safeguards against false alarms

    @IsTest
    static void steadyOrTinyCountsAreNotFlagged() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> steady = village('Steady Village', 3);
        List<Contact> tiny = village('Tiny Village', 3);
        List<Health_Visit__c> visits = history(tiny[2].Id);
        for (Integer week = 0; week <= 4; week++) {
            visits.add(fever(steady[0].Id, week * 7 + 1));
            visits.add(fever(steady[1].Id, week * 7 + 2));
        }
        visits.add(fever(tiny[0].Id, 1));
        visits.add(fever(tiny[1].Id, 2));   // 2 this week, 0 before: unusual, but below the minimum of 3
        insert visits;
        for (SentinelService.SignalResult r : SentinelService.evaluate(Date.today())) {
            Assert.areEqual('Normal', r.severity, r.villageName + ' ' + r.signalKey + ': ' + r.explanation);
        }
        SentinelService.SignalResult steadyFever = find(Date.today(), 'Steady Village', 'Fever_Cluster');
        Assert.isTrue(steadyFever.expected == 2 && steadyFever.z == 0, steadyFever.explanation);
        Assert.areEqual(0, SentinelService.scan(Date.today(), false).flagged);
        Assert.areEqual(0, [SELECT COUNT() FROM Community_Signal__c]);
    }

    @IsTest
    static void villagesWithoutEnoughHistoryAreNotAssessed() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> fresh = village('New Village', 6);
        List<Contact> oneWeek = village('One Week Village', 6);
        List<Health_Visit__c> visits = new List<Health_Visit__c>{ routine(oneWeek[5].Id, 10) };   // history in 1 week only
        for (Integer i = 0; i < 6; i++) {
            visits.add(fever(fresh[i].Id, Math.mod(i, 5)));
            visits.add(fever(oneWeek[i].Id, Math.mod(i, 5)));
        }
        insert visits;

        for (String name : new List<String>{ 'New Village', 'One Week Village' }) {
            SentinelService.SignalResult r = find(Date.today(), name, 'Fever_Cluster');
            Assert.areEqual(6, r.observed);
            Assert.isTrue(r.insufficientHistory, name);
            Assert.areEqual('Normal', r.severity, 'six cases with no history is not compared with "zero": ' + r.explanation);
            Assert.isTrue(r.explanation.contains('not assessed'), r.explanation);
        }
        Assert.areEqual(0, SentinelService.scan(Date.today(), false).flagged);
    }

    @IsTest
    static void thresholdsDecideWatchAndAlertAndAreConfigurable() {
        Surveillance_Signal__mdt standard = signal('Fever_Cluster', new Map<String, Object>());
        Surveillance_Signal__mdt strict = signal('Fever_Cluster', new Map<String, Object>{ 'Alert_Z__c' => 5 });

        SentinelService.SignalResult watch = scored(new List<Integer>{ 2, 3, 2, 3 }, 5, standard);
        Assert.areEqual('Watch', watch.severity, watch.explanation);   // mean 2.5, spread 1 -> z 2.5
        Assert.isTrue(watch.z == 2.5 && watch.threshold == 4.5, watch.explanation);

        Assert.areEqual('Alert', scored(new List<Integer>{ 2, 3, 2, 3 }, 6, standard).severity);   // z 3.5
        Assert.areEqual('Watch', scored(new List<Integer>{ 2, 3, 2, 3 }, 6, strict).severity, 'Alert_Z 5 from custom metadata');
        Assert.areEqual('Normal', scored(new List<Integer>{ 2, 3, 2, 3 }, 4, standard).severity);  // z 1.5

        SentinelService.SignalResult flat = scored(new List<Integer>{ 0, 0, 0, 0 }, 2, standard);
        Assert.areEqual('Normal', flat.severity, 'spread floor 1 and minimum 3 stop 0 -> 2 from alerting');
        Assert.isTrue(flat.spread == 1);

        SentinelService.SignalResult noisy = scored(new List<Integer>{ 0, 10, 0, 10 }, 12, standard);
        Assert.areEqual('Normal', noisy.severity, 'a village that is always up and down needs a bigger jump: ' + noisy.explanation);
    }

    private static SentinelService.SignalResult scored(List<Integer> baseline, Integer observed, Surveillance_Signal__mdt s) {
        SentinelService.SignalResult r = new SentinelService.SignalResult();
        r.villageName = 'Unit Village';
        r.signalKey = s.DeveloperName;
        r.signalLabel = s.MasterLabel;
        r.baselineCounts = baseline;
        r.historyWeeks = new Set<Integer>{ 1, 2, 3, 4 };
        r.observed = observed;
        SentinelService.score(r, s, null);
        return r;
    }

    // ------------------------------------------------------------------ recording, duplicates, review statuses

    @IsTest
    static void scanRecordsOnceKeepsStatusAndRespectsDismissal() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Failed Village', 7);
        List<Health_Visit__c> visits = history(people[6].Id);
        for (Integer i = 0; i < 6; i++) {
            visits.add(notReached(people[i].Id, i));
        }
        insert visits;

        SentinelService.ScanSummary first = SentinelService.scan(Date.today(), false);
        Assert.areEqual(1, first.created);
        Community_Signal__c signal = [SELECT Id, Status__c, Severity__c, Observed__c, Evidence_Ids__c, Alert_Key__c, Region__c,
                                      Explanation__c FROM Community_Signal__c];
        Assert.areEqual('New', signal.Status__c);
        Assert.isTrue(signal.Observed__c == 6);
        Assert.areEqual('North', signal.Region__c);
        Assert.areEqual(6, signal.Evidence_Ids__c.split(',').size());
        Assert.isFalse(signal.Explanation__c.contains(people[0].LastName), 'explanations never name a patient');

        update new Community_Signal__c(Id = signal.Id, Status__c = 'Investigating');
        SentinelService.ScanSummary second = SentinelService.scan(Date.today(), false);
        Assert.areEqual(0, second.created, 'same investigation, no duplicate');
        Assert.areEqual(1, second.updated);
        Assert.areEqual('Investigating', [SELECT Status__c FROM Community_Signal__c WHERE Id = :signal.Id].Status__c);

        update new Community_Signal__c(Id = signal.Id, Status__c = 'Dismissed');
        CareLoopClock.testToday = Date.today().addDays(1);
        SentinelService.ScanSummary third = SentinelService.scan(CareLoopClock.today(), false);
        Assert.areEqual(0, third.created + third.updated, 'a dismissed signal is not raised again during its week');
        Assert.areEqual(1, [SELECT COUNT() FROM Community_Signal__c]);
    }

    @IsTest
    static void closedSignalIsSuppressedThatWeekButANewClusterLaterIsRaised() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Closed Village', 10);
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer week = 0; week <= 6; week++) {
            visits.add(routine(people[9].Id, week * 7 + 3));
        }
        for (Integer i = 0; i < 5; i++) {
            visits.add(fever(people[i].Id, 14 + i));       // first cluster: 14-18 days ago
        }
        for (Integer i = 0; i < 9; i++) {
            visits.add(fever(people[i].Id, Math.mod(i, 5))); // second, bigger cluster: this week
        }
        insert visits;
        Date earlier = Date.today().addDays(-14);

        Assert.areEqual(1, SentinelService.scan(earlier, false).created, 'first cluster raised');
        Community_Signal__c first = [SELECT Id FROM Community_Signal__c];
        update new Community_Signal__c(Id = first.Id, Status__c = 'Closed', Investigation_Notes__c = 'Handled by PHC');
        SentinelService.ScanSummary nextDay = SentinelService.scan(earlier.addDays(1), false);
        Assert.areEqual(0, nextDay.created + nextDay.updated, 'closed signals are not re-raised in the same window');

        SentinelService.ScanSummary later = SentinelService.scan(Date.today(), false);
        Assert.areEqual(1, later.created, 'a new cluster two weeks later is a new signal');
        Assert.areEqual(2, [SELECT COUNT() FROM Community_Signal__c]);
        Assert.areEqual('Closed', [SELECT Status__c FROM Community_Signal__c WHERE Id = :first.Id].Status__c);
    }

    // ------------------------------------------------------------------ notifications

    @IsTest
    static void managersAreNotifiedForNewSignalsAndEscalationsOnly() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        User manager = CareLoopPhase4TestData.newUser('snm');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert manager;
            insert new PermissionSetAssignment(AssigneeId = manager.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :SentinelService.MANAGER_PERMISSION_SET].Id);
        }
        List<Contact> people = village('Bell Village', 8);
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        // baseline of missed visits per week 1,2,1,2 (mean 1.5, spread 1) plus routine history
        List<Integer> baseline = new List<Integer>{ 1, 2, 1, 2 };
        for (Integer week = 1; week <= 4; week++) {
            visits.add(routine(people[7].Id, week * 7 + 1));
            for (Integer k = 0; k < baseline[week - 1]; k++) {
                visits.add(notReached(people[k].Id, week * 7 + 2 + k));
            }
        }
        for (Integer i = 0; i < 4; i++) {
            visits.add(notReached(people[i].Id, i));   // this week 4 -> z 2.5 -> Watch
        }
        insert visits;

        Integer bellsBefore = CareLoopAlertService.bellsSent;
        SentinelService.ScanSummary first = SentinelService.scan(Date.today(), true);
        Assert.areEqual(1, first.created);
        Assert.areEqual('Watch', [SELECT Severity__c FROM Community_Signal__c].Severity__c);
        Assert.areEqual(1, first.notified, 'new signal -> one notification');
        Assert.areEqual(bellsBefore + 1, CareLoopAlertService.bellsSent);

        SentinelService.ScanSummary repeat = SentinelService.scan(Date.today(), true);
        Assert.areEqual(0, repeat.notified, 'no new bell when nothing changed');

        insert notReached(people[4].Id, 1);              // this week 5 -> z 3.5 -> Alert
        SentinelService.ScanSummary escalated = SentinelService.scan(Date.today(), true);
        Assert.areEqual(1, escalated.updated);
        Assert.areEqual(1, escalated.notified, 'Watch -> Alert notifies again');
        Assert.areEqual('Alert', [SELECT Severity__c FROM Community_Signal__c].Severity__c);
    }

    // ------------------------------------------------------------------ scheduling

    @IsTest
    static void dailyJobSchedulesOnceAndRuns() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        Test.startTest();
        Id first = SentinelJob.scheduleDaily();
        Assert.areEqual(first, SentinelJob.scheduleDaily());
        new SentinelJob().execute(null);
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c]);
        Assert.isFalse(SentinelService.signals().isEmpty());
    }
}
