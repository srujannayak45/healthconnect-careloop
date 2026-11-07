/**
 * The nightly care sweep (step 1 of the nightly chain).
 *
 * For every patient with open care it:
 *   1. moves each open activity to the right status for today (Scheduled -> Due -> Overdue)
 *      and refreshes Days Overdue, using the CareLoop clock (so the demo "time machine" works);
 *   2. climbs the escalation ladder (EscalationService): reminders, worker tasks, supervisor escalation;
 *   3. sends one bell notification per worker and per supervisor summarising their new items.
 * When it finishes it starts PatientPriorityBatch (step 2), unless told not to.
 *
 * Scope is patients (not activities), so each patient's items are evaluated together and a
 * caregiver gets one combined reminder. Default scope 50 patients per chunk.
 */
public with sharing class CareSweepBatch implements Database.Batchable<SObject>, Database.Stateful {

    public static final Integer DEFAULT_SCOPE = 50;
    private final Boolean chainPriority;

    public Integer patientsProcessed = 0;
    public Integer statusChanges = 0;
    public Integer remindersCreated = 0;
    public Integer tasksCreated = 0;
    public Integer failures = 0;

    public CareSweepBatch() {
        this(true);
    }

    public CareSweepBatch(Boolean chainPriority) {
        this.chainPriority = chainPriority;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Set<String> openStatuses = CareRules.OPEN_STATUSES;
        return Database.getQueryLocator(
            'SELECT Id FROM Contact WHERE Id IN (SELECT Patient__c FROM Care_Activity__c WHERE Status__c IN :openStatuses)',
            AccessLevel.SYSTEM_MODE
        );
    }

    public void execute(Database.BatchableContext context, List<Contact> scope) {
        try {
            run(new Map<Id, Contact>(scope).keySet());
        } catch (Exception e) {
            failures++;
            ErrorLogger.log('CareSweepBatch', e, null);
        }
    }

    public void finish(Database.BatchableContext context) {
        System.debug(LoggingLevel.INFO, 'CareSweepBatch: patients=' + patientsProcessed + ' statusChanges=' + statusChanges
            + ' reminders=' + remindersCreated + ' tasks=' + tasksCreated + ' failures=' + failures);
        if (chainPriority && !Test.isRunningTest()) {
            Database.executeBatch(new PatientPriorityBatch(), PatientPriorityBatch.DEFAULT_SCOPE);
        }
    }

    /** One sweep over these patients. Public so scripts and tests can run it synchronously. */
    public void run(Set<Id> patientIds) {
        Date today = CareLoopClock.today();
        Set<String> openStatuses = CareRules.OPEN_STATUSES;
        String query = 'SELECT ' + EscalationService.ACTIVITY_FIELDS
            + ' FROM Care_Activity__c WHERE Patient__c IN :patientIds AND Status__c IN :openStatuses ORDER BY Due_Date__c';
        List<Care_Activity__c> activities = Database.queryWithBinds(query,
            new Map<String, Object>{ 'patientIds' => patientIds, 'openStatuses' => openStatuses }, AccessLevel.SYSTEM_MODE);
        patientsProcessed += patientIds.size();

        Map<Id, Care_Activity__c> updates = new Map<Id, Care_Activity__c>();
        for (Care_Activity__c a : activities) {
            String status = CareRules.openStatusFor(a.Due_Date__c, today);
            Integer days = CareRules.daysOverdue(a.Due_Date__c, today);
            if (status != a.Status__c || days != a.Days_Overdue__c) {
                updates.put(a.Id, new Care_Activity__c(Id = a.Id, Status__c = status, Days_Overdue__c = days));
                a.Status__c = status;
                a.Days_Overdue__c = days;
                statusChanges++;
            }
        }

        EscalationService.Outcome outcome = EscalationService.evaluate(activities, today);
        for (Care_Activity__c change : outcome.activityUpdates.values()) {
            if (updates.containsKey(change.Id)) {
                Care_Activity__c merged = updates.get(change.Id);
                merged.Escalation_Level__c = change.Escalation_Level__c;
                merged.Last_Escalated_On__c = change.Last_Escalated_On__c;
                merged.Reminders_Sent__c = change.Reminders_Sent__c;
                merged.Next_Action__c = change.Next_Action__c;
            } else {
                updates.put(change.Id, change);
            }
        }
        if (!updates.isEmpty()) {
            List<Care_Activity__c> rows = updates.values();
            List<Database.SaveResult> results = Database.update(rows, false, AccessLevel.SYSTEM_MODE);
            failures += countFailures(results, rows, 'CareSweepBatch.activities', false);
        }
        if (!outcome.notifications.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(outcome.notifications, false, AccessLevel.SYSTEM_MODE);
            Integer failed = countFailures(results, outcome.notifications, 'CareSweepBatch.notifications', true);
            remindersCreated += outcome.notifications.size() - failed;
        }
        if (!outcome.tasks.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(outcome.tasks, false, AccessLevel.SYSTEM_MODE);
            Integer failed = countFailures(results, outcome.tasks, 'CareSweepBatch.tasks', false);
            tasksCreated += outcome.tasks.size() - failed;
            failures += failed;
        }
        for (Id userId : outcome.workerAlerts.keySet()) {
            Integer n = outcome.workerAlerts.get(userId);
            CareLoopAlertService.notify(new Set<Id>{ userId }, n + ' overdue care item(s) need your follow-up',
                'CareLoop created ' + n + ' follow-up task(s) for you today. Open Care Navigator or your Tasks.',
                outcome.alertTarget.get(userId));
        }
        for (Id userId : outcome.supervisorAlerts.keySet()) {
            Integer n = outcome.supervisorAlerts.get(userId);
            CareLoopAlertService.notify(new Set<Id>{ userId }, n + ' care item(s) escalated to you',
                n + ' activities are more than ' + supervisorDays() + ' days overdue. See your Tasks.',
                outcome.alertTarget.get(userId));
        }
    }

    /** Counts real failures; a duplicate key (already created by an earlier run) is not a failure. */
    private static Integer countFailures(List<Database.SaveResult> results, List<SObject> rows, String source,
                                         Boolean duplicatesAreFine) {
        Integer failed = 0;
        List<Database.SaveResult> toLog = new List<Database.SaveResult>();
        List<SObject> rowsToLog = new List<SObject>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                continue;
            }
            failed++;
            Boolean duplicate = false;
            for (Database.Error e : results[i].getErrors()) {
                if (e.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
                    duplicate = true;
                }
            }
            if (!(duplicate && duplicatesAreFine)) {
                toLog.add(results[i]);
                rowsToLog.add(rows[i]);
            }
        }
        if (!toLog.isEmpty()) {
            ErrorLogger.logSaveResults(source, toLog, rowsToLog);
        }
        return failed;
    }

    private static Integer supervisorDays() {
        for (Escalation_Rule__mdt r : CareRules.activeEscalationRules()) {
            if (r.Action__c == EscalationService.ACTION_SUPERVISOR && r.Days_From_Due__c != null) {
                return r.Days_From_Due__c.intValue();
            }
        }
        return 10;
    }
}
