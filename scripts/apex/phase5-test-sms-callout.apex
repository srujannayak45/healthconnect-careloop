// =====================================================================================
// HealthConnect CareLoop - Phase 5: live test of the SMS integration (no records changed)
// =====================================================================================
// Makes ONE real HTTP callout through the CareLoop_SMS Named Credential (HttpSmsProvider) to the
// echo service and prints the response. Nothing is saved and no real SMS is sent.
//
// Run:
//   sf apex run --file scripts/apex/phase5-test-sms-callout.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
SmsResult r = new HttpSmsProvider().send('9000000101', '+910000000000', 'CareLoop integration test', 'TEST-' + System.now().getTime());
System.debug(LoggingLevel.ERROR, 'SMS ' + (r.success ? 'OK    | ' : 'FAIL  | ') + r.providerName);
System.debug(LoggingLevel.ERROR, 'SMS RESPONSE | ' + (r.providerResponse == null ? '' : r.providerResponse.left(400)));
