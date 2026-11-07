/**
 * Doctor Recommendation (Medical_Recommendation__c) automation.
 *
 * before insert/update: when the status becomes Final, stamp the doctor and the time.
 *                       (After that, the Phase 1 validation rule locks the recommendation.)
 * after insert/update : when the status became Final in this save, hand the recommendations
 *                       to CarePlanService, which creates the follow-up and check-up activities
 *                       and marks the visit Reviewed.
 */
public with sharing class MedicalRecommendationTriggerHandler extends TriggerHandler {

    public static final String STATUS_FINAL = 'Final';

    protected override void beforeInsert(List<SObject> newRecords) {
        for (Medical_Recommendation__c r : (List<Medical_Recommendation__c>) newRecords) {
            stampIfFinalised(r, null);
        }
    }

    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        for (Medical_Recommendation__c r : (List<Medical_Recommendation__c>) newRecords) {
            stampIfFinalised(r, (Medical_Recommendation__c) oldMap.get(r.Id));
        }
    }

    protected override void afterInsert(List<SObject> newRecords) {
        CarePlanService.applyFinalisedRecommendations(newlyFinalised(newRecords, null));
    }

    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        CarePlanService.applyFinalisedRecommendations(newlyFinalised(newRecords, oldMap));
    }

    private static Boolean becameFinal(Medical_Recommendation__c r, Medical_Recommendation__c old) {
        return r.Status__c == STATUS_FINAL && (old == null || old.Status__c != STATUS_FINAL);
    }

    private static void stampIfFinalised(Medical_Recommendation__c r, Medical_Recommendation__c old) {
        if (becameFinal(r, old)) {
            r.Doctor__c = UserInfo.getUserId();
            r.Finalized_On__c = System.now();
        }
    }

    private static List<Medical_Recommendation__c> newlyFinalised(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        List<Medical_Recommendation__c> result = new List<Medical_Recommendation__c>();
        for (Medical_Recommendation__c r : (List<Medical_Recommendation__c>) newRecords) {
            Medical_Recommendation__c old = oldMap == null ? null : (Medical_Recommendation__c) oldMap.get(r.Id);
            if (becameFinal(r, old)) {
                result.add(r);
            }
        }
        return result;
    }
}
