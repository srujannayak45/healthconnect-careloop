// =====================================================================================
// HealthConnect CareLoop - Phase 2: verify security (read-only)
// =====================================================================================
// Checks, without changing anything:
//   A. Sharing defaults (Household private, Patient controlled by parent, CareLoop objects)
//   B. The four CareLoop roles and their parents
//   C. The four staff users: active, licence, profile, role, manager, permission set,
//      and their EFFECTIVE object permissions (profile + permission sets combined)
//   D. Nobody holds CareLoop_Validation_Bypass; you hold CareLoop_Admin
//   E. Record visibility matrix: which user can read which test record
//      (needs the records from phase2-access-fixtures.apex; skipped if they are missing)
//
// Run:
//   sf apex run --file scripts/apex/phase2-verify-security.apex --target-org careloop | Select-String "USER_DEBUG"
// The last line is "PHASE 2 SECURITY OK" or lists the number of problems.
// =====================================================================================

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'VERIFY ' + line);
}

Integer check(Boolean ok, String label) {
    say((ok ? 'PASS  ' : 'FAIL  ') + label);
    return ok ? 0 : 1;
}

String normalise(String value) {
    return value == null ? '' : value.toLowerCase().replaceAll('[^a-z]', '');
}

String usernameFor(String first, String last) {
    return (first + '.' + last + '.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo';
}

// ---------------------------------------------------------------- A. Sharing defaults
Integer checkSharing() {
    Integer failures = 0;
    Organization org = [SELECT DefaultAccountAccess, DefaultContactAccess FROM Organization LIMIT 1];
    failures += check(org.DefaultAccountAccess == 'None',
        'A1 Household (Account) default access is Private (found: ' + org.DefaultAccountAccess + ')');
    failures += check(org.DefaultContactAccess == 'ControlledByParent',
        'A2 Patient (Contact) default access is Controlled by Parent (found: ' + org.DefaultContactAccess + ')');

    Map<String, String> expected = new Map<String, String>{
        'Village__c' => 'Read',
        'Health_Visit__c' => 'ControlledByParent',
        'Medical_Recommendation__c' => 'ControlledByParent',
        'Care_Activity__c' => 'ControlledByParent',
        'Consent__c' => 'ControlledByParent',
        'Notification__c' => 'ControlledByParent',
        'Consent_Event__c' => 'Private',
        'Error_Log__c' => 'Private'
    };
    Set<String> objectNames = expected.keySet();
    try {
        List<SObject> definitions = Database.query(
            'SELECT QualifiedApiName, InternalSharingModel FROM EntityDefinition WHERE QualifiedApiName IN :objectNames');
        for (SObject d : definitions) {
            String name = String.valueOf(d.get('QualifiedApiName'));
            String actual = String.valueOf(d.get('InternalSharingModel'));
            failures += check(actual == expected.get(name),
                'A3 ' + name + ' sharing is ' + expected.get(name) + ' (found: ' + actual + ')');
        }
    } catch (Exception e) {
        say('INFO  A3 could not read object sharing models (' + e.getMessage() + '). Check them in Setup > Sharing Settings.');
    }
    return failures;
}

// ---------------------------------------------------------------- B. Roles
Map<String, UserRole> findRoles() {
    Map<String, UserRole> found = new Map<String, UserRole>();
    Set<String> wanted = new Set<String>{ 'programmeoffice', 'medicalofficer', 'healthworkernorth', 'healthworkersouth' };
    for (UserRole r : [SELECT Id, Name, DeveloperName, ParentRoleId FROM UserRole]) {
        String key = normalise(r.Name);
        if (wanted.contains(key)) {
            found.put(key, r);
        }
    }
    return found;
}

Integer checkRoles(Map<String, UserRole> roles) {
    Integer failures = 0;
    for (String key : new List<String>{ 'programmeoffice', 'medicalofficer', 'healthworkernorth', 'healthworkersouth' }) {
        UserRole r = roles.get(key);
        failures += check(r != null, 'B1 Role exists: ' + key + (r == null ? '' : ' -> ' + r.Name + ' (API name ' + r.DeveloperName + ')'));
    }
    if (failures > 0) {
        return failures;
    }
    Id office = roles.get('programmeoffice').Id;
    Id medical = roles.get('medicalofficer').Id;
    failures += check(roles.get('medicalofficer').ParentRoleId == office, 'B2 Medical Officer reports to Programme Office');
    failures += check(roles.get('healthworkernorth').ParentRoleId == medical, 'B3 Health Worker - North reports to Medical Officer');
    failures += check(roles.get('healthworkersouth').ParentRoleId == medical, 'B4 Health Worker - South reports to Medical Officer');
    return failures;
}

// ---------------------------------------------------------------- C + D. Users and permission sets
Map<String, Id> findUsers() {
    Map<String, String> usernames = new Map<String, String>{
        'meena' => usernameFor('Meena', 'Iyer'),
        'arjun' => usernameFor('Arjun', 'Reddy'),
        'lakshmi' => usernameFor('Lakshmi', 'Devi'),
        'sunita' => usernameFor('Sunita', 'Rao')
    };
    Map<String, Id> byUsername = new Map<String, Id>();
    for (User u : [SELECT Id, Username FROM User WHERE Username IN :usernames.values()]) {
        byUsername.put(u.Username.toLowerCase(), u.Id);
    }
    Map<String, Id> result = new Map<String, Id>();
    for (String key : usernames.keySet()) {
        if (byUsername.containsKey(usernames.get(key))) {
            result.put(key, byUsername.get(usernames.get(key)));
        }
    }
    return result;
}

Integer checkUsers(Map<String, Id> userIds, Map<String, UserRole> roles) {
    Integer failures = 0;
    Map<String, String> roleOf = new Map<String, String>{
        'meena' => 'programmeoffice', 'arjun' => 'medicalofficer',
        'lakshmi' => 'healthworkernorth', 'sunita' => 'healthworkersouth'
    };
    Map<String, String> permsetOf = new Map<String, String>{
        'meena' => 'CareLoop_Programme_Manager', 'arjun' => 'CareLoop_Doctor',
        'lakshmi' => 'CareLoop_Health_Worker', 'sunita' => 'CareLoop_Health_Worker'
    };
    Map<Id, User> users = new Map<Id, User>([
        SELECT Id, Name, IsActive, Profile.Name, Profile.UserLicense.Name, UserRoleId, ManagerId
        FROM User WHERE Id IN :userIds.values()]);
    Set<String> assignments = new Set<String>();
    for (PermissionSetAssignment a : [SELECT AssigneeId, PermissionSet.Name FROM PermissionSetAssignment
                                      WHERE AssigneeId IN :userIds.values() AND PermissionSet.Name LIKE 'CareLoop%']) {
        assignments.add(String.valueOf(a.AssigneeId) + ':' + a.PermissionSet.Name);
    }
    for (String key : new List<String>{ 'meena', 'arjun', 'lakshmi', 'sunita' }) {
        if (!userIds.containsKey(key)) {
            failures += check(false, 'C1 User ' + key + ' exists (run phase2-provision-users.apex)');
            continue;
        }
        User u = users.get(userIds.get(key));
        UserRole expectedRole = roles.get(roleOf.get(key));
        failures += check(u.IsActive, 'C1 ' + u.Name + ' is active');
        failures += check(u.Profile.UserLicense.Name == 'Salesforce Platform',
            'C2 ' + u.Name + ' uses the Salesforce Platform licence (found: ' + u.Profile.UserLicense.Name + ')');
        failures += check(u.Profile.Name == 'CareLoop Platform Staff', 'C3 ' + u.Name + ' has profile CareLoop Platform Staff (found: ' + u.Profile.Name + ')');
        failures += check(expectedRole != null && u.UserRoleId == expectedRole.Id, 'C4 ' + u.Name + ' has role ' + roleOf.get(key));
        if (key != 'meena') {
            failures += check(u.ManagerId == userIds.get('meena'), 'C5 ' + u.Name + ' reports to Meena Iyer (manager field)');
        }
        failures += check(assignments.contains(String.valueOf(u.Id) + ':' + permsetOf.get(key)),
            'C6 ' + u.Name + ' has permission set ' + permsetOf.get(key));
        failures += check(!assignments.contains(String.valueOf(u.Id) + ':CareLoop_Admin'), 'C7 ' + u.Name + ' does NOT have CareLoop_Admin');
    }
    failures += checkEffectivePermissions(userIds);
    Integer bypassHolders = [SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSet.Name = 'CareLoop_Validation_Bypass'];
    failures += check(bypassHolders == 0, 'D1 Nobody holds CareLoop_Validation_Bypass (holders: ' + bypassHolders + ')');
    Integer adminHolds = [SELECT COUNT() FROM PermissionSetAssignment
                          WHERE PermissionSet.Name = 'CareLoop_Admin' AND AssigneeId = :UserInfo.getUserId()];
    failures += check(adminHolds == 1, 'D2 You hold CareLoop_Admin');
    return failures;
}

// Effective object permissions = profile + every assigned permission set, combined.
// (PermissionSetAssignment also lists the hidden permission set that holds each profile's permissions.)
Integer checkEffectivePermissions(Map<String, Id> userIds) {
    Integer failures = 0;
    Map<Id, String> personaOfUser = new Map<Id, String>();
    for (String key : userIds.keySet()) {
        personaOfUser.put(userIds.get(key), key);
    }
    Map<Id, Set<Id>> permsetsOfUser = new Map<Id, Set<Id>>();
    Set<Id> allPermsets = new Set<Id>();
    for (PermissionSetAssignment a : [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds.values()]) {
        if (!permsetsOfUser.containsKey(a.AssigneeId)) {
            permsetsOfUser.put(a.AssigneeId, new Set<Id>());
        }
        permsetsOfUser.get(a.AssigneeId).add(a.PermissionSetId);
        allPermsets.add(a.PermissionSetId);
    }
    // effective.get(userId).get('Account') -> set of granted actions, e.g. {'Read','Create'}
    Map<Id, Map<String, Set<String>>> effective = new Map<Id, Map<String, Set<String>>>();
    List<ObjectPermissions> grants = [
        SELECT ParentId, SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
        FROM ObjectPermissions
        WHERE ParentId IN :allPermsets
          AND SobjectType IN ('Account', 'Contact', 'Village__c', 'Health_Visit__c', 'Care_Activity__c',
                              'Medical_Recommendation__c', 'Consent__c', 'Consent_Event__c', 'Notification__c', 'Error_Log__c')
    ];
    for (Id userId : permsetsOfUser.keySet()) {
        Map<String, Set<String>> byObject = new Map<String, Set<String>>();
        for (ObjectPermissions op : grants) {
            if (!permsetsOfUser.get(userId).contains(op.ParentId)) {
                continue;
            }
            if (!byObject.containsKey(op.SobjectType)) {
                byObject.put(op.SobjectType, new Set<String>());
            }
            if (op.PermissionsRead) { byObject.get(op.SobjectType).add('Read'); }
            if (op.PermissionsCreate) { byObject.get(op.SobjectType).add('Create'); }
            if (op.PermissionsEdit) { byObject.get(op.SobjectType).add('Edit'); }
            if (op.PermissionsDelete) { byObject.get(op.SobjectType).add('Delete'); }
        }
        effective.put(userId, byObject);
    }
    // persona -> object -> exactly the actions expected (from the Phase 1 permission sets)
    Set<String> noAccess = new Set<String>();
    Set<String> r = new Set<String>{ 'Read' };
    Set<String> re = new Set<String>{ 'Read', 'Edit' };
    Set<String> rce = new Set<String>{ 'Read', 'Create', 'Edit' };
    Set<String> rced = new Set<String>{ 'Read', 'Create', 'Edit', 'Delete' };
    Map<String, Map<String, Set<String>>> expected = new Map<String, Map<String, Set<String>>>{
        'lakshmi' => new Map<String, Set<String>>{
            'Account' => rce, 'Contact' => rce, 'Village__c' => r, 'Health_Visit__c' => rce,
            'Care_Activity__c' => rce, 'Medical_Recommendation__c' => r, 'Consent__c' => r,
            'Consent_Event__c' => r, 'Notification__c' => r, 'Error_Log__c' => noAccess
        },
        'arjun' => new Map<String, Set<String>>{
            'Account' => r, 'Contact' => re, 'Village__c' => r, 'Health_Visit__c' => re,
            'Care_Activity__c' => rce, 'Medical_Recommendation__c' => rce, 'Consent__c' => r,
            'Consent_Event__c' => r, 'Notification__c' => r, 'Error_Log__c' => noAccess
        },
        'meena' => new Map<String, Set<String>>{
            'Account' => r, 'Contact' => re, 'Village__c' => rced, 'Health_Visit__c' => r,
            'Care_Activity__c' => re, 'Medical_Recommendation__c' => r, 'Consent__c' => r,
            'Consent_Event__c' => r, 'Notification__c' => r, 'Error_Log__c' => r
        }
    };
    expected.put('sunita', expected.get('lakshmi'));
    Map<String, String> objectLabel = new Map<String, String>{
        'Account' => 'Households', 'Contact' => 'Patients', 'Village__c' => 'Villages',
        'Health_Visit__c' => 'Health Visits', 'Care_Activity__c' => 'Care Activities',
        'Medical_Recommendation__c' => 'Doctor Recommendations', 'Consent__c' => 'Consents',
        'Consent_Event__c' => 'Consent Events', 'Notification__c' => 'Notifications', 'Error_Log__c' => 'Error Logs'
    };
    for (String key : new List<String>{ 'meena', 'arjun', 'lakshmi', 'sunita' }) {
        if (!userIds.containsKey(key)) {
            continue;
        }
        Map<String, Set<String>> actualByObject = effective.containsKey(userIds.get(key))
            ? effective.get(userIds.get(key)) : new Map<String, Set<String>>();
        for (String objectName : expected.get(key).keySet()) {
            Set<String> want = expected.get(key).get(objectName);
            Set<String> have = actualByObject.containsKey(objectName) ? actualByObject.get(objectName) : new Set<String>();
            List<String> wantList = new List<String>(want);
            List<String> haveList = new List<String>(have);
            wantList.sort();
            haveList.sort();
            failures += check(want.equals(have), 'C8 ' + key + ' on ' + objectLabel.get(objectName) + ': expected ['
                + String.join(wantList, ', ') + '], effective [' + String.join(haveList, ', ') + ']');
        }
    }
    return failures;
}

// ---------------------------------------------------------------- E. Record visibility
// Returns -1 when the test records are missing (visibility not tested).
Integer checkVisibility(Map<String, Id> userIds) {
    List<Account> households = [SELECT Id, Name FROM Account WHERE Name LIKE 'ZZ Access Test%'];
    List<Village__c> villages = [SELECT Id FROM Village__c WHERE Name = 'ZZ Access Test Village'];
    List<Error_Log__c> logs = [SELECT Id FROM Error_Log__c WHERE Source__c = 'ZZ Access Test'];
    if (households.size() != 2 || villages.isEmpty() || logs.isEmpty() || userIds.size() != 4) {
        say('SKIP  E  Record visibility not tested: run phase2-access-fixtures.apex first.');
        return -1;
    }

    // label -> record Id, and label -> users who should be able to read it
    Map<String, Id> records = new Map<String, Id>();
    Map<String, Set<String>> readers = new Map<String, Set<String>>();
    Set<String> northReaders = new Set<String>{ 'lakshmi', 'arjun', 'meena' };
    Set<String> southReaders = new Set<String>{ 'sunita', 'arjun', 'meena' };
    Map<Id, String> regionOfHousehold = new Map<Id, String>();
    for (Account a : households) {
        String region = a.Name.contains('North') ? 'North' : 'South';
        regionOfHousehold.put(a.Id, region);
        records.put(region + ' household', a.Id);
        readers.put(region + ' household', region == 'North' ? northReaders : southReaders);
    }
    Map<Id, String> regionOfPatient = new Map<Id, String>();
    for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :regionOfHousehold.keySet()]) {
        String region = regionOfHousehold.get(c.AccountId);
        regionOfPatient.put(c.Id, region);
        records.put(region + ' patient', c.Id);
        readers.put(region + ' patient', region == 'North' ? northReaders : southReaders);
    }
    for (Health_Visit__c v : [SELECT Id, Patient__c FROM Health_Visit__c WHERE Patient__c IN :regionOfPatient.keySet()]) {
        String region = regionOfPatient.get(v.Patient__c);
        records.put(region + ' outreach visit', v.Id);
        readers.put(region + ' outreach visit', region == 'North' ? northReaders : southReaders);
    }
    for (Care_Activity__c a : [SELECT Id, Patient__c FROM Care_Activity__c
                               WHERE Patient__c IN :regionOfPatient.keySet() AND Name = 'Access test check-up']) {
        String region = regionOfPatient.get(a.Patient__c);
        records.put(region + ' care activity', a.Id);
        readers.put(region + ' care activity', region == 'North' ? northReaders : southReaders);
    }
    records.put('test village', villages[0].Id);
    readers.put('test village', new Set<String>{ 'lakshmi', 'sunita', 'arjun', 'meena' });
    records.put('error log', logs[0].Id);
    readers.put('error log', new Set<String>{ 'meena' });

    Set<Id> recordIds = new Set<Id>(records.values());
    Map<String, String> displayName = new Map<String, String>{
        'meena' => 'Meena (Programme Manager)', 'arjun' => 'Arjun (Doctor)',
        'lakshmi' => 'Lakshmi (Health Worker North)', 'sunita' => 'Sunita (Health Worker South)'
    };
    Integer failures = 0;
    for (String userKey : new List<String>{ 'lakshmi', 'sunita', 'arjun', 'meena' }) {
        Id userId = userIds.get(userKey);
        Map<Id, Boolean> canRead = new Map<Id, Boolean>();
        for (UserRecordAccess access : [SELECT RecordId, HasReadAccess FROM UserRecordAccess
                                        WHERE UserId = :userId AND RecordId IN :recordIds]) {
            canRead.put(access.RecordId, access.HasReadAccess);
        }
        List<String> labels = new List<String>(records.keySet());
        labels.sort();
        for (String label : labels) {
            Boolean expected = readers.get(label).contains(userKey);
            Boolean actual = canRead.get(records.get(label)) == true;
            failures += check(expected == actual, 'E  ' + displayName.get(userKey) + (expected ? ' CAN ' : ' CANNOT ')
                + 'read ' + label + (expected == actual ? '' : '  <-- actual: ' + (actual ? 'can read' : 'cannot read')));
        }
    }
    return failures;
}

// ---------------------------------------------------------------- main
Map<String, UserRole> roles = findRoles();
Map<String, Id> userIds = findUsers();
Integer failures = checkSharing() + checkRoles(roles) + checkUsers(userIds, roles);
Integer visibility = checkVisibility(userIds);
if (visibility > 0) {
    failures += visibility;
}
if (failures > 0) {
    say('PHASE 2 SECURITY PROBLEMS: ' + failures + ' check(s) failed. Send this output to your mentor/handbook troubleshooting.');
} else if (visibility < 0) {
    say('PHASE 2 SECURITY CONFIG OK - record visibility not yet tested (run phase2-access-fixtures.apex, then this script again)');
} else {
    say('PHASE 2 SECURITY OK');
}
