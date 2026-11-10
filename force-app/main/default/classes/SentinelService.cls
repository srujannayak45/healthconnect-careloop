/**
 * CareLoop Sentinel - community health early warning.
 *
 * Every day it compares, for each village and each configured signal (Surveillance_Signal__mdt),
 * the count in the latest 7 days with the same village's own previous weeks:
 *
 *     expected  = mean of the baseline weeks          (default: the 4 weeks before)
 *     spread    = standard deviation of those weeks, never below 1 (tiny baselines are not "certain")
 *     z         = (observed - expected) / spread
 *     Watch     when z >= Watch_Z (2) and observed >= Min_Count (3)
 *     Alert     when z >= Alert_Z (3) and observed >= Min_Count
 *     Not assessed when fewer than Min_History_Weeks (2) of the baseline weeks contain ANY recorded
 *               visit (or dose, for activity signals): missing data is not the same as zero cases.
 *
 * This is the idea of the CDC EARS aberration-detection methods used in syndromic surveillance,
 * applied to data CareLoop already collects (symptoms, temperature and SpO2 on visits; visit
 * outcomes; vaccine doses given late). It flags *unusual change* for a human to investigate. It does
 * not diagnose anything or predict outbreaks.
 *
 * Signals live in custom metadata, so the programme can tune thresholds, add symptoms or switch
 * signals off without code. Results hold counts only; the contributing records are stored as Ids,
 * and every drill-down re-applies the viewer's sharing (CommunityWatchController.getEvidence).
 */
public with sharing class SentinelService {

    public static final String SOURCE_VISIT = 'Health Visit';
    public static final String SOURCE_ACTIVITY = 'Care Activity';
    public static final String NORMAL = 'Normal';
    public static final String WATCH = 'Watch';
    public static final String ALERT = 'Alert';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_INVESTIGATING = 'Investigating';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_DISMISSED = 'Dismissed';
    /** A reviewed signal with one of these statuses is not raised again for the same 7-day window. */
    public static final Set<String> SUPPRESSING_STATUSES = new Set<String>{ STATUS_CLOSED, STATUS_DISMISSED };
    public static final String MANAGER_PERMISSION_SET = 'CareLoop_Sentinel_Manager';
    public static final Integer WINDOW_DAYS = 7;
    public static final Decimal MIN_SPREAD = 1;
    public static final Integer DEFAULT_MIN_HISTORY_WEEKS = 2;

    @TestVisible
    private static List<Surveillance_Signal__mdt> signalOverride;

    public class SignalResult {
        @AuraEnabled public Id villageId;
        @AuraEnabled public String villageName;
        @AuraEnabled public String region;
        @AuraEnabled public String signalKey;
        @AuraEnabled public String signalLabel;
        @AuraEnabled public Integer observed = 0;
        @AuraEnabled public Decimal expected = 0;
        @AuraEnabled public Decimal spread = MIN_SPREAD;
        @AuraEnabled public Decimal threshold = 0;
        @AuraEnabled public Decimal z = 0;
        @AuraEnabled public Integer households = 0;
        @AuraEnabled public Decimal ratePer1000;
        @AuraEnabled public String severity = NORMAL;
        @AuraEnabled public Boolean insufficientHistory = false;
        @AuraEnabled public List<Integer> weekly = new List<Integer>();
        @AuraEnabled public Date windowStart;
        @AuraEnabled public Date windowEnd;
        @AuraEnabled public String explanation;
        @AuraEnabled public String guidance;
        public List<Id> evidenceIds = new List<Id>();
        public Set<Id> householdIds = new Set<Id>();
        public List<Integer> baselineCounts = new List<Integer>();
        /** Baseline weeks (1..n) in which the village has ANY recorded visit / dose of the right kind. */
        public Set<Integer> historyWeeks = new Set<Integer>();
    }

    public class ScanSummary {
        @AuraEnabled public Integer cellsEvaluated = 0;
        @AuraEnabled public Integer flagged = 0;
        @AuraEnabled public Integer created = 0;
        @AuraEnabled public Integer updated = 0;
        @AuraEnabled public Integer notified = 0;
    }

    /** Active signals from custom metadata (or injected by tests). */
    public static List<Surveillance_Signal__mdt> signals() {
        if (signalOverride != null) {
            return signalOverride;
        }
        List<Surveillance_Signal__mdt> active = new List<Surveillance_Signal__mdt>();
        for (Surveillance_Signal__mdt s : Surveillance_Signal__mdt.getAll().values()) {
            if (s.Active__c) {
                active.add(s);
            }
        }
        return active;
    }

    /** Evaluates every village x signal as of the given day. Reads only. */
    public static List<SignalResult> evaluate(Date asOf) {
        List<SignalResult> results = new List<SignalResult>();
        List<Surveillance_Signal__mdt> configured = signals();
        if (configured.isEmpty()) {
            return results;
        }
        Map<Id, Village__c> villages = new Map<Id, Village__c>([
            SELECT Id, Name, Region__c, Population__c FROM Village__c
            WHERE Active__c = true
            WITH SYSTEM_MODE
            ORDER BY Region__c, Name
            LIMIT 500
        ]);
        Integer maxWeeks = 1;
        Integer maxGrace = 0;
        Boolean needVisits = false;
        Boolean needActivities = false;
        for (Surveillance_Signal__mdt s : configured) {
            maxWeeks = Math.max(maxWeeks, baselineWeeks(s));
            if (s.Source__c == SOURCE_ACTIVITY) {
                needActivities = true;
                maxGrace = Math.max(maxGrace, graceDays(s));
            } else {
                needVisits = true;
            }
        }
        Date earliest = asOf.addDays(-(WINDOW_DAYS * (maxWeeks + 1)) - maxGrace);
        List<Health_Visit__c> visits = needVisits ? [
            SELECT Id, Visit_Date__c, Symptoms__c, Temperature__c, SpO2__c, Visit_Outcome__c,
                   Patient__r.AccountId, Patient__r.Village__c, Patient__r.Account.Village__c
            FROM Health_Visit__c
            WHERE Visit_Date__c >= :Datetime.newInstance(earliest, Time.newInstance(0, 0, 0, 0))
              AND Visit_Date__c < :Datetime.newInstance(asOf.addDays(1), Time.newInstance(0, 0, 0, 0))
            WITH SYSTEM_MODE
            LIMIT 40000
        ] : new List<Health_Visit__c>();
        List<Care_Activity__c> activities = needActivities ? [
            SELECT Id, Activity_Type__c, Due_Date__c, Status__c, Completed_Date__c,
                   Patient__r.AccountId, Patient__r.Village__c, Patient__r.Account.Village__c
            FROM Care_Activity__c
            WHERE Due_Date__c >= :earliest AND Due_Date__c <= :asOf
            WITH SYSTEM_MODE
            LIMIT 40000
        ] : new List<Care_Activity__c>();

        for (Surveillance_Signal__mdt s : configured) {
            Map<Id, SignalResult> byVillage = new Map<Id, SignalResult>();
            for (Village__c v : villages.values()) {
                byVillage.put(v.Id, newResult(v, s, asOf));
            }
            Integer weeks = baselineWeeks(s);
            if (s.Source__c == SOURCE_ACTIVITY) {
                Integer grace = graceDays(s);
                Date windowEnd = asOf.addDays(-grace);
                Set<String> types = splitSet(s.Activity_Types__c);
                for (Care_Activity__c a : activities) {
                    if (!types.isEmpty() && !types.contains(a.Activity_Type__c)) {
                        continue;
                    }
                    if (a.Status__c == CareRules.STATUS_CANCELLED) {
                        continue;   // approved closures (moved away, duplicate...) are not delays
                    }
                    markHistory(byVillage, villageOf(a.Patient__r), a.Due_Date__c, windowEnd, weeks);
                    Boolean late = a.Completed_Date__c == null || a.Completed_Date__c > a.Due_Date__c.addDays(grace);
                    if (!late) {
                        continue;
                    }
                    count(byVillage, villageOf(a.Patient__r), a.Patient__r.AccountId, a.Id, a.Due_Date__c, windowEnd, weeks);
                }
            } else {
                Set<String> symptoms = splitSet(s.Symptoms__c);
                Set<String> outcomes = splitSet(s.Visit_Outcomes__c);
                for (Health_Visit__c v : visits) {
                    markHistory(byVillage, villageOf(v.Patient__r), v.Visit_Date__c.date(), asOf, weeks);
                    if (!matches(v, s, symptoms, outcomes)) {
                        continue;
                    }
                    count(byVillage, villageOf(v.Patient__r), v.Patient__r.AccountId, v.Id, v.Visit_Date__c.date(), asOf, weeks);
                }
            }
            for (SignalResult r : byVillage.values()) {
                score(r, s, villages.get(r.villageId));
                results.add(r);
            }
        }
        return results;
    }

    /**
     * Evaluates and records the flagged signals. An open or dismissed signal for the same village and
     * signal from the last 7 days is updated (or, if dismissed, left alone) instead of creating a
     * new one each day, so an ongoing cluster is one investigation, not seven.
     */
    public static ScanSummary scan(Date asOf, Boolean sendNotifications) {
        ScanSummary summary = new ScanSummary();
        List<SignalResult> results = evaluate(asOf);
        summary.cellsEvaluated = results.size();
        List<SignalResult> flagged = new List<SignalResult>();
        Set<Id> villageIds = new Set<Id>();
        for (SignalResult r : results) {
            if (r.severity != NORMAL) {
                flagged.add(r);
                villageIds.add(r.villageId);
            }
        }
        summary.flagged = flagged.size();
        if (flagged.isEmpty()) {
            return summary;
        }

Map<String, Community_Signal__c> recent = new Map<String, Community_Signal__c>();
Set<String> candidateKeys = new Set<String>();

// Build keys for the current scan date and previous six days.
// This makes suppression depend on the scan date, not execution time.
for (SignalResult r : flagged) {
    for (Integer dayOffset = 0; dayOffset < WINDOW_DAYS; dayOffset++) {
        Date scanDate = asOf.addDays(-dayOffset);

        String alertKey = String.valueOf(r.villageId) + '-' +
            r.signalKey + '-' +
            Datetime.newInstance(
                scanDate,
                Time.newInstance(0, 0, 0, 0)
            ).format('yyyyMMdd');

        candidateKeys.add(alertKey);
    }
}

// Find signals scanned within the seven-day window.
// Alert_Key__c also handles signals whose observation window ends earlier
// because of a configured grace period.
for (Community_Signal__c c : [
    SELECT Id, Village__c, Signal_Key__c, Status__c,
           Severity__c, Window_End__c, Last_Scanned_On__c,
           Alert_Key__c
    FROM Community_Signal__c
    WHERE Village__c IN :villageIds
      AND Alert_Key__c IN :candidateKeys
    WITH SYSTEM_MODE
    ORDER BY Alert_Key__c DESC
]) {
    String key = c.Village__c + '|' + c.Signal_Key__c;

    if (!recent.containsKey(key)) {
        recent.put(key, c);
    }
}
        List<Community_Signal__c> toInsert = new List<Community_Signal__c>();
        List<Community_Signal__c> toUpdate = new List<Community_Signal__c>();
        List<SignalResult> toNotify = new List<SignalResult>();
        for (SignalResult r : flagged) {
            Community_Signal__c existing = recent.get(r.villageId + '|' + r.signalKey);
            if (existing != null && SUPPRESSING_STATUSES.contains(existing.Status__c)) {
                continue;   // already reviewed (closed or dismissed) for this window
            }
            Community_Signal__c row = toRecord(r, asOf);
            if (existing == null) {
                row.Status__c = STATUS_NEW;
                toInsert.add(row);
                toNotify.add(r);
            } else {
                row.Id = existing.Id;
                if (r.severity == ALERT && existing.Severity__c != ALERT) {
                    toNotify.add(r);       // escalated from Watch to Alert
                }
                toUpdate.add(row);
            }
        }
        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, true, AccessLevel.SYSTEM_MODE);
            summary.created = toInsert.size();
        }
        if (!toUpdate.isEmpty()) {
            List<Community_Signal__c> clean = new List<Community_Signal__c>();
            for (Community_Signal__c row : toUpdate) {
                clean.add(withoutKey(row));   // keep the key, status and notes of the open investigation
            }
            Database.update(clean, true, AccessLevel.SYSTEM_MODE);
            summary.updated = clean.size();
        }
        if (sendNotifications && !toNotify.isEmpty()) {
            summary.notified = notifyReviewers(toNotify, toInsert, toUpdate);
        }
        return summary;
    }

    // ------------------------------------------------------------------ helpers

    private static SignalResult newResult(Village__c v, Surveillance_Signal__mdt s, Date asOf) {
        SignalResult r = new SignalResult();
        r.villageId = v.Id;
        r.villageName = v.Name;
        r.region = v.Region__c;
        r.signalKey = s.DeveloperName;
        r.signalLabel = s.MasterLabel;
        r.guidance = s.Guidance__c;
        Integer weeks = baselineWeeks(s);
        Integer grace = s.Source__c == SOURCE_ACTIVITY ? graceDays(s) : 0;
        r.windowEnd = asOf.addDays(-grace);
        r.windowStart = r.windowEnd.addDays(-(WINDOW_DAYS - 1));
        for (Integer i = 0; i < weeks; i++) {
            r.baselineCounts.add(0);
        }
        return r;
    }

    /** Puts one matching event into the current week (index 0) or a baseline week (1..weeks). */
    private static void count(Map<Id, SignalResult> byVillage, Id villageId, Id householdId, Id recordId,
                              Date eventDate, Date windowEnd, Integer weeks) {
        if (villageId == null || !byVillage.containsKey(villageId) || eventDate == null || eventDate > windowEnd) {
            return;
        }
        Integer week = eventDate.daysBetween(windowEnd) / WINDOW_DAYS;
        if (week > weeks) {
            return;
        }
        SignalResult r = byVillage.get(villageId);
        if (week == 0) {
            r.observed++;
            if (householdId != null) {
                r.householdIds.add(householdId);
            }
            r.evidenceIds.add(recordId);
        } else {
            r.baselineCounts[week - 1] = r.baselineCounts[week - 1] + 1;
        }
    }

    /** Remembers that the village had data in a baseline week (needed before any signal is raised). */
    private static void markHistory(Map<Id, SignalResult> byVillage, Id villageId, Date eventDate, Date windowEnd, Integer weeks) {
        if (villageId == null || !byVillage.containsKey(villageId) || eventDate == null || eventDate > windowEnd) {
            return;
        }
        Integer week = eventDate.daysBetween(windowEnd) / WINDOW_DAYS;
        if (week >= 1 && week <= weeks) {
            byVillage.get(villageId).historyWeeks.add(week);
        }
    }

    @TestVisible
    private static void score(SignalResult r, Surveillance_Signal__mdt s, Village__c village) {
        Integer n = r.baselineCounts.size();
        Decimal total = 0;
        for (Integer c : r.baselineCounts) {
            total += c;
        }
        Decimal mean = 0;
        if (n > 0) {
            mean = total / n;
        }
        Decimal sumSq = 0;
        for (Integer c : r.baselineCounts) {
            sumSq += (c - mean) * (c - mean);
        }
        Decimal sd = 0;
        if (n > 1) {
            sd = Decimal.valueOf(Math.sqrt((sumSq / (n - 1)).doubleValue()));
        }
        r.expected = mean.setScale(2);
        r.spread = Math.max(sd, MIN_SPREAD).setScale(2);
        Decimal watchZ = s.Watch_Z__c == null ? Decimal.valueOf(2) : s.Watch_Z__c;
        Decimal alertZ = s.Alert_Z__c == null ? Decimal.valueOf(3) : s.Alert_Z__c;
        Integer minCount = s.Min_Count__c == null ? 3 : s.Min_Count__c.intValue();
        r.threshold = (mean + watchZ * r.spread).setScale(2);
        r.z = ((r.observed - mean) / r.spread).setScale(2);
        r.households = r.householdIds.size();
        if (village != null && village.Population__c != null && village.Population__c > 0) {
            r.ratePer1000 = (r.observed * 1000 / village.Population__c).setScale(2);
        }
        Integer minHistory = minHistoryWeeks(s, n);
        r.insufficientHistory = r.historyWeeks.size() < minHistory;
        if (r.insufficientHistory) {
            r.severity = NORMAL;   // never compare against missing data
        } else if (r.observed >= minCount && r.z >= alertZ) {
            r.severity = ALERT;
        } else if (r.observed >= minCount && r.z >= watchZ) {
            r.severity = WATCH;
        }
        // weekly: oldest baseline week first, current week last (for the chart)
        for (Integer i = n - 1; i >= 0; i--) {
            r.weekly.add(r.baselineCounts[i]);
        }
        r.weekly.add(r.observed);
        r.explanation = r.insufficientHistory ? explainNoHistory(r, s, n, minHistory) : explain(r, s, minCount);
    }

    private static String explainNoHistory(SignalResult r, Surveillance_Signal__mdt s, Integer weeks, Integer minHistory) {
        String unit = s.Source__c == SOURCE_ACTIVITY ? 'vaccine/care doses' : 'visits';
        return r.signalLabel + ' in ' + r.villageName + ': not assessed. Only ' + r.historyWeeks.size() + ' of the previous '
            + weeks + ' weeks have any recorded ' + unit + ' (at least ' + minHistory + ' needed), so there is no reliable'
            + ' normal level to compare with. Missing data is not treated as zero cases.';
    }

    private static String explain(SignalResult r, Surveillance_Signal__mdt s, Integer minCount) {
        String what = s.Source__c == SOURCE_ACTIVITY
            ? 'vaccine/care doses due ' + fmt(r.windowStart) + ' - ' + fmt(r.windowEnd) + ' not given within '
                + graceDays(s) + ' days'
            : 'visits ' + fmt(r.windowStart) + ' - ' + fmt(r.windowEnd);
        List<String> baseline = new List<String>();
        for (Integer i = 0; i < r.weekly.size() - 1; i++) {
            baseline.add(String.valueOf(r.weekly[i]));
        }
        String text = r.signalLabel + ' in ' + r.villageName + ': ' + r.observed + ' ' + what
            + (r.households > 0 ? ', from ' + r.households + ' household(s)' : '')
            + '. Normal for this village: ' + r.expected.setScale(1) + ' per week (previous weeks: '
            + String.join(baseline, ', ') + '). That is ' + r.z.setScale(1) + ' standard deviations above normal'
            + ' (watch level ' + r.threshold.setScale(1) + ', minimum ' + minCount + ' events).';
        if (r.ratePer1000 != null) {
            text += ' Rate: ' + r.ratePer1000 + ' per 1,000 people.';
        }
        return text;
    }

    private static Boolean matches(Health_Visit__c v, Surveillance_Signal__mdt s, Set<String> symptoms, Set<String> outcomes) {
        if (!outcomes.isEmpty()) {
            return outcomes.contains(v.Visit_Outcome__c);
        }
        if (!symptoms.isEmpty() && v.Symptoms__c != null) {
            for (String recorded : v.Symptoms__c.split(';')) {
                if (symptoms.contains(recorded.trim())) {
                    return true;
                }
            }
        }
        if (s.Min_Temperature__c != null && v.Temperature__c != null && v.Temperature__c >= s.Min_Temperature__c) {
            return true;
        }
        if (s.Max_SpO2__c != null && v.SpO2__c != null && v.SpO2__c < s.Max_SpO2__c) {
            return true;
        }
        return false;
    }

    private static Id villageOf(Contact patient) {
        if (patient == null) {
            return null;
        }
        if (patient.Village__c != null) {
            return patient.Village__c;
        }
        return patient.Account == null ? null : patient.Account.Village__c;
    }

    private static Community_Signal__c toRecord(SignalResult r, Date asOf) {
        List<String> weekly = new List<String>();
        for (Integer c : r.weekly) {
            weekly.add(String.valueOf(c));
        }
        return new Community_Signal__c(
            Name = (r.signalLabel + ' - ' + r.villageName).left(80),
            Village__c = r.villageId,
            Signal_Key__c = r.signalKey,
            Signal_Label__c = r.signalLabel,
            Window_Start__c = r.windowStart,
            Window_End__c = r.windowEnd,
            Observed__c = r.observed,
            Expected__c = r.expected,
            Std_Dev__c = r.spread,
            Threshold__c = r.threshold,
            Z_Score__c = r.z,
            Households__c = r.households,
            Rate_Per_1000__c = r.ratePer1000,
            Severity__c = r.severity,
            Explanation__c = r.explanation.left(2000),
            Guidance__c = r.guidance == null ? null : r.guidance.left(255),
            Weekly_Counts__c = String.join(weekly, ',').left(120),
            Evidence_Ids__c = String.join(r.evidenceIds, ',').left(10000),
            Last_Scanned_On__c = System.now(),
            Alert_Key__c = (String.valueOf(r.villageId) + '-' + r.signalKey + '-'
                + Datetime.newInstance(asOf, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd')).left(120)
        );
    }

    private static Community_Signal__c withoutKey(Community_Signal__c row) {
        Community_Signal__c u = new Community_Signal__c(Id = row.Id);
        for (String field : new List<String>{ 'Name', 'Window_Start__c', 'Window_End__c', 'Observed__c', 'Expected__c',
                'Std_Dev__c', 'Threshold__c', 'Z_Score__c', 'Households__c', 'Rate_Per_1000__c', 'Severity__c',
                'Explanation__c', 'Guidance__c', 'Weekly_Counts__c', 'Evidence_Ids__c', 'Last_Scanned_On__c' }) {
            u.put(field, row.get(field));
        }
        return u;
    }

    private static Integer notifyReviewers(List<SignalResult> toNotify, List<Community_Signal__c> inserted,
                                           List<Community_Signal__c> updated) {
        Set<Id> reviewers = CareLoopAlertService.doctors();
        for (PermissionSetAssignment a : [
            SELECT AssigneeId FROM PermissionSetAssignment
            WHERE PermissionSet.Name = :MANAGER_PERMISSION_SET AND Assignee.IsActive = true
            WITH SYSTEM_MODE
        ]) {
            reviewers.add(a.AssigneeId);
        }
        Map<String, Id> recordByKey = new Map<String, Id>();
        for (Community_Signal__c c : inserted) {
            recordByKey.put(c.Village__c + '|' + c.Signal_Key__c, c.Id);
        }
        for (Community_Signal__c c : updated) {
            recordByKey.put(c.Village__c + '|' + c.Signal_Key__c, c.Id);
        }
        Integer sent = 0;
        for (SignalResult r : toNotify) {
            Id target = recordByKey.get(r.villageId + '|' + r.signalKey);
            Boolean ok = CareLoopAlertService.notify(reviewers,
                'Community ' + r.severity.toLowerCase() + ': ' + r.signalLabel + ' in ' + r.villageName,
                r.explanation, target);
            sent += ok ? 1 : 0;
        }
        return sent;
    }

    private static Integer baselineWeeks(Surveillance_Signal__mdt s) {
        return (s.Baseline_Weeks__c == null || s.Baseline_Weeks__c < 2) ? 4 : s.Baseline_Weeks__c.intValue();
    }

    private static Integer minHistoryWeeks(Surveillance_Signal__mdt s, Integer baselineWeeks) {
        Integer configured = s.Min_History_Weeks__c == null ? DEFAULT_MIN_HISTORY_WEEKS : s.Min_History_Weeks__c.intValue();
        return Math.min(Math.max(configured, 1), baselineWeeks);
    }

    private static Integer graceDays(Surveillance_Signal__mdt s) {
        return s.Grace_Days__c == null ? 7 : s.Grace_Days__c.intValue();
    }

    private static Set<String> splitSet(String text) {
        Set<String> out = new Set<String>();
        if (String.isBlank(text)) {
            return out;
        }
        for (String part : text.split(';')) {
            if (String.isNotBlank(part)) {
                out.add(part.trim());
            }
        }
        return out;
    }

    private static String fmt(Date d) {
        return d == null ? '' : Datetime.newInstance(d, Time.newInstance(9, 0, 0, 0)).format('d MMM');
    }
}
