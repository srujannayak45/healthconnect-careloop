/** One trigger per object: all Doctor Recommendation logic lives in MedicalRecommendationTriggerHandler. */
trigger MedicalRecommendationTrigger on Medical_Recommendation__c (before insert, before update, after insert, after update) {
    new MedicalRecommendationTriggerHandler().run();
}
