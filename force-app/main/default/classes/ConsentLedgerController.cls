/** Staff view of a patient's consent: current state, the hash-chained ledger, verification, recording. */
public with sharing class ConsentLedgerController {

    public class LedgerView {
        @AuraEnabled public List<Consent__c> consents;
        @AuraEnabled public List<Consent_Event__c> events;
    }

    @AuraEnabled
    public static LedgerView getLedger(Id patientId) {
        requireVisible(patientId);
        LedgerView view = new LedgerView();
        view.consents = [SELECT Id, Purpose__c, Status__c, Channel__c, Effective_On__c, Captured_By__r.Name
                         FROM Consent__c WHERE Patient__c = :patientId WITH SYSTEM_MODE ORDER BY Purpose__c];
        view.events = ConsentService.events(patientId, 50);
        return view;
    }

    @AuraEnabled
    public static ConsentService.VerifyResult verifyLedger(Id patientId) {
        requireVisible(patientId);
        return ConsentService.verify(patientId);
    }

    /** A health worker records consent given on paper or verbally (witnessed). */
    @AuraEnabled
    public static LedgerView recordConsent(Id patientId, String purpose, Boolean grant, String channel, String reason) {
        requireEditable(patientId);
        if (channel == 'Patient Portal') {
            throw new AuraHandledException('Portal consent can only be given by the patient in the portal.');
        }
        try {
            ConsentService.record(new List<ConsentService.ConsentRequest>{
                new ConsentService.ConsentRequest(patientId, purpose, grant, channel, reason)
            });
        } catch (Exception e) {
            throw new AuraHandledException('Consent not recorded: ' + e.getMessage());
        }
        return getLedger(patientId);
    }

    private static void requireVisible(Id patientId) {
        if ([SELECT COUNT() FROM Contact WHERE Id = :patientId WITH USER_MODE] == 0) {
            throw new AuraHandledException('You do not have access to this patient.');
        }
    }

    private static void requireEditable(Id patientId) {
        requireVisible(patientId);
        List<UserRecordAccess> access = [SELECT RecordId, HasEditAccess FROM UserRecordAccess
                                         WHERE UserId = :UserInfo.getUserId() AND RecordId = :patientId];
        if (access.isEmpty() || !access[0].HasEditAccess || !Schema.SObjectType.Contact.isUpdateable()) {
            throw new AuraHandledException('Only staff who can edit this patient can record consent.');
        }
    }
}
