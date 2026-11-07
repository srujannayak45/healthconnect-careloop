/**
 * The programme's "today".
 *
 * Every CareLoop rule that depends on the date (due, overdue, days overdue, escalation)
 * asks this class instead of calling Date.today(). Normally it returns the real date.
 * For a live demo, an admin can set CareLoop Setting > Default > Simulated Today
 * (Setup > Custom Metadata Types) to move the programme forward, for example to show an
 * activity becoming overdue and escalating, without waiting days. Clear the field to
 * return to the real date.
 *
 * Note: validation rules (for example "completed date cannot be in the future") always use
 * the real date, because they protect data quality rather than demo timing.
 */
public with sharing class CareLoopClock {

    @TestVisible
    private static Date testToday;

    public static Date today() {
        if (testToday != null) {
            return testToday;
        }
        Date simulated = CareRules.setting().Simulated_Today__c;
        return simulated != null ? simulated : Date.today();
    }

    /** True when the demo clock (Simulated Today) is in use. */
    public static Boolean isSimulated() {
        return testToday == null && CareRules.setting().Simulated_Today__c != null;
    }
}
