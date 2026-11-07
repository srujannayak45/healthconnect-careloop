// Phase 1 schema check: confirms every CareLoop object and field exists and custom metadata loaded.
// Run: sf apex run --file scripts/apex/verify-phase1.apex --target-org careloop
// Read the lines that contain USER_DEBUG. The last one says PHASE 1 SCHEMA OK or lists what is missing.
Map<String, List<String>> expected = new Map<String, List<String>>();
expected.put('Village__c', new List<String>{ 'District__c', 'State__c', 'Region__c', 'Location__c', 'Population__c', 'Health_Worker__c', 'Active__c' });
expected.put('Health_Visit__c', new List<String>{ 'Patient__c', 'Visit_Date__c', 'Visit_Type__c', 'Visit_Outcome__c', 'Health_Worker__c', 'BP_Systolic__c', 'BP_Diastolic__c', 'Pulse__c', 'Temperature__c', 'SpO2__c', 'Blood_Sugar__c', 'Weight_Kg__c', 'Height_Cm__c', 'BMI__c', 'Symptoms__c', 'Observations__c', 'Needs_Doctor_Review__c', 'Red_Flag__c', 'Red_Flag_Reason__c', 'Review_Status__c', 'Reviewed_By__c', 'Reviewed_On__c' });
expected.put('Medical_Recommendation__c', new List<String>{ 'Outreach_Visit__c', 'Patient_Name__c', 'Doctor__c', 'Status__c', 'Assessment__c', 'Advice__c', 'Medication_Advice__c', 'Doctor_Notes__c', 'Follow_Up_In_Days__c', 'Check_Up_Interval_Days__c', 'Check_Up_Occurrences__c', 'Referral_Required__c', 'Finalized_On__c' });
expected.put('Care_Activity__c', new List<String>{ 'Patient__c', 'Activity_Type__c', 'Status__c', 'Due_Date__c', 'Completed_Date__c', 'Completed_Visit__c', 'Description__c', 'Source__c', 'Schedule_Key__c', 'Dose_Number__c', 'Recommendation__c', 'Assigned_To__c', 'Days_Overdue__c', 'Escalation_Level__c', 'Last_Escalated_On__c', 'Escalation_Paused_Until__c', 'Reminders_Sent__c', 'Next_Action__c', 'Patient_Response__c', 'Proposed_Date__c', 'Patient_Response_Date__c', 'Closure_Reason__c', 'Approval_Status__c', 'Is_Open__c', 'Is_Completed__c', 'Is_Overdue__c', 'Completed_On_Time__c' });
expected.put('Consent__c', new List<String>{ 'Patient__c', 'Purpose__c', 'Status__c', 'Channel__c', 'Captured_By__c', 'Effective_On__c', 'Consent_Key__c', 'Latest_Event_Hash__c' });
expected.put('Consent_Event__c', new List<String>{ 'Patient__c', 'Purpose__c', 'Action__c', 'Channel__c', 'Performed_By__c', 'Event_Time__c', 'Sequence__c', 'Reason__c', 'Previous_Hash__c', 'Event_Hash__c' });
expected.put('Notification__c', new List<String>{ 'Patient__c', 'Care_Activity__c', 'Channel__c', 'Language__c', 'Subject__c', 'Message__c', 'Status__c', 'Skip_Reason__c', 'Notification_Key__c', 'Escalation_Level__c', 'Recipient__c', 'Provider__c', 'Attempts__c', 'Sent_On__c', 'Read_On__c', 'Provider_Response__c' });
expected.put('Error_Log__c', new List<String>{ 'Source__c', 'Severity__c', 'Message__c', 'Record_Id__c' });
expected.put('Contact', new List<String>{ 'Patient_Code__c', 'Gender__c', 'Village__c', 'Preferred_Language__c', 'Preferred_Channel__c', 'Is_Pregnant__c', 'Expected_Delivery_Date__c', 'Chronic_Conditions__c', 'Assigned_Health_Worker__c', 'Age__c', 'Priority_Score__c', 'Priority_Level__c', 'Priority_Explanation__c', 'Priority_Calculated_On__c', 'Next_Best_Action__c', 'Open_Care_Gaps__c', 'Overdue_Activities__c', 'Last_Successful_Contact__c', 'Failed_Outreach_Attempts__c', 'Reminder_Consent__c', 'Data_Sharing_Consent__c' });
expected.put('Account', new List<String>{ 'Household_Code__c', 'Village__c' });
Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
Integer missing = 0;
for (String objectName : expected.keySet()) {
    Schema.SObjectType objectType = globalDescribe.get(objectName.toLowerCase());
    if (objectType == null) {
        System.debug(LoggingLevel.ERROR, 'MISSING OBJECT ' + objectName);
        missing++;
        continue;
    }
    Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
    Integer found = 0;
    for (String fieldName : expected.get(objectName)) {
        if (fieldMap.containsKey(fieldName.toLowerCase())) {
            found++;
        } else {
            System.debug(LoggingLevel.ERROR, 'MISSING FIELD ' + objectName + '.' + fieldName);
            missing++;
        }
    }
    System.debug(LoggingLevel.ERROR, objectName + ': ' + found + '/' + expected.get(objectName).size() + ' fields');
}
Map<String, Integer> expectedRecords = new Map<String, Integer>{
    'Care_Schedule__mdt' => 16, 'Care_Rule__mdt' => 20, 'Escalation_Rule__mdt' => 3,
    'Message_Template__mdt' => 6, 'CareLoop_Setting__mdt' => 1
};
for (String typeName : expectedRecords.keySet()) {
    Integer actual = Database.query('SELECT DeveloperName FROM ' + typeName).size();
    System.debug(LoggingLevel.ERROR, typeName + ': ' + actual + ' records (expected ' + expectedRecords.get(typeName) + ')');
    if (actual != expectedRecords.get(typeName)) {
        missing++;
    }
}
System.debug(LoggingLevel.ERROR, missing == 0 ? 'PHASE 1 SCHEMA OK' : 'PHASE 1 SCHEMA PROBLEMS: ' + missing);
