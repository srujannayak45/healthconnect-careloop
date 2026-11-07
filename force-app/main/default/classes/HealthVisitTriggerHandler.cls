/**
 * Outreach Visit (Health_Visit__c) automation.
 *
 * before insert/update:
 *   - stamp the health worker and default the outcome to Completed
 *   - RED FLAG: compare vitals with the "Red Flag" thresholds in Care_Rule__mdt
 *     (systolic >= 180, diastolic >= 110, SpO2 < 92, temperature >= 39.5, sugar >= 300 by default)
 *     and write a plain-language reason, e.g. "Systolic BP 186 mmHg; Diastolic BP 112 mmHg"
 *   - REVIEW STATUS: Pending Review when red-flagged or the worker asked for a doctor;
 *     never downgraded once Reviewed
 * after insert/update:
 *   - refresh the patient's contact history used by the Care Gap Radar:
 *     Last_Successful_Contact__c (latest Completed visit) and
 *     Failed_Outreach_Attempts__c (unsuccessful visits in the last 90 days)
 *
 *   - (Phase 4) alert doctors when a visit starts waiting for review: one bell notification
 *     and a CareLoop_Alert__e platform event (CareLoopAlertService)
 */
public with sharing class HealthVisitTriggerHandler extends TriggerHandler {

    public static final String OUTCOME_COMPLETED = 'Completed';
    public static final String REVIEW_NOT_REQUIRED = 'Not Required';
    public static final String REVIEW_PENDING = 'Pending Review';
    public static final String REVIEW_DONE = 'Reviewed';
    private static final Integer FAILED_ATTEMPT_WINDOW_DAYS = 90;

    protected override void beforeInsert(List<SObject> newRecords) {
        for (Health_Visit__c visit : (List<Health_Visit__c>) newRecords) {
            if (visit.Health_Worker__c == null) {
                visit.Health_Worker__c = UserInfo.getUserId();
            }
            if (visit.Visit_Date__c == null) {
                visit.Visit_Date__c = System.now();
            }
            if (visit.Visit_Outcome__c == null) {
                visit.Visit_Outcome__c = OUTCOME_COMPLETED;
            }
            applyRedFlag(visit);
            applyReviewStatus(visit);
        }
    }

    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        for (Health_Visit__c visit : (List<Health_Visit__c>) newRecords) {
            applyRedFlag(visit);
            applyReviewStatus(visit);
        }
    }

    protected override void afterInsert(List<SObject> newRecords) {
        Set<Id> patientIds = new Set<Id>();
        for (Health_Visit__c visit : (List<Health_Visit__c>) newRecords) {
            patientIds.add(visit.Patient__c);
        }
        refreshContactHistory(patientIds);
        // Phase 4: tell doctors at once when a visit starts waiting for review (bell + live event).
        CareLoopAlertService.alertDoctorsForVisits((List<Health_Visit__c>) newRecords, null);
    }

    protected override void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        Set<Id> patientIds = new Set<Id>();
        for (Health_Visit__c visit : (List<Health_Visit__c>) newRecords) {
            Health_Visit__c old = (Health_Visit__c) oldMap.get(visit.Id);
            if (visit.Visit_Outcome__c != old.Visit_Outcome__c || visit.Visit_Date__c != old.Visit_Date__c) {
                patientIds.add(visit.Patient__c);
            }
        }
        refreshContactHistory(patientIds);
        // Phase 4: a corrected reading can turn a visit into a red flag after it was first saved.
        CareLoopAlertService.alertDoctorsForVisits((List<Health_Visit__c>) newRecords, oldMap);
    }

    @TestVisible
    private static void applyRedFlag(Health_Visit__c visit) {
        List<String> reasons = new List<String>();
        if (visit.Visit_Outcome__c == null || visit.Visit_Outcome__c == OUTCOME_COMPLETED) {
            addIfAtLeast(reasons, 'RF_BP_SYSTOLIC', visit.BP_Systolic__c);
            addIfAtLeast(reasons, 'RF_BP_DIASTOLIC', visit.BP_Diastolic__c);
            addIfBelow(reasons, 'RF_SPO2', visit.SpO2__c);
            addIfAtLeast(reasons, 'RF_TEMPERATURE', visit.Temperature__c);
            addIfAtLeast(reasons, 'RF_BLOOD_SUGAR', visit.Blood_Sugar__c);
        }
        visit.Red_Flag__c = !reasons.isEmpty();
        visit.Red_Flag_Reason__c = reasons.isEmpty() ? null : String.join(reasons, '; ').left(255);
    }

    private static void applyReviewStatus(Health_Visit__c visit) {
        if (visit.Review_Status__c == REVIEW_DONE) {
            return;
        }
        Boolean needsReview = visit.Red_Flag__c == true || visit.Needs_Doctor_Review__c == true;
        visit.Review_Status__c = needsReview ? REVIEW_PENDING : REVIEW_NOT_REQUIRED;
    }

    private static void addIfAtLeast(List<String> reasons, String ruleKey, Decimal value) {
        Care_Rule__mdt rule = CareRules.rule(ruleKey);
        if (value != null && rule != null && rule.Threshold__c != null && value >= rule.Threshold__c) {
            reasons.add(describe(rule, value));
        }
    }

    private static void addIfBelow(List<String> reasons, String ruleKey, Decimal value) {
        Care_Rule__mdt rule = CareRules.rule(ruleKey);
        if (value != null && rule != null && rule.Threshold__c != null && value < rule.Threshold__c) {
            reasons.add(describe(rule, value));
        }
    }

    /** Fills the rule's explanation template, e.g. "Systolic BP {v} mmHg" -> "Systolic BP 186 mmHg". */
    private static String describe(Care_Rule__mdt rule, Decimal value) {
        String shown = value == value.round() ? String.valueOf(value.longValue()) : String.valueOf(value.setScale(1));
        String template = String.isBlank(rule.Explanation__c) ? rule.DeveloperName + ' {v}' : rule.Explanation__c;
        return template.replace('{v}', shown);
    }

    private static void refreshContactHistory(Set<Id> patientIds) {
        patientIds.remove(null);
        if (patientIds.isEmpty()) {
            return;
        }
        Datetime windowStart = Datetime.newInstance(
            CareLoopClock.today().addDays(-FAILED_ATTEMPT_WINDOW_DAYS), Time.newInstance(0, 0, 0, 0));

        Map<Id, Contact> updates = new Map<Id, Contact>();
        for (Id patientId : patientIds) {
            updates.put(patientId, new Contact(Id = patientId, Last_Successful_Contact__c = null, Failed_Outreach_Attempts__c = 0));
        }
        for (AggregateResult row : [
            SELECT Patient__c patientId, MAX(Visit_Date__c) lastVisit
            FROM Health_Visit__c
            WHERE Patient__c IN :patientIds AND Visit_Outcome__c = :OUTCOME_COMPLETED
            WITH SYSTEM_MODE
            GROUP BY Patient__c
        ]) {
            Datetime lastVisit = (Datetime) row.get('lastVisit');
            updates.get((Id) row.get('patientId')).Last_Successful_Contact__c = lastVisit == null ? null : lastVisit.date();
        }
        for (AggregateResult row : [
            SELECT Patient__c patientId, COUNT(Id) attempts
            FROM Health_Visit__c
            WHERE Patient__c IN :patientIds AND Visit_Outcome__c != :OUTCOME_COMPLETED AND Visit_Date__c >= :windowStart
            WITH SYSTEM_MODE
            GROUP BY Patient__c
        ]) {
            updates.get((Id) row.get('patientId')).Failed_Outreach_Attempts__c = (Integer) row.get('attempts');
        }
        DerivedFieldWriter.write(updates.values(), 'HealthVisitTriggerHandler');
    }
}
