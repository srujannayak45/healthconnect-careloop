/**
 * Every morning (06:15 by default, after the 05:30 care sweep) plan the day for every health worker
 * who has care due. Schedule once with scripts/apex/phase6-schedule-navigator.apex.
 */
public with sharing class NavigatorNightlyJob implements Schedulable {

    public static final String JOB_NAME = 'CareLoop Navigator Morning Plans';
    public static final String DEFAULT_CRON = '0 15 6 * * ?';

    public void execute(SchedulableContext context) {
        runNow();
    }

    public static Id runNow() {
        Date today = CareLoopClock.today();
        Set<Id> workers = NavigatorService.workersWithOpenCare(today);
        if (workers.isEmpty()) {
            return null;
        }
        return System.enqueueJob(new NavigatorPlanQueueable(workers, today));
    }

    public static Id scheduleDaily() {
        List<CronTrigger> existing = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :JOB_NAME LIMIT 1];
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }
        return System.schedule(JOB_NAME, DEFAULT_CRON, new NavigatorNightlyJob());
    }
}
