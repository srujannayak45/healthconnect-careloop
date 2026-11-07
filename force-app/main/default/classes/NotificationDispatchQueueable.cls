/**
 * Delivers queued reminders (SMS and Email) in the background, with callouts allowed.
 * Up to BATCH_SIZE notifications per run; it re-queues itself while more are waiting.
 * Failed sends are retried on the next run, up to MAX_ATTEMPTS, then marked Failed with the reason.
 * Only one dispatcher runs at a time (ensureRunning checks the job queue).
 */
public with sharing class NotificationDispatchQueueable implements Queueable, Database.AllowsCallouts {

    public static final Integer BATCH_SIZE = 40;
    public static final Integer MAX_ATTEMPTS = 3;
    public static final Set<String> DISPATCHED_CHANNELS = new Set<String>{ 'SMS', 'Email' };

    public void execute(QueueableContext context) {
        Integer remaining = 0;
        try {
            remaining = dispatch(BATCH_SIZE);
        } catch (Exception e) {
            ErrorLogger.log('NotificationDispatchQueueable', e, null);
        }
        if (remaining > 0 && !Test.isRunningTest() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new NotificationDispatchQueueable());
        }
    }

    /** Sends up to maxCount queued notifications. Returns how many are still queued. */
    public static Integer dispatch(Integer maxCount) {
        List<Notification__c> queued = [
            SELECT Id, Name, Channel__c, Message__c, Subject__c, Attempts__c, Patient__c, Patient__r.MobilePhone,
                   Patient__r.Email
            FROM Notification__c
            WHERE Status__c = 'Queued' AND Channel__c IN :DISPATCHED_CHANNELS
            WITH SYSTEM_MODE
            ORDER BY CreatedDate
            LIMIT :maxCount
        ];
        if (queued.isEmpty()) {
            return 0;
        }
        CareLoop_Setting__mdt setting = CareRules.setting();
        SmsProvider sms = provider(setting);
        String fromNumber = setting == null ? null : setting.SMS_From__c;
        Boolean emailEnabled = setting != null && setting.Email_Enabled__c == true;

        // All callouts first, then all DML (Salesforce does not allow a callout after uncommitted DML).
        List<Notification__c> updates = new List<Notification__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Notification__c> emailRows = new List<Notification__c>();
        for (Notification__c n : queued) {
            Notification__c u = new Notification__c(Id = n.Id, Attempts__c = (n.Attempts__c == null ? 0 : n.Attempts__c) + 1);
            if (n.Channel__c == 'SMS') {
                SmsResult r = sms.send(n.Patient__r.MobilePhone, fromNumber, n.Message__c, n.Name);
                u.Provider__c = r.providerName == null ? null : r.providerName.left(60);
                u.Provider_Response__c = r.providerResponse;
                markOutcome(u, r.success);
                updates.add(u);
            } else if (!emailEnabled || String.isBlank(n.Patient__r.Email)) {
                u.Status__c = 'Skipped';
                u.Skip_Reason__c = emailEnabled ? 'No email address' : 'Email channel switched off in CareLoop Setting';
                updates.add(u);
            } else {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(n.Patient__c);
                mail.setSaveAsActivity(false);
                mail.setSubject(n.Subject__c);
                mail.setPlainTextBody(n.Message__c);
                emails.add(mail);
                emailRows.add(u);
            }
        }
        if (!emails.isEmpty()) {
            Boolean capacity = true;
            try {
                Messaging.reserveSingleEmailCapacity(emails.size());
            } catch (Exception e) {
                capacity = false;
            }
            List<Messaging.SendEmailResult> results = capacity ? Messaging.sendEmail(emails, false) : null;
            for (Integer i = 0; i < emailRows.size(); i++) {
                Notification__c u = emailRows[i];
                Boolean ok = results != null && results[i].isSuccess();
                u.Provider__c = 'Salesforce Email';
                u.Provider_Response__c = ok ? 'Sent' : (results == null ? 'Daily email limit reached' : String.valueOf(results[i].getErrors()));
                markOutcome(u, ok);
                updates.add(u);
            }
        }
        List<Database.SaveResult> saved = Database.update(updates, false, AccessLevel.SYSTEM_MODE);
        ErrorLogger.logSaveResults('NotificationDispatchQueueable', saved, updates);
        return [SELECT COUNT() FROM Notification__c WHERE Status__c = 'Queued' AND Channel__c IN :DISPATCHED_CHANNELS WITH SYSTEM_MODE];
    }

    /** Starts the dispatcher unless one is already queued or running. Never throws. */
    public static void ensureRunning() {
        try {
            if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
                return;
            }
            if (Test.isRunningTest() && System.isQueueable()) {
                return;
            }
            Integer active = [
                SELECT COUNT() FROM AsyncApexJob
                WHERE ApexClass.Name = 'NotificationDispatchQueueable'
                  AND Status IN ('Queued', 'Preparing', 'Processing', 'Holding')
            ];
            if (active == 0) {
                System.enqueueJob(new NotificationDispatchQueueable());
            }
        } catch (Exception e) {
            ErrorLogger.log('NotificationDispatchQueueable.ensureRunning', e, null);
        }
    }

    private static void markOutcome(Notification__c u, Boolean ok) {
        if (ok) {
            u.Status__c = 'Sent';
            u.Sent_On__c = System.now();
        } else if (u.Attempts__c >= MAX_ATTEMPTS) {
            u.Status__c = 'Failed';
        }
    }

    @TestVisible
    private static SmsProvider provider(CareLoop_Setting__mdt setting) {
        String className = (setting == null || String.isBlank(setting.SMS_Provider_Class__c))
            ? 'SimulatedSmsProvider' : setting.SMS_Provider_Class__c;
        Type t = Type.forName(className);
        if (t != null) {
            Object instance = t.newInstance();
            if (instance instanceof SmsProvider) {
                return (SmsProvider) instance;
            }
        }
        ErrorLogger.logMessage('NotificationDispatchQueueable', 'SMS provider class "' + className
            + '" not found or not an SmsProvider; using SimulatedSmsProvider.', null, ErrorLogger.SEVERITY_WARNING);
        return new SimulatedSmsProvider();
    }
}
