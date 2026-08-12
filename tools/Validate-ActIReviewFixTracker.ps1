$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIReviewFixTracker.ps1"
$jsonPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$mdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I review fix tracker exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I review fix tracker export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated Act I review fix tracker artifact: $path"
    }
}

$tracker = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rooms = @($tracker.rooms)
if ($rooms.Count -ne 11) {
    throw "Act I review fix tracker expected 11 rooms, got $($rooms.Count)."
}

$allowedRoomStatuses = @($tracker.allowed_room_statuses)
$allowedHotspotStatuses = @($tracker.allowed_hotspot_statuses)
foreach ($expected in @("pending_review", "approved", "revise_before_art", "stop_and_redesign")) {
    if ($expected -notin $allowedRoomStatuses) {
        throw "Act I review fix tracker missing room status: $expected"
    }
}
foreach ($expected in @("pending_review", "readable", "unclear", "move_before_paint")) {
    if ($expected -notin $allowedHotspotStatuses) {
        throw "Act I review fix tracker missing hotspot status: $expected"
    }
}

$requiredRoomIds = @(
    "mudflats",
    "old_quay",
    "salt_market",
    "harbor_registry",
    "bone_chandler",
    "almshouse",
    "fish_hall",
    "church_of_the_drowned",
    "grey_float",
    "harbormaster_office",
    "sabine_office"
)
foreach ($roomId in $requiredRoomIds) {
    $room = @($rooms | Where-Object { $_.room_id -eq $roomId })[0]
    if ($null -eq $room) {
        throw "Act I review fix tracker missing room: $roomId"
    }
    if ($room.review_status -notin $allowedRoomStatuses) {
        throw "Room $roomId has invalid review_status: $($room.review_status)"
    }
    if ($room.reviewer_decision -notin $allowedRoomStatuses) {
        throw "Room $roomId has invalid reviewer_decision: $($room.reviewer_decision)"
    }
    if ([bool]$room.approved_for_paintover -and ($room.review_status -ne "approved" -or $room.reviewer_decision -ne "approved")) {
        throw "Room $roomId is approved_for_paintover without approved review statuses."
    }
    if (-not [bool]$room.approved_for_paintover -and $room.review_status -eq "approved") {
        throw "Room $roomId has approved review_status but approved_for_paintover is false."
    }
    if ($room.review_status -ne "pending_review" -or $room.reviewer_decision -ne "pending_review") {
        if ([string]::IsNullOrWhiteSpace([string]$room.build_commit)) {
            throw "Room $roomId has non-pending review state and must include build_commit."
        }
        if ([string]$room.build_commit -notmatch '^(unknown|[0-9a-f]{7,40})$') {
            throw "Room $roomId has invalid build_commit: $($room.build_commit)"
        }
        if ([string]::IsNullOrWhiteSpace([string]$room.reviewer) -or [string]::IsNullOrWhiteSpace([string]$room.reviewed_at) -or [string]::IsNullOrWhiteSpace([string]$room.decision_note)) {
            throw "Room $roomId has non-pending review state and must include reviewer, reviewed_at, and decision_note."
        }
        $parsedReviewedAt = [datetime]::MinValue
        if (-not [datetime]::TryParseExact([string]$room.reviewed_at, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsedReviewedAt)) {
            throw "Room $roomId has non-pending review state and reviewed_at must use YYYY-MM-DD."
        }
    }
    foreach ($bucketName in @("layout", "hotspot_readability", "walk_band", "palette_lighting", "content_compliance", "duel_format", "vo_timing_or_pacing")) {
        if ($null -eq $room.fix_buckets.$bucketName) {
            throw "Room $roomId missing fix bucket: $bucketName"
        }
    }
    foreach ($hotspot in @($room.critical_hotspots)) {
        if ($hotspot.review_status -notin $allowedHotspotStatuses) {
            throw "Room $roomId hotspot $($hotspot.name) has invalid review_status: $($hotspot.review_status)"
        }
    }
    foreach ($pair in @($room.close_pair_review)) {
        if ($pair.review_status -notin $allowedHotspotStatuses) {
            throw "Room $roomId close-pair $($pair.pair) has invalid review_status: $($pair.review_status)"
        }
    }
}

$greyFloat = @($rooms | Where-Object { $_.room_id -eq "grey_float" })[0]
foreach ($tag in @("hard_r_float_staging", "unsafe_amber_exception")) {
    if ($tag -notin @($greyFloat.risk_tags)) {
        throw "Grey Float review tracker missing risk tag: $tag"
    }
}

$registry = @($rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
if ("duel_format_lock" -notin @($registry.risk_tags)) {
    throw "Harbor Registry review tracker must carry duel_format_lock risk tag."
}

$wetRooms = @($rooms | Where-Object { "wet_readability" -in @($_.risk_tags) })
if ($wetRooms.Count -lt 4) {
    throw "Review tracker must preserve at least four wet readability risk rooms."
}

$confessionRooms = @($rooms | Where-Object { "confession_source_readability" -in @($_.risk_tags) })
if ($confessionRooms.Count -lt 4) {
    throw "Review tracker must preserve confession-source readability risk rooms."
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Review Fix Tracker",
    "Allowed room decisions",
    "Global unresolved state",
    "Reviewer:",
    "Reviewed at:",
    "Build commit:",
    "YYYY-MM-DD",
    "Decision note:",
    "Duel format:",
    "Content compliance:",
    "hard_r_float_staging",
    "duel_format_lock"
)) {
    if ($md -notmatch [regex]::Escape($requiredText)) {
        throw "Act I review fix tracker Markdown missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ï»¿", "`t", "	ools/")) {
    if ($md.Contains($forbiddenText)) {
        throw "Act I review fix tracker contains malformed generated Markdown: $forbiddenText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I review fix tracker must stay ASCII-only."
}

Write-Host "Act I review fix tracker validation passed: rooms=$($rooms.Count), wetRooms=$($wetRooms.Count), confessionRooms=$($confessionRooms.Count)."
