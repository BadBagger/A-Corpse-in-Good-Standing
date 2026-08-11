$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_source_acquisition.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_acquisition.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_acquisition.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundSourceAcquisition.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source acquisition artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw
$items = @($payload.items)
$rooms = @($payload.rooms)

if ($payload.item_count -ne 130 -or $items.Count -ne 130 -or $rows.Count -ne 130) {
    throw "Act I background source acquisition expected 130 items, got payload=$($payload.item_count), json=$($items.Count), csv=$($rows.Count)."
}
if ($payload.room_count -ne 11 -or $rooms.Count -ne 11) {
    throw "Act I background source acquisition expected 11 rooms, got payload=$($payload.room_count), json=$($rooms.Count)."
}

$ids = @($rows | ForEach-Object { $_.id })
$duplicates = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicates.Count -gt 0) {
    throw "Act I background source acquisition contains duplicate ids: $($duplicates -join ', ')"
}

$readyNow = @($rows | Where-Object { $_.source_status -eq "ready_to_generate" })
$held = @($rows | Where-Object { $_.source_status -eq "held_pending_room_review" })
$received = @($rows | Where-Object { $_.source_status -eq "received_unreviewed" })
if ($readyNow.Count -ne 84) {
    throw "Expected 84 ready-to-generate Meshy/reference items, got $($readyNow.Count)."
}
if ($held.Count -ne 46) {
    throw "Expected 46 held paintover/navigation PSD items, got $($held.Count)."
}
if ($received.Count -ne 0) {
    throw "Expected no received source files in current acquisition baseline, got $($received.Count)."
}

foreach ($row in $rows) {
    foreach ($pathField in @("source_path", "source_directory", "dropzone_readme", "runtime_path", "placement_target")) {
        $value = [string]$row.$pathField
        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -match "\\") {
            throw "Act I background source acquisition path must use forward slashes in $pathField for $($row.id): $value"
        }
    }
    if ($row.kind -in @("interactive_layer", "navigation_silhouette") -and $row.blocking_rule -ne "requires_human_room_review_before_source_psd") {
        throw "PSD source item must be held until human room review: $($row.id)"
    }
    if ($row.kind -in @("meshy_source_model", "generated_reference") -and $row.blocking_rule -ne "can_acquire_before_human_review") {
        throw "Meshy/reference source item should be acquirable before human review: $($row.id)"
    }
}

foreach ($required in @(
    "Act I Background Source Acquisition Checklist",
    "Acquire Meshy helper GLBs and generated reference boards before room approval if useful.",
    "Hold interactive and navigation PSD source work until the room passes human art review.",
    "Do not batch-generate final backgrounds.",
    "Do not create placeholder binary outputs.",
    "A received source file remains unreviewed until intake, placement, and its handoff gate pass."
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act I background source acquisition report missing guardrail: $required"
    }
}

$firstRoomHeading = [string](@([regex]::Matches($brief, "(?m)^##\s+R\d+\s+-\s+.+$") | ForEach-Object { $_.Value })[0]).Trim()
if ($firstRoomHeading -ne "## R01 - Mudflats") {
    throw "Act I background source acquisition must be ordered by room code; first heading was: $firstRoomHeading"
}
if ($brief -match "[^\u0000-\u007F]") {
    throw "Act I background source acquisition report must stay ASCII-only."
}

Write-Host "Act I background source acquisition validation passed: rooms=$($payload.room_count), items=$($payload.item_count), ready=$($readyNow.Count), held=$($held.Count), received=$($received.Count)."
