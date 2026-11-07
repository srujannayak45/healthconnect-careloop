/**
 * Records automation failures in Error_Log__c so nothing fails silently.
 *
 * Writes in SYSTEM_MODE: health workers and doctors have no permission on Error_Log__c,
 * yet an error in their transaction must still be recorded. Error logs are private and
 * readable only by programme managers and admins. Logging never throws: if the log itself
 * cannot be written, the failure goes to the debug log instead.
 *
 * Limitation to remember: a log written in a transaction that is later rolled back is
 * rolled back too. Services therefore catch, log and continue rather than re-throw.
 */
public with sharing class ErrorLogger {

    @TestVisible
    private static final Integer MESSAGE_LIMIT = 32000;
    public static final String SEVERITY_ERROR = 'Error';
    public static final String SEVERITY_WARNING = 'Warning';

    public static void log(String source, Exception error, Id recordId) {
        String message = error == null
            ? 'Unknown error'
            : error.getTypeName() + ': ' + error.getMessage() + '\n' + error.getStackTraceString();
        logMessage(source, message, recordId, SEVERITY_ERROR);
    }

    public static void logMessage(String source, String message, Id recordId, String severity) {
        write(new List<Error_Log__c>{ build(source, message, recordId, severity) });
    }

    /** Logs every failed row of a partial-success DML operation. */
    public static void logSaveResults(String source, List<Database.SaveResult> results, List<SObject> records) {
        if (results == null) {
            return;
        }
        List<Error_Log__c> logs = new List<Error_Log__c>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                continue;
            }
            Id recordId = (records != null && i < records.size()) ? records[i].Id : null;
            logs.add(build(source, describe(results[i].getErrors()), recordId, SEVERITY_ERROR));
        }
        write(logs);
    }

    public static String describe(List<Database.Error> errors) {
        List<String> parts = new List<String>();
        for (Database.Error e : errors) {
            String fields = e.getFields().isEmpty() ? '' : ' [' + String.join(e.getFields(), ', ') + ']';
            parts.add(String.valueOf(e.getStatusCode()) + ': ' + e.getMessage() + fields);
        }
        return String.join(parts, '; ');
    }

    private static Error_Log__c build(String source, String message, Id recordId, String severity) {
        return new Error_Log__c(
            Source__c = source == null ? null : source.left(120),
            Severity__c = severity == null ? SEVERITY_ERROR : severity,
            Message__c = message == null ? null : message.left(MESSAGE_LIMIT),
            Record_Id__c = recordId == null ? null : String.valueOf(recordId)
        );
    }

    private static void write(List<Error_Log__c> logs) {
        if (logs.isEmpty()) {
            return;
        }
        for (Error_Log__c entry : logs) {
            System.debug(LoggingLevel.ERROR, 'CareLoop error in ' + entry.Source__c + ': ' + entry.Message__c);
        }
        try {
            Database.insert(logs, false, AccessLevel.SYSTEM_MODE);
        } catch (Exception loggingFailure) {
            System.debug(LoggingLevel.ERROR, 'ErrorLogger could not write a log: ' + loggingFailure.getMessage());
        }
    }
}
