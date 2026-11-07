// Phase 1 smoke test: proves formulas, auto-numbers, unique keys and validation rules behave.
// Everything is rolled back at the end, so no data is left in your org.
// Run: sf apex run --file scripts/apex/phase1-smoke-test.apex --target-org careloop
// Run it as your admin user WITHOUT the CareLoop Validation Bypass permission set.

String outcome(Database.SaveResult r) {
    return r.isSuccess() ? 'saved' : r.getErrors()[0].getMessage();
}

Integer mark(List<String> lines, Boolean ok, String label) {
    lines.add((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}

List<String> lines = new List<String>();
Integer failures = 0;
Savepoint sp = Database.setSavepoint();
try {
    Village__c village = new Village__c(Name = 'Smoke Test Village', District__c = 'Rangareddy',
        State__c = 'Telangana', Region__c = 'South');
    insert village;
    Account household = new Account(Name = 'Smoke Test Household', Village__c = village.Id);
    insert household;
    Contact patient = new Contact(FirstName = 'Smoke', LastName = 'Patient', AccountId = household.Id,
        Village__c = village.Id, Birthdate = Date.today().addYears(-30), Gender__c = 'Female',
        MobilePhone = '9848012345', Preferred_Language__c = 'Telugu', Preferred_Channel__c = 'Portal Inbox');
    insert patient;
    patient = [SELECT Id, Patient_Code__c, Age__c FROM Contact WHERE Id = :patient.Id];
    failures += mark(lines, patient.Patient_Code__c != null && patient.Patient_Code__c.startsWith('PT-'),
        'Patient code auto-number: ' + patient.Patient_Code__c);
    failures += mark(lines, patient.Age__c != null && patient.Age__c >= 29 && patient.Age__c <= 30,
        'Age formula: ' + patient.Age__c);

    Database.SaveResult r;
    r = Database.insert(new Contact(LastName = 'Bad Mobile', MobilePhone = '12345'), false);
    failures += mark(lines, !r.isSuccess(), 'Invalid mobile rejected: ' + outcome(r));
    r = Database.insert(new Contact(LastName = 'Male Pregnant', Gender__c = 'Male', Is_Pregnant__c = true), false);
    failures += mark(lines, !r.isSuccess(), 'Pregnancy for a male patient rejected: ' + outcome(r));

    Health_Visit__c visit = new Health_Visit__c(Patient__c = patient.Id, Visit_Date__c = System.now(),
        Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed', BP_Systolic__c = 130, BP_Diastolic__c = 85,
        Weight_Kg__c = 60, Height_Cm__c = 160);
    insert visit;
    visit = [SELECT Id, Name, BMI__c FROM Health_Visit__c WHERE Id = :visit.Id];
    failures += mark(lines, visit.Name.startsWith('VIS-'), 'Visit auto-number: ' + visit.Name);
    failures += mark(lines, visit.BMI__c != null && visit.BMI__c > 23 && visit.BMI__c < 24,
        'BMI formula (expect 23.4): ' + visit.BMI__c);

    r = Database.insert(new Health_Visit__c(Patient__c = patient.Id, Visit_Date__c = System.now(),
        Visit_Outcome__c = 'Completed', BP_Systolic__c = 120, BP_Diastolic__c = 130), false);
    failures += mark(lines, !r.isSuccess(), 'Diastolic above systolic rejected: ' + outcome(r));
    r = Database.insert(new Health_Visit__c(Patient__c = patient.Id, Visit_Date__c = System.now(),
        Visit_Outcome__c = 'Patient Not Available', BP_Systolic__c = 120, BP_Diastolic__c = 80), false);
    failures += mark(lines, !r.isSuccess(), 'Vitals on an unsuccessful visit rejected: ' + outcome(r));
    r = Database.insert(new Health_Visit__c(Patient__c = patient.Id, Visit_Date__c = System.now().addDays(1),
        Visit_Outcome__c = 'Completed'), false);
    failures += mark(lines, !r.isSuccess(), 'Future visit rejected: ' + outcome(r));

    r = Database.insert(new Care_Activity__c(Name = 'No due date', Patient__c = patient.Id,
        Activity_Type__c = 'Routine Check-up'), false);
    failures += mark(lines, !r.isSuccess(), 'Activity without due date rejected: ' + outcome(r));
    Care_Activity__c activity = new Care_Activity__c(Name = 'BP monitoring', Patient__c = patient.Id,
        Activity_Type__c = 'Routine Check-up', Due_Date__c = Date.today().addDays(7),
        Schedule_Key__c = patient.Id + '-SMOKE-1');
    r = Database.insert(activity, false);
    failures += mark(lines, r.isSuccess(), 'Valid activity saved: ' + outcome(r));
    r = Database.insert(new Care_Activity__c(Name = 'Duplicate key', Patient__c = patient.Id,
        Activity_Type__c = 'Routine Check-up', Due_Date__c = Date.today().addDays(7),
        Schedule_Key__c = patient.Id + '-SMOKE-1'), false);
    failures += mark(lines, !r.isSuccess(), 'Duplicate schedule key rejected: ' + outcome(r));
    r = Database.insert(new Care_Activity__c(Name = 'Completed without date', Patient__c = patient.Id,
        Activity_Type__c = 'Immunization', Due_Date__c = Date.today(), Status__c = 'Completed'), false);
    failures += mark(lines, !r.isSuccess(), 'Completed without a date rejected: ' + outcome(r));
    r = Database.insert(new Care_Activity__c(Name = 'Missed without approval', Patient__c = patient.Id,
        Activity_Type__c = 'Immunization', Due_Date__c = Date.today(), Status__c = 'Missed',
        Closure_Reason__c = 'Moved Away'), false);
    failures += mark(lines, !r.isSuccess(), 'Missed without supervisor approval rejected: ' + outcome(r));
    activity = [SELECT Is_Open__c, Is_Completed__c FROM Care_Activity__c WHERE Id = :activity.Id];
    failures += mark(lines, activity.Is_Open__c && activity.Is_Completed__c == 0,
        'Is Open / Is Completed formulas: ' + activity.Is_Open__c + ' / ' + activity.Is_Completed__c);

    r = Database.insert(new Medical_Recommendation__c(Outreach_Visit__c = visit.Id, Status__c = 'Final'), false);
    failures += mark(lines, !r.isSuccess(), 'Final recommendation without advice rejected: ' + outcome(r));
    Medical_Recommendation__c rec = new Medical_Recommendation__c(Outreach_Visit__c = visit.Id, Status__c = 'Draft',
        Advice__c = 'Reduce salt. Re-check BP in two weeks.');
    insert rec;
    rec = [SELECT Patient_Name__c FROM Medical_Recommendation__c WHERE Id = :rec.Id];
    failures += mark(lines, rec.Patient_Name__c == 'Smoke Patient', 'Patient name formula: ' + rec.Patient_Name__c);
} catch (Exception e) {
    lines.add('ERROR ' + e.getTypeName() + ': ' + e.getMessage() + ' at ' + e.getLineNumber());
    failures++;
} finally {
    Database.rollback(sp);
}
for (String line : lines) {
    System.debug(LoggingLevel.ERROR, line);
}
System.debug(LoggingLevel.ERROR, failures == 0
    ? 'PHASE 1 SMOKE TEST PASSED (all test data rolled back)'
    : 'PHASE 1 SMOKE TEST: ' + failures + ' FAILURE(S) (all test data rolled back)');
