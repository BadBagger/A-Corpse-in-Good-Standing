$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIPaintoverWorkOrder.ps1"
$jsonPath = Join-Path $root "docs\art\act_i_paintover_work_order.json"
$mdPath = Join-Path $root "docs\art\act_i_paintover_work_order.md"
$startGatePath = Join-Path $root "docs\art\act_i_paintover_start_gate.json"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I paintover work order exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I paintover work order export failed."
}

foreach ($path in @($jsonPath, $mdPath, $startGatePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover work order validation input: $path"
    }
}

$workOrder = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$startGate = Get-Content -LiteralPath $startGatePath -Raw | ConvertFrom-Json
$workRooms = @($workOrder.rooms)
$gateReadyRooms = @($startGate.rooms | Where-Object { [bool]$_.ready_for_paintover })

if ($workRooms.Count -ne $gateReadyRooms.Count) {
    throw "Paintover work order ready room count does not match start gate."
}
if ([int]$workOrder.ready_room_count -ne $workRooms.Count) {
    throw "Paintover work order ready_room_count does not match room list."
}
if ([int]$workOrder.blocked_room_count -ne [int]$startGate.blocked_count) {
    throw "Paintover work order blocked_room_count does not match start gate."
}
if ($workRooms.Count -eq 0 -and $workOrder.status -ne "empty_pending_human_review") {
    throw "Empty paintover work order must report empty_pending_human_review."
}
if ($workRooms.Count -gt 0 -and $workOrder.status -ne "ready_rooms_available") {
    throw "Non-empty paintover work order must report ready_rooms_available."
}

foreach ($room in $workRooms) {
    $gateRoom = @($gateReadyRooms | Where-Object { $_.room_id -eq $room.room_id })[0]
    if ($null -eq $gateRoom) {
        throw "Paintover work order includes room not ready in start gate: $($room.room_id)"
    }
    if (@($gateRoom.blockers).Count -gt 0) {
        throw "Paintover work order includes blocked room: $($room.room_id)"
    }
    foreach ($requiredReviewField in @("review_status", "reviewer_decision", "reviewer", "reviewed_at", "decision_note")) {
        if ($null -eq $room.$requiredReviewField -or [string]$room.$requiredReviewField -eq "") {
            throw "Paintover work order room $($room.room_id) missing review proof field: $requiredReviewField"
        }
    }
    if ($room.review_status -ne "approved" -or $room.reviewer_decision -ne "approved") {
        throw "Paintover work order room $($room.room_id) is not backed by approved review statuses."
    }
    foreach ($requiredReviewField in @("reviewer", "reviewed_at", "decision_note")) {
        if ([string]$room.$requiredReviewField -ne [string]$gateRoom.$requiredReviewField) {
            throw "Paintover work order room $($room.room_id) review proof does not match start gate field: $requiredReviewField"
        }
    }
    foreach ($requiredField in @("target_paintover_source", "scaffold", "blockout_reference", "overlay", "source_blend", "godot_background", "tone", "walk_band")) {
        if ($null -eq $room.$requiredField -or [string]$room.$requiredField -eq "") {
            throw "Paintover work order room $($room.room_id) missing field: $requiredField"
        }
    }
    foreach ($requiredLayer in @("00_blockout_reference_locked", "04_puzzle_hotspot_readability", "07_final_paint", "08_export_notes")) {
        if ($requiredLayer -notin @($room.layer_stack)) {
            throw "Paintover work order room $($room.room_id) missing layer: $requiredLayer"
        }
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Paintover Work Order",
    "Status: $($workOrder.status)",
    "Ready rooms in work order: $($workOrder.ready_room_count)",
    "Accepted Litany/Registrar duel format remains locked",
    "Grey Float remains hard-R",
    "Do not create placeholder PSDs"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover work order report missing required text: $requiredText"
    }
}
if ($workRooms.Count -gt 0) {
    foreach ($requiredText in @("Reviewer:", "Reviewed at:", "Decision note:")) {
        if ($report -notmatch [regex]::Escape($requiredText)) {
            throw "Act I paintover work order report missing review proof text: $requiredText"
        }
    }
}
foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I paintover work order contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I paintover work order must stay ASCII-only."
}

Write-Host "Act I paintover work order validation passed: status=$($workOrder.status), ready=$($workRooms.Count), blocked=$($workOrder.blocked_room_count)."
