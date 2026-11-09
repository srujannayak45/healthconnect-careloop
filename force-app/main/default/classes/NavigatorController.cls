/**
 * Apex for the Care Navigator page. Health workers see and plan their own day; supervisors
 * (Meena, through the role hierarchy) can open any plan they are allowed to see. All reads of plans
 * are USER_MODE, so sharing decides who sees which plan.
 */
public with sharing class NavigatorController {

    public class Member {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String name;
        @AuraEnabled public List<String> items = new List<String>();
    }
    public class StopView {
        @AuraEnabled public Id id;
        @AuraEnabled public Integer sequence;
        @AuraEnabled public Id householdId;
        @AuraEnabled public String household;
        @AuraEnabled public String village;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public Integer urgency;
        @AuraEnabled public Integer gaps;
        @AuraEnabled public Integer gapsClosed;
        @AuraEnabled public Decimal distance;
        @AuraEnabled public String status;
        @AuraEnabled public String skipReason;
        @AuraEnabled public List<String> reasons = new List<String>();
        @AuraEnabled public List<Member> members = new List<Member>();
    }
    public class PlanView {
        @AuraEnabled public Id planId;
        @AuraEnabled public String workerName;
        @AuraEnabled public Id workerId;
        @AuraEnabled public Date planDate;
        @AuraEnabled public Boolean isMine;
        @AuraEnabled public Integer capacity;
        @AuraEnabled public Integer gapsTargeted;
        @AuraEnabled public Integer baselineGaps;
        @AuraEnabled public Integer urgency;
        @AuraEnabled public Integer baselineUrgency;
        @AuraEnabled public Decimal distance;
        @AuraEnabled public Decimal baselineDistance;
        @AuraEnabled public Integer gapsClosed;
        @AuraEnabled public Integer visited;
        @AuraEnabled public Datetime generatedOn;
        @AuraEnabled public List<StopView> stops = new List<StopView>();
    }
    public class TeamPlan {
        @AuraEnabled public Id workerId;
        @AuraEnabled public String workerName;
        @AuraEnabled public Integer planned;
        @AuraEnabled public Integer visited;
        @AuraEnabled public Integer gapsTargeted;
        @AuraEnabled public Integer gapsClosed;
    }

    /** The plan of a worker (default: me) for today, with progress refreshed. Null if none yet. */
    @AuraEnabled
    public static PlanView getPlan(Id workerId) {
        try {
            Id worker = workerId == null ? UserInfo.getUserId() : workerId;
            Date today = CareLoopClock.today();
            String key = NavigatorService.planKey(worker, today);
            List<Visit_Plan__c> plans = [SELECT Id FROM Visit_Plan__c WHERE Plan_Key__c = :key WITH USER_MODE LIMIT 1];
            if (plans.isEmpty()) {
                return null;
            }
            NavigatorService.refreshProgress(new Set<Id>{ plans[0].Id });
            return view(plans[0].Id);
        } catch (Exception e) {
            throw new AuraHandledException('Could not load the plan: ' + e.getMessage());
        }
    }

    /** Plans (or re-plans, while untouched) the current user's day. */
    @AuraEnabled
    public static PlanView planMyDay() {
        try {
            NavigatorService.generate(new Set<Id>{ UserInfo.getUserId() }, CareLoopClock.today());
            return getPlan(null);
        } catch (Exception e) {
            throw new AuraHandledException('Could not plan your day: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static PlanView updateStop(Id stopId, String status, String reason) {
        List<Visit_Plan_Stop__c> stops = [SELECT Id, Plan__c, Plan__r.Health_Worker__c FROM Visit_Plan_Stop__c WHERE Id = :stopId WITH USER_MODE];
        if (stops.isEmpty()) {
            throw new AuraHandledException('You do not have access to this stop.');
        }
        List<UserRecordAccess> access = [SELECT RecordId, HasEditAccess FROM UserRecordAccess
                                         WHERE UserId = :UserInfo.getUserId() AND RecordId = :stops[0].Plan__c];
        if (access.isEmpty() || !access[0].HasEditAccess) {
            throw new AuraHandledException('Only the health worker who owns this plan can change it.');
        }
        try {
            NavigatorService.setStopStatus(stopId, status, reason);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return getPlan(stops[0].Plan__r.Health_Worker__c);
    }

    /** Today's plans this user can see (supervisors see their team). */
    @AuraEnabled
    public static List<TeamPlan> getTeamPlans() {
        List<TeamPlan> result = new List<TeamPlan>();
        for (Visit_Plan__c p : [SELECT Health_Worker__c, Health_Worker__r.Name, Planned_Stops__c, Stops_Visited__c,
                                       Gaps_Targeted__c, Gaps_Closed__c
                                FROM Visit_Plan__c WHERE Plan_Date__c = :CareLoopClock.today() WITH USER_MODE
                                ORDER BY Health_Worker__r.Name]) {
            TeamPlan t = new TeamPlan();
            t.workerId = p.Health_Worker__c;
            t.workerName = p.Health_Worker__r == null ? '' : p.Health_Worker__r.Name;
            t.planned = toInt(p.Planned_Stops__c);
            t.visited = toInt(p.Stops_Visited__c);
            t.gapsTargeted = toInt(p.Gaps_Targeted__c);
            t.gapsClosed = toInt(p.Gaps_Closed__c);
            result.add(t);
        }
        return result;
    }

    private static PlanView view(Id planId) {
        Visit_Plan__c p = [
            SELECT Id, Health_Worker__c, Health_Worker__r.Name, Plan_Date__c, Capacity__c, Gaps_Targeted__c, Baseline_Gaps__c,
                   Urgency_Targeted__c, Baseline_Urgency__c, Total_Distance_Km__c, Baseline_Distance_Km__c, Gaps_Closed__c,
                   Stops_Visited__c, Generated_On__c,
                   (SELECT Id, Sequence__c, Household__c, Household__r.Name, Village__r.Name, Village__r.Location__Latitude__s,
                           Village__r.Location__Longitude__s, Urgency_Score__c, Gaps_Targeted__c, Gaps_Closed__c,
                           Distance_From_Previous_Km__c, Status__c, Skip_Reason__c, Reasons__c, Target_Activity_Ids__c
                    FROM Stops__r ORDER BY Sequence__c)
            FROM Visit_Plan__c WHERE Id = :planId WITH USER_MODE
        ];
        PlanView v = new PlanView();
        v.planId = p.Id;
        v.workerId = p.Health_Worker__c;
        v.workerName = p.Health_Worker__r == null ? '' : p.Health_Worker__r.Name;
        v.isMine = p.Health_Worker__c == UserInfo.getUserId();
        v.planDate = p.Plan_Date__c;
        v.capacity = toInt(p.Capacity__c);
        v.gapsTargeted = toInt(p.Gaps_Targeted__c);
        v.baselineGaps = toInt(p.Baseline_Gaps__c);
        v.urgency = toInt(p.Urgency_Targeted__c);
        v.baselineUrgency = toInt(p.Baseline_Urgency__c);
        v.distance = p.Total_Distance_Km__c;
        v.baselineDistance = p.Baseline_Distance_Km__c;
        v.gapsClosed = toInt(p.Gaps_Closed__c);
        v.visited = toInt(p.Stops_Visited__c);
        v.generatedOn = p.Generated_On__c;

        Set<Id> activityIds = new Set<Id>();
        for (Visit_Plan_Stop__c s : p.Stops__r) {
            for (String idText : String.isBlank(s.Target_Activity_Ids__c) ? new List<String>() : s.Target_Activity_Ids__c.split(',')) {
                activityIds.add(Id.valueOf(idText.trim()));
            }
        }
        // The activities are read in system mode: the plan was built from them and the user can already see the plan.
        Map<Id, List<Care_Activity__c>> byHousehold = new Map<Id, List<Care_Activity__c>>();
        for (Care_Activity__c a : [SELECT Id, Name, Status__c, Patient__c, Patient__r.FirstName, Patient__r.LastName, Patient__r.AccountId
                                   FROM Care_Activity__c WHERE Id IN :activityIds WITH SYSTEM_MODE ORDER BY Due_Date__c]) {
            if (!byHousehold.containsKey(a.Patient__r.AccountId)) {
                byHousehold.put(a.Patient__r.AccountId, new List<Care_Activity__c>());
            }
            byHousehold.get(a.Patient__r.AccountId).add(a);
        }
        for (Visit_Plan_Stop__c s : p.Stops__r) {
            StopView sv = new StopView();
            sv.id = s.Id;
            sv.sequence = toInt(s.Sequence__c);
            sv.householdId = s.Household__c;
            sv.household = s.Household__r == null ? '' : s.Household__r.Name;
            sv.village = s.Village__r == null ? '' : s.Village__r.Name;
            sv.latitude = s.Village__r == null ? null : s.Village__r.Location__Latitude__s;
            sv.longitude = s.Village__r == null ? null : s.Village__r.Location__Longitude__s;
            sv.urgency = toInt(s.Urgency_Score__c);
            sv.gaps = toInt(s.Gaps_Targeted__c);
            sv.gapsClosed = toInt(s.Gaps_Closed__c);
            sv.distance = s.Distance_From_Previous_Km__c;
            sv.status = s.Status__c;
            sv.skipReason = s.Skip_Reason__c;
            sv.reasons = String.isBlank(s.Reasons__c) ? new List<String>() : s.Reasons__c.split('\n');
            Map<Id, Member> members = new Map<Id, Member>();
            List<Care_Activity__c> acts = byHousehold.containsKey(s.Household__c) ? byHousehold.get(s.Household__c) : new List<Care_Activity__c>();
            for (Care_Activity__c a : acts) {
                if (!members.containsKey(a.Patient__c)) {
                    Member m = new Member();
                    m.contactId = a.Patient__c;
                    m.name = ((a.Patient__r.FirstName == null ? '' : a.Patient__r.FirstName + ' ') + a.Patient__r.LastName).trim();
                    members.put(a.Patient__c, m);
                }
                members.get(a.Patient__c).items.add(a.Name + (a.Status__c == 'Completed' ? ' (done)' : ' (' + a.Status__c + ')'));
            }
            sv.members = members.values();
            v.stops.add(sv);
        }
        return v;
    }

    private static Integer toInt(Decimal d) {
        return d == null ? 0 : d.intValue();
    }
}
