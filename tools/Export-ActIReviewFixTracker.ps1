$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$paintoverPacketPath = Join-Path $root "docs\art\act_i_paintover_packet.json"
$jsonPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$mdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"

if (-not (Test-Path -LiteralPath $paintoverPacketPath)) {
    throw "Missing Act I paintover packet JSON: $paintoverPacketPath"
}

$packet = Get-Content -LiteralPath $paintoverPacketPath -Raw | ConvertFrom-Json
$rooms = @($packet.rooms)
if ($rooms.Count -ne 11) {
    throw "Act I review fix tracker expected 11 rooms, got $($rooms.Count)."
}

$existingByRoom = @{}
if (Test-Path -LiteralPath $jsonPath) {
    $existingTracker = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    foreach ($existingRoom in @($existingTracker.rooms)) {
        $existingByRoom[$existingRoom.room_id] = $existingRoom
    }
}

function Get-RiskTags {
    param($Room)

    $tags = @()
    $priorities = @($Room.interaction_priorities)
    if ("wet_verb" -in $priorities) { $tags += "wet_readability" }
    if ("confession_source" -in $priorities) { $tags += "confession_source_readability" }
    if ("duel" -in $priorities) { $tags += "duel_format_lock" }
    if (@($Room.close_pair_review).Count -gt 0) { $tags += "close_pair_spacing" }
    if ($Room.room_id -eq "grey_float") { $tags += "hard_r_float_staging"; $tags += "unsafe_amber_exception" }
    if ($tags.Count -eq 0) { $tags += "general_layout_readability" }
    return @($tags)
}

function Get-ExistingText {
    param($Value)
    if ($null -eq $Value) { return "" }
    return [string]$Value
}

function Get-FixBuckets {
    param($ExistingRoom)

    $bucketNames = @("layout", "hotspot_readability", "walk_band", "palette_lighting", "content_compliance", "duel_format", "vo_timing_or_pacing")
    $buckets = [ordered]@{}
    foreach ($bucketName in $bucketNames) {
        $value = ""
        if ($null -ne $ExistingRoom -and $null -ne $ExistingRoom.fix_buckets -and $null -ne $ExistingRoom.fix_buckets.$bucketName) {
            $value = [string]$ExistingRoom.fix_buckets.$bucketName
        }
        $buckets[$bucketName] = $value
    }
    return $buckets
}

$trackerRooms = @()
foreach ($room in $rooms) {
    $existingRoom = $existingByRoom[$room.room_id]
    $criticalHotspots = @()
    foreach ($hotspot in @($room.critical_hotspots)) {
        $existingHotspot = $null
        if ($null -ne $existingRoom) {
            $existingHotspot = @($existingRoom.critical_hotspots | Where-Object { $_.name -eq $hotspot.name })[0]
        }
        $criticalHotspots += [ordered]@{
            name = $hotspot.name
            label = $hotspot.label
            position = $hotspot.position
            roles = @($hotspot.roles)
            review_status = if ($null -ne $existingHotspot -and $null -ne $existingHotspot.review_status) { [string]$existingHotspot.review_status } else { "pending_review" }
            fix_note = if ($null -ne $existingHotspot) { Get-ExistingText $existingHotspot.fix_note } else { "" }
        }
    }

    $closePairs = @()
    foreach ($pair in @($room.close_pair_review)) {
        $existingPair = $null
        if ($null -ne $existingRoom) {
            $existingPair = @($existingRoom.close_pair_review | Where-Object { $_.pair -eq $pair })[0]
        }
        $closePairs += [ordered]@{
            pair = $pair
            review_status = if ($null -ne $existingPair -and $null -ne $existingPair.review_status) { [string]$existingPair.review_status } else { "pending_review" }
            fix_note = if ($null -ne $existingPair) { Get-ExistingText $existingPair.fix_note } else { "" }
        }
    }

    $reviewStatus = if ($null -ne $existingRoom -and $null -ne $existingRoom.review_status) { [string]$existingRoom.review_status } else { "pending_review" }
    $reviewerDecision = if ($null -ne $existingRoom -and $null -ne $existingRoom.reviewer_decision) { [string]$existingRoom.reviewer_decision } else { $reviewStatus }
    $approvedForPaintover = if ($null -ne $existingRoom -and $null -ne $existingRoom.approved_for_paintover) { [bool]$existingRoom.approved_for_paintover } else { $false }
    $reviewer = if ($null -ne $existingRoom -and $null -ne $existingRoom.reviewer) { [string]$existingRoom.reviewer } else { "" }
    $reviewedAt = if ($null -ne $existingRoom -and $null -ne $existingRoom.reviewed_at) { [string]$existingRoom.reviewed_at } else { "" }
    $decisionNote = if ($null -ne $existingRoom -and $null -ne $existingRoom.decision_note) { [string]$existingRoom.decision_note } else { "" }
    $buildCommit = if ($null -ne $existingRoom -and $null -ne $existingRoom.build_commit) { [string]$existingRoom.build_commit } else { "" }

    $trackerRooms += [ordered]@{
        room_id = $room.room_id
        room_code = $room.room_code
        title = $room.title
        review_status = $reviewStatus
        paintover_status = $room.paintover_status
        paintover_source = $room.paintover_source
        blockout_export = $room.blockout_export
        overlay = $room.review_overlay
        risk_tags = @(Get-RiskTags $room)
        fix_buckets = Get-FixBuckets $existingRoom
        critical_hotspots = $criticalHotspots
        close_pair_review = $closePairs
        reviewer_decision = $reviewerDecision
        reviewer = $reviewer
        reviewed_at = $reviewedAt
        build_commit = $buildCommit
        decision_note = $decisionNote
        approved_for_paintover = $approvedForPaintover
    }
}

$tracker = [ordered]@{
    generated_from = "docs/art/act_i_paintover_packet.json"
    purpose = "Convert Act I human greybox and art-readability review findings into room-level fixes before final paintover."
    allowed_room_statuses = @("pending_review", "approved", "revise_before_art", "stop_and_redesign")
    allowed_hotspot_statuses = @("pending_review", "readable", "unclear", "move_before_paint")
    rooms = $trackerRooms
}

$tracker | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Act I Review Fix Tracker",
    "",
    'Generated by `tools/Export-ActIReviewFixTracker.ps1` from `docs/art/act_i_paintover_packet.json`.',
    "",
    "Purpose: turn one human Step 5 review into exact room/layout fixes before final paintover.",
    "",
    "Allowed room decisions: pending_review, approved, revise_before_art, stop_and_redesign.",
    "Allowed hotspot decisions: pending_review, readable, unclear, move_before_paint.",
    "Non-pending room decisions require build_commit, reviewer, reviewed_at as YYYY-MM-DD, and decision_note.",
    "",
    "Global unresolved state: pending/revise/stop rooms block final paintover until a human Act I art/readability run resolves them.",
    ""
)

foreach ($room in $trackerRooms) {
    $lines += "## $($room.room_code) - $($room.title)"
    $lines += ""
    $lines += "- Review status: $($room.review_status)"
    $lines += "- Reviewer decision: $($room.reviewer_decision)"
    $lines += "- Reviewer: $($room.reviewer)"
    $lines += "- Reviewed at: $($room.reviewed_at)"
    $buildText = if ([string]::IsNullOrWhiteSpace([string]$room.build_commit)) { "none" } else { [string]$room.build_commit }
    $lines += "- Build commit: $buildText"
    $lines += "- Decision note: $($room.decision_note)"
    $lines += "- Approved for paintover: $($room.approved_for_paintover)"
    $lines += "- Paintover source: ``$($room.paintover_source)`` ($($room.paintover_status))"
    $lines += "- Blockout: ``$($room.blockout_export)``"
    $lines += "- Overlay: ``$($room.overlay)``"
    $lines += "- Risk tags: $((@($room.risk_tags) -join ', '))"
    $lines += ""
    $lines += "Fix buckets:"
    $lines += "- Layout: $($room.fix_buckets.layout)"
    $lines += "- Hotspot readability: $($room.fix_buckets.hotspot_readability)"
    $lines += "- Walk band: $($room.fix_buckets.walk_band)"
    $lines += "- Palette/lighting: $($room.fix_buckets.palette_lighting)"
    $lines += "- Content compliance: $($room.fix_buckets.content_compliance)"
    $lines += "- Duel format: $($room.fix_buckets.duel_format)"
    $lines += "- VO timing or pacing: $($room.fix_buckets.vo_timing_or_pacing)"
    $lines += ""
    $lines += "Critical hotspots:"
    if (@($room.critical_hotspots).Count -eq 0) {
        $lines += "- None."
    } else {
        foreach ($hotspot in @($room.critical_hotspots)) {
            $note = if ($hotspot.fix_note.Length -gt 0) { " - $($hotspot.fix_note)" } else { "" }
            $lines += "- $($hotspot.label) at $($hotspot.position): $($hotspot.review_status)$note"
        }
    }
    $lines += ""
    $lines += "Close-pair review:"
    if (@($room.close_pair_review).Count -eq 0) {
        $lines += "- None."
    } else {
        foreach ($pair in @($room.close_pair_review)) {
            $note = if ($pair.fix_note.Length -gt 0) { " - $($pair.fix_note)" } else { "" }
            $lines += "- $($pair.pair): $($pair.review_status)$note"
        }
    }
    $lines += ""
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Act I review fix tracker JSON -> $jsonPath"
Write-Host "Exported Act I review fix tracker brief -> $mdPath"
