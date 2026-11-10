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
