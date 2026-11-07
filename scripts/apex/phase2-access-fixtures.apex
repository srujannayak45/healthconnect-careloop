// =====================================================================================
// HealthConnect CareLoop - Phase 2: create the access-test records
// =====================================================================================
// Creates a small, clearly labelled set of synthetic records so we can prove who sees what:
//   * 1 village       "ZZ Access Test Village"            (Village: public read-only)
//   * 2 households    North (owned by Lakshmi), South (owned by Sunita)
//   * 1 patient, 1 outreach visit and 1 care activity in each household
//   * 1 error log     source "ZZ Access Test"             (private; only managers/admins)
// These records are committed (kept) so you can also check them with "Login As".
// Remove them afterwards with scripts/apex/phase2-remove-access-fixtures.apex.
// Safe to re-run: if the test village already exists, nothing is created.
//
// Run:
//   sf apex run --file scripts/apex/phase2-access-fixtures.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'FIXTURE ' + line);
}

String usernameFor(String first, String last) {
    return (first + '.' + last + '.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
}

void run() {
    String lakshmiUsername = usernameFor('Lakshmi', 'Devi');
    String sunitaUsername = usernameFor('Sunita', 'Rao');
    List<String> usernames = new List<String>{ lakshmiUsername, sunitaUsername };
    Map<String, Id> userIds = new Map<String, Id>();
    for (User u : [SELECT Id, Username FROM User WHERE IsActive = true AND Username IN :usernames]) {
        userIds.put(u.Username.toLowerCase(), u.Id);
    }
    if (userIds.size() != 2) {
        say('STOP | Lakshmi and Sunita must exist and be active. Run phase2-provision-users.apex first.');
        return;
    }
    Id lakshmi = userIds.get(lakshmiUsername);
    Id sunita = userIds.get(sunitaUsername);

    if ([SELECT COUNT() FROM Village__c WHERE Name = 'ZZ Access Test Village'] > 0) {
        say('EXISTS | The access-test records already exist. Nothing created.');
        return;
    }

    Village__c village = new Village__c(Name = 'ZZ Access Test Village', District__c = 'Test District',
        State__c = 'Telangana', Region__c = 'North');
    insert village;

    List<Account> households = new List<Account>{
        new Account(Name = 'ZZ Access Test - North Household', Village__c = village.Id, OwnerId = lakshmi),
        new Account(Name = 'ZZ Access Test - South Household', Village__c = village.Id, OwnerId = sunita)
    };
    insert households;

    List<Contact> patients = new List<Contact>{
        new Contact(FirstName = 'North', LastName = 'Access Test Patient', AccountId = households[0].Id,
            OwnerId = lakshmi, Village__c = village.Id, Birthdate = Date.today().addYears(-40), Gender__c = 'Female',
            Assigned_Health_Worker__c = lakshmi, Preferred_Language__c = 'English', Preferred_Channel__c = 'Portal Inbox'),
        new Contact(FirstName = 'South', LastName = 'Access Test Patient', AccountId = households[1].Id,
            OwnerId = sunita, Village__c = village.Id, Birthdate = Date.today().addYears(-40), Gender__c = 'Female',
            Assigned_Health_Worker__c = sunita, Preferred_Language__c = 'English', Preferred_Channel__c = 'Portal Inbox')
    };
    insert patients;

    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    List<Care_Activity__c> activities = new List<Care_Activity__c>();
    for (Contact p : patients) {
        visits.add(new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = System.now(), Visit_Type__c = 'Home Visit',
            Visit_Outcome__c = 'Completed', BP_Systolic__c = 120, BP_Diastolic__c = 80));
        activities.add(new Care_Activity__c(Name = 'Access test check-up', Patient__c = p.Id,
            Activity_Type__c = 'Routine Check-up', Due_Date__c = Date.today().addDays(30)));
    }
    insert visits;
    insert activities;

    insert new Error_Log__c(Source__c = 'ZZ Access Test', Severity__c = 'Warning',
        Message__c = 'Synthetic record used by phase2-verify-security.apex. Safe to delete.');

    say('CREATED | village ' + village.Id);
    say('CREATED | North household ' + households[0].Id + ' owned by Lakshmi Devi');
    say('CREATED | South household ' + households[1].Id + ' owned by Sunita Rao');
    say('CREATED | 2 patients, 2 outreach visits, 2 care activities, 1 error log');
    say('FINISHED | Next: run scripts/apex/phase2-verify-security.apex');
}

run();
