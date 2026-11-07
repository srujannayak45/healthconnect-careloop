// =====================================================================================
// HealthConnect CareLoop - Phase 4: schedule the nightly care sweep (once)
// =====================================================================================
// Schedules "CareLoop Nightly Care Sweep" at 05:30 every day (your time zone). The job runs
// CareSweepBatch (statuses + escalation ladder) and then PatientPriorityBatch (priority scores).
// Safe to re-run: if the job is already scheduled, nothing changes.
// To remove it later: Setup > Scheduled Jobs > Del next to "CareLoop Nightly Care Sweep".
//
// Run:
//   sf apex run --file scripts/apex/phase4-schedule-nightly.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Id cronId = CareLoopNightlyJob.scheduleDaily();
CronTrigger ct = [SELECT Id, CronJobDetail.Name, NextFireTime, State FROM CronTrigger WHERE Id = :cronId];
System.debug(LoggingLevel.ERROR, 'SCHEDULE OK | ' + ct.CronJobDetail.Name + ' | state ' + ct.State + ' | next run ' + ct.NextFireTime);
