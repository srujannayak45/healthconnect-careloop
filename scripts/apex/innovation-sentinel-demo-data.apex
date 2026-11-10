// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): community signal demo data (kept)
// =====================================================================================
// Adds SYNTHETIC (made-up, clearly tagged) visits and care activities to the Phase 4 demo villages so the early-warning scan
// has a realistic history and three clear signals to find:
//   * every village: 2 routine visits a week for 6 weeks (history) and a low background of fever and missed visits
//   * Kondapur   : RESPIRATORY CLUSTER - 4 visits with cough / breathlessness / SpO2 93 in the last 5 days
//   * Moinabad   : FEVER CLUSTER - 7 febrile visits from different households in the last 5 days
//   * Kandukur   : HOUSEHOLDS NOT REACHABLE - 6 visits "Patient Not Available" in the last 6 days
//   * Shamshabad : VACCINE DOSES DELAYED - 5 catch-up doses due 8-12 days ago not given
// Every record is tagged (visit Observations / activity Name start with "Sentinel demo") so innovation-remove-demo-data.apex can remove it.
// Requires phase4-demo-data.apex. Safe to re-run: stops if the tag already exists.
//
// Run:
//   sf apex run --file scripts/apex/innovation-sentinel-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'SENTINEL ' + line);
}

Integer nextInt(Integer bound) {
    Integer r = Crypto.getRandomInteger();
    return Math.mod(r < 0 ? -(r + 1) : r, bound);
}

Datetime at(Date day) {
    return Datetime.newInstance(day, Time.newInstance(10, 30, 0, 0));
}

Health_Visit__c feverVisit(Contact p, Date day, Decimal temperature) {
    return new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = at(day), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = 'Completed', Health_Worker__c = p.Assigned_Health_Worker__c,
        Symptoms__c = 'Fever;Headache', Temperature__c = temperature, Observations__c = 'Sentinel demo');
}

Health_Visit__c routineVisit(Contact p, Date day) {
    return new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = at(day), Visit_Type__c = 'Routine Check-up',
        Visit_Outcome__c = 'Completed', Health_Worker__c = p.Assigned_Health_Worker__c, Observations__c = 'Sentinel demo');
}

Health_Visit__c missedVisit(Contact p, Date day) {
    return new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = at(day), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = 'Patient Not Available', Health_Worker__c = p.Assigned_Health_Worker__c,
        Observations__c = 'Sentinel demo');
}

void run() {
    // Observations__c is a long text field (cannot be filtered in SOQL), so the tagged catch-up doses are the marker.
    if ([SELECT COUNT() FROM Care_Activity__c WHERE Name LIKE 'Sentinel demo%'] > 0) {
        say('EXISTS  | Sentinel demo data already loaded. Nothing changed.');
        return;
    }
    Date today = CareLoopClock.today();
    if (today > Date.today()) {
        // Visits dated after the real today would break the No_Future_Visit validation rule.
        say('STOP    | The CareLoop demo clock (Simulated Today = ' + today + ') is ahead of the real date. Clear it or set it to today first.');
        return;
    }
    Map<String, List<Contact>> adultsByVillage = new Map<String, List<Contact>>();
    Map<String, List<Contact>> childrenByVillage = new Map<String, List<Contact>>();
    for (Contact c : [SELECT Id, AccountId, Birthdate, Assigned_Health_Worker__c, Village__r.Name FROM Contact
                      WHERE Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur') AND Birthdate != null
                      ORDER BY AccountId]) {
        Map<String, List<Contact>> target = c.Birthdate <= today.addYears(-18) ? adultsByVillage : childrenByVillage;
        if (!target.containsKey(c.Village__r.Name)) {
            target.put(c.Village__r.Name, new List<Contact>());
        }
        target.get(c.Village__r.Name).add(c);
    }
    for (String v : new List<String>{ 'Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur' }) {
        if (!adultsByVillage.containsKey(v) || adultsByVillage.get(v).size() < 4) {
            say('STOP    | Not enough demo patients in ' + v + '. Run scripts/apex/phase4-demo-data.apex first.');
            return;
        }
    }

    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    // ---- normal background: 2 routine visits every week (this is the "history" Sentinel needs before it
    //      will assess a village), plus 0-1 fever and 0-1 missed visits per week in weeks 1-4
    for (String v : adultsByVillage.keySet()) {
        List<Contact> adults = adultsByVillage.get(v);
        for (Integer week = 0; week <= 5; week++) {
            visits.add(routineVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - 1 - nextInt(3))));
            visits.add(routineVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - 4 - nextInt(3))));
        }
        for (Integer week = 1; week <= 4; week++) {
            if (nextInt(3) > 0) {
                visits.add(feverVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - nextInt(6)), 38.1 + nextInt(8) / 10.0));
            }
            if (nextInt(2) == 0) {
                visits.add(missedVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - nextInt(6))));
            }
        }
    }
    // ---- Moinabad fever cluster: 7 visits in the last 5 days, one per household where possible
    List<Contact> moinabad = adultsByVillage.get('Moinabad');
    Set<Id> usedHouseholds = new Set<Id>();
    Integer added = 0;
    for (Contact c : moinabad) {
        if (added == 7) { break; }
        if (usedHouseholds.contains(c.AccountId) && usedHouseholds.size() < 5) { continue; }
        usedHouseholds.add(c.AccountId);
        visits.add(feverVisit(c, today.addDays(-1 - Math.mod(added, 5)), 38.2 + Math.mod(added * 3, 11) / 10.0));
        added++;
    }
    say('PLANNED | Moinabad fever cluster: ' + added + ' visits from ' + usedHouseholds.size() + ' households');
    // ---- Kondapur respiratory cluster: 4 visits in the last 5 days (cough, breathlessness, low SpO2)
    List<Contact> kondapur = adultsByVillage.get('Kondapur');
    List<String> respiratory = new List<String>{ 'Cough', 'Cough;Fever', 'Breathlessness', null };
    for (Integer i = 0; i < 4; i++) {
        Contact c = kondapur[Math.mod(i, kondapur.size())];
        visits.add(new Health_Visit__c(Patient__c = c.Id, Visit_Date__c = at(today.addDays(-1 - i)), Visit_Type__c = 'Home Visit',
            Visit_Outcome__c = 'Completed', Health_Worker__c = c.Assigned_Health_Worker__c, Symptoms__c = respiratory[i],
            Temperature__c = i == 1 ? 38.3 : null, SpO2__c = i == 3 ? 93 : null, Observations__c = 'Sentinel demo'));
    }
    // ---- Kandukur access problem: 6 "not available" visits in the last 6 days
    List<Contact> kandukur = adultsByVillage.get('Kandukur');
    for (Integer i = 0; i < 6; i++) {
        visits.add(missedVisit(kandukur[Math.mod(i, kandukur.size())], today.addDays(-1 - i)));
    }
    insert visits;
    say('CREATED | ' + visits.size() + ' synthetic visits (history + background + three clusters)');

    // ---- Shamshabad vaccine delay: catch-up doses; 4 on time in earlier weeks, 5 overdue now
    List<Contact> kids = childrenByVillage.containsKey('Shamshabad') ? childrenByVillage.get('Shamshabad') : adultsByVillage.get('Shamshabad');
    List<Care_Activity__c> doses = new List<Care_Activity__c>();
    for (Integer i = 0; i < 4; i++) {
        Date due = today.addDays(-15 - i * 7);
        doses.add(new Care_Activity__c(Name = 'Sentinel demo - catch-up dose ' + (i + 1), Patient__c = kids[Math.mod(i, kids.size())].Id,
            Activity_Type__c = 'Immunization', Due_Date__c = due, Source__c = 'Manual'));
    }
    for (Integer i = 0; i < 5; i++) {
        doses.add(new Care_Activity__c(Name = 'Sentinel demo - catch-up dose ' + (i + 5), Patient__c = kids[Math.mod(i, kids.size())].Id,
            Activity_Type__c = 'Immunization', Due_Date__c = today.addDays(-8 - i), Source__c = 'Manual'));
    }
    insert doses;
    List<Care_Activity__c> onTime = new List<Care_Activity__c>();
    for (Integer i = 0; i < 4; i++) {
        onTime.add(new Care_Activity__c(Id = doses[i].Id, Status__c = 'Completed', Completed_Date__c = doses[i].Due_Date__c.addDays(2)));
    }
    update onTime;
    say('CREATED | 9 catch-up doses in Shamshabad (4 given on time earlier, 5 now delayed)');
    say('FINISHED | Next: scripts/apex/innovation-run-scan.apex');
}

run();
