@IsTest
private class ConsentServiceTest {

    private static Contact patient() {
        return CareLoopPhase4TestData.insertPatient(UserInfo.getUserId(), Date.today().addYears(-30), 'English', 'Portal Inbox', false);
    }

    @IsTest
    static void grantAndWithdrawBuildAVerifiableChain() {
        Contact p = patient();
        ConsentService.record(new List<ConsentService.ConsentRequest>{
            new ConsentService.ConsentRequest(p.Id, ConsentService.PURPOSE_REMINDERS, true, 'Paper Form', 'Signed at registration'),
            new ConsentService.ConsentRequest(p.Id, ConsentService.PURPOSE_SHARE_DOCTORS, true, 'Paper Form', null)
        });
        ConsentService.record(new List<ConsentService.ConsentRequest>{
            new ConsentService.ConsentRequest(p.Id, ConsentService.PURPOSE_REMINDERS, false, 'Verbal (Witnessed)', 'Moving away')
        });

        List<Consent_Event__c> events = [SELECT Sequence__c, Previous_Hash__c, Event_Hash__c, Action__c FROM Consent_Event__c
                                         WHERE Patient__c = :p.Id ORDER BY Sequence__c];
        Assert.areEqual(3, events.size());
        Assert.areEqual(ConsentService.GENESIS, events[0].Previous_Hash__c);
        Assert.areEqual(events[0].Event_Hash__c, events[1].Previous_Hash__c);
        Assert.areEqual(events[1].Event_Hash__c, events[2].Previous_Hash__c);
        Assert.areEqual(64, events[2].Event_Hash__c.length());

        Consent__c reminders = [SELECT Status__c, Channel__c FROM Consent__c WHERE Patient__c = :p.Id AND Purpose__c = :ConsentService.PURPOSE_REMINDERS];
        Assert.areEqual('Withdrawn', reminders.Status__c);
        Assert.areEqual(2, [SELECT COUNT() FROM Consent__c WHERE Patient__c = :p.Id], 'one current-state row per purpose');
        Contact mirrored = [SELECT Reminder_Consent__c, Data_Sharing_Consent__c FROM Contact WHERE Id = :p.Id];
        Assert.isFalse(mirrored.Reminder_Consent__c);
        Assert.isTrue(mirrored.Data_Sharing_Consent__c);

        ConsentService.VerifyResult result = ConsentService.verify(p.Id);
        Assert.isTrue(result.intact, result.message);
        Assert.areEqual(3, result.events);
    }

    @IsTest
    static void tamperingIsDetectedAndEditsAreBlocked() {
        Contact p = patient();
        ConsentService.record(new List<ConsentService.ConsentRequest>{
            new ConsentService.ConsentRequest(p.Id, ConsentService.PURPOSE_REMINDERS, true, 'Paper Form', null),
            new ConsentService.ConsentRequest(p.Id, ConsentService.PURPOSE_REMINDERS, false, 'Paper Form', null)
        });
        Consent_Event__c first = [SELECT Id FROM Consent_Event__c WHERE Patient__c = :p.Id AND Sequence__c = 1];

        try {
            update new Consent_Event__c(Id = first.Id, Action__c = 'Withdrawn');
            Assert.fail('Edits must be blocked');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('append-only'), e.getMessage());
        }
        try {
            delete first;
            Assert.fail('Deletes must be blocked');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('append-only'), e.getMessage());
        }

        // Simulate someone bypassing the protection (for example a direct data load).
        TriggerHandler.bypass('ConsentEventTriggerHandler');
        update new Consent_Event__c(Id = first.Id, Action__c = 'Withdrawn');
        TriggerHandler.clearBypass('ConsentEventTriggerHandler');

        ConsentService.VerifyResult result = ConsentService.verify(p.Id);
        Assert.isFalse(result.intact);
        Assert.areEqual(1, result.brokenAtSequence);
        Assert.isTrue(result.message.startsWith('TAMPERING DETECTED'), result.message);
    }

    @IsTest
    static void rejectsBadInput() {
        Contact p = patient();
        try {
            ConsentService.record(new List<ConsentService.ConsentRequest>{
                new ConsentService.ConsentRequest(p.Id, ConsentService.PURPOSE_REMINDERS, true, 'Telepathy', null)
            });
            Assert.fail('Unknown channel must be rejected');
        } catch (ConsentService.ConsentException e) {
            Assert.isTrue(e.getMessage().contains('channel'));
        }
        Assert.isTrue(ConsentService.record(null).isEmpty());
        Assert.areEqual('No consent events recorded yet.', ConsentService.verify(p.Id).message);
    }

    @IsTest
    static void staffControllerRecordsAndVerifies() {
        Contact p = patient();
        ConsentLedgerController.LedgerView view = ConsentLedgerController.recordConsent(p.Id,
            ConsentService.PURPOSE_REMINDERS, true, 'Verbal (Witnessed)', 'Agreed during home visit');
        Assert.areEqual(1, view.events.size());
        Assert.areEqual(1, view.consents.size());
        Assert.isTrue(ConsentLedgerController.verifyLedger(p.Id).intact);
        Assert.areEqual(1, ConsentLedgerController.getLedger(p.Id).events.size());
        try {
            ConsentLedgerController.recordConsent(p.Id, ConsentService.PURPOSE_REMINDERS, true, 'Patient Portal', null);
            Assert.fail('Staff cannot record portal consent');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
    }
}
