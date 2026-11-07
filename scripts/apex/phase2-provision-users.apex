// =====================================================================================
// HealthConnect CareLoop - Phase 2: provision the four CareLoop staff users
// =====================================================================================
// For each of Meena Iyer, Arjun Reddy, Lakshmi Devi and Sunita Rao this script:
//   * creates the user if missing (licence Salesforce Platform, profile CareLoop Platform Staff,
//     the stripped-down clone of Standard Platform User you create in handbook step P2-7)
//   * sets the CareLoop role (and re-activates the user if someone deactivated it)
//   * sets the manager to Meena Iyer (for Arjun, Lakshmi and Sunita)
//   * assigns the CareLoop permission set, only if it is not already assigned
// It also gives YOUR user the Programme Office role, but only if you have no role yet.
//
// SAFE TO RE-RUN: users are found by username and assignments are checked first,
// so a second run changes nothing that is already correct.
// NO E-MAILS: no welcome or password e-mails are sent. You test each user with "Login As".
//
// IRREVERSIBLE PART: Salesforce never deletes users. A created user can only be
// deactivated, and its username stays reserved. That is why this script has a preview mode.
//
// HOW TO RUN
//   1. Run it once as it is (preview). Read the plan it prints.
//   2. Change applyChanges() below from false to true, save the file, run it again.
//   sf apex run --file scripts/apex/phase2-provision-users.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

Boolean applyChanges() {
    return false;   // <-- change false to true to create the users
}

String staffProfileName() {
    return 'CareLoop Platform Staff';   // created in handbook step P2-7
}

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'PROVISION ' + line);
}

// "Health Worker – North" -> "healthworkernorth": matches roles whatever dash or spacing was used.
String normalise(String value) {
    return value == null ? '' : value.toLowerCase().replaceAll('[^a-z]', '');
}

// Usernames must be unique across ALL Salesforce orgs, so they include your org's Id.
// They are login identifiers only: the careloop.demo domain receives no e-mail.
String usernameFor(Map<String, String> persona) {
    return (persona.get('first') + '.' + persona.get('last') + '.' + UserInfo.getOrganizationId()).toLowerCase()
        + '@careloop.demo';
}

List<Map<String, String>> personas() {
    return new List<Map<String, String>>{
        new Map<String, String>{
            'key' => 'meena', 'first' => 'Meena', 'last' => 'Iyer', 'alias' => 'miyer',
            'title' => 'District Programme Manager', 'role' => 'programmeoffice',
            'permset' => 'CareLoop_Programme_Manager', 'manager' => ''
        },
        new Map<String, String>{
            'key' => 'arjun', 'first' => 'Arjun', 'last' => 'Reddy', 'alias' => 'areddy',
            'title' => 'Medical Officer (PHC)', 'role' => 'medicalofficer',
            'permset' => 'CareLoop_Doctor', 'manager' => 'meena'
        },
        new Map<String, String>{
            'key' => 'lakshmi', 'first' => 'Lakshmi', 'last' => 'Devi', 'alias' => 'ldevi',
            'title' => 'Health Worker (North)', 'role' => 'healthworkernorth',
            'permset' => 'CareLoop_Health_Worker', 'manager' => 'meena'
        },
        new Map<String, String>{
            'key' => 'sunita', 'first' => 'Sunita', 'last' => 'Rao', 'alias' => 'srao',
            'title' => 'Health Worker (South)', 'role' => 'healthworkersouth',
            'permset' => 'CareLoop_Health_Worker', 'manager' => 'meena'
        }
    };
}

// Prints one line per result; returns true if anything failed.
Boolean report(List<Database.SaveResult> results, List<String> labels) {
    Boolean failed = false;
    for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
            say('DONE  | ' + labels[i]);
        } else {
            failed = true;
            List<String> messages = new List<String>();
            for (Database.Error e : results[i].getErrors()) {
                messages.add(e.getStatusCode() + ': ' + e.getMessage());
            }
            say('ERROR | ' + labels[i] + ' | ' + String.join(messages, '; '));
        }
    }
    return failed;
}

void run(Boolean apply) {
    List<Map<String, String>> people = personas();
    say('MODE  | ' + (apply ? 'APPLY - changes will be made' : 'PREVIEW - nothing will be changed'));

    // ---- 1. Profile: must exist, use the Platform licence, and grant nothing on Households/Patients
    String profileName = staffProfileName();
    List<Profile> profiles = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :profileName LIMIT 1];
    if (profiles.isEmpty()) {
        say('STOP  | Profile "' + profileName + '" was not found. Do handbook step P2-7 (clone Standard Platform User) first.');
        return;
    }
    Profile platformProfile = profiles[0];
    if (platformProfile.UserLicense.Name != 'Salesforce Platform') {
        say('STOP  | Profile "' + profileName + '" uses licence ' + platformProfile.UserLicense.Name
            + '. Clone it from Standard Platform User so it uses Salesforce Platform.');
        return;
    }
    say('OK    | Profile ' + profileName + ' uses licence ' + platformProfile.UserLicense.Name);
    // Standard Platform User grants Create/Edit/Delete on Accounts and Contacts (and may grant
    // full access to custom objects). Profiles and permission sets ADD UP, so anything the profile
    // grants would override the narrower permission sets. The cloned profile must grant none of it.
    Boolean profileTooOpen = false;
    Set<String> careLoopObjects = new Set<String>{
        'Account', 'Contact', 'Village__c', 'Health_Visit__c', 'Care_Activity__c', 'Medical_Recommendation__c',
        'Consent__c', 'Consent_Event__c', 'Notification__c', 'Error_Log__c'
    };
    for (ObjectPermissions op : [SELECT SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete,
                                        PermissionsViewAllRecords, PermissionsModifyAllRecords
                                 FROM ObjectPermissions
                                 WHERE Parent.ProfileId = :platformProfile.Id AND SobjectType IN :careLoopObjects]) {
        Boolean isStandardObject = op.SobjectType == 'Account' || op.SobjectType == 'Contact';
        Boolean writes = op.PermissionsCreate || op.PermissionsEdit || op.PermissionsDelete
            || op.PermissionsViewAllRecords || op.PermissionsModifyAllRecords;
        if (writes || (!isStandardObject && op.PermissionsRead)) {
            profileTooOpen = true;
            say('STOP  | The profile still grants access on ' + op.SobjectType
                + '. Remove it (handbook step P2-7); the permission sets grant what each role needs.');
        } else if (op.PermissionsRead) {
            say('INFO  | The profile grants Read on ' + op.SobjectType + ' (acceptable: every staff role reads it anyway).');
        }
    }
    if (profileTooOpen) {
        return;
    }

    // ---- 2. Roles (matched by name, ignoring spaces, dashes and capital letters)
    Map<String, List<UserRole>> rolesByKey = new Map<String, List<UserRole>>();
    for (UserRole r : [SELECT Id, Name, DeveloperName FROM UserRole]) {
        String key = normalise(r.Name);
        if (!rolesByKey.containsKey(key)) {
            rolesByKey.put(key, new List<UserRole>());
        }
        rolesByKey.get(key).add(r);
    }
    Map<String, Id> roleIdByPersona = new Map<String, Id>();
    Boolean rolesFound = true;
    for (Map<String, String> p : people) {
        List<UserRole> matches = rolesByKey.get(p.get('role'));
        if (matches == null || matches.size() != 1) {
            rolesFound = false;
            say('STOP  | Expected exactly one role named like "' + p.get('role') + '" for ' + p.get('first')
                + ', found ' + (matches == null ? 0 : matches.size()));
        } else {
            roleIdByPersona.put(p.get('key'), matches[0].Id);
            say('OK    | Role for ' + p.get('first') + ': ' + matches[0].Name + ' (API name ' + matches[0].DeveloperName + ')');
        }
    }
    if (!rolesFound) {
        return;
    }

    // ---- 3. Permission sets
    Map<String, Id> permsetIds = new Map<String, Id>();
    for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet
                             WHERE Name IN ('CareLoop_Programme_Manager', 'CareLoop_Doctor', 'CareLoop_Health_Worker')]) {
        permsetIds.put(ps.Name, ps.Id);
    }
    if (permsetIds.size() != 3) {
        say('STOP  | Expected 3 CareLoop permission sets, found ' + permsetIds.size() + '. Is Phase 1 deployed?');
        return;
    }

    // ---- 4. Existing users and licences
    Map<String, String> usernameByPersona = new Map<String, String>();
    for (Map<String, String> p : people) {
        usernameByPersona.put(p.get('key'), usernameFor(p));
    }
    Map<String, User> existingByUsername = new Map<String, User>();
    for (User u : [SELECT Id, Username, IsActive, ProfileId FROM User WHERE Username IN :usernameByPersona.values()]) {
        existingByUsername.put(u.Username.toLowerCase(), u);
    }
    Integer needLicence = 0;
    for (Map<String, String> p : people) {
        User u = existingByUsername.get(usernameByPersona.get(p.get('key')));
        String action = u == null ? 'CREATE' : (u.IsActive ? 'EXISTS' : 'REACTIVATE');
        if (u == null || !u.IsActive) {
            needLicence++;
        }
        say('PLAN  | ' + action + ' | ' + p.get('first') + ' ' + p.get('last') + ' | ' + p.get('title')
            + ' | username ' + usernameByPersona.get(p.get('key')));
    }
    List<UserLicense> licences = [SELECT TotalLicenses, UsedLicenses FROM UserLicense WHERE Name = 'Salesforce Platform' LIMIT 1];
    if (licences.isEmpty()) {
        say('STOP  | No "Salesforce Platform" licence found in this org.');
        return;
    }
    Integer freeLicences = licences[0].TotalLicenses - licences[0].UsedLicenses;
    say('OK    | Salesforce Platform licences free: ' + freeLicences + ' | needed now: ' + needLicence);
    if (needLicence > freeLicences) {
        say('STOP  | Not enough free Salesforce Platform licences.');
        return;
    }
    say('INFO  | E-mail address on the new users: ' + UserInfo.getUserEmail()
        + ' (your own address, so any system e-mail reaches you; no e-mail is sent by this script)');

    if (!apply) {
        say('PREVIEW ONLY | Nothing was changed. Change applyChanges() to return true, save, and run again.');
        return;
    }

    // ---- 5. Create or update the users (managers are set in step 6, once Meena exists)
    Database.DMLOptions options = new Database.DMLOptions();
    options.EmailHeader.triggerUserEmail = false;
    options.OptAllOrNone = false;

    List<User> toInsert = new List<User>();
    List<String> insertLabels = new List<String>();
    List<User> toUpdate = new List<User>();
    List<String> updateLabels = new List<String>();
    for (Map<String, String> p : people) {
        String username = usernameByPersona.get(p.get('key'));
        User existing = existingByUsername.get(username);
        if (existing == null) {
            toInsert.add(new User(
                FirstName = p.get('first'),
                LastName = p.get('last'),
                Alias = p.get('alias'),
                Username = username,
                Email = UserInfo.getUserEmail(),
                CommunityNickname = 'careloop.' + p.get('key'),
                Title = p.get('title'),
                Department = 'HealthConnect CareLoop',
                CompanyName = 'HealthConnect Outreach (demo)',
                ProfileId = platformProfile.Id,
                UserRoleId = roleIdByPersona.get(p.get('key')),
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_IN',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8'
            ));
            insertLabels.add('created user ' + p.get('first') + ' ' + p.get('last'));
        } else {
            toUpdate.add(new User(
                Id = existing.Id,
                IsActive = true,
                UserRoleId = roleIdByPersona.get(p.get('key')),
                Title = p.get('title')
            ));
            updateLabels.add('checked role and status of ' + p.get('first') + ' ' + p.get('last'));
        }
    }
    Boolean failed = false;
    if (!toInsert.isEmpty()) {
        failed = report(Database.insert(toInsert, options), insertLabels) || failed;
    }
    if (!toUpdate.isEmpty()) {
        failed = report(Database.update(toUpdate, options), updateLabels) || failed;
    }
    if (failed) {
        say('STOP  | Fix the errors above, then run the script again (it is safe to re-run).');
        return;
    }

    // ---- 6. Managers
    Map<String, User> userByPersona = new Map<String, User>();
    Map<String, User> byUsername = new Map<String, User>();
    for (User u : [SELECT Id, Username, ManagerId FROM User WHERE Username IN :usernameByPersona.values()]) {
        byUsername.put(u.Username.toLowerCase(), u);
    }
    for (Map<String, String> p : people) {
        userByPersona.put(p.get('key'), byUsername.get(usernameByPersona.get(p.get('key'))));
    }
    Id meenaId = userByPersona.get('meena').Id;
    List<User> managerUpdates = new List<User>();
    List<String> managerLabels = new List<String>();
    for (Map<String, String> p : people) {
        User u = userByPersona.get(p.get('key'));
        if (p.get('manager') == 'meena' && u.ManagerId != meenaId) {
            managerUpdates.add(new User(Id = u.Id, ManagerId = meenaId));
            managerLabels.add('set manager of ' + p.get('first') + ' to Meena Iyer');
        }
    }
    if (!managerUpdates.isEmpty() && report(Database.update(managerUpdates, options), managerLabels)) {
        say('STOP  | Manager update failed; run the script again after fixing the error.');
        return;
    }

    // ---- 7. Permission set assignments (only the missing ones)
    Set<Id> userIds = new Set<Id>();
    for (User u : userByPersona.values()) {
        userIds.add(u.Id);
    }
    Set<String> alreadyAssigned = new Set<String>();
    for (PermissionSetAssignment a : [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment
                                      WHERE AssigneeId IN :userIds AND PermissionSetId IN :permsetIds.values()]) {
        alreadyAssigned.add(String.valueOf(a.AssigneeId) + ':' + String.valueOf(a.PermissionSetId));
    }
    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
    List<String> assignmentLabels = new List<String>();
    for (Map<String, String> p : people) {
        Id userId = userByPersona.get(p.get('key')).Id;
        Id permsetId = permsetIds.get(p.get('permset'));
        if (alreadyAssigned.contains(String.valueOf(userId) + ':' + String.valueOf(permsetId))) {
            say('EXISTS | ' + p.get('permset') + ' already assigned to ' + p.get('first'));
        } else {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permsetId));
            assignmentLabels.add('assigned ' + p.get('permset') + ' to ' + p.get('first'));
        }
    }
    if (!assignments.isEmpty() && report(Database.insert(assignments, false), assignmentLabels)) {
        say('STOP  | A permission set assignment failed; run the script again after fixing the error.');
        return;
    }

    // ---- 8. Your own role (needed later: portal users require a household owner with a role)
    User me = [SELECT Id, UserRoleId, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
    if (me.UserRoleId == null) {
        List<String> myLabel = new List<String>{ 'gave your user the Programme Office role' };
        report(Database.update(new List<User>{ new User(Id = me.Id, UserRoleId = roleIdByPersona.get('meena')) }, false), myLabel);
    } else {
        say('KEEP  | Your user keeps its current role: ' + me.UserRole.Name);
    }

    say('FINISHED | Provisioning complete. Next: run scripts/apex/phase2-access-fixtures.apex');
}

run(applyChanges());
