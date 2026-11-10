// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): schedule the daily scan (06:30)
// =====================================================================================
// Safe to re-run. Remove in Setup > Scheduled Jobs.
//   sf apex run --file scripts/apex/innovation-schedule-sentinel.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Id cronId = SentinelJob.scheduleDaily();
CronTrigger ct = [SELECT CronJobDetail.Name, NextFireTime, State FROM CronTrigger WHERE Id = :cronId];
System.debug(LoggingLevel.ERROR, 'SCHEDULE OK | ' + ct.CronJobDetail.Name + ' | ' + ct.State + ' | next run ' + ct.NextFireTime);
