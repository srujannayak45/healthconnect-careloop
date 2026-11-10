/**
 * Runs the CareLoop Sentinel scan every morning (06:30, after the 05:30 care sweep) and sends bell
 * notifications for new or escalated community signals. Schedule once with
 * scripts/apex/innovation-schedule-sentinel.apex.
 *
 * Scale note: one transaction is enough for a programme of this size (a few hundred villages and
 * < 40,000 visits in six weeks). For a district-wide roll-out, turn this into Batch Apex that calls
 * SentinelService per chunk of villages.
 */
public with sharing class SentinelJob implements Schedulable {

    public static final String JOB_NAME = 'CareLoop Sentinel Daily Scan';
    public static final String DEFAULT_CRON = '0 30 6 * * ?';

    public void execute(SchedulableContext context) {
        try {
            SentinelService.scan(CareLoopClock.today(), true);
        } catch (Exception e) {
            ErrorLogger.log('SentinelJob', e, null);
        }
    }

    public static Id scheduleDaily() {
        List<CronTrigger> existing = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :JOB_NAME LIMIT 1];
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }
        return System.schedule(JOB_NAME, DEFAULT_CRON, new SentinelJob());
    }
}
