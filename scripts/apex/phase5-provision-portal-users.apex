// =====================================================================================
// HealthConnect CareLoop - Phase 5: create the demo patient portal users (Kavya and Venkat Rao)
// =====================================================================================
// PREVIEW by default (changes nothing). To create the users, change applyChanges() to return true,
// save, run again, then set it back to false.
//
// What it does (APPLY):
//   * creates an Experience Cloud user for each demo patient Contact, with the profile
//     "CareLoop Patient Portal User" (your clone of Customer Community Login User, step P5-4)
//     -> uses 2 of your 5 Customer Community Login licences
//   * assigns the CareLoop_Patient permission set
//   * username kavya.rao.<org id>@careloop.demo (a login name only; careloop.demo is not a mail domain),
//     e-mail = YOUR address, no welcome e-mail sent
// IRREVERSIBLE PART: users cannot be deleted, only deactivated (Setup > Users > Edit > Active).
// Safe to re-run: existing users are found by username and not duplicated.
//
// Run:
//   sf apex run --file scripts/apex/phase5-provision-portal-users.apex --target-org careloop | Select-String "USER_DEBUG"
// =====================================================================================

Boolean applyChanges() {
    return false;   // <-- change false to true to create the portal users
}

String portalProfileName() {
    return 'CareLoop Patient Portal User';
}

void say(String line) {
    System.debug(LoggingLevel.ERROR, 'PORTAL ' + line);
}

void run(Boolean apply) {
    say('MODE    | ' + (apply ? 'APPLY - users will be created' : 'PREVIEW - nothing will be changed'));
    List<Profile> profiles = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :portalProfileName() LIMIT 1];
    if (profiles.isEmpty()) {
        say('STOP    | Profile "' + portalProfileName() + '" not found. Do handbook step P5-4 first.');
        return;
    }
    say('OK      | Profile uses licence ' + profiles[0].UserLicense.Name);
    List<Contact> patients = [SELECT Id, FirstName, LastName, AccountId, Account.Owner.UserRoleId, Account.Owner.Name
                              FROM Contact WHERE Account.Name = 'Rao Household' AND FirstName IN ('Kavya', 'Venkat')];
    if (patients.size() != 2) {
        say('STOP    | Kavya and Venkat Rao not found in "Rao Household" (run phase3-demo-household.apex).');
        return;
    }
    if (patients[0].Account.Owner.UserRoleId == null) {
        say('STOP    | The household owner ' + patients[0].Account.Owner.Name + ' has no role. Portal users need a household owner with a role.');
        return;
    }
    List<UserLicense> lic = [SELECT TotalLicenses, UsedLicenses FROM UserLicense WHERE Name = :profiles[0].UserLicense.Name];
    Integer free = lic.isEmpty() ? 0 : lic[0].TotalLicenses - lic[0].UsedLicenses;

    User me = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Contact> byUsername = new Map<String, Contact>();
    for (Contact c : patients) {
        byUsername.put((c.FirstName + '.' + c.LastName + '.' + UserInfo.getOrganizationId()).toLowerCase() + '@careloop.demo', c);
    }
    Map<String, User> existing = new Map<String, User>();
    for (User u : [SELECT Id, Username, IsActive FROM User WHERE Username IN :byUsername.keySet()]) {
        existing.put(u.Username, u);
    }
    List<User> toCreate = new List<User>();
    for (String username : byUsername.keySet()) {
        Contact c = byUsername.get(username);
        if (existing.containsKey(username)) {
            say('EXISTS  | ' + c.FirstName + ' ' + c.LastName + ' (' + username + ', active=' + existing.get(username).IsActive + ')');
            continue;
        }
        say('PLAN    | CREATE portal user for ' + c.FirstName + ' ' + c.LastName + ' | username ' + username);
        toCreate.add(new User(
            ContactId = c.Id, ProfileId = profiles[0].Id, Username = username, Email = me.Email,
            FirstName = c.FirstName, LastName = c.LastName,
            Alias = (c.FirstName.left(4) + c.LastName.left(3)).toLowerCase(),
            CommunityNickname = ('careloop.' + c.FirstName + '.' + String.valueOf(c.Id).right(5)).toLowerCase(),
            TimeZoneSidKey = 'Asia/Kolkata', LocaleSidKey = 'en_IN', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8'
        ));
    }
    say('OK      | Free ' + profiles[0].UserLicense.Name + ' licences: ' + free + ' | needed: ' + toCreate.size());
    if (toCreate.size() > free) {
        say('STOP    | Not enough licences.');
        return;
    }
    if (!apply) {
        say('PREVIEW ONLY | Nothing changed. Set applyChanges() to true and run again.');
        return;
    }
    if (!toCreate.isEmpty()) {
        Database.DMLOptions options = new Database.DMLOptions();
        options.EmailHeader.triggerUserEmail = false;
        List<Database.SaveResult> results = Database.insert(toCreate, options);
        for (Integer i = 0; i < results.size(); i++) {
            say((results[i].isSuccess() ? 'DONE    | created ' : 'ERROR   | ') + toCreate[i].Username
                + (results[i].isSuccess() ? '' : ' ' + results[i].getErrors()[0].getMessage()));
        }
    }
    PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CareLoop_Patient'];
    Set<Id> userIds = new Map<Id, User>([SELECT Id FROM User WHERE Username IN :byUsername.keySet()]).keySet();
    Set<Id> assigned = new Set<Id>();
    for (PermissionSetAssignment a : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id AND AssigneeId IN :userIds]) {
        assigned.add(a.AssigneeId);
    }
    List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
    for (Id userId : userIds) {
        if (!assigned.contains(userId)) {
            psas.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id));
        }
    }
    insert psas;
    say('DONE    | assigned CareLoop_Patient to ' + psas.size() + ' user(s)');
    say('FINISHED | Next: add the profile to the site members (P5-6), then "Log in to Experience as User" from Kavya\'s record.');
}

run(applyChanges());
