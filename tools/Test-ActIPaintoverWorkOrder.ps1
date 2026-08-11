$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$trackerMdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$startGatePath = Join-Path $root "docs\art\act_i_paintover_start_gate.json"
$startGateMdPath = Join-Path $root "docs\art\act_i_paintover_start_gate.md"
$workOrderPath = Join-Path $root "docs\art\act_i_paintover_work_order.json"
$workOrderMdPath = Join-Path $root "docs\art\act_i_paintover_work_order.md"
$setDecisionScript = Join-Path $PSScriptRoot "Set-ActIReviewDecision.ps1"
$validateStartGateScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverStartGate.ps1"
$validateWorkOrderScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverWorkOrder.ps1"

foreach ($path in @($trackerPath, $trackerMdPath, $setDecisionScript, $validateStartGateScript, $validateWorkOrderScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover work order test input: $path"
    }
}

$originalTrackerJson = Get-Content -LiteralPath $trackerPath -Raw
$originalTrackerMd = Get-Content -LiteralPath $trackerMdPath -Raw
$originalStartGateJson = if (Test-Path -LiteralPath $startGatePath) { Get-Content -LiteralPath $startGatePath -Raw } else { $null }
$originalStartGateMd = if (Test-Path -LiteralPath $startGateMdPath) { Get-Content -LiteralPath $startGateMdPath -Raw } else { $null }
$originalWorkOrderJson = if (Test-Path -LiteralPath $workOrderPath) { Get-Content -LiteralPath $workOrderPath -Raw } else { $null }
$originalWorkOrderMd = if (Test-Path -LiteralPath $workOrderMdPath) { Get-Content -LiteralPath $workOrderMdPath -Raw } else { $null }

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateStartGateScript
    if ($LASTEXITCODE -ne 0) { throw "Initial start gate validation failed." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateWorkOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Initial empty work order validation failed." }

    $workOrder = Get-Content -LiteralPath $workOrderPath -Raw | ConvertFrom-Json
    if ($workOrder.status -ne "empty_pending_human_review" -or [int]$workOrder.ready_room_count -ne 0) {
        throw "Initial work order should be empty while no rooms are approved."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setDecisionScript -RoomId "harbor_registry" -Decision "approved" -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Approve Harbor Registry for work-order simulation; accepted Litany format preserved."
    if ($LASTEXITCODE -ne 0) { throw "Failed to approve Harbor Registry for work order simulation." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateStartGateScript
    if ($LASTEXITCODE -ne 0) { throw "Start gate validation failed after simulated approval." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateWorkOrderScript
    if ($LASTEXITCODE -ne 0) { throw "Work order validation failed after simulated approval." }

    $workOrder = Get-Content -LiteralPath $workOrderPath -Raw | ConvertFrom-Json
    $rooms = @($workOrder.rooms)
    if ($workOrder.status -ne "ready_rooms_available" -or $rooms.Count -ne 1) {
        throw "Simulated approval should produce one ready work-order room."
    }
    $room = $rooms[0]
    if ($room.room_id -ne "harbor_registry") {
        throw "Simulated work order expected Harbor Registry, got $($room.room_id)."
    }
    if ("duel_format_lock" -notin @($room.risk_tags)) {
        throw "Harbor Registry work order must preserve duel_format_lock risk tag."
    }
    if ($room.reviewer -ne "Automated test" -or $room.reviewed_at -ne "2026-08-11" -or $room.decision_note -notmatch "work-order simulation") {
        throw "Harbor Registry work order did not preserve reviewer metadata from the start gate."
    }
}
finally {
    Set-Content -LiteralPath $trackerPath -Value $originalTrackerJson -Encoding UTF8
    Set-Content -LiteralPath $trackerMdPath -Value $originalTrackerMd -Encoding UTF8
    if ($null -ne $originalStartGateJson) { Set-Content -LiteralPath $startGatePath -Value $originalStartGateJson -Encoding UTF8 }
    if ($null -ne $originalStartGateMd) { Set-Content -LiteralPath $startGateMdPath -Value $originalStartGateMd -Encoding UTF8 }
    if ($null -ne $originalWorkOrderJson) { Set-Content -LiteralPath $workOrderPath -Value $originalWorkOrderJson -Encoding UTF8 }
    if ($null -ne $originalWorkOrderMd) { Set-Content -LiteralPath $workOrderMdPath -Value $originalWorkOrderMd -Encoding UTF8 }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateStartGateScript
    if ($LASTEXITCODE -ne 0) {
        throw "Start gate validation failed while restoring after work order test."
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateWorkOrderScript
    if ($LASTEXITCODE -ne 0) {
        throw "Work order validation failed while restoring after work order test."
    }
}

Write-Host "Act I paintover work order tests passed and restored tracker/start-gate/work-order artifacts."
