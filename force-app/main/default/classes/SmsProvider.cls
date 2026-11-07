/**
 * Outbound SMS adapter. The implementation is chosen by CareLoop_Setting__mdt.SMS_Provider_Class__c
 * (SimulatedSmsProvider or HttpSmsProvider), so a real, licensed gateway can be plugged in later
 * without touching the dispatcher.
 */
public interface SmsProvider {
    SmsResult send(String toNumber, String fromNumber, String body, String reference);
}
