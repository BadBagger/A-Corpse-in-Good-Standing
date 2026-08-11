$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$trackerMdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$psdPath = Join-Path $root "art\src\backgrounds\act_i\harbor_registry.psd"
$completionPath = Join-Path $root "docs\art\act_i_final_paintover_completion.json"
$completionMdPath = Join-Path $root "docs\art\act_i_final_paintover_completion.md"
$setDecisionScript = Join-Path $PSScriptRoot "Set-ActIReviewDecision.ps1"
$completionScript = Join-Path $PSScriptRoot "Validate-ActIFinalPaintoverCompletion.ps1"
$assetStatusScript = Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1"
$startGateScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverStartGate.ps1"
$workOrderScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverWorkOrder.ps1"
$intakeScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverSourceIntake.ps1"

foreach ($path in @($trackerPath, $trackerMdPath, $setDecisionScript, $completionScript, $assetStatusScript, $startGateScript, $workOrderScript, $intakeScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I final paintover completion test input: $path"
    }
}
if (Test-Path -LiteralPath $psdPath) {
    throw "Act I final paintover completion test refuses to overwrite existing PSD fixture: $psdPath"
}

$originalTrackerJson = Get-Content -LiteralPath $trackerPath -Raw
$originalTrackerMd = Get-Content -LiteralPath $trackerMdPath -Raw
$originalCompletionJson = if (Test-Path -LiteralPath $completionPath) { Get-Content -LiteralPath $completionPath -Raw } else { $null }
$originalCompletionMd = if (Test-Path -LiteralPath $completionMdPath) { Get-Content -LiteralPath $completionMdPath -Raw } else { $null }

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $completionScript
    if ($LASTEXITCODE -ne 0) { throw "Initial final paintover completion validation failed." }
    $completion = Get-Content -LiteralPath $completionPath -Raw | ConvertFrom-Json
    if ([int]$completion.complete_count -ne 0 -or [int]$completion.blocked_not_started_count -ne 11) {
        throw "Initial final paintover completion state should be 0 complete / 11 blocked."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setDecisionScript -RoomId "harbor_registry" -Decision "approved" -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Approve Harbor Registry for final-paintover completion simulation; accepted Litany format preserved."
    if ($LASTEXITCODE -ne 0) { throw "Failed to approve Harbor Registry for completion simulation." }
    [System.IO.File]::WriteAllBytes($psdPath, [byte[]](0x38, 0x42, 0x50, 0x53, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    Start-Sleep -Milliseconds 50

    & powershell -NoProfile -ExecutionPolicy Bypass -File $assetStatusScript
    if ($LASTEXITCODE -ne 0) { throw "Asset status validation failed after simulated PSD." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startGateScript
    if ($LASTEXITCODE -ne 0) { throw "Start gate validation failed after simulated PSD." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Work order validation failed after simulated PSD." }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $completionScript
    if ($LASTEXITCODE -ne 0) { throw "Final paintover completion validation failed after simulated PSD." }
    $completion = Get-Content -LiteralPath $completionPath -Raw | ConvertFrom-Json
    $registry = @($completion.rows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    if ($registry.completion_status -ne "pending_final_export") {
        throw "Accepted Harbor Registry PSD should require a newer final export, got $($registry.completion_status)."
    }
    if ($registry.reviewer -ne "Automated test" -or $registry.reviewed_at -ne "2026-08-11" -or $registry.decision_note -notmatch "final-paintover completion simulation") {
        throw "Final paintover completion did not preserve reviewer metadata from source intake."
    }
    if ($registry.source_content_status -ne "valid_psd_source" -or -not [bool]$registry.valid_paintover_source -or [int64]$registry.source_size_bytes -le 0) {
        throw "Final paintover completion did not preserve valid PSD source proof from source intake."
    }
    if ([int]$completion.complete_count -ne 0 -or [int]$completion.pending_final_export_count -ne 1) {
        throw "Simulated accepted PSD should not count as complete without a newer export."
    }
}
finally {
    if (Test-Path -LiteralPath $psdPath) {
        Remove-Item -LiteralPath $psdPath -Force
    }
    Set-Content -LiteralPath $trackerPath -Value $originalTrackerJson -Encoding UTF8
    Set-Content -LiteralPath $trackerMdPath -Value $originalTrackerMd -Encoding UTF8
    if ($null -ne $originalCompletionJson) { Set-Content -LiteralPath $completionPath -Value $originalCompletionJson -Encoding UTF8 }
    if ($null -ne $originalCompletionMd) { Set-Content -LiteralPath $completionMdPath -Value $originalCompletionMd -Encoding UTF8 }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $assetStatusScript
    if ($LASTEXITCODE -ne 0) { throw "Asset status validation failed while restoring after completion test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startGateScript
    if ($LASTEXITCODE -ne 0) { throw "Start gate validation failed while restoring after completion test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Work order validation failed while restoring after completion test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript
    if ($LASTEXITCODE -ne 0) { throw "Source intake validation failed while restoring after completion test." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $completionScript
    if ($LASTEXITCODE -ne 0) { throw "Final paintover completion validation failed while restoring after completion test." }
}

Write-Host "Act I final paintover completion tests passed and restored tracker/source/completion artifacts."
