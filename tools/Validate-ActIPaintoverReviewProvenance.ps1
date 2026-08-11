$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$completionScript = Join-Path $PSScriptRoot "Validate-ActIFinalPaintoverCompletion.ps1"
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$startGatePath = Join-Path $root "docs\art\act_i_paintover_start_gate.json"
$workOrderPath = Join-Path $root "docs\art\act_i_paintover_work_order.json"
$intakePath = Join-Path $root "docs\art\act_i_paintover_source_intake.json"
$completionPath = Join-Path $root "docs\art\act_i_final_paintover_completion.json"
$jsonPath = Join-Path $root "docs\art\act_i_paintover_review_provenance.json"
$mdPath = Join-Path $root "docs\art\act_i_paintover_review_provenance.md"

if (-not (Test-Path -LiteralPath $completionScript)) {
    throw "Missing Act I paintover review provenance dependency: $completionScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $completionScript
if ($LASTEXITCODE -ne 0) {
    throw "Final paintover completion validation failed before provenance audit."
}

foreach ($path in @($trackerPath, $startGatePath, $workOrderPath, $intakePath, $completionPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover review provenance input: $path"
    }
}

$tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
$startGate = Get-Content -LiteralPath $startGatePath -Raw | ConvertFrom-Json
$workOrder = Get-Content -LiteralPath $workOrderPath -Raw | ConvertFrom-Json
$intake = Get-Content -LiteralPath $intakePath -Raw | ConvertFrom-Json
$completion = Get-Content -LiteralPath $completionPath -Raw | ConvertFrom-Json

$trackerRooms = @($tracker.rooms)
$startGateRooms = @($startGate.rooms)
$workOrderRooms = @($workOrder.rooms)
$intakeRows = @($intake.rows)
$completionRows = @($completion.rows)
if ($trackerRooms.Count -ne 11 -or $startGateRooms.Count -ne 11 -or $intakeRows.Count -ne 11 -or $completionRows.Count -ne 11) {
    throw "Act I paintover review provenance expected 11 tracker/start-gate/intake/completion rooms."
}

function Get-Proof {
    param($Row)

    return [ordered]@{
        review_status = [string]$Row.review_status
        reviewer_decision = [string]$Row.reviewer_decision
        reviewer = [string]$Row.reviewer
        reviewed_at = [string]$Row.reviewed_at
        decision_note = [string]$Row.decision_note
    }
}

function Assert-ProofPresent {
    param(
        [string]$RoomId,
        [string]$Layer,
        $Row
    )

    foreach ($field in @("review_status", "reviewer_decision", "reviewer", "reviewed_at", "decision_note")) {
        if ($null -eq $Row.$field -or [string]$Row.$field -eq "") {
            throw "Room $RoomId has approved $Layer state without review proof field: $field"
        }
    }
}

function Assert-ProofMatches {
    param(
        [string]$RoomId,
        [string]$FromLayer,
        $FromRow,
        [string]$ToLayer,
        $ToRow
    )

    foreach ($field in @("review_status", "reviewer_decision", "reviewer", "reviewed_at", "decision_note")) {
        if ([string]$FromRow.$field -ne [string]$ToRow.$field) {
            throw "Room $RoomId review proof mismatch from $FromLayer to $ToLayer on field $field."
        }
    }
}

$auditRows = @()
foreach ($trackerRoom in $trackerRooms) {
    $roomId = [string]$trackerRoom.room_id
    $startGateRoom = @($startGateRooms | Where-Object { $_.room_id -eq $roomId })[0]
    $workOrderRoom = @($workOrderRooms | Where-Object { $_.room_id -eq $roomId })[0]
    $intakeRow = @($intakeRows | Where-Object { $_.room_id -eq $roomId })[0]
    $completionRow = @($completionRows | Where-Object { $_.room_id -eq $roomId })[0]
    if ($null -eq $startGateRoom -or $null -eq $intakeRow -or $null -eq $completionRow) {
        throw "Act I paintover review provenance missing downstream row for room: $roomId"
    }

    $approved = [bool]$trackerRoom.approved_for_paintover
    if ($approved) {
        Assert-ProofPresent -RoomId $roomId -Layer "tracker" -Row $trackerRoom
        Assert-ProofPresent -RoomId $roomId -Layer "start gate" -Row $startGateRoom
        Assert-ProofMatches -RoomId $roomId -FromLayer "tracker" -FromRow $trackerRoom -ToLayer "start gate" -ToRow $startGateRoom
    }
    if ($null -ne $workOrderRoom) {
        Assert-ProofPresent -RoomId $roomId -Layer "work order" -Row $workOrderRoom
        Assert-ProofMatches -RoomId $roomId -FromLayer "start gate" -FromRow $startGateRoom -ToLayer "work order" -ToRow $workOrderRoom
    }
    if ($intakeRow.approved_by_work_order -eq "True" -or [bool]$intakeRow.approved_by_work_order) {
        if ($null -eq $workOrderRoom) {
            throw "Room $roomId has approved intake without a work-order row."
        }
        Assert-ProofPresent -RoomId $roomId -Layer "source intake" -Row $intakeRow
        Assert-ProofMatches -RoomId $roomId -FromLayer "work order" -FromRow $workOrderRoom -ToLayer "source intake" -ToRow $intakeRow
    }
    if ($completionRow.approved_by_work_order -eq "True" -or [bool]$completionRow.approved_by_work_order) {
        Assert-ProofPresent -RoomId $roomId -Layer "final completion" -Row $completionRow
        Assert-ProofMatches -RoomId $roomId -FromLayer "source intake" -FromRow $intakeRow -ToLayer "final completion" -ToRow $completionRow
    }

    $auditRows += [pscustomobject][ordered]@{
        room_code = $trackerRoom.room_code
        room_id = $roomId
        title = $trackerRoom.title
        tracker_decision = $trackerRoom.reviewer_decision
        start_gate_ready = [bool]$startGateRoom.ready_for_paintover
        work_order_present = $null -ne $workOrderRoom
        intake_status = $intakeRow.intake_status
        completion_status = $completionRow.completion_status
        reviewer = if ($approved) { [string]$trackerRoom.reviewer } else { "" }
        reviewed_at = if ($approved) { [string]$trackerRoom.reviewed_at } else { "" }
    }
}

$approvedRows = @($auditRows | Where-Object { $_.tracker_decision -eq "approved" })
$workOrderRows = @($auditRows | Where-Object { $_.work_order_present })
$acceptedRows = @($auditRows | Where-Object { $_.intake_status -eq "accepted_present" })
$completionApprovedRows = @($auditRows | Where-Object { $_.completion_status -in @("complete", "pending_final_export", "approved_source_missing") })

$audit = [ordered]@{
    generated_from = @(
        "docs/playtest/act_i_review_fix_tracker.json",
        "docs/art/act_i_paintover_start_gate.json",
        "docs/art/act_i_paintover_work_order.json",
        "docs/art/act_i_paintover_source_intake.json",
        "docs/art/act_i_final_paintover_completion.json"
    )
    purpose = "Verify Act I paintover human-review provenance across final-art gates."
    status = "pass"
    room_count = $auditRows.Count
    approved_count = $approvedRows.Count
    work_order_count = $workOrderRows.Count
    accepted_source_count = $acceptedRows.Count
    completion_approved_count = $completionApprovedRows.Count
    rows = $auditRows
}
$audit | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Act I Paintover Review Provenance",
    "",
    'Generated by `tools/Validate-ActIPaintoverReviewProvenance.ps1` from the review tracker, start gate, work order, source intake, and final completion audit.',
    "",
    "Purpose: verify that human-review proof survives every final-art handoff layer.",
    "",
    "Status: pass",
    "Rooms: $($auditRows.Count)",
    "Approved tracker rooms: $($approvedRows.Count)",
    "Work-order rooms: $($workOrderRows.Count)",
    "Accepted source rows: $($acceptedRows.Count)",
    "Completion-approved rows: $($completionApprovedRows.Count)",
    "",
    "Rule locks:",
    "- Approved rooms must carry reviewer, reviewed_at, and decision_note.",
    "- Start gate, work order, source intake, and final completion proof must match the tracker proof exactly.",
    "- Blocked rooms may have blank reviewer fields but cannot appear as approved downstream.",
    "",
    "| Room | Decision | Start Ready | Work Order | Intake | Completion | Reviewer | Reviewed At |",
    "|---|---|---|---|---|---|---|---|"
)
foreach ($row in ($auditRows | Sort-Object room_code)) {
    $reviewerText = if ([string]::IsNullOrWhiteSpace([string]$row.reviewer)) { "none" } else { [string]$row.reviewer }
    $reviewedAtText = if ([string]::IsNullOrWhiteSpace([string]$row.reviewed_at)) { "none" } else { [string]$row.reviewed_at }
    $lines += "| $($row.room_code) $($row.title) | $($row.tracker_decision) | $($row.start_gate_ready) | $($row.work_order_present) | $($row.intake_status) | $($row.completion_status) | $reviewerText | $reviewedAtText |"
}
Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Paintover Review Provenance",
    "human-review proof survives every final-art handoff layer",
    "Start gate, work order, source intake, and final completion proof must match the tracker proof exactly"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover review provenance report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @("System.Object[]", "@{", "ÃƒÂ¯Ã‚Â»Ã‚Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I paintover review provenance report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I paintover review provenance report must stay ASCII-only."
}

Write-Host "Act I paintover review provenance validation passed: rooms=$($auditRows.Count), approved=$($approvedRows.Count), workOrder=$($workOrderRows.Count), accepted=$($acceptedRows.Count)."
