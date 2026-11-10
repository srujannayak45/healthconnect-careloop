@IsTest
private class CommunityWatchControllerTest {

    /** A user with the given permission sets; staff=true uses the restricted CareLoop staff profile. */
    private static User userWith(List<String> permissionSets, Boolean staff) {
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u = CareLoopPhase4TestData.newUser('sen');
            if (staff) {
                List<Profile> profiles = [SELECT Id FROM Profile WHERE Name IN ('CareLoop Platform Staff', 'Standard Platform User')
                                          ORDER BY Name ASC LIMIT 1];
                u.ProfileId = profiles[0].Id;
            }
            insert u;
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name IN :permissionSets]) {
                assignments.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id));
            }
            insert assignments;
        }
        return u;
    }

    private static Id setUpSpike() {
        CareLoopTestFactory.useRealToday();
        Map<String, Object> f = new Map<String, Object>{
            'DeveloperName' => 'Fever_Cluster', 'MasterLabel' => 'Fever cluster', 'Active__c' => true, 'Source__c' => 'Health Visit',
            'Symptoms__c' => 'Fever', 'Min_Count__c' => 3, 'Watch_Z__c' => 2, 'Alert_Z__c' => 3, 'Baseline_Weeks__c' => 4,
            'Min_History_Weeks__c' => 2
        };
        SentinelService.signalOverride = new List<Surveillance_Signal__mdt>{
            (Surveillance_Signal__mdt) JSON.deserialize(JSON.serialize(f), Surveillance_Signal__mdt.class)
        };
        Village__c v = new Village__c(Name = 'Watch Village', Region__c = 'South', District__c = 'D', State__c = 'Telangana');
        insert v;
        Account hh = new Account(Name = 'Watch household', Village__c = v.Id);
        insert hh;
        TriggerHandler.bypass('ContactTriggerHandler');
        Contact p = CareLoopTestFactory.newPatient(hh.Id, v.Id, Date.today().addYears(-40));
        insert p;
        TriggerHandler.clearBypass('ContactTriggerHandler');
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer i = 0; i < 4; i++) {
            visits.add(new Health_Visit__c(Patient__c = p.Id, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed',
                Visit_Date__c = Datetime.newInstance(Date.today().addDays(-i), Time.newInstance(0, 5, 0, 0)), Symptoms__c = 'Fever'));
        }
        for (Integer week = 1; week <= 4; week++) {   // ordinary visits = history to compare with
            visits.add(new Health_Visit__c(Patient__c = p.Id, Visit_Type__c = 'Routine Check-up', Visit_Outcome__c = 'Completed',
                Visit_Date__c = Datetime.newInstance(Date.today().addDays(-(week * 7 + 2)), Time.newInstance(0, 5, 0, 0))));
        }
        insert visits;
        return v.Id;
    }

    @IsTest
    static void managerScansReviewsAndSeesEvidence() {
        Id villageId = setUpSpike();
        User manager = userWith(new List<String>{ 'CareLoop_Sentinel_Manager' }, false);
        System.runAs(manager) {
            CommunityWatchController.Overview before = CommunityWatchController.getOverview();
            Assert.isTrue(before.canRunScan);
            Assert.areEqual(1, before.signalKeys.size());
            Boolean found = false;
            for (CommunityWatchController.Row row : before.rows) {
                if (row.villageId == villageId) {
                    found = true;
                    Assert.areEqual('Alert', row.cells[0].severity);
                }
            }
            Assert.isTrue(found);

            SentinelService.ScanSummary summary = CommunityWatchController.runScan();
            Assert.areEqual(1, summary.created);
            Community_Signal__c signal = CommunityWatchController.getOverview().signals[0];

            try {
                CommunityWatchController.updateStatus(signal.Id, 'Dismissed', '');
                Assert.fail('Notes are required to dismiss');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            CommunityWatchController.updateStatus(signal.Id, 'Investigating', 'Health worker visiting today');
            CommunityWatchController.updateStatus(signal.Id, 'Closed', 'Four cases in one family, referred to PHC');
            Community_Signal__c after = [SELECT Status__c, Reviewed_By__c, Investigation_Notes__c FROM Community_Signal__c WHERE Id = :signal.Id];
            Assert.areEqual('Closed', after.Status__c);
            Assert.areEqual(manager.Id, after.Reviewed_By__c);
            Assert.isTrue(after.Investigation_Notes__c.contains('Investigating') && after.Investigation_Notes__c.contains('Closed'));
            Assert.areEqual(0, CommunityWatchController.runScan().created, 'a closed signal is not raised again the same week');
        }
        // The evidence is read with the viewer's sharing: the admin sees all four visits.
        Community_Signal__c signal = [SELECT Id FROM Community_Signal__c];
        Assert.areEqual(4, CommunityWatchController.getEvidence(signal.Id).size());
    }

    @IsTest
    static void viewersCannotScanOrChangeSignals() {
        Id villageId = setUpSpike();
        SentinelService.scan(Date.today(), false);
        Community_Signal__c signal = [SELECT Id FROM Community_Signal__c];
        User viewer = userWith(new List<String>{ 'CareLoop_Sentinel_Viewer', 'CareLoop_Health_Worker' }, true);
        System.runAs(viewer) {
            CommunityWatchController.Overview o = CommunityWatchController.getOverview();
            Assert.isFalse(o.canRunScan);
            Assert.isFalse(o.canReview);
            Assert.areEqual(1, o.signals.size(), 'viewers can read signals (counts only)');
            try {
                CommunityWatchController.runScan();
                Assert.fail('Viewers cannot scan');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            try {
                CommunityWatchController.updateStatus(signal.Id, 'Investigating', 'x');
                Assert.fail('Viewers cannot change a signal');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
            Assert.areEqual(0, CommunityWatchController.getEvidence(signal.Id).size(),
                'a health worker outside this household\'s hierarchy sees no patient records');
            for (CommunityWatchController.Row row : o.rows) {
                if (row.villageId == villageId) {
                    Assert.areEqual(0, row.cells[0].observed, 'grid counts only include records the viewer can see');
                    Assert.areNotEqual('Alert', row.cells[0].severity);
                }
            }
        }
    }

    @IsTest
    static void invalidRequestsAreRejected() {
        Id villageId = setUpSpike();
        SentinelService.scan(Date.today(), false);
        Community_Signal__c signal = [SELECT Id, Village__c FROM Community_Signal__c];
        Assert.areEqual(villageId, signal.Village__c);
        for (String status : new List<String>{ 'Confirmed', 'Outbreak', null }) {
            try {
                CommunityWatchController.updateStatus(signal.Id, status, 'note');
                Assert.fail('Status ' + status + ' must be rejected');
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage());
            }
        }
        try {
            CommunityWatchController.updateStatus(signal.Id, 'Closed', '  ');
            Assert.fail('Closing needs a note');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        delete signal;
        try {
            CommunityWatchController.updateStatus(signal.Id, 'Investigating', 'x');
            Assert.fail('Unknown signal');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Assert.areEqual(0, CommunityWatchController.getEvidence(signal.Id).size());
        Assert.areEqual(0, [SELECT COUNT() FROM Community_Signal__c]);
    }
}
