/**
 * Closes the loop when a patient answers a reminder in the portal:
 *   Will Attend (with a proposed date) -> task for the health worker to confirm the new date
 *   Completed Elsewhere                -> task for the health worker to verify and record it
 *   Need Help                          -> high-priority task + bell notification for the health worker
 * "Will Attend" without a new date only records the answer (it lowers no-show risk; no task needed).
 * The patient's priority also rises (PATIENT_NEEDS_HELP rule) on the next score.
 * "inherited sharing": it is only called by PatientPortalService after the ownership check.
 */
public inherited sharing class PatientResponseService {

    public static void followUp(Care_Activity__c a, String response, Date proposedDate, String note) {
        if (response == 'Will Attend' && proposedDate == null) {
            return;
        }
        Id worker = a.Assigned_To__c;
        if (worker == null) {
            List<Contact> p = [SELECT Assigned_Health_Worker__c FROM Contact WHERE Id = :a.Patient__c WITH SYSTEM_MODE];
            worker = p.isEmpty() ? null : p[0].Assigned_Health_Worker__c;
        }
        if (worker == null) {
            ErrorLogger.logMessage('PatientResponseService', 'Patient replied "' + response + '" but no health worker is assigned.',
                a.Id, ErrorLogger.SEVERITY_WARNING);
            return;
        }
        String subject;
        String priority = 'Normal';
        if (response == 'Need Help') {
            subject = 'Patient asked for help: ';
            priority = 'High';
        } else if (response == 'Completed Elsewhere') {
            subject = 'Patient says done elsewhere - verify: ';
        } else {
            subject = 'Patient proposed ' + proposedDate.format() + ': ';
        }
        String patientName = a.Patient__r == null ? '' : a.Patient__r.Name;
        Task t = new Task(
            OwnerId = worker,
            WhatId = a.Id,
            WhoId = a.Patient__c,
            Subject = (subject + a.Name + ' - ' + patientName).left(255),
            Priority = priority,
            Status = 'Not Started',
            ActivityDate = CareLoopClock.today().addDays(1),
            Description = ('Reply from the HealthConnect portal: ' + response
                + (proposedDate == null ? '' : '\nProposed date: ' + proposedDate.format())
                + (String.isBlank(note) ? '' : '\nPatient note: ' + note)).left(32000)
        );
        Database.insert(t, true, AccessLevel.SYSTEM_MODE);
        if (response == 'Need Help') {
            // Event-driven: the bell is sent by CareLoopAlertSubscriber in its own transaction.
            CareLoopAlertService.alertPatientNeedsHelp(a.Id, a.Patient__c, note);
        }
    }
}
