@IsTest
private class ErrorLoggerTest {

    private class SimulatedException extends Exception {
    }

    @IsTest
    static void logsAnException() {
        try {
            throw new SimulatedException('Simulated failure');
        } catch (Exception e) {
            ErrorLogger.log('ErrorLoggerTest', e, null);
        }
        Error_Log__c entry = [SELECT Source__c, Severity__c, Message__c, Record_Id__c FROM Error_Log__c];
        Assert.areEqual('ErrorLoggerTest', entry.Source__c);
        Assert.areEqual(ErrorLogger.SEVERITY_ERROR, entry.Severity__c);
        Assert.isTrue(entry.Message__c.contains('Simulated failure'), 'Message is recorded');
        Assert.isNull(entry.Record_Id__c);
    }

    @IsTest
    static void logsOnlyTheFailedRowsOfAPartialSave() {
        Village__c valid = new Village__c(Name = 'Logger Test Village');
        Care_Activity__c invalid = new Care_Activity__c(Name = 'Activity without a patient');
        List<Database.SaveResult> results = new List<Database.SaveResult>{
            Database.insert(valid, false),
            Database.insert(invalid, false)
        };
        ErrorLogger.logSaveResults('ErrorLoggerTest', results, new List<SObject>{ valid, invalid });

        List<Error_Log__c> logs = [SELECT Message__c FROM Error_Log__c];
        Assert.areEqual(1, logs.size(), 'Only the failed row is logged');
        Assert.isTrue(String.isNotBlank(logs[0].Message__c), 'The failure reason is recorded');
    }

    @IsTest
    static void truncatesLongMessagesAndKeepsSeverity() {
        ErrorLogger.logMessage('ErrorLoggerTest', 'x'.repeat(40000), null, ErrorLogger.SEVERITY_WARNING);
        Error_Log__c entry = [SELECT Message__c, Severity__c FROM Error_Log__c];
        Assert.areEqual(ErrorLogger.MESSAGE_LIMIT, entry.Message__c.length());
        Assert.areEqual(ErrorLogger.SEVERITY_WARNING, entry.Severity__c);
    }

    @IsTest
    static void handlesNullInputs() {
        ErrorLogger.log(null, null, null);
        ErrorLogger.logSaveResults('ErrorLoggerTest', null, null);
        Assert.areEqual(1, [SELECT COUNT() FROM Error_Log__c], 'A null exception is still logged once');
    }
}
