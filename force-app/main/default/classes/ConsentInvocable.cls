/**
 * Lets flows (CareLoop Register Patient) record consent in the hash-chained ledger.
 * The running user must be able to see each patient (checked in USER_MODE) before anything is recorded.
 */
public with sharing class ConsentInvocable {

    public class Request {
        @InvocableVariable(required=true label='Patient Id')
        public Id patientId;
        @InvocableVariable(required=true label='Purpose' description='e.g. Reminders and Communication')
        public String purpose;
        @InvocableVariable(required=true label='Grant (true) or withdraw (false)')
        public Boolean grant;
        @InvocableVariable(required=true label='Channel' description='Paper Form or Verbal (Witnessed)')
        public String channel;
        @InvocableVariable(label='Reason')
        public String reason;
    }

    @InvocableMethod(label='Record patient consent (CareLoop ledger)' description='Adds a consent event to the patient\'s hash-chained consent ledger.' category='CareLoop')
    public static void record(List<Request> requests) {
        Set<Id> ids = new Set<Id>();
        for (Request r : requests) {
            ids.add(r.patientId);
        }
        Set<Id> visible = new Map<Id, Contact>([SELECT Id FROM Contact WHERE Id IN :ids WITH USER_MODE]).keySet();
        List<ConsentService.ConsentRequest> toRecord = new List<ConsentService.ConsentRequest>();
        for (Request r : requests) {
            if (!visible.contains(r.patientId)) {
                throw new ConsentService.ConsentException('You do not have access to this patient.');
            }
            toRecord.add(new ConsentService.ConsentRequest(r.patientId, r.purpose, r.grant, r.channel, r.reason));
        }
        ConsentService.record(toRecord);
    }
}
