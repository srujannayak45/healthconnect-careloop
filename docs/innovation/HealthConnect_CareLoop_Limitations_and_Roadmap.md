# HealthConnect CareLoop — Known Limitations and Future Enhancements

## 1. Known limitations (current solution)

### CareLoop Sentinel
| # | Limitation | Impact | Mitigation now |
|---|---|---|---|
| S1 | Thresholds are sensible defaults, not validated on real district data | Watch/Alert sensitivity may not suit a real programme | All thresholds in custom metadata; dashboard tracks closed vs dismissed for tuning |
| S2 | Weekly windows on small populations | Some real clusters may stay under the minimum count | Watch level; configurable minimums |
| S3 | A "Patient Not Available" surge can mean migration, festivals or harvest season, not illness | Interpretation needed | Signal is labelled "Households not reachable"; guidance asks to check the reason |
| S4 | Single-transaction scan | Not for thousands of villages | Documented Batch Apex path |
| S5 | Notifications go to all Sentinel managers and doctors, not per region | Some bells irrelevant to a reader | Region shown in every signal; per-region routing is future |
| S6 | The grid is computed live on page load | Slower with large data | Six-week query window; stored signals for history |
| S7 | Region on a signal follows the village's current region (formula) | Historic signals move if a village changes region | Rare; a snapshot field is future |
| S8 | The scheduled job runs as the admin who scheduled it | That user must stay active | Documented; reschedule if the admin changes |
| S9 | Developer Edition limits dynamic dashboards | Dashboard deploy could fail | Reports and Community Watch remain; dashboard can be deferred |
| S10 | No LWC Jest tests | UI regressions are caught manually | UAT checklist |

### Phases 1–7 (as documented in the phase READMEs)
| # | Limitation |
|---|---|
| P1 | All data is synthetic; clinical thresholds and the immunisation schedule are configurable samples needing clinical sign-off |
| P2 | SMS goes to an echo gateway; no real SMS (production needs DLT registration in India) |
| P3 | Portal labels are in English; reminder texts are in the patient's language |
| P4 | The consent ledger is tamper-evident, not tamper-proof |
| P5 | Navigator distances are straight lines between village centres (no road routing); weights are expert-set, not learned |
| P6 | One reminder per person per day (by design); a duplicate-key reminder is not re-sent the same day |
| P7 | Bells are not sent inside Apex tests (tests count them) |

## 2. Future enhancements (not implemented)

| Priority | Enhancement | Value | Effort |
|---|---|---|---|
| 1 | Feed open Sentinel signals into Navigator priority, so workers visit flagged villages first | Closes the loop from detection to field action | Medium |
| 2 | Per-region notification routing (signal region → that region's supervisor) | Fewer irrelevant bells | Low |
| 3 | Threshold tuning report: confirmed vs dismissed rate per signal | Evidence-based configuration | Low |
| 4 | Batch Apex Sentinel for district scale | Thousands of villages | Medium |
| 5 | Additional signals: diarrhoea cluster (needs a symptom value), ANC drop-out | Wider surveillance | Low–Medium (config + field) |
| 6 | Randomised reminder experiments (A/B on timing and channel) | Honest outreach-effectiveness measurement | Medium; needs weeks of data |
| 7 | Referral closure tracking using `Referral_Required__c` | Know whether referred patients reached the facility | Medium |
| 8 | Production SMS gateway with DLT templates | Real reminders | Depends on provider |
| 9 | Offline capture for areas with poor connectivity | Field reliability | High |
| 10 | Export of de-identified weekly counts to the district (IDSP-style S-form) | Integration with public-health reporting | Medium; needs governance |

Not planned: LLM chatbots, outbreak "prediction" and IVR. They have weak value-to-risk for this programme and would need paid services or send patient data outside the org.
