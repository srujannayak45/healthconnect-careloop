/**
 * The scheduled entry point: runs the care sweep, which then runs the priority batch.
 * Schedule it once (scripts/apex/phase4-schedule-nightly.apex); it appears in Setup > Scheduled Jobs.
 */
public with sharing class CareLoopNightlyJob implements Schedulable {

    public static final String JOB_NAME = 'CareLoop Nightly Care Sweep';
    /** 05:30 every day (in the time zone of the user who schedules it). */
    public static final String DEFAULT_CRON = '0 30 5 * * ?';

    public void execute(SchedulableContext context) {
        runNow();
    }

    /** Starts the chain immediately. Returns the batch job Id. */
    public static Id runNow() {
        return Database.executeBatch(new CareSweepBatch(true), CareSweepBatch.DEFAULT_SCOPE);
    }

    /** Schedules the nightly job if it is not scheduled yet. Returns the CronTrigger Id. */
    public static Id scheduleDaily() {
        List<CronTrigger> existing = [
            SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :JOB_NAME AND State != 'DELETED' LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }
        return System.schedule(JOB_NAME, DEFAULT_CRON, new CareLoopNightlyJob());
    }
}
