/**
 * Consent ledger: every consent change (grant or withdraw, for a purpose) is an append-only
 * Consent_Event__c chained to the previous event of the same patient by a SHA-256 hash:
 *
 *   Event_Hash = SHA-256( previous hash | patient | sequence | purpose | action | channel | time | user | reason )
 *
 * Changing or removing any past event breaks every hash after it, so verify() detects tampering.
 * (Tamper-evident, not tamper-proof; and not a blockchain: one org, one chain per patient.)
 * Edits and deletes of events are also blocked outright by ConsentEventTriggerHandler.
 *
 * Consent__c holds the current state per purpose (unique Consent_Key__c = patientId-purpose), and the
 * Patient checkboxes Reminder_Consent__c / Data_Sharing_Consent__c mirror it, because the escalation
 * ladder checks Reminder_Consent__c before any reminder.
 *
 * Runs WITHOUT SHARING on purpose: the ledger is private and nobody has create/edit permission on it,
 * so only this service writes it. Every caller proves access first: ConsentLedgerController checks
 * that the staff member can see (or edit) the patient; PatientPortalService only passes the logged-in
 * patient's own Id or her dependants'. Events are owned by the patient's health worker, so the
 * worker's role hierarchy (and Meena's View All) can audit them.
 */
public without sharing class ConsentService {

    public static final String PURPOSE_REMINDERS = 'Reminders and Communication';
    public static final String PURPOSE_SHARE_DOCTORS = 'Share With Doctors';
    public static final String ACTION_GRANT = 'Granted';
    public static final String ACTION_WITHDRAW = 'Withdrawn';
    public static final String GENESIS = 'GENESIS';
    public static final Set<String> CHANNELS = new Set<String>{ 'Paper Form', 'Verbal (Witnessed)', 'Patient Portal' };

    public class ConsentRequest {
        public Id patientId;
        public String purpose;
        public Boolean grant;
        public String channel;
        public String reason;
        public ConsentRequest(Id patientId, String purpose, Boolean grant, String channel, String reason) {
            this.patientId = patientId;
            this.purpose = purpose;
            this.grant = grant;
            this.channel = channel;
            this.reason = reason;
        }
    }

    public class VerifyResult {
        @AuraEnabled public Boolean intact = true;
        @AuraEnabled public Integer events = 0;
        @AuraEnabled public Integer brokenAtSequence;
        @AuraEnabled public String message;
    }

    /** Records consent changes. Requests for the same patient are chained in the given order. */
    public static List<Consent_Event__c> record(List<ConsentRequest> requests) {
        List<Consent_Event__c> created = new List<Consent_Event__c>();
        if (requests == null || requests.isEmpty()) {
            return created;
        }
        Set<Id> patientIds = new Set<Id>();
        for (ConsentRequest r : requests) {
            if (r.patientId == null || String.isBlank(r.purpose) || r.grant == null) {
                throw new ConsentException('Patient, purpose and grant/withdraw are required.');
            }
            if (!CHANNELS.contains(r.channel)) {
                throw new ConsentException('Unknown consent channel: ' + r.channel);
            }
            patientIds.add(r.patientId);
        }
        // Lock the patients so two consent changes for one patient cannot fork the chain.
        Map<Id, Contact> locked = new Map<Id, Contact>([
            SELECT Id, Assigned_Health_Worker__c FROM Contact WHERE Id IN :patientIds FOR UPDATE
        ]);
        if (locked.size() != patientIds.size()) {
            throw new ConsentException('Patient not found or not accessible.');
        }
        Map<Id, Consent_Event__c> latest = new Map<Id, Consent_Event__c>();
        for (Consent_Event__c e : [SELECT Patient__c, Sequence__c, Event_Hash__c FROM Consent_Event__c
                                   WHERE Patient__c IN :patientIds WITH SYSTEM_MODE ORDER BY Patient__c, Sequence__c DESC]) {
            if (!latest.containsKey(e.Patient__c)) {
                latest.put(e.Patient__c, e);
            }
        }

        Datetime now = System.now();
        Datetime eventTime = Datetime.newInstanceGmt(now.dateGmt(), Time.newInstance(now.hourGmt(), now.minuteGmt(), now.secondGmt(), 0));
        Map<String, Consent__c> currentState = new Map<String, Consent__c>();
        Map<Id, Contact> mirror = new Map<Id, Contact>();
        for (ConsentRequest r : requests) {
            Consent_Event__c previous = latest.get(r.patientId);
            Integer sequence = previous == null ? 1 : previous.Sequence__c.intValue() + 1;
            String previousHash = previous == null ? GENESIS : previous.Event_Hash__c;
            Consent_Event__c e = new Consent_Event__c(
                Patient__c = r.patientId,
                Sequence__c = sequence,
                Purpose__c = r.purpose.left(80),
                Action__c = r.grant ? ACTION_GRANT : ACTION_WITHDRAW,
                Channel__c = r.channel,
                Event_Time__c = eventTime,
                Performed_By__c = UserInfo.getUserId(),
                Reason__c = r.reason == null ? null : r.reason.left(255),
                Previous_Hash__c = previousHash,
                OwnerId = locked.get(r.patientId).Assigned_Health_Worker__c != null
                    ? locked.get(r.patientId).Assigned_Health_Worker__c : UserInfo.getUserId()
            );
            e.Event_Hash__c = hashOf(e);
            created.add(e);
            latest.put(r.patientId, e);

            String key = (r.patientId + '-' + r.purpose).left(80);
            currentState.put(key, new Consent__c(
                Consent_Key__c = key,
                Patient__c = r.patientId,
                Purpose__c = r.purpose,
                Status__c = r.grant ? 'Granted' : 'Withdrawn',
                Channel__c = r.channel,
                Captured_By__c = UserInfo.getUserId(),
                Effective_On__c = eventTime,
                Latest_Event_Hash__c = e.Event_Hash__c
            ));
            Contact c = mirror.containsKey(r.patientId) ? mirror.get(r.patientId) : new Contact(Id = r.patientId);
            if (r.purpose == PURPOSE_REMINDERS) {
                c.Reminder_Consent__c = r.grant;
            } else if (r.purpose == PURPOSE_SHARE_DOCTORS) {
                c.Data_Sharing_Consent__c = r.grant;
            }
            mirror.put(r.patientId, c);
        }
        Database.insert(created, true, AccessLevel.SYSTEM_MODE);
        Database.upsert(currentState.values(), Consent__c.Consent_Key__c, true, AccessLevel.SYSTEM_MODE);
        TriggerHandler.bypass('ContactTriggerHandler');
        try {
            Database.update(mirror.values(), true, AccessLevel.SYSTEM_MODE);
        } finally {
            TriggerHandler.clearBypass('ContactTriggerHandler');
        }
        return created;
    }

    /** The latest events of one patient, newest first (for display). */
    public static List<Consent_Event__c> events(Id patientId, Integer max) {
        return [SELECT Id, Name, Sequence__c, Purpose__c, Action__c, Channel__c, Event_Time__c, Performed_By__r.Name,
                       Reason__c, Event_Hash__c, Previous_Hash__c
                FROM Consent_Event__c WHERE Patient__c = :patientId WITH SYSTEM_MODE ORDER BY Sequence__c DESC LIMIT :max];
    }

    /** Re-computes the whole chain of one patient. */
    public static VerifyResult verify(Id patientId) {
        VerifyResult result = new VerifyResult();
        String expectedPrevious = GENESIS;
        Integer expectedSequence = 1;
        for (Consent_Event__c e : [SELECT Patient__c, Sequence__c, Purpose__c, Action__c, Channel__c, Event_Time__c,
                                          Performed_By__c, Reason__c, Previous_Hash__c, Event_Hash__c
                                   FROM Consent_Event__c WHERE Patient__c = :patientId WITH SYSTEM_MODE
                                   ORDER BY Sequence__c ASC]) {
            result.events++;
            Integer sequence = e.Sequence__c == null ? -1 : e.Sequence__c.intValue();
            Boolean ok = sequence == expectedSequence && e.Previous_Hash__c == expectedPrevious && hashOf(e) == e.Event_Hash__c;
            if (!ok && result.intact) {
                result.intact = false;
                result.brokenAtSequence = expectedSequence;
            }
            expectedPrevious = e.Event_Hash__c;
            expectedSequence++;
        }
        result.message = result.intact
            ? (result.events == 0 ? 'No consent events recorded yet.' : 'Ledger intact: ' + result.events + ' event(s), every hash verified.')
            : 'TAMPERING DETECTED at event ' + result.brokenAtSequence + ': the stored history does not match its hashes.';
        return result;
    }

    @TestVisible
    private static String hashOf(Consent_Event__c e) {
        String canonical = String.join(new List<String>{
            e.Previous_Hash__c == null ? '' : e.Previous_Hash__c,
            String.valueOf(e.Patient__c),
            String.valueOf(e.Sequence__c == null ? null : e.Sequence__c.intValue()),
            e.Purpose__c == null ? '' : e.Purpose__c,
            e.Action__c == null ? '' : e.Action__c,
            e.Channel__c == null ? '' : e.Channel__c,
            e.Event_Time__c == null ? '' : e.Event_Time__c.formatGmt('yyyy-MM-dd HH:mm:ss'),
            String.valueOf(e.Performed_By__c),
            e.Reason__c == null ? '' : e.Reason__c
        }, '|');
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(canonical)));
    }

    public class ConsentException extends Exception {}
}
