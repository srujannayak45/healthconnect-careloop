/** Records the SMS as sent without any network call (offline demos, tests, no gateway configured). */
public with sharing class SimulatedSmsProvider implements SmsProvider {
    public SmsResult send(String toNumber, String fromNumber, String body, String reference) {
        return new SmsResult(true, 'Simulated SMS', 'SIMULATED-' + reference + ' to ' + toNumber);
    }
}
