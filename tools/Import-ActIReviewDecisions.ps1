param(
    [Parameter(Mandatory=$true)][string]$InputCsv,
    [switch]$DryRun,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

if (-not $DryRun -and -not $Apply) {
    throw "Choose -DryRun or -Apply."
}
if ($DryRun -and $Apply) {
    throw "Choose only one mode: -DryRun or -Apply."
}

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$latestNotesPath = Join-Path $root "docs\playtest\results\act_i_human_playtest_latest.md"
$exportTrackerScript = Join-Path $PSScriptRoot "Export-ActIReviewFixTracker.ps1"
$startGateScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverStartGate.ps1"
$reportPath = Join-Path $root "docs\playtest\act_i_review_decision_import_report.md"

$resolvedInput = if ([System.IO.Path]::IsPathRooted($InputCsv)) { $InputCsv } else { Join-Path $root $InputCsv }

foreach ($path in @($trackerPath, $latestNotesPath, $exportTrackerScript, $startGateScript, $resolvedInput)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I review decision import input: $path"
    }
}

$tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
$latestNotes = Get-Content -LiteralPath $latestNotesPath -Raw
$buildMatch = [regex]::Match($latestNotes, '(?m)^Build commit:\s*(?<commit>unknown|[0-9a-f]{7,40})\s*$')
if (-not $buildMatch.Success) {
    throw "Latest Act I human review notes must include a valid 'Build commit:' stamp before importing decisions."
}
$expectedBuildCommit = [string]$buildMatch.Groups["commit"].Value
$rooms = @($tracker.rooms)
$rows = @(Import-Csv -LiteralPath $resolvedInput)
$allowed = @($tracker.allowed_room_statuses)
$requiredColumns = @(
    "room_id",
    "room_code",
    "title",
    "build_commit",
    "decision",
    "reviewer",
    "reviewed_at",
    "decision_note",
    "layout",
    "hotspot_readability",
    "walk_band",
    "palette_lighting",
    "content_compliance",
    "duel_format",
    "vo_timing_or_pacing",
    "risk_tags",
    "critical_hotspots",
    "close_pairs"
)

if ($rows.Count -ne 11) {
    throw "Act I review decision import expected 11 CSV rows, got $($rows.Count)."
}
foreach ($column in $requiredColumns) {
    if (-not ($rows[0].PSObject.Properties.Name -contains $column)) {
        throw "Review decision CSV missing required column: $column"
    }
}

$roomsById = @{}
foreach ($room in $rooms) {
    $roomsById[$room.room_id] = $room
}

function Set-ReviewProperty {
    param(
        [Parameter(Mandatory=$true)]$Target,
        [Parameter(Mandatory=$true)][string]$Name,
        $Value
    )

    if ($Target.PSObject.Properties.Name -contains $Name) {
        $Target.$Name = $Value
    } else {
        $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

$seen = @{}
$changes = @()
foreach ($row in $rows) {
    $roomId = [string]$row.room_id
    if ($roomId.Length -eq 0) {
        throw "Review decision CSV has a row without room_id."
    }
    if ($seen.ContainsKey($roomId)) {
        throw "Review decision CSV contains duplicate room_id: $roomId"
    }
    $seen[$roomId] = $true

    if (-not $roomsById.ContainsKey($roomId)) {
        throw "Review decision CSV has unknown room_id: $roomId"
    }
    $decision = [string]$row.decision
    if ($decision.Length -eq 0) {
        $decision = "pending_review"
    }
    if ($decision -notin $allowed) {
        throw "Room $roomId has invalid decision '$decision'. Allowed: $($allowed -join ', ')"
    }

    $room = $roomsById[$roomId]
    $buildCommit = [string]$row.build_commit
    $reviewer = [string]$row.reviewer
    $reviewedAt = [string]$row.reviewed_at
    $decisionNote = [string]$row.decision_note
    if ($decision -ne "pending_review") {
        if ([string]::IsNullOrWhiteSpace($buildCommit)) {
            throw "Room $roomId has non-pending decision '$decision' and must include build_commit."
        }
        if ($buildCommit -notmatch '^(unknown|[0-9a-f]{7,40})$') {
            throw "Room $roomId has invalid build_commit '$buildCommit'. Expected a git hash or unknown."
        }
        if ($buildCommit -ne $expectedBuildCommit) {
            throw "Room $roomId build_commit '$buildCommit' must match latest human-review notes build commit '$expectedBuildCommit'."
        }
        if ([string]::IsNullOrWhiteSpace($reviewer) -or [string]::IsNullOrWhiteSpace($reviewedAt) -or [string]::IsNullOrWhiteSpace($decisionNote)) {
            throw "Room $roomId has non-pending decision '$decision' and must include reviewer, reviewed_at, and decision_note."
        }
        $parsedReviewedAt = [datetime]::MinValue
        if (-not [datetime]::TryParseExact($reviewedAt, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsedReviewedAt)) {
            throw "Room $roomId has non-pending decision '$decision' and reviewed_at must use YYYY-MM-DD."
        }
    }
    $fixValues = @(
        [string]$row.layout,
        [string]$row.hotspot_readability,
        [string]$row.walk_band,
        [string]$row.palette_lighting,
        [string]$row.content_compliance,
        [string]$row.duel_format,
        [string]$row.vo_timing_or_pacing
    )
    $hasFix = @($fixValues | Where-Object { $_.Length -gt 0 }).Count -gt 0
    if ($decision -eq "revise_before_art" -and -not $hasFix) {
        throw "Room $roomId marked revise_before_art must include at least one fix note."
    }
    if ($decision -ne "pending_review" -and "hard_r_float_staging" -in @($room.risk_tags) -and [string]::IsNullOrWhiteSpace([string]$row.content_compliance)) {
        throw "Room $roomId has hard-R content risk and must include a content_compliance note before review can leave pending."
    }
    if ($decision -ne "pending_review" -and "duel_format_lock" -in @($room.risk_tags) -and [string]::IsNullOrWhiteSpace([string]$row.duel_format)) {
        throw "Room $roomId has duel-format risk and must include a duel_format note before review can leave pending."
    }

    if ($Apply) {
        Set-ReviewProperty -Target $room -Name "review_status" -Value $decision
        Set-ReviewProperty -Target $room -Name "reviewer_decision" -Value $decision
        Set-ReviewProperty -Target $room -Name "build_commit" -Value $buildCommit
        Set-ReviewProperty -Target $room -Name "reviewer" -Value $reviewer
        Set-ReviewProperty -Target $room -Name "reviewed_at" -Value $reviewedAt
        Set-ReviewProperty -Target $room -Name "decision_note" -Value $decisionNote
        Set-ReviewProperty -Target $room -Name "approved_for_paintover" -Value ($decision -eq "approved")
        $room.fix_buckets.layout = [string]$row.layout
        $room.fix_buckets.hotspot_readability = [string]$row.hotspot_readability
        $room.fix_buckets.walk_band = [string]$row.walk_band
        $room.fix_buckets.palette_lighting = [string]$row.palette_lighting
        $room.fix_buckets.content_compliance = [string]$row.content_compliance
        $room.fix_buckets.duel_format = [string]$row.duel_format
        $room.fix_buckets.vo_timing_or_pacing = [string]$row.vo_timing_or_pacing

        if ($decision -eq "approved") {
            foreach ($hotspot in @($room.critical_hotspots)) {
                if ($hotspot.review_status -eq "pending_review") { $hotspot.review_status = "readable" }
            }
            foreach ($pair in @($room.close_pair_review)) {
                if ($pair.review_status -eq "pending_review") { $pair.review_status = "readable" }
            }
        }
    }

    $changes += [ordered]@{
        room_id = $roomId
        room_code = $room.room_code
        title = $room.title
        previous_decision = $room.reviewer_decision
        incoming_decision = $decision
        build_commit = $buildCommit
        reviewer = $reviewer
        reviewed_at = $reviewedAt
        decision_note = $decisionNote
        approved_after_import = $decision -eq "approved"
        has_fix_note = $hasFix
    }
}

foreach ($room in $rooms) {
    if (-not $seen.ContainsKey($room.room_id)) {
        throw "Review decision CSV missing room_id: $($room.room_id)"
    }
}

if ($Apply) {
    $tracker | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $trackerPath -Encoding UTF8
    & powershell -NoProfile -ExecutionPolicy Bypass -File $exportTrackerScript
    if ($LASTEXITCODE -ne 0) { throw "Review fix tracker refresh failed after import." }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $startGateScript
    if ($LASTEXITCODE -ne 0) { throw "Paintover start gate validation failed after import." }
}

$approvedCount = @($changes | Where-Object { $_.incoming_decision -eq "approved" }).Count
$reviseCount = @($changes | Where-Object { $_.incoming_decision -eq "revise_before_art" }).Count
$stopCount = @($changes | Where-Object { $_.incoming_decision -eq "stop_and_redesign" }).Count
$pendingCount = @($changes | Where-Object { $_.incoming_decision -eq "pending_review" }).Count
$mode = if ($Apply) { "apply" } else { "dry_run" }

$lines = @(
    "# Act I Review Decision Import Report",
    "",
    "Mode: $mode",
    "Input CSV: ``$InputCsv``",
    "Rows: $($rows.Count)",
    "Approved: $approvedCount",
    "Revise before art: $reviseCount",
    "Stop and redesign: $stopCount",
    "Pending review: $pendingCount",
    "",
    "Rule locks:",
    "- Accepted Litany/Registrar duel format remains locked.",
    "- Grey Float remains hard-R: steam, silhouette, privacy, and agency only.",
    "- Non-pending decisions require build_commit from the generated human-review notes.",
    "- Non-pending decisions require reviewer, reviewed_at, and decision_note.",
    "- Harbor Registry non-pending decisions require an explicit duel_format note from the reviewer.",
    "",
    "| Room | Previous | Incoming | Build | Reviewer | Fix Note |",
    "|---|---|---|---|---|---|"
)
foreach ($change in $changes) {
    $lines += "| $($change.room_code) $($change.title) | $($change.previous_decision) | $($change.incoming_decision) | $($change.build_commit) | $($change.reviewer) | $($change.has_fix_note) |"
}

Set-Content -LiteralPath $reportPath -Value $lines -Encoding UTF8

Write-Host "Act I review decision import $mode passed: approved=$approvedCount, revise=$reviseCount, stop=$stopCount, pending=$pendingCount."
Write-Host "Import report -> $reportPath"
