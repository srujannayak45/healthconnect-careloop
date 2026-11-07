/**
 * Explainable patient priority ("who needs help first, and why").
 *
 * Every point comes from a Care_Rule__mdt record of category "Priority" (points, threshold and
 * explanation text are configuration), and every point is returned with its reason, so a health
 * worker, a doctor or a judge can see exactly why a patient is ranked where she is.
 * This is transparent rule-based decision support, not machine learning.
 *
 * Counting rules (overdue items, failed attempts, escalations) score each item, capped at
 * MAX_ITEMS_PER_RULE items, so a single long backlog cannot drown every other signal.
 * Level thresholds come from the "Level" rules (LEVEL_CRITICAL, LEVEL_HIGH, LEVEL_MEDIUM).
 *
 * The service only reads (SYSTEM_MODE, because it is engine logic that must see every open
 * activity of the patients it is asked about). Callers decide what to show or store.
 */
public with sharing class PriorityScoringService {

    public static final Integer MAX_ITEMS_PER_RULE = 3;
    public static final String TYPE_IMMUNIZATION = 'Immunization';
    public static final String TYPE_FOLLOW_UP = 'Follow-up';
    public static final String RESPONSE_NEED_HELP = 'Need Help';

    public class Reason {
        @AuraEnabled public String ruleKey;
        @AuraEnabled public Integer points;
        @AuraEnabled public String text;
        public Reason(String ruleKey, Integer points, String text) {
            this.ruleKey = ruleKey;
            this.points = points;
            this.text = text;
        }
    }

    public class PatientScore {
        @AuraEnabled public Id patientId;
        @AuraEnabled public String patientName;
        @AuraEnabled public Integer score = 0;
        @AuraEnabled public String level = 'Low';
        @AuraEnabled public List<Reason> reasons = new List<Reason>();
        @AuraEnabled public String nextBestAction = 'No action needed today';
        @AuraEnabled public Integer openGaps = 0;
        @AuraEnabled public Integer overdue = 0;
        /** Open activities that are Due or Overdue (the gaps a visit could close), most urgent first. */
        public List<Care_Activity__c> actionable = new List<Care_Activity__c>();

        public String explanation() {
            List<String> lines = new List<String>();
            for (Reason r : reasons) {
                lines.add('+' + r.points + '  ' + r.text);
            }
            return lines.isEmpty() ? 'No open care gaps.' : String.join(lines, '\n');
        }
    }

    /** Scores the given patients as of the CareLoop clock's today. */
    public static Map<Id, PatientScore> score(Set<Id> patientIds) {
        Map<Id, PatientScore> results = new Map<Id, PatientScore>();
        if (patientIds == null || patientIds.isEmpty()) {
            return results;
        }
        Date today = CareLoopClock.today();
        Integer redFlagDays = CareRules.threshold('RECENT_RED_FLAG', 14).intValue();
        Datetime redFlagSince = Datetime.newInstance(today.addDays(-redFlagDays), Time.newInstance(0, 0, 0, 0));

        Map<Id, Contact> patients = new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Birthdate, Is_Pregnant__c, Last_Successful_Contact__c,
                   Failed_Outreach_Attempts__c, CreatedDate
            FROM Contact WHERE Id IN :patientIds WITH SYSTEM_MODE
        ]);
        Map<Id, List<Care_Activity__c>> openByPatient = new Map<Id, List<Care_Activity__c>>();
        for (Care_Activity__c a : [
            SELECT Id, Name, Patient__c, Activity_Type__c, Status__c, Due_Date__c, Days_Overdue__c,
                   Escalation_Level__c, Patient_Response__c
            FROM Care_Activity__c
            WHERE Patient__c IN :patientIds AND Status__c IN :CareRules.OPEN_STATUSES
            WITH SYSTEM_MODE
            ORDER BY Due_Date__c ASC NULLS LAST
        ]) {
            if (!openByPatient.containsKey(a.Patient__c)) {
                openByPatient.put(a.Patient__c, new List<Care_Activity__c>());
            }
            openByPatient.get(a.Patient__c).add(a);
        }
        Set<Id> recentRedFlag = new Set<Id>();
        Set<Id> pendingReview = new Set<Id>();
        for (Health_Visit__c v : [
            SELECT Patient__c, Red_Flag__c, Review_Status__c, Visit_Date__c
            FROM Health_Visit__c
            WHERE Patient__c IN :patientIds
              AND ((Red_Flag__c = true AND Visit_Date__c >= :redFlagSince) OR Review_Status__c = 'Pending Review')
            WITH SYSTEM_MODE
        ]) {
            if (v.Red_Flag__c && v.Visit_Date__c >= redFlagSince) {
                recentRedFlag.add(v.Patient__c);
            }
            if (v.Review_Status__c == 'Pending Review') {
                pendingReview.add(v.Patient__c);
            }
        }

        for (Contact patient : patients.values()) {
            List<Care_Activity__c> open = openByPatient.containsKey(patient.Id)
                ? openByPatient.get(patient.Id) : new List<Care_Activity__c>();
            results.put(patient.Id, evaluate(patient, open, recentRedFlag.contains(patient.Id),
                pendingReview.contains(patient.Id), today));
        }
        return results;
    }

    /** Pure scoring logic for one patient (no queries), public for tests and the Navigator. */
    public static PatientScore evaluate(Contact patient, List<Care_Activity__c> open, Boolean recentRedFlag,
                                        Boolean pendingReview, Date today) {
        PatientScore result = new PatientScore();
        result.patientId = patient.Id;
        result.patientName = ((patient.FirstName == null ? '' : patient.FirstName + ' ') + patient.LastName).trim();

        Integer overdueImm = 0, overdueFollowUp = 0, overdueCheckUp = 0, longOverdue = 0, escalated = 0;
        Boolean needsHelp = false;
        Integer longOverdueDays = CareRules.threshold('LONG_OVERDUE', 30).intValue();
        Care_Activity__c firstImm, firstFollowUp, firstCheckUp;
        for (Care_Activity__c a : open) {
            Boolean isOverdue = a.Status__c == CareRules.STATUS_OVERDUE;
            if (a.Status__c == CareRules.STATUS_OVERDUE || a.Status__c == CareRules.STATUS_DUE) {
                result.openGaps++;
                result.actionable.add(a);
            }
            if (a.Patient_Response__c == RESPONSE_NEED_HELP) {
                needsHelp = true;
            }
            if (a.Escalation_Level__c != null && a.Escalation_Level__c >= 3) {
                escalated++;
            }
            if (!isOverdue) {
                continue;
            }
            result.overdue++;
            if (CareRules.daysOverdue(a.Due_Date__c, today) > longOverdueDays) {
                longOverdue++;
            }
            if (a.Activity_Type__c == TYPE_IMMUNIZATION) {
                overdueImm++;
                if (firstImm == null) { firstImm = a; }
            } else if (a.Activity_Type__c == TYPE_FOLLOW_UP) {
                overdueFollowUp++;
                if (firstFollowUp == null) { firstFollowUp = a; }
            } else {
                overdueCheckUp++;
                if (firstCheckUp == null) { firstCheckUp = a; }
            }
        }

        addCounted(result, 'RECENT_RED_FLAG', recentRedFlag ? 1 : 0, false);
        addCounted(result, 'OVERDUE_FOLLOWUP', overdueFollowUp, true);
        addCounted(result, 'OVERDUE_IMMUNIZATION', overdueImm, true);
        addCounted(result, 'PENDING_REVIEW', pendingReview ? 1 : 0, false);
        addCounted(result, 'OVERDUE_CHECKUP', overdueCheckUp, true);
        addCounted(result, 'PATIENT_NEEDS_HELP', needsHelp ? 1 : 0, false);
        addCounted(result, 'LONG_OVERDUE', longOverdue, true);
        addCounted(result, 'SUPERVISOR_ESCALATION', escalated, true);

        Integer failed = patient.Failed_Outreach_Attempts__c == null ? 0 : patient.Failed_Outreach_Attempts__c.intValue();
        addCounted(result, 'FAILED_OUTREACH', failed, true);

        Integer noContactDays = CareRules.threshold('NO_CONTACT', 60).intValue();
        if (patient.Last_Successful_Contact__c != null) {
            Integer since = patient.Last_Successful_Contact__c.daysBetween(today);
            if (since > noContactDays) {
                addReason(result, 'NO_CONTACT', 1, since);
            }
        } else if (patient.CreatedDate != null && patient.CreatedDate.date().daysBetween(today) > noContactDays) {
            addReason(result, 'NO_CONTACT', 1, patient.CreatedDate.date().daysBetween(today));
        }
        if (patient.Is_Pregnant__c == true) {
            addCounted(result, 'PREGNANCY', 1, false);
        }
        if (patient.Birthdate != null && patient.Birthdate > today.addYears(-2)) {
            addCounted(result, 'INFANT', 1, false);
        }

        result.reasons.sort(new ByPointsDesc());
        result.level = levelFor(result.score);
        result.nextBestAction = nextBestAction(result, recentRedFlag || pendingReview, needsHelp,
            firstFollowUp, firstImm, firstCheckUp, patient);
        return result;
    }

    /** Low / Medium / High / Critical from the configured Level thresholds. */
    public static String levelFor(Integer score) {
        if (score >= CareRules.threshold('LEVEL_CRITICAL', 15)) { return 'Critical'; }
        if (score >= CareRules.threshold('LEVEL_HIGH', 9)) { return 'High'; }
        if (score >= CareRules.threshold('LEVEL_MEDIUM', 4)) { return 'Medium'; }
        return 'Low';
    }

    /** The Contact field values that store a score (written by PatientPriorityBatch). */
    public static Contact toContact(PatientScore s) {
        return new Contact(
            Id = s.patientId,
            Priority_Score__c = s.score,
            Priority_Level__c = s.level,
            Priority_Explanation__c = s.explanation().left(5000),
            Next_Best_Action__c = s.nextBestAction.left(255),
            Open_Care_Gaps__c = s.openGaps,
            Overdue_Activities__c = s.overdue,
            Priority_Calculated_On__c = System.now()
        );
    }

    private static void addCounted(PatientScore result, String ruleKey, Integer count, Boolean perItem) {
        if (count == null || count <= 0) {
            return;
        }
        Integer items = perItem ? Math.min(count, MAX_ITEMS_PER_RULE) : 1;
        addReason(result, ruleKey, items, count);
    }

    private static void addReason(PatientScore result, String ruleKey, Integer items, Integer n) {
        Care_Rule__mdt rule = CareRules.rule(ruleKey);
        if (rule == null || rule.Points__c == null) {
            return;
        }
        Integer points = rule.Points__c.intValue() * items;
        String text = rule.Explanation__c == null ? ruleKey : rule.Explanation__c;
        text = text.replace('{n}', String.valueOf(n));
        text = text.replace('{t}', rule.Threshold__c == null ? '' : String.valueOf(rule.Threshold__c.intValue()));
        result.score += points;
        result.reasons.add(new Reason(ruleKey, points, text));
    }

    private static String nextBestAction(PatientScore result, Boolean clinicalFlag, Boolean needsHelp,
                                         Care_Activity__c followUp, Care_Activity__c imm, Care_Activity__c checkUp,
                                         Contact patient) {
        if (clinicalFlag) {
            return 'Red-flag visit: make sure the doctor has reviewed it and re-check vitals within 48 hours';
        }
        if (needsHelp) {
            return 'Call the patient back: they asked for help';
        }
        if (followUp != null) {
            return 'Complete the doctor-ordered follow-up: ' + followUp.Name;
        }
        if (imm != null) {
            return 'Give the overdue vaccine at a home visit or the next session: ' + imm.Name;
        }
        if (checkUp != null) {
            return 'Arrange the overdue check-up: ' + checkUp.Name;
        }
        if (result.openGaps > 0) {
            return 'Confirm the upcoming appointment: ' + result.actionable[0].Name;
        }
        if (patient.Is_Pregnant__c == true) {
            return 'Confirm the next antenatal check-up date';
        }
        return 'No action needed today';
    }

    private class ByPointsDesc implements Comparator<Reason> {
        public Integer compare(Reason a, Reason b) {
            return b.points - a.points;
        }
    }
}
