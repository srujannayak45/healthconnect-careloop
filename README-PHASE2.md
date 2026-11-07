# HealthConnect CareLoop – Phase 2 incremental package (Security & users)

This package finishes Phase 2. It adds **only new files**. It does not change any Phase 0/1 file.

## What it contains

| File | What it does | Changes the org? |
|---|---|---|
| `scripts/apex/phase2-provision-users.apex` | Creates/updates the four staff users, roles, managers and permission-set assignments. **Preview by default.** | Only when `applyChanges()` returns `true` |
| `scripts/apex/phase2-verify-security.apex` | Read-only checks: sharing defaults, roles, users, licences, profile, effective object permissions, bypass holders, record-visibility matrix | No |
| `scripts/apex/phase2-access-fixtures.apex` | Creates temporary `ZZ Access Test` records (one North and one South household) for the visibility matrix | Yes (temporary records) |
| `scripts/apex/phase2-remove-access-fixtures.apex` | Deletes the `ZZ Access Test` records again and empties them from the Recycle Bin | Yes (deletes only `ZZ Access Test` records) |

## Install (Windows PowerShell, from the project folder)

```powershell
cd C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop
Expand-Archive -Path "$HOME\Downloads\healthconnect-careloop-phase2-incremental.zip" -DestinationPath .
git status
```

`Expand-Archive` refuses to overwrite existing files. If it reports that a file already exists, stop and check before re-running.
`git status` should list only `README-PHASE2.md` and the four new `scripts/apex/phase2-*.apex` files.

## Order of use (details and expected output: handbook section 2)

1. **P2-7** Clone *Standard Platform User* as **CareLoop Platform Staff** and remove its Create/Edit/Delete on Accounts and Contacts and all access to CareLoop custom objects (Setup UI).
2. Preview: `sf apex run --file scripts/apex/phase2-provision-users.apex --target-org careloop | Select-String "USER_DEBUG"`
3. Apply: change `return false;` to `return true;` in `applyChanges()`, save, run the same command again, then change it back to `false`.
4. Verify configuration: `sf apex run --file scripts/apex/phase2-verify-security.apex --target-org careloop | Select-String "USER_DEBUG"` → last line `PHASE 2 SECURITY CONFIG OK - record visibility not yet tested`.
5. Fixtures: `sf apex run --file scripts/apex/phase2-access-fixtures.apex --target-org careloop | Select-String "USER_DEBUG"`
6. Verify again → last line `PHASE 2 SECURITY OK`.
7. Login As each user (handbook P2-13).
8. Remove fixtures: `sf apex run --file scripts/apex/phase2-remove-access-fixtures.apex --target-org careloop | Select-String "USER_DEBUG"`
9. Commit (handbook P2-16).

## Safety notes

* Usernames look like `meena.iyer.<your-org-id>@careloop.demo`. They are login identifiers only. `careloop.demo` is not a real mail domain; the users' e-mail is set to **your own** address so that any system mail reaches you. No welcome e-mails are sent.
* **Irreversible:** Salesforce users cannot be deleted, only deactivated; a username stays reserved forever. That is why provisioning has a preview mode. Each user consumes one *Salesforce Platform* licence (4 of your 6); deactivating a user frees its licence.
* `CareLoop_Validation_Bypass` is never assigned. `CareLoop_Admin` stays only on your own user.
* OrgFarm EPIC and the Analytics Cloud Integration users are never queried for changes or modified.
