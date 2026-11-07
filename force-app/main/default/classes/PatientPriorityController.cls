/**
 * Data for the "Why this patient?" card on the Patient page: the live, explainable priority.
 * The user must be able to see the patient (checked in USER_MODE) before anything is calculated.
 */
public with sharing class PatientPriorityController {

    public class PriorityView {
        @AuraEnabled public PriorityScoringService.PatientScore live;
        @AuraEnabled public Decimal storedScore;
        @AuraEnabled public String storedLevel;
        @AuraEnabled public Datetime calculatedOn;
    }

    @AuraEnabled
    public static PriorityView getPriority(Id patientId) {
        Contact patient = visiblePatient(patientId);
        PriorityView view = new PriorityView();
        view.live = PriorityScoringService.score(new Set<Id>{ patientId }).get(patientId);
        view.storedScore = patient.Priority_Score__c;
        view.storedLevel = patient.Priority_Level__c;
        view.calculatedOn = patient.Priority_Calculated_On__c;
        return view;
    }

    /** Saves the live score on the Patient record now, instead of waiting for the nightly run. */
    @AuraEnabled
    public static PriorityView saveNow(Id patientId) {
        visiblePatient(patientId);
        PatientPriorityBatch.store(new Set<Id>{ patientId });
        return getPriority(patientId);
    }

    private static Contact visiblePatient(Id patientId) {
        List<Contact> rows = [
            SELECT Id, Priority_Score__c, Priority_Level__c, Priority_Calculated_On__c
            FROM Contact WHERE Id = :patientId WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw new AuraHandledException('You do not have access to this patient.');
        }
        return rows[0];
    }
}
