# HealthConnect CareLoop

Preventive-care outreach on Salesforce: every vaccine dose, check-up and doctor follow-up is a **Care Activity**;
a rule-based, explainable engine ranks patients by need; an escalation ladder reaches the patient in her own
language, then the health worker, then the supervisor; nothing is sent or shared without recorded,
purpose-specific, tamper-evident consent.

## Status

| Phase | Contents | State |
| --- | --- | --- |
| 1 | Data model, validation rules, custom metadata, permission sets, tabs, app | In this package |
| 2 | Security: OWD, roles, users, sharing | Next |
| 3+ | Apex engine, LWCs, flows, portal, dashboards | Planned |

## Deploy (Phase 1)

```bash
sf org login web --alias careloop --set-default
sf project deploy start --source-dir force-app --target-org careloop --wait 30
sf org assign permset --name CareLoop_Admin --target-org careloop
sf apex run --file scripts/apex/verify-phase1.apex --target-org careloop
sf apex run --file scripts/apex/phase1-smoke-test.apex --target-org careloop
```

## Layout

```
force-app/main/default/
  applications/        CareLoop Lightning app
  customMetadata/      Care schedules, care rules, escalation rules, message templates, settings (46 records)
  customPermissions/   CareLoop_Bypass_Validation
  objects/             8 custom objects, 5 custom metadata types, Contact and Account fields
  permissionsets/      Admin, Health Worker, Doctor, Programme Manager, Patient, Validation Bypass
  tabs/                One tab per custom object
manifest/package.xml   Phase 1 components, for retrieve
scripts/apex/          Verification and smoke-test scripts
```

## Notes

- Clinical thresholds and the immunisation schedule are configurable samples; a clinician must set real values.
- The immunisation schedule is modelled on India's Universal Immunisation Programme; verify before quoting.
- All sample data is synthetic.
