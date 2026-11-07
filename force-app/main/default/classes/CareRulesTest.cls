@IsTest
private class CareRulesTest {

    @IsTest
    static void openStatusFollowsTheDueDate() {
        Date today = Date.newInstance(2026, 11, 10);
        Integer window = CareRules.dueWindowDays();
        Assert.areEqual(CareRules.STATUS_OVERDUE, CareRules.openStatusFor(today.addDays(-1), today), 'Yesterday is overdue');
        Assert.areEqual(CareRules.STATUS_DUE, CareRules.openStatusFor(today, today), 'Today is due');
        Assert.areEqual(CareRules.STATUS_DUE, CareRules.openStatusFor(today.addDays(window), today), 'Inside the window is due');
        Assert.areEqual(CareRules.STATUS_SCHEDULED, CareRules.openStatusFor(today.addDays(window + 1), today), 'Beyond the window is scheduled');
        Assert.areEqual(CareRules.STATUS_SCHEDULED, CareRules.openStatusFor(null, today), 'No due date stays scheduled');
    }

    @IsTest
    static void daysOverdueCountsOnlyPastDueDates() {
        Date today = Date.newInstance(2026, 11, 10);
        Assert.areEqual(5, CareRules.daysOverdue(today.addDays(-5), today));
        Assert.areEqual(0, CareRules.daysOverdue(today, today));
        Assert.areEqual(0, CareRules.daysOverdue(today.addDays(3), today));
        Assert.areEqual(0, CareRules.daysOverdue(null, today));
    }

    @IsTest
    static void dueWindowComesFromEscalationLevelOne() {
        CareRules.escalationRules = new List<Escalation_Rule__mdt>{
            (Escalation_Rule__mdt) JSON.deserialize(
                '{"DeveloperName":"Level_1","Level__c":1,"Days_From_Due__c":-5,"Active__c":true}',
                Escalation_Rule__mdt.class)
        };
        Assert.areEqual(5, CareRules.dueWindowDays(), 'Window follows the level 1 reminder');

        CareRules.escalationRules = new List<Escalation_Rule__mdt>();
        Assert.areEqual(3, CareRules.dueWindowDays(), 'Falls back to 3 days without a level 1 rule');
    }

    @IsTest
    static void thresholdsAndPointsFallBackWhenARuleIsMissing() {
        CareRules.careRules = new Map<String, Care_Rule__mdt>{
            'TEST_RULE' => CareLoopTestFactory.rule('TEST_RULE', 'Priority', 4, 30, 'test')
        };
        Assert.isTrue(CareRules.threshold('TEST_RULE', 1) == 30, 'Configured threshold is used');
        Assert.isTrue(CareRules.points('TEST_RULE', 1) == 4, 'Configured points are used');
        Assert.isTrue(CareRules.threshold('MISSING', 7) == 7, 'Fallback threshold is used');
        Assert.isTrue(CareRules.points('MISSING', 2) == 2, 'Fallback points are used');
        Assert.isNull(CareRules.rule('MISSING'));
    }

    @IsTest
    static void loadsActiveConfigurationFromCustomMetadata() {
        Integer activeRules = 0;
        for (Care_Rule__mdt r : Care_Rule__mdt.getAll().values()) {
            if (r.Active__c) {
                activeRules++;
            }
        }
        Integer activeSchedules = 0;
        for (Care_Schedule__mdt s : Care_Schedule__mdt.getAll().values()) {
            if (s.Active__c) {
                activeSchedules++;
            }
        }
        Assert.areEqual(activeRules, CareRules.rules().size(), 'All active care rules are loaded');
        Assert.areEqual(activeSchedules, CareRules.activeSchedules().size(), 'All active schedules are loaded');

        List<Escalation_Rule__mdt> ladder = CareRules.activeEscalationRules();
        for (Integer i = 1; i < ladder.size(); i++) {
            Assert.isTrue(ladder[i].Level__c > ladder[i - 1].Level__c, 'Escalation rules are sorted by level');
        }
    }

    @IsTest
    static void statusHelpersClassifyStatuses() {
        Assert.isTrue(CareRules.isOpen('Due'));
        Assert.isTrue(CareRules.isOpen(null), 'A blank status is treated as open');
        Assert.isFalse(CareRules.isOpen('Completed'));
        Assert.isTrue(CareRules.isClosed('Cancelled'));
        Assert.isFalse(CareRules.isClosed('Overdue'));
        Assert.isFalse(CareRules.isClosed(null));
    }

    @IsTest
    static void settingIsNeverNull() {
        Assert.isNotNull(CareRules.setting(), 'A blank setting is returned in tests');
        Assert.isNull(CareRules.setting().Simulated_Today__c, 'Tests ignore the org demo clock');
    }
}
