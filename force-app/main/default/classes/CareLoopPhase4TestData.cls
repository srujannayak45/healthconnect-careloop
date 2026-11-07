/**
 * Test data for the Phase 4 engine: configuration injected in memory (so tests never depend on
 * what an admin changes in Setup), staff users with a manager, and patients with open care.
 */
@IsTest
public class CareLoopPhase4TestData {

    private static Integer counter = 0;

    /** The default priority rules and level thresholds, as shipped in Phase 1. */
    public static void usePriorityRules() {
        Map<String, Care_Rule__mdt> rules = new Map<String, Care_Rule__mdt>{
            'OVERDUE_IMMUNIZATION' => CareLoopTestFactory.rule('OVERDUE_IMMUNIZATION', 'Priority', 4, null, '{n} overdue vaccine dose(s)'),
            'OVERDUE_FOLLOWUP' => CareLoopTestFactory.rule('OVERDUE_FOLLOWUP', 'Priority', 5, null, '{n} missed doctor follow-up(s)'),
            'OVERDUE_CHECKUP' => CareLoopTestFactory.rule('OVERDUE_CHECKUP', 'Priority', 3, null, '{n} overdue check-up(s)'),
            'LONG_OVERDUE' => CareLoopTestFactory.rule('LONG_OVERDUE', 'Priority', 2, 30, '{n} item(s) overdue more than {t} days'),
            'NO_CONTACT' => CareLoopTestFactory.rule('NO_CONTACT', 'Priority', 3, 60, 'No successful contact for {n} days'),
            'FAILED_OUTREACH' => CareLoopTestFactory.rule('FAILED_OUTREACH', 'Priority', 2, null, '{n} unsuccessful outreach attempt(s) in 90 days'),
            'PREGNANCY' => CareLoopTestFactory.rule('PREGNANCY', 'Priority', 2, null, 'Currently pregnant'),
            'INFANT' => CareLoopTestFactory.rule('INFANT', 'Priority', 1, null, 'Child under 2 years'),
            'RECENT_RED_FLAG' => CareLoopTestFactory.rule('RECENT_RED_FLAG', 'Priority', 6, 14, 'Red-flag visit in the last {t} days'),
            'PENDING_REVIEW' => CareLoopTestFactory.rule('PENDING_REVIEW', 'Priority', 4, null, 'Visit awaiting doctor review'),
            'PATIENT_NEEDS_HELP' => CareLoopTestFactory.rule('PATIENT_NEEDS_HELP', 'Priority', 3, null, 'Patient asked for help'),
            'SUPERVISOR_ESCALATION' => CareLoopTestFactory.rule('SUPERVISOR_ESCALATION', 'Priority', 2, null, '{n} activity(ies) escalated to supervisor'),
            'LEVEL_CRITICAL' => CareLoopTestFactory.rule('LEVEL_CRITICAL', 'Level', null, 15, 'Critical'),
            'LEVEL_HIGH' => CareLoopTestFactory.rule('LEVEL_HIGH', 'Level', null, 9, 'High'),
            'LEVEL_MEDIUM' => CareLoopTestFactory.rule('LEVEL_MEDIUM', 'Level', null, 4, 'Medium')
        };
        rules.putAll(CareLoopTestFactory.redFlagRules());
        CareRules.careRules = rules;
    }

    /** The default escalation ladder: -3 reminder, +3 worker task, +10 supervisor. */
    public static void useLadder() {
        CareRules.escalationRules = new List<Escalation_Rule__mdt>{
            ladderRule('Level_1', 1, -3, 'Patient Reminder', 'Remind the patient 3 days before the due date'),
            ladderRule('Level_2', 2, 3, 'Health Worker Task', 'Task the assigned health worker 3 days after the due date'),
            ladderRule('Level_3', 3, 10, 'Supervisor Escalation', 'Escalate to the supervisor 10 days after the due date')
        };
        Map<String, Object> setting = new Map<String, Object>{
            'DeveloperName' => 'Default', 'MasterLabel' => 'Default', 'Max_Reminders_Per_Activity__c' => 3
        };
        CareRules.settingRecord = (CareLoop_Setting__mdt) JSON.deserialize(JSON.serialize(setting), CareLoop_Setting__mdt.class);
    }

    public static Escalation_Rule__mdt ladderRule(String name, Integer level, Integer days, String action, String description) {
        Map<String, Object> fields = new Map<String, Object>{
            'DeveloperName' => name, 'MasterLabel' => name, 'Level__c' => level, 'Days_From_Due__c' => days,
            'Action__c' => action, 'Description__c' => description, 'Active__c' => true
        };
        return (Escalation_Rule__mdt) JSON.deserialize(JSON.serialize(fields), Escalation_Rule__mdt.class);
    }

    /** Creates a supervisor and a health worker who reports to her. Index 0 = worker, 1 = supervisor. */
    public static List<User> insertWorkerAndSupervisor() {
        List<User> users = new List<User>();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            User supervisor = newUser('sup');
            insert supervisor;
            User worker = newUser('wrk');
            worker.ManagerId = supervisor.Id;
            insert worker;
            users.add(worker);
            users.add(supervisor);
        }
        return users;
    }

    public static User newUser(String prefix) {
        counter++;
        String unique = prefix + counter + String.valueOf(Crypto.getRandomInteger()).replace('-', '').left(6);
        return new User(
            FirstName = 'Test',
            LastName = prefix + counter,
            Alias = (prefix + counter).left(8),
            Email = unique + '@careloop.test',
            Username = unique + '@careloop.test',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8'
        );
    }

    /** A patient (no automatic schedule) assigned to the given worker, with reminder consent. */
    public static Contact insertPatient(Id workerId, Date birthdate, String language, String channel, Boolean consent) {
        TriggerHandler.bypass('ContactTriggerHandler');
        Village__c village = CareLoopTestFactory.insertVillage(workerId);
        Account household = CareLoopTestFactory.insertHousehold(village.Id);
        Contact patient = CareLoopTestFactory.newPatient(household.Id, village.Id, birthdate);
        patient.Assigned_Health_Worker__c = workerId;
        patient.Preferred_Language__c = language;
        patient.Preferred_Channel__c = channel;
        patient.Reminder_Consent__c = consent;
        insert patient;
        TriggerHandler.clearBypass('ContactTriggerHandler');
        return patient;
    }

    public static Care_Activity__c activity(Id patientId, String type, String name, Date dueDate) {
        return new Care_Activity__c(Name = name, Patient__c = patientId, Activity_Type__c = type, Due_Date__c = dueDate);
    }
}
