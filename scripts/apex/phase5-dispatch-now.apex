// =====================================================================================
// HealthConnect CareLoop - Phase 5: deliver queued SMS / Email reminders now
// =====================================================================================
// Starts NotificationDispatchQueueable (normally started automatically when reminders are queued).
// With SMS Provider Class = HttpSmsProvider the SMS goes through the CareLoop_SMS Named Credential.
//
// Run:
//   sf apex run --file scripts/apex/phase5-dispatch-now.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Integer queued = [SELECT COUNT() FROM Notification__c WHERE Status__c = 'Queued' AND Channel__c IN ('SMS', 'Email')];
Id jobId = System.enqueueJob(new NotificationDispatchQueueable());
System.debug(LoggingLevel.ERROR, 'DISPATCH STARTED | job ' + jobId + ' | queued reminders: ' + queued
    + ' | provider: ' + CareRules.setting().SMS_Provider_Class__c);
