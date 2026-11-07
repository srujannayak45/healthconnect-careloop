// =====================================================================================
// HealthConnect CareLoop - Phase 4: run the nightly chain NOW (for demos and testing)
// =====================================================================================
// Starts CareSweepBatch, which then starts PatientPriorityBatch. Both appear in Setup > Apex Jobs
// (usually finished within a minute). Re-running the same day creates no duplicate reminders or tasks.
// Demo "time machine": set Simulated Today in Setup > Custom Metadata Types > CareLoop Setting >
// Manage Records > Default, run this script, and the engine behaves as if it were that day.
//
// Run:
//   sf apex run --file scripts/apex/phase4-run-sweep-now.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Id jobId = CareLoopNightlyJob.runNow();
System.debug(LoggingLevel.ERROR, 'SWEEP STARTED | batch job ' + jobId + ' | CareLoop today = ' + CareLoopClock.today()
    + (CareLoopClock.isSimulated() ? ' (SIMULATED)' : ' (real date)'));
System.debug(LoggingLevel.ERROR, 'SWEEP NEXT    | Wait one minute, then check Setup > Apex Jobs: CareSweepBatch and PatientPriorityBatch Completed.');
