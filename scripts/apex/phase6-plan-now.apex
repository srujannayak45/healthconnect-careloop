// =====================================================================================
// HealthConnect CareLoop - Phase 6: build today's Navigator plans now (Lakshmi and Sunita)
// =====================================================================================
// Builds (or re-builds, while untouched) today's household visit plan for both health workers
// and prints each plan's predicted impact against a plain due-date list. Safe to re-run.
//
// Run:
//   sf apex run --file scripts/apex/phase6-plan-now.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'NAVIGATOR ' + line);
}
Set<String> usernames = new Set<String>();
for (String name : new List<String>{ 'lakshmi.devi', 'sunita.rao' }) {
    usernames.add((name + '.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo');
}
Map<Id, User> workers = new Map<Id, User>([SELECT Id, Name FROM User WHERE Username IN :usernames AND IsActive = true]);
if (workers.isEmpty()) {
    say('STOP | Lakshmi Devi / Sunita Rao not found (Phase 2).');
} else {
    Date today = CareLoopClock.today();
    Map<Id, Id> plans = NavigatorService.generate(workers.keySet(), today);
    NavigatorService.refreshProgress(new Set<Id>(plans.values()));
    for (Visit_Plan__c p : [SELECT Name, Planned_Stops__c, Gaps_Targeted__c, Baseline_Gaps__c, Gap_Gain_Percent__c,
                                   Urgency_Targeted__c, Baseline_Urgency__c, Total_Distance_Km__c, Baseline_Distance_Km__c,
                                   (SELECT Sequence__c, Name, Gaps_Targeted__c, Urgency_Score__c, Patients__c FROM Stops__r ORDER BY Sequence__c)
                            FROM Visit_Plan__c WHERE Id IN :plans.values()]) {
        say('PLAN  | ' + p.Name + ' | ' + p.Planned_Stops__c + ' visits | ' + p.Gaps_Targeted__c + ' gaps (due-date list: '
            + p.Baseline_Gaps__c + ', gain ' + p.Gap_Gain_Percent__c + '%) | urgency ' + p.Urgency_Targeted__c + ' vs '
            + p.Baseline_Urgency__c + ' | ' + p.Total_Distance_Km__c + ' km vs ' + p.Baseline_Distance_Km__c + ' km');
        for (Visit_Plan_Stop__c s : p.Stops__r) {
            say('  STOP ' + s.Name + ' | ' + s.Gaps_Targeted__c + ' gaps | urgency ' + s.Urgency_Score__c + ' | ' + s.Patients__c);
        }
    }
    say('FINISHED | CareLoop today = ' + today + '. Open the Care Navigator tab as Lakshmi Devi.');
}
