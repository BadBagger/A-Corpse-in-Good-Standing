$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$castPlanPath = Join-Path $root "docs\vo\vo_cast_plan.json"
$audioStatusPath = Join-Path $root "docs\vo\vo_audio_asset_status.json"
$readinessPath = Join-Path $root "docs\vo\vo_commercial_readiness.json"
$validateScript = Join-Path $PSScriptRoot "Validate-VoCommercialReadiness.ps1"

foreach ($path in @($castPlanPath, $audioStatusPath, $validateScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO commercial readiness test input: $path"
    }
}

$originalCastPlan = Get-Content -LiteralPath $castPlanPath -Raw
$originalAudioStatus = Get-Content -LiteralPath $audioStatusPath -Raw

try {
    $staleCastPlan = $originalCastPlan | ConvertFrom-Json
    $staleCastPlan.scratch_cast_count = 999
    $staleCastPlan.needs_cast_decision_count = 0
    $staleCastPlan | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $castPlanPath -Encoding UTF8

    $staleAudioStatus = $originalAudioStatus | ConvertFrom-Json
    $staleAudioStatus.present_count = 999
    $staleAudioStatus.missing_count = 0
    $staleAudioStatus | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $audioStatusPath -Encoding UTF8

    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript
    if ($LASTEXITCODE -ne 0) {
        throw "VO commercial readiness validation failed during stale-input recovery test."
    }

    $castPlan = Get-Content -LiteralPath $castPlanPath -Raw | ConvertFrom-Json
    $audioStatus = Get-Content -LiteralPath $audioStatusPath -Raw | ConvertFrom-Json
    $readiness = Get-Content -LiteralPath $readinessPath -Raw | ConvertFrom-Json

    if ([int]$castPlan.scratch_cast_count -ne 9 -or [int]$castPlan.needs_cast_decision_count -ne 8) {
        throw "VO commercial readiness did not regenerate the cast plan before export."
    }
    if ([int]$audioStatus.present_count -ne 0 -or [int]$audioStatus.missing_count -ne 652) {
        throw "VO commercial readiness did not regenerate audio status before export."
    }
    if ([int]$readiness.scratch_cast_count -ne 9 -or [int]$readiness.present_audio_count -ne 0 -or [int]$readiness.missing_audio_count -ne 652) {
        throw "VO commercial readiness report used stale upstream VO counts."
    }
}
finally {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript
    if ($LASTEXITCODE -ne 0) {
        throw "VO commercial readiness validation failed while restoring after stale-input test."
    }
}

Write-Host "VO commercial readiness tests passed: stale cast/audio JSON is regenerated before shipping blocker export."
