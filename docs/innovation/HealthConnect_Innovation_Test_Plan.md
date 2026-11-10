# HealthConnect CareLoop — CareLoop Sentinel Test Plan

> Written **before** execution. No result here has been observed yet. Fill the Result column only with what Salesforce actually shows.

## 1. Targets

| Measure | Target | Confirmed by |
|---|---|---|
| New Apex test methods | 14 (SentinelServiceTest 11, CommunityWatchControllerTest 3) | I-7 output |
| Total local tests | 137 (123 + 14), 0 failures | I-3 validation and I-15 output |
| Coverage of new classes | ≥ 85% each (75% is Salesforce's minimum) | I-7 coverage table |
| Org-wide coverage | ≥ 85% (baseline 89%) | I-15 |
| Sentinel verify script | 10/10 PASS | I-8 |
| Phase 1–7 verify scripts | all 7 unchanged verdicts | I-15 |

## 2. Apex unit tests

| ID | Test method | Requirement covered | Scenario | Expected | Result |
|---|---|---|---|---|---|
| U1 | `SentinelServiceTest.feverSpikeIsAnAlertWithExplanation` | Fever signal, explanation | Baseline 1,1,0,1 fever visits; 6 this week from 4 households; population 2,000 | Alert; expected 0.75; 5 weekly bars, last 6; "from 4 household(s)"; 3 per 1,000; 6 evidence Ids | |
| U2 | `…respiratoryClusterCountsCoughBreathlessnessOrLowSpO2` | Respiratory signal | Cough, Cough+Fever, Breathlessness, SpO2 93 → count; SpO2 97, Headache → don't | Observed 4, Alert, 4 households | |
| U3 | `…unreachableHouseholdsNeedAtLeastFourVisits` | Unreachable signal, minimum count | Village A: 3 missed visits; village B: 5 *Not Available* + 1 *Refused* | A Normal (below min 4); B observed 6, Alert | |
| U4 | `…delayedVaccineDosesAreDetectedButGraceCancelledAndOnTimeAreNot` | Immunisation signal, grace, cancellations | 5 doses overdue > 7 days; plus one inside grace, one given within grace, one approved cancellation, one check-up | Observed 5, Alert, window ends today − 7 | |
| U5 | `…steadyOrTinyCountsAreNotFlagged` | False-positive prevention | Steady 2/week for 5 weeks; tiny 0 → 2 | All Normal; steady z = 0; scan flags nothing; no records | |
| U6 | `…villagesWithoutEnoughHistoryAreNotAssessed` | Missing / insufficient history | New village: no history; another with 1 week of history; both 6 fever visits | insufficientHistory = true, Normal, "not assessed" | |
| U7 | `…thresholdsDecideWatchAndAlertAndAreConfigurable` | Thresholds, spread floor, config | Unit scoring: 2,3,2,3 with 4/5/6; Alert_Z 5; 0,0,0,0 with 2; 0,10,0,10 with 12 | Normal / Watch (z 2.5, threshold 4.5) / Alert; strict → Watch; flat Normal (spread 1); noisy Normal | |
| U8 | `…scanRecordsOnceKeepsStatusAndRespectsDismissal` | Duplicate prevention, dismissed | Scan; Investigating; rescan; Dismiss; scan next day | 1 created; rescan updates 1, keeps Investigating; dismissed not re-raised; region North; explanation has no patient name | |
| U9 | `…closedSignalIsSuppressedThatWeekButANewClusterLaterIsRaised` | Closed signals, new windows | Cluster two weeks ago → signal → Closed; scan next day; new bigger cluster this week | Next-day scan: nothing; today: 1 new record; old stays Closed | |
| U10 | `…managersAreNotifiedForNewSignalsAndEscalationsOnly` | Manager notifications | Watch created; rescan unchanged; one more visit → Alert | 1 bell; 0 bells; 1 bell on Watch→Alert | |
| U11 | `…dailyJobSchedulesOnceAndRuns` | Scheduling | Schedule twice; execute | Same job Id; no Error Log | |
| U12 | `CommunityWatchControllerTest.managerScansReviewsAndSeesEvidence` | Review workflow | Manager: grid, scan, Dismiss without note, Investigating, Closed, rescan | Alert cell; 1 created; error without note; Closed + reviewer + both stamps; rescan creates 0; admin sees 4 evidence rows | |
| U13 | `…viewersCannotScanOrChangeSignals` | Permissions, visibility | Restricted-profile viewer (Viewer + Health Worker permission sets) | No scan, no review; reads 1 signal; scan and update throw; 0 evidence; grid count 0 for records she can't see | |
| U14 | `…invalidRequestsAreRejected` | Input validation | Status "Confirmed", "Outbreak", null; Closed with blank note; deleted signal | All rejected with a message; evidence empty | |

All tests set their own signal definitions in memory, so they do not depend on the org's custom metadata. They also use their own test data (no `SeeAllData`).

> **If U13's visibility assertions fail** (the viewer sees records), that reveals a pre-existing Phase 2 sharing issue, not a Sentinel bug. Stop and review; do not weaken the test.

## 3. Verification script (`innovation-verify.apex`, rolled back)

| Check | Proves | Expected line (after `SENTINEL `) |
|---|---|---|
| 1 | Signals configured | `PASS  1  4 active surveillance signals configured` |
| 2 | Fever cluster | `PASS  2  Fever cluster is an Alert: Fever cluster in Verify Spike: 6 visits …` |
| 3 | Respiratory cluster | `PASS  3  Respiratory cluster detected: Alert, observed 3 vs normal 0.00` |
| 4 | Unreachable + minimum count | `PASS  4  5 unreachable visits flagged (Alert, …); 3 not flagged (Normal, …)` |
| 5 | Vaccine delay | `PASS  5  Delayed vaccine doses detected: Alert, observed 5 …` |
| 6 | Steady village | `PASS  6  Steady village is Normal: Normal, observed 2 vs normal 2.00` |
| 7 | No history | `PASS  7  Village with no history is not assessed: … not assessed …` |
| 8 | Duplicate prevention | `PASS  8  One signal recorded; re-scan updated it (no duplicate) and kept "Investigating"` |
| 9 | Closed and Dismissed | `PASS  9  Closed and dismissed signals left alone, not raised again` |
| 10 | No errors | `PASS  10 No Error Log entries (0)` |
| — | Verdict | `INNOVATION VERIFY PASSED (10 checks, all test data rolled back)` |

## 4. Signal tests on demo data (I-9)

| Signal | Village | Expected | Result |
|---|---|---|---|
| Fever cluster | Moinabad | Alert (≈ 7 visits vs normal ≈ 0.5–1) | |
| Respiratory illness cluster | Kondapur | Watch or Alert (4 vs ≈ 0) | |
| Households not reachable | Kandukur | Alert (≥ 6 vs ≈ 0.5) | |
| Vaccine doses delayed | Shamshabad | Watch or Alert (≥ 5 vs ≈ 0) | |
| Other villages × signals | — | Normal, or a genuine signal from Phase 4 data (note it) | |

## 5. Safeguard and false-positive tests

| Safeguard | Automated | Manual |
|---|---|---|
| Minimum count | U3, U5, U7, verify 4 | — |
| Spread floor | U7 | Hover a 0,0,0,0 cell: "watch level 2.0" |
| Missing history | U6, verify 7 | Cells read "no history yet" before demo data |
| Noisy baseline | U7 | — |
| Vaccine grace and cancellations | U4 | — |
| Configurable thresholds | U7 | I-10.5 (Min Count 10, then back to 3) |
| Duplicate prevention | U8, U12, verify 8 | I-11.6 |
| Closed and Dismissed | U8, U9, U12, verify 9 | I-11.7–11.8 |

## 6. Role-based UAT

| ID | As | Steps | Expected | Result |
|---|---|---|---|---|
| R1 | Admin / Meena | Community Watch | Grid; planted cells red/amber; *Run scan now* visible | |
| R2 | Meena | Bell | "Community alert: …" bells | |
| R3 | Meena | Details and review | Bars, explanation, guidance, evidence links | |
| R4 | Meena | Dismiss with no note | Error toast | |
| R5 | Meena | Note → Acknowledge (Investigating) | Stamped note | |
| R6 | Meena | Run scan now | No duplicate, status kept | |
| R7 | Meena | Note → Close (follow-up done) → Run scan | Closed; not raised again | |
| R8 | Arjun | Community Watch + bell | Read-only; bells received | |
| R9 | Lakshmi | Community Watch | Counts only from records she can see | |
| R10 | Sunita | North signal details | Counts only; evidence "None visible to you" | |
| R11 | Any viewer | Signal record | No Edit | |
| R12 | Kavya (portal) | Portal | No Sentinel data | |
| R13 | Admin | 3 reports + dashboard | Aggregates only; no patient names | |

## 7. Regression of Phases 1–7

| Test | Command | Expected | Result |
|---|---|---|---|
| All local tests | `sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 30 --target-org careloop` | 137 run, 0 fail, ≥ 85% | |
| 7 phase verify scripts + Sentinel | `powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications-with-sentinel.ps1` | 8 green verdicts (Phase 2 verdict as in baseline) | |
| Existing screens | Doctor Review, Care Navigator, patient page, portal home, Programme Intelligence dashboard | Unchanged behaviour | |
| Existing jobs | Setup → Scheduled Jobs | Nightly 05:30 and Navigator 06:15 still scheduled | |

**Known interaction:** synthetic *Patient Not Available* demo visits raise some Kandukur patients' failed-attempt counts and priorities. That is expected Phase 3/4 behaviour. Remove the demo data if an exact-number Phase 3/4 check depends on it.

## 8. Not covered (honest gaps)

- Performance at district scale (thousands of villages): the design note is to move to Batch Apex.
- LWC Jest tests: none, as for the earlier LWCs; the LWC is covered by UAT R1–R13.
- Statistical validity on real epidemiological data: the thresholds are defaults and are not validated for any real district.
- Bell delivery itself: tests count bells (`CareLoopAlertService.bellsSent`) because Salesforce does not send notifications inside tests; R2 and R8 check real delivery.
