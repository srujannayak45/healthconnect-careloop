// =====================================================================================
// HealthConnect CareLoop - Phase 6: schedule the morning Navigator plans (once)
// =====================================================================================
// "CareLoop Navigator Morning Plans" runs at 06:15 every day, after the 05:30 care sweep.
// Safe to re-run. Remove in Setup > Scheduled Jobs.
//
// Run:
//   sf apex run --file scripts/apex/phase6-schedule-navigator.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Id cronId = NavigatorNightlyJob.scheduleDaily();
CronTrigger ct = [SELECT CronJobDetail.Name, NextFireTime, State FROM CronTrigger WHERE Id = :cronId];
System.debug(LoggingLevel.ERROR, 'SCHEDULE OK | ' + ct.CronJobDetail.Name + ' | ' + ct.State + ' | next run ' + ct.NextFireTime);
