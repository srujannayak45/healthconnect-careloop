/** Notification automation: start background delivery when SMS or Email reminders are queued. */
public with sharing class NotificationTriggerHandler extends TriggerHandler {

    protected override void afterInsert(List<SObject> newRecords) {
        for (Notification__c n : (List<Notification__c>) newRecords) {
            if (n.Status__c == 'Queued' && NotificationDispatchQueueable.DISPATCHED_CHANNELS.contains(n.Channel__c)) {
                NotificationDispatchQueueable.ensureRunning();
                return;
            }
        }
    }
}
