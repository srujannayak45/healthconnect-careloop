// =====================================================================================
// HealthConnect CareLoop - Phase 3: create the first demo household (kept in your org)
// =====================================================================================
// Creates synthetic demo records owned by health worker Lakshmi Devi:
//   * Village "Kondapur" (North), served by Lakshmi
//   * Household "Rao Household" with three patients:
//       Ananya Rao  - 75-day-old baby        -> immunisation schedule (some doses overdue)
//       Kavya Rao   - 26, pregnant            -> antenatal check-ups
//       Venkat Rao  - 62, hypertension        -> BP monitoring + annual screening
// The patient trigger queues the schedule generation as a BACKGROUND JOB, exactly as when a
// health worker registers patients in the app. Watch it in Setup > Apex Jobs.
// All names and numbers are invented. Safe to re-run: existing records are reused.
//
// Run:
//   sf apex run --file scripts/apex/phase3-demo-household.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'DEMO ' + line);
}

void run() {
    String lakshmiUsername = ('Lakshmi.Devi.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
    List<User> lakshmi = [SELECT Id FROM User WHERE Username = :lakshmiUsername AND IsActive = true];
    if (lakshmi.isEmpty()) {
        say('STOP | Lakshmi Devi was not found. Complete Phase 2 (phase2-provision-users.apex) first.');
        return;
    }
    Id worker = lakshmi[0].Id;

    List<Village__c> villages = [SELECT Id FROM Village__c WHERE Name = 'Kondapur' LIMIT 1];
    Village__c village;
    if (villages.isEmpty()) {
        village = new Village__c(Name = 'Kondapur', District__c = 'Rangareddy', State__c = 'Telangana', Region__c = 'North',
            Population__c = 5200, Health_Worker__c = worker, Active__c = true,
            Location__Latitude__s = 17.4600, Location__Longitude__s = 78.3570);
        insert village;
        say('CREATED | Village Kondapur');
    } else {
        village = villages[0];
        say('EXISTS  | Village Kondapur');
    }

    List<Account> households = [SELECT Id FROM Account WHERE Name = 'Rao Household' LIMIT 1];
    if (!households.isEmpty()) {
        say('EXISTS  | Rao Household already exists. Nothing else created.');
        say('FINISHED | Open the Households tab (or Login As Lakshmi Devi) to see it.');
        return;
    }
    Account household = new Account(Name = 'Rao Household', Village__c = village.Id, OwnerId = worker);
    insert household;

    List<Contact> patients = new List<Contact>{
        new Contact(FirstName = 'Ananya', LastName = 'Rao', AccountId = household.Id, OwnerId = worker,
            Village__c = village.Id, Birthdate = Date.today().addDays(-75), Gender__c = 'Female',
            Preferred_Language__c = 'Telugu', Preferred_Channel__c = 'Portal Inbox'),
        new Contact(FirstName = 'Kavya', LastName = 'Rao', AccountId = household.Id, OwnerId = worker,
            Village__c = village.Id, Birthdate = Date.today().addYears(-26), Gender__c = 'Female',
            Is_Pregnant__c = true, Expected_Delivery_Date__c = Date.today().addDays(150),
            MobilePhone = '9000000101', Preferred_Language__c = 'Telugu', Preferred_Channel__c = 'SMS'),
        new Contact(FirstName = 'Venkat', LastName = 'Rao', AccountId = household.Id, OwnerId = worker,
            Village__c = village.Id, Birthdate = Date.today().addYears(-62), Gender__c = 'Male',
            Chronic_Conditions__c = 'Hypertension', MobilePhone = '9000000102',
            Preferred_Language__c = 'Hindi', Preferred_Channel__c = 'Portal Inbox')
    };
    insert patients;

    say('CREATED | Rao Household ' + household.Id + ' owned by Lakshmi Devi');
    for (Contact p : patients) {
        say('CREATED | Patient ' + p.FirstName + ' ' + p.LastName + ' ' + p.Id);
    }
    say('QUEUED  | Care schedule generation runs as a background job within a minute (Setup > Apex Jobs).');
    say('FINISHED | Next: open each patient > Related > Care Activities.');
}

run();
