/**
 * Real-time alerts between care providers, built as an event-driven flow:
 *
 *   clinical save (visit trigger, portal reply)
 *        -> publishes CareLoop_Alert__e  (no queries, PublishAfterCommit: a rolled-back save alerts nobody)
 *        -> CareLoopAlertTrigger / CareLoopAlertSubscriber (own transaction) sends the bell notifications
 *        -> the Doctor Review page (lightning/empApi) refreshes itself at the same moment
 *
 * Publishing costs the clinical save no SOQL queries, and a problem with notifications can never
 * block or slow down the health worker's save. Bell notifications use the custom notification type
 * CareLoop_Alert; one bell per person per batch of events.
 */
public with sharing class CareLoopAlertService {

    public static final String NOTIFICATION_TYPE = 'CareLoop_Alert';
    public static final String DOCTOR_PERMISSION_SET = 'CareLoop_Doctor';
    public static final String ALERT_REVIEW = 'REVIEW_REQUESTED';
    public static final String ALERT_RED_FLAG = 'RED_FLAG';
    public static final String ALERT_PATIENT_HELP = 'PATIENT_HELP';

    @TestVisible
    private static Integer bellsSent = 0;
    @TestVisible
    private static List<CareLoop_Alert__e> lastPublished = new List<CareLoop_Alert__e>();

    /**
     * Called by HealthVisitTriggerHandler after insert/update: one event for every visit that has
     * just become "Pending Review" (red flag, or the health worker asked for a doctor).
     */
    public static void alertDoctorsForVisits(List<Health_Visit__c> visits, Map<Id, SObject> oldMap) {
        try {
            List<CareLoop_Alert__e> events = new List<CareLoop_Alert__e>();
            for (Health_Visit__c v : visits) {
                Health_Visit__c old = oldMap == null ? null : (Health_Visit__c) oldMap.get(v.Id);
                Boolean nowPending = v.Review_Status__c == HealthVisitTriggerHandler.REVIEW_PENDING;
                Boolean wasPending = old != null && old.Review_Status__c == HealthVisitTriggerHandler.REVIEW_PENDING;
                if (!nowPending || wasPending) {
                    continue;
                }
                events.add(new CareLoop_Alert__e(
                    Alert_Type__c = v.Red_Flag__c ? ALERT_RED_FLAG : ALERT_REVIEW,
                    Record_Id__c = v.Id,
                    Patient_Id__c = v.Patient__c,
                    Severity__c = v.Red_Flag__c ? 'High' : 'Normal',
                    Message__c = (v.Red_Flag__c ? v.Red_Flag_Reason__c : 'The health worker asked for a doctor review.')
                ));
            }
            publish(events);
        } catch (Exception e) {
            ErrorLogger.log('CareLoopAlertService.alertDoctorsForVisits', e, null);
        }
    }

    /** A patient asked for help in the portal: alert the assigned health worker (Phase 5 uses this). */
    public static void alertPatientNeedsHelp(Id activityId, Id patientId, String note) {
        try {
            publish(new List<CareLoop_Alert__e>{ new CareLoop_Alert__e(
                Alert_Type__c = ALERT_PATIENT_HELP,
                Record_Id__c = activityId,
                Patient_Id__c = patientId,
                Severity__c = 'High',
                Message__c = String.isBlank(note) ? 'The patient asked for help in the portal.' : note.left(255)
            ) });
        } catch (Exception e) {
            ErrorLogger.log('CareLoopAlertService.alertPatientNeedsHelp', e, activityId);
        }
    }

    /** Sends one bell notification to each user. Returns false (and logs) if it could not be sent. */
    public static Boolean notify(Set<Id> userIds, String title, String body, Id targetId) {
        if (userIds == null || userIds.isEmpty() || targetId == null) {
            return false;
        }
        try {
            Id typeId = notificationTypeId();
            if (typeId == null) {
                ErrorLogger.logMessage('CareLoopAlertService', 'Custom notification type ' + NOTIFICATION_TYPE
                    + ' not found; bell notification not sent.', targetId, ErrorLogger.SEVERITY_WARNING);
                return false;
            }
            Set<String> recipients = new Set<String>();
            for (Id userId : userIds) {
                recipients.add(String.valueOf(userId));
            }
            Messaging.CustomNotification bell = new Messaging.CustomNotification();
            bell.setNotificationTypeId(typeId);
            bell.setTitle(String.isBlank(title) ? 'CareLoop' : title.left(250));
            bell.setBody(String.isBlank(body) ? ' ' : body.left(750));
            bell.setTargetId(targetId);
            if (!Test.isRunningTest()) {
                // Tests verify who would be notified (bellsSent) without depending on the notification service.
                bell.send(recipients);
            }
            bellsSent++;
            return true;
        } catch (Exception e) {
            ErrorLogger.log('CareLoopAlertService.notify', e, targetId);
            return false;
        }
    }

    /** Active users holding the CareLoop_Doctor permission set. */
    public static Set<Id> doctors() {
        Set<Id> ids = new Set<Id>();
        for (PermissionSetAssignment a : [
            SELECT AssigneeId FROM PermissionSetAssignment
            WHERE PermissionSet.Name = :DOCTOR_PERMISSION_SET AND Assignee.IsActive = true
            WITH SYSTEM_MODE
        ]) {
            ids.add(a.AssigneeId);
        }
        return ids;
    }

    private static void publish(List<CareLoop_Alert__e> events) {
        if (events.isEmpty()) {
            return;
        }
        lastPublished = events;
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult r : results) {
            if (!r.isSuccess()) {
                ErrorLogger.logMessage('CareLoopAlertService.publish', ErrorLogger.describe(r.getErrors()), null,
                    ErrorLogger.SEVERITY_WARNING);
            }
        }
    }

    private static Id cachedTypeId;
    private static Id notificationTypeId() {
        if (cachedTypeId == null) {
            List<CustomNotificationType> types = [
                SELECT Id FROM CustomNotificationType WHERE DeveloperName = :NOTIFICATION_TYPE LIMIT 1
            ];
            cachedTypeId = types.isEmpty() ? null : types[0].Id;
        }
        return cachedTypeId;
    }
}
