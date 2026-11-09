/**
 * Saves Navigator plans and tracks what actually happened.
 *
 *  * generate(): one Visit_Plan__c per worker and day (unique Plan_Key__c), owned by the worker,
 *    with its Visit_Plan_Stop__c records. A plan is regenerated only while no stop has been worked;
 *    once the worker has started, regenerating keeps the plan (no lost progress).
 *  * refreshProgress(): reads the outcome from the real records - a Completed visit to any member on
 *    the plan day marks the stop Visited, an unsuccessful one Not Home, and every targeted activity
 *    that is now Completed counts as a gap closed. Nobody has to tick the plan by hand.
 *
 * Writes run in SYSTEM_MODE: health workers can read their plans and update a stop's status (through
 * NavigatorController after an access check) but they cannot edit the measured numbers.
 */
public with sharing class NavigatorService {

    public static final String STOP_PLANNED = 'Planned';
    public static final String STOP_VISITED = 'Visited';
    public static final String STOP_NOT_HOME = 'Not Home';
    public static final String STOP_SKIPPED = 'Skipped';

    public static String planKey(Id workerId, Date planDate) {
        return String.valueOf(workerId) + '-' + Datetime.newInstance(planDate, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd');
    }

    /** Creates (or regenerates, while untouched) the plans of these workers for one day. Returns plan Ids by worker. */
    public static Map<Id, Id> generate(Set<Id> workerIds, Date planDate) {
        Map<Id, Id> planByWorker = new Map<Id, Id>();
        if (workerIds == null || workerIds.isEmpty()) {
            return planByWorker;
        }
        Map<Id, User> workers = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :workerIds AND IsActive = true]);
        Set<String> keys = new Set<String>();
        for (Id workerId : workers.keySet()) {
            keys.add(planKey(workerId, planDate));
        }
        Map<String, Visit_Plan__c> existing = new Map<String, Visit_Plan__c>();
        for (Visit_Plan__c p : [SELECT Id, Plan_Key__c, (SELECT Id, Status__c FROM Stops__r)
                                FROM Visit_Plan__c WHERE Plan_Key__c IN :keys WITH SYSTEM_MODE]) {
            existing.put(p.Plan_Key__c, p);
        }

        Integer capacity = NavigatorPlanner.capacity();
        List<Visit_Plan__c> plans = new List<Visit_Plan__c>();
        Map<String, NavigatorPlanner.Plan> computed = new Map<String, NavigatorPlanner.Plan>();
        List<Visit_Plan_Stop__c> oldStops = new List<Visit_Plan_Stop__c>();
        for (User worker : workers.values()) {
            String key = planKey(worker.Id, planDate);
            Visit_Plan__c current = existing.get(key);
            if (current != null && hasProgress(current)) {
                planByWorker.put(worker.Id, current.Id);
                continue;
            }
            if (current != null) {
                oldStops.addAll(current.Stops__r);
            }
            NavigatorPlanner.Plan p = NavigatorPlanner.plan(worker.Id, planDate, capacity);
            computed.put(key, p);
            plans.add(new Visit_Plan__c(
                Name = (worker.Name + ' - ' + Datetime.newInstance(planDate, Time.newInstance(9, 0, 0, 0)).format('d MMM yyyy')).left(80),
                Plan_Key__c = key,
                OwnerId = worker.Id,
                Health_Worker__c = worker.Id,
                Plan_Date__c = planDate,
                Status__c = 'Active',
                Capacity__c = capacity,
                Planned_Stops__c = p.stops.size(),
                Gaps_Targeted__c = p.gapsTargeted,
                Urgency_Targeted__c = p.urgencyTargeted,
                Total_Distance_Km__c = p.distanceKm,
                Baseline_Gaps__c = p.baselineGaps,
                Baseline_Urgency__c = p.baselineUrgency,
                Baseline_Distance_Km__c = p.baselineDistanceKm,
                Gaps_Closed__c = 0,
                Stops_Visited__c = 0,
                Stops_Not_Home__c = 0,
                Stops_Skipped__c = 0,
                Generated_On__c = System.now()
            ));
        }
        if (!oldStops.isEmpty()) {
            Database.delete(oldStops, true, AccessLevel.SYSTEM_MODE);
        }
        if (plans.isEmpty()) {
            return planByWorker;
        }
        Database.upsert(plans, Visit_Plan__c.Plan_Key__c, true, AccessLevel.SYSTEM_MODE);

        List<Visit_Plan_Stop__c> stops = new List<Visit_Plan_Stop__c>();
        for (Visit_Plan__c plan : plans) {
            planByWorker.put(plan.Health_Worker__c, plan.Id);
            NavigatorPlanner.Plan p = computed.get(plan.Plan_Key__c);
            Integer sequence = 0;
            for (NavigatorPlanner.Stop s : p.stops) {
                sequence++;
                stops.add(new Visit_Plan_Stop__c(
                    Plan__c = plan.Id,
                    Name = (sequence + '. ' + s.householdName).left(80),
                    Household__c = s.householdId,
                    Village__c = s.villageId,
                    Sequence__c = sequence,
                    Urgency_Score__c = s.urgency,
                    Gaps_Targeted__c = s.gaps,
                    Gaps_Closed__c = 0,
                    Distance_From_Previous_Km__c = s.distanceFromPrevious,
                    Patients__c = String.join(s.patientNames, ', ').left(255),
                    Reasons__c = String.join(s.reasons, '\n').left(2000),
                    Target_Activity_Ids__c = String.join(s.activityIds, ',').left(4000),
                    Status__c = STOP_PLANNED,
                    Stop_Key__c = (plan.Plan_Key__c + '-' + sequence).left(80)
                ));
            }
        }
        Database.insert(stops, true, AccessLevel.SYSTEM_MODE);
        return planByWorker;
    }

    private static Boolean hasProgress(Visit_Plan__c plan) {
        for (Visit_Plan_Stop__c s : plan.Stops__r) {
            if (s.Status__c != STOP_PLANNED) {
                return true;
            }
        }
        return false;
    }

    /** Recomputes stop outcomes and plan totals from visits and activities. */
    public static void refreshProgress(Set<Id> planIds) {
        if (planIds == null || planIds.isEmpty()) {
            return;
        }
        List<Visit_Plan__c> plans = [
            SELECT Id, Plan_Date__c,
                   (SELECT Id, Household__c, Status__c, Target_Activity_Ids__c, Gaps_Closed__c FROM Stops__r)
            FROM Visit_Plan__c WHERE Id IN :planIds WITH SYSTEM_MODE
        ];
        Set<Id> activityIds = new Set<Id>();
        Set<Id> householdIds = new Set<Id>();
        Date minDate;
        Date maxDate;
        for (Visit_Plan__c p : plans) {
            minDate = minDate == null || p.Plan_Date__c < minDate ? p.Plan_Date__c : minDate;
            maxDate = maxDate == null || p.Plan_Date__c > maxDate ? p.Plan_Date__c : maxDate;
            for (Visit_Plan_Stop__c s : p.Stops__r) {
                householdIds.add(s.Household__c);
                for (String idText : String.isBlank(s.Target_Activity_Ids__c) ? new List<String>() : s.Target_Activity_Ids__c.split(',')) {
                    activityIds.add(Id.valueOf(idText.trim()));
                }
            }
        }
        if (minDate == null) {
            return;
        }
        Set<Id> completed = new Map<Id, Care_Activity__c>([
            SELECT Id FROM Care_Activity__c WHERE Id IN :activityIds AND Status__c = 'Completed' WITH SYSTEM_MODE
        ]).keySet();
        Datetime fromTime = Datetime.newInstance(minDate, Time.newInstance(0, 0, 0, 0));
        Datetime toTime = Datetime.newInstance(maxDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        // household -> date -> best outcome that day ('Completed' wins)
        Map<String, String> outcome = new Map<String, String>();
        for (Health_Visit__c v : [
            SELECT Patient__r.AccountId, Visit_Date__c, Visit_Outcome__c FROM Health_Visit__c
            WHERE Patient__r.AccountId IN :householdIds AND Visit_Date__c >= :fromTime AND Visit_Date__c < :toTime
            WITH SYSTEM_MODE
        ]) {
            String key = v.Patient__r.AccountId + '|' + v.Visit_Date__c.date();
            if (outcome.get(key) != 'Completed') {
                outcome.put(key, v.Visit_Outcome__c);
            }
        }

        List<SObject> updates = new List<SObject>();
        for (Visit_Plan__c p : plans) {
            Integer closed = 0, visited = 0, notHome = 0, skipped = 0;
            for (Visit_Plan_Stop__c s : p.Stops__r) {
                Integer stopClosed = 0;
                for (String idText : String.isBlank(s.Target_Activity_Ids__c) ? new List<String>() : s.Target_Activity_Ids__c.split(',')) {
                    if (completed.contains(Id.valueOf(idText.trim()))) {
                        stopClosed++;
                    }
                }
                String status = s.Status__c;
                String seen = outcome.get(s.Household__c + '|' + p.Plan_Date__c);
                if (seen == 'Completed' || (stopClosed > 0 && status != STOP_SKIPPED)) {
                    status = STOP_VISITED;
                } else if (seen != null && status == STOP_PLANNED) {
                    status = STOP_NOT_HOME;
                }
                if (status != s.Status__c || stopClosed != s.Gaps_Closed__c) {
                    updates.add(new Visit_Plan_Stop__c(Id = s.Id, Status__c = status, Gaps_Closed__c = stopClosed));
                }
                closed += stopClosed;
                visited += status == STOP_VISITED ? 1 : 0;
                notHome += status == STOP_NOT_HOME ? 1 : 0;
                skipped += status == STOP_SKIPPED ? 1 : 0;
            }
            updates.add(new Visit_Plan__c(Id = p.Id, Gaps_Closed__c = closed, Stops_Visited__c = visited,
                Stops_Not_Home__c = notHome, Stops_Skipped__c = skipped));
        }
        List<Database.SaveResult> results = Database.update(updates, false, AccessLevel.SYSTEM_MODE);
        ErrorLogger.logSaveResults('NavigatorService.refreshProgress', results, updates);
    }

    /** The worker marks a stop by hand (Not Home or Skipped needs a reason for Skipped). */
    public static void setStopStatus(Id stopId, String status, String reason) {
        if (status != STOP_NOT_HOME && status != STOP_SKIPPED && status != STOP_PLANNED) {
            throw new NavigatorException('Visited is recorded automatically from the visit itself.');
        }
        if (status == STOP_SKIPPED && String.isBlank(reason)) {
            throw new NavigatorException('Please give a reason for skipping this household.');
        }
        Visit_Plan_Stop__c stop = [SELECT Id, Plan__c FROM Visit_Plan_Stop__c WHERE Id = :stopId WITH SYSTEM_MODE];
        Database.update(new Visit_Plan_Stop__c(Id = stopId, Status__c = status,
            Skip_Reason__c = status == STOP_SKIPPED ? reason.left(255) : null), true, AccessLevel.SYSTEM_MODE);
        refreshProgress(new Set<Id>{ stop.Plan__c });
    }

    /** Workers with open care that is due (used by the nightly job). */
    public static Set<Id> workersWithOpenCare(Date planDate) {
        Set<Id> ids = new Set<Id>();
        Date horizon = planDate.addDays(NavigatorPlanner.lookaheadDays());
        for (AggregateResult r : [
            SELECT Assigned_To__c worker FROM Care_Activity__c
            WHERE Assigned_To__c != null AND (Status__c IN ('Due', 'Overdue') OR (Status__c = 'Scheduled' AND Due_Date__c <= :horizon))
            WITH SYSTEM_MODE
            GROUP BY Assigned_To__c
        ]) {
            ids.add((Id) r.get('worker'));
        }
        return ids;
    }

    public class NavigatorException extends Exception {}
}
