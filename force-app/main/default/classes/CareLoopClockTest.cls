@IsTest
private class CareLoopClockTest {

    @IsTest
    static void usesTheRealDateWithoutSimulation() {
        CareRules.settingRecord = new CareLoop_Setting__mdt();
        Assert.areEqual(Date.today(), CareLoopClock.today());
        Assert.isFalse(CareLoopClock.isSimulated());
    }

    @IsTest
    static void usesTheSimulatedDateFromSettings() {
        CareRules.settingRecord = (CareLoop_Setting__mdt) JSON.deserialize(
            '{"DeveloperName":"Default","Simulated_Today__c":"2027-01-15"}', CareLoop_Setting__mdt.class);
        Assert.areEqual(Date.newInstance(2027, 1, 15), CareLoopClock.today());
        Assert.isTrue(CareLoopClock.isSimulated());
    }

    @IsTest
    static void testOverrideWinsOverSettings() {
        CareRules.settingRecord = (CareLoop_Setting__mdt) JSON.deserialize(
            '{"DeveloperName":"Default","Simulated_Today__c":"2027-01-15"}', CareLoop_Setting__mdt.class);
        CareLoopClock.testToday = Date.newInstance(2030, 6, 1);
        Assert.areEqual(Date.newInstance(2030, 6, 1), CareLoopClock.today());
        Assert.isFalse(CareLoopClock.isSimulated());
    }
}
