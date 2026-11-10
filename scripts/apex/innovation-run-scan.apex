// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): run the community scan now
// =====================================================================================
// Evaluates every village x signal as of the CareLoop clock's today, records Watch / Alert signals
// and sends bell notifications to programme managers and doctors. Safe to re-run: an open signal
// is updated, a dismissed one is left alone.
//
// Run:
//   sf apex run --file scripts/apex/innovation-run-scan.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Date asOf = CareLoopClock.today();
SentinelService.ScanSummary summary = SentinelService.scan(asOf, true);
System.debug(LoggingLevel.ERROR, 'SENTINEL SCAN  | as of ' + asOf + (CareLoopClock.isSimulated() ? ' (SIMULATED)' : '')
    + ' | ' + summary.cellsEvaluated + ' village-signals | ' + summary.flagged + ' flagged | ' + summary.created + ' new | '
    + summary.updated + ' updated | ' + summary.notified + ' notification(s)');
for (Community_Signal__c s : [SELECT Name, Severity__c, Status__c, Observed__c, Expected__c, Z_Score__c, Households__c
                              FROM Community_Signal__c WHERE Window_End__c >= :asOf.addDays(-14) ORDER BY Z_Score__c DESC]) {
    System.debug(LoggingLevel.ERROR, 'SENTINEL SIGNAL| ' + s.Severity__c + ' | ' + s.Name + ' | observed ' + s.Observed__c
        + ' vs normal ' + s.Expected__c + ' | ' + s.Z_Score__c + ' SD | ' + s.Households__c + ' households | ' + s.Status__c);
}
