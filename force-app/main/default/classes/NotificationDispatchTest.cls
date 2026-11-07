@IsTest
private class NotificationDispatchTest {

    private class EchoMock implements HttpCalloutMock {
        public Integer status;
        public EchoMock(Integer status) { this.status = status; }
        public HttpResponse respond(HttpRequest request) {
            Assert.isTrue(request.getEndpoint().startsWith('callout:CareLoop_SMS/'), request.getEndpoint());
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setBody('{"json":' + request.getBody() + '}');
            return response;
        }
    }

    private static void useProvider(String className) {
        Map<String, Object> fields = new Map<String, Object>{
            'DeveloperName' => 'Default', 'MasterLabel' => 'Default', 'SMS_Provider_Class__c' => className,
            'SMS_Named_Credential__c' => 'CareLoop_SMS', 'SMS_From__c' => '+910000000000', 'Email_Enabled__c' => false,
            'Max_Reminders_Per_Activity__c' => 3
        };
        CareRules.settingRecord = (CareLoop_Setting__mdt) JSON.deserialize(JSON.serialize(fields), CareLoop_Setting__mdt.class);
    }

    private static Notification__c queued(Id patientId, String channel, String key) {
        return new Notification__c(Patient__c = patientId, Channel__c = channel, Status__c = 'Queued', Subject__c = 'S',
            Message__c = 'Namaste, your check-up is due.', Notification_Key__c = key, Attempts__c = 0);
    }

    @IsTest
    static void httpProviderSendsThroughTheNamedCredential() {
        useProvider('HttpSmsProvider');
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'SMS', true);
        insert queued(p.Id, 'SMS', 'sms-1');   // the trigger also queues the background dispatcher
        Test.setMock(HttpCalloutMock.class, new EchoMock(200));
        Test.startTest();
        Integer remaining = NotificationDispatchQueueable.dispatch(10);
        Test.stopTest();
        Assert.areEqual(0, remaining);
        Notification__c n = [SELECT Status__c, Provider__c, Provider_Response__c, Attempts__c, Sent_On__c FROM Notification__c];
        Assert.areEqual('Sent', n.Status__c);
        Assert.isTrue(n.Provider__c.startsWith('HTTP SMS gateway'), n.Provider__c);
        Assert.isTrue(n.Provider_Response__c.contains('HTTP 200'), n.Provider_Response__c);
        Assert.isTrue(n.Attempts__c == 1);
        Assert.isNotNull(n.Sent_On__c);
    }

    @IsTest
    static void failuresAreRetriedThenMarkedFailed() {
        useProvider('HttpSmsProvider');
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'SMS', true);
        Notification__c n = queued(p.Id, 'SMS', 'sms-2');
        n.Attempts__c = 2;
        insert n;
        Test.setMock(HttpCalloutMock.class, new EchoMock(500));
        Test.startTest();
        Integer remaining = NotificationDispatchQueueable.dispatch(10);
        Test.stopTest();
        Notification__c after = [SELECT Status__c, Attempts__c, Provider_Response__c FROM Notification__c WHERE Id = :n.Id];
        Assert.areEqual('Failed', after.Status__c, 'third failed attempt');
        Assert.isTrue(after.Provider_Response__c.contains('HTTP 500'));
        Assert.areEqual(0, remaining);
    }

    @IsTest
    static void simulatedProviderAndSwitchedOffEmail() {
        useProvider('SimulatedSmsProvider');
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'SMS', true);
        insert new List<Notification__c>{ queued(p.Id, 'SMS', 'sms-3'), queued(p.Id, 'Email', 'mail-1') };
        Test.startTest();
        NotificationDispatchQueueable.dispatch(10);
        Test.stopTest();
        Map<String, Notification__c> byChannel = new Map<String, Notification__c>();
        for (Notification__c n : [SELECT Channel__c, Status__c, Provider__c, Skip_Reason__c FROM Notification__c]) {
            byChannel.put(n.Channel__c, n);
        }
        Assert.areEqual('Sent', byChannel.get('SMS').Status__c);
        Assert.areEqual('Simulated SMS', byChannel.get('SMS').Provider__c);
        Assert.areEqual('Skipped', byChannel.get('Email').Status__c);
    }

    @IsTest
    static void unknownProviderFallsBackToSimulated() {
        useProvider('NoSuchProvider');
        Assert.isTrue(NotificationDispatchQueueable.provider(CareRules.setting()) instanceof SimulatedSmsProvider);
    }

    @IsTest
    static void queueableDeliversInTheBackground() {
        Contact p = CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'SMS', true);
        insert queued(p.Id, 'SMS', 'sms-4');
        Test.setMock(HttpCalloutMock.class, new EchoMock(200));
        Test.startTest();
        System.enqueueJob(new NotificationDispatchQueueable());
        Test.stopTest();
        Assert.areEqual('Sent', [SELECT Status__c FROM Notification__c WHERE Notification_Key__c = 'sms-4'].Status__c);
    }
}
