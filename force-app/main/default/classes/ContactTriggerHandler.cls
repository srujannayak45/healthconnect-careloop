/**
 * Patient (Contact) automation.
 *
 * before insert : assign the patient to the village's health worker (or, if the village has
 *                 none, to the user registering the patient). Assigned_Health_Worker__c is
 *                 engine-owned, so health workers cannot set it themselves.
 * after insert  : queue care-schedule generation for the new patients.
 * after update  : queue generation again only when something that changes eligibility changed
 *                 (birth date, pregnancy, chronic conditions). Generation is idempotent, so only
 *                 the newly eligible activities are added.
 */
public with sharing class ContactTriggerHandler extends TriggerHandler {

    protected override void beforeInsert(List<SObject> newRecords) {
        defaultAssignedWorker((List<Contact>) newRecords);
    }

    protected override void afterInsert(List<SObject> newRecords) {
        CareScheduleQueueable.schedule(new Map<Id, SObject>(newRecords).keySet());
    }

    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        Set<Id> changed = new Set<Id>();
        for (Contact patient : (List<Contact>) newRecords) {
            Contact old = (Contact) oldMap.get(patient.Id);
            if (patient.Birthdate != old.Birthdate
                || patient.Is_Pregnant__c != old.Is_Pregnant__c
                || patient.Chronic_Conditions__c != old.Chronic_Conditions__c) {
                changed.add(patient.Id);
            }
        }
        CareScheduleQueueable.schedule(changed);
    }

    private static void defaultAssignedWorker(List<Contact> patients) {
        Set<Id> villageIds = new Set<Id>();
        for (Contact patient : patients) {
            if (patient.Assigned_Health_Worker__c == null && patient.Village__c != null) {
                villageIds.add(patient.Village__c);
            }
        }
        Map<Id, Village__c> villages = new Map<Id, Village__c>();
        if (!villageIds.isEmpty()) {
            villages = new Map<Id, Village__c>([
                SELECT Id, Health_Worker__c FROM Village__c WHERE Id IN :villageIds WITH SYSTEM_MODE
            ]);
        }
        for (Contact patient : patients) {
            if (patient.Assigned_Health_Worker__c != null) {
                continue;
            }
            Village__c village = patient.Village__c == null ? null : villages.get(patient.Village__c);
            patient.Assigned_Health_Worker__c = (village != null && village.Health_Worker__c != null)
                ? village.Health_Worker__c
                : UserInfo.getUserId();
        }
    }
}
