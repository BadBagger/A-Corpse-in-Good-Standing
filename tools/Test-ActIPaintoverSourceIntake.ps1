$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$trackerMdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$psdPath = Join-Path $root "art\src\backgrounds\act_i\harbor_registry.psd"
$intakePath = Join-Path $root "docs\art\act_i_paintover_source_intake.json"
$intakeMdPath = Join-Path $root "docs\art\act_i_paintover_source_intake.md"
$setDecisionScript = Join-Path $PSScriptRoot "Set-ActIReviewDecision.ps1"
$startGateScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverStartGate.ps1"
$workOrderScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverWorkOrder.ps1"
$intakeScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverSourceIntake.ps1"
$assetStatusScript = Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1"

foreach ($path in @($trackerPath, $trackerMdPath, $setDecisionScript, $startGateScript, $workOrderScript, $intakeScript, $assetStatusScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover source intake test input: $path"
    }
}
if (Test-Path -LiteralPath $psdPath) {
    throw "Act I paintover source intake test refuses to overwrite existing PSD fixture: $psdPath"
}

function Normalize-TestRestoreText {
    param([string]$Text)
    return $Text.TrimEnd("`r", "`n") + "`r`n"
}

$originalTrackerJson = Normalize-TestRestoreText (Get-Content -LiteralPath $trackerPath -Raw)
$originalTrackerMd = Normalize-TestRestoreText (Get-Content -LiteralPath $trackerMdPath -Raw)
$originalIntakeJson = if (Test-Path -LiteralPath $intakePath) { Get-Content -LiteralPath $intakePath -Raw } else { $null }
$originalIntakeMd = if (Test-Path -LiteralPath $intakeMdPath) { Get-Content -LiteralPath $intakeMdPath -Raw } else { $null }

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript
    if ($LASTEXITCODE -ne 0) { throw "Initial paintover source intake validation failed." }

    [System.IO.File]::WriteAllBytes($psdPath, [byte[]](0x38, 0x42, 0x50, 0x53, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $blockedOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript 2>&1
        $blockedExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($blockedExitCode -eq 0) {
        throw "Paintover source intake should fail when a blocked-room PSD exists."
    }
    if (($blockedOutput -join "`n") -notmatch "without work-order approval") {
        throw "Paintover source intake failure did not explain unapproved PSD."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setDecisionScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit "abcdef1" -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Approve Harbor Registry for source-intake simulation; accepted Litany format preserved."
    if ($LASTEXITCODE -ne 0) { throw "Failed to approve Harbor Registry for intake simulation." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startGateScript
    if ($LASTEXITCODE -ne 0) { throw "Start gate validation failed after intake simulation approval." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Work order validation failed after intake simulation approval." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript
    if ($LASTEXITCODE -ne 0) { throw "Paintover source intake should pass for approved-room PSD." }

    $intake = Get-Content -LiteralPath $intakePath -Raw | ConvertFrom-Json
    if ([int]$intake.accepted_present_count -ne 1 -or [int]$intake.unapproved_present_count -ne 0) {
        throw "Paintover source intake did not accept exactly one approved PSD in simulation."
    }
    $registryRow = @($intake.rows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    if ($registryRow.build_commit -ne "abcdef1" -or $registryRow.reviewer -ne "Automated test" -or $registryRow.reviewed_at -ne "2026-08-11" -or $registryRow.decision_note -notmatch "source-intake simulation") {
        throw "Paintover source intake did not preserve build_commit and reviewer metadata from the approved work order."
    }
    if ($registryRow.content_status -ne "valid_psd_source" -or -not [bool]$registryRow.valid_paintover_source) {
        throw "Paintover source intake did not preserve valid PSD source proof."
    }

    Set-Content -LiteralPath $psdPath -Value "temporary intake test placeholder" -Encoding ASCII
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $placeholderOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript 2>&1
        $placeholderExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($placeholderExitCode -eq 0) {
        throw "Paintover source intake should fail when an approved-room PSD is a text placeholder."
    }
    if (($placeholderOutput -join "`n") -notmatch "PSD-like 8BPS") {
        throw "Paintover source intake placeholder failure did not explain PSD signature requirement."
    }
}
finally {
    if (Test-Path -LiteralPath $psdPath) {
        Remove-Item -LiteralPath $psdPath -Force
    }
    Set-Content -LiteralPath $trackerPath -Value $originalTrackerJson -Encoding UTF8
    Set-Content -LiteralPath $trackerMdPath -Value $originalTrackerMd -Encoding UTF8
    if ($null -ne $originalIntakeJson) { Set-Content -LiteralPath $intakePath -Value $originalIntakeJson -Encoding UTF8 }
    if ($null -ne $originalIntakeMd) { Set-Content -LiteralPath $intakeMdPath -Value $originalIntakeMd -Encoding UTF8 }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $assetStatusScript
    if ($LASTEXITCODE -ne 0) { throw "Asset status validation failed while restoring after intake test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startGateScript
    if ($LASTEXITCODE -ne 0) { throw "Start gate validation failed while restoring after intake test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Work order validation failed while restoring after intake test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript
    if ($LASTEXITCODE -ne 0) { throw "Paintover source intake validation failed while restoring after intake test." }
}

Write-Host "Act I paintover source intake tests passed and restored tracker/work-order/source artifacts."
