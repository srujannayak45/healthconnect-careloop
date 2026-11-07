/** One trigger per object: all Care Activity logic lives in CareActivityTriggerHandler. */
trigger CareActivityTrigger on Care_Activity__c (before insert, before update, after insert, after update) {
    new CareActivityTriggerHandler().run();
}
