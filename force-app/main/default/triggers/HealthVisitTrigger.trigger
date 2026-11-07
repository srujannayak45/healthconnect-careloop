/** One trigger per object: all Outreach Visit logic lives in HealthVisitTriggerHandler. */
trigger HealthVisitTrigger on Health_Visit__c (before insert, before update, after insert, after update) {
    new HealthVisitTriggerHandler().run();
}
