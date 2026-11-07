/** Apex entry points for the patient portal page (patientPortalHome). */
public with sharing class PatientPortalController {

    @AuraEnabled
    public static PatientPortalService.Home getHome() {
        try {
            return PatientPortalService.getHome();
        } catch (Exception e) {
            throw toAuraHandled(e);
        }
    }

    @AuraEnabled
    public static PatientPortalService.Home respond(Id activityId, String response, Date proposedDate, String note) {
        try {
            PatientPortalService.respond(activityId, response, proposedDate, note);
            return PatientPortalService.getHome();
        } catch (Exception e) {
            throw toAuraHandled(e);
        }
    }

    @AuraEnabled
    public static PatientPortalService.Home markRead(Id notificationId) {
        try {
            PatientPortalService.markRead(notificationId);
            return PatientPortalService.getHome();
        } catch (Exception e) {
            throw toAuraHandled(e);
        }
    }

    @AuraEnabled
    public static PatientPortalService.Home setReminderConsent(Boolean granted) {
        try {
            PatientPortalService.setReminderConsent(granted);
            return PatientPortalService.getHome();
        } catch (Exception e) {
            throw toAuraHandled(e);
        }
    }

    private static String friendly(Exception e) {
        if (e instanceof PatientPortalService.PortalException) {
            return e.getMessage();
        }
        ErrorLogger.log('PatientPortalController', e, null);
        return 'Something went wrong. Please try again or contact your health worker.';
    }
    private static AuraHandledException toAuraHandled(Exception e) {
        String message = friendly(e);
        AuraHandledException handled = new AuraHandledException(message);
        handled.setMessage(message);
        return handled;
    }
}
