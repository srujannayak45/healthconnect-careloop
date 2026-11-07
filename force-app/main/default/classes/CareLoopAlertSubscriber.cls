/**
 * Subscriber for CareLoop_Alert__e (runs in its own transaction as the Automated Process user).
 * Turns events into bell notifications:
 *   RED_FLAG / REVIEW_REQUESTED -> one bell to every doctor for the batch of visits
 *   PATIENT_HELP                -> a bell to the health worker assigned to the activity
 * WITHOUT SHARING on purpose: it only reads the records named in the events, to word the
 * notification, and it never returns data to a user.
 */
public without sharing class CareLoopAlertSubscriber {

    public static void handle(List<CareLoop_Alert__e> events) {
        try {
            Set<Id> visitIds = new Set<Id>();
            Set<Id> helpActivityIds = new Set<Id>();
            Map<Id, String> notes = new Map<Id, String>();
            for (CareLoop_Alert__e e : events) {
                if (String.isBlank(e.Record_Id__c)) {
                    continue;
                }
                Id recordId = Id.valueOf(e.Record_Id__c);
                if (e.Alert_Type__c == CareLoopAlertService.ALERT_PATIENT_HELP) {
                    helpActivityIds.add(recordId);
                    notes.put(recordId, e.Message__c);
                } else {
                    visitIds.add(recordId);
                }
            }
            if (!visitIds.isEmpty()) {
                alertDoctors(visitIds);
            }
            if (!helpActivityIds.isEmpty()) {
                alertWorkers(helpActivityIds, notes);
            }
        } catch (Exception e) {
            ErrorLogger.log('CareLoopAlertSubscriber', e, null);
        }
    }

    private static void alertDoctors(Set<Id> visitIds) {
        List<Health_Visit__c> visits = [
            SELECT Id, Red_Flag__c, Red_Flag_Reason__c, Patient__r.Name, Patient__r.Village__r.Name
            FROM Health_Visit__c WHERE Id IN :visitIds ORDER BY Red_Flag__c DESC
        ];
        if (visits.isEmpty()) {
            return;
        }
        Integer redFlags = 0;
        for (Health_Visit__c v : visits) {
            redFlags += v.Red_Flag__c ? 1 : 0;
        }
        Health_Visit__c first = visits[0];
        String village = first.Patient__r.Village__r == null ? '' : ' (' + first.Patient__r.Village__r.Name + ')';
        String title = visits.size() == 1
            ? (first.Red_Flag__c ? 'Red flag: ' : 'Review requested: ') + first.Patient__r.Name + village
            : visits.size() + ' visits need a doctor review';
        String body = visits.size() == 1
            ? (first.Red_Flag__c ? first.Red_Flag_Reason__c : 'The health worker asked for a doctor review.')
            : redFlags + ' of them are red-flagged. Open Doctor Review.';
        CareLoopAlertService.notify(CareLoopAlertService.doctors(), title, body, first.Id);
    }

    private static void alertWorkers(Set<Id> activityIds, Map<Id, String> notes) {
        for (Care_Activity__c a : [
            SELECT Id, Name, Assigned_To__c, Patient__r.Name, Patient__r.Assigned_Health_Worker__c
            FROM Care_Activity__c WHERE Id IN :activityIds
        ]) {
            Id worker = a.Assigned_To__c != null ? a.Assigned_To__c : a.Patient__r.Assigned_Health_Worker__c;
            if (worker == null) {
                continue;
            }
            CareLoopAlertService.notify(new Set<Id>{ worker }, 'Patient asked for help: ' + a.Patient__r.Name,
                a.Name + ' - "' + (notes.get(a.Id) == null ? '' : notes.get(a.Id)) + '"', a.Id);
        }
    }
}
