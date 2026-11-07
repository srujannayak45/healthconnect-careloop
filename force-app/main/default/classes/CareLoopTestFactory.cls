/**
 * Builds valid, synthetic CareLoop test data for Apex tests.
 * Every record satisfies the Phase 1 validation rules, because tests run as a normal admin
 * without the validation bypass.
 */
@IsTest
public class CareLoopTestFactory {

    private static Integer counter = 0;

    /** Pins the CareLoop clock to the real date for the current test. */
    public static void useRealToday() {
        CareLoopClock.testToday = Date.today();
    }

    public static Village__c insertVillage(Id healthWorkerId) {
        counter++;
        Village__c village = new Village__c(
            Name = 'Test Village ' + counter,
            District__c = 'Test District',
            State__c = 'Telangana',
            Region__c = 'North',
            Health_Worker__c = healthWorkerId
        );
        insert village;
        return village;
    }

    public static Account insertHousehold(Id villageId) {
        counter++;
        Account household = new Account(Name = 'Test Household ' + counter, Village__c = villageId);
        insert household;
        return household;
    }

    /** A valid female patient assigned to the running user (not inserted). */
    public static Contact newPatient(Id householdId, Id villageId, Date birthdate) {
        counter++;
        return new Contact(
            FirstName = 'Test',
            LastName = 'Patient' + counter,
            AccountId = householdId,
            Village__c = villageId,
            Birthdate = birthdate,
            Gender__c = 'Female',
            MobilePhone = '9' + String.valueOf(100000000 + counter),
            Preferred_Language__c = 'English',
            Preferred_Channel__c = 'Portal Inbox',
            Assigned_Health_Worker__c = UserInfo.getUserId()
        );
    }

    /** Creates a village, a household and one patient. */
    public static Contact insertPatient(Date birthdate) {
        Village__c village = insertVillage(null);
        Account household = insertHousehold(village.Id);
        Contact patient = newPatient(household.Id, village.Id, birthdate);
        insert patient;
        return patient;
    }

    /** A completed home visit with no vitals (not inserted). */
    public static Health_Visit__c newVisit(Id patientId) {
        return new Health_Visit__c(
            Patient__c = patientId,
            Visit_Date__c = System.now(),
            Visit_Type__c = 'Home Visit',
            Visit_Outcome__c = 'Completed'
        );
    }

    /** A manual routine check-up (not inserted). */
    public static Care_Activity__c newActivity(Id patientId, Date dueDate) {
        counter++;
        return new Care_Activity__c(
            Name = 'Test activity ' + counter,
            Patient__c = patientId,
            Activity_Type__c = 'Routine Check-up',
            Due_Date__c = dueDate
        );
    }

    /** An in-memory Care_Schedule__mdt record (custom metadata cannot be inserted in tests). */
    public static Care_Schedule__mdt schedule(
        String developerName, String activityType, String name, Integer dose, Integer offsetDays,
        String anchor, String eligibility, Integer repeatEveryDays, Integer occurrences
    ) {
        Map<String, Object> fields = new Map<String, Object>{
            'DeveloperName' => developerName,
            'MasterLabel' => name,
            'Activity_Type__c' => activityType,
            'Activity_Name__c' => name,
            'Dose_Number__c' => dose,
            'Offset_Days__c' => offsetDays,
            'Anchor__c' => anchor,
            'Eligibility__c' => eligibility,
            'Repeat_Every_Days__c' => repeatEveryDays,
            'Occurrences__c' => occurrences,
            'Active__c' => true
        };
        return (Care_Schedule__mdt) JSON.deserialize(JSON.serialize(fields), Care_Schedule__mdt.class);
    }

    /** An in-memory Care_Rule__mdt record. */
    public static Care_Rule__mdt rule(String developerName, String category, Decimal points, Decimal threshold, String explanation) {
        Map<String, Object> fields = new Map<String, Object>{
            'DeveloperName' => developerName,
            'MasterLabel' => developerName,
            'Category__c' => category,
            'Points__c' => points,
            'Threshold__c' => threshold,
            'Explanation__c' => explanation,
            'Active__c' => true
        };
        return (Care_Rule__mdt) JSON.deserialize(JSON.serialize(fields), Care_Rule__mdt.class);
    }

    /** The default red-flag thresholds, independent of what an admin configures. */
    public static Map<String, Care_Rule__mdt> redFlagRules() {
        return new Map<String, Care_Rule__mdt>{
            'RF_BP_SYSTOLIC' => rule('RF_BP_SYSTOLIC', 'Red Flag', null, 180, 'Systolic BP {v} mmHg'),
            'RF_BP_DIASTOLIC' => rule('RF_BP_DIASTOLIC', 'Red Flag', null, 110, 'Diastolic BP {v} mmHg'),
            'RF_SPO2' => rule('RF_SPO2', 'Red Flag', null, 92, 'SpO2 {v}%'),
            'RF_TEMPERATURE' => rule('RF_TEMPERATURE', 'Red Flag', null, 39.5, 'Temperature {v} C'),
            'RF_BLOOD_SUGAR' => rule('RF_BLOOD_SUGAR', 'Red Flag', null, 300, 'Blood sugar {v} mg/dL')
        };
    }

    /** Number of activities the org's real configuration creates for one eligibility group. */
    public static Integer configuredOccurrences(String eligibility) {
        Integer total = 0;
        for (Care_Schedule__mdt s : Care_Schedule__mdt.getAll().values()) {
            if (s.Active__c && s.Eligibility__c == eligibility) {
                total += (s.Occurrences__c == null || s.Occurrences__c < 1) ? 1 : s.Occurrences__c.intValue();
            }
        }
        return total;
    }
}
