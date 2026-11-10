# =====================================================================================
# HealthConnect CareLoop - full regression INCLUDING CareLoop Sentinel.
# Same behaviour as scripts/run-all-verifications.ps1 (Phases 1-7, unchanged) plus the Sentinel verify.
# It only runs read-only or rolled-back verification scripts. Run from the project folder:
#   powershell -ExecutionPolicy Bypass -File scripts/run-all-verifications-with-sentinel.ps1
# =====================================================================================
$org = "careloop"
$scripts = @(
    "scripts/apex/verify-phase1.apex",
    "scripts/apex/phase2-verify-security.apex",
    "scripts/apex/phase3-verify.apex",
    "scripts/apex/phase4-verify.apex",
    "scripts/apex/phase5-verify.apex",
    "scripts/apex/phase6-verify.apex",
    "scripts/apex/phase7-verify.apex",
    "scripts/apex/innovation-verify.apex"
)
foreach ($s in $scripts) {
    if (-not (Test-Path $s)) { Write-Host "MISSING  $s" -ForegroundColor Yellow; continue }
    $lines = sf apex run --file $s --target-org $org | Select-String "USER_DEBUG"
    $fails = $lines | Select-String "FAIL "
    $last = if ($lines) { ($lines | Select-Object -Last 1).ToString() } else { "no output - run the script alone to see the error" }
    $verdict = ($last -split '\|')[-1].Trim()
    $color = if ($fails -or $verdict -match "FAIL|ERROR|PROBLEMS") { "Red" } else { "Green" }
    Write-Host ("{0,-45} {1}" -f $s, $verdict) -ForegroundColor $color
    foreach ($f in $fails) { Write-Host ("    " + (($f.ToString() -split '\|')[-1].Trim())) -ForegroundColor Red }
}
