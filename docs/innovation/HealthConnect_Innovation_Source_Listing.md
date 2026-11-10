# HealthConnect CareLoop — CareLoop Sentinel Source Listing

Complete content of the 84 source, manifest and script files in `HealthConnect_Innovation_Source.zip` (documents excluded). NEW unless marked MODIFIED.

## `force-app/main/default/objects/Community_Signal__c/Community_Signal__c.object-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <description>CareLoop Sentinel: an unusual rise in a community-level signal in one village, for human investigation. Holds counts only, no patient details.</description>
    <enableActivities>false</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>false</enableHistory>
    <enableLicensing>false</enableLicensing>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <label>Community Signal</label>
    <nameField>
        <label>Signal Name</label>
        <type>Text</type>
    </nameField>
    <pluralLabel>Community Signals</pluralLabel>
    <sharingModel>Read</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Alert_Key__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Alert_Key__c</fullName>
    <caseSensitive>false</caseSensitive>
    <externalId>true</externalId>
    <label>Alert Key</label>
    <length>120</length>
    <required>false</required>
    <type>Text</type>
    <unique>true</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Evidence_Ids__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Evidence_Ids__c</fullName>
    <label>Contributing Records</label>
    <length>10000</length>
    <type>LongTextArea</type>
    <visibleLines>4</visibleLines>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Expected__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Expected__c</fullName>
    <externalId>false</externalId>
    <label>Expected (baseline mean)</label>
    <precision>8</precision>
    <required>false</required>
    <scale>2</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Explanation__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Explanation__c</fullName>
    <label>Why It Was Flagged</label>
    <length>2000</length>
    <type>LongTextArea</type>
    <visibleLines>4</visibleLines>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Guidance__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Guidance__c</fullName>
    <externalId>false</externalId>
    <label>Suggested Verification Steps</label>
    <length>255</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Households__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Households__c</fullName>
    <externalId>false</externalId>
    <label>Households Affected</label>
    <precision>6</precision>
    <required>false</required>
    <scale>0</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Investigation_Notes__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Investigation_Notes__c</fullName>
    <label>Investigation Notes</label>
    <length>4000</length>
    <type>LongTextArea</type>
    <visibleLines>4</visibleLines>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Last_Scanned_On__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Last_Scanned_On__c</fullName>
    <label>Last Scanned On</label>
    <required>false</required>
    <type>DateTime</type>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Observed__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Observed__c</fullName>
    <externalId>false</externalId>
    <label>Observed (this week)</label>
    <precision>6</precision>
    <required>false</required>
    <scale>0</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Rate_Per_1000__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Rate_Per_1000__c</fullName>
    <externalId>false</externalId>
    <label>Rate per 1,000 Population</label>
    <precision>8</precision>
    <required>false</required>
    <scale>2</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Region__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Region__c</fullName>
    <externalId>false</externalId>
    <formula>TEXT(Village__r.Region__c)</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
    <label>Region</label>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Reviewed_By__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Reviewed_By__c</fullName>
    <deleteConstraint>SetNull</deleteConstraint>
    <label>Reviewed By</label>
    <referenceTo>User</referenceTo>
    <relationshipName>Community_Signals_Reviewed</relationshipName>
    <required>false</required>
    <type>Lookup</type>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Reviewed_On__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Reviewed_On__c</fullName>
    <label>Reviewed On</label>
    <required>false</required>
    <type>DateTime</type>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Severity__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Severity__c</fullName>
    <label>Severity</label>
    <required>false</required>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>Watch</fullName>
                <default>true</default>
                <label>Watch</label>
            </value>
            <value>
                <fullName>Alert</fullName>
                <default>false</default>
                <label>Alert</label>
            </value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Signal_Key__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Signal_Key__c</fullName>
    <externalId>false</externalId>
    <label>Signal</label>
    <length>80</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Signal_Label__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Signal_Label__c</fullName>
    <externalId>false</externalId>
    <label>Signal Label</label>
    <length>120</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Status__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Status__c</fullName>
    <inlineHelpText>New: raised by the scan. Investigating: acknowledged, being checked. Closed: checked and follow-up done. Dismissed: checked, not a real increase (e.g. data-entry or duplicate visits).</inlineHelpText>
    <label>Status</label>
    <required>false</required>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>New</fullName>
                <default>true</default>
                <label>New</label>
            </value>
            <value>
                <fullName>Investigating</fullName>
                <default>false</default>
                <label>Investigating</label>
            </value>
            <value>
                <fullName>Closed</fullName>
                <default>false</default>
                <label>Closed</label>
            </value>
            <value>
                <fullName>Dismissed</fullName>
                <default>false</default>
                <label>Dismissed</label>
            </value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Std_Dev__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Std_Dev__c</fullName>
    <externalId>false</externalId>
    <label>Baseline Spread (SD)</label>
    <precision>8</precision>
    <required>false</required>
    <scale>2</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Threshold__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Threshold__c</fullName>
    <externalId>false</externalId>
    <label>Watch Threshold</label>
    <precision>8</precision>
    <required>false</required>
    <scale>2</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Village__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Village__c</fullName>
    <deleteConstraint>SetNull</deleteConstraint>
    <label>Village</label>
    <referenceTo>Village__c</referenceTo>
    <relationshipLabel>Community Signals</relationshipLabel>
    <relationshipName>Community_Signals</relationshipName>
    <required>false</required>
    <type>Lookup</type>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Weekly_Counts__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Weekly_Counts__c</fullName>
    <externalId>false</externalId>
    <label>Weekly Counts (oldest to current)</label>
    <length>120</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Window_End__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Window_End__c</fullName>
    <label>Window End</label>
    <required>false</required>
    <type>Date</type>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Window_Start__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Window_Start__c</fullName>
    <label>Window Start</label>
    <required>false</required>
    <type>Date</type>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/fields/Z_Score__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Z_Score__c</fullName>
    <externalId>false</externalId>
    <label>Standard Deviations Above Normal</label>
    <precision>6</precision>
    <required>false</required>
    <scale>2</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Community_Signal__c/listViews/All.listView-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>All</fullName>
    <columns>NAME</columns>
    <columns>Severity__c</columns>
    <columns>Status__c</columns>
    <columns>Region__c</columns>
    <columns>Observed__c</columns>
    <columns>Expected__c</columns>
    <columns>Z_Score__c</columns>
    <columns>Window_End__c</columns>
    <filterScope>Everything</filterScope>
    <label>All</label>
</ListView>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/Surveillance_Signal__mdt.object-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>CareLoop Sentinel: which community-level signals to watch and when a change counts as unusual. Editable by the programme without code.</description>
    <label>Surveillance Signal</label>
    <pluralLabel>Surveillance Signals</pluralLabel>
    <visibility>Public</visibility>
</CustomObject>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Active__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Active__c</fullName>
    <defaultValue>true</defaultValue>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <label>Active</label>
    <type>Checkbox</type>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Activity_Types__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Activity_Types__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Semicolon-separated care activity types (Care Activity source).</inlineHelpText>
    <label>Activity Types</label>
    <length>120</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Alert_Z__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Alert_Z__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Standard deviations above the baseline mean for an Alert.</inlineHelpText>
    <label>Alert Threshold (SD)</label>
    <precision>4</precision>
    <required>false</required>
    <scale>1</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Baseline_Weeks__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Baseline_Weeks__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>How many previous weeks form the normal level.</inlineHelpText>
    <label>Baseline Weeks</label>
    <precision>2</precision>
    <required>false</required>
    <scale>0</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Grace_Days__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Grace_Days__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Care Activity source: a dose counts as delayed if not given within this many days of its due date.</inlineHelpText>
    <label>Grace Days</label>
    <precision>3</precision>
    <required>false</required>
    <scale>0</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Guidance__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Guidance__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Process guidance shown with an alert. Not clinical advice.</inlineHelpText>
    <label>Suggested Verification Steps</label>
    <length>255</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Max_SpO2__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Max_SpO2__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>A visit also matches if its SpO2 is below this value.</inlineHelpText>
    <label>SpO2 Below</label>
    <precision>3</precision>
    <required>false</required>
    <scale>0</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Min_Count__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Min_Count__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Never flag fewer events than this in the current week (protects against noise in small numbers).</inlineHelpText>
    <label>Minimum Count</label>
    <precision>3</precision>
    <required>false</required>
    <scale>0</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Min_History_Weeks__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Min_History_Weeks__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>How many of the baseline weeks must contain any recorded visit (or dose) before a signal can be raised. Missing data is not treated as zero cases.</inlineHelpText>
    <label>Min History Weeks</label>
    <precision>2</precision>
    <required>false</required>
    <scale>0</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Min_Temperature__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Min_Temperature__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>A visit also matches if its temperature is at or above this value.</inlineHelpText>
    <label>Minimum Temperature (C)</label>
    <precision>4</precision>
    <required>false</required>
    <scale>1</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Source__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Source__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Health Visit or Care Activity.</inlineHelpText>
    <label>Source</label>
    <length>40</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Symptoms__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Symptoms__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Semicolon-separated symptoms; a visit matches if it records any of them.</inlineHelpText>
    <label>Symptoms</label>
    <length>255</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Visit_Outcomes__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Visit_Outcomes__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Semicolon-separated visit outcomes to count (for access signals such as failed visits).</inlineHelpText>
    <label>Visit Outcomes</label>
    <length>255</length>
    <required>false</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/objects/Surveillance_Signal__mdt/fields/Watch_Z__c.field-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Watch_Z__c</fullName>
    <externalId>false</externalId>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <inlineHelpText>Standard deviations above the baseline mean for a Watch.</inlineHelpText>
    <label>Watch Threshold (SD)</label>
    <precision>4</precision>
    <required>false</required>
    <scale>1</scale>
    <type>Number</type>
    <unique>false</unique>
</CustomField>
```

## `force-app/main/default/customMetadata/Surveillance_Signal.Failed_Visit_Surge.md-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Households not reachable</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Activity_Types__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Alert_Z__c</field>
        <value xsi:type="xsd:double">3</value>
    </values>
    <values>
        <field>Baseline_Weeks__c</field>
        <value xsi:type="xsd:double">4</value>
    </values>
    <values>
        <field>Grace_Days__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Guidance__c</field>
        <value xsi:type="xsd:string">Ask the health worker why families are away or refusing (migration, festival, distrust) and plan a camp or a different visit time.</value>
    </values>
    <values>
        <field>Max_SpO2__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Min_Count__c</field>
        <value xsi:type="xsd:double">4</value>
    </values>
    <values>
        <field>Min_History_Weeks__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
    <values>
        <field>Min_Temperature__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Source__c</field>
        <value xsi:type="xsd:string">Health Visit</value>
    </values>
    <values>
        <field>Symptoms__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Visit_Outcomes__c</field>
        <value xsi:type="xsd:string">Patient Not Available;Patient Refused</value>
    </values>
    <values>
        <field>Watch_Z__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
</CustomMetadata>
```

## `force-app/main/default/customMetadata/Surveillance_Signal.Fever_Cluster.md-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Fever cluster</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Activity_Types__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Alert_Z__c</field>
        <value xsi:type="xsd:double">3</value>
    </values>
    <values>
        <field>Baseline_Weeks__c</field>
        <value xsi:type="xsd:double">4</value>
    </values>
    <values>
        <field>Grace_Days__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Guidance__c</field>
        <value xsi:type="xsd:string">Confirm the cases with the health worker, look for a shared exposure (water, mosquitoes, event) and report to the PHC Medical Officer as per IDSP.</value>
    </values>
    <values>
        <field>Max_SpO2__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Min_Count__c</field>
        <value xsi:type="xsd:double">3</value>
    </values>
    <values>
        <field>Min_History_Weeks__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
    <values>
        <field>Min_Temperature__c</field>
        <value xsi:type="xsd:double">38.0</value>
    </values>
    <values>
        <field>Source__c</field>
        <value xsi:type="xsd:string">Health Visit</value>
    </values>
    <values>
        <field>Symptoms__c</field>
        <value xsi:type="xsd:string">Fever</value>
    </values>
    <values>
        <field>Visit_Outcomes__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Watch_Z__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
</CustomMetadata>
```

## `force-app/main/default/customMetadata/Surveillance_Signal.Immunisation_Delay.md-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Vaccine doses delayed</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Activity_Types__c</field>
        <value xsi:type="xsd:string">Immunization</value>
    </values>
    <values>
        <field>Alert_Z__c</field>
        <value xsi:type="xsd:double">3</value>
    </values>
    <values>
        <field>Baseline_Weeks__c</field>
        <value xsi:type="xsd:double">4</value>
    </values>
    <values>
        <field>Grace_Days__c</field>
        <value xsi:type="xsd:double">7</value>
    </values>
    <values>
        <field>Guidance__c</field>
        <value xsi:type="xsd:string">Check vaccine supply and the session plan for this village, then use the Care Navigator to schedule catch-up visits.</value>
    </values>
    <values>
        <field>Max_SpO2__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Min_Count__c</field>
        <value xsi:type="xsd:double">3</value>
    </values>
    <values>
        <field>Min_History_Weeks__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
    <values>
        <field>Min_Temperature__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Source__c</field>
        <value xsi:type="xsd:string">Care Activity</value>
    </values>
    <values>
        <field>Symptoms__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Visit_Outcomes__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Watch_Z__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
</CustomMetadata>
```

## `force-app/main/default/customMetadata/Surveillance_Signal.Respiratory_Cluster.md-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Respiratory illness cluster</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Activity_Types__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Alert_Z__c</field>
        <value xsi:type="xsd:double">3</value>
    </values>
    <values>
        <field>Baseline_Weeks__c</field>
        <value xsi:type="xsd:double">4</value>
    </values>
    <values>
        <field>Grace_Days__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Guidance__c</field>
        <value xsi:type="xsd:string">Confirm the cases, check whether they share a household or workplace, and report to the PHC Medical Officer as per IDSP.</value>
    </values>
    <values>
        <field>Max_SpO2__c</field>
        <value xsi:type="xsd:double">94</value>
    </values>
    <values>
        <field>Min_Count__c</field>
        <value xsi:type="xsd:double">3</value>
    </values>
    <values>
        <field>Min_History_Weeks__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
    <values>
        <field>Min_Temperature__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Source__c</field>
        <value xsi:type="xsd:string">Health Visit</value>
    </values>
    <values>
        <field>Symptoms__c</field>
        <value xsi:type="xsd:string">Cough;Breathlessness</value>
    </values>
    <values>
        <field>Visit_Outcomes__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Watch_Z__c</field>
        <value xsi:type="xsd:double">2</value>
    </values>
</CustomMetadata>
```

## `force-app/main/default/customPermissions/CareLoop_Run_Sentinel.customPermission-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomPermission xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Run the CareLoop Sentinel community scan on demand (programme managers).</description>
    <isLicensed>false</isLicensed>
    <label>Run CareLoop Sentinel Scan</label>
</CustomPermission>
```

## `force-app/main/default/classes/CommunityWatchController.cls` — NEW

```java
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
```

## `force-app/main/default/classes/CommunityWatchController.cls-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

## `force-app/main/default/classes/CommunityWatchControllerTest.cls` — NEW

```java
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
```

## `force-app/main/default/classes/CommunityWatchControllerTest.cls-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

## `force-app/main/default/classes/SentinelJob.cls` — NEW

```java
/**
 * Runs the CareLoop Sentinel scan every morning (06:30, after the 05:30 care sweep) and sends bell
 * notifications for new or escalated community signals. Schedule once with
 * scripts/apex/innovation-schedule-sentinel.apex.
 *
 * Scale note: one transaction is enough for a programme of this size (a few hundred villages and
 * < 40,000 visits in six weeks). For a district-wide roll-out, turn this into Batch Apex that calls
 * SentinelService per chunk of villages.
 */
public with sharing class SentinelJob implements Schedulable {

    public static final String JOB_NAME = 'CareLoop Sentinel Daily Scan';
    public static final String DEFAULT_CRON = '0 30 6 * * ?';

    public void execute(SchedulableContext context) {
        try {
            SentinelService.scan(CareLoopClock.today(), true);
        } catch (Exception e) {
            ErrorLogger.log('SentinelJob', e, null);
        }
    }

    public static Id scheduleDaily() {
        List<CronTrigger> existing = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :JOB_NAME LIMIT 1];
        if (!existing.isEmpty()) {
            return existing[0].Id;
        }
        return System.schedule(JOB_NAME, DEFAULT_CRON, new SentinelJob());
    }
}
```

## `force-app/main/default/classes/SentinelJob.cls-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

## `force-app/main/default/classes/SentinelService.cls` — NEW

```java
/**
 * CareLoop Sentinel - community health early warning.
 *
 * Every day it compares, for each village and each configured signal (Surveillance_Signal__mdt),
 * the count in the latest 7 days with the same village's own previous weeks:
 *
 *     expected  = mean of the baseline weeks          (default: the 4 weeks before)
 *     spread    = standard deviation of those weeks, never below 1 (tiny baselines are not "certain")
 *     z         = (observed - expected) / spread
 *     Watch     when z >= Watch_Z (2) and observed >= Min_Count (3)
 *     Alert     when z >= Alert_Z (3) and observed >= Min_Count
 *     Not assessed when fewer than Min_History_Weeks (2) of the baseline weeks contain ANY recorded
 *               visit (or dose, for activity signals): missing data is not the same as zero cases.
 *
 * This is the idea of the CDC EARS aberration-detection methods used in syndromic surveillance,
 * applied to data CareLoop already collects (symptoms, temperature and SpO2 on visits; visit
 * outcomes; vaccine doses given late). It flags *unusual change* for a human to investigate. It does
 * not diagnose anything or predict outbreaks.
 *
 * Signals live in custom metadata, so the programme can tune thresholds, add symptoms or switch
 * signals off without code. Results hold counts only; the contributing records are stored as Ids,
 * and every drill-down re-applies the viewer's sharing (CommunityWatchController.getEvidence).
 */
public with sharing class SentinelService {

    public static final String SOURCE_VISIT = 'Health Visit';
    public static final String SOURCE_ACTIVITY = 'Care Activity';
    public static final String NORMAL = 'Normal';
    public static final String WATCH = 'Watch';
    public static final String ALERT = 'Alert';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_INVESTIGATING = 'Investigating';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_DISMISSED = 'Dismissed';
    /** A reviewed signal with one of these statuses is not raised again for the same 7-day window. */
    public static final Set<String> SUPPRESSING_STATUSES = new Set<String>{ STATUS_CLOSED, STATUS_DISMISSED };
    public static final String MANAGER_PERMISSION_SET = 'CareLoop_Sentinel_Manager';
    public static final Integer WINDOW_DAYS = 7;
    public static final Decimal MIN_SPREAD = 1;
    public static final Integer DEFAULT_MIN_HISTORY_WEEKS = 2;

    @TestVisible
    private static List<Surveillance_Signal__mdt> signalOverride;

    public class SignalResult {
        @AuraEnabled public Id villageId;
        @AuraEnabled public String villageName;
        @AuraEnabled public String region;
        @AuraEnabled public String signalKey;
        @AuraEnabled public String signalLabel;
        @AuraEnabled public Integer observed = 0;
        @AuraEnabled public Decimal expected = 0;
        @AuraEnabled public Decimal spread = MIN_SPREAD;
        @AuraEnabled public Decimal threshold = 0;
        @AuraEnabled public Decimal z = 0;
        @AuraEnabled public Integer households = 0;
        @AuraEnabled public Decimal ratePer1000;
        @AuraEnabled public String severity = NORMAL;
        @AuraEnabled public Boolean insufficientHistory = false;
        @AuraEnabled public List<Integer> weekly = new List<Integer>();
        @AuraEnabled public Date windowStart;
        @AuraEnabled public Date windowEnd;
        @AuraEnabled public String explanation;
        @AuraEnabled public String guidance;
        public List<Id> evidenceIds = new List<Id>();
        public Set<Id> householdIds = new Set<Id>();
        public List<Integer> baselineCounts = new List<Integer>();
        /** Baseline weeks (1..n) in which the village has ANY recorded visit / dose of the right kind. */
        public Set<Integer> historyWeeks = new Set<Integer>();
    }

    public class ScanSummary {
        @AuraEnabled public Integer cellsEvaluated = 0;
        @AuraEnabled public Integer flagged = 0;
        @AuraEnabled public Integer created = 0;
        @AuraEnabled public Integer updated = 0;
        @AuraEnabled public Integer notified = 0;
    }

    /** Active signals from custom metadata (or injected by tests). */
    public static List<Surveillance_Signal__mdt> signals() {
        if (signalOverride != null) {
            return signalOverride;
        }
        List<Surveillance_Signal__mdt> active = new List<Surveillance_Signal__mdt>();
        for (Surveillance_Signal__mdt s : Surveillance_Signal__mdt.getAll().values()) {
            if (s.Active__c) {
                active.add(s);
            }
        }
        return active;
    }

    /** Evaluates every village x signal as of the given day. Reads only. */
    public static List<SignalResult> evaluate(Date asOf) {
        List<SignalResult> results = new List<SignalResult>();
        List<Surveillance_Signal__mdt> configured = signals();
        if (configured.isEmpty()) {
            return results;
        }
        Map<Id, Village__c> villages = new Map<Id, Village__c>([
            SELECT Id, Name, Region__c, Population__c FROM Village__c
            WHERE Active__c = true
            WITH SYSTEM_MODE
            ORDER BY Region__c, Name
            LIMIT 500
        ]);
        Integer maxWeeks = 1;
        Integer maxGrace = 0;
        Boolean needVisits = false;
        Boolean needActivities = false;
        for (Surveillance_Signal__mdt s : configured) {
            maxWeeks = Math.max(maxWeeks, baselineWeeks(s));
            if (s.Source__c == SOURCE_ACTIVITY) {
                needActivities = true;
                maxGrace = Math.max(maxGrace, graceDays(s));
            } else {
                needVisits = true;
            }
        }
        Date earliest = asOf.addDays(-(WINDOW_DAYS * (maxWeeks + 1)) - maxGrace);
        List<Health_Visit__c> visits = needVisits ? [
            SELECT Id, Visit_Date__c, Symptoms__c, Temperature__c, SpO2__c, Visit_Outcome__c,
                   Patient__r.AccountId, Patient__r.Village__c, Patient__r.Account.Village__c
            FROM Health_Visit__c
            WHERE Visit_Date__c >= :Datetime.newInstance(earliest, Time.newInstance(0, 0, 0, 0))
              AND Visit_Date__c < :Datetime.newInstance(asOf.addDays(1), Time.newInstance(0, 0, 0, 0))
            WITH SYSTEM_MODE
            LIMIT 40000
        ] : new List<Health_Visit__c>();
        List<Care_Activity__c> activities = needActivities ? [
            SELECT Id, Activity_Type__c, Due_Date__c, Status__c, Completed_Date__c,
                   Patient__r.AccountId, Patient__r.Village__c, Patient__r.Account.Village__c
            FROM Care_Activity__c
            WHERE Due_Date__c >= :earliest AND Due_Date__c <= :asOf
            WITH SYSTEM_MODE
            LIMIT 40000
        ] : new List<Care_Activity__c>();

        for (Surveillance_Signal__mdt s : configured) {
            Map<Id, SignalResult> byVillage = new Map<Id, SignalResult>();
            for (Village__c v : villages.values()) {
                byVillage.put(v.Id, newResult(v, s, asOf));
            }
            Integer weeks = baselineWeeks(s);
            if (s.Source__c == SOURCE_ACTIVITY) {
                Integer grace = graceDays(s);
                Date windowEnd = asOf.addDays(-grace);
                Set<String> types = splitSet(s.Activity_Types__c);
                for (Care_Activity__c a : activities) {
                    if (!types.isEmpty() && !types.contains(a.Activity_Type__c)) {
                        continue;
                    }
                    if (a.Status__c == CareRules.STATUS_CANCELLED) {
                        continue;   // approved closures (moved away, duplicate...) are not delays
                    }
                    markHistory(byVillage, villageOf(a.Patient__r), a.Due_Date__c, windowEnd, weeks);
                    Boolean late = a.Completed_Date__c == null || a.Completed_Date__c > a.Due_Date__c.addDays(grace);
                    if (!late) {
                        continue;
                    }
                    count(byVillage, villageOf(a.Patient__r), a.Patient__r.AccountId, a.Id, a.Due_Date__c, windowEnd, weeks);
                }
            } else {
                Set<String> symptoms = splitSet(s.Symptoms__c);
                Set<String> outcomes = splitSet(s.Visit_Outcomes__c);
                for (Health_Visit__c v : visits) {
                    markHistory(byVillage, villageOf(v.Patient__r), v.Visit_Date__c.date(), asOf, weeks);
                    if (!matches(v, s, symptoms, outcomes)) {
                        continue;
                    }
                    count(byVillage, villageOf(v.Patient__r), v.Patient__r.AccountId, v.Id, v.Visit_Date__c.date(), asOf, weeks);
                }
            }
            for (SignalResult r : byVillage.values()) {
                score(r, s, villages.get(r.villageId));
                results.add(r);
            }
        }
        return results;
    }

    /**
     * Evaluates and records the flagged signals. An open or dismissed signal for the same village and
     * signal from the last 7 days is updated (or, if dismissed, left alone) instead of creating a
     * new one each day, so an ongoing cluster is one investigation, not seven.
     */
    public static ScanSummary scan(Date asOf, Boolean sendNotifications) {
        ScanSummary summary = new ScanSummary();
        List<SignalResult> results = evaluate(asOf);
        summary.cellsEvaluated = results.size();
        List<SignalResult> flagged = new List<SignalResult>();
        Set<Id> villageIds = new Set<Id>();
        for (SignalResult r : results) {
            if (r.severity != NORMAL) {
                flagged.add(r);
                villageIds.add(r.villageId);
            }
        }
        summary.flagged = flagged.size();
        if (flagged.isEmpty()) {
            return summary;
        }
        Map<String, Community_Signal__c> recent = new Map<String, Community_Signal__c>();
        for (Community_Signal__c c : [
            SELECT Id, Village__c, Signal_Key__c, Status__c, Severity__c, Window_End__c
            FROM Community_Signal__c
            WHERE Village__c IN :villageIds AND Window_End__c >= :asOf.addDays(-(WINDOW_DAYS - 1))
            WITH SYSTEM_MODE
            ORDER BY Window_End__c DESC
        ]) {
            String key = c.Village__c + '|' + c.Signal_Key__c;
            if (!recent.containsKey(key)) {
                recent.put(key, c);
            }
        }
        List<Community_Signal__c> toInsert = new List<Community_Signal__c>();
        List<Community_Signal__c> toUpdate = new List<Community_Signal__c>();
        List<SignalResult> toNotify = new List<SignalResult>();
        for (SignalResult r : flagged) {
            Community_Signal__c existing = recent.get(r.villageId + '|' + r.signalKey);
            if (existing != null && SUPPRESSING_STATUSES.contains(existing.Status__c)) {
                continue;   // already reviewed (closed or dismissed) for this window
            }
            Community_Signal__c row = toRecord(r, asOf);
            if (existing == null) {
                row.Status__c = STATUS_NEW;
                toInsert.add(row);
                toNotify.add(r);
            } else {
                row.Id = existing.Id;
                if (r.severity == ALERT && existing.Severity__c != ALERT) {
                    toNotify.add(r);       // escalated from Watch to Alert
                }
                toUpdate.add(row);
            }
        }
        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, true, AccessLevel.SYSTEM_MODE);
            summary.created = toInsert.size();
        }
        if (!toUpdate.isEmpty()) {
            List<Community_Signal__c> clean = new List<Community_Signal__c>();
            for (Community_Signal__c row : toUpdate) {
                clean.add(withoutKey(row));   // keep the key, status and notes of the open investigation
            }
            Database.update(clean, true, AccessLevel.SYSTEM_MODE);
            summary.updated = clean.size();
        }
        if (sendNotifications && !toNotify.isEmpty()) {
            summary.notified = notifyReviewers(toNotify, toInsert, toUpdate);
        }
        return summary;
    }

    // ------------------------------------------------------------------ helpers

    private static SignalResult newResult(Village__c v, Surveillance_Signal__mdt s, Date asOf) {
        SignalResult r = new SignalResult();
        r.villageId = v.Id;
        r.villageName = v.Name;
        r.region = v.Region__c;
        r.signalKey = s.DeveloperName;
        r.signalLabel = s.MasterLabel;
        r.guidance = s.Guidance__c;
        Integer weeks = baselineWeeks(s);
        Integer grace = s.Source__c == SOURCE_ACTIVITY ? graceDays(s) : 0;
        r.windowEnd = asOf.addDays(-grace);
        r.windowStart = r.windowEnd.addDays(-(WINDOW_DAYS - 1));
        for (Integer i = 0; i < weeks; i++) {
            r.baselineCounts.add(0);
        }
        return r;
    }

    /** Puts one matching event into the current week (index 0) or a baseline week (1..weeks). */
    private static void count(Map<Id, SignalResult> byVillage, Id villageId, Id householdId, Id recordId,
                              Date eventDate, Date windowEnd, Integer weeks) {
        if (villageId == null || !byVillage.containsKey(villageId) || eventDate == null || eventDate > windowEnd) {
            return;
        }
        Integer week = eventDate.daysBetween(windowEnd) / WINDOW_DAYS;
        if (week > weeks) {
            return;
        }
        SignalResult r = byVillage.get(villageId);
        if (week == 0) {
            r.observed++;
            if (householdId != null) {
                r.householdIds.add(householdId);
            }
            r.evidenceIds.add(recordId);
        } else {
            r.baselineCounts[week - 1] = r.baselineCounts[week - 1] + 1;
        }
    }

    /** Remembers that the village had data in a baseline week (needed before any signal is raised). */
    private static void markHistory(Map<Id, SignalResult> byVillage, Id villageId, Date eventDate, Date windowEnd, Integer weeks) {
        if (villageId == null || !byVillage.containsKey(villageId) || eventDate == null || eventDate > windowEnd) {
            return;
        }
        Integer week = eventDate.daysBetween(windowEnd) / WINDOW_DAYS;
        if (week >= 1 && week <= weeks) {
            byVillage.get(villageId).historyWeeks.add(week);
        }
    }

    @TestVisible
    private static void score(SignalResult r, Surveillance_Signal__mdt s, Village__c village) {
        Integer n = r.baselineCounts.size();
        Decimal total = 0;
        for (Integer c : r.baselineCounts) {
            total += c;
        }
        Decimal mean = 0;
        if (n > 0) {
            mean = total / n;
        }
        Decimal sumSq = 0;
        for (Integer c : r.baselineCounts) {
            sumSq += (c - mean) * (c - mean);
        }
        Decimal sd = 0;
        if (n > 1) {
            sd = Decimal.valueOf(Math.sqrt((sumSq / (n - 1)).doubleValue()));
        }
        r.expected = mean.setScale(2);
        r.spread = Math.max(sd, MIN_SPREAD).setScale(2);
        Decimal watchZ = s.Watch_Z__c == null ? Decimal.valueOf(2) : s.Watch_Z__c;
        Decimal alertZ = s.Alert_Z__c == null ? Decimal.valueOf(3) : s.Alert_Z__c;
        Integer minCount = s.Min_Count__c == null ? 3 : s.Min_Count__c.intValue();
        r.threshold = (mean + watchZ * r.spread).setScale(2);
        r.z = ((r.observed - mean) / r.spread).setScale(2);
        r.households = r.householdIds.size();
        if (village != null && village.Population__c != null && village.Population__c > 0) {
            r.ratePer1000 = (r.observed * 1000 / village.Population__c).setScale(2);
        }
        Integer minHistory = minHistoryWeeks(s, n);
        r.insufficientHistory = r.historyWeeks.size() < minHistory;
        if (r.insufficientHistory) {
            r.severity = NORMAL;   // never compare against missing data
        } else if (r.observed >= minCount && r.z >= alertZ) {
            r.severity = ALERT;
        } else if (r.observed >= minCount && r.z >= watchZ) {
            r.severity = WATCH;
        }
        // weekly: oldest baseline week first, current week last (for the chart)
        for (Integer i = n - 1; i >= 0; i--) {
            r.weekly.add(r.baselineCounts[i]);
        }
        r.weekly.add(r.observed);
        r.explanation = r.insufficientHistory ? explainNoHistory(r, s, n, minHistory) : explain(r, s, minCount);
    }

    private static String explainNoHistory(SignalResult r, Surveillance_Signal__mdt s, Integer weeks, Integer minHistory) {
        String unit = s.Source__c == SOURCE_ACTIVITY ? 'vaccine/care doses' : 'visits';
        return r.signalLabel + ' in ' + r.villageName + ': not assessed. Only ' + r.historyWeeks.size() + ' of the previous '
            + weeks + ' weeks have any recorded ' + unit + ' (at least ' + minHistory + ' needed), so there is no reliable'
            + ' normal level to compare with. Missing data is not treated as zero cases.';
    }

    private static String explain(SignalResult r, Surveillance_Signal__mdt s, Integer minCount) {
        String what = s.Source__c == SOURCE_ACTIVITY
            ? 'vaccine/care doses due ' + fmt(r.windowStart) + ' - ' + fmt(r.windowEnd) + ' not given within '
                + graceDays(s) + ' days'
            : 'visits ' + fmt(r.windowStart) + ' - ' + fmt(r.windowEnd);
        List<String> baseline = new List<String>();
        for (Integer i = 0; i < r.weekly.size() - 1; i++) {
            baseline.add(String.valueOf(r.weekly[i]));
        }
        String text = r.signalLabel + ' in ' + r.villageName + ': ' + r.observed + ' ' + what
            + (r.households > 0 ? ', from ' + r.households + ' household(s)' : '')
            + '. Normal for this village: ' + r.expected.setScale(1) + ' per week (previous weeks: '
            + String.join(baseline, ', ') + '). That is ' + r.z.setScale(1) + ' standard deviations above normal'
            + ' (watch level ' + r.threshold.setScale(1) + ', minimum ' + minCount + ' events).';
        if (r.ratePer1000 != null) {
            text += ' Rate: ' + r.ratePer1000 + ' per 1,000 people.';
        }
        return text;
    }

    private static Boolean matches(Health_Visit__c v, Surveillance_Signal__mdt s, Set<String> symptoms, Set<String> outcomes) {
        if (!outcomes.isEmpty()) {
            return outcomes.contains(v.Visit_Outcome__c);
        }
        if (!symptoms.isEmpty() && v.Symptoms__c != null) {
            for (String recorded : v.Symptoms__c.split(';')) {
                if (symptoms.contains(recorded.trim())) {
                    return true;
                }
            }
        }
        if (s.Min_Temperature__c != null && v.Temperature__c != null && v.Temperature__c >= s.Min_Temperature__c) {
            return true;
        }
        if (s.Max_SpO2__c != null && v.SpO2__c != null && v.SpO2__c < s.Max_SpO2__c) {
            return true;
        }
        return false;
    }

    private static Id villageOf(Contact patient) {
        if (patient == null) {
            return null;
        }
        if (patient.Village__c != null) {
            return patient.Village__c;
        }
        return patient.Account == null ? null : patient.Account.Village__c;
    }

    private static Community_Signal__c toRecord(SignalResult r, Date asOf) {
        List<String> weekly = new List<String>();
        for (Integer c : r.weekly) {
            weekly.add(String.valueOf(c));
        }
        return new Community_Signal__c(
            Name = (r.signalLabel + ' - ' + r.villageName).left(80),
            Village__c = r.villageId,
            Signal_Key__c = r.signalKey,
            Signal_Label__c = r.signalLabel,
            Window_Start__c = r.windowStart,
            Window_End__c = r.windowEnd,
            Observed__c = r.observed,
            Expected__c = r.expected,
            Std_Dev__c = r.spread,
            Threshold__c = r.threshold,
            Z_Score__c = r.z,
            Households__c = r.households,
            Rate_Per_1000__c = r.ratePer1000,
            Severity__c = r.severity,
            Explanation__c = r.explanation.left(2000),
            Guidance__c = r.guidance == null ? null : r.guidance.left(255),
            Weekly_Counts__c = String.join(weekly, ',').left(120),
            Evidence_Ids__c = String.join(r.evidenceIds, ',').left(10000),
            Last_Scanned_On__c = System.now(),
            Alert_Key__c = (r.villageId + '-' + r.signalKey + '-'
                + Datetime.newInstance(asOf, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd')).left(120)
        );
    }

    private static Community_Signal__c withoutKey(Community_Signal__c row) {
        Community_Signal__c u = new Community_Signal__c(Id = row.Id);
        for (String field : new List<String>{ 'Name', 'Window_Start__c', 'Window_End__c', 'Observed__c', 'Expected__c',
                'Std_Dev__c', 'Threshold__c', 'Z_Score__c', 'Households__c', 'Rate_Per_1000__c', 'Severity__c',
                'Explanation__c', 'Guidance__c', 'Weekly_Counts__c', 'Evidence_Ids__c', 'Last_Scanned_On__c' }) {
            u.put(field, row.get(field));
        }
        return u;
    }

    private static Integer notifyReviewers(List<SignalResult> toNotify, List<Community_Signal__c> inserted,
                                           List<Community_Signal__c> updated) {
        Set<Id> reviewers = CareLoopAlertService.doctors();
        for (PermissionSetAssignment a : [
            SELECT AssigneeId FROM PermissionSetAssignment
            WHERE PermissionSet.Name = :MANAGER_PERMISSION_SET AND Assignee.IsActive = true
            WITH SYSTEM_MODE
        ]) {
            reviewers.add(a.AssigneeId);
        }
        Map<String, Id> recordByKey = new Map<String, Id>();
        for (Community_Signal__c c : inserted) {
            recordByKey.put(c.Village__c + '|' + c.Signal_Key__c, c.Id);
        }
        for (Community_Signal__c c : updated) {
            recordByKey.put(c.Village__c + '|' + c.Signal_Key__c, c.Id);
        }
        Integer sent = 0;
        for (SignalResult r : toNotify) {
            Id target = recordByKey.get(r.villageId + '|' + r.signalKey);
            Boolean ok = CareLoopAlertService.notify(reviewers,
                'Community ' + r.severity.toLowerCase() + ': ' + r.signalLabel + ' in ' + r.villageName,
                r.explanation, target);
            sent += ok ? 1 : 0;
        }
        return sent;
    }

    private static Integer baselineWeeks(Surveillance_Signal__mdt s) {
        return (s.Baseline_Weeks__c == null || s.Baseline_Weeks__c < 2) ? 4 : s.Baseline_Weeks__c.intValue();
    }

    private static Integer minHistoryWeeks(Surveillance_Signal__mdt s, Integer baselineWeeks) {
        Integer configured = s.Min_History_Weeks__c == null ? DEFAULT_MIN_HISTORY_WEEKS : s.Min_History_Weeks__c.intValue();
        return Math.min(Math.max(configured, 1), baselineWeeks);
    }

    private static Integer graceDays(Surveillance_Signal__mdt s) {
        return s.Grace_Days__c == null ? 7 : s.Grace_Days__c.intValue();
    }

    private static Set<String> splitSet(String text) {
        Set<String> out = new Set<String>();
        if (String.isBlank(text)) {
            return out;
        }
        for (String part : text.split(';')) {
            if (String.isNotBlank(part)) {
                out.add(part.trim());
            }
        }
        return out;
    }

    private static String fmt(Date d) {
        return d == null ? '' : Datetime.newInstance(d, Time.newInstance(9, 0, 0, 0)).format('d MMM');
    }
}
```

## `force-app/main/default/classes/SentinelService.cls-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

## `force-app/main/default/classes/SentinelServiceTest.cls` — NEW

```java
@IsTest
private class SentinelServiceTest {

    // ------------------------------------------------------------------ fixtures

    /** A signal definition built in memory (custom metadata cannot be inserted in tests). */
    private static Surveillance_Signal__mdt signal(String name, Map<String, Object> overrides) {
        Map<String, Object> f = new Map<String, Object>{
            'DeveloperName' => name, 'MasterLabel' => name.replace('_', ' '), 'Active__c' => true, 'Source__c' => 'Health Visit',
            'Grace_Days__c' => 7, 'Min_Count__c' => 3, 'Watch_Z__c' => 2, 'Alert_Z__c' => 3, 'Baseline_Weeks__c' => 4,
            'Min_History_Weeks__c' => 2, 'Guidance__c' => 'Verify with the health worker.'
        };
        f.putAll(overrides);
        return (Surveillance_Signal__mdt) JSON.deserialize(JSON.serialize(f), Surveillance_Signal__mdt.class);
    }

    /** The four shipped signals, defined in the test so the tests do not depend on org configuration. */
    private static void useSignals() {
        SentinelService.signalOverride = new List<Surveillance_Signal__mdt>{
            signal('Fever_Cluster', new Map<String, Object>{ 'Symptoms__c' => 'Fever', 'Min_Temperature__c' => 38.0 }),
            signal('Respiratory_Cluster', new Map<String, Object>{ 'Symptoms__c' => 'Cough;Breathlessness', 'Max_SpO2__c' => 94 }),
            signal('Failed_Visit_Surge', new Map<String, Object>{
                'Visit_Outcomes__c' => 'Patient Not Available;Patient Refused', 'Min_Count__c' => 4 }),
            signal('Immunisation_Delay', new Map<String, Object>{ 'Source__c' => 'Care Activity', 'Activity_Types__c' => 'Immunization' })
        };
    }

    /** A village (population 2000) with n households of one patient each. */
    private static List<Contact> village(String name, Integer households) {
        Village__c v = new Village__c(Name = name, Region__c = 'North', District__c = 'D', State__c = 'Telangana', Population__c = 2000);
        insert v;
        List<Account> hh = new List<Account>();
        for (Integer i = 0; i < households; i++) {
            hh.add(new Account(Name = name + ' household ' + i, Village__c = v.Id));
        }
        insert hh;
        TriggerHandler.bypass('ContactTriggerHandler');
        List<Contact> people = new List<Contact>();
        for (Account a : hh) {
            people.add(CareLoopTestFactory.newPatient(a.Id, v.Id, Date.today().addYears(-30)));
        }
        insert people;
        TriggerHandler.clearBypass('ContactTriggerHandler');
        return people;
    }

    private static Datetime daysAgo(Integer days) {
        return Datetime.newInstance(Date.today().addDays(-days), Time.newInstance(0, 5, 0, 0));
    }

    private static Health_Visit__c fever(Id patientId, Integer days) {
        return new Health_Visit__c(Patient__c = patientId, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Completed',
            Visit_Date__c = daysAgo(days), Symptoms__c = 'Fever;Headache', Temperature__c = 38.6);
    }

    private static Health_Visit__c routine(Id patientId, Integer days) {
        return new Health_Visit__c(Patient__c = patientId, Visit_Type__c = 'Routine Check-up', Visit_Outcome__c = 'Completed',
            Visit_Date__c = daysAgo(days));
    }

    private static Health_Visit__c notReached(Id patientId, Integer days) {
        return new Health_Visit__c(Patient__c = patientId, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Patient Not Available',
            Visit_Date__c = daysAgo(days));
    }

    /** One ordinary visit in each of the 5 previous weeks, so the village has a history to compare with. */
    private static List<Health_Visit__c> history(Id patientId) {
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer week = 1; week <= 5; week++) {
            visits.add(routine(patientId, week * 7 + 3));
        }
        return visits;
    }

    private static SentinelService.SignalResult find(Date asOf, String villageName, String signalKey) {
        for (SentinelService.SignalResult r : SentinelService.evaluate(asOf)) {
            if (r.villageName == villageName && r.signalKey == signalKey) {
                return r;
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ the four signals

    @IsTest
    static void feverSpikeIsAnAlertWithExplanation() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Spike Village', 5);
        List<Health_Visit__c> visits = new List<Health_Visit__c>{
            fever(people[0].Id, 10), fever(people[1].Id, 17), fever(people[2].Id, 30)   // baseline weeks: 1,1,0,1
        };
        for (Integer i = 0; i < 6; i++) {
            visits.add(fever(people[Math.mod(i, 4)].Id, Math.mod(i, 5)));                 // this week: 6 from 4 households
        }
        insert visits;

        SentinelService.SignalResult r = find(Date.today(), 'Spike Village', 'Fever_Cluster');
        Assert.areEqual(6, r.observed);
        Assert.areEqual(4, r.households);
        Assert.areEqual('Alert', r.severity, r.explanation);
        Assert.isFalse(r.insufficientHistory);
        Assert.isTrue(r.expected == 0.75, 'baseline 1,1,0,1 -> mean 0.75: ' + r.expected);
        Assert.areEqual(5, r.weekly.size());
        Assert.areEqual(6, r.weekly[4], 'current week last');
        Assert.isTrue(r.explanation.contains('from 4 household(s)'), r.explanation);
        Assert.isTrue(r.ratePer1000 == 3, 'six per 2,000 people');
        Assert.areEqual(6, r.evidenceIds.size());
    }

    @IsTest
    static void respiratoryClusterCountsCoughBreathlessnessOrLowSpO2() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Cough Village', 6);
        List<Health_Visit__c> visits = history(people[5].Id);
        visits.add(new Health_Visit__c(Patient__c = people[0].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(1), Symptoms__c = 'Cough'));
        visits.add(new Health_Visit__c(Patient__c = people[1].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(2), Symptoms__c = 'Cough;Fever'));
        visits.add(new Health_Visit__c(Patient__c = people[2].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(3), Symptoms__c = 'Breathlessness'));
        visits.add(new Health_Visit__c(Patient__c = people[3].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(4), SpO2__c = 93));
        // not respiratory: normal SpO2 and an unrelated symptom
        visits.add(new Health_Visit__c(Patient__c = people[4].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(1), SpO2__c = 97));
        visits.add(new Health_Visit__c(Patient__c = people[4].Id, Visit_Type__c = 'Home Visit', Visit_Date__c = daysAgo(2), Symptoms__c = 'Headache'));
        insert visits;

        SentinelService.SignalResult r = find(Date.today(), 'Cough Village', 'Respiratory_Cluster');
        Assert.areEqual(4, r.observed, 'cough, cough+fever, breathlessness and SpO2 93 count; SpO2 97 and headache do not');
        Assert.areEqual('Alert', r.severity, r.explanation);
        Assert.areEqual(4, r.households);
    }

    @IsTest
    static void unreachableHouseholdsNeedAtLeastFourVisits() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> three = village('Three Missed', 4);
        List<Contact> five = village('Five Missed', 6);
        List<Health_Visit__c> visits = history(three[3].Id);
        visits.addAll(history(five[5].Id));
        for (Integer i = 0; i < 3; i++) {
            visits.add(notReached(three[i].Id, i));
        }
        for (Integer i = 0; i < 5; i++) {
            visits.add(notReached(five[i].Id, i));
        }
        visits.add(new Health_Visit__c(Patient__c = five[0].Id, Visit_Type__c = 'Home Visit', Visit_Outcome__c = 'Patient Refused',
            Visit_Date__c = daysAgo(5)));
        insert visits;

        SentinelService.SignalResult small = find(Date.today(), 'Three Missed', 'Failed_Visit_Surge');
        Assert.areEqual(3, small.observed);
        Assert.areEqual('Normal', small.severity, 'below the minimum of 4: ' + small.explanation);
        SentinelService.SignalResult surge = find(Date.today(), 'Five Missed', 'Failed_Visit_Surge');
        Assert.areEqual(6, surge.observed, '"Patient Not Available" and "Patient Refused" both count');
        Assert.areEqual('Alert', surge.severity, surge.explanation);
    }

    @IsTest
    static void delayedVaccineDosesAreDetectedButGraceCancelledAndOnTimeAreNot() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Vaccine Village', 4);
        List<Care_Activity__c> doses = new List<Care_Activity__c>();
        // baseline weeks (due 15-36 days ago): given on time -> history, but not delays
        for (Integer i = 0; i < 4; i++) {
            Date due = Date.today().addDays(-15 - i * 7);
            doses.add(new Care_Activity__c(Name = 'On time ' + i, Patient__c = people[i].Id, Activity_Type__c = 'Immunization',
                Due_Date__c = due, Status__c = 'Completed', Completed_Date__c = due.addDays(2)));
        }
        // assessed window (due 8-13 days ago): five doses not given
        for (Integer i = 0; i < 5; i++) {
            doses.add(new Care_Activity__c(Name = 'Delayed ' + i, Patient__c = people[Math.mod(i, 4)].Id,
                Activity_Type__c = 'Immunization', Due_Date__c = Date.today().addDays(-8 - i)));
        }
        // not counted: still inside the 7-day grace period, given within grace, approved cancellation, other type
        doses.add(new Care_Activity__c(Name = 'In grace', Patient__c = people[0].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = Date.today().addDays(-3)));
        doses.add(new Care_Activity__c(Name = 'Given in grace', Patient__c = people[1].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = Date.today().addDays(-9), Status__c = 'Completed', Completed_Date__c = Date.today().addDays(-4)));
        doses.add(new Care_Activity__c(Name = 'Moved away', Patient__c = people[2].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = Date.today().addDays(-10), Status__c = 'Cancelled', Approval_Status__c = 'Approved',
            Closure_Reason__c = 'Moved Away'));
        doses.add(new Care_Activity__c(Name = 'Check-up', Patient__c = people[3].Id, Activity_Type__c = 'Routine Check-up',
            Due_Date__c = Date.today().addDays(-11)));
        insert doses;

        SentinelService.SignalResult r = find(Date.today(), 'Vaccine Village', 'Immunisation_Delay');
        Assert.areEqual(5, r.observed, r.explanation);
        Assert.areEqual('Alert', r.severity, r.explanation);
        Assert.isTrue(r.explanation.contains('not given within 7 days'), r.explanation);
        Assert.areEqual(Date.today().addDays(-7), r.windowEnd, 'vaccine window ends after the grace period');
    }

    // ------------------------------------------------------------------ safeguards against false alarms

    @IsTest
    static void steadyOrTinyCountsAreNotFlagged() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> steady = village('Steady Village', 3);
        List<Contact> tiny = village('Tiny Village', 3);
        List<Health_Visit__c> visits = history(tiny[2].Id);
        for (Integer week = 0; week <= 4; week++) {
            visits.add(fever(steady[0].Id, week * 7 + 1));
            visits.add(fever(steady[1].Id, week * 7 + 2));
        }
        visits.add(fever(tiny[0].Id, 1));
        visits.add(fever(tiny[1].Id, 2));   // 2 this week, 0 before: unusual, but below the minimum of 3
        insert visits;
        for (SentinelService.SignalResult r : SentinelService.evaluate(Date.today())) {
            Assert.areEqual('Normal', r.severity, r.villageName + ' ' + r.signalKey + ': ' + r.explanation);
        }
        SentinelService.SignalResult steadyFever = find(Date.today(), 'Steady Village', 'Fever_Cluster');
        Assert.isTrue(steadyFever.expected == 2 && steadyFever.z == 0, steadyFever.explanation);
        Assert.areEqual(0, SentinelService.scan(Date.today(), false).flagged);
        Assert.areEqual(0, [SELECT COUNT() FROM Community_Signal__c]);
    }

    @IsTest
    static void villagesWithoutEnoughHistoryAreNotAssessed() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> fresh = village('New Village', 6);
        List<Contact> oneWeek = village('One Week Village', 6);
        List<Health_Visit__c> visits = new List<Health_Visit__c>{ routine(oneWeek[5].Id, 10) };   // history in 1 week only
        for (Integer i = 0; i < 6; i++) {
            visits.add(fever(fresh[i].Id, Math.mod(i, 5)));
            visits.add(fever(oneWeek[i].Id, Math.mod(i, 5)));
        }
        insert visits;

        for (String name : new List<String>{ 'New Village', 'One Week Village' }) {
            SentinelService.SignalResult r = find(Date.today(), name, 'Fever_Cluster');
            Assert.areEqual(6, r.observed);
            Assert.isTrue(r.insufficientHistory, name);
            Assert.areEqual('Normal', r.severity, 'six cases with no history is not compared with "zero": ' + r.explanation);
            Assert.isTrue(r.explanation.contains('not assessed'), r.explanation);
        }
        Assert.areEqual(0, SentinelService.scan(Date.today(), false).flagged);
    }

    @IsTest
    static void thresholdsDecideWatchAndAlertAndAreConfigurable() {
        Surveillance_Signal__mdt standard = signal('Fever_Cluster', new Map<String, Object>());
        Surveillance_Signal__mdt strict = signal('Fever_Cluster', new Map<String, Object>{ 'Alert_Z__c' => 5 });

        SentinelService.SignalResult watch = scored(new List<Integer>{ 2, 3, 2, 3 }, 5, standard);
        Assert.areEqual('Watch', watch.severity, watch.explanation);   // mean 2.5, spread 1 -> z 2.5
        Assert.isTrue(watch.z == 2.5 && watch.threshold == 4.5, watch.explanation);

        Assert.areEqual('Alert', scored(new List<Integer>{ 2, 3, 2, 3 }, 6, standard).severity);   // z 3.5
        Assert.areEqual('Watch', scored(new List<Integer>{ 2, 3, 2, 3 }, 6, strict).severity, 'Alert_Z 5 from custom metadata');
        Assert.areEqual('Normal', scored(new List<Integer>{ 2, 3, 2, 3 }, 4, standard).severity);  // z 1.5

        SentinelService.SignalResult flat = scored(new List<Integer>{ 0, 0, 0, 0 }, 2, standard);
        Assert.areEqual('Normal', flat.severity, 'spread floor 1 and minimum 3 stop 0 -> 2 from alerting');
        Assert.isTrue(flat.spread == 1);

        SentinelService.SignalResult noisy = scored(new List<Integer>{ 0, 10, 0, 10 }, 12, standard);
        Assert.areEqual('Normal', noisy.severity, 'a village that is always up and down needs a bigger jump: ' + noisy.explanation);
    }

    private static SentinelService.SignalResult scored(List<Integer> baseline, Integer observed, Surveillance_Signal__mdt s) {
        SentinelService.SignalResult r = new SentinelService.SignalResult();
        r.villageName = 'Unit Village';
        r.signalKey = s.DeveloperName;
        r.signalLabel = s.MasterLabel;
        r.baselineCounts = baseline;
        r.historyWeeks = new Set<Integer>{ 1, 2, 3, 4 };
        r.observed = observed;
        SentinelService.score(r, s, null);
        return r;
    }

    // ------------------------------------------------------------------ recording, duplicates, review statuses

    @IsTest
    static void scanRecordsOnceKeepsStatusAndRespectsDismissal() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Failed Village', 7);
        List<Health_Visit__c> visits = history(people[6].Id);
        for (Integer i = 0; i < 6; i++) {
            visits.add(notReached(people[i].Id, i));
        }
        insert visits;

        SentinelService.ScanSummary first = SentinelService.scan(Date.today(), false);
        Assert.areEqual(1, first.created);
        Community_Signal__c signal = [SELECT Id, Status__c, Severity__c, Observed__c, Evidence_Ids__c, Alert_Key__c, Region__c,
                                      Explanation__c FROM Community_Signal__c];
        Assert.areEqual('New', signal.Status__c);
        Assert.isTrue(signal.Observed__c == 6);
        Assert.areEqual('North', signal.Region__c);
        Assert.areEqual(6, signal.Evidence_Ids__c.split(',').size());
        Assert.isFalse(signal.Explanation__c.contains(people[0].LastName), 'explanations never name a patient');

        update new Community_Signal__c(Id = signal.Id, Status__c = 'Investigating');
        SentinelService.ScanSummary second = SentinelService.scan(Date.today(), false);
        Assert.areEqual(0, second.created, 'same investigation, no duplicate');
        Assert.areEqual(1, second.updated);
        Assert.areEqual('Investigating', [SELECT Status__c FROM Community_Signal__c WHERE Id = :signal.Id].Status__c);

        update new Community_Signal__c(Id = signal.Id, Status__c = 'Dismissed');
        CareLoopClock.testToday = Date.today().addDays(1);
        SentinelService.ScanSummary third = SentinelService.scan(CareLoopClock.today(), false);
        Assert.areEqual(0, third.created + third.updated, 'a dismissed signal is not raised again during its week');
        Assert.areEqual(1, [SELECT COUNT() FROM Community_Signal__c]);
    }

    @IsTest
    static void closedSignalIsSuppressedThatWeekButANewClusterLaterIsRaised() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        List<Contact> people = village('Closed Village', 10);
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        for (Integer week = 0; week <= 6; week++) {
            visits.add(routine(people[9].Id, week * 7 + 3));
        }
        for (Integer i = 0; i < 5; i++) {
            visits.add(fever(people[i].Id, 14 + i));       // first cluster: 14-18 days ago
        }
        for (Integer i = 0; i < 9; i++) {
            visits.add(fever(people[i].Id, Math.mod(i, 5))); // second, bigger cluster: this week
        }
        insert visits;
        Date earlier = Date.today().addDays(-14);

        Assert.areEqual(1, SentinelService.scan(earlier, false).created, 'first cluster raised');
        Community_Signal__c first = [SELECT Id FROM Community_Signal__c];
        update new Community_Signal__c(Id = first.Id, Status__c = 'Closed', Investigation_Notes__c = 'Handled by PHC');
        SentinelService.ScanSummary nextDay = SentinelService.scan(earlier.addDays(1), false);
        Assert.areEqual(0, nextDay.created + nextDay.updated, 'closed signals are not re-raised in the same window');

        SentinelService.ScanSummary later = SentinelService.scan(Date.today(), false);
        Assert.areEqual(1, later.created, 'a new cluster two weeks later is a new signal');
        Assert.areEqual(2, [SELECT COUNT() FROM Community_Signal__c]);
        Assert.areEqual('Closed', [SELECT Status__c FROM Community_Signal__c WHERE Id = :first.Id].Status__c);
    }

    // ------------------------------------------------------------------ notifications

    @IsTest
    static void managersAreNotifiedForNewSignalsAndEscalationsOnly() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        User manager = CareLoopPhase4TestData.newUser('snm');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert manager;
            insert new PermissionSetAssignment(AssigneeId = manager.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :SentinelService.MANAGER_PERMISSION_SET].Id);
        }
        List<Contact> people = village('Bell Village', 8);
        List<Health_Visit__c> visits = new List<Health_Visit__c>();
        // baseline of missed visits per week 1,2,1,2 (mean 1.5, spread 1) plus routine history
        List<Integer> baseline = new List<Integer>{ 1, 2, 1, 2 };
        for (Integer week = 1; week <= 4; week++) {
            visits.add(routine(people[7].Id, week * 7 + 1));
            for (Integer k = 0; k < baseline[week - 1]; k++) {
                visits.add(notReached(people[k].Id, week * 7 + 2 + k));
            }
        }
        for (Integer i = 0; i < 4; i++) {
            visits.add(notReached(people[i].Id, i));   // this week 4 -> z 2.5 -> Watch
        }
        insert visits;

        Integer bellsBefore = CareLoopAlertService.bellsSent;
        SentinelService.ScanSummary first = SentinelService.scan(Date.today(), true);
        Assert.areEqual(1, first.created);
        Assert.areEqual('Watch', [SELECT Severity__c FROM Community_Signal__c].Severity__c);
        Assert.areEqual(1, first.notified, 'new signal -> one notification');
        Assert.areEqual(bellsBefore + 1, CareLoopAlertService.bellsSent);

        SentinelService.ScanSummary repeat = SentinelService.scan(Date.today(), true);
        Assert.areEqual(0, repeat.notified, 'no new bell when nothing changed');

        insert notReached(people[4].Id, 1);              // this week 5 -> z 3.5 -> Alert
        SentinelService.ScanSummary escalated = SentinelService.scan(Date.today(), true);
        Assert.areEqual(1, escalated.updated);
        Assert.areEqual(1, escalated.notified, 'Watch -> Alert notifies again');
        Assert.areEqual('Alert', [SELECT Severity__c FROM Community_Signal__c].Severity__c);
    }

    // ------------------------------------------------------------------ scheduling

    @IsTest
    static void dailyJobSchedulesOnceAndRuns() {
        CareLoopTestFactory.useRealToday();
        useSignals();
        Test.startTest();
        Id first = SentinelJob.scheduleDaily();
        Assert.areEqual(first, SentinelJob.scheduleDaily());
        new SentinelJob().execute(null);
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM Error_Log__c]);
        Assert.isFalse(SentinelService.signals().isEmpty());
    }
}
```

## `force-app/main/default/classes/SentinelServiceTest.cls-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

## `force-app/main/default/lwc/communityWatch/communityWatch.css` — NEW

```css
.actions { display: flex; gap: 0.5rem; align-items: center; }
.intro { font-size: 0.8rem; color: #5b6476; margin-bottom: 0.6rem; }
.legend { display: inline-block; padding: 0 0.4rem; border-radius: 0.6rem; font-size: 0.7rem; font-weight: 700; }
.legend.alert { background: #ba0517; color: #fff; }
.legend.watch { background: #fe9339; color: #fff; }
.legend.normal { background: #e5f4ea; color: #1e7b3c; }
.legend.nohistory { background: #f3f3f3; color: #706e6b; }
.grid-wrap { overflow-x: auto; margin-bottom: 1rem; }
.grid { border-collapse: separate; border-spacing: 3px; width: 100%; }
.grid th { font-size: 0.72rem; color: #5b6476; text-align: center; padding: 0.2rem; }
.grid th:first-child { text-align: left; }
.village { font-weight: 600; white-space: nowrap; padding-right: 0.5rem; }
.region { display: block; font-size: 0.65rem; color: #8a93a3; font-weight: 400; }
.cell { text-align: center; border-radius: 0.3rem; padding: 0.35rem 0.25rem; min-width: 6rem; }
.cell.normal { background: #f1f8f3; color: #1e5e33; }
.cell.watch { background: #fff1e0; color: #8a4a00; }
.cell.alert { background: #ba0517; color: #fff; }
.cell.nohistory { background: #f3f3f3; color: #706e6b; font-style: italic; }
.count { display: block; font-size: 1.1rem; font-weight: 700; }
.sub { font-size: 0.65rem; opacity: 0.85; }
.section { font-weight: 700; margin: 0.5rem 0; }
.signal { border: 1px solid #d9dee7; border-radius: 0.35rem; padding: 0.6rem 0.75rem; margin-bottom: 0.6rem; }
.signal-head { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }
.badge { font-size: 0.65rem; font-weight: 700; padding: 0.1rem 0.5rem; border-radius: 0.6rem; color: #fff; }
.badge.alert { background: #ba0517; }
.badge.watch { background: #fe9339; }
.status { margin-left: auto; font-size: 0.7rem; font-weight: 700; padding: 0.1rem 0.5rem; border-radius: 0.6rem; background: #eef0f3; }
.s-new { background: #e4edf9; color: #1f5aa6; }
.s-investigating { background: #fdf0d5; color: #8a5a00; }
.s-closed { background: #e6f4ea; color: #1e5e33; }
.s-dismissed { background: #eef0f3; color: #5b6476; }
.signal-body { display: flex; gap: 1rem; align-items: flex-end; margin: 0.4rem 0; flex-wrap: wrap; }
.chart { display: flex; gap: 4px; align-items: flex-end; min-height: 64px; }
.bar-wrap { display: flex; flex-direction: column; align-items: center; font-size: 0.65rem; color: #5b6476; }
.bar { width: 14px; background: #a9b4c4; border-radius: 2px 2px 0 0; }
.bar.current { background: #ba0517; }
.explain { flex: 1; min-width: 240px; font-size: 0.82rem; }
.guidance { color: #3e3e3c; margin-top: 0.25rem; }
.details { border-top: 1px solid #eef0f3; margin-top: 0.4rem; padding-top: 0.4rem; }
.notes { white-space: pre-wrap; font-size: 0.75rem; background: #f6f7f9; padding: 0.4rem; border-radius: 0.25rem; }
.evidence { font-size: 0.8rem; margin: 0.25rem 0 0.5rem; }
.buttons { display: flex; gap: 0.4rem; margin-top: 0.4rem; }
.muted { color: #706e6b; font-size: 0.78rem; }
```

## `force-app/main/default/lwc/communityWatch/communityWatch.html` — NEW

```html
<template>
    <lightning-card title="Community Watch" icon-name="standard:incident">
        <div slot="actions" class="actions">
            <lightning-button-icon icon-name="utility:refresh" alternative-text="Refresh" onclick={load}></lightning-button-icon>
            <template lwc:if={overview}>
                <template lwc:if={overview.canRunScan}>
                    <lightning-button variant="brand" label="Run scan now" onclick={handleScan}></lightning-button>
                </template>
            </template>
        </div>
        <div class="slds-p-horizontal_medium">
            <template lwc:if={loading}><lightning-spinner alternative-text="Loading" size="small"></lightning-spinner></template>
            <template lwc:if={error}><p class="slds-text-color_error">{error}</p></template>
            <p class="intro">
                Each cell compares this week's count with the same village's previous four weeks.
                <span class="legend alert">Alert</span> <span class="legend watch">Watch</span> <span class="legend normal">Normal</span>
                <span class="legend nohistory">No history yet</span>
                Signals flag unusual change for a person to verify. They are not diagnoses.
            </p>
            <template lwc:if={overview}>
                <div class="grid-wrap">
                    <table class="grid">
                        <thead>
                            <tr>
                                <th>Village</th>
                                <template for:each={headers} for:item="h"><th key={h.key}>{h.label}</th></template>
                            </tr>
                        </thead>
                        <tbody>
                            <template for:each={rows} for:item="row">
                                <tr key={row.villageId}>
                                    <td class="village">{row.villageName}<span class="region">{row.region}</span></td>
                                    <template for:each={row.cellRows} for:item="c">
                                        <td key={c.key} class={c.cls} title={c.title}>
                                            <span class="count">{c.text}</span><span class="sub">{c.sub}</span>
                                        </td>
                                    </template>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>

                <h3 class="section">Signals under investigation ({openCount} open)</h3>
                <template lwc:if={hasSignals}>
                    <template for:each={signals} for:item="s">
                        <div key={s.Id} class="signal">
                            <div class="signal-head">
                                <span class={s.badgeClass}>{s.Severity__c}</span>
                                <strong>{s.Signal_Label__c}</strong> · {s.village}
                                <span class={s.statusClass}>{s.Status__c}</span>
                            </div>
                            <div class="signal-body">
                                <div class="chart" title="Weekly counts: previous weeks, then this week">
                                    <template for:each={s.bars} for:item="b">
                                        <div key={b.key} class="bar-wrap"><div class={b.cls} style={b.style}></div><span>{b.label}</span></div>
                                    </template>
                                </div>
                                <div class="explain">
                                    <p>{s.Explanation__c}</p>
                                    <p class="guidance"><strong>Suggested verification:</strong> {s.Guidance__c}</p>
                                </div>
                            </div>
                            <lightning-button variant="base" label="Details and review" data-id={s.Id} onclick={toggleDetails}></lightning-button>
                            <template lwc:if={s.isOpen}>
                                <div class="details">
                                    <template lwc:if={s.Investigation_Notes__c}>
                                        <pre class="notes">{s.Investigation_Notes__c}</pre>
                                    </template>
                                    <p class="muted">Contributing records you are allowed to see:</p>
                                    <template lwc:if={hasEvidence}>
                                        <ul class="evidence">
                                            <template for:each={evidence} for:item="e">
                                                <li key={e.key}><a data-id={e.recordId} onclick={openRecord}>{e.title}</a> · {e.eventDate} · {e.detail}</li>
                                            </template>
                                        </ul>
                                    </template>
                                    <template lwc:else><p class="muted">None visible to you (other regions' patients stay private).</p></template>
                                    <template lwc:if={overview.canReview}>
                                        <lightning-textarea label="What did you find?" value={notes} onchange={handleNotes}></lightning-textarea>
                                        <div class="buttons">
                                            <lightning-button label="Acknowledge (Investigating)" data-status="Investigating" onclick={setStatus}></lightning-button>
                                            <lightning-button label="Close (follow-up done)" variant="brand" data-status="Closed" onclick={setStatus}></lightning-button>
                                            <lightning-button label="Dismiss (not a real increase)" data-status="Dismissed" onclick={setStatus}></lightning-button>
                                        </div>
                                    </template>
                                </div>
                            </template>
                        </div>
                    </template>
                </template>
                <template lwc:else><p class="muted">No unusual signals recorded.</p></template>
            </template>
        </div>
    </lightning-card>
</template>
```

## `force-app/main/default/lwc/communityWatch/communityWatch.js` — NEW

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOverview from '@salesforce/apex/CommunityWatchController.getOverview';
import runScan from '@salesforce/apex/CommunityWatchController.runScan';
import updateStatus from '@salesforce/apex/CommunityWatchController.updateStatus';
import getEvidence from '@salesforce/apex/CommunityWatchController.getEvidence';

const SEVERITY_CLASS = { Alert: 'cell alert', Watch: 'cell watch', Normal: 'cell normal' };

export default class CommunityWatch extends NavigationMixin(LightningElement) {
    overview;
    error;
    loading = true;
    openSignalId;
    evidence = [];
    notes = '';

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        try {
            this.overview = await getOverview();
            this.error = undefined;
        } catch (e) {
            this.error = e?.body?.message || 'Could not load Community Watch.';
        } finally {
            this.loading = false;
        }
    }

    get headers() {
        return (this.overview?.signalLabels || []).map((label, i) => ({ key: `h${i}`, label }));
    }

    get rows() {
        return (this.overview?.rows || []).map((row) => ({
            ...row,
            cellRows: row.cells.map((c, i) => ({
                key: `${row.villageId}-${i}`,
                cls: c.insufficientHistory ? 'cell nohistory' : SEVERITY_CLASS[c.severity] || 'cell normal',
                text: `${c.observed}`,
                sub: c.insufficientHistory ? 'no history yet' : `normal ${Number(c.expected).toFixed(1)}`,
                title: c.explanation
            }))
        }));
    }

    get signals() {
        return (this.overview?.signals || []).map((s) => {
            const weekly = (s.Weekly_Counts__c || '').split(',').filter((x) => x !== '').map((x) => Number(x));
            const max = Math.max(1, ...weekly);
            return {
                ...s,
                village: s.Village__r ? s.Village__r.Name : '',
                badgeClass: s.Severity__c === 'Alert' ? 'badge alert' : 'badge watch',
                statusClass: `status s-${(s.Status__c || '').toLowerCase()}`,
                isOpen: this.openSignalId === s.Id,
                isClosed: s.Status__c === 'Closed' || s.Status__c === 'Dismissed',
                bars: weekly.map((count, i) => ({
                    key: `${s.Id}-b${i}`,
                    style: `height:${Math.round((count / max) * 48) + 4}px`,
                    cls: i === weekly.length - 1 ? 'bar current' : 'bar',
                    label: `${count}`
                }))
            };
        });
    }

    get hasSignals() {
        return this.signals.length > 0;
    }

    get openCount() {
        return this.signals.filter((s) => !s.isClosed).length;
    }

    async handleScan() {
        this.loading = true;
        try {
            const summary = await runScan();
            this.toast('Scan complete',
                `${summary.cellsEvaluated} village-signals checked · ${summary.flagged} flagged · ${summary.created} new · ${summary.updated} updated`,
                'success');
            await this.load();
        } catch (e) {
            this.toast('Scan failed', e?.body?.message || '', 'error');
        } finally {
            this.loading = false;
        }
    }

    async toggleDetails(event) {
        const id = event.currentTarget.dataset.id;
        if (this.openSignalId === id) {
            this.openSignalId = undefined;
            return;
        }
        this.openSignalId = id;
        this.notes = '';
        try {
            this.evidence = (await getEvidence({ signalId: id })).map((e) => ({ ...e, key: e.recordId }));
        } catch (e) {
            this.evidence = [];
        }
    }

    get hasEvidence() {
        return this.evidence.length > 0;
    }

    handleNotes(event) {
        this.notes = event.target.value;
    }

    async setStatus(event) {
        const status = event.currentTarget.dataset.status;
        try {
            await updateStatus({ signalId: this.openSignalId, status, notes: this.notes });
            this.toast('Signal updated', status, 'success');
            this.notes = '';
            await this.load();
        } catch (e) {
            this.toast('Not updated', e?.body?.message || '', 'error');
        }
    }

    openRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: event.currentTarget.dataset.id, actionName: 'view' }
        });
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
```

## `force-app/main/default/lwc/communityWatch/communityWatch.js-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>CareLoop Community Watch</masterLabel>
    <description>CareLoop Sentinel: village x signal grid, flagged community signals and human review.</description>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
    </targets>
</LightningComponentBundle>
```

## `force-app/main/default/flexipages/Community_Watch.flexipage-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<FlexiPage xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>CareLoop Sentinel: community health early warning.</description>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentName>communityWatch</componentName>
                <identifier>c_communityWatch</identifier>
            </componentInstance>
        </itemInstances>
        <name>main</name>
        <type>Region</type>
    </flexiPageRegions>
    <masterLabel>Community Watch</masterLabel>
    <template>
        <name>flexipage:defaultAppHomeTemplate</name>
    </template>
    <type>AppPage</type>
</FlexiPage>
```

## `force-app/main/default/tabs/Community_Signal__c.tab-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <customObject>true</customObject>
    <motif>Custom25: Alarm clock</motif>
</CustomTab>
```

## `force-app/main/default/tabs/Community_Watch.tab-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomTab xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>CareLoop Sentinel: community health early warning.</description>
    <flexiPage>Community_Watch</flexiPage>
    <label>Community Watch</label>
    <motif>Custom26: Flag</motif>
</CustomTab>
```

## `force-app/main/default/permissionsets/CareLoop_Sentinel_Manager.permissionset-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <classAccesses>
        <apexClass>CommunityWatchController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <customPermissions>
        <enabled>true</enabled>
        <name>CareLoop_Run_Sentinel</name>
    </customPermissions>
    <description>Community Watch for programme managers: read, review (investigate / confirm / dismiss) and run the scan.</description>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Alert_Key__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Evidence_Ids__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Expected__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Explanation__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Guidance__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Households__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Community_Signal__c.Investigation_Notes__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Last_Scanned_On__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Observed__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Rate_Per_1000__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Region__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Community_Signal__c.Reviewed_By__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Community_Signal__c.Reviewed_On__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Severity__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Signal_Key__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Signal_Label__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Community_Signal__c.Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Std_Dev__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Threshold__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Village__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Weekly_Counts__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Window_End__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Window_Start__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Z_Score__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label>CareLoop Sentinel Manager</label>
    <objectPermissions>
        <allowCreate>false</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>Community_Signal__c</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>
    <tabSettings>
        <tab>Community_Signal__c</tab>
        <visibility>Visible</visibility>
    </tabSettings>
    <tabSettings>
        <tab>Community_Watch</tab>
        <visibility>Visible</visibility>
    </tabSettings>
</PermissionSet>
```

## `force-app/main/default/permissionsets/CareLoop_Sentinel_Viewer.permissionset-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <classAccesses>
        <apexClass>CommunityWatchController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <description>Community Watch for health workers and doctors: read-only view of community signals (counts only).</description>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Alert_Key__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Evidence_Ids__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Expected__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Explanation__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Guidance__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Households__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Investigation_Notes__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Last_Scanned_On__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Observed__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Rate_Per_1000__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Region__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Reviewed_By__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Reviewed_On__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Severity__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Signal_Key__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Signal_Label__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Std_Dev__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Threshold__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Village__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Weekly_Counts__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Window_End__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Window_Start__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>false</editable>
        <field>Community_Signal__c.Z_Score__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label>CareLoop Sentinel Viewer</label>
    <objectPermissions>
        <allowCreate>false</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>false</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Community_Signal__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <tabSettings>
        <tab>Community_Signal__c</tab>
        <visibility>Available</visibility>
    </tabSettings>
    <tabSettings>
        <tab>Community_Watch</tab>
        <visibility>Visible</visibility>
    </tabSettings>
</PermissionSet>
```

## `force-app/main/default/applications/CareLoop.app-meta.xml` — **MODIFIED**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomApplication xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionOverrides>
        <actionName>View</actionName>
        <comment>CareLoop record page</comment>
        <content>CareLoop_Patient_Record_Page</content>
        <formFactor>Large</formFactor>
        <skipRecordTypeSelect>false</skipRecordTypeSelect>
        <type>Flexipage</type>
        <pageOrSobjectType>Contact</pageOrSobjectType>
    </actionOverrides>
    <brand>
        <headerColor>#0B6E6E</headerColor>
        <shouldOverrideOrgTheme>true</shouldOverrideOrgTheme>
    </brand>
    <description>HealthConnect CareLoop: preventive-care outreach for health workers, doctors and programme managers.</description>
    <formFactors>Small</formFactors>
    <formFactors>Large</formFactors>
    <label>CareLoop</label>
    <navType>Standard</navType>
    <tabs>standard-home</tabs>
    <tabs>Care_Navigator</tabs>
    <tabs>Doctor_Review</tabs>
    <tabs>Community_Watch</tabs>
    <tabs>Care_Activity__c</tabs>
    <tabs>standard-Contact</tabs>
    <tabs>standard-Account</tabs>
    <tabs>Health_Visit__c</tabs>
    <tabs>Medical_Recommendation__c</tabs>
    <tabs>Village__c</tabs>
    <tabs>Visit_Plan__c</tabs>
    <tabs>Community_Signal__c</tabs>
    <tabs>Notification__c</tabs>
    <tabs>Consent__c</tabs>
    <tabs>Consent_Event__c</tabs>
    <tabs>standard-report</tabs>
    <tabs>standard-Dashboard</tabs>
    <tabs>Error_Log__c</tabs>
    <uiType>Lightning</uiType>
</CustomApplication>
```

## `force-app/main/default/reportTypes/CareLoop_Community_Signals.reportType-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ReportType xmlns="http://soap.sforce.com/2006/04/metadata">
    <baseObject>Community_Signal__c</baseObject>
    <category>other</category>
    <deployed>true</deployed>
    <description>CareLoop Sentinel community signals by village, signal, severity and review status.</description>
    <label>CareLoop Community Signals</label>
    <sections>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Name</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Signal_Label__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Severity__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Status__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Observed__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Expected__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Z_Score__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Households__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Rate_Per_1000__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Window_Start__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Window_End__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Region__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Reviewed_On__c</field>
                <table>Community_Signal__c</table>
            </columns>
            <columns>
                <checkedByDefault>true</checkedByDefault>
                <field>Village__c</field>
                <table>Community_Signal__c</table>
            </columns>
        <masterLabel>Community Signals</masterLabel>
    </sections>
</ReportType>
```

## `force-app/main/default/reports/CareLoop_Reports/Community_Signals_by_Region.report-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Report xmlns="http://soap.sforce.com/2006/04/metadata">
    <columns>
        <field>Community_Signal__c$Name</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Signal_Label__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Severity__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Observed__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Expected__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Z_Score__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Window_End__c</field>
    </columns>
    <description>CareLoop Sentinel: community signals by region and review status.</description>
    <format>Summary</format>
    <groupingsDown>
        <dateGranularity>Day</dateGranularity>
        <field>Community_Signal__c$Region__c</field>
        <sortOrder>Asc</sortOrder>
    </groupingsDown>
    <groupingsDown>
        <dateGranularity>Day</dateGranularity>
        <field>Community_Signal__c$Status__c</field>
        <sortOrder>Asc</sortOrder>
    </groupingsDown>
    <name>Community signals by region and status</name>
    <params>
        <name>co</name>
        <value>1</value>
    </params>
    <reportType>CareLoop_Community_Signals__c</reportType>
    <scope>organization</scope>
    <showDetails>true</showDetails>
    <showGrandTotal>true</showGrandTotal>
    <showSubTotals>true</showSubTotals>
    <timeFrameFilter>
        <dateColumn>Community_Signal__c$Window_End__c</dateColumn>
        <interval>INTERVAL_CUSTOM</interval>
    </timeFrameFilter>
</Report>
```

## `force-app/main/default/reports/CareLoop_Reports/Community_Signals_by_Signal_Type.report-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Report xmlns="http://soap.sforce.com/2006/04/metadata">
    <columns>
        <field>Community_Signal__c$Name</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Region__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Status__c</field>
    </columns>
    <columns>
        <aggregateTypes>Sum</aggregateTypes>
        <field>Community_Signal__c$Observed__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Expected__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Z_Score__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Window_End__c</field>
    </columns>
    <description>CareLoop Sentinel: how many Watch and Alert signals each signal type produced (village-level counts only, no patient data).</description>
    <format>Summary</format>
    <groupingsDown>
        <dateGranularity>Day</dateGranularity>
        <field>Community_Signal__c$Signal_Label__c</field>
        <sortOrder>Asc</sortOrder>
    </groupingsDown>
    <groupingsDown>
        <dateGranularity>Day</dateGranularity>
        <field>Community_Signal__c$Severity__c</field>
        <sortOrder>Asc</sortOrder>
    </groupingsDown>
    <name>Community signals by signal type and severity</name>
    <params>
        <name>co</name>
        <value>1</value>
    </params>
    <reportType>CareLoop_Community_Signals__c</reportType>
    <scope>organization</scope>
    <showDetails>true</showDetails>
    <showGrandTotal>true</showGrandTotal>
    <showSubTotals>true</showSubTotals>
    <timeFrameFilter>
        <dateColumn>Community_Signal__c$Window_End__c</dateColumn>
        <interval>INTERVAL_CUSTOM</interval>
    </timeFrameFilter>
</Report>
```

## `force-app/main/default/reports/CareLoop_Reports/Community_Signals_by_Village.report-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Report xmlns="http://soap.sforce.com/2006/04/metadata">
    <columns>
        <field>Community_Signal__c$Name</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Severity__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Status__c</field>
    </columns>
    <columns>
        <aggregateTypes>Sum</aggregateTypes>
        <field>Community_Signal__c$Observed__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Expected__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Households__c</field>
    </columns>
    <columns>
        <field>Community_Signal__c$Window_End__c</field>
    </columns>
    <description>CareLoop Sentinel: signals per village and signal type, with the number of events observed (village-level counts only, no patient data).</description>
    <format>Summary</format>
    <groupingsDown>
        <dateGranularity>Day</dateGranularity>
        <field>Community_Signal__c$Village__c</field>
        <sortOrder>Asc</sortOrder>
    </groupingsDown>
    <groupingsDown>
        <dateGranularity>Day</dateGranularity>
        <field>Community_Signal__c$Signal_Label__c</field>
        <sortOrder>Asc</sortOrder>
    </groupingsDown>
    <name>Community signals by village</name>
    <params>
        <name>co</name>
        <value>1</value>
    </params>
    <reportType>CareLoop_Community_Signals__c</reportType>
    <scope>organization</scope>
    <showDetails>true</showDetails>
    <showGrandTotal>true</showGrandTotal>
    <showSubTotals>true</showSubTotals>
    <timeFrameFilter>
        <dateColumn>Community_Signal__c$Window_End__c</dateColumn>
        <interval>INTERVAL_CUSTOM</interval>
    </timeFrameFilter>
</Report>
```

## `force-app/main/default/dashboards/CareLoop_Dashboards/CareLoop_Sentinel.dashboard-meta.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Dashboard xmlns="http://soap.sforce.com/2006/04/metadata">
    <backgroundEndColor>#FFFFFF</backgroundEndColor>
    <backgroundFadeDirection>Diagonal</backgroundFadeDirection>
    <backgroundStartColor>#FFFFFF</backgroundStartColor>
    <chartTheme>light</chartTheme>
    <colorPalette>unity</colorPalette>
    <dashboardChartTheme>light</dashboardChartTheme>
    <dashboardColorPalette>unity</dashboardColorPalette>
    <dashboardGridLayout>
        <dashboardGridComponents>
            <colSpan>6</colSpan>
            <columnIndex>0</columnIndex>
            <dashboardComponent>
                <autoselectColumnsFromReport>true</autoselectColumnsFromReport>
                <chartAxisRange>Auto</chartAxisRange>
                <componentType>ColumnStacked</componentType>
                <displayUnits>Integer</displayUnits>
                <footer>Stacked by review status</footer>
                <header>Community signals by region</header>
                <legendPosition>Bottom</legendPosition>
                <report>CareLoop_Reports/Community_Signals_by_Region</report>
                <showPercentage>false</showPercentage>
                <showValues>true</showValues>
                <sortBy>RowLabelAscending</sortBy>
                <useReportChart>false</useReportChart>
            </dashboardComponent>
            <rowIndex>0</rowIndex>
            <rowSpan>8</rowSpan>
        </dashboardGridComponents>
        <dashboardGridComponents>
            <colSpan>6</colSpan>
            <columnIndex>6</columnIndex>
            <dashboardComponent>
                <autoselectColumnsFromReport>true</autoselectColumnsFromReport>
                <chartAxisRange>Auto</chartAxisRange>
                <componentType>BarStacked</componentType>
                <displayUnits>Integer</displayUnits>
                <footer>Stacked by Watch / Alert</footer>
                <header>Signals by type</header>
                <legendPosition>Bottom</legendPosition>
                <report>CareLoop_Reports/Community_Signals_by_Signal_Type</report>
                <showPercentage>false</showPercentage>
                <showValues>true</showValues>
                <sortBy>RowLabelAscending</sortBy>
                <useReportChart>false</useReportChart>
            </dashboardComponent>
            <rowIndex>0</rowIndex>
            <rowSpan>8</rowSpan>
        </dashboardGridComponents>
        <dashboardGridComponents>
            <colSpan>12</colSpan>
            <columnIndex>0</columnIndex>
            <dashboardComponent>
                <autoselectColumnsFromReport>true</autoselectColumnsFromReport>
                <chartAxisRange>Auto</chartAxisRange>
                <componentType>BarStacked</componentType>
                <displayUnits>Integer</displayUnits>
                <footer>Stacked by signal type</footer>
                <header>Signals by village</header>
                <legendPosition>Bottom</legendPosition>
                <report>CareLoop_Reports/Community_Signals_by_Village</report>
                <showPercentage>false</showPercentage>
                <showValues>true</showValues>
                <sortBy>RowLabelAscending</sortBy>
                <useReportChart>false</useReportChart>
            </dashboardComponent>
            <rowIndex>8</rowIndex>
            <rowSpan>8</rowSpan>
        </dashboardGridComponents>
        <numberOfColumns>12</numberOfColumns>
        <rowHeight>36</rowHeight>
    </dashboardGridLayout>
    <dashboardType>LoggedInUser</dashboardType>
    <description>CareLoop Sentinel early-warning signals: village-level counts only, never patient data. Signals are unusual increases for investigation, not diagnoses. Runs as the viewer.</description>
    <isGridLayout>true</isGridLayout>
    <textColor>#000000</textColor>
    <title>CareLoop Sentinel - Community Early Warning</title>
    <titleColor>#000000</titleColor>
    <titleSize>12</titleSize>
</Dashboard>
```

## `manifest/innovation-1-data-model.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Community_Signal__c</members>
        <members>Surveillance_Signal__mdt</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Community_Signal__c.Alert_Key__c</members>
        <members>Community_Signal__c.Evidence_Ids__c</members>
        <members>Community_Signal__c.Expected__c</members>
        <members>Community_Signal__c.Explanation__c</members>
        <members>Community_Signal__c.Guidance__c</members>
        <members>Community_Signal__c.Households__c</members>
        <members>Community_Signal__c.Investigation_Notes__c</members>
        <members>Community_Signal__c.Last_Scanned_On__c</members>
        <members>Community_Signal__c.Observed__c</members>
        <members>Community_Signal__c.Rate_Per_1000__c</members>
        <members>Community_Signal__c.Region__c</members>
        <members>Community_Signal__c.Reviewed_By__c</members>
        <members>Community_Signal__c.Reviewed_On__c</members>
        <members>Community_Signal__c.Severity__c</members>
        <members>Community_Signal__c.Signal_Key__c</members>
        <members>Community_Signal__c.Signal_Label__c</members>
        <members>Community_Signal__c.Status__c</members>
        <members>Community_Signal__c.Std_Dev__c</members>
        <members>Community_Signal__c.Threshold__c</members>
        <members>Community_Signal__c.Village__c</members>
        <members>Community_Signal__c.Weekly_Counts__c</members>
        <members>Community_Signal__c.Window_End__c</members>
        <members>Community_Signal__c.Window_Start__c</members>
        <members>Community_Signal__c.Z_Score__c</members>
        <members>Surveillance_Signal__mdt.Active__c</members>
        <members>Surveillance_Signal__mdt.Activity_Types__c</members>
        <members>Surveillance_Signal__mdt.Alert_Z__c</members>
        <members>Surveillance_Signal__mdt.Baseline_Weeks__c</members>
        <members>Surveillance_Signal__mdt.Grace_Days__c</members>
        <members>Surveillance_Signal__mdt.Guidance__c</members>
        <members>Surveillance_Signal__mdt.Max_SpO2__c</members>
        <members>Surveillance_Signal__mdt.Min_Count__c</members>
        <members>Surveillance_Signal__mdt.Min_History_Weeks__c</members>
        <members>Surveillance_Signal__mdt.Min_Temperature__c</members>
        <members>Surveillance_Signal__mdt.Source__c</members>
        <members>Surveillance_Signal__mdt.Symptoms__c</members>
        <members>Surveillance_Signal__mdt.Visit_Outcomes__c</members>
        <members>Surveillance_Signal__mdt.Watch_Z__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Community_Signal__c.All</members>
        <name>ListView</name>
    </types>
    <types>
        <members>Surveillance_Signal.Failed_Visit_Surge</members>
        <members>Surveillance_Signal.Fever_Cluster</members>
        <members>Surveillance_Signal.Immunisation_Delay</members>
        <members>Surveillance_Signal.Respiratory_Cluster</members>
        <name>CustomMetadata</name>
    </types>
    <types>
        <members>CareLoop_Run_Sentinel</members>
        <name>CustomPermission</name>
    </types>
    <version>62.0</version>
</Package>
```

## `manifest/innovation-2-application.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>CommunityWatchController</members>
        <members>CommunityWatchControllerTest</members>
        <members>SentinelJob</members>
        <members>SentinelService</members>
        <members>SentinelServiceTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>communityWatch</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Community_Watch</members>
        <name>FlexiPage</name>
    </types>
    <types>
        <members>Community_Signal__c</members>
        <members>Community_Watch</members>
        <name>CustomTab</name>
    </types>
    <types>
        <members>CareLoop_Sentinel_Manager</members>
        <members>CareLoop_Sentinel_Viewer</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>CareLoop</members>
        <name>CustomApplication</name>
    </types>
    <types>
        <members>CareLoop_Community_Signals</members>
        <name>ReportType</name>
    </types>
    <types>
        <members>CareLoop_Reports/Community_Signals_by_Region</members>
        <members>CareLoop_Reports/Community_Signals_by_Signal_Type</members>
        <members>CareLoop_Reports/Community_Signals_by_Village</members>
        <name>Report</name>
    </types>
    <types>
        <members>CareLoop_Dashboards/CareLoop_Sentinel</members>
        <name>Dashboard</name>
    </types>
    <version>62.0</version>
</Package>
```

## `manifest/innovation-package.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>Community_Signal__c</members>
        <members>Surveillance_Signal__mdt</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Community_Signal__c.Alert_Key__c</members>
        <members>Community_Signal__c.Evidence_Ids__c</members>
        <members>Community_Signal__c.Expected__c</members>
        <members>Community_Signal__c.Explanation__c</members>
        <members>Community_Signal__c.Guidance__c</members>
        <members>Community_Signal__c.Households__c</members>
        <members>Community_Signal__c.Investigation_Notes__c</members>
        <members>Community_Signal__c.Last_Scanned_On__c</members>
        <members>Community_Signal__c.Observed__c</members>
        <members>Community_Signal__c.Rate_Per_1000__c</members>
        <members>Community_Signal__c.Region__c</members>
        <members>Community_Signal__c.Reviewed_By__c</members>
        <members>Community_Signal__c.Reviewed_On__c</members>
        <members>Community_Signal__c.Severity__c</members>
        <members>Community_Signal__c.Signal_Key__c</members>
        <members>Community_Signal__c.Signal_Label__c</members>
        <members>Community_Signal__c.Status__c</members>
        <members>Community_Signal__c.Std_Dev__c</members>
        <members>Community_Signal__c.Threshold__c</members>
        <members>Community_Signal__c.Village__c</members>
        <members>Community_Signal__c.Weekly_Counts__c</members>
        <members>Community_Signal__c.Window_End__c</members>
        <members>Community_Signal__c.Window_Start__c</members>
        <members>Community_Signal__c.Z_Score__c</members>
        <members>Surveillance_Signal__mdt.Active__c</members>
        <members>Surveillance_Signal__mdt.Activity_Types__c</members>
        <members>Surveillance_Signal__mdt.Alert_Z__c</members>
        <members>Surveillance_Signal__mdt.Baseline_Weeks__c</members>
        <members>Surveillance_Signal__mdt.Grace_Days__c</members>
        <members>Surveillance_Signal__mdt.Guidance__c</members>
        <members>Surveillance_Signal__mdt.Max_SpO2__c</members>
        <members>Surveillance_Signal__mdt.Min_Count__c</members>
        <members>Surveillance_Signal__mdt.Min_History_Weeks__c</members>
        <members>Surveillance_Signal__mdt.Min_Temperature__c</members>
        <members>Surveillance_Signal__mdt.Source__c</members>
        <members>Surveillance_Signal__mdt.Symptoms__c</members>
        <members>Surveillance_Signal__mdt.Visit_Outcomes__c</members>
        <members>Surveillance_Signal__mdt.Watch_Z__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Community_Signal__c.All</members>
        <name>ListView</name>
    </types>
    <types>
        <members>Surveillance_Signal.Failed_Visit_Surge</members>
        <members>Surveillance_Signal.Fever_Cluster</members>
        <members>Surveillance_Signal.Immunisation_Delay</members>
        <members>Surveillance_Signal.Respiratory_Cluster</members>
        <name>CustomMetadata</name>
    </types>
    <types>
        <members>CareLoop_Run_Sentinel</members>
        <name>CustomPermission</name>
    </types>
    <types>
        <members>CommunityWatchController</members>
        <members>CommunityWatchControllerTest</members>
        <members>SentinelJob</members>
        <members>SentinelService</members>
        <members>SentinelServiceTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>communityWatch</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Community_Watch</members>
        <name>FlexiPage</name>
    </types>
    <types>
        <members>Community_Signal__c</members>
        <members>Community_Watch</members>
        <name>CustomTab</name>
    </types>
    <types>
        <members>CareLoop_Sentinel_Manager</members>
        <members>CareLoop_Sentinel_Viewer</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>CareLoop</members>
        <name>CustomApplication</name>
    </types>
    <types>
        <members>CareLoop_Community_Signals</members>
        <name>ReportType</name>
    </types>
    <types>
        <members>CareLoop_Reports/Community_Signals_by_Region</members>
        <members>CareLoop_Reports/Community_Signals_by_Signal_Type</members>
        <members>CareLoop_Reports/Community_Signals_by_Village</members>
        <name>Report</name>
    </types>
    <types>
        <members>CareLoop_Dashboards/CareLoop_Sentinel</members>
        <name>Dashboard</name>
    </types>
    <version>62.0</version>
</Package>
```

## `manifest/innovation-rollback/destructiveChanges.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>CareLoop_Dashboards/CareLoop_Sentinel</members>
        <name>Dashboard</name>
    </types>
    <types>
        <members>CareLoop_Reports/Community_Signals_by_Region</members>
        <members>CareLoop_Reports/Community_Signals_by_Signal_Type</members>
        <members>CareLoop_Reports/Community_Signals_by_Village</members>
        <name>Report</name>
    </types>
    <types>
        <members>CareLoop_Community_Signals</members>
        <name>ReportType</name>
    </types>
    <types>
        <members>CareLoop_Sentinel_Manager</members>
        <members>CareLoop_Sentinel_Viewer</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>Community_Signal__c</members>
        <members>Community_Watch</members>
        <name>CustomTab</name>
    </types>
    <types>
        <members>Community_Watch</members>
        <name>FlexiPage</name>
    </types>
    <types>
        <members>communityWatch</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>CommunityWatchController</members>
        <members>CommunityWatchControllerTest</members>
        <members>SentinelJob</members>
        <members>SentinelService</members>
        <members>SentinelServiceTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>CareLoop_Run_Sentinel</members>
        <name>CustomPermission</name>
    </types>
    <types>
        <members>Surveillance_Signal.Failed_Visit_Surge</members>
        <members>Surveillance_Signal.Fever_Cluster</members>
        <members>Surveillance_Signal.Immunisation_Delay</members>
        <members>Surveillance_Signal.Respiratory_Cluster</members>
        <name>CustomMetadata</name>
    </types>
    <types>
        <members>Community_Signal__c</members>
        <members>Surveillance_Signal__mdt</members>
        <name>CustomObject</name>
    </types>
    <version>62.0</version>
</Package>
```

## `manifest/innovation-rollback/package.xml` — NEW

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>62.0</version>
</Package>
```

## `scripts/apex/innovation-assign-permissions.apex` — NEW

```java
// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): assign the two new permission sets
// =====================================================================================
//   CareLoop_Sentinel_Manager -> you (admin) and Meena Iyer   (review signals, run the scan)
//   CareLoop_Sentinel_Viewer  -> Arjun Reddy, Lakshmi Devi, Sunita Rao (read-only Community Watch)
// Existing permission sets are not changed. Safe to re-run (only missing assignments are added).
//
// Run:
//   sf apex run --file scripts/apex/innovation-assign-permissions.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'SENTINEL ' + line);
}
String username(String first, String last) {
    return (first + '.' + last + '.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
}
Map<String, String> planned = new Map<String, String>{
    username('Meena', 'Iyer') => 'CareLoop_Sentinel_Manager',
    username('Arjun', 'Reddy') => 'CareLoop_Sentinel_Viewer',
    username('Lakshmi', 'Devi') => 'CareLoop_Sentinel_Viewer',
    username('Sunita', 'Rao') => 'CareLoop_Sentinel_Viewer'
};
Map<String, Id> permsets = new Map<String, Id>();
for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('CareLoop_Sentinel_Manager', 'CareLoop_Sentinel_Viewer')]) {
    permsets.put(ps.Name, ps.Id);
}
if (permsets.size() != 2) {
    say('STOP  | Deploy the innovation package first (permission sets not found).');
} else {
    Map<Id, String> wanted = new Map<Id, String>{ UserInfo.getUserId() => 'CareLoop_Sentinel_Manager' };
    for (User u : [SELECT Id, Username FROM User WHERE Username IN :planned.keySet() AND IsActive = true]) {
        wanted.put(u.Id, planned.get(u.Username));
    }
    Set<String> existing = new Set<String>();
    for (PermissionSetAssignment a : [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment
                                      WHERE AssigneeId IN :wanted.keySet() AND PermissionSetId IN :permsets.values()]) {
        existing.add(a.AssigneeId + ':' + a.PermissionSetId);
    }
    List<PermissionSetAssignment> toAdd = new List<PermissionSetAssignment>();
    for (Id userId : wanted.keySet()) {
        Id psId = permsets.get(wanted.get(userId));
        if (!existing.contains(userId + ':' + psId)) {
            toAdd.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = psId));
        }
    }
    insert toAdd;
    say('DONE  | ' + toAdd.size() + ' assignment(s) added, ' + existing.size() + ' already present, ' + wanted.size() + ' users covered');
}
```

## `scripts/apex/innovation-remove-demo-data.apex` — NEW

```java
// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): remove the Sentinel demo data
// =====================================================================================
// Deletes ONLY: visits whose Observations are exactly "Sentinel demo", care activities whose Name starts
// with "Sentinel demo", and the Community Signal records of the four demo villages (recreated by the next scan).
// Phase 1-7 records (patients, households, other visits and activities) are not touched.
//   sf apex run --file scripts/apex/innovation-remove-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
// Observations__c is a long text field and cannot be used in a WHERE clause, so candidates are
// selected by village and date and the tag is checked in Apex.
List<Health_Visit__c> visits = new List<Health_Visit__c>();
for (Health_Visit__c v : [SELECT Id, Observations__c FROM Health_Visit__c
                          WHERE Patient__r.Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur')
                            AND Visit_Date__c = LAST_N_DAYS:120]) {
    if (v.Observations__c == 'Sentinel demo') {
        visits.add(v);
    }
}
List<Care_Activity__c> doses = [SELECT Id FROM Care_Activity__c WHERE Name LIKE 'Sentinel demo%'];
// Signals are produced by the Sentinel scan; only those for the four demo villages are removed.
List<Community_Signal__c> signals = [SELECT Id FROM Community_Signal__c
                                     WHERE Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur')];
delete visits;
delete doses;
delete signals;
System.debug(LoggingLevel.ERROR, 'SENTINEL CLEANUP | ' + visits.size() + ' visits, ' + doses.size() + ' doses, ' + signals.size() + ' signals removed');
```

## `scripts/apex/innovation-rollback-prepare.apex` — NEW

```java
// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): prepare a rollback
// =====================================================================================
// Run this ONLY if you decide to remove the innovation. It clears everything that would block
// Salesforce from deleting the new metadata:
//   1. aborts the "CareLoop Sentinel Daily Scan" scheduled job (a scheduled class cannot be deleted)
//   2. removes the Sentinel permission set assignments (an assigned permission set cannot be deleted)
//   3. deletes all Community Signal records and the "Sentinel demo" visits and doses
// Phase 1-7 data and permission sets are not touched. Next steps are in README-INNOVATION.md (Rollback).
//   sf apex run --file scripts/apex/innovation-rollback-prepare.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'ROLLBACK ' + line);
}
Integer jobs = 0;
for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'CareLoop Sentinel Daily Scan']) {
    System.abortJob(ct.Id);
    jobs++;
}
say('1 | ' + jobs + ' scheduled Sentinel job(s) aborted');
List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment
    WHERE PermissionSet.Name IN ('CareLoop_Sentinel_Manager', 'CareLoop_Sentinel_Viewer')];
delete assignments;
say('2 | ' + assignments.size() + ' Sentinel permission set assignment(s) removed');
List<Health_Visit__c> visits = new List<Health_Visit__c>();
for (Health_Visit__c v : [SELECT Id, Observations__c FROM Health_Visit__c
                          WHERE Patient__r.Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur')
                            AND Visit_Date__c = LAST_N_DAYS:120]) {
    if (v.Observations__c == 'Sentinel demo') {
        visits.add(v);
    }
}
List<Care_Activity__c> doses = [SELECT Id FROM Care_Activity__c WHERE Name LIKE 'Sentinel demo%'];
List<Community_Signal__c> signals = [SELECT Id FROM Community_Signal__c];
delete visits;
delete doses;
delete signals;
say('3 | ' + visits.size() + ' demo visits, ' + doses.size() + ' demo doses, ' + signals.size() + ' signals deleted');
say('READY | Now restore the CareLoop app from Git and run the destructive deploy (README-INNOVATION.md)');
```

## `scripts/apex/innovation-run-scan.apex` — NEW

```java
// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): run the community scan now
// =====================================================================================
// Evaluates every village x signal as of the CareLoop clock's today, records Watch / Alert signals
// and sends bell notifications to programme managers and doctors. Safe to re-run: an open signal
// is updated, a dismissed one is left alone.
//
// Run:
//   sf apex run --file scripts/apex/innovation-run-scan.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Date asOf = CareLoopClock.today();
SentinelService.ScanSummary summary = SentinelService.scan(asOf, true);
System.debug(LoggingLevel.ERROR, 'SENTINEL SCAN  | as of ' + asOf + (CareLoopClock.isSimulated() ? ' (SIMULATED)' : '')
    + ' | ' + summary.cellsEvaluated + ' village-signals | ' + summary.flagged + ' flagged | ' + summary.created + ' new | '
    + summary.updated + ' updated | ' + summary.notified + ' notification(s)');
for (Community_Signal__c s : [SELECT Name, Severity__c, Status__c, Observed__c, Expected__c, Z_Score__c, Households__c
                              FROM Community_Signal__c WHERE Window_End__c >= :asOf.addDays(-14) ORDER BY Z_Score__c DESC]) {
    System.debug(LoggingLevel.ERROR, 'SENTINEL SIGNAL| ' + s.Severity__c + ' | ' + s.Name + ' | observed ' + s.Observed__c
        + ' vs normal ' + s.Expected__c + ' | ' + s.Z_Score__c + ' SD | ' + s.Households__c + ' households | ' + s.Status__c);
}
```

## `scripts/apex/innovation-schedule-sentinel.apex` — NEW

```java
// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): schedule the daily scan (06:30)
// =====================================================================================
// Safe to re-run. Remove in Setup > Scheduled Jobs.
//   sf apex run --file scripts/apex/innovation-schedule-sentinel.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
Id cronId = SentinelJob.scheduleDaily();
CronTrigger ct = [SELECT CronJobDetail.Name, NextFireTime, State FROM CronTrigger WHERE Id = :cronId];
System.debug(LoggingLevel.ERROR, 'SCHEDULE OK | ' + ct.CronJobDetail.Name + ' | ' + ct.State + ' | next run ' + ct.NextFireTime);
```

## `scripts/apex/innovation-sentinel-demo-data.apex` — NEW

```java
// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): community signal demo data (kept)
// =====================================================================================
// Adds SYNTHETIC (made-up, clearly tagged) visits and care activities to the Phase 4 demo villages so the early-warning scan
// has a realistic history and three clear signals to find:
//   * every village: 2 routine visits a week for 6 weeks (history) and a low background of fever and missed visits
//   * Kondapur   : RESPIRATORY CLUSTER - 4 visits with cough / breathlessness / SpO2 93 in the last 5 days
//   * Moinabad   : FEVER CLUSTER - 7 febrile visits from different households in the last 5 days
//   * Kandukur   : HOUSEHOLDS NOT REACHABLE - 6 visits "Patient Not Available" in the last 6 days
//   * Shamshabad : VACCINE DOSES DELAYED - 5 catch-up doses due 8-12 days ago not given
// Every record is tagged (visit Observations / activity Name start with "Sentinel demo") so innovation-remove-demo-data.apex can remove it.
// Requires phase4-demo-data.apex. Safe to re-run: stops if the tag already exists.
//
// Run:
//   sf apex run --file scripts/apex/innovation-sentinel-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'SENTINEL ' + line);
}

Integer nextInt(Integer bound) {
    Integer r = Crypto.getRandomInteger();
    return Math.mod(r < 0 ? -(r + 1) : r, bound);
}

Datetime at(Date day) {
    return Datetime.newInstance(day, Time.newInstance(10, 30, 0, 0));
}

Health_Visit__c feverVisit(Contact p, Date day, Decimal temperature) {
    return new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = at(day), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = 'Completed', Health_Worker__c = p.Assigned_Health_Worker__c,
        Symptoms__c = 'Fever;Headache', Temperature__c = temperature, Observations__c = 'Sentinel demo');
}

Health_Visit__c routineVisit(Contact p, Date day) {
    return new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = at(day), Visit_Type__c = 'Routine Check-up',
        Visit_Outcome__c = 'Completed', Health_Worker__c = p.Assigned_Health_Worker__c, Observations__c = 'Sentinel demo');
}

Health_Visit__c missedVisit(Contact p, Date day) {
    return new Health_Visit__c(Patient__c = p.Id, Visit_Date__c = at(day), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = 'Patient Not Available', Health_Worker__c = p.Assigned_Health_Worker__c,
        Observations__c = 'Sentinel demo');
}

void run() {
    // Observations__c is a long text field (cannot be filtered in SOQL), so the tagged catch-up doses are the marker.
    if ([SELECT COUNT() FROM Care_Activity__c WHERE Name LIKE 'Sentinel demo%'] > 0) {
        say('EXISTS  | Sentinel demo data already loaded. Nothing changed.');
        return;
    }
    Date today = CareLoopClock.today();
    if (today > Date.today()) {
        // Visits dated after the real today would break the No_Future_Visit validation rule.
        say('STOP    | The CareLoop demo clock (Simulated Today = ' + today + ') is ahead of the real date. Clear it or set it to today first.');
        return;
    }
    Map<String, List<Contact>> adultsByVillage = new Map<String, List<Contact>>();
    Map<String, List<Contact>> childrenByVillage = new Map<String, List<Contact>>();
    for (Contact c : [SELECT Id, AccountId, Birthdate, Assigned_Health_Worker__c, Village__r.Name FROM Contact
                      WHERE Village__r.Name IN ('Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur') AND Birthdate != null
                      ORDER BY AccountId]) {
        Map<String, List<Contact>> target = c.Birthdate <= today.addYears(-18) ? adultsByVillage : childrenByVillage;
        if (!target.containsKey(c.Village__r.Name)) {
            target.put(c.Village__r.Name, new List<Contact>());
        }
        target.get(c.Village__r.Name).add(c);
    }
    for (String v : new List<String>{ 'Kondapur', 'Moinabad', 'Shamshabad', 'Kandukur' }) {
        if (!adultsByVillage.containsKey(v) || adultsByVillage.get(v).size() < 4) {
            say('STOP    | Not enough demo patients in ' + v + '. Run scripts/apex/phase4-demo-data.apex first.');
            return;
        }
    }

    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    // ---- normal background: 2 routine visits every week (this is the "history" Sentinel needs before it
    //      will assess a village), plus 0-1 fever and 0-1 missed visits per week in weeks 1-4
    for (String v : adultsByVillage.keySet()) {
        List<Contact> adults = adultsByVillage.get(v);
        for (Integer week = 0; week <= 5; week++) {
            visits.add(routineVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - 1 - nextInt(3))));
            visits.add(routineVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - 4 - nextInt(3))));
        }
        for (Integer week = 1; week <= 4; week++) {
            if (nextInt(3) > 0) {
                visits.add(feverVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - nextInt(6)), 38.1 + nextInt(8) / 10.0));
            }
            if (nextInt(2) == 0) {
                visits.add(missedVisit(adults[nextInt(adults.size())], today.addDays(-(week * 7) - nextInt(6))));
            }
        }
    }
    // ---- Moinabad fever cluster: 7 visits in the last 5 days, one per household where possible
    List<Contact> moinabad = adultsByVillage.get('Moinabad');
    Set<Id> usedHouseholds = new Set<Id>();
    Integer added = 0;
    for (Contact c : moinabad) {
        if (added == 7) { break; }
        if (usedHouseholds.contains(c.AccountId) && usedHouseholds.size() < 5) { continue; }
        usedHouseholds.add(c.AccountId);
        visits.add(feverVisit(c, today.addDays(-1 - Math.mod(added, 5)), 38.2 + Math.mod(added * 3, 11) / 10.0));
        added++;
    }
    say('PLANNED | Moinabad fever cluster: ' + added + ' visits from ' + usedHouseholds.size() + ' households');
    // ---- Kondapur respiratory cluster: 4 visits in the last 5 days (cough, breathlessness, low SpO2)
    List<Contact> kondapur = adultsByVillage.get('Kondapur');
    List<String> respiratory = new List<String>{ 'Cough', 'Cough;Fever', 'Breathlessness', null };
    for (Integer i = 0; i < 4; i++) {
        Contact c = kondapur[Math.mod(i, kondapur.size())];
        visits.add(new Health_Visit__c(Patient__c = c.Id, Visit_Date__c = at(today.addDays(-1 - i)), Visit_Type__c = 'Home Visit',
            Visit_Outcome__c = 'Completed', Health_Worker__c = c.Assigned_Health_Worker__c, Symptoms__c = respiratory[i],
            Temperature__c = i == 1 ? 38.3 : null, SpO2__c = i == 3 ? 93 : null, Observations__c = 'Sentinel demo'));
    }
    // ---- Kandukur access problem: 6 "not available" visits in the last 6 days
    List<Contact> kandukur = adultsByVillage.get('Kandukur');
    for (Integer i = 0; i < 6; i++) {
        visits.add(missedVisit(kandukur[Math.mod(i, kandukur.size())], today.addDays(-1 - i)));
    }
    insert visits;
    say('CREATED | ' + visits.size() + ' synthetic visits (history + background + three clusters)');

    // ---- Shamshabad vaccine delay: catch-up doses; 4 on time in earlier weeks, 5 overdue now
    List<Contact> kids = childrenByVillage.containsKey('Shamshabad') ? childrenByVillage.get('Shamshabad') : adultsByVillage.get('Shamshabad');
    List<Care_Activity__c> doses = new List<Care_Activity__c>();
    for (Integer i = 0; i < 4; i++) {
        Date due = today.addDays(-15 - i * 7);
        doses.add(new Care_Activity__c(Name = 'Sentinel demo - catch-up dose ' + (i + 1), Patient__c = kids[Math.mod(i, kids.size())].Id,
            Activity_Type__c = 'Immunization', Due_Date__c = due, Source__c = 'Manual'));
    }
    for (Integer i = 0; i < 5; i++) {
        doses.add(new Care_Activity__c(Name = 'Sentinel demo - catch-up dose ' + (i + 5), Patient__c = kids[Math.mod(i, kids.size())].Id,
            Activity_Type__c = 'Immunization', Due_Date__c = today.addDays(-8 - i), Source__c = 'Manual'));
    }
    insert doses;
    List<Care_Activity__c> onTime = new List<Care_Activity__c>();
    for (Integer i = 0; i < 4; i++) {
        onTime.add(new Care_Activity__c(Id = doses[i].Id, Status__c = 'Completed', Completed_Date__c = doses[i].Due_Date__c.addDays(2)));
    }
    update onTime;
    say('CREATED | 9 catch-up doses in Shamshabad (4 given on time earlier, 5 now delayed)');
    say('FINISHED | Next: scripts/apex/innovation-run-scan.apex');
}

run();
```

## `scripts/apex/innovation-verify.apex` — NEW

```java
// =====================================================================================
// HealthConnect CareLoop - Innovation (CareLoop Sentinel): verify (rolls everything back)
// =====================================================================================
//   1  The four configured signals are active
//   2  Fever cluster (6 visits, 4 households, quiet baseline) is an Alert, with a plain explanation
//   3  Respiratory cluster (cough / breathlessness / SpO2 < 94) is detected
//   4  Households-not-reachable surge is detected; 3 missed visits (below the minimum 4) is not
//   5  Delayed vaccine doses are detected
//   6  A village with a steady level is Normal
//   7  A village with no history is "not assessed", never flagged
//   8  Scan records one signal; re-scan updates it (no duplicate) and keeps its status
//   9  Closed / dismissed signals are not raised again in the same week
//   10 No Error Log entries
// Uses synthetic villages named "Verify ..." and rolls everything back at the end.
// Run:
//   sf apex run --file scripts/apex/innovation-verify.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================
void say(String line) {
    System.debug(LoggingLevel.ERROR, 'SENTINEL ' + line);
}
Integer mark(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}
Datetime at(Date day) {
    return Datetime.newInstance(day, Time.newInstance(0, 5, 0, 0));
}
SentinelService.SignalResult find(List<SentinelService.SignalResult> results, String village, String signal) {
    for (SentinelService.SignalResult r : results) {
        if (r.villageName == village && r.signalKey == signal) {
            return r;
        }
    }
    return null;
}
List<Contact> village(String name, Integer households) {
    Village__c v = new Village__c(Name = name, Region__c = 'North', District__c = 'D', State__c = 'Telangana', Population__c = 1500);
    insert v;
    List<Account> hh = new List<Account>();
    for (Integer i = 0; i < households; i++) {
        hh.add(new Account(Name = name + ' HH ' + i, Village__c = v.Id));
    }
    insert hh;
    List<Contact> people = new List<Contact>();
    for (Account a : hh) {
        people.add(new Contact(FirstName = 'Verify', LastName = name, AccountId = a.Id, Village__c = v.Id,
            Birthdate = Date.today().addYears(-35), Gender__c = 'Female', Assigned_Health_Worker__c = UserInfo.getUserId()));
    }
    insert people;
    return people;
}
Health_Visit__c visit(Id patientId, Date day, String outcome, String symptoms, Decimal temperature, Decimal spo2) {
    return new Health_Visit__c(Patient__c = patientId, Visit_Date__c = at(day), Visit_Type__c = 'Home Visit',
        Visit_Outcome__c = outcome, Symptoms__c = symptoms, Temperature__c = temperature, SpO2__c = spo2);
}
List<Health_Visit__c> history(Id patientId, Date today) {
    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    for (Integer week = 1; week <= 5; week++) {
        visits.add(visit(patientId, today.addDays(-(week * 7) - 3), 'Completed', null, null, null));
    }
    return visits;
}
String describe(SentinelService.SignalResult r) {
    return r == null ? '(not found)' : r.severity + ', observed ' + r.observed + ' vs normal ' + r.expected;
}

Integer runChecks() {
    Integer failures = 0;
    Integer logsBefore = [SELECT COUNT() FROM Error_Log__c];
    Date today = CareLoopClock.today();
    if (today > Date.today()) {
        say('STOP  The CareLoop demo clock is ahead of the real date; clear Simulated Today first.');
        return 1;
    }
    failures += mark(SentinelService.signals().size() >= 4, '1  ' + SentinelService.signals().size() + ' active surveillance signals configured');
    TriggerHandler.bypass('ContactTriggerHandler');
    List<Contact> spike = village('Verify Spike', 6);
    List<Contact> steady = village('Verify Steady', 6);
    List<Contact> fresh = village('Verify New', 4);
    List<Health_Visit__c> visits = new List<Health_Visit__c>();
    visits.addAll(history(spike[5].Id, today));
    visits.addAll(history(steady[5].Id, today));
    visits.add(visit(spike[0].Id, today.addDays(-10), 'Completed', 'Fever', 38.4, null));
    visits.add(visit(spike[1].Id, today.addDays(-30), 'Completed', 'Fever', 38.4, null));
    for (Integer i = 0; i < 6; i++) {
        visits.add(visit(spike[Math.mod(i, 4)].Id, today.addDays(-Math.mod(i, 5)), 'Completed', 'Fever', 38.4, null));
        visits.add(visit(fresh[Math.mod(i, 4)].Id, today.addDays(-Math.mod(i, 5)), 'Completed', 'Fever', 38.4, null));
    }
    visits.add(visit(spike[0].Id, today.addDays(-1), 'Completed', 'Cough', null, null));
    visits.add(visit(spike[1].Id, today.addDays(-2), 'Completed', 'Breathlessness', null, null));
    visits.add(visit(spike[2].Id, today.addDays(-3), 'Completed', null, null, 93));
    for (Integer i = 0; i < 5; i++) {
        visits.add(visit(spike[i].Id, today.addDays(-i), 'Patient Not Available', null, null, null));
    }
    for (Integer i = 0; i < 3; i++) {
        visits.add(visit(steady[i].Id, today.addDays(-i), 'Patient Not Available', null, null, null));
    }
    for (Integer week = 0; week <= 4; week++) {
        visits.add(visit(steady[0].Id, today.addDays(-(week * 7) - 1), 'Completed', 'Fever', 38.4, null));
        visits.add(visit(steady[1].Id, today.addDays(-(week * 7) - 2), 'Completed', 'Fever', 38.4, null));
    }
    insert visits;
    List<Care_Activity__c> doses = new List<Care_Activity__c>();
    for (Integer i = 0; i < 4; i++) {
        Date due = today.addDays(-15 - i * 7);
        doses.add(new Care_Activity__c(Name = 'Verify on time ' + i, Patient__c = steady[i].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = due, Status__c = 'Completed', Completed_Date__c = due.addDays(1)));
    }
    for (Integer i = 0; i < 5; i++) {
        doses.add(new Care_Activity__c(Name = 'Verify dose ' + i, Patient__c = steady[Math.mod(i, 3)].Id, Activity_Type__c = 'Immunization',
            Due_Date__c = today.addDays(-8 - i)));
    }
    insert doses;

    List<SentinelService.SignalResult> results = SentinelService.evaluate(today);
    SentinelService.SignalResult r = find(results, 'Verify Spike', 'Fever_Cluster');
    failures += mark(r != null && r.severity == 'Alert' && r.observed == 6 && r.households == 4,
        '2  Fever cluster is an Alert: ' + (r == null ? '(not found)' : r.explanation));
    r = find(results, 'Verify Spike', 'Respiratory_Cluster');
    failures += mark(r != null && r.observed == 3 && r.severity != 'Normal', '3  Respiratory cluster detected: ' + describe(r));
    r = find(results, 'Verify Spike', 'Failed_Visit_Surge');
    SentinelService.SignalResult small = find(results, 'Verify Steady', 'Failed_Visit_Surge');
    failures += mark(r != null && r.severity == 'Alert' && small != null && small.severity == 'Normal',
        '4  5 unreachable visits flagged (' + describe(r) + '); 3 not flagged (' + describe(small) + ')');
    r = find(results, 'Verify Steady', 'Immunisation_Delay');
    failures += mark(r != null && r.observed == 5 && r.severity != 'Normal', '5  Delayed vaccine doses detected: ' + describe(r));
    r = find(results, 'Verify Steady', 'Fever_Cluster');
    failures += mark(r != null && r.severity == 'Normal' && r.observed == 2, '6  Steady village is Normal: ' + describe(r));
    r = find(results, 'Verify New', 'Fever_Cluster');
    failures += mark(r != null && r.severity == 'Normal' && r.insufficientHistory, '7  Village with no history is not assessed: '
        + (r == null ? '(not found)' : r.explanation));

    SentinelService.scan(today, false);
    Id villageId = [SELECT Id FROM Village__c WHERE Name = 'Verify Spike'].Id;
    List<Community_Signal__c> recorded = [SELECT Id, Status__c FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Fever_Cluster'];
    Boolean firstOk = recorded.size() == 1 && recorded[0].Status__c == 'New';
    update new Community_Signal__c(Id = recorded[0].Id, Status__c = 'Investigating');
    SentinelService.scan(today, false);
    recorded = [SELECT Id, Status__c FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Fever_Cluster'];
    failures += mark(firstOk && recorded.size() == 1 && recorded[0].Status__c == 'Investigating',
        '8  One signal recorded; re-scan updated it (no duplicate) and kept "Investigating"');
    update new Community_Signal__c(Id = recorded[0].Id, Status__c = 'Closed', Investigation_Notes__c = 'verify');
    List<Community_Signal__c> respiratory = [SELECT Id FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Respiratory_Cluster'];
    if (!respiratory.isEmpty()) {
        update new Community_Signal__c(Id = respiratory[0].Id, Status__c = 'Dismissed', Investigation_Notes__c = 'verify');
    }
    SentinelService.scan(today, false);
    Community_Signal__c closed = [SELECT Status__c FROM Community_Signal__c WHERE Id = :recorded[0].Id];
    Integer feverRows = [SELECT COUNT() FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Fever_Cluster'];
    Integer respiratoryRows = [SELECT COUNT() FROM Community_Signal__c WHERE Village__c = :villageId AND Signal_Key__c = 'Respiratory_Cluster'];
    failures += mark(closed.Status__c == 'Closed' && feverRows == 1 && respiratoryRows == 1,
        '9  Closed and dismissed signals left alone, not raised again');
    Integer newLogs = [SELECT COUNT() FROM Error_Log__c] - logsBefore;
    failures += mark(newLogs == 0, '10 No Error Log entries (' + newLogs + ')');
    return failures;
}

Savepoint sp = Database.setSavepoint();
Integer failures = 1;
try {
    failures = runChecks();
} catch (Exception e) {
    say('ERROR ' + e.getTypeName() + ': ' + e.getMessage() + ' | ' + e.getStackTraceString());
} finally {
    Database.rollback(sp);
}
say(failures == 0 ? 'INNOVATION VERIFY PASSED (10 checks, all test data rolled back)' : 'INNOVATION VERIFY: ' + failures + ' FAILURE(S) (rolled back)');
```

## `scripts/run-all-verifications-with-sentinel.ps1` — NEW

```powershell
# =====================================================================================
# HealthConnect CareLoop - full regression INCLUDING CareLoop Sentinel.
# Same behaviour as scripts/run-all-verifications.ps1 (Phases 1-7, unchanged) plus the Sentinel verify.
# It only runs read-only or rolled-back verification scripts. Run from the project folder:
#   powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications-with-sentinel.ps1
# =====================================================================================
$org = "careloop"
$scripts = @(
    "scripts/apex/verify-phase1.apex",
    "scripts/apex/phase2-verify-security.apex",
    "scripts/apex/phase3-verify.apex",
    "scripts/apex/phase4-verify.apex",
    "scripts/apex/phase5-verify.apex",
    "scripts/apex/phase6-verify.apex",
    "scripts/apex/phase7-verify.apex",
    "scripts/apex/innovation-verify.apex"
)
foreach ($s in $scripts) {
    if (-not (Test-Path $s)) { Write-Host "MISSING  $s" -ForegroundColor Yellow; continue }
    $lines = sf apex run --file $s --target-org $org | Select-String "USER_DEBUG"
    $fails = $lines | Select-String "FAIL "
    $last = if ($lines) { ($lines | Select-Object -Last 1).ToString() } else { "no output - run the script alone to see the error" }
    $verdict = ($last -split '\|')[-1].Trim()
    $color = if ($fails -or $verdict -match "FAIL|ERROR|PROBLEMS") { "Red" } else { "Green" }
    Write-Host ("{0,-45} {1}" -f $s, $verdict) -ForegroundColor $color
    foreach ($f in $fails) { Write-Host ("    " + (($f.ToString() -split '\|')[-1].Trim())) -ForegroundColor Red }
}
```
