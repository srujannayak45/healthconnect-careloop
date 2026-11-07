/**
 * Nightly step 2: stores every patient's explainable priority on the Patient record
 * (Priority Score, Level, Explanation, Next Best Action, Open Care Gaps, Overdue Activities),
 * so list views, reports and dashboards can sort and group by it.
 * The Patient page shows the live score at any time (PatientPriorityController).
 */
public with sharing class PatientPriorityBatch implements Database.Batchable<SObject>, Database.Stateful {

    public static final Integer DEFAULT_SCOPE = 100;
    public Integer patientsScored = 0;
    public Integer failures = 0;

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            'SELECT Id FROM Contact WHERE Assigned_Health_Worker__c != null OR Priority_Score__c != null',
            AccessLevel.SYSTEM_MODE
        );
    }

    public void execute(Database.BatchableContext context, List<Contact> scope) {
        try {
            failures += store(new Map<Id, Contact>(scope).keySet());
            patientsScored += scope.size();
        } catch (Exception e) {
            failures++;
            ErrorLogger.log('PatientPriorityBatch', e, null);
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO, 'PatientPriorityBatch: scored=' + patientsScored + ' failures=' + failures);
    }

    /** Scores and saves these patients. Returns the number of rows that failed. */
    public static Integer store(Set<Id> patientIds) {
        Map<Id, PriorityScoringService.PatientScore> scores = PriorityScoringService.score(patientIds);
        List<Contact> updates = new List<Contact>();
        for (PriorityScoringService.PatientScore s : scores.values()) {
            updates.add(PriorityScoringService.toContact(s));
        }
        if (updates.isEmpty()) {
            return 0;
        }
        // Only derived fields change; the patient trigger has nothing to do, so skip it.
        TriggerHandler.bypass('ContactTriggerHandler');
        try {
            List<Database.SaveResult> results = Database.update(updates, false, AccessLevel.SYSTEM_MODE);
            ErrorLogger.logSaveResults('PatientPriorityBatch', results, updates);
            Integer failed = 0;
            for (Database.SaveResult r : results) {
                if (!r.isSuccess()) {
                    failed++;
                }
            }
            return failed;
        } finally {
            TriggerHandler.clearBypass('ContactTriggerHandler');
        }
    }
}
