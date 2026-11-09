/**
 * CareLoop Navigator: turns a health worker's open care gaps into the best household visit plan
 * for one day.
 *
 * The insight: the household, not the patient, is the unit of outreach. One visit to a home can
 * close a baby's vaccine, the mother's antenatal check-up and the grandfather's BP check together.
 * A due-date list ignores that, and it ignores how far apart the villages are.
 *
 * Algorithm (deterministic, explainable, no machine learning):
 *   1. Candidate gaps: the worker's open activities that are Due or Overdue, or Scheduled within
 *      the look-ahead window (default 7 days), unless escalation is paused.
 *   2. Every patient is scored with PriorityScoringService (configured rules, each point explained).
 *   3. Household value = sum of the scores of the members who have a candidate gap
 *      (a member whose only gaps are upcoming counts 1 point per gap).
 *   4. Greedy route: repeatedly pick the household with the highest
 *          value - travelPenaltyPerKm x distance from the current village
 *      until the daily capacity is used. Staying in a village costs nothing, so the route
 *      naturally finishes one village before walking to the next.
 *   5. Baseline for comparison: the same number of visits made in due-date order, one patient
 *      per visit (how a worker uses a plain overdue list). Gaps reached, urgency and distance of both
 *      are stored, so the plan's advantage is measured on the worker's real data every day.
 */
public with sharing class NavigatorPlanner {

    public static final Integer DEFAULT_CAPACITY = 8;
    public static final Decimal DEFAULT_PENALTY_PER_KM = 0.5;
    public static final Integer DEFAULT_LOOKAHEAD_DAYS = 7;
    public static final Decimal UNKNOWN_DISTANCE_PENALTY = 3;
    public static final Integer MAX_ACTIVITIES = 2000;

    public class Stop {
        public Id householdId;
        public String householdName;
        public Id villageId;
        public String villageName;
        public Decimal latitude;
        public Decimal longitude;
        public Integer urgency = 0;
        public Integer gaps = 0;
        public Decimal distanceFromPrevious = 0;
        public List<String> patientNames = new List<String>();
        public List<String> reasons = new List<String>();
        public List<Id> activityIds = new List<Id>();
    }

    public class Plan {
        public Id workerId;
        public Date planDate;
        public Integer capacity;
        public List<Stop> stops = new List<Stop>();
        public Integer gapsTargeted = 0;
        public Integer urgencyTargeted = 0;
        public Decimal distanceKm = 0;
        public Integer baselineGaps = 0;
        public Integer baselineUrgency = 0;
        public Decimal baselineDistanceKm = 0;
        public Integer candidateHouseholds = 0;
    }

    public static Integer capacity() {
        CareLoop_Setting__mdt s = CareRules.setting();
        return (s == null || s.Daily_Visit_Capacity__c == null || s.Daily_Visit_Capacity__c < 1)
            ? DEFAULT_CAPACITY : s.Daily_Visit_Capacity__c.intValue();
    }

    public static Decimal penaltyPerKm() {
        CareLoop_Setting__mdt s = CareRules.setting();
        return (s == null || s.Travel_Penalty_Per_Km__c == null) ? DEFAULT_PENALTY_PER_KM : s.Travel_Penalty_Per_Km__c;
    }

    public static Integer lookaheadDays() {
        CareLoop_Setting__mdt s = CareRules.setting();
        return (s == null || s.Plan_Lookahead_Days__c == null) ? DEFAULT_LOOKAHEAD_DAYS : s.Plan_Lookahead_Days__c.intValue();
    }

    /** Builds the plan for one worker and day (reads only). */
    public static Plan plan(Id workerId, Date planDate, Integer capacity) {
        Plan result = new Plan();
        result.workerId = workerId;
        result.planDate = planDate;
        result.capacity = capacity;
        Date horizon = planDate.addDays(lookaheadDays());

        List<Care_Activity__c> candidates = [
            SELECT Id, Name, Patient__c, Status__c, Due_Date__c, Activity_Type__c, Escalation_Paused_Until__c,
                   Patient__r.FirstName, Patient__r.LastName, Patient__r.AccountId, Patient__r.Account.Name,
                   Patient__r.Account.Village__c, Patient__r.Account.Village__r.Name,
                   Patient__r.Account.Village__r.Location__Latitude__s, Patient__r.Account.Village__r.Location__Longitude__s
            FROM Care_Activity__c
            WHERE Assigned_To__c = :workerId
              AND Patient__r.AccountId != null
              AND (Status__c IN ('Due', 'Overdue') OR (Status__c = 'Scheduled' AND Due_Date__c <= :horizon))
            WITH SYSTEM_MODE
            ORDER BY Due_Date__c ASC
            LIMIT :MAX_ACTIVITIES
        ];
        List<Care_Activity__c> gaps = new List<Care_Activity__c>();
        Set<Id> patientIds = new Set<Id>();
        for (Care_Activity__c a : candidates) {
            if (a.Escalation_Paused_Until__c != null && a.Escalation_Paused_Until__c >= planDate) {
                continue;
            }
            gaps.add(a);
            patientIds.add(a.Patient__c);
        }
        if (gaps.isEmpty()) {
            return result;
        }
        Map<Id, PriorityScoringService.PatientScore> scores = PriorityScoringService.score(patientIds);

        // ---- group gaps by household
        Map<Id, Stop> byHousehold = new Map<Id, Stop>();
        Map<Id, Map<Id, Integer>> gapsPerPatient = new Map<Id, Map<Id, Integer>>();
        for (Care_Activity__c a : gaps) {
            Id hh = a.Patient__r.AccountId;
            if (!byHousehold.containsKey(hh)) {
                Stop s = new Stop();
                s.householdId = hh;
                s.householdName = a.Patient__r.Account.Name;
                s.villageId = a.Patient__r.Account.Village__c;
                s.villageName = a.Patient__r.Account.Village__r == null ? null : a.Patient__r.Account.Village__r.Name;
                s.latitude = a.Patient__r.Account.Village__r == null ? null : a.Patient__r.Account.Village__r.Location__Latitude__s;
                s.longitude = a.Patient__r.Account.Village__r == null ? null : a.Patient__r.Account.Village__r.Location__Longitude__s;
                byHousehold.put(hh, s);
                gapsPerPatient.put(hh, new Map<Id, Integer>());
            }
            Stop s = byHousehold.get(hh);
            s.gaps++;
            s.activityIds.add(a.Id);
            Map<Id, Integer> perPatient = gapsPerPatient.get(hh);
            perPatient.put(a.Patient__c, (perPatient.containsKey(a.Patient__c) ? perPatient.get(a.Patient__c) : 0) + 1);
        }
        for (Id hh : byHousehold.keySet()) {
            Stop s = byHousehold.get(hh);
            List<PriorityScoringService.Reason> householdReasons = new List<PriorityScoringService.Reason>();
            for (Id patientId : gapsPerPatient.get(hh).keySet()) {
                PriorityScoringService.PatientScore ps = scores.get(patientId);
                Integer value = (ps == null || ps.score == 0) ? gapsPerPatient.get(hh).get(patientId) : ps.score;
                s.urgency += value;
                String first = ps == null ? '' : ps.patientName.split(' ')[0];
                s.patientNames.add(first);
                if (ps != null) {
                    for (PriorityScoringService.Reason r : ps.reasons) {
                        householdReasons.add(new PriorityScoringService.Reason(r.ruleKey, r.points, first + ': ' + r.text));
                    }
                }
                if (ps == null || ps.score == 0) {
                    householdReasons.add(new PriorityScoringService.Reason('UPCOMING', value, first + ': '
                        + value + ' check(s) due within ' + lookaheadDays() + ' days'));
                }
            }
            householdReasons.sort(new ByPointsDesc());
            for (Integer i = 0; i < householdReasons.size() && i < 5; i++) {
                s.reasons.add('+' + householdReasons[i].points + '  ' + householdReasons[i].text);
            }
        }
        result.candidateHouseholds = byHousehold.size();

        // ---- greedy, travel-aware selection
        List<Stop> remaining = byHousehold.values();
        Decimal penalty = penaltyPerKm();
        Stop current;
        while (result.stops.size() < capacity && !remaining.isEmpty()) {
            Integer bestIndex = 0;
            Decimal bestValue;
            for (Integer i = 0; i < remaining.size(); i++) {
                Stop candidate = remaining[i];
                Decimal kmToCandidate = distanceKm(current, candidate);
                Decimal value = kmToCandidate == null
                    ? candidate.urgency - UNKNOWN_DISTANCE_PENALTY
                    : candidate.urgency - penalty * kmToCandidate;
                Boolean better = bestValue == null || value > bestValue
                    || (value == bestValue && candidate.gaps > remaining[bestIndex].gaps);
                if (better) {
                    bestValue = value;
                    bestIndex = i;
                }
            }
            Stop chosen = remaining.remove(bestIndex);
            Decimal km = distanceKm(current, chosen);
            chosen.distanceFromPrevious = km == null ? 0 : km.setScale(1);
            result.distanceKm += chosen.distanceFromPrevious;
            result.gapsTargeted += chosen.gaps;
            result.urgencyTargeted += chosen.urgency;
            result.stops.add(chosen);
            current = chosen;
        }

        // ---- baseline: due-date order, one patient per visit
        Set<Id> visitedPatients = new Set<Id>();
        Map<Id, Integer> gapCount = new Map<Id, Integer>();
        Map<Id, Stop> patientStop = new Map<Id, Stop>();
        for (Care_Activity__c a : gaps) {
            gapCount.put(a.Patient__c, (gapCount.containsKey(a.Patient__c) ? gapCount.get(a.Patient__c) : 0) + 1);
            patientStop.put(a.Patient__c, byHousehold.get(a.Patient__r.AccountId));
        }
        Stop previous;
        for (Care_Activity__c a : gaps) {
            if (visitedPatients.size() >= capacity) {
                break;
            }
            if (visitedPatients.contains(a.Patient__c)) {
                continue;
            }
            visitedPatients.add(a.Patient__c);
            PriorityScoringService.PatientScore ps = scores.get(a.Patient__c);
            result.baselineGaps += gapCount.get(a.Patient__c);
            result.baselineUrgency += (ps == null || ps.score == 0) ? gapCount.get(a.Patient__c) : ps.score;
            Stop here = patientStop.get(a.Patient__c);
            Decimal hop = distanceKm(previous, here);
            result.baselineDistanceKm += hop == null ? 0 : hop.setScale(1);
            previous = here;
        }
        return result;
    }

    /** Kilometres between two stops' villages; 0 for the first stop or the same village; null if unknown. */
    @TestVisible
    private static Decimal distanceKm(Stop fromStop, Stop toStop) {
        if (fromStop == null || toStop == null) {
            return 0;
        }
        if (fromStop.villageId != null && fromStop.villageId == toStop.villageId) {
            return 0;
        }
        if (fromStop.latitude == null || fromStop.longitude == null || toStop.latitude == null || toStop.longitude == null) {
            return null;
        }
        Location a = Location.newInstance(fromStop.latitude, fromStop.longitude);
        Location b = Location.newInstance(toStop.latitude, toStop.longitude);
        return Decimal.valueOf(Location.getDistance(a, b, 'km'));
    }

    private class ByPointsDesc implements Comparator<PriorityScoringService.Reason> {
        public Integer compare(PriorityScoringService.Reason a, PriorityScoringService.Reason b) {
            return b.points - a.points;
        }
    }
}
