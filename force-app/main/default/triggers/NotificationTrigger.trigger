trigger NotificationTrigger on Notification__c (before insert, before update, after insert, after update) {
    new NotificationTriggerHandler().run();
}
