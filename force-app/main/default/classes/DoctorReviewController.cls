/**
 * Data for the Doctor Review page: visits waiting for a doctor, red flags first.
 * Runs in USER_MODE, so a doctor only sees visits her role and sharing allow, and only fields
 * her permission sets allow.
 */
public with sharing class DoctorReviewController {

    public class ReviewItem {
        @AuraEnabled public Id visitId;
        @AuraEnabled public String visitName;
        @AuraEnabled public Id patientId;
        @AuraEnabled public String patientName;
        @AuraEnabled public String village;
        @AuraEnabled public String region;
        @AuraEnabled public Datetime visitDate;
        @AuraEnabled public Boolean redFlag;
        @AuraEnabled public String reason;
        @AuraEnabled public String vitals;
        @AuraEnabled public String healthWorker;
        @AuraEnabled public Integer hoursWaiting;
    }

    @AuraEnabled
    public static List<ReviewItem> getPendingReviews() {
        try {
            List<ReviewItem> items = new List<ReviewItem>();
            for (Health_Visit__c v : [
                SELECT Id, Name, Patient__c, Patient__r.Name, Patient__r.Village__r.Name, Patient__r.Village__r.Region__c,
                       Visit_Date__c, Red_Flag__c, Red_Flag_Reason__c, BP_Systolic__c, BP_Diastolic__c, SpO2__c,
                       Temperature__c, Blood_Sugar__c, Health_Worker__r.Name, CreatedDate
                FROM Health_Visit__c
                WHERE Review_Status__c = 'Pending Review'
                WITH USER_MODE
                ORDER BY Red_Flag__c DESC, Visit_Date__c ASC
                LIMIT 100
            ]) {
                ReviewItem item = new ReviewItem();
                item.visitId = v.Id;
                item.visitName = v.Name;
                item.patientId = v.Patient__c;
                item.patientName = v.Patient__r.Name;
                item.village = v.Patient__r.Village__r == null ? null : v.Patient__r.Village__r.Name;
                item.region = v.Patient__r.Village__r == null ? null : v.Patient__r.Village__r.Region__c;
                item.visitDate = v.Visit_Date__c;
                item.redFlag = v.Red_Flag__c;
                item.reason = v.Red_Flag__c ? v.Red_Flag_Reason__c : 'Health worker requested a review';
                item.vitals = vitals(v);
                item.healthWorker = v.Health_Worker__r == null ? null : v.Health_Worker__r.Name;
                Long minutes = (System.now().getTime() - v.CreatedDate.getTime()) / 60000;
                item.hoursWaiting = (minutes / 60).intValue();
                items.add(item);
            }
            return items;
        } catch (Exception e) {
            throw new AuraHandledException('Could not load the review queue: ' + e.getMessage());
        }
    }

    private static String vitals(Health_Visit__c v) {
        List<String> parts = new List<String>();
        if (v.BP_Systolic__c != null && v.BP_Diastolic__c != null) {
            parts.add('BP ' + v.BP_Systolic__c.intValue() + '/' + v.BP_Diastolic__c.intValue());
        }
        if (v.SpO2__c != null) { parts.add('SpO2 ' + v.SpO2__c.intValue() + '%'); }
        if (v.Temperature__c != null) { parts.add('Temp ' + v.Temperature__c + ' C'); }
        if (v.Blood_Sugar__c != null) { parts.add('Sugar ' + v.Blood_Sugar__c.intValue()); }
        return String.join(parts, ' · ');
    }
}
