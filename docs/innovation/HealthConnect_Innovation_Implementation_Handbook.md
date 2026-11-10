# HealthConnect CareLoop — CareLoop Sentinel Implementation Handbook

**Innovation:** CareLoop Sentinel, community health early warning (approved 10 Nov 2026)
**Baseline:** commit `5ef9d6a`, Phases 1–7, 123 Apex tests, 89% coverage, 7 verify scripts passing
**Environment:** Windows PowerShell, VS Code, Salesforce CLI (`sf`), Developer Edition org alias `careloop`
**Project folder:** `C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop`

---

## How to use this handbook

- Do **one step at a time**. Each step says **What**, **Why**, **Command**, **Expected**, **Verify** and **If it fails**.
- After each step, paste the full output to Claude **before** moving on. Never assume a step worked.
- Commands are for **PowerShell**. Run them from the project folder unless a step says otherwise.
- The PowerShell prompt shows `PS C:\...>`. Type or paste only the command, not the prompt.
- Lines starting with `#` are comments. Pasting them is harmless.
- **Status words used below:**
  - **Integrated** = the files are in your local project.
  - **Validated** = Salesforce compiled them and ran the tests without saving anything.
  - **Deployed** = the files are in the org.
  - **Verified** = tests, scripts and screens behaved as expected.

### Progress tracker (fill in as you go)

| Phase | Step | Status |
|---|---|---|
| I-0 | Baseline and Git checkpoint | ☐ |
| I-1 | Download, extract and integrate the package | ☐ |
| I-2 | Inspect changes and dependencies; local commit | ☐ |
| I-3 | Check-only validation (org unchanged) | ☐ |
| I-4 | Deploy the validated package | ☐ |
| I-5 | Salesforce UI checks | ☐ |
| I-6 | Permission set assignment | ☐ |
| I-7 | Sentinel Apex tests | ☐ |
| I-8 | Sentinel verification script | ☐ |
| I-9 | Demo data and testing each signal | ☐ |
| I-10 | Thresholds, minimum counts and false-positive checks | ☐ |
| I-11 | Notifications and signal review | ☐ |
| I-12 | Permissions and record visibility | ☐ |
| I-13 | Reports and dashboard | ☐ |
| I-14 | Schedule the daily scan | ☐ |
| I-15 | Full regression of Phases 1–7 | ☐ |
| I-16 | Final commit, push and merge | ☐ |
| I-17 | End-to-end demo rehearsal | ☐ |

### Where each of your 25 requested topics is covered

| # | Topic | Section | # | Topic | Section |
|---|---|---|---|---|---|
| 1 | Prerequisites | P | 14 | Running Apex tests | I-7, I-15 |
| 2 | Git checkpoint and recovery | I-0, R | 15 | Verification scripts | I-8, I-15 |
| 3 | Download and extract | I-1 | 16 | Testing each signal | I-9 |
| 4 | Folder structure | I-1.3, D | 17 | Thresholds and minimum counts | I-10 |
| 5 | Copy and merge safely | I-1.4–I-1.6, I-2 | 18 | False-positive prevention | I-10 |
| 6 | CLI commands | all, summary in Q | 19 | Notifications and review | I-11 |
| 7 | Check-only validation | I-3 | 20 | Permissions and visibility | I-12 |
| 8 | Understanding validation results | I-3.2 | 21 | Reports and dashboard | I-13 |
| 9 | Fixing compile and deploy errors | I-3.3, T | 22 | Regression of Phases 1–7 | I-15 |
| 10 | Incremental deployment | I-4 | 23 | Commit and push | I-16 |
| 11 | UI configuration | I-5 | 24 | End-to-end demo | I-17 |
| 12 | Permission set assignment | I-6 | 25 | Troubleshooting | T |
| 13 | Test data generation | I-9 | | | |

---

## P. Prerequisites

| Item | How to check | Expected |
|---|---|---|
| Phases 1–7 deployed and committed | `git log --oneline -1` | `5ef9d6a …` (or a later commit of yours) |
| Salesforce CLI | `sf --version` | `@salesforce/cli/2.x …` |
| Logged in to the org | `sf org display --target-org careloop` | `Connected Status  Connected` |
| Phase 2 users exist | Setup → Users | Meena Iyer, Arjun Reddy, Lakshmi Devi, Sunita Rao active |
| Phase 4 demo villages | App → Villages | Kondapur, Moinabad, Shamshabad, Kandukur |
| Demo clock | Setup → Custom Metadata Types → CareLoop Setting → Manage Records → Default | *Simulated Today* empty (or today) |
| Report/dashboard folders shared (Phase 7, P7-5) | Reports → CareLoop Reports → Share | All Internal Users: View |
| Time | — | Plan 4–6 hours; decision point at 12:00 on 11 Nov |

---

## I-0 · Baseline and Git checkpoint (org unchanged)

### I-0.1 Inspect the repository (read-only)
- **What:** look at Git's view of your project without changing anything.
- **Why:** we must start from a clean, known commit, so that every later change is visible and can be undone.
- **Command:**
  ```powershell
  cd C:\Users\sruja\OneDrive\Documents\Cognizant-Hackathon\healthconnect-careloop
  git status
  git branch --show-current
  git log --oneline -5
  git remote -v
  git fetch origin
  git status -sb
  ```
- **Expected:**
  - `On branch main` and `nothing to commit, working tree clean`;
  - the newest log line is `5ef9d6a …` (or your later commit);
  - `origin  https://github.com/srujannayak45/healthconnect-careloop.git (fetch/push)`;
  - `## main...origin/main` with no `[ahead n]` or `[behind n]`.
- **Verify:** all four points above.
- **If it fails:**
  - Uncommitted changes: send the `git status` output and do **not** stash or delete anything yet.
  - `ahead`: you have unpushed commits; push them first with `git push`.
  - `behind`: someone pushed; tell Claude before pulling.

### I-0.2 Confirm the org connection
- **What / Why:** make sure every command talks to the right org.
- **Command:** `sf org display --target-org careloop`
- **Expected:** `Connected Status  Connected`, your username, and `Instance Url https://….my.salesforce.com`.
- **If it fails:** `sf org login web --alias careloop` then repeat.

### I-0.3 Baseline Apex tests (no metadata change)
- **What:** run all local tests before adding anything.
- **Why:** proves the starting point is green. Any later failure is then clearly caused by the new work.
- **Command:**
  ```powershell
  sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 30 --target-org careloop
  ```
- **Expected:** `Outcome Passed`, `Tests Ran 123`, `Pass Rate 100%`, `Org Wide Coverage 89%` (± 1%).
- **Verify:** the numbers match your recorded baseline.
- **If it fails:** stop. Fix the baseline first and send Claude the failing test names.

### I-0.4 Baseline verification scripts
- **Command:** `powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications.ps1`
- **Expected:** seven green lines, `PHASE 1 … PASSED` through `PHASE 7 VERIFY PASSED`. Phase 2 prints `PHASE 2 SECURITY OK` or, if the access fixtures are removed, `PHASE 2 SECURITY CONFIG OK - record visibility not yet tested`. That is your normal state.
- **If it fails:** stop and send the red lines.

### I-0.5 Create the checkpoint
- **What:** a tag on the current commit and a new branch for Sentinel.
- **Why:** the tag `phase7-complete` is a permanent bookmark you can always return to. The branch keeps `main` untouched until everything is green.
- **Command:**
  ```powershell
  git tag -a phase7-complete -m "Phases 1-7 complete: 123 tests, 89% coverage, 7 verify scripts passing"
  git push origin phase7-complete
  git checkout -b innovation-sentinel
  git branch --show-current
  ```
- **Expected:** `* [new tag] phase7-complete -> phase7-complete`; `Switched to a new branch 'innovation-sentinel'`; `innovation-sentinel`.
- **If it fails:** `tag 'phase7-complete' already exists` is fine; skip that line and continue.

### Recovery procedure (keep this in mind for the whole day)
| Situation | Command | Effect |
|---|---|---|
| Undo uncopied or unwanted **local** file changes | `git restore .` then `git clean -n` (preview) and `git clean -fd` (delete untracked files) | Local folder back to the last commit; **org unchanged** |
| Go back to the Phase 7 code | `git checkout main` | Your branch stays; `main` is the Phase 7 code |
| Something already **deployed** | Rollback section R | Org back to Phase 7 behaviour |

---

## I-1 · Download, extract and integrate the package

### I-1.1 Download
- **What:** save `HealthConnect_Innovation_Source.zip` from the chat to `C:\Users\sruja\Downloads`.
- **Command:** `Get-Item "$HOME\Downloads\HealthConnect_Innovation_Source.zip" | Select-Object Name, Length, LastWriteTime`
- **Expected:** one line with today's date and a size of about 150–170 KB (Length about 157000).
- **If it fails:** the browser may have renamed it (for example `… (1).zip`). Use that name in the next steps.

### I-1.2 Extract to a staging folder (not into the project)
- **Why:** extracting outside the project lets us check for collisions before anything touches your files.
- **Command:**
  ```powershell
  $pkg = "$HOME\Downloads\sentinel-package"
  Remove-Item $pkg -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive -Path "$HOME\Downloads\HealthConnect_Innovation_Source.zip" -DestinationPath $pkg
  (Get-ChildItem $pkg -Recurse -File).Count
  Get-ChildItem $pkg | Select-Object Name
  ```
- **Expected:** a file count of **95**, and top-level names `docs`, `force-app`, `manifest`, `scripts`, `README-INNOVATION.md`, `README.md`.

### I-1.3 Understand the folder structure
```text
README.md                              MODIFIED  project README (replaces the Phase 1 version)
README-INNOVATION.md                   NEW       Sentinel quick reference
docs/innovation/                       NEW       this handbook and the other documents
manifest/innovation-package.xml        NEW       everything (validate + deploy)
manifest/innovation-1-data-model.xml   NEW       fallback: data model only
manifest/innovation-2-application.xml  NEW       fallback: code, UI, security, reports
manifest/innovation-rollback/          NEW       full rollback
scripts/apex/innovation-*.apex         NEW       7 scripts
scripts/run-all-verifications-with-sentinel.ps1  NEW
force-app/main/default/
  applications/CareLoop.app-meta.xml   MODIFIED  +2 tabs (Community Watch, Community Signals)
  objects/Surveillance_Signal__mdt/    NEW       custom metadata type (14 fields)
  customMetadata/Surveillance_Signal.* NEW       4 signal definitions
  objects/Community_Signal__c/         NEW       object (24 fields, 1 list view)
  classes/ Sentinel* CommunityWatch*   NEW       5 classes (+ meta files)
  lwc/communityWatch/                  NEW       Community Watch screen
  flexipages/Community_Watch           NEW       app page
  tabs/Community_Watch, Community_Signal__c       NEW
  customPermissions/CareLoop_Run_Sentinel         NEW
  permissionsets/CareLoop_Sentinel_Manager, _Viewer  NEW
  reportTypes/CareLoop_Community_Signals          NEW
  reports/CareLoop_Reports/Community_Signals_*    NEW  (3, existing folder)
  dashboards/CareLoop_Dashboards/CareLoop_Sentinel NEW (existing folder)
```
The full list with line counts is in `HealthConnect_Innovation_File_Structure.md`.

### I-1.4 Collision check: which files already exist?
- **What:** list every package file that already exists in your project.
- **Why:** constraint 13, *never overwrite without identifying the impact*.
- **Command:**
  ```powershell
  $pkg = "$HOME\Downloads\sentinel-package"
  Get-ChildItem $pkg -Recurse -File | ForEach-Object {
      $rel = $_.FullName.Substring($pkg.Length + 1)
      if (Test-Path $rel) { "EXISTS   $rel" }
  }
  ```
- **Expected:** exactly two lines:
  ```text
  EXISTS   force-app\main\default\applications\CareLoop.app-meta.xml
  EXISTS   README.md
  ```
- **Verify:** no other `EXISTS` line. In particular, no class, permission set, flow, report or dashboard of Phases 1–7.
- **If it fails:** any other line means a name clash. Stop and send the output.

### I-1.5 Copy into the project
- **Command:**
  ```powershell
  Copy-Item -Path "$HOME\Downloads\sentinel-package\*" -Destination . -Recurse -Force
  ```
- **Expected:** no output. `-Force` is needed only because of the two files above.

### I-1.6 First look with Git
- **Command:** `git status --short`
- **Expected:**
  ```text
   M README.md
   M force-app/main/default/applications/CareLoop.app-meta.xml
  ?? README-INNOVATION.md
  ?? docs/
  ?? force-app/main/default/classes/CommunityWatchController.cls
  …
  ```
  Exactly two `M` lines. Everything else is `??` (new).
- **If it fails:** another `M` line means an existing file changed. Undo that file with `git restore <path>` and tell Claude.

**Status after I-1: Integrated (local only).**

---

## I-2 · Inspect changes and dependencies

### I-2.1 Read the only code-level modification
- **Command:** `git diff force-app/main/default/applications/CareLoop.app-meta.xml`
- **Expected:** two added lines (`+    <tabs>Community_Watch</tabs>` and `+    <tabs>Community_Signal__c</tabs>`) and **no** removed (`-`) lines.

### I-2.2 Size of the README change
- **Command:** `git diff --stat README.md`
- **Expected:** `README.md | … +/-`. The Phase 1 README is replaced by the full project README. Open it in VS Code to read it.

### I-2.3 Count the new files
- **Command:** `(git status --porcelain --untracked-files=all | Where-Object { $_ -like '??*' }).Count`
- **Expected:** **93** (95 package files minus the 2 modified ones).

### I-2.4 Check that the existing dependencies are present
- **Why:** Sentinel calls these existing classes and objects; they must exist and be unchanged.
- **Command:**
  ```powershell
  "CareLoopAlertService","CareLoopClock","ErrorLogger","CareRules","TriggerHandler","CareLoopTestFactory","CareLoopPhase4TestData" |
    ForEach-Object { "{0,-24} {1}" -f $_, (Test-Path "force-app/main/default/classes/$_.cls") }
  git diff --quiet HEAD -- force-app/main/default/classes ; if ($LASTEXITCODE -eq 0) { "existing classes unchanged" }
  ```
- **Expected:** seven lines ending `True`, then `existing classes unchanged`.

### I-2.5 Local commit of the integration (org still unchanged)
- **Why:** a commit is a save point. Even if validation fails we can compare and fix calmly.
- **Command:**
  ```powershell
  git add -A
  git commit -m "Integrate CareLoop Sentinel source package (not yet validated or deployed)"
  git log --oneline -2
  ```
- **Expected:** `[innovation-sentinel xxxxxxx] Integrate CareLoop Sentinel …`, about `95 files changed`.

---

## I-3 · Check-only validation (nothing is saved in the org)

### I-3.1 Validate everything with all local tests
- **What:** Salesforce compiles every Sentinel component and runs **all** local tests (Phases 1–7 plus Sentinel), then throws the result away.
- **Why:** this proves the package compiles, that the new tests pass and that no Phase 1–7 test broke, while **changing nothing**. Phases 4–7 used the same pattern.
- **Command:**
  ```powershell
  sf project deploy validate --manifest manifest/innovation-package.xml --test-level RunLocalTests --wait 60 --target-org careloop
  ```
- **Expected (when successful, usually 5–15 minutes):**
  ```text
  Status: Succeeded
  Deploy ID: 0Af…
  Target Org: …
  Elapsed Time: …
  Deployed Source … (about 70 rows)
  Test Results Summary
  Passing: 137
  Failing: 0
  Total: 137
  Successfully validated the deployment (0Af…).
  ```
  *137 = 123 existing + 14 new. This is the **expected** number; only this output can confirm it.*
- **Verify:** `Failing: 0`, and the final line says *Successfully validated*. **Write down the Deploy ID.**

### I-3.2 Understanding the result

| You see | Meaning | Org changed? |
|---|---|---|
| `Status: Succeeded` + `Successfully validated` | Compiles and all tests pass | **No** |
| `Component Failures` table | A file did not compile or a metadata file is invalid. Columns: Type, Name, Problem, Line | No |
| `Test Failures` table | Compiled, but a test assertion failed. Shows class.method and message | No |
| `Code Coverage` warning | A class has < 75% coverage | No |
| `Client timed out` | The CLI stopped waiting; the server may still be running | No |

### I-3.3 If validation fails
1. Copy the **whole** output, including the `Component Failures` / `Test Failures` tables, and send it to Claude.
2. Do not edit Phase 1–7 files to make it pass.
3. After a fix, run `git diff` (to see exactly what changed), commit, and validate again.
4. If the same error happens twice and is unclear, isolate it: validate the data model alone first:
   ```powershell
   sf project deploy validate --manifest manifest/innovation-1-data-model.xml --test-level NoTestRun --wait 20 --target-org careloop
   ```
   Note: `NoTestRun` is allowed for validation only because a Developer Edition org is not production.

Common errors are in section **T**.

**Status after I-3: Validated.**

---

## I-4 · Deploy the validated package

### I-4.1 Quick deploy
- **What:** deploy exactly what was validated in I-3.
- **Why:** quick deploy reuses the successful validation, so what lands in the org is byte-for-byte what passed 137 tests. That is safer than re-sending files. The "incremental" control is that the data, permissions, scan and schedule each come later as separate, checked steps.
- **Command:**
  ```powershell
  sf project deploy quick --use-most-recent --target-org careloop --wait 30
  ```
  (If you ran other validations since, use `--job-id 0Af…` with the ID from I-3.)
- **Expected:** `Status: Succeeded`, `Deployed Source` table.
- **If it fails:**
  - `INVALID_ID_FIELD` or `validation expired` → validations last 10 days; run I-3 again.
  - Anything else → send the output.

### I-4.2 Fallback: two increments (only if quick deploy is not possible)
```powershell
sf project deploy start --manifest manifest/innovation-1-data-model.xml --wait 20 --target-org careloop
sf project deploy start --manifest manifest/innovation-2-application.xml --test-level RunLocalTests --wait 60 --target-org careloop
```
`deploy start` with tests rolls itself back if any test fails.

### I-4.3 Check in Setup
| Where | Expected |
|---|---|
| Setup → Object Manager → *Community Signal* | Exists, 24 custom fields |
| Setup → Custom Metadata Types → *Surveillance Signal* → Manage Records | Fever cluster, Respiratory illness cluster, Households not reachable, Vaccine doses delayed |
| Setup → Apex Classes | `SentinelService`, `SentinelJob`, `CommunityWatchController` and 2 test classes |
| Setup → Permission Sets | *CareLoop Sentinel Manager*, *CareLoop Sentinel Viewer* |

**Status after I-4: Deployed (not yet verified).**
```powershell
git commit --allow-empty -m "CareLoop Sentinel deployed to careloop org (validated: 137 tests passing)"
```
(Write the number you actually saw.)

---

## I-5 · Salesforce UI checks (no manual building required)

| # | What | How | Expected |
|---|---|---|---|
| 5.1 | New tabs in the app | App Launcher → CareLoop | *Community Watch* after *Doctor Review*; *Community Signals* after *Visit Plans* |
| 5.2 | Page loads | Click **Community Watch** | Card "Community Watch" with a village × signal grid (cells may say *no history yet* before demo data) |
| 5.3 | Notification type exists (Phase 4) | Setup → Custom Notifications | `CareLoop Alert` present |
| 5.4 | Report folder sharing (Phase 7) | Reports → All Folders → CareLoop Reports | 3 new *Community signals …* reports visible |
| 5.5 | Dashboard | Dashboards → CareLoop Dashboards | *CareLoop Sentinel – Community Early Warning* |

**If 5.2 shows an error:** an "insufficient access" message for your admin user means the permission sets are not yet assigned. Do I-6, then refresh.

---

## I-6 · Permission set assignment

- **What:**
  - **Manager** permission set: you (admin) and Meena, who can run scans and review signals.
  - **Viewer** permission set: Arjun, Lakshmi and Sunita, who have read-only access.
- **Why:** least privilege. Existing permission sets are not touched.
- **Command:**
  ```powershell
  sf apex run --file scripts/apex/innovation-assign-permissions.apex --target-org careloop | Select-String "USER_DEBUG"
  ```
- **Expected:** `SENTINEL DONE  | 5 assignment(s) added, 0 already present, 5 users covered`. On a re-run: `0 assignment(s) added, 5 already present, 5 users covered`.
- **Verify:** Setup → Permission Sets → CareLoop Sentinel Manager → Manage Assignments shows you and Meena Iyer.
- **If it fails:**
  - `STOP | Deploy the innovation package first` → I-4 did not succeed.
  - `4 users covered` → a Phase 2 user has a different username; send the output.

---

## I-7 · Sentinel Apex tests

- **What / Why:** run only the 14 new tests, with coverage, to see each result by name.
- **Command:**
  ```powershell
  sf apex run test --class-names SentinelServiceTest --class-names CommunityWatchControllerTest --code-coverage --result-format human --wait 20 --target-org careloop
  ```
- **Expected:** `Outcome Passed`, `Tests Ran 14`, `Pass Rate 100%`. The coverage table lists `SentinelService`, `SentinelJob` and `CommunityWatchController`; the **target is ≥ 85%** each.
- **What the 14 tests prove:** see the Test Plan, section 2: all four signals, steady villages, tiny counts, missing history, thresholds, duplicates, Closed/Dismissed, notifications, permissions and invalid input.
- **If it fails:** send the `Test Failures` section (method name + message).

---

## I-8 · Sentinel verification script (rolled back)

- **What:** 10 checks in your real org, using temporary "Verify …" villages. Everything is rolled back.
- **Command:**
  ```powershell
  sf apex run --file scripts/apex/innovation-verify.apex --target-org careloop | Select-String "USER_DEBUG"
  ```
- **Expected:** 10 lines `SENTINEL PASS  1 …` to `SENTINEL PASS  10 …`, then `SENTINEL INNOVATION VERIFY PASSED (10 checks, all test data rolled back)`.
- **Verify:** App → Villages has **no** "Verify …" village afterwards.
- **If it fails:** send every `FAIL` or `ERROR` line.

**Status after I-7 and I-8: Logic verified.**

---

## I-9 · Demo data and testing each signal

### I-9.1 Create synthetic demo data
- **What:** about 90 tagged visits and 9 tagged vaccine doses in the four Phase 4 villages:
  - 6 weeks of routine visits (the history Sentinel needs) and a low background of fever and missed visits;
  - **Moinabad:** fever cluster;
  - **Kondapur:** respiratory cluster;
  - **Kandukur:** unreachable households;
  - **Shamshabad:** delayed vaccine doses.
- **Why:** shows all four signal types with realistic history. Every record is tagged `Sentinel demo` so it can be removed exactly.
- **Command:**
  ```powershell
  sf apex run --file scripts/apex/innovation-sentinel-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
  ```
- **Expected:**
  ```text
  SENTINEL PLANNED | Moinabad fever cluster: 7 visits from 5 households
  SENTINEL CREATED | N synthetic visits (history + background + three clusters)
  SENTINEL CREATED | 9 catch-up doses in Shamshabad (4 given on time earlier, 5 now delayed)
  SENTINEL FINISHED | Next: scripts/apex/innovation-run-scan.apex
  ```
  (Fewer than 5 households is fine if Moinabad has fewer adults.)
- **If it fails:**
  - `STOP | The CareLoop demo clock …` → clear *Simulated Today* (Prerequisites).
  - `STOP | Not enough demo patients` → run `phase4-demo-data.apex` first.
  - `EXISTS` → data is already loaded; continue.

### I-9.2 Run the first scan
- **Command:**
  ```powershell
  sf apex run --file scripts/apex/innovation-run-scan.apex --target-org careloop | Select-String "USER_DEBUG"
  ```
- **Expected:** one `SENTINEL SCAN  | as of <today> | 16 village-signals | k flagged | k new | 0 updated | k notification(s)` line (16 = 4 villages × 4 signals; more if you have more active villages), then one `SENTINEL SIGNAL|` line per signal.

### I-9.3 Check each signal type

| Signal | Village | Expected in scan output | Expected on Community Watch |
|---|---|---|---|
| Fever cluster | Moinabad | `Alert | Fever cluster - Moinabad | observed ~7 …` | Red cell |
| Respiratory illness cluster | Kondapur | `Alert` or `Watch | Respiratory illness cluster - Kondapur | observed 4 …` | Red or amber cell |
| Households not reachable | Kandukur | `Alert | Households not reachable - Kandukur | observed ≥ 6 …` | Red cell |
| Vaccine doses delayed | Shamshabad | `Alert` or `Watch | Vaccine doses delayed - Shamshabad | observed ≥ 5 …` | Red or amber cell |

Other lines (for example vaccine delays in Moinabad from the Phase 4 "poor coverage" data) are **genuine results from your existing data**. Note them; they are not errors.

**If a planted signal is missing:** look at that village's cell tooltip (hover) on Community Watch. It explains the numbers. Send it to Claude.

---

## I-10 · Thresholds, minimum counts and false-positive checks

| # | Test | How | Expected |
|---|---|---|---|
| 10.1 | Steady villages stay Normal | Community Watch grid | Most cells green with "normal x.x" |
| 10.2 | No-history safeguard | Unit test `villagesWithoutEnoughHistoryAreNotAssessed` and verify check 7 | Passed in I-7 / I-8 |
| 10.3 | Tiny counts | Unit test `steadyOrTinyCountsAreNotFlagged`, `unreachableHouseholdsNeedAtLeastFourVisits`; verify check 4 | Passed |
| 10.4 | Thresholds decide Watch vs Alert | Unit test `thresholdsDecideWatchAndAlertAndAreConfigurable` | Passed |
| 10.5 | **Live threshold change (optional, 3 min)** | Setup → Custom Metadata Types → Surveillance Signal → Manage Records → *Fever cluster* → Edit → **Min Count = 10** → Save → refresh Community Watch | Moinabad fever cell is no longer red (7 < 10). **Set Min Count back to 3** and refresh: red again |
| 10.6 | Spread floor | Hover any cell with a 0,0,0,0 history | Explanation shows "watch level 2.0", so 1 or 2 cases are not flagged |

10.5 shows the panel that the thresholds are configuration, not code. The grid recalculates live; recorded signals change only on the next scan.

---

## I-11 · Notifications and signal review

| # | As | Steps | Expected |
|---|---|---|---|
| 11.1 | Meena (Setup → Users → Meena Iyer → **Login**) | Bell icon | Bells such as "Community alert: Fever cluster in Moinabad" from I-9.2 |
| 11.2 | Meena | Click the bell | Opens the Community Signal record |
| 11.3 | Meena | Community Watch → Moinabad signal → **Details and review** | Weekly bar chart, explanation, suggested verification, evidence links |
| 11.4 | Meena | **Dismiss** with an empty note | Error toast: notes are required |
| 11.5 | Meena | Type "ASHA asked to re-visit; PHC informed" → **Acknowledge (Investigating)** | Success toast; badge *Investigating*; note stamped with date and name |
| 11.6 | Meena | **Run scan now** | Toast "… 0 new · k updated"; the Moinabad signal is still *Investigating* (no duplicate) |
| 11.7 | Meena | Add a note → **Close (follow-up done)** | Status *Closed*; history shows both stamps |
| 11.8 | Meena | **Run scan now** | Moinabad fever is not raised again this week |
| 11.9 | Arjun | Bell | Same bells (doctors are notified too) |

Log out of each user (top-right → Log out as …) before the next one.

---

## I-12 · Permissions and record visibility

| # | As | Check | Expected |
|---|---|---|---|
| 12.1 | Arjun | Community Watch | Grid and signals visible; **no** "Run scan now"; no review buttons |
| 12.2 | Lakshmi (North) | Community Watch | Counts for North villages from her patients; South villages show "no history yet" or 0, because she cannot see those records |
| 12.3 | Lakshmi | Open a Kandukur (South) signal → Details | Explanation text visible (village counts only); evidence: *None visible to you* |
| 12.4 | Sunita (South) | Open the Moinabad (North) signal | Same: counts only, no patient records |
| 12.5 | Any viewer | Open a Community Signal record | No Edit button |
| 12.6 | Kavya (portal) | Portal home | No Sentinel data or tab |
| 12.7 | Admin | `sf apex run --file scripts/apex/phase2-verify-security.apex --target-org careloop \| Select-String "USER_DEBUG"` | Same Phase 2 verdict as in I-0.4 |

---

## I-13 · Reports and dashboard

| # | Where | Expected |
|---|---|---|
| 13.1 | Reports → CareLoop Reports → *Community signals by region and status* | Groups North / South, then New / Investigating / Closed |
| 13.2 | *Community signals by signal type and severity* | 4 signal labels × Watch / Alert |
| 13.3 | *Community signals by village* | Village → signal, with the sum of Observed |
| 13.4 | Dashboards → *CareLoop Sentinel – Community Early Warning* → Refresh | 3 charts; **no patient names anywhere** |
| 13.5 | Same dashboard as Lakshmi | Loads (dynamic dashboard, runs as the viewer) |

**If the dashboard failed to deploy** because of the Developer Edition dynamic-dashboard limit, see section T. The reports and Community Watch still work.

---

## I-14 · Schedule the daily scan

- **Command:**
  ```powershell
  sf apex run --file scripts/apex/innovation-schedule-sentinel.apex --target-org careloop | Select-String "USER_DEBUG"
  ```
- **Expected:** `SCHEDULE OK | CareLoop Sentinel Daily Scan | WAITING | next run <tomorrow> 06:30:00`
- **Verify:** Setup → Scheduled Jobs shows the CareLoop nightly job (05:30), the Navigator (06:15) and the Sentinel scan (06:30).

**Status after I-9 to I-14: Verified in the UI.**

---

## I-15 · Full regression of Phases 1–7 (+ Sentinel)

```powershell
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 30 --target-org careloop
powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications-with-sentinel.ps1
```
- **Expected:** `Tests Ran 137`, `Pass Rate 100%`, org-wide coverage ≥ 85%. Eight green lines, the same seven as in I-0.4 plus `SENTINEL INNOVATION VERIFY PASSED`.
- **Known interaction:** the demo data adds synthetic *Patient Not Available* visits in Kandukur, so some Kandukur patients' Phase 3/4 failed-attempt counts and priority scores rise. That is correct behaviour. If a phase verify depends on exact demo priorities and goes red, run `innovation-remove-demo-data.apex`, repeat, and tell Claude.

---

## I-16 · Final commit, push and merge

```powershell
git status
git add -A
git commit -m "CareLoop Sentinel: deployed and verified (137 tests, verify scripts green)"
git push -u origin innovation-sentinel
git checkout main
git merge --no-ff innovation-sentinel -m "Merge CareLoop Sentinel innovation"
git push origin main
git tag -a sentinel-complete -m "HealthConnect CareLoop with CareLoop Sentinel"
git push origin sentinel-complete
```
- Write the numbers you actually saw in the commit message.
- Update the README status row from *Package integrated* to *Implemented and verified* before this commit.
- **Expected:** pushes succeed; GitHub shows `main` with the merge commit and tags `phase7-complete` and `sentinel-complete`.

---

## I-17 · End-to-end demo rehearsal

Follow `HealthConnect_CareLoop_Final_Demo_Script.md` twice with a timer. Before the real demo (morning of 12 Nov):
```powershell
sf apex run --file scripts/apex/innovation-remove-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-sentinel-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-run-scan.apex --target-org careloop | Select-String "USER_DEBUG"
```
This refreshes the clusters so they fall in "this week" on demo day.

---

## R. Rollback

| Level | When | Steps | Result |
|---|---|---|---|
| **Local only** | Before I-4 | `git checkout main` (or `git restore .` + `git clean -fd` on the branch) | Org never changed |
| **Soft** (5 min) | After I-4, if anything misbehaves | 1. `sf apex run --file scripts/apex/innovation-rollback-prepare.apex --target-org careloop \| Select-String "USER_DEBUG"` 2. `git checkout phase7-complete -- force-app/main/default/applications/CareLoop.app-meta.xml` 3. `sf project deploy start --source-dir force-app/main/default/applications/CareLoop.app-meta.xml --target-org careloop --wait 10` | Job stopped; signals, demo data and Sentinel assignments removed; tabs gone. Phases 1–7 behave exactly as before. Classes remain unused |
| **Full** | Only if you must remove the metadata | After soft: `sf project deploy start --manifest manifest/innovation-rollback/package.xml --post-destructive-changes manifest/innovation-rollback/destructiveChanges.xml --target-org careloop --wait 20`, then `git checkout main` | New components deleted. If Salesforce says a component is still in use, run the command again or delete that item in Setup. Deleted objects stay 15 days in *Object Manager → Deleted Objects* |
| **After merge** | — | `git revert -m 1 <merge-commit-id>` + push | Code history kept, Sentinel removed from `main` |

`innovation-rollback-prepare.apex` deletes only Sentinel data: Community Signals, records tagged `Sentinel demo`, and Sentinel permission-set assignments.

---

## T. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `sf : The term 'sf' is not recognized` | CLI not on PATH in this window | Close and reopen VS Code / PowerShell; `npm install -g @salesforce/cli` if needed |
| `No authorization information found for careloop` | Session expired | `sf org login web --alias careloop` |
| `Expand-Archive : … already exists` | Staging folder exists | Re-run I-1.2 (it deletes the staging folder first) |
| Validation: `Invalid type: Surveillance_Signal__mdt` / `Community_Signal__c` | The object failed earlier in the same deployment | Look at the **first** component failure; that is the real error |
| Validation: `Variable does not exist` / `Method does not exist or incorrect signature` + class + line | Compile error in new code | Send to Claude with the line; it will be a one-line fix |
| Validation: `Field Min_History_Weeks__c does not exist` in a CustomMetadata row | Type field not included | Check that `manifest/innovation-package.xml` lists `Surveillance_Signal__mdt.Min_History_Weeks__c` |
| Validation: `System.AssertException: Assertion Failed …` | A test failed | Send the method name and message. Don't weaken the assertion |
| Validation: `Average test coverage … at least 75% required` | Coverage dropped | Send the coverage table |
| Validation: `You can't … more than … dynamic dashboards` (wording may differ) | Developer Edition dynamic-dashboard limit | Remove the `<types>` block for `Dashboard` from `manifest/innovation-package.xml`, validate again, and note the dashboard as *deferred*. Reports and Community Watch are unaffected |
| Validation: report error mentioning `Community_Signal__c$…` | Report column name issue | Remove that report from the manifest, validate, and tell Claude |
| `Client timed out` / `Request timed out` | CLI stopped waiting | `sf project deploy report --use-most-recent --target-org careloop` |
| Community Watch: *Could not load Community Watch: …* | User lacks Sentinel or Village access | Assign permission sets (I-6) |
| Grid all *no history yet* | No visits in the last 5 weeks | Run demo data (I-9.1) |
| No bells | Notifications go to doctors and Sentinel managers; your browser may have them muted | Check Setup → Custom Notifications → CareLoop Alert; check the scan output's `notification(s)` count |
| Planted signal is only *Watch* | Random background made the baseline higher | Fine; still a valid demo. Re-generate data (remove, then create) if you want Alert |
| Phase 3/4 verify red after demo data | Demo visits changed failed-attempt counts | Remove demo data, re-run the verify, tell Claude |
| `INSUFFICIENT_ACCESS` when assigning permission sets | Not admin | Run as the admin user (`sf org display` shows who) |

---

## Q. Command summary

```powershell
# validate (org unchanged) -> deploy
sf project deploy validate --manifest manifest/innovation-package.xml --test-level RunLocalTests --wait 60 --target-org careloop
sf project deploy quick --use-most-recent --target-org careloop --wait 30
# set up and check
sf apex run --file scripts/apex/innovation-assign-permissions.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run test --class-names SentinelServiceTest --class-names CommunityWatchControllerTest --code-coverage --result-format human --wait 20 --target-org careloop
sf apex run --file scripts/apex/innovation-verify.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-sentinel-demo-data.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-run-scan.apex --target-org careloop | Select-String "USER_DEBUG"
sf apex run --file scripts/apex/innovation-schedule-sentinel.apex --target-org careloop | Select-String "USER_DEBUG"
# regression
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 30 --target-org careloop
powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications-with-sentinel.ps1
```

## D. Source

Every file is in `HealthConnect_Innovation_Source.zip`. A full listing of every source file is in `HealthConnect_Innovation_Source_Listing.md`.
