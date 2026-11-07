/**
 * Sends the SMS as a REST call through the Named Credential in CareLoop_Setting__mdt.SMS_Named_Credential__c
 * (default CareLoop_SMS). No endpoint or secret lives in code: the Named Credential holds the URL
 * and authentication. In this demo the Named Credential points at a public echo service
 * (https://postman-echo.com), which returns the request, so the full integration is exercised
 * without sending a real SMS. A production gateway (DLT-registered in India) only needs a
 * different Named Credential and, if its payload differs, a provider class.
 */
public with sharing class HttpSmsProvider implements SmsProvider {

    public static final String DEFAULT_NAMED_CREDENTIAL = 'CareLoop_SMS';
    public static final String PATH = '/post';

    public SmsResult send(String toNumber, String fromNumber, String body, String reference) {
        CareLoop_Setting__mdt s = CareRules.setting();
        String credential = (s == null || String.isBlank(s.SMS_Named_Credential__c)) ? DEFAULT_NAMED_CREDENTIAL : s.SMS_Named_Credential__c;
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + credential + PATH);
        request.setMethod('POST');
        request.setTimeout(20000);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(new Map<String, Object>{
            'to' => toNumber,
            'from' => fromNumber,
            'text' => body,
            'reference' => reference
        }));
        try {
            HttpResponse response = new Http().send(request);
            Integer code = response.getStatusCode();
            String responseBody = response.getBody() == null ? '' : response.getBody();
            Boolean ok = code >= 200 && code < 300;
            return new SmsResult(ok, 'HTTP SMS gateway (' + credential + ')', ('HTTP ' + code + ' ' + responseBody).left(2000));
        } catch (Exception e) {
            return new SmsResult(false, 'HTTP SMS gateway (' + credential + ')', ('Callout failed: ' + e.getMessage()).left(2000));
        }
    }
}
