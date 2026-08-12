param(
    [Parameter(Mandatory=$true)][string]$RoomId,
    [Parameter(Mandatory=$true)][ValidateSet("approved", "revise_before_art", "stop_and_redesign", "pending_review")][string]$Decision,
    [string]$Layout = "",
    [string]$HotspotReadability = "",
    [string]$WalkBand = "",
    [string]$PaletteLighting = "",
    [string]$ContentCompliance = "",
    [string]$DuelFormat = "",
    [string]$VoTimingOrPacing = "",
    [string]$BuildCommit = "",
    [string]$Reviewer = "",
    [string]$ReviewedAt = "",
    [string]$DecisionNote = "",
    [switch]$AllowUnresolvedHotspots
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$exportScript = Join-Path $PSScriptRoot "Export-ActIReviewFixTracker.ps1"

if (-not (Test-Path -LiteralPath $trackerPath)) {
    throw "Missing Act I review fix tracker JSON: $trackerPath"
}
if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I review fix tracker exporter: $exportScript"
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

$tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
$rooms = @($tracker.rooms)
$room = @($rooms | Where-Object { $_.room_id -eq $RoomId })[0]
if ($null -eq $room) {
    $knownRooms = (@($rooms | ForEach-Object { $_.room_id }) -join ", ")
    throw "Unknown Act I room '$RoomId'. Known rooms: $knownRooms"
}

$allowedRoomStatuses = @($tracker.allowed_room_statuses)
if ($Decision -notin $allowedRoomStatuses) {
    throw "Decision '$Decision' is not allowed. Allowed: $($allowedRoomStatuses -join ', ')"
}

Set-ReviewProperty -Target $room -Name "review_status" -Value $Decision
Set-ReviewProperty -Target $room -Name "reviewer_decision" -Value $Decision
Set-ReviewProperty -Target $room -Name "build_commit" -Value $BuildCommit
Set-ReviewProperty -Target $room -Name "reviewer" -Value $Reviewer
Set-ReviewProperty -Target $room -Name "reviewed_at" -Value $ReviewedAt
Set-ReviewProperty -Target $room -Name "decision_note" -Value $DecisionNote
Set-ReviewProperty -Target $room -Name "approved_for_paintover" -Value ($Decision -eq "approved")

if ($Decision -ne "pending_review") {
    if ([string]::IsNullOrWhiteSpace($BuildCommit)) {
        throw "Room '$RoomId' has non-pending decision '$Decision' and must include -BuildCommit."
    }
    if ($BuildCommit -notmatch '^(unknown|[0-9a-f]{7,40})$') {
        throw "Room '$RoomId' has invalid -BuildCommit '$BuildCommit'. Expected a git hash or unknown."
    }
    if ([string]::IsNullOrWhiteSpace($Reviewer) -or [string]::IsNullOrWhiteSpace($ReviewedAt) -or [string]::IsNullOrWhiteSpace($DecisionNote)) {
        throw "Room '$RoomId' has non-pending decision '$Decision' and must include -Reviewer, -ReviewedAt, and -DecisionNote."
    }
    $parsedReviewedAt = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($ReviewedAt, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsedReviewedAt)) {
        throw "Room '$RoomId' has non-pending decision '$Decision' and -ReviewedAt must use YYYY-MM-DD."
    }
}

if ($Layout.Length -gt 0) { $room.fix_buckets.layout = $Layout }
if ($HotspotReadability.Length -gt 0) { $room.fix_buckets.hotspot_readability = $HotspotReadability }
if ($WalkBand.Length -gt 0) { $room.fix_buckets.walk_band = $WalkBand }
if ($PaletteLighting.Length -gt 0) { $room.fix_buckets.palette_lighting = $PaletteLighting }
if ($ContentCompliance.Length -gt 0) { $room.fix_buckets.content_compliance = $ContentCompliance }
if ($DuelFormat.Length -gt 0) { $room.fix_buckets.duel_format = $DuelFormat }
if ($VoTimingOrPacing.Length -gt 0) { $room.fix_buckets.vo_timing_or_pacing = $VoTimingOrPacing }

if ($Decision -ne "pending_review" -and "hard_r_float_staging" -in @($room.risk_tags) -and [string]::IsNullOrWhiteSpace([string]$room.fix_buckets.content_compliance)) {
    throw "Room '$RoomId' has hard-R content risk and must include -ContentCompliance before review can leave pending."
}

if ($Decision -eq "approved") {
    if ("duel_format_lock" -in @($room.risk_tags) -and $room.fix_buckets.duel_format.Length -eq 0) {
        $room.fix_buckets.duel_format = "Accepted Litany/Registrar duel format preserved; no second confession-spend UI added."
    }

    foreach ($hotspot in @($room.critical_hotspots)) {
        if ($hotspot.review_status -eq "pending_review") {
            $hotspot.review_status = "readable"
        }
    }
    foreach ($pair in @($room.close_pair_review)) {
        if ($pair.review_status -eq "pending_review") {
            $pair.review_status = "readable"
        }
    }

    if (-not $AllowUnresolvedHotspots) {
        $unresolvedHotspots = @($room.critical_hotspots | Where-Object { $_.review_status -ne "readable" })
        $unresolvedPairs = @($room.close_pair_review | Where-Object { $_.review_status -ne "readable" })
        if ($unresolvedHotspots.Count -gt 0 -or $unresolvedPairs.Count -gt 0) {
            throw "Room '$RoomId' cannot be approved with unresolved hotspot or close-pair statuses. Use revise_before_art or pass -AllowUnresolvedHotspots after explicit review."
        }
    }
}

if ($Decision -eq "revise_before_art") {
    $hasFix = @(
        $room.fix_buckets.layout,
        $room.fix_buckets.hotspot_readability,
        $room.fix_buckets.walk_band,
        $room.fix_buckets.palette_lighting,
        $room.fix_buckets.content_compliance,
        $room.fix_buckets.duel_format,
        $room.fix_buckets.vo_timing_or_pacing
    ) | Where-Object { $_.Length -gt 0 }
    if (@($hasFix).Count -eq 0) {
        throw "Room '$RoomId' marked revise_before_art must include at least one fix note."
    }
}

$tracker | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $trackerPath -Encoding UTF8

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Review fix tracker Markdown refresh failed."
}

Write-Host "Act I review decision recorded: room=$RoomId, decision=$Decision, approved_for_paintover=$($room.approved_for_paintover)."
