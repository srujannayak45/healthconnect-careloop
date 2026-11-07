# HealthConnect CareLoop – Phase 5: Patient Engagement (portal, consent ledger, SMS integration)

Experience Cloud patient portal (LWC): the patient sees her own and her children's care, reminders (in her language), visits and the doctor's advice, replies with one tap (I will come / another date / done elsewhere / I need help) and switches reminders on or off. Replies create tasks and bells for the health worker. Hash-chained, append-only consent ledger with integrity verification. SMS delivery through a Named Credential callout (Queueable with callouts).

## Prerequisites

Phase 4 completed and committed. Org alias `careloop`. Salesforce CLI logged in.

## Files

**New:**
* `force-app/main/default/classes/: ConsentService, ConsentEventTriggerHandler, ConsentLedgerController, PatientPortalService, PatientPortalController, PatientResponseService, NotificationDispatchQueueable, NotificationTriggerHandler, SmsProvider, SmsResult, SimulatedSmsProvider, HttpSmsProvider + 3 test classes`
* `force-app/main/default/triggers/ConsentEventTrigger, NotificationTrigger`
* `force-app/main/default/lwc/patientPortalHome, lwc/consentLedger`
* `scripts/apex/phase5-provision-portal-users.apex, phase5-backfill-consent-ledger.apex, phase5-dispatch-now.apex, phase5-test-sms-callout.apex, phase5-verify.apex`

**Replaced (complete updated versions of existing files):**
* `force-app/main/default/flexipages/CareLoop_Patient_Record_Page (consent ledger added)`
* `force-app/main/default/permissionsets/ (5 files: Phase 4 content + portal/ledger class access)`

## Install (Windows PowerShell, from the project folder)

```powershell
cd C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop
git status                      # must say "nothing to commit, working tree clean"
Expand-Archive -Path "$HOME\Downloads\healthconnect-careloop-phase5-incremental.zip" -DestinationPath . -Force
git status                      # new files (untracked) + the replaced files listed below (modified)
git diff --stat                 # review what changed in existing files
```
`-Force` is needed because this package replaces existing files (listed below). Because your tree was clean,
`git checkout -- <file>` restores any of them, and `git clean -n` lists the new files.

## Deploy (check-only first)

Deploy only these paths. **Do not deploy the whole `force-app` folder**: it would also redeploy the
CareLoop Setting custom-metadata record and reset what you set in Setup (demo clock, SMS provider).

```powershell
sf project deploy validate --target-org careloop --test-level RunLocalTests --wait 30 `
  --source-dir force-app/main/default/classes `
  --source-dir force-app/main/default/triggers `
  --source-dir force-app/main/default/lwc `
  --source-dir force-app/main/default/flexipages `
  --source-dir force-app/main/default/permissionsets
sf project deploy quick --use-most-recent --target-org careloop
```

## Manual Setup steps

1. **P5-2 Enable Digital Experiences** (Setup → Digital Experiences → Settings): tick *Enable Digital Experiences*, choose a domain name, Save. **Cannot be switched off again.**
2. **P5-3 Create the site**: Setup → Digital Experiences → All Sites → New → *Build Your Own (LWR)* → name `HealthConnect`, URL `healthconnect` → Create.
3. **P5-4 Portal profile**: Setup → Profiles → *Customer Community Login User* → Clone → `CareLoop Patient Portal User`.
4. **P5-5 Provision portal users**: preview, then apply `phase5-provision-portal-users.apex`.
5. **P5-6 Members**: site Administration → Members → add profile `CareLoop Patient Portal User`.
6. **P5-7 Page**: Experience Builder → Home page → drag **CareLoop Patient Home** into the content area → Publish; Administration → Settings → Activate.
7. **P5-8 Named Credential**: External Credential `CareLoop SMS` (Custom), principal `CareLoopSmsPrincipal`; Named Credential `CareLoop_SMS` URL `https://postman-echo.com` using it; new permission set `CareLoop SMS Integration` with External Credential Principal Access → assign to yourself. Then CareLoop Setting → Default → SMS Provider Class = `HttpSmsProvider`.

## Run, verify, demo

```powershell
sf apex run --file scripts/apex/phase5-backfill-consent-ledger.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase5-test-sms-callout.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase5-dispatch-now.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/phase5-verify.apex --target-org careloop | Select-String "USER_DEBUG"
```
Expected: `PHASE 5 VERIFY PASSED` once all setup items are done (`PHASE 5 LOGIC OK - n setup item(s) still TODO` before).

## Known limitations

* The SMS gateway is an echo service: the callout is real, no SMS reaches a phone. A production gateway needs DLT registration in India.
* Portal pages show English labels; reminder texts are in the patient's language.
* The consent ledger is tamper-evident (detects changes), not tamper-proof.

## Rollback

Nothing changes in the org until `deploy quick`. After deployment: restore the replaced files with `git checkout`, delete the new
files, and redeploy the restored files; or delete new triggers with `sf project delete source --metadata ApexTrigger:<Name> --target-org careloop`.
Details: handbook section 8.
