// =====================================================================================
// HealthConnect CareLoop - Phase 4: realistic multi-village demo data (kept in your org)
// =====================================================================================
// Creates SYNTHETIC data for four villages so the radar, escalation ladder, dashboards and the
// Care Navigator have something real to work on:
//   North (Lakshmi Devi): Kondapur (good coverage), Moinabad (poor coverage - the "hotspot")
//   South (Sunita Rao)  : Shamshabad (good coverage), Kandukur (medium coverage)
// 24 households, ~75 patients: young families with infants and pregnant mothers, elders with
// hypertension/diabetes, adults due for screening. Past vaccine doses are partly completed
// (coverage differs by village), some visits failed, two visits are red-flagged.
// It also links Ananya Rao to her caregiver Kavya and records reminder consent for the Rao family.
// All names and phone numbers are invented. Safe to re-run: if demo households exist it stops.
//
// Run:
//   sf apex run --file scripts/apex/phase4-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'DEMO ' + line);
}

Integer nextInt(Integer bound) {
    Integer r = Crypto.getRandomInteger();
    return Math.mod(r < 0 ? -(r + 1) : r, bound);
}

User userFor(String first, String last) {
    String username = (first + '.' + last + '.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
    List<User> users = [SELECT Id FROM User WHERE Username = :username AND IsActive = true];
    return users.isEmpty() ? null : users[0];
}

Village__c village(String name, String region, Id worker, Decimal lat, Decimal lng, Integer population) {
    List<Village__c> existing = [SELECT Id, Name, Location__Latitude__s, Location__Longitude__s FROM Village__c WHERE Name = :name LIMIT 1];
    if (!existing.isEmpty()) {
        Village__c v = existing[0];
        if (v.Location__Latitude__s == null) {
            update new Village__c(Id = v.Id, Location__Latitude__s = lat, Location__Longitude__s = lng);
        }
        return v;
    }
    Village__c v = new Village__c(Name = name, Region__c = region, District__c = 'Rangareddy', State__c = 'Telangana',
        Population__c = population, Health_Worker__c = worker, Active__c = true,
        Location__Latitude__s = lat, Location__Longitude__s = lng);
    insert v;
    return v;
}

void linkRaoFamily() {
    List<Contact> rao = [SELECT Id, FirstName FROM Contact WHERE Account.Name = 'Rao Household'];
    Map<String, Contact> byName = new Map<String, Contact>();
    for (Contact c : rao) {
        byName.put(c.FirstName, c);
    }
    if (!byName.containsKey('Kavya') || !byName.containsKey('Ananya')) {
        say('INFO    | Rao Household not found (phase3-demo-household.apex); skipped linking it.');
        return;
    }
    List<Contact> updates = new List<Contact>{
        new Contact(Id = byName.get('Ananya').Id, Caregiver__c = byName.get('Kavya').Id),
        new Contact(Id = byName.get('Kavya').Id, Reminder_Consent__c = true)
    };
    if (byName.containsKey('Venkat')) {
        updates.add(new Contact(Id = byName.get('Venkat').Id, Reminder_Consent__c = true));
    }
    update updates;
    say('UPDATED | Rao Household: Kavya is Ananya\'s caregiver; reminder consent recorded for Kavya and Venkat');
}

void run() {
    User lakshmi = userFor('Lakshmi', 'Devi');
    User sunita = userFor('Sunita', 'Rao');
    if (lakshmi == null || sunita == null) {
        say('STOP    | Lakshmi Devi and Sunita Rao must exist (Phase 2).');
        return;
    }
    linkRaoFamily();
    if ([SELECT COUNT() FROM Account WHERE Name LIKE 'Demo - %'] > 0) {
        say('EXISTS  | Demo households already exist. Nothing else created.');
        say('FINISHED');
        return;
    }
    Date today = CareLoopClock.today();

    List<Village__c> villages = new List<Village__c>{
        village('Kondapur', 'North', lakshmi.Id, 17.4600, 78.3570, 5200),
        village('Moinabad', 'North', lakshmi.Id, 17.3290, 78.2660, 4100),
        village('Shamshabad', 'South', sunita.Id, 17.2630, 78.3960, 6300),
        village('Kandukur', 'South', sunita.Id, 17.1520, 78.5370, 3900)
    };
    Map<Id, Id> workerOf = new Map<Id, Id>{
        villages[0].Id => lakshmi.Id, villages[1].Id => lakshmi.Id, villages[2].Id => sunita.Id, villages[3].Id => sunita.Id
    };
    Map<Id, Decimal> coverage = new Map<Id, Decimal>{
        villages[0].Id => 0.85, villages[1].Id => 0.40, villages[2].Id => 0.80, villages[3].Id => 0.60
    };
    List<String> surnames = new List<String>{ 'Reddy', 'Goud', 'Yadav', 'Naidu', 'Chary', 'Shaik', 'Banoth', 'Mudiraj',
        'Varma', 'Achari', 'Kumar', 'Patel', 'Pasha', 'Gowda', 'Nayak', 'Sharma', 'Pillai', 'Joshi', 'Khan', 'Raju',
        'Mallesh', 'Babu', 'Prasad', 'Swamy' };
    List<String> women = new List<String>{ 'Lavanya', 'Swathi', 'Padma', 'Sarita', 'Anitha', 'Bhavani', 'Kalpana', 'Rekha',
        'Sujatha', 'Divya', 'Haritha', 'Manjula' };
    List<String> men = new List<String>{ 'Ramesh', 'Srinivas', 'Mahesh', 'Ravi', 'Naresh', 'Venkatesh', 'Prakash', 'Suresh',
        'Anil', 'Raju', 'Kiran', 'Gopal' };
    List<String> babies = new List<String>{ 'Aarav', 'Diya', 'Ishaan', 'Meera', 'Vihaan', 'Anika', 'Arjun', 'Saanvi' };
    List<String> elders = new List<String>{ 'Lakshmamma', 'Narsimha', 'Yadamma', 'Ramulu', 'Sathyamma', 'Pentaiah' };
    List<String> languages = new List<String>{ 'Telugu', 'Telugu', 'Hindi', 'English' };
    List<String> channels = new List<String>{ 'Portal Inbox', 'SMS', 'Portal Inbox', 'SMS' };

    // ---- households
    List<Account> households = new List<Account>();
    Integer s = 0;
    for (Village__c v : villages) {
        for (Integer h = 0; h < 6; h++) {
            households.add(new Account(Name = 'Demo - ' + surnames[s] + ' Household (' + v.Name + ')',
                Village__c = v.Id, OwnerId = workerOf.get(v.Id)));
            s++;
        }
    }
    insert households;

    // ---- patients: kind 0 = young family, 1 = elders, 2 = working adults
    List<Contact> patients = new List<Contact>();
    Map<Integer, Integer> motherIndexOfBaby = new Map<Integer, Integer>();
    Integer phone = 0;
    for (Integer i = 0; i < households.size(); i++) {
        Account hh = households[i];
        String surname = surnames[i];
        Id worker = workerOf.get(hh.Village__c);
        String language = languages[nextInt(languages.size())];
        String channel = channels[nextInt(channels.size())];
        Integer kind = Math.mod(i, 3);
        List<Contact> members = new List<Contact>();
        if (kind == 0) {
            Boolean pregnant = nextInt(2) == 0;
            Contact mother = new Contact(FirstName = women[nextInt(women.size())], LastName = surname,
                Birthdate = today.addYears(-(22 + nextInt(9))).addDays(-nextInt(300)), Gender__c = 'Female',
                Is_Pregnant__c = pregnant, Expected_Delivery_Date__c = pregnant ? today.addDays(40 + nextInt(180)) : null);
            members.add(mother);
            motherIndexOfBaby.put(patients.size() + 1, patients.size());
            members.add(new Contact(FirstName = babies[nextInt(babies.size())], LastName = surname,
                Birthdate = today.addDays(-(30 + nextInt(420))), Gender__c = nextInt(2) == 0 ? 'Female' : 'Male'));
            members.add(new Contact(FirstName = men[nextInt(men.size())], LastName = surname,
                Birthdate = today.addYears(-(28 + nextInt(10))), Gender__c = 'Male'));
        } else if (kind == 1) {
            members.add(new Contact(FirstName = elders[nextInt(elders.size())], LastName = surname,
                Birthdate = today.addYears(-(60 + nextInt(12))), Gender__c = 'Female', Chronic_Conditions__c = 'Diabetes'));
            members.add(new Contact(FirstName = elders[nextInt(elders.size())], LastName = surname,
                Birthdate = today.addYears(-(62 + nextInt(12))), Gender__c = 'Male', Chronic_Conditions__c = 'Hypertension'));
            members.add(new Contact(FirstName = women[nextInt(women.size())], LastName = surname,
                Birthdate = today.addYears(-(32 + nextInt(8))), Gender__c = 'Female'));
        } else {
            members.add(new Contact(FirstName = men[nextInt(men.size())], LastName = surname,
                Birthdate = today.addYears(-(40 + nextInt(15))), Gender__c = 'Male', Chronic_Conditions__c = 'Hypertension;Diabetes'));
            members.add(new Contact(FirstName = women[nextInt(women.size())], LastName = surname,
                Birthdate = today.addYears(-(35 + nextInt(10))), Gender__c = 'Female'));
        }
        for (Contact c : members) {
            phone++;
            c.AccountId = hh.Id;
            c.Village__c = hh.Village__c;
            c.Assigned_Health_Worker__c = worker;
            c.OwnerId = worker;
            c.Preferred_Language__c = language;
            c.Preferred_Channel__c = channel;
            c.Reminder_Consent__c = nextInt(100) < 85;
            Boolean isChild = c.Birthdate > today.addYears(-18);
            c.MobilePhone = isChild ? null : '9' + String.valueOf(700000000 + phone * 7919);
            patients.add(c);
        }
    }
    TriggerHandler.bypass('ContactTriggerHandler');   // schedules are generated below, in this transaction
    insert patients;
    List<Contact> caregiverLinks = new List<Contact>();
    for (Integer babyIndex : motherIndexOfBaby.keySet()) {
        caregiverLinks.add(new Contact(Id = patients[babyIndex].Id, Caregiver__c = patients[motherIndexOfBaby.get(babyIndex)].Id));
    }
    update caregiverLinks;
    TriggerHandler.clearBypass('ContactTriggerHandler');
    say('CREATED | ' + households.size() + ' households and ' + patients.size() + ' patients in 4 villages');

    Set<Id> patientIds = new Map<Id, Contact>(patients).keySet();
    Integer generated = CareScheduleService.generate(patientIds);
    say('CREATED | ' + generated + ' care activities from the care schedules');

    // ---- history: adults were registered months ago, so shift their monitoring/screening back in time;
    //      complete past items according to the village's coverage.
    Map<Id, Contact> patientById = new Map<Id, Contact>(patients);
    List<Care_Activity__c> changes = new List<Care_Activity__c>();
    Integer completed = 0;
    for (Care_Activity__c a : [SELECT Id, Patient__c, Activity_Type__c, Due_Date__c, Source__c FROM Care_Activity__c
                               WHERE Patient__c IN :patientIds ORDER BY Due_Date__c]) {
        Contact p = patientById.get(a.Patient__c);
        Date due = a.Due_Date__c;
        if (a.Activity_Type__c == 'Routine Check-up') {
            due = due.addDays(-(25 + nextInt(50)));
        }
        Decimal cover = coverage.get(p.Village__c);
        Care_Activity__c change = new Care_Activity__c(Id = a.Id, Due_Date__c = due);
        Boolean pastDue = due < today.addDays(-2);
        if (pastDue && nextInt(100) < cover * 100) {
            Date doneOn = due.addDays(nextInt(6));
            change.Status__c = 'Completed';
            change.Completed_Date__c = doneOn > today ? today : doneOn;
            completed++;
        }
        changes.add(change);
    }
    update changes;
    say('UPDATED | ' + completed + ' past activities completed (coverage differs by village)');

    // ---- visits: a recent successful visit for many adults, failed attempts in the two weaker
    //      villages, and two red-flag visits waiting for the doctor.
    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    Contact northElder;
    Contact southChronic;
    for (Contact p : patients) {
        if (northElder == null && p.Village__c == villages[1].Id && p.Chronic_Conditions__c != null
                && p.Chronic_Conditions__c.contains('Hypertension')) {
            northElder = p;
            continue;
        }
        if (southChronic == null && p.Village__c == villages[3].Id && p.Chronic_Conditions__c != null) {
            southChronic = p;
            continue;
        }
        Boolean adult = p.Birthdate <= today.addYears(-18);
        if (!adult || nextInt(100) < 45) {
            continue;
        }
        Boolean weaker = p.Village__c == villages[1].Id || p.Village__c == villages[3].Id;
        Datetime visitTime = Datetime.newInstance(today.addDays(-(5 + nextInt(70))), Time.newInstance(10, 30, 0, 0));
        if (weaker && nextInt(100) < 50) {
            visits.add(new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = visitTime, Visit_Type__c = 'Home Visit',
                Visit_Outcome__c = 'Patient Not Available', Health_Worker__c = p.Assigned_Health_Worker__c));
        } else {
            visits.add(new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = visitTime, Visit_Type__c = 'Home Visit',
                Visit_Outcome__c = 'Completed', Health_Worker__c = p.Assigned_Health_Worker__c,
                BP_Systolic__c = 118 + nextInt(25), BP_Diastolic__c = 76 + nextInt(12), SpO2__c = 96 + nextInt(3),
                Pulse__c = 70 + nextInt(15)));
        }
    }
    insert visits;
    say('CREATED | ' + visits.size() + ' past visits (completed and unsuccessful)');
    List<Health_Visit__c> redFlagVisits = new List<Health_Visit__c>();
    if (northElder != null) {
        redFlagVisits.add(new Health_Visit__c(Patient__c = northElder.Id, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed',
            Visit_Date__c = Datetime.newInstance(today.addDays(-2), Time.newInstance(11, 0, 0, 0)),
            Health_Worker__c = northElder.Assigned_Health_Worker__c, BP_Systolic__c = 184, BP_Diastolic__c = 114, SpO2__c = 96));
    }
    if (southChronic != null) {
        redFlagVisits.add(new Health_Visit__c(Patient__c = southChronic.Id, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed',
            Visit_Date__c = Datetime.newInstance(today.addDays(-1), Time.newInstance(15, 0, 0, 0)),
            Health_Worker__c = southChronic.Assigned_Health_Worker__c, BP_Systolic__c = 132, BP_Diastolic__c = 84,
            SpO2__c = 89, Temperature__c = 39.8));
    }
    insert redFlagVisits;
    say('CREATED | ' + redFlagVisits.size() + ' red-flag visits waiting for Dr Arjun (Moinabad and Kandukur)');

    // ---- one patient asked for help in reply to a reminder
    List<Care_Activity__c> openOnes = [SELECT Id FROM Care_Activity__c WHERE Patient__c IN :patientIds
                                       AND Status__c = 'Overdue' AND Patient__r.Village__c = :villages[1].Id LIMIT 1];
    if (!openOnes.isEmpty()) {
        update new Care_Activity__c(Id = openOnes[0].Id, Patient_Response__c = 'Need Help', Patient_Response_Date__c = today);
        say('UPDATED | One Moinabad patient replied "Need Help"');
    }
    say('FINISHED | Next: run scripts/apex/phase4-run-sweep-now.apex');
}

run();
