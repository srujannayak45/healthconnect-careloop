trigger ConsentEventTrigger on Consent_Event__c (before insert, before update, before delete, after insert, after update) {
    if (Trigger.isDelete) {
        ConsentEventTriggerHandler.blockDelete(Trigger.old);
    } else {
        new ConsentEventTriggerHandler().run();
    }
}
