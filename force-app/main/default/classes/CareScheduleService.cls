/**
 * Generates the preventive-care obligations (Care Activities) each patient is eligible for.
 *
 * The rules live in Care_Schedule__mdt, not in code:
 *   Child Under 2  -> immunisation doses, due dates counted from the birth date
 *   Pregnant       -> antenatal check-ups, counted from the day pregnancy is recorded
 *   Hypertension / Diabetes -> monitoring check-ups, counted from the day the condition is recorded
 *   Adult 30 Plus  -> one annual health screening
 * ("Registration Date" anchors mean: the day the patient becomes eligible, i.e. today
 * on the CareLoop clock when generation runs.)
 *
 * Idempotent: every generated activity carries Schedule_Key__c = patientId-schedule-occurrence,
 * a unique external-ID field. Running generation again skips existing keys, and the database
 * itself rejects a duplicate key, so a patient can never receive the same dose twice.
 *
 * Doses already past their due date are still created, as Overdue: that is the catch-up list
 * the health worker verifies (marking doses given elsewhere as Completed).
 */
public with sharing class CareScheduleService {

    public static final String SOURCE_SCHEDULE = 'Care Schedule';
    public static final String ELIGIBILITY_CHILD = 'Child Under 2';
    public static final String ELIGIBILITY_PREGNANT = 'Pregnant';
    public static final String ELIGIBILITY_ADULT = 'Adult 30 Plus';
    public static final String ANCHOR_BIRTHDATE = 'Birthdate';

    /** Creates the missing scheduled activities for these patients. Returns how many were created. */
    public static Integer generate(Set<Id> patientIds) {
        if (patientIds == null || patientIds.isEmpty()) {
            return 0;
        }
        Date today = CareLoopClock.today();
        List<Contact> patients = [
            SELECT Id, Birthdate, Is_Pregnant__c, Chronic_Conditions__c, Assigned_Health_Worker__c
            FROM Contact
            WHERE Id IN :patientIds
            WITH SYSTEM_MODE
        ];
        Set<String> existingKeys = new Set<String>();
        for (Care_Activity__c existing : [
            SELECT Schedule_Key__c
            FROM Care_Activity__c
            WHERE Patient__c IN :patientIds AND Schedule_Key__c != null
            WITH SYSTEM_MODE
        ]) {
            existingKeys.add(existing.Schedule_Key__c);
        }

        List<Care_Activity__c> activities = new List<Care_Activity__c>();
        for (Contact patient : patients) {
            for (Care_Schedule__mdt schedule : CareRules.activeSchedules()) {
                if (isEligible(schedule, patient, today)) {
                    activities.addAll(buildActivities(schedule, patient, today, existingKeys));
                }
            }
        }
        return insertActivities(activities, 'CareScheduleService');
    }

    @TestVisible
    private static Boolean isEligible(Care_Schedule__mdt schedule, Contact patient, Date today) {
        String eligibility = schedule.Eligibility__c;
        if (eligibility == ELIGIBILITY_CHILD) {
            return patient.Birthdate != null && patient.Birthdate > today.addYears(-2);
        }
        if (eligibility == ELIGIBILITY_PREGNANT) {
            return patient.Is_Pregnant__c == true;
        }
        if (eligibility == ELIGIBILITY_ADULT) {
            return patient.Birthdate != null && patient.Birthdate <= today.addYears(-30);
        }
        return hasCondition(patient, eligibility);
    }

    private static Boolean hasCondition(Contact patient, String condition) {
        if (String.isBlank(condition) || String.isBlank(patient.Chronic_Conditions__c)) {
            return false;
        }
        return new Set<String>(patient.Chronic_Conditions__c.split(';')).contains(condition);
    }

    @TestVisible
    private static List<Care_Activity__c> buildActivities(
        Care_Schedule__mdt schedule, Contact patient, Date today, Set<String> existingKeys
    ) {
        List<Care_Activity__c> result = new List<Care_Activity__c>();
        Date anchor = schedule.Anchor__c == ANCHOR_BIRTHDATE ? patient.Birthdate : today;
        if (anchor == null) {
            return result;
        }
        Integer occurrences = (schedule.Occurrences__c == null || schedule.Occurrences__c < 1)
            ? 1
            : schedule.Occurrences__c.intValue();
        Integer offset = schedule.Offset_Days__c == null ? 0 : schedule.Offset_Days__c.intValue();
        Integer repeatEvery = schedule.Repeat_Every_Days__c == null ? 0 : schedule.Repeat_Every_Days__c.intValue();

        for (Integer i = 0; i < occurrences; i++) {
            String key = String.valueOf(patient.Id) + '-' + schedule.DeveloperName + '-' + (i + 1);
            if (existingKeys.contains(key)) {
                continue;
            }
            existingKeys.add(key);
            result.add(new Care_Activity__c(
                Name = activityName(schedule, i + 1, occurrences),
                Patient__c = patient.Id,
                Activity_Type__c = schedule.Activity_Type__c,
                Due_Date__c = anchor.addDays(offset + repeatEvery * i),
                Source__c = SOURCE_SCHEDULE,
                Schedule_Key__c = key,
                Dose_Number__c = schedule.Dose_Number__c,
                Assigned_To__c = patient.Assigned_Health_Worker__c,
                Description__c = ('Care schedule: ' + schedule.MasterLabel).left(255)
            ));
        }
        return result;
    }

    private static String activityName(Care_Schedule__mdt schedule, Integer occurrence, Integer occurrences) {
        String name = String.isBlank(schedule.Activity_Name__c) ? schedule.MasterLabel : schedule.Activity_Name__c;
        if (schedule.Dose_Number__c != null) {
            name += ' - dose ' + schedule.Dose_Number__c.intValue();
        }
        if (occurrences > 1) {
            name += ' (' + occurrence + ' of ' + occurrences + ')';
        }
        return name.left(80);
    }

    /**
     * Inserts generated activities with partial success and returns how many were created.
     * SYSTEM_MODE: Source, Schedule Key, Dose Number and Doctor Recommendation are engine-owned
     * fields that no user may edit; record sharing still applies ("with sharing"), so the running
     * user must have access to the patient. A duplicate key means the activity already exists and
     * is not an error; anything else is logged.
     */
    public static Integer insertActivities(List<Care_Activity__c> activities, String source) {
        if (activities == null || activities.isEmpty()) {
            return 0;
        }
        List<Database.SaveResult> results = Database.insert(activities, false, AccessLevel.SYSTEM_MODE);
        Integer created = 0;
        List<Database.SaveResult> failures = new List<Database.SaveResult>();
        List<SObject> failedRecords = new List<SObject>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                created++;
            } else if (!isDuplicateKey(results[i])) {
                failures.add(results[i]);
                failedRecords.add(activities[i]);
            }
        }
        if (!failures.isEmpty()) {
            ErrorLogger.logSaveResults(source, failures, failedRecords);
        }
        return created;
    }

    private static Boolean isDuplicateKey(Database.SaveResult result) {
        for (Database.Error e : result.getErrors()) {
            if (e.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
                return true;
            }
        }
        return false;
    }
}
