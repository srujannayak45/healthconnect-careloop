/**
 * Turns a doctor's finalised recommendation into tracked care.
 *
 * When a Doctor Recommendation becomes Final:
 *   - Follow_Up_In_Days__c = N         -> one "Follow-up" care activity due N days after the visit
 *   - Check_Up_Interval_Days__c = D and
 *     Check_Up_Occurrences__c   = K    -> K "Routine Check-up" activities, every D days after the visit
 *   - the outreach visit is marked Reviewed, by this doctor, at this time.
 * Keys <recommendationId>-FU and <recommendationId>-CU-<n> make the plan impossible to duplicate.
 * From here on, the radar, reminders and escalation treat doctor-ordered care exactly like a vaccine dose.
 */
public with sharing class CarePlanService {

    public static final String SOURCE_DOCTOR = 'Doctor Recommendation';
    public static final String REVIEW_DONE = 'Reviewed';

    public static void applyFinalisedRecommendations(List<Medical_Recommendation__c> recommendations) {
        if (recommendations == null || recommendations.isEmpty()) {
            return;
        }
        Set<Id> visitIds = new Set<Id>();
        for (Medical_Recommendation__c r : recommendations) {
            visitIds.add(r.Outreach_Visit__c);
        }
        Map<Id, Health_Visit__c> visits = new Map<Id, Health_Visit__c>([
            SELECT Id, Patient__c, Visit_Date__c, Patient__r.Assigned_Health_Worker__c
            FROM Health_Visit__c
            WHERE Id IN :visitIds
            WITH SYSTEM_MODE
        ]);

        List<Care_Activity__c> activities = new List<Care_Activity__c>();
        List<Health_Visit__c> reviewedVisits = new List<Health_Visit__c>();
        Set<Id> alreadyMarked = new Set<Id>();
        for (Medical_Recommendation__c r : recommendations) {
            Health_Visit__c visit = visits.get(r.Outreach_Visit__c);
            if (visit == null) {
                continue;
            }
            activities.addAll(buildActivities(r, visit));
            if (alreadyMarked.add(visit.Id)) {
                reviewedVisits.add(new Health_Visit__c(
                    Id = visit.Id,
                    Review_Status__c = REVIEW_DONE,
                    Reviewed_By__c = r.Doctor__c == null ? UserInfo.getUserId() : r.Doctor__c,
                    Reviewed_On__c = r.Finalized_On__c == null ? System.now() : r.Finalized_On__c
                ));
            }
        }
        CareScheduleService.insertActivities(activities, 'CarePlanService');
        DerivedFieldWriter.write(reviewedVisits, 'CarePlanService');
    }

    @TestVisible
    private static List<Care_Activity__c> buildActivities(Medical_Recommendation__c r, Health_Visit__c visit) {
        List<Care_Activity__c> result = new List<Care_Activity__c>();
        Date base = visit.Visit_Date__c == null ? CareLoopClock.today() : visit.Visit_Date__c.date();
        Id assignee = visit.Patient__r == null ? null : visit.Patient__r.Assigned_Health_Worker__c;
        String description = ('Ordered in ' + (r.Name == null ? 'a doctor recommendation' : r.Name)).left(255);

        if (r.Follow_Up_In_Days__c != null && r.Follow_Up_In_Days__c > 0) {
            result.add(newActivity(r, visit, assignee, 'Follow-up', 'Doctor follow-up',
                base.addDays(r.Follow_Up_In_Days__c.intValue()), String.valueOf(r.Id) + '-FU', description));
        }
        if (r.Check_Up_Interval_Days__c != null && r.Check_Up_Interval_Days__c > 0
            && r.Check_Up_Occurrences__c != null && r.Check_Up_Occurrences__c > 0) {
            Integer occurrences = r.Check_Up_Occurrences__c.intValue();
            Integer every = r.Check_Up_Interval_Days__c.intValue();
            for (Integer i = 1; i <= occurrences; i++) {
                result.add(newActivity(r, visit, assignee, 'Routine Check-up',
                    'Care plan check-up (' + i + ' of ' + occurrences + ')',
                    base.addDays(every * i), String.valueOf(r.Id) + '-CU-' + i, description));
            }
        }
        return result;
    }

    private static Care_Activity__c newActivity(
        Medical_Recommendation__c r, Health_Visit__c visit, Id assignee,
        String activityType, String name, Date dueDate, String key, String description
    ) {
        return new Care_Activity__c(
            Name = name,
            Patient__c = visit.Patient__c,
            Activity_Type__c = activityType,
            Due_Date__c = dueDate,
            Source__c = SOURCE_DOCTOR,
            Schedule_Key__c = key,
            Recommendation__c = r.Id,
            Assigned_To__c = assignee,
            Description__c = description
        );
    }
}
