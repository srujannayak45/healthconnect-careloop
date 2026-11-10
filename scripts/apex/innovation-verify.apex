// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): verify (rolls everything back)
// =====================================================================================
//   1  The four configured signals are active
//   2  Fever cluster (6 visits, 4 households, quiet baseline) is an Alert, with a plain explanation
//   3  Respiratory cluster (cough / breathlessness / SpO2 < 94) is detected
//   4  Households-not-reachable surge is detected; 3 missed visits (below the minimum 4) is not
//   5  Delayed vaccine doses are detected
//   6  A village with a steady level is Normal
//   7  A village with no history is "not assessed", never flagged
//   8  Scan records one signal; re-scan updates it (no duplicate) and keeps its status
//   9  Closed / dismissed signals are not raised again in the same week
//   10 No Error Log entries
// Uses synthetic villages named "Verify ..." and rolls everything back at the end.
// Run:
//   sf apex run --file scripts/apex/innovation-verify.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'SENTINEL ' + line);
}
Integer mark(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}
Datetime at(Date day) {
    return Datetime.newInstance(day, Time.newInstance(0, 5, 0, 0));
}
SentinelService.SignalResult find(List<SentinelService.SignalResult> results, String village, String signal) {
    for (SentinelService.SignalResult r : results) {
        if (r.villageName == village && r.signalKey == signal) {
            return r;
        }
    }
    return null;
}
List<Contact> village(String name, Integer households) {
    Village__c v = new Village__c(Name = name, Region__c = 'North', District__c = 'D', State__c = 'Telangana', Population__c = 1500);
    insert v;
    List<Account> hh = new List<Account>();
    for (Integer i = 0; i < households; i++) {
        hh.add(new Account(Name = name + ' HH ' + i, Village__c = v.Id));
    }
    insert hh;
    List<Contact> people = new List<Contact>();
    for (Account a : hh) {
        people.add(new Contact(FirstName = 'Verify', LastName = name, AccountId = a.Id, Village__c = v.Id,
            Birthdate = Date.today().addYears(-35), Gender__c = 'Female', Assigned_Health_Worker__c = UserInfo.getUserId()));
    }
    insert people;
    return people;
}
Health_Visit__c visit(Id patientId, Date day, String outcome, String symptoms, Decimal temperature, Decimal spo2) {
    return new Health_Visit__c(Patient__c = patientId, Visit_Date__c = at(day), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = outcome, Symptoms__c = symptoms, Temperature__c = temperature, SpO2__c = spo2);
}
List<Health_Visit__c> history(Id patientId, Date today) {
    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    for (Integer week = 1; week <= 5; week++) {
        visits.add(visit(patientId, today.addDays(-(week * 7) - 3), 'Completed', null, null, null));
    }
    return visits;
}
String describe(SentinelService.SignalResult r) {
    return r == null ? '(not found)' : r.severity + ', observed ' + r.observed + ' vs normal ' + r.expected;
}

Integer runChecks() {
    Integer failures = 0;
    Integer logsBefore = [SELECT COUNT() FROM Error_Log__c];
    Date today = CareLoopClock.today();
    if (today > Date.today()) {
        say('STOP  The CareLoop demo clock is ahead of the real date; clear Simulated Today first.');
        return 1;
    }
    failures += mark(SentinelService.signals().size() >= 4, '1  ' + SentinelService.signals().size() + ' active surveillance signals configured');
    TriggerHandler.bypass('ContactTriggerHandler');
    List<Contact> spike = village('Verify Spike', 6);
    List<Contact> steady = village('Verify Steady', 6);
    List<Contact> fresh = village('Verify New', 4);
    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    visits.addAll(history(spike[5].Id, today));
    visits.addAll(history(steady[5].Id, today));
    visits.add(visit(spike[0].Id, today.addDays(-10), 'Completed', 'Fever', 38.4, null));
    visits.add(visit(spike[1].Id, today.addDays(-30), 'Completed', 'Fever', 38.4, null));
    for (Integer i = 0; i < 6; i++) {
        visits.add(visit(spike[Math.mod(i, 4)].Id, today.addDays(-Math.mod(i, 5)), 'Completed', 'Fever', 38.4, null));
        visits.add(visit(fresh[Math.mod(i, 4)].Id, today.addDays(-Math.mod(i, 5)), 'Completed', 'Fever', 38.4, null));
    }
    visits.add(visit(spike[0].Id, today.addDays(-1), 'Completed', 'Cough', null, null));
    visits.add(visit(spike[1].Id, today.addDays(-2), 'Completed', 'Breathlessness', null, null));
    visits.add(visit(spike[2].Id, today.addDays(-3), 'Completed', null, null, 93));
    for (Integer i = 0; i < 5; i++) {
        visits.add(visit(spike[i].Id, today.addDays(-i), 'Patient Not Available', null, null, null));
    }
    for (Integer i = 0; i < 3; i++) {
        visits.add(visit(steady[i].Id, today.addDays(-i), 'Patient Not Available', null, null, null));
    }
    for (Integer week = 0; week <= 4; week++) {
        visits.add(visit(steady[0].Id, today.addDays(-(week * 7) - 1), 'Completed', 'Fever', 38.4, null));
        visits.add(visit(steady[1].Id, today.addDays(-(week * 7) - 2), 'Completed', 'Fever', 38.4, null));
    }
    insert visits;
    List<Care_Activity__c> doses = new List<Care_Activity__c>();
    for (Integer i = 0; i < 4; i++) {
        Date due = today.addDays(-15 - i * 7);
        doses.add(new Care_Activity__c(Name = 'Verify on time ' + i, Patient__c = steady[i].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = due, Status__c = 'Completed', Completed_Date__c = due.addDays(1)));
    }
    for (Integer i = 0; i < 5; i++) {
        doses.add(new Care_Activity__c(Name = 'Verify dose ' + i, Patient__c = steady[Math.mod(i, 3)].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = today.addDays(-8 - i)));
    }
    insert doses;

    List<SentinelService.SignalResult> results = SentinelService.evaluate(today);
    SentinelService.SignalResult r = find(results, 'Verify Spike', 'Fever_Cluster');
    failures += mark(r != null && r.severity == 'Alert' && r.observed == 6 && r.households == 4,
        '2  Fever cluster is an Alert: ' + (r == null ? '(not found)' : r.explanation));
    r = find(results, 'Verify Spike', 'Respiratory_Cluster');
    failures += mark(r != null && r.observed == 3 && r.severity != 'Normal', '3  Respiratory cluster detected: ' + describe(r));
    r = find(results, 'Verify Spike', 'Failed_Visit_Surge');
    SentinelService.SignalResult small = find(results, 'Verify Steady', 'Failed_Visit_Surge');
    failures += mark(r != null && r.severity == 'Alert' && small != null && small.severity == 'Normal',
        '4  5 unreachable visits flagged (' + describe(r) + '); 3 not flagged (' + describe(small) + ')');
    r = find(results, 'Verify Steady', 'Immunisation_Delay');
    failures += mark(r != null && r.observed == 5 && r.severity != 'Normal', '5  Delayed vaccine doses detected: ' + describe(r));
    r = find(results, 'Verify Steady', 'Fever_Cluster');
    failures += mark(r != null && r.severity == 'Normal' && r.observed == 2, '6  Steady village is Normal: ' + describe(r));
    r = find(results, 'Verify New', 'Fever_Cluster');
    failures += mark(r != null && r.severity == 'Normal' && r.insufficientHistory, '7  Village with no history is not assessed: '
        + (r == null ? '(not found)' : r.explanation));

    SentinelService.scan(today, false);
    Id villageId = [SELECT Id FROM Village__c WHERE Name = 'Verify Spike'].Id;
    List<Community_Signal__c> recorded = [SELECT Id, Status__c FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Fever_Cluster'];
    Boolean firstOk = recorded.size() == 1 && recorded[0].Status__c == 'New';
    update new Community_Signal__c(Id = recorded[0].Id, Status__c = 'Investigating');
    SentinelService.scan(today, false);
    recorded = [SELECT Id, Status__c FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Fever_Cluster'];
    failures += mark(firstOk && recorded.size() == 1 && recorded[0].Status__c == 'Investigating',
        '8  One signal recorded; re-scan updated it (no duplicate) and kept "Investigating"');
    update new Community_Signal__c(Id = recorded[0].Id, Status__c = 'Closed', Investigation_Notes__c = 'verify');
    List<Community_Signal__c> respiratory = [SELECT Id FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Respiratory_Cluster'];
    if (!respiratory.isEmpty()) {
        update new Community_Signal__c(Id = respiratory[0].Id, Status__c = 'Dismissed', Investigation_Notes__c = 'verify');
    }
    SentinelService.scan(today, false);
    Community_Signal__c closed = [SELECT Status__c FROM Community_Signal__c WHERE Id = :recorded[0].Id];
    Integer feverRows = [SELECT COUNT() FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Fever_Cluster'];
    Integer respiratoryRows = [SELECT COUNT() FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Respiratory_Cluster'];
    failures += mark(closed.Status__c == 'Closed' && feverRows == 1 && respiratoryRows == 1,
        '9  Closed and dismissed signals left alone, not raised again');
    Integer newLogs = [SELECT COUNT() FROM Error_Log__c] - logsBefore;
    failures += mark(newLogs == 0, '10 No Error Log entries (' + newLogs + ')');
    return failures;
}

Savepoint sp = Database.setSavepoint();
Integer failures = 1;
try {
    failures = runChecks();
} catch (Exception e) {
    say('ERROR ' + e.getTypeName() + ': ' + e.getMessage() + ' | ' + e.getStackTraceString());
} finally {
    Database.rollback(sp);
}
say(failures == 0 ? 'INNOVATION VERIFY PASSED (10 checks, all test data rolled back)' : 'INNOVATION VERIFY: ' + failures + ' FAILURE(S) (rolled back)');
