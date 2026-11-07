// =====================================================================================
// HealthConnect CareLoop - Phase 5: move existing reminder consent into the consent ledger
// =====================================================================================
// Patients whose Reminder Consent checkbox was ticked before the ledger existed (Phase 4 demo data,
// Rao family) get one "Granted / Paper Form" ledger event, so every reminder is backed by an
// auditable record. Patients that already have a ledger entry for reminders are skipped.
// Safe to re-run.
//
// Run:
//   sf apex run --file scripts/apex/phase5-backfill-consent-ledger.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Set<Id> already = new Set<Id>();
for (Consent__c c : [SELECT Patient__c FROM Consent__c WHERE Purpose__c = 'Reminders and Communication']) {
    already.add(c.Patient__c);
}
List<ConsentService.ConsentRequest> requests = new List<ConsentService.ConsentRequest>();
for (Contact p : [SELECT Id FROM Contact WHERE Reminder_Consent__c = true AND Id NOT IN :already LIMIT 150]) {
    requests.add(new ConsentService.ConsentRequest(p.Id, ConsentService.PURPOSE_REMINDERS, true, 'Paper Form',
        'Consent recorded at registration (moved into the ledger)'));
}
ConsentService.record(requests);
System.debug(LoggingLevel.ERROR, 'LEDGER DONE | ' + requests.size() + ' consent(s) recorded; ' + already.size() + ' already in the ledger');
System.debug(LoggingLevel.ERROR, 'LEDGER NEXT | If the count was 150, run the script again for the rest.');
