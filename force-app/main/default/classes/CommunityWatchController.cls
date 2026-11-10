/**
 * Apex for the Community Watch page.
 *  - getOverview: the village x signal grid (live evaluation, counts only) and the recorded signals.
 *  - runScan: managers with the CareLoop_Run_Sentinel custom permission can scan now.
 *  - updateStatus: investigate / confirm / dismiss, with notes (USER_MODE, so only users allowed to
 *    edit Community Signals can do it).
 *  - getEvidence: the contributing visits or care activities, read in USER_MODE, so each person only
 *    sees the patient records their role and sharing already allow.
 */
public with sharing class CommunityWatchController {

    public static final String RUN_PERMISSION = 'CareLoop_Run_Sentinel';
    public static final Set<String> STATUSES = new Set<String>{
        SentinelService.STATUS_NEW, SentinelService.STATUS_INVESTIGATING, SentinelService.STATUS_CLOSED, SentinelService.STATUS_DISMISSED
    };

    public class Cell {
        @AuraEnabled public String signalKey;
        @AuraEnabled public Integer observed;
        @AuraEnabled public Decimal expected;
        @AuraEnabled public String severity;
        @AuraEnabled public Boolean insufficientHistory;
        @AuraEnabled public List<Integer> weekly;
        @AuraEnabled public String explanation;
    }
    public class Row {
        @AuraEnabled public Id villageId;
        @AuraEnabled public String villageName;
        @AuraEnabled public String region;
        @AuraEnabled public List<Cell> cells = new List<Cell>();
    }
    public class Overview {
        @AuraEnabled public Date asOf;
        @AuraEnabled public Boolean canRunScan;
        @AuraEnabled public Boolean canReview;
        @AuraEnabled public List<String> signalKeys = new List<String>();
        @AuraEnabled public List<String> signalLabels = new List<String>();
        @AuraEnabled public List<Row> rows = new List<Row>();
        @AuraEnabled public List<Community_Signal__c> signals = new List<Community_Signal__c>();
    }
    public class Evidence {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String title;
        @AuraEnabled public String detail;
        @AuraEnabled public Date eventDate;
    }

    @AuraEnabled
    public static Overview getOverview() {
        try {
            Overview o = new Overview();
            o.asOf = CareLoopClock.today();
            o.canRunScan = FeatureManagement.checkPermission(RUN_PERMISSION);
            o.canReview = Schema.SObjectType.Community_Signal__c.isUpdateable();
            for (Surveillance_Signal__mdt s : SentinelService.signals()) {
                o.signalKeys.add(s.DeveloperName);
                o.signalLabels.add(s.MasterLabel);
            }
            Map<Id, Row> rows = new Map<Id, Row>();
            Map<String, SentinelService.SignalResult> byKey = new Map<String, SentinelService.SignalResult>();
            for (SentinelService.SignalResult r : SentinelService.evaluate(o.asOf)) {
                if (!rows.containsKey(r.villageId)) {
                    Row row = new Row();
                    row.villageId = r.villageId;
                    row.villageName = r.villageName;
                    row.region = r.region;
                    rows.put(r.villageId, row);
                }
                byKey.put(r.villageId + '|' + r.signalKey, r);
            }
            for (Row row : rows.values()) {
                for (String key : o.signalKeys) {
                    SentinelService.SignalResult r = byKey.get(row.villageId + '|' + key);
                    Cell c = new Cell();
                    c.signalKey = key;
                    c.observed = r == null ? 0 : r.observed;
                    c.expected = r == null ? Decimal.valueOf(0) : r.expected;
                    c.severity = r == null ? SentinelService.NORMAL : r.severity;
                    c.insufficientHistory = r == null ? true : r.insufficientHistory;
                    c.weekly = r == null ? new List<Integer>() : r.weekly;
                    c.explanation = r == null ? '' : r.explanation;
                    row.cells.add(c);
                }
                o.rows.add(row);
            }
            o.signals = [
                SELECT Id, Name, Village__c, Village__r.Name, Region__c, Signal_Key__c, Signal_Label__c, Severity__c, Status__c,
                       Observed__c, Expected__c, Z_Score__c, Households__c, Rate_Per_1000__c, Weekly_Counts__c,
                       Window_Start__c, Window_End__c, Explanation__c, Guidance__c, Investigation_Notes__c,
                       Reviewed_By__r.Name, Reviewed_On__c, CreatedDate
                FROM Community_Signal__c
                WITH USER_MODE
                ORDER BY Window_End__c DESC, Z_Score__c DESC
                LIMIT 50
            ];
            return o;
        } catch (Exception e) {
            throw new AuraHandledException('Could not load Community Watch: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static SentinelService.ScanSummary runScan() {
        if (!FeatureManagement.checkPermission(RUN_PERMISSION)) {
            throw new AuraHandledException('Only programme managers can run the community scan.');
        }
        try {
            return SentinelService.scan(CareLoopClock.today(), true);
        } catch (Exception e) {
            ErrorLogger.log('CommunityWatchController.runScan', e, null);
            throw new AuraHandledException('The scan failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateStatus(Id signalId, String status, String notes) {
        if (!STATUSES.contains(status)) {
            throw new AuraHandledException('Unknown status.');
        }
        if (SentinelService.SUPPRESSING_STATUSES.contains(status) && String.isBlank(notes)) {
            throw new AuraHandledException('Please write what you found before closing or dismissing a signal.');
        }
        List<Community_Signal__c> rows = [SELECT Id, Investigation_Notes__c FROM Community_Signal__c WHERE Id = :signalId WITH USER_MODE];
        if (rows.isEmpty()) {
            throw new AuraHandledException('Signal not found.');
        }
        String stamp = '[' + System.now().format('d MMM yyyy HH:mm') + ' ' + UserInfo.getName() + ' -> ' + status + '] ';
        String history = rows[0].Investigation_Notes__c == null ? '' : rows[0].Investigation_Notes__c + '\n';
        Community_Signal__c change = new Community_Signal__c(
            Id = signalId,
            Status__c = status,
            Reviewed_By__c = UserInfo.getUserId(),
            Reviewed_On__c = System.now(),
            Investigation_Notes__c = (history + stamp + (notes == null ? '' : notes)).right(4000)
        );
        try {
            Database.update(change, true, AccessLevel.USER_MODE);
        } catch (Exception e) {
            throw new AuraHandledException('You cannot update this signal: ' + e.getMessage());
        }
    }

    /** Contributing records the current user is allowed to see (sharing applies). */
    @AuraEnabled
    public static List<Evidence> getEvidence(Id signalId) {
        List<Community_Signal__c> rows = [SELECT Evidence_Ids__c FROM Community_Signal__c WHERE Id = :signalId WITH USER_MODE];
        List<Evidence> out = new List<Evidence>();
        if (rows.isEmpty() || String.isBlank(rows[0].Evidence_Ids__c)) {
            return out;
        }
        Set<Id> visitIds = new Set<Id>();
        Set<Id> activityIds = new Set<Id>();
        for (String text : rows[0].Evidence_Ids__c.split(',')) {
            Id recordId = Id.valueOf(text.trim());
            if (recordId.getSObjectType() == Health_Visit__c.SObjectType) {
                visitIds.add(recordId);
            } else if (recordId.getSObjectType() == Care_Activity__c.SObjectType) {
                activityIds.add(recordId);
            }
        }
        if (!visitIds.isEmpty() && Schema.SObjectType.Health_Visit__c.isAccessible()) {
            for (Health_Visit__c v : [SELECT Id, Visit_Date__c, Visit_Outcome__c, Symptoms__c, Temperature__c, SpO2__c, Patient__r.Name
                                      FROM Health_Visit__c WHERE Id IN :visitIds WITH USER_MODE ORDER BY Visit_Date__c DESC]) {
                Evidence e = new Evidence();
                e.recordId = v.Id;
                e.title = v.Patient__r.Name;
                e.eventDate = v.Visit_Date__c.date();
                List<String> parts = new List<String>{ v.Visit_Outcome__c };
                if (v.Symptoms__c != null) { parts.add(v.Symptoms__c.replace(';', ', ')); }
                if (v.Temperature__c != null) { parts.add(v.Temperature__c + ' C'); }
                if (v.SpO2__c != null) { parts.add('SpO2 ' + v.SpO2__c.intValue() + '%'); }
                e.detail = String.join(parts, ' · ');
                out.add(e);
            }
        }
        if (!activityIds.isEmpty() && Schema.SObjectType.Care_Activity__c.isAccessible()) {
            for (Care_Activity__c a : [SELECT Id, Name, Due_Date__c, Status__c, Patient__r.Name FROM Care_Activity__c
                                       WHERE Id IN :activityIds WITH USER_MODE ORDER BY Due_Date__c DESC]) {
                Evidence e = new Evidence();
                e.recordId = a.Id;
                e.title = a.Patient__r.Name;
                e.eventDate = a.Due_Date__c;
                e.detail = a.Name + ' · ' + a.Status__c;
                out.add(e);
            }
        }
        return out;
    }
}
