/**
 * Reads CareLoop configuration from custom metadata and holds the shared status rules.
 *
 * Custom metadata is read with getAll()/getInstance(), which uses no SOQL queries, and is
 * cached for the transaction. Admins change schedules, thresholds, the escalation ladder
 * and settings in Setup without touching code.
 *
 * Tests never depend on the values an admin may change: in a test, the CareLoop setting
 * (including the demo clock) is ignored unless the test injects one, and tests can inject
 * rules, schedules and escalation rules through the @TestVisible fields below.
 */
public with sharing class CareRules {

    public static final String STATUS_SCHEDULED = 'Scheduled';
    public static final String STATUS_DUE = 'Due';
    public static final String STATUS_OVERDUE = 'Overdue';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_MISSED = 'Missed';
    public static final String STATUS_CANCELLED = 'Cancelled';

    public static final Set<String> OPEN_STATUSES = new Set<String>{ STATUS_SCHEDULED, STATUS_DUE, STATUS_OVERDUE };
    public static final Set<String> CLOSED_STATUSES = new Set<String>{ STATUS_COMPLETED, STATUS_MISSED, STATUS_CANCELLED };

    private static final Integer DEFAULT_DUE_WINDOW_DAYS = 3;

    @TestVisible
    private static Map<String, Care_Rule__mdt> careRules;
    @TestVisible
    private static List<Care_Schedule__mdt> schedules;
    @TestVisible
    private static List<Escalation_Rule__mdt> escalationRules;
    @TestVisible
    private static CareLoop_Setting__mdt settingRecord;

    /** Active care rules keyed by developer name, e.g. RF_BP_SYSTOLIC. */
    public static Map<String, Care_Rule__mdt> rules() {
        if (careRules == null) {
            careRules = new Map<String, Care_Rule__mdt>();
            for (Care_Rule__mdt r : Care_Rule__mdt.getAll().values()) {
                if (r.Active__c) {
                    careRules.put(r.DeveloperName, r);
                }
            }
        }
        return careRules;
    }

    public static Care_Rule__mdt rule(String key) {
        return rules().get(key);
    }

    public static Decimal threshold(String key, Decimal fallback) {
        Care_Rule__mdt r = rule(key);
        return (r == null || r.Threshold__c == null) ? fallback : r.Threshold__c;
    }

    public static Decimal points(String key, Decimal fallback) {
        Care_Rule__mdt r = rule(key);
        return (r == null || r.Points__c == null) ? fallback : r.Points__c;
    }

    /** Active care schedules (immunisation doses, antenatal, monitoring, screening). */
    public static List<Care_Schedule__mdt> activeSchedules() {
        if (schedules == null) {
            schedules = new List<Care_Schedule__mdt>();
            for (Care_Schedule__mdt s : Care_Schedule__mdt.getAll().values()) {
                if (s.Active__c) {
                    schedules.add(s);
                }
            }
        }
        return schedules;
    }

    /** Active escalation rules, sorted by level (1, 2, 3). */
    public static List<Escalation_Rule__mdt> activeEscalationRules() {
        if (escalationRules == null) {
            Map<Integer, Escalation_Rule__mdt> byLevel = new Map<Integer, Escalation_Rule__mdt>();
            for (Escalation_Rule__mdt r : Escalation_Rule__mdt.getAll().values()) {
                if (r.Active__c && r.Level__c != null) {
                    byLevel.put(r.Level__c.intValue(), r);
                }
            }
            List<Integer> levels = new List<Integer>(byLevel.keySet());
            levels.sort();
            escalationRules = new List<Escalation_Rule__mdt>();
            for (Integer level : levels) {
                escalationRules.add(byLevel.get(level));
            }
        }
        return escalationRules;
    }

    /** The single CareLoop setting record ("Default"). Never null. */
    public static CareLoop_Setting__mdt setting() {
        if (settingRecord == null) {
            if (!Test.isRunningTest()) {
                settingRecord = CareLoop_Setting__mdt.getInstance('Default');
            }
            if (settingRecord == null) {
                settingRecord = new CareLoop_Setting__mdt();
            }
        }
        return settingRecord;
    }

    /**
     * How many days before its due date an activity counts as "Due". Taken from escalation
     * level 1 (the patient reminder, 3 days before by default), so the status a worker sees
     * and the moment the patient is reminded always agree.
     */
    public static Integer dueWindowDays() {
        for (Escalation_Rule__mdt r : activeEscalationRules()) {
            if (r.Level__c == 1 && r.Days_From_Due__c != null && r.Days_From_Due__c < 0) {
                return -r.Days_From_Due__c.intValue();
            }
        }
        return DEFAULT_DUE_WINDOW_DAYS;
    }

    /** Status of an open activity on a given day: Overdue, Due or Scheduled. */
    public static String openStatusFor(Date dueDate, Date today) {
        if (dueDate == null) {
            return STATUS_SCHEDULED;
        }
        if (dueDate < today) {
            return STATUS_OVERDUE;
        }
        if (dueDate <= today.addDays(dueWindowDays())) {
            return STATUS_DUE;
        }
        return STATUS_SCHEDULED;
    }

    public static Integer daysOverdue(Date dueDate, Date today) {
        if (dueDate == null || dueDate >= today) {
            return 0;
        }
        return dueDate.daysBetween(today);
    }

    public static Boolean isOpen(String status) {
        return status == null || OPEN_STATUSES.contains(status);
    }

    public static Boolean isClosed(String status) {
        return status != null && CLOSED_STATUSES.contains(status);
    }
}
