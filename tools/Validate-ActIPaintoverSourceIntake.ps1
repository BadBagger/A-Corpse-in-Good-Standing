$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$assetStatusScript = Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1"
$workOrderScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverWorkOrder.ps1"
$assetStatusPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$workOrderPath = Join-Path $root "docs\art\act_i_paintover_work_order.json"
$jsonPath = Join-Path $root "docs\art\act_i_paintover_source_intake.json"
$mdPath = Join-Path $root "docs\art\act_i_paintover_source_intake.md"

foreach ($path in @($assetStatusScript, $workOrderScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover source intake validator dependency: $path"
    }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $assetStatusScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I background asset status validation failed before paintover intake."
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $workOrderScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I paintover work order validation failed before paintover intake."
}

foreach ($path in @($assetStatusPath, $workOrderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover source intake input: $path"
    }
}

$rows = @(Import-Csv -LiteralPath $assetStatusPath)
$workOrder = Get-Content -LiteralPath $workOrderPath -Raw | ConvertFrom-Json
$approvedRoomIds = @($workOrder.rooms | ForEach-Object { $_.room_id })
$workOrderByRoom = @{}
foreach ($approvedRoom in @($workOrder.rooms)) {
    foreach ($requiredReviewField in @("review_status", "reviewer_decision", "build_commit", "reviewer", "reviewed_at", "decision_note", "look_target_reviewed", "corvin_action_scaffold_reviewed")) {
        if ($null -eq $approvedRoom.$requiredReviewField -or [string]$approvedRoom.$requiredReviewField -eq "") {
            throw "Approved work-order room $($approvedRoom.room_id) is missing review proof field for source intake: $requiredReviewField"
        }
    }
    $workOrderByRoom[$approvedRoom.room_id] = $approvedRoom
}
$paintoverRows = @($rows | Where-Object { $_.asset_kind -eq "paintover_source" })
if ($paintoverRows.Count -ne 11) {
    throw "Act I paintover source intake expected 11 paintover rows, got $($paintoverRows.Count)."
}

$intakeRows = @()
foreach ($row in $paintoverRows) {
    $approved = $row.room_id -in $approvedRoomIds
    $approvedWorkRoom = if ($approved) { $workOrderByRoom[$row.room_id] } else { $null }
    $present = $row.status -eq "present"
    $validPaintoverSource = $present -and $row.content_status -eq "valid_psd_source"
    $status = if ($present -and $approved) {
        "accepted_present"
    } elseif ($present -and -not $approved) {
        "unapproved_present"
    } elseif (-not $present -and $approved) {
        "approved_missing"
    } else {
        "blocked_pending"
    }
    $intakeRows += [pscustomobject][ordered]@{
        room_code = $row.room_code
        room_id = $row.room_id
        title = $row.title
        approved_by_work_order = $approved
        review_status = if ($approved) { $approvedWorkRoom.review_status } else { "" }
        reviewer_decision = if ($approved) { $approvedWorkRoom.reviewer_decision } else { "" }
        build_commit = if ($approved) { $approvedWorkRoom.build_commit } else { "" }
        reviewer = if ($approved) { $approvedWorkRoom.reviewer } else { "" }
        reviewed_at = if ($approved) { $approvedWorkRoom.reviewed_at } else { "" }
        decision_note = if ($approved) { $approvedWorkRoom.decision_note } else { "" }
        look_target_reviewed = if ($approved) { $approvedWorkRoom.look_target_reviewed } else { "" }
        corvin_action_scaffold_reviewed = if ($approved) { $approvedWorkRoom.corvin_action_scaffold_reviewed } else { "" }
        source_status = $row.status
        content_status = $row.content_status
        size_bytes = [int64]$row.size_bytes
        valid_paintover_source = $validPaintoverSource
        intake_status = $status
        relative_path = $row.relative_path
    }
}

foreach ($intakeRow in @($intakeRows | Where-Object { [bool]$_.approved_by_work_order })) {
    $workRoom = $workOrderByRoom[$intakeRow.room_id]
    foreach ($requiredReviewField in @("review_status", "reviewer_decision", "build_commit", "reviewer", "reviewed_at", "decision_note", "look_target_reviewed", "corvin_action_scaffold_reviewed")) {
        if ($null -eq $intakeRow.$requiredReviewField -or [string]$intakeRow.$requiredReviewField -eq "") {
            throw "Approved intake row $($intakeRow.room_id) is missing review proof field: $requiredReviewField"
        }
        if ([string]$intakeRow.$requiredReviewField -ne [string]$workRoom.$requiredReviewField) {
            throw "Approved intake row $($intakeRow.room_id) review proof does not match work order field: $requiredReviewField"
        }
    }
}

$unapprovedPresent = @($intakeRows | Where-Object { $_.intake_status -eq "unapproved_present" })
if ($unapprovedPresent.Count -gt 0) {
    $badRooms = ($unapprovedPresent | ForEach-Object { "$($_.room_code) $($_.title)" }) -join ", "
    throw "Blocked Act I rooms have final paintover PSD sources present without work-order approval: $badRooms"
}

$invalidApprovedSources = @($intakeRows | Where-Object { $_.approved_by_work_order -and $_.source_status -eq "present" -and -not $_.valid_paintover_source })
if ($invalidApprovedSources.Count -gt 0) {
    $badRooms = ($invalidApprovedSources | ForEach-Object { "$($_.room_code) $($_.title) ($($_.content_status))" }) -join ", "
    throw "Approved Act I paintover source rows must be valid PSD-like 8BPS files: $badRooms"
}

$acceptedPresent = @($intakeRows | Where-Object { $_.intake_status -eq "accepted_present" })
$approvedMissing = @($intakeRows | Where-Object { $_.intake_status -eq "approved_missing" })
$blockedPending = @($intakeRows | Where-Object { $_.intake_status -eq "blocked_pending" })
$status = if ($acceptedPresent.Count -gt 0) { "approved_sources_present" } else { "no_approved_sources_present" }

$intake = [ordered]@{
    generated_from = @(
        "docs/art/act_i_background_asset_status.csv",
        "docs/art/act_i_paintover_work_order.json"
    )
    purpose = "Validate final paintover source intake against approved-room work order."
    status = $status
    accepted_present_count = $acceptedPresent.Count
    approved_missing_count = $approvedMissing.Count
    blocked_pending_count = $blockedPending.Count
    unapproved_present_count = $unapprovedPresent.Count
    rows = $intakeRows
}
$intake | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Act I Paintover Source Intake",
    "",
    'Generated by `tools/Validate-ActIPaintoverSourceIntake.ps1` from the background asset status and approved-room paintover work order.',
    "",
    "Purpose: refuse final PSD paintover sources for rooms that have not passed the paintover start gate.",
    "",
    "Status: $status",
    "Accepted present: $($acceptedPresent.Count)",
    "Approved missing: $($approvedMissing.Count)",
    "Blocked pending: $($blockedPending.Count)",
    "Unapproved present: $($unapprovedPresent.Count)",
    "",
    "Rule locks:",
    "- A PSD can count only when the room appears in the approved-room work order.",
    "- A PSD can be accepted only when asset status reports valid_psd_source with a nonzero size.",
    "- Approved or accepted PSD rows must preserve build_commit, reviewer metadata, look_target_reviewed, and corvin_action_scaffold_reviewed from the work order.",
    "- Do not create placeholder PSDs for blocked rooms.",
    "- Accepted Litany/Registrar duel format remains locked.",
    "- Grey Float remains hard-R: steam, silhouette, privacy, and agency only.",
    "",
    "| Room | Work Order Approved | Build | Reviewer | Reviewed At | Look Target | Corvin Scaffold | Source Status | Content Status | Bytes | Intake Status | Path |",
    "|---|---|---|---|---|---|---|---|---|---:|---|---|"
)
foreach ($row in ($intakeRows | Sort-Object room_code)) {
    $buildText = if ([string]::IsNullOrWhiteSpace([string]$row.build_commit)) { "none" } else { [string]$row.build_commit }
    $reviewerText = if ([string]::IsNullOrWhiteSpace([string]$row.reviewer)) { "none" } else { [string]$row.reviewer }
    $reviewedAtText = if ([string]::IsNullOrWhiteSpace([string]$row.reviewed_at)) { "none" } else { [string]$row.reviewed_at }
    $lookTargetText = if ([string]::IsNullOrWhiteSpace([string]$row.look_target_reviewed)) { "none" } else { [string]$row.look_target_reviewed }
    $corvinScaffoldText = if ([string]::IsNullOrWhiteSpace([string]$row.corvin_action_scaffold_reviewed)) { "none" } else { [string]$row.corvin_action_scaffold_reviewed }
    $lines += "| $($row.room_code) $($row.title) | $($row.approved_by_work_order) | $buildText | $reviewerText | $reviewedAtText | $lookTargetText | $corvinScaffoldText | $($row.source_status) | $($row.content_status) | $($row.size_bytes) | $($row.intake_status) | ``$($row.relative_path)`` |"
}
Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I paintover source intake report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I paintover source intake report must stay ASCII-only."
}
foreach ($requiredText in @(
    "Approved or accepted PSD rows must preserve build_commit, reviewer metadata, look_target_reviewed, and corvin_action_scaffold_reviewed from the work order.",
    "valid_psd_source",
    "Build",
    "Reviewer",
    "Reviewed At",
    "Look Target",
    "Corvin Scaffold"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover source intake report missing review proof text: $requiredText"
    }
}

Write-Host "Act I paintover source intake validation passed: status=$status, accepted=$($acceptedPresent.Count), approvedMissing=$($approvedMissing.Count), blockedPending=$($blockedPending.Count)."
