$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$trackerMdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$psdPath = Join-Path $root "art\src\backgrounds\act_i\harbor_registry.psd"
$provenancePath = Join-Path $root "docs\art\act_i_paintover_review_provenance.json"
$provenanceMdPath = Join-Path $root "docs\art\act_i_paintover_review_provenance.md"
$setDecisionScript = Join-Path $PSScriptRoot "Set-ActIReviewDecision.ps1"
$provenanceScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverReviewProvenance.ps1"
$assetStatusScript = Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1"
$startGateScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverStartGate.ps1"
$workOrderScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverWorkOrder.ps1"
$intakeScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverSourceIntake.ps1"
$completionScript = Join-Path $PSScriptRoot "Validate-ActIFinalPaintoverCompletion.ps1"

foreach ($path in @($trackerPath, $trackerMdPath, $setDecisionScript, $provenanceScript, $assetStatusScript, $startGateScript, $workOrderScript, $intakeScript, $completionScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover review provenance test input: $path"
    }
}
if (Test-Path -LiteralPath $psdPath) {
    throw "Act I paintover review provenance test refuses to overwrite existing PSD fixture: $psdPath"
}

function Normalize-TestRestoreText {
    param([string]$Text)
    return $Text.TrimEnd("`r", "`n") + "`r`n"
}

$originalTrackerJson = Normalize-TestRestoreText (Get-Content -LiteralPath $trackerPath -Raw)
$originalTrackerMd = Normalize-TestRestoreText (Get-Content -LiteralPath $trackerMdPath -Raw)
$originalProvenanceJson = if (Test-Path -LiteralPath $provenancePath) { Get-Content -LiteralPath $provenancePath -Raw } else { $null }
$originalProvenanceMd = if (Test-Path -LiteralPath $provenanceMdPath) { Get-Content -LiteralPath $provenanceMdPath -Raw } else { $null }

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $provenanceScript
    if ($LASTEXITCODE -ne 0) { throw "Initial paintover review provenance validation failed." }
    $initial = Get-Content -LiteralPath $provenancePath -Raw | ConvertFrom-Json
    if ([int]$initial.approved_count -ne 0 -or [int]$initial.work_order_count -ne 0) {
        throw "Initial provenance state should have 0 approved / 0 work-order rooms."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setDecisionScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit "abcdef1" -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Approve Harbor Registry for end-to-end provenance simulation; accepted Litany format preserved." -LookTargetReviewed "yes"
    if ($LASTEXITCODE -ne 0) { throw "Failed to approve Harbor Registry for provenance simulation." }
    [System.IO.File]::WriteAllBytes($psdPath, [byte[]](0x38, 0x42, 0x50, 0x53, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    & powershell -NoProfile -ExecutionPolicy Bypass -File $assetStatusScript
    if ($LASTEXITCODE -ne 0) { throw "Asset status validation failed after provenance simulation PSD." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startGateScript
    if ($LASTEXITCODE -ne 0) { throw "Start gate validation failed after provenance simulation approval." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Work order validation failed after provenance simulation approval." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript
    if ($LASTEXITCODE -ne 0) { throw "Source intake validation failed after provenance simulation PSD." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $completionScript
    if ($LASTEXITCODE -ne 0) { throw "Completion validation failed after provenance simulation PSD." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $provenanceScript
    if ($LASTEXITCODE -ne 0) { throw "Paintover review provenance validation failed after simulation." }

    $audit = Get-Content -LiteralPath $provenancePath -Raw | ConvertFrom-Json
    $registry = @($audit.rows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    if ($null -eq $registry) {
        throw "Provenance audit missing simulated Harbor Registry row."
    }
    if ([int]$audit.approved_count -ne 1 -or [int]$audit.work_order_count -ne 1 -or [int]$audit.accepted_source_count -ne 1 -or [int]$audit.completion_approved_count -ne 1) {
        throw "Provenance audit did not carry simulated approval through all downstream layers."
    }
    if ($registry.build_commit -ne "abcdef1" -or $registry.reviewer -ne "Automated test" -or $registry.reviewed_at -ne "2026-08-11") {
        throw "Provenance audit did not preserve build_commit and reviewer metadata for Harbor Registry."
    }
    if ($registry.look_target_reviewed -ne "yes") {
        throw "Provenance audit did not preserve look-target acknowledgement for Harbor Registry."
    }
}
finally {
    if (Test-Path -LiteralPath $psdPath) {
        Remove-Item -LiteralPath $psdPath -Force
    }
    Set-Content -LiteralPath $trackerPath -Value $originalTrackerJson -Encoding UTF8
    Set-Content -LiteralPath $trackerMdPath -Value $originalTrackerMd -Encoding UTF8
    if ($null -ne $originalProvenanceJson) { Set-Content -LiteralPath $provenancePath -Value $originalProvenanceJson -Encoding UTF8 }
    if ($null -ne $originalProvenanceMd) { Set-Content -LiteralPath $provenanceMdPath -Value $originalProvenanceMd -Encoding UTF8 }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $assetStatusScript
    if ($LASTEXITCODE -ne 0) { throw "Asset status validation failed while restoring after provenance test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startGateScript
    if ($LASTEXITCODE -ne 0) { throw "Start gate validation failed while restoring after provenance test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Work order validation failed while restoring after provenance test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript
    if ($LASTEXITCODE -ne 0) { throw "Source intake validation failed while restoring after provenance test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $completionScript
    if ($LASTEXITCODE -ne 0) { throw "Completion validation failed while restoring after provenance test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $provenanceScript
    if ($LASTEXITCODE -ne 0) { throw "Provenance validation failed while restoring after provenance test." }
}

Write-Host "Act I paintover review provenance tests passed and restored tracker/source/provenance artifacts."
