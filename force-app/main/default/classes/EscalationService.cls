/**
 * The escalation ladder (configured in Escalation_Rule__mdt, levels sorted 1..3):
 *   Level 1  "Patient Reminder"       (default 3 days BEFORE the due date)
 *   Level 2  "Health Worker Task"     (default 3 days AFTER the due date) + an overdue reminder to the patient
 *   Level 3  "Supervisor Escalation"  (default 10 days AFTER the due date)
 *
 * Rules that keep it humane and safe:
 *   * One reminder per recipient per day and template, listing all of that person's items
 *     (a mother gets one message for her baby's three vaccines, not three messages).
 *   * Reminders for children go to the Primary Caregiver, in the caregiver's language and channel.
 *   * No reminder without Reminder_Consent__c: the notification is stored as "Skipped" with the reason.
 *   * At most Max_Reminders_Per_Activity__c reminders per activity.
 *   * Escalation_Paused_Until__c (for example while a patient travels) pauses the ladder.
 *   * Idempotent: Escalation_Level__c records how far an activity has climbed, and
 *     Notification_Key__c is unique, so re-running a sweep never duplicates anything.
 *
 * The service only builds records; CareSweepBatch saves them.
 */
public with sharing class EscalationService {

    public static final String ACTION_REMINDER = 'Patient Reminder';
    public static final String ACTION_WORKER_TASK = 'Health Worker Task';
    public static final String ACTION_SUPERVISOR = 'Supervisor Escalation';
    public static final String TEMPLATE_UPCOMING = 'REMINDER_UPCOMING';
    public static final String TEMPLATE_OVERDUE = 'REMINDER_OVERDUE';
    public static final String CHANNEL_PORTAL = 'Portal Inbox';
    public static final String CHANNEL_SMS = 'SMS';
    public static final String CHANNEL_EMAIL = 'Email';
    private static final Integer DEFAULT_MAX_REMINDERS = 3;

    public class Outcome {
        public Map<Id, Care_Activity__c> activityUpdates = new Map<Id, Care_Activity__c>();
        public List<Notification__c> notifications = new List<Notification__c>();
        public List<Task> tasks = new List<Task>();
        /** userId -> number of new items for that user (one bell per user per run). */
        public Map<Id, Integer> workerAlerts = new Map<Id, Integer>();
        public Map<Id, Integer> supervisorAlerts = new Map<Id, Integer>();
        public Map<Id, Id> alertTarget = new Map<Id, Id>();
    }

    private class ReminderGroup {
        public Contact recipient;
        public String templateKey;
        public Integer level = 0;
        public List<Care_Activity__c> activities = new List<Care_Activity__c>();
        /** Activity Id -> patient, so one activity is listed once per message. */
        public Map<Id, Contact> patients = new Map<Id, Contact>();
    }

    /** The fields this service needs on each activity (CareSweepBatch queries them). */
    public static final String ACTIVITY_FIELDS =
        'Id, Name, Patient__c, Status__c, Due_Date__c, Days_Overdue__c, Activity_Type__c, Escalation_Level__c, '
        + 'Escalation_Paused_Until__c, Reminders_Sent__c, Assigned_To__c, Assigned_To__r.ManagerId, Next_Action__c, '
        + 'Patient__r.FirstName, Patient__r.LastName, Patient__r.Caregiver__c, Patient__r.Preferred_Language__c, '
        + 'Patient__r.Preferred_Channel__c, Patient__r.Reminder_Consent__c, Patient__r.MobilePhone, Patient__r.Email, '
        + 'Patient__r.Village__r.Name, Patient__r.Assigned_Health_Worker__c';

    public static Outcome evaluate(List<Care_Activity__c> activities, Date today) {
        Outcome outcome = new Outcome();
        List<Escalation_Rule__mdt> ladder = CareRules.activeEscalationRules();
        if (activities == null || activities.isEmpty() || ladder.isEmpty()) {
            return outcome;
        }
        Integer maxReminders = maxReminders();
        Map<Id, Contact> caregivers = loadCaregivers(activities);
        Map<String, ReminderGroup> reminderGroups = new Map<String, ReminderGroup>();
        List<String> withoutSupervisor = new List<String>();

        for (Care_Activity__c a : activities) {
            if (!CareRules.isOpen(a.Status__c) || a.Due_Date__c == null) {
                continue;
            }
            if (a.Escalation_Paused_Until__c != null && a.Escalation_Paused_Until__c >= today) {
                continue;
            }
            Integer daysFromDue = a.Due_Date__c.daysBetween(today);
            Integer current = a.Escalation_Level__c == null ? 0 : a.Escalation_Level__c.intValue();
            Integer target = current;
            for (Escalation_Rule__mdt rule : ladder) {
                if (rule.Days_From_Due__c != null && daysFromDue >= rule.Days_From_Due__c && rule.Level__c > target) {
                    target = rule.Level__c.intValue();
                }
            }
            if (target <= current) {
                continue;
            }
            Care_Activity__c change = new Care_Activity__c(Id = a.Id, Escalation_Level__c = target, Last_Escalated_On__c = today);
            Decimal remindersSent = a.Reminders_Sent__c == null ? 0 : a.Reminders_Sent__c;
            List<String> done = new List<String>();
            Id worker = a.Assigned_To__c != null ? a.Assigned_To__c : a.Patient__r.Assigned_Health_Worker__c;

            for (Escalation_Rule__mdt rule : ladder) {
                Integer level = rule.Level__c.intValue();
                if (level <= current || level > target) {
                    continue;
                }
                Boolean remindPatient = rule.Action__c == ACTION_REMINDER
                    || (rule.Action__c == ACTION_WORKER_TASK && daysFromDue > 0);
                if (remindPatient && remindersSent < maxReminders) {
                    String templateKey = daysFromDue > 0 ? TEMPLATE_OVERDUE : TEMPLATE_UPCOMING;
                    Contact recipient = recipientFor(a, caregivers);
                    String groupKey = recipient.Id + '|' + templateKey;
                    if (!reminderGroups.containsKey(groupKey)) {
                        ReminderGroup g = new ReminderGroup();
                        g.recipient = recipient;
                        g.templateKey = templateKey;
                        reminderGroups.put(groupKey, g);
                    }
                    ReminderGroup g = reminderGroups.get(groupKey);
                    if (!g.patients.containsKey(a.Id)) {
                        g.activities.add(a);
                        g.patients.put(a.Id, new Contact(Id = a.Patient__c, FirstName = a.Patient__r.FirstName,
                            LastName = a.Patient__r.LastName));
                        g.level = Math.max(g.level, level);
                        remindersSent++;
                    }
                    done.add('L' + level + ' patient reminder');
                }
                if (rule.Action__c == ACTION_WORKER_TASK && worker != null) {
                    outcome.tasks.add(buildTask(a, worker, 'Follow up overdue care: ', 'Normal', today, rule));
                    increment(outcome.workerAlerts, worker, a.Id, outcome);
                    done.add('L' + level + ' task for health worker');
                }
                if (rule.Action__c == ACTION_SUPERVISOR) {
                    Id supervisor = a.Assigned_To__r != null ? a.Assigned_To__r.ManagerId : null;
                    Id owner = supervisor != null ? supervisor : worker;
                    if (owner != null) {
                        outcome.tasks.add(buildTask(a, owner, 'Escalated - still overdue: ', 'High', today, rule));
                        increment(outcome.supervisorAlerts, owner, a.Id, outcome);
                        done.add('L' + level + ' escalated to supervisor');
                    }
                    if (supervisor == null) {
                        withoutSupervisor.add(a.Name);
                    }
                }
            }
            change.Reminders_Sent__c = remindersSent;
            change.Next_Action__c = (done.isEmpty() ? 'Escalation level ' + target : String.join(done, '; ')).left(255);
            outcome.activityUpdates.put(a.Id, change);
        }

        if (!withoutSupervisor.isEmpty()) {
            ErrorLogger.logMessage('EscalationService', 'The health worker has no manager (supervisor), so these '
                + 'escalations were given to the health worker instead: ' + String.join(withoutSupervisor, ', '),
                null, ErrorLogger.SEVERITY_WARNING);
        }
        for (ReminderGroup g : reminderGroups.values()) {
            outcome.notifications.add(buildNotification(g, today));
        }
        return outcome;
    }

    /** The person who should receive reminders: the caregiver for dependants, otherwise the patient. */
    private static Contact recipientFor(Care_Activity__c a, Map<Id, Contact> caregivers) {
        Id caregiverId = a.Patient__r.Caregiver__c;
        if (caregiverId != null && caregivers.containsKey(caregiverId)) {
            return caregivers.get(caregiverId);
        }
        return new Contact(
            Id = a.Patient__c,
            FirstName = a.Patient__r.FirstName,
            LastName = a.Patient__r.LastName,
            Preferred_Language__c = a.Patient__r.Preferred_Language__c,
            Preferred_Channel__c = a.Patient__r.Preferred_Channel__c,
            Reminder_Consent__c = a.Patient__r.Reminder_Consent__c,
            MobilePhone = a.Patient__r.MobilePhone,
            Email = a.Patient__r.Email
        );
    }

    private static Map<Id, Contact> loadCaregivers(List<Care_Activity__c> activities) {
        Set<Id> ids = new Set<Id>();
        for (Care_Activity__c a : activities) {
            if (a.Patient__r != null && a.Patient__r.Caregiver__c != null) {
                ids.add(a.Patient__r.Caregiver__c);
            }
        }
        if (ids.isEmpty()) {
            return new Map<Id, Contact>();
        }
        return new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Preferred_Language__c, Preferred_Channel__c, Reminder_Consent__c,
                   MobilePhone, Email
            FROM Contact WHERE Id IN :ids WITH SYSTEM_MODE
        ]);
    }

    private static Notification__c buildNotification(ReminderGroup g, Date today) {
        Contact r = g.recipient;
        String language = String.isBlank(r.Preferred_Language__c) ? 'English' : r.Preferred_Language__c;
        String channel = String.isBlank(r.Preferred_Channel__c) ? CHANNEL_PORTAL : r.Preferred_Channel__c;
        Message_Template__mdt template = template(g.templateKey, language);

        Date earliest;
        List<String> items = new List<String>();
        Care_Activity__c mostUrgent;
        String place;
        for (Care_Activity__c a : g.activities) {
            if (earliest == null || a.Due_Date__c < earliest) {
                earliest = a.Due_Date__c;
                mostUrgent = a;
            }
            if (place == null && a.Patient__r.Village__r != null) {
                place = a.Patient__r.Village__r.Name + ' health sub-centre';
            }
            String item = a.Name;
            if (a.Patient__c != r.Id && a.Patient__r.FirstName != null) {
                item += ' (' + a.Patient__r.FirstName + ')';
            }
            items.add(item);
        }
        String activityText = items.size() <= 3
            ? String.join(items, ', ')
            : items[0] + ', ' + items[1] + ', ' + items[2] + ' +' + (items.size() - 3);
        String dateText = earliest == null ? '' : Datetime.newInstance(earliest, Time.newInstance(9, 0, 0, 0)).format('d MMM yyyy');

        String subject = fill(template == null ? 'Reminder: {activity}' : template.Subject__c, r, activityText, dateText, place);
        String body = fill(template == null ? 'Namaste {name}, {activity} on {date}.' : template.Body__c, r, activityText, dateText, place);

        Notification__c n = new Notification__c(
            Patient__c = r.Id,
            Care_Activity__c = mostUrgent == null ? null : mostUrgent.Id,
            Channel__c = channel,
            Language__c = language,
            Escalation_Level__c = g.level,
            Subject__c = subject.left(120),
            Message__c = body.left(2000),
            Recipient__c = (((r.FirstName == null ? '' : r.FirstName + ' ') + (r.LastName == null ? '' : r.LastName)).trim()).left(80),
            Attempts__c = 0,
            Notification_Key__c = (r.Id + '-' + Datetime.newInstance(today, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd')
                + '-' + g.templateKey).left(120)
        );
        String skip = skipReason(r, channel);
        if (skip != null) {
            n.Status__c = 'Skipped';
            n.Skip_Reason__c = skip;
        } else if (channel == CHANNEL_PORTAL) {
            n.Status__c = 'Sent';
            n.Sent_On__c = System.now();
            n.Provider__c = 'Portal Inbox';
        } else {
            n.Status__c = 'Queued';
        }
        return n;
    }

    @TestVisible
    private static String skipReason(Contact r, String channel) {
        if (r.Reminder_Consent__c != true) {
            return 'No reminder consent recorded';
        }
        if (channel == CHANNEL_SMS && String.isBlank(r.MobilePhone)) {
            return 'SMS preferred but no mobile number';
        }
        if (channel == CHANNEL_EMAIL && String.isBlank(r.Email)) {
            return 'Email preferred but no email address';
        }
        return null;
    }

    private static String fill(String text, Contact r, String activity, String dateText, String place) {
        if (text == null) {
            return '';
        }
        return text.replace('{name}', r.FirstName == null ? (r.LastName == null ? '' : r.LastName) : r.FirstName)
                   .replace('{activity}', activity)
                   .replace('{date}', dateText)
                   .replace('{place}', place == null ? 'your health sub-centre' : place);
    }

    @TestVisible
    private static Message_Template__mdt template(String key, String language) {
        Message_Template__mdt fallback;
        for (Message_Template__mdt t : Message_Template__mdt.getAll().values()) {
            if (t.Template_Key__c != key) {
                continue;
            }
            if (t.Language__c == language) {
                return t;
            }
            if (t.Language__c == 'English') {
                fallback = t;
            }
        }
        return fallback;
    }

    private static Task buildTask(Care_Activity__c a, Id ownerId, String prefix, String priority, Date today,
                                  Escalation_Rule__mdt rule) {
        String patientName = ((a.Patient__r.FirstName == null ? '' : a.Patient__r.FirstName + ' ') + a.Patient__r.LastName).trim();
        String contactLine = String.isBlank(a.Patient__r.MobilePhone) ? 'No mobile number on record.' : 'Mobile: ' + a.Patient__r.MobilePhone;
        return new Task(
            OwnerId = ownerId,
            WhatId = a.Id,
            WhoId = a.Patient__c,
            Subject = (prefix + a.Name + ' - ' + patientName).left(255),
            Priority = priority,
            Status = 'Not Started',
            ActivityDate = today.addDays(1),
            Description = ('CareLoop escalation level ' + rule.Level__c.intValue() + ': ' + rule.Description__c
                + '\nDue date: ' + a.Due_Date__c.format() + ' (' + CareRules.daysOverdue(a.Due_Date__c, today) + ' days overdue)'
                + '\n' + contactLine).left(32000)
        );
    }

    private static void increment(Map<Id, Integer> counts, Id userId, Id activityId, Outcome outcome) {
        counts.put(userId, (counts.containsKey(userId) ? counts.get(userId) : 0) + 1);
        if (!outcome.alertTarget.containsKey(userId)) {
            outcome.alertTarget.put(userId, activityId);
        }
    }

    private static Integer maxReminders() {
        CareLoop_Setting__mdt s = CareRules.setting();
        return (s == null || s.Max_Reminders_Per_Activity__c == null)
            ? DEFAULT_MAX_REMINDERS : s.Max_Reminders_Per_Activity__c.intValue();
    }
}
