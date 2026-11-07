/** Result of one SMS send attempt. */
public with sharing class SmsResult {
    public Boolean success;
    public String providerName;
    public String providerResponse;

    public SmsResult(Boolean success, String providerName, String providerResponse) {
        this.success = success;
        this.providerName = providerName;
        this.providerResponse = providerResponse;
    }
}
