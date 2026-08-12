$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$intakeScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverSourceIntake.ps1"
$paletteScript = Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1"
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$intakePath = Join-Path $root "docs\art\act_i_paintover_source_intake.json"
$palettePath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$jsonPath = Join-Path $root "docs\art\act_i_final_paintover_completion.json"
$mdPath = Join-Path $root "docs\art\act_i_final_paintover_completion.md"

foreach ($path in @($intakeScript, $paletteScript, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I final paintover completion input: $path"
    }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $intakeScript
if ($LASTEXITCODE -ne 0) {
    throw "Paintover source intake validation failed before final completion audit."
}
& powershell -NoProfile -ExecutionPolicy Bypass -File $paletteScript
if ($LASTEXITCODE -ne 0) {
    throw "Background palette audit validation failed before final completion audit."
}

foreach ($path in @($intakePath, $palettePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I final paintover completion generated input: $path"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$intake = Get-Content -LiteralPath $intakePath -Raw | ConvertFrom-Json
$paletteRows = @(Import-Csv -LiteralPath $palettePath)
$manifestRooms = @($manifest.rooms)
$intakeRows = @($intake.rows)

if ($manifestRooms.Count -ne 11 -or $intakeRows.Count -ne 11) {
    throw "Act I final paintover completion expected 11 manifest/intake rooms."
}

$completionRows = @()
foreach ($room in $manifestRooms) {
    $intakeRow = @($intakeRows | Where-Object { $_.room_id -eq $room.room_id })[0]
    $paletteRow = @($paletteRows | Where-Object { $_.room_id -eq $room.room_id })[0]
    if ($null -eq $intakeRow -or $null -eq $paletteRow) {
        throw "Act I final paintover completion missing intake or palette row for: $($room.room_id)"
    }
    $approvedByWorkOrder = $intakeRow.approved_by_work_order -eq "True" -or [bool]$intakeRow.approved_by_work_order
    if ($approvedByWorkOrder) {
        foreach ($requiredReviewField in @("review_status", "reviewer_decision", "build_commit", "reviewer", "reviewed_at", "decision_note", "look_target_reviewed")) {
            if ($null -eq $intakeRow.$requiredReviewField -or [string]$intakeRow.$requiredReviewField -eq "") {
                throw "Approved final paintover completion input $($room.room_id) is missing intake review proof field: $requiredReviewField"
            }
        }
        if ($intakeRow.intake_status -eq "accepted_present") {
            if ($intakeRow.content_status -ne "valid_psd_source" -or -not [bool]$intakeRow.valid_paintover_source -or [int64]$intakeRow.size_bytes -le 0) {
                throw "Accepted final paintover completion input $($room.room_id) lacks valid PSD source proof."
            }
        }
    }

    $sourcePath = Join-Path $root ($room.paintover_source -replace "/", "\")
    $exportPath = Join-Path $root ($room.export_png -replace "/", "\")
    $sourcePresent = Test-Path -LiteralPath $sourcePath
    $exportPresent = Test-Path -LiteralPath $exportPath
    $exportNewerThanSource = $false
    if ($sourcePresent -and $exportPresent) {
        $sourceTime = (Get-Item -LiteralPath $sourcePath).LastWriteTimeUtc
        $exportTime = (Get-Item -LiteralPath $exportPath).LastWriteTimeUtc
        $exportNewerThanSource = $exportTime -gt $sourceTime
    }

    $palettePass = $paletteRow.status -eq "audited" -and $paletteRow.pass -eq "True"
    $completionStatus = if ($intakeRow.intake_status -eq "accepted_present" -and $exportNewerThanSource -and $palettePass) {
        "complete"
    } elseif ($intakeRow.intake_status -eq "accepted_present") {
        "pending_final_export"
    } elseif ($approvedByWorkOrder) {
        "approved_source_missing"
    } else {
        "blocked_not_started"
    }

    $completionRows += [pscustomobject][ordered]@{
        room_code = $room.room_code
        room_id = $room.room_id
        title = $room.title
        approved_by_work_order = $approvedByWorkOrder
        review_status = if ($approvedByWorkOrder) { $intakeRow.review_status } else { "" }
        reviewer_decision = if ($approvedByWorkOrder) { $intakeRow.reviewer_decision } else { "" }
        build_commit = if ($approvedByWorkOrder) { $intakeRow.build_commit } else { "" }
        reviewer = if ($approvedByWorkOrder) { $intakeRow.reviewer } else { "" }
        reviewed_at = if ($approvedByWorkOrder) { $intakeRow.reviewed_at } else { "" }
        decision_note = if ($approvedByWorkOrder) { $intakeRow.decision_note } else { "" }
        look_target_reviewed = if ($approvedByWorkOrder) { $intakeRow.look_target_reviewed } else { "" }
        intake_status = $intakeRow.intake_status
        source_content_status = $intakeRow.content_status
        source_size_bytes = [int64]$intakeRow.size_bytes
        valid_paintover_source = [bool]$intakeRow.valid_paintover_source
        completion_status = $completionStatus
        source_present = $sourcePresent
        export_present = $exportPresent
        export_newer_than_source = $exportNewerThanSource
        palette_pass = $palettePass
        paintover_source = $room.paintover_source
        export_png = $room.export_png
    }
}

$completeRows = @($completionRows | Where-Object { $_.completion_status -eq "complete" })
$pendingFinalExportRows = @($completionRows | Where-Object { $_.completion_status -eq "pending_final_export" })
$approvedMissingRows = @($completionRows | Where-Object { $_.completion_status -eq "approved_source_missing" })
$blockedRows = @($completionRows | Where-Object { $_.completion_status -eq "blocked_not_started" })
foreach ($row in @($completionRows | Where-Object { $_.completion_status -in @("complete", "pending_final_export", "approved_source_missing") })) {
    foreach ($requiredReviewField in @("review_status", "reviewer_decision", "build_commit", "reviewer", "reviewed_at", "decision_note", "look_target_reviewed")) {
        if ($null -eq $row.$requiredReviewField -or [string]$row.$requiredReviewField -eq "") {
            throw "Final paintover completion row $($row.room_id) has approved status without review proof field: $requiredReviewField"
        }
    }
}
$status = if ($completeRows.Count -eq 11) { "complete" } elseif ($completeRows.Count -gt 0) { "partial" } else { "none_complete" }

$completion = [ordered]@{
    generated_from = @(
        "docs/art/act_i_paintover_source_intake.json",
        "docs/art/act_i_background_palette_audit.csv",
        "docs/art/act_i_background_manifest.json"
    )
    purpose = "Audit final Act I paintover completion without counting greybox exports as final art."
    status = $status
    complete_count = $completeRows.Count
    pending_final_export_count = $pendingFinalExportRows.Count
    approved_source_missing_count = $approvedMissingRows.Count
    blocked_not_started_count = $blockedRows.Count
    rows = $completionRows
}
$completion | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Act I Final Paintover Completion",
    "",
    'Generated by `tools/Validate-ActIFinalPaintoverCompletion.ps1` from source intake, palette audit, and the background manifest.',
    "",
    "Purpose: prevent existing greybox PNGs from being counted as final paintover exports.",
    "",
    "Status: $status",
    "Complete: $($completeRows.Count)",
    "Pending final export: $($pendingFinalExportRows.Count)",
    "Approved source missing: $($approvedMissingRows.Count)",
    "Blocked not started: $($blockedRows.Count)",
    "",
    "Completion rule:",
    "- A room is complete only when its PSD is accepted by source intake, its exported PNG is newer than that PSD, and the exported PNG passes G9/G10 palette audit.",
    "- Accepted PSD sources must carry valid_psd_source proof from asset status into final completion.",
    "- Approved, pending, or complete final rows must preserve build_commit, reviewer metadata, and look_target_reviewed from source intake.",
    "- Existing greybox PNGs do not count as final paintover exports.",
    "- Accepted Litany/Registrar duel format remains locked.",
    "- Grey Float remains hard-R: steam, silhouette, privacy, and agency only.",
    "",
    "| Room | Approved | Build | Reviewer | Reviewed At | Look Target | Intake | Source Proof | PSD Bytes | Completion | PSD Present | Export Present | Export Newer | Palette Pass |",
    "|---|---|---|---|---|---|---|---|---:|---|---|---|---|---|"
)
foreach ($row in ($completionRows | Sort-Object room_code)) {
    $buildText = if ([string]::IsNullOrWhiteSpace([string]$row.build_commit)) { "none" } else { [string]$row.build_commit }
    $reviewerText = if ([string]::IsNullOrWhiteSpace([string]$row.reviewer)) { "none" } else { [string]$row.reviewer }
    $reviewedAtText = if ([string]::IsNullOrWhiteSpace([string]$row.reviewed_at)) { "none" } else { [string]$row.reviewed_at }
    $lookTargetText = if ([string]::IsNullOrWhiteSpace([string]$row.look_target_reviewed)) { "none" } else { [string]$row.look_target_reviewed }
    $lines += "| $($row.room_code) $($row.title) | $($row.approved_by_work_order) | $buildText | $reviewerText | $reviewedAtText | $lookTargetText | $($row.intake_status) | $($row.source_content_status) | $($row.source_size_bytes) | $($row.completion_status) | $($row.source_present) | $($row.export_present) | $($row.export_newer_than_source) | $($row.palette_pass) |"
}
Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Final Paintover Completion",
    "Approved, pending, or complete final rows must preserve build_commit, reviewer metadata, and look_target_reviewed from source intake.",
    "Accepted PSD sources must carry valid_psd_source proof",
    "Existing greybox PNGs do not count as final paintover exports",
    "exported PNG is newer than that PSD",
    "Accepted Litany/Registrar duel format remains locked",
    "Grey Float remains hard-R"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I final paintover completion report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I final paintover completion report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I final paintover completion report must stay ASCII-only."
}

Write-Host "Act I final paintover completion validation passed: status=$status, complete=$($completeRows.Count), pendingFinalExport=$($pendingFinalExportRows.Count), blocked=$($blockedRows.Count)."
