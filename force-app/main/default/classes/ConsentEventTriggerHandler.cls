/**
 * Keeps the consent ledger append-only: no user (administrators included) can edit or delete a
 * Consent_Event__c. Corrections are made by recording a new event.
 */
public with sharing class ConsentEventTriggerHandler extends TriggerHandler {

    public static final String MESSAGE = 'Consent events are an append-only ledger and cannot be changed or deleted. '
        + 'Record a new consent event instead.';

    protected override void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldMap) {
        for (SObject record : newRecords) {
            record.addError(MESSAGE);
        }
    }

    /** Called by the trigger on before delete (the base handler covers insert/update only). */
    public static void blockDelete(List<SObject> oldRecords) {
        if (TriggerHandler.isBypassed('ConsentEventTriggerHandler')) {
            return;
        }
        for (SObject record : oldRecords) {
            record.addError(MESSAGE);
        }
    }
}
