/**
 * The one place that updates engine-owned fields.
 *
 * Engine-owned fields (for example Contact.Last_Successful_Contact__c, Health_Visit__c.Review_Status__c,
 * Task status when CareLoop closes a task) are read-only for every user through field-level security,
 * so they cannot be tampered with in the UI or the API. Only CareLoop services change them, through
 * this class, in SYSTEM_MODE.
 *
 * The class keeps "with sharing": SYSTEM_MODE skips object and field permissions, but record sharing
 * still follows the class, so a user can only cause updates to records they can see.
 * Partial success: one bad record is logged and does not block the others or the user's own save.
 */
public with sharing class DerivedFieldWriter {

    public static void write(List<SObject> records, String source) {
        if (records == null || records.isEmpty()) {
            return;
        }
        List<Database.SaveResult> results = Database.update(records, false, AccessLevel.SYSTEM_MODE);
        ErrorLogger.logSaveResults(source, results, records);
    }
}
