/**
 * Everything a logged-in patient can see or do in the HealthConnect portal.
 *
 * Security model (deliberate): portal users get NO direct access to clinical objects through
 * sharing sets. Instead this service, which runs WITHOUT SHARING, works out who the patient is
 * from the logged-in user (User.ContactId, never from anything the browser sends) and only ever
 * touches that patient's records and those of her dependants (Contact.Caregiver__c = her).
 * It returns small view objects with only the fields a patient needs (data minimisation).
 * Every write re-checks ownership. PatientPortalServiceTest proves a patient cannot read or answer
 * another patient's care.
 */
public without sharing class PatientPortalService {

    public static final Set<String> RESPONSES = new Set<String>{ 'Will Attend', 'Completed Elsewhere', 'Need Help' };

    @TestVisible
    private static Id contactOverride;

    public class Person {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String name;
        @AuraEnabled public String relation;
        @AuraEnabled public List<CareItem> care = new List<CareItem>();
    }
    public class CareItem {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public String status;
        @AuraEnabled public Integer daysOverdue;
        @AuraEnabled public String response;
        @AuraEnabled public Date proposedDate;
        @AuraEnabled public Boolean open;
    }
    public class Message {
        @AuraEnabled public Id id;
        @AuraEnabled public String subject;
        @AuraEnabled public String body;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime sentOn;
        @AuraEnabled public String channel;
        @AuraEnabled public String language;
    }
    public class VisitSummary {
        @AuraEnabled public Id id;
        @AuraEnabled public String personName;
        @AuraEnabled public Datetime visitDate;
        @AuraEnabled public String visitType;
        @AuraEnabled public String outcome;
        @AuraEnabled public String vitals;
        @AuraEnabled public Boolean redFlag;
        @AuraEnabled public String doctorAdvice;
        @AuraEnabled public String medicationAdvice;
        @AuraEnabled public String doctorName;
        @AuraEnabled public Decimal followUpInDays;
    }
    public class Home {
        @AuraEnabled public String firstName;
        @AuraEnabled public String language;
        @AuraEnabled public String channel;
        @AuraEnabled public String village;
        @AuraEnabled public Boolean reminderConsent;
        @AuraEnabled public List<Person> people = new List<Person>();
        @AuraEnabled public List<Message> inbox = new List<Message>();
        @AuraEnabled public List<VisitSummary> visits = new List<VisitSummary>();
        @AuraEnabled public Integer unread = 0;
    }

    public class PortalException extends Exception {}

    /** The patient behind the logged-in user. */
    public static Id currentContactId() {
        if (contactOverride != null) {
            return contactOverride;
        }
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        if (u.ContactId == null) {
            throw new PortalException('This page is for registered patients. Please log in to the HealthConnect portal.');
        }
        return u.ContactId;
    }

    /** The patient and the dependants she cares for. */
    public static Map<Id, Contact> family(Id me) {
        return new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Caregiver__c, Preferred_Language__c, Preferred_Channel__c,
                   Reminder_Consent__c, Village__r.Name
            FROM Contact WHERE Id = :me OR Caregiver__c = :me
            ORDER BY Birthdate DESC NULLS LAST
        ]);
    }

    public static Home getHome() {
        Id me = currentContactId();
        Map<Id, Contact> people = family(me);
        Contact self = people.get(me);
        Home home = new Home();
        home.firstName = self.FirstName;
        home.language = self.Preferred_Language__c;
        home.channel = self.Preferred_Channel__c;
        home.village = self.Village__r == null ? null : self.Village__r.Name;
        home.reminderConsent = self.Reminder_Consent__c;

        Map<Id, Person> personById = new Map<Id, Person>();
        List<Id> order = new List<Id>{ me };
        for (Contact c : people.values()) {
            if (c.Id != me) {
                order.add(c.Id);
            }
        }
        for (Id id : order) {
            Contact c = people.get(id);
            Person p = new Person();
            p.contactId = c.Id;
            p.name = ((c.FirstName == null ? '' : c.FirstName + ' ') + c.LastName).trim();
            p.relation = c.Id == me ? 'You' : 'In your care';
            personById.put(c.Id, p);
            home.people.add(p);
        }
        Date recent = CareLoopClock.today().addDays(-60);
        for (Care_Activity__c a : [
            SELECT Id, Name, Activity_Type__c, Due_Date__c, Status__c, Days_Overdue__c, Patient_Response__c,
                   Proposed_Date__c, Patient__c, Completed_Date__c
            FROM Care_Activity__c
            WHERE Patient__c IN :people.keySet()
              AND (Status__c IN :CareRules.OPEN_STATUSES OR Completed_Date__c >= :recent)
            ORDER BY Due_Date__c ASC
            LIMIT 200
        ]) {
            CareItem item = new CareItem();
            item.id = a.Id;
            item.name = a.Name;
            item.type = a.Activity_Type__c;
            item.dueDate = a.Due_Date__c;
            item.status = a.Status__c;
            item.daysOverdue = a.Days_Overdue__c == null ? 0 : a.Days_Overdue__c.intValue();
            item.response = a.Patient_Response__c;
            item.proposedDate = a.Proposed_Date__c;
            item.open = CareRules.isOpen(a.Status__c);
            personById.get(a.Patient__c).care.add(item);
        }
        for (Notification__c n : [
            SELECT Id, Subject__c, Message__c, Status__c, Sent_On__c, Channel__c, Language__c, CreatedDate
            FROM Notification__c
            WHERE Patient__c = :me AND Status__c IN ('Sent', 'Read')
            ORDER BY CreatedDate DESC
            LIMIT 30
        ]) {
            Message m = new Message();
            m.id = n.Id;
            m.subject = n.Subject__c;
            m.body = n.Message__c;
            m.status = n.Status__c;
            m.sentOn = n.Sent_On__c == null ? n.CreatedDate : n.Sent_On__c;
            m.channel = n.Channel__c;
            m.language = n.Language__c;
            if (n.Status__c == 'Sent') {
                home.unread++;
            }
            home.inbox.add(m);
        }
        Map<Id, VisitSummary> visitById = new Map<Id, VisitSummary>();
        for (Health_Visit__c v : [
            SELECT Id, Patient__c, Visit_Date__c, Visit_Type__c, Visit_Outcome__c, BP_Systolic__c, BP_Diastolic__c,
                   SpO2__c, Temperature__c, Weight_Kg__c, Red_Flag__c
            FROM Health_Visit__c
            WHERE Patient__c IN :people.keySet()
            ORDER BY Visit_Date__c DESC
            LIMIT 10
        ]) {
            VisitSummary s = new VisitSummary();
            s.id = v.Id;
            s.personName = personById.get(v.Patient__c).name;
            s.visitDate = v.Visit_Date__c;
            s.visitType = v.Visit_Type__c;
            s.outcome = v.Visit_Outcome__c;
            s.redFlag = v.Red_Flag__c;
            List<String> parts = new List<String>();
            if (v.BP_Systolic__c != null && v.BP_Diastolic__c != null) {
                parts.add('BP ' + v.BP_Systolic__c.intValue() + '/' + v.BP_Diastolic__c.intValue());
            }
            if (v.SpO2__c != null) { parts.add('SpO2 ' + v.SpO2__c.intValue() + '%'); }
            if (v.Temperature__c != null) { parts.add('Temperature ' + v.Temperature__c + ' C'); }
            if (v.Weight_Kg__c != null) { parts.add('Weight ' + v.Weight_Kg__c + ' kg'); }
            s.vitals = String.join(parts, ' · ');
            visitById.put(v.Id, s);
            home.visits.add(s);
        }
        if (!visitById.isEmpty()) {
            for (Medical_Recommendation__c r : [
                SELECT Outreach_Visit__c, Advice__c, Medication_Advice__c, Follow_Up_In_Days__c, Doctor__r.Name
                FROM Medical_Recommendation__c
                WHERE Outreach_Visit__c IN :visitById.keySet() AND Status__c = 'Final'
            ]) {
                VisitSummary s = visitById.get(r.Outreach_Visit__c);
                s.doctorAdvice = r.Advice__c;
                s.medicationAdvice = r.Medication_Advice__c;
                s.followUpInDays = r.Follow_Up_In_Days__c;
                s.doctorName = r.Doctor__r == null ? null : r.Doctor__r.Name;
            }
        }
        return home;
    }

    /** The patient answers a care activity (her own or a dependant's). */
    public static void respond(Id activityId, String response, Date proposedDate, String note) {
        if (!RESPONSES.contains(response)) {
            throw new PortalException('Unknown response.');
        }
        Id me = currentContactId();
        Map<Id, Contact> people = family(me);
        List<Care_Activity__c> rows = [
            SELECT Id, Name, Patient__c, Status__c, Assigned_To__c, Due_Date__c, Patient__r.Name
            FROM Care_Activity__c WHERE Id = :activityId LIMIT 1
        ];
        if (rows.isEmpty() || !people.containsKey(rows[0].Patient__c)) {
            throw new PortalException('This care item is not yours.');
        }
        Care_Activity__c a = rows[0];
        if (!CareRules.isOpen(a.Status__c)) {
            throw new PortalException('This care item is already closed.');
        }
        Date today = CareLoopClock.today();
        if (proposedDate != null && (proposedDate < today || proposedDate > today.addDays(90))) {
            throw new PortalException('Please choose a date within the next 90 days.');
        }
        Database.update(new Care_Activity__c(Id = a.Id, Patient_Response__c = response, Patient_Response_Date__c = today,
            Proposed_Date__c = proposedDate), true, AccessLevel.SYSTEM_MODE);
        PatientResponseService.followUp(a, response, proposedDate, note);
    }

    /** Marks one of the patient's own messages as read. */
    public static void markRead(Id notificationId) {
        Id me = currentContactId();
        List<Notification__c> rows = [SELECT Id, Patient__c, Status__c FROM Notification__c WHERE Id = :notificationId LIMIT 1];
        if (rows.isEmpty() || rows[0].Patient__c != me) {
            throw new PortalException('This message is not yours.');
        }
        if (rows[0].Status__c == 'Sent') {
            Database.update(new Notification__c(Id = notificationId, Status__c = 'Read', Read_On__c = System.now()),
                true, AccessLevel.SYSTEM_MODE);
        }
    }

    /** The patient grants or withdraws consent to reminders; recorded in the hash-chained ledger. */
    public static void setReminderConsent(Boolean granted) {
        Id me = currentContactId();
        ConsentService.record(new List<ConsentService.ConsentRequest>{
            new ConsentService.ConsentRequest(me, ConsentService.PURPOSE_REMINDERS, granted, 'Patient Portal',
                granted ? 'Patient opted in to reminders in the portal' : 'Patient opted out of reminders in the portal')
        });
    }
}
