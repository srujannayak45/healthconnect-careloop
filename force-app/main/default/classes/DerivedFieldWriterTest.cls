@IsTest
private class DerivedFieldWriterTest {

    @IsTest
    static void writesEngineOwnedFields() {
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact patient = CareLoopTestFactory.insertPatient(Date.today().addYears(-40));

        DerivedFieldWriter.write(new List<Contact>{ new Contact(Id = patient.Id, Priority_Score__c = 12) }, 'DerivedFieldWriterTest');

        Contact saved = [SELECT Priority_Score__c FROM Contact WHERE Id = :patient.Id];
        Assert.isTrue(saved.Priority_Score__c == 12, 'Engine-owned field is written');
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c], 'No errors logged');
    }

    @IsTest
    static void logsRecordsThatCannotBeSavedWithoutThrowing() {
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact patient = CareLoopTestFactory.insertPatient(Date.today().addYears(-40));

        // Breaks the Valid_Indian_Mobile validation rule on purpose.
        DerivedFieldWriter.write(new List<Contact>{ new Contact(Id = patient.Id, MobilePhone = '12345') }, 'DerivedFieldWriterTest');

        Error_Log__c entry = [SELECT Source__c, Record_Id__c FROM Error_Log__c];
        Assert.areEqual('DerivedFieldWriterTest', entry.Source__c);
        Assert.areEqual(String.valueOf(patient.Id), entry.Record_Id__c);
    }

    @IsTest
    static void ignoresEmptyInput() {
        DerivedFieldWriter.write(null, 'DerivedFieldWriterTest');
        DerivedFieldWriter.write(new List<Contact>(), 'DerivedFieldWriterTest');
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c]);
    }
}
