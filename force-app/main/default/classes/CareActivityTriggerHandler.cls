/**
 * Care Activity automation: keeps every activity's status honest against the CareLoop clock.
 *
 * before insert : default Source (Manual) and the assignee (the patient's health worker);
 *                 set the status of open activities from the due date (Scheduled / Due / Overdue)
 *                 and Days_Overdue__c; start the escalation counters at zero.
 * before update : when an activity is closed (Completed, Missed, Cancelled) reset Days Overdue,
 *                 the escalation pause and the next action; when an open activity is rescheduled
 *                 or re-opened, recalculate its status.
 * after update  : when an activity is closed, close its open follow-up Tasks (created by the
 *                 escalation ladder in Phase 5), so nobody chases care that already happened.
 * The nightly Care Gap Radar (Phase 4) moves open activities from Scheduled to Due to Overdue
 * as time passes.
 */
public with sharing class CareActivityTriggerHandler extends TriggerHandler {

    public static final String SOURCE_MANUAL = 'Manual';

    protected override void beforeInsert(List<SObject> newRecords) {
        List<Care_Activity__c> activities = (List<Care_Activity__c>) newRecords;
        defaultAssignee(activities);
        Date today = CareLoopClock.today();
        for (Care_Activity__c activity : activities) {
            if (activity.Source__c == null) {
                activity.Source__c = SOURCE_MANUAL;
            }
            if (activity.Escalation_Level__c == null) {
                activity.Escalation_Level__c = 0;
            }
            if (activity.Reminders_Sent__c == null) {
                activity.Reminders_Sent__c = 0;
            }
            if (CareRules.isOpen(activity.Status__c)) {
                refreshOpenStatus(activity, today);
            } else {
                activity.Days_Overdue__c = 0;
            }
        }
    }

    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        Date today = CareLoopClock.today();
        for (Care_Activity__c activity : (List<Care_Activity__c>) newRecords) {
            Care_Activity__c old = (Care_Activity__c) oldMap.get(activity.Id);
            Boolean closedNow = CareRules.isClosed(activity.Status__c) && !CareRules.isClosed(old.Status__c);
            Boolean reopened = CareRules.isOpen(activity.Status__c) && CareRules.isClosed(old.Status__c);
            Boolean rescheduled = CareRules.isOpen(activity.Status__c) && activity.Due_Date__c != old.Due_Date__c;
            if (closedNow) {
                activity.Days_Overdue__c = 0;
                activity.Escalation_Paused_Until__c = null;
                activity.Next_Action__c = null;
            } else if (reopened || rescheduled) {
                refreshOpenStatus(activity, today);
            }
        }
    }

    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        Set<Id> closedIds = new Set<Id>();
        for (Care_Activity__c activity : (List<Care_Activity__c>) newRecords) {
            Care_Activity__c old = (Care_Activity__c) oldMap.get(activity.Id);
            if (CareRules.isClosed(activity.Status__c) && !CareRules.isClosed(old.Status__c)) {
                closedIds.add(activity.Id);
            }
        }
        closeOpenTasks(closedIds);
    }

    private static void refreshOpenStatus(Care_Activity__c activity, Date today) {
        activity.Status__c = CareRules.openStatusFor(activity.Due_Date__c, today);
        activity.Days_Overdue__c = CareRules.daysOverdue(activity.Due_Date__c, today);
    }

    private static void defaultAssignee(List<Care_Activity__c> activities) {
        Set<Id> patientIds = new Set<Id>();
        for (Care_Activity__c activity : activities) {
            if (activity.Assigned_To__c == null && activity.Patient__c != null) {
                patientIds.add(activity.Patient__c);
            }
        }
        if (patientIds.isEmpty()) {
            return;
        }
        Map<Id, Contact> patients = new Map<Id, Contact>([
            SELECT Id, Assigned_Health_Worker__c FROM Contact WHERE Id IN :patientIds WITH SYSTEM_MODE
        ]);
        for (Care_Activity__c activity : activities) {
            Contact patient = activity.Patient__c == null ? null : patients.get(activity.Patient__c);
            if (activity.Assigned_To__c == null && patient != null) {
                activity.Assigned_To__c = patient.Assigned_Health_Worker__c;
            }
        }
    }

    private static void closeOpenTasks(Set<Id> activityIds) {
        if (activityIds.isEmpty()) {
            return;
        }
        new TaskCloser().closeFor(activityIds);
    }

    /**
     * Runs WITHOUT SHARING on purpose, and only here: when a health worker completes an activity,
     * the escalation task sitting with her supervisor (which she cannot see) must close too.
     * It touches nothing but open Tasks linked to the activities that were just closed.
     */
    private without sharing class TaskCloser {
        public void closeFor(Set<Id> activityIds) {
            List<Task> openTasks = [
                SELECT Id, Status FROM Task WHERE WhatId IN :activityIds AND IsClosed = false WITH SYSTEM_MODE
            ];
            if (openTasks.isEmpty()) {
                return;
            }
            for (Task t : openTasks) {
                t.Status = 'Completed';
            }
            List<Database.SaveResult> results = Database.update(openTasks, false, AccessLevel.SYSTEM_MODE);
            ErrorLogger.logSaveResults('CareActivityTriggerHandler.TaskCloser', results, openTasks);
        }
    }
}
