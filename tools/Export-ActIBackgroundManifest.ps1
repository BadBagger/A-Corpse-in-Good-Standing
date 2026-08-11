$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mapPath = Join-Path $root "docs\art\act_i_hotspot_map.csv"
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$briefPath = Join-Path $root "docs\art\act_i_background_brief.md"

if (-not (Test-Path -LiteralPath $mapPath)) {
    throw "Missing Act I hotspot map export: $mapPath"
}

$rows = @(Import-Csv -LiteralPath $mapPath)
if ($rows.Count -eq 0) {
    throw "Act I hotspot map is empty: $mapPath"
}

$stageWidth = 1920
$stageHeight = 1080
$walkBand = @{
    y_min = 650
    y_max = 800
}

function Split-Field {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return @($Value -split "\|" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-CriticalRole {
    param($Row)

    $roles = @()
    if ($Row.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($Row.duel_opponent)) {
        $roles += "duel"
    }
    if (-not [string]::IsNullOrWhiteSpace($Row.wet_ink_knot)) {
        $roles += "wet_verb"
    }
    if (-not [string]::IsNullOrWhiteSpace($Row.alternate_ink_knot)) {
        $roles += "conditional_followup"
    }
    if (-not [string]::IsNullOrWhiteSpace($Row.blocked_ink_knot)) {
        $roles += "blocked_feedback"
    }
    if (-not [string]::IsNullOrWhiteSpace($Row.confessions_discover)) {
        $roles += "confession_source"
    }
    if (-not [string]::IsNullOrWhiteSpace($Row.items_add)) {
        $roles += "item_reward"
    }
    if (-not [string]::IsNullOrWhiteSpace($Row.requires_items) -or -not [string]::IsNullOrWhiteSpace($Row.requires_flags)) {
        $roles += "gated"
    }
    if ($Row.name -cmatch "Exit$" -or $Row.name -cmatch "^To[A-Z]") {
        $roles += "custom_navigation"
    }

    return @($roles)
}

$rooms = @()
foreach ($roomGroup in ($rows | Group-Object room_id | Sort-Object @{ Expression = { [int](($_.Group[0].room_code) -replace "\D", "") } })) {
    $roomRows = @($roomGroup.Group | Sort-Object @{ Expression = { [int]$_.y } }, @{ Expression = { [int]$_.x } }, name)
    $first = $roomRows[0]
    $roomId = $first.room_id

    $exits = @()
    foreach ($exitRow in @($roomRows | Where-Object { $_.type -eq "exit" })) {
        $exits += [ordered]@{
            name = $exitRow.name
            label = $exitRow.label
            x = [int]$exitRow.x
            y = [int]$exitRow.y
            target_room = $exitRow.target_room
            requires_flags = @(Split-Field $exitRow.requires_flags)
            requires_items = @(Split-Field $exitRow.requires_items)
        }
    }

    $hotspots = @()
    foreach ($hotspotRow in @($roomRows | Where-Object { $_.type -ne "exit" })) {
        $hotspots += [ordered]@{
            name = $hotspotRow.name
            label = $hotspotRow.label
            type = $hotspotRow.type
            x = [int]$hotspotRow.x
            y = [int]$hotspotRow.y
            critical_roles = @(Get-CriticalRole $hotspotRow)
            requires_flags = @(Split-Field $hotspotRow.requires_flags)
            requires_items = @(Split-Field $hotspotRow.requires_items)
            rewards_items = @(Split-Field $hotspotRow.items_add)
            sets_flags = @(Split-Field $hotspotRow.flags_set)
            confessions_discover = @(Split-Field $hotspotRow.confessions_discover)
            ink_knot = $hotspotRow.ink_knot
            wet_ink_knot = $hotspotRow.wet_ink_knot
            blocked_ink_knot = $hotspotRow.blocked_ink_knot
            alternate_ink_knot = $hotspotRow.alternate_ink_knot
            duel_opponent = $hotspotRow.duel_opponent
        }
    }

    $backgroundFileName = "${roomId}_bg.png"
    if ($roomId -eq "old_quay") {
        $backgroundFileName = "old_quay_blockout_bg.png"
    }

    $rooms += [ordered]@{
        room_id = $roomId
        room_code = $first.room_code
        title = $first.room_title
        stage = @{
            width = $stageWidth
            height = $stageHeight
        }
        walk_band = $walkBand
        source_blend = "art/src/backgrounds/act_i/$roomId.blend"
        paintover_source = "art/src/backgrounds/act_i/$roomId.psd"
        export_png = "art/export/backgrounds/act_i/$backgroundFileName"
        godot_background_resource = "game/rooms/$roomId/background/$backgroundFileName"
        review_overlay = "docs/art/act_i_hotspot_overlay.svg#room-$roomId"
        exits = $exits
        hotspots = $hotspots
    }
}

$manifest = [ordered]@{
    generated_from = "docs/art/act_i_hotspot_map.csv"
    native_resolution = @{
        width = $stageWidth
        height = $stageHeight
    }
    default_walk_band = $walkBand
    rooms = $rooms
}

$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$briefLines = @(
    "# Act I Background Production Brief",
    "",
    'Generated from `docs/art/act_i_hotspot_map.csv` by `tools/Export-ActIBackgroundManifest.ps1`.',
    "",
    "Native background size: ${stageWidth}x${stageHeight}.",
    "Default walk band: y $($walkBand.y_min)-$($walkBand.y_max).",
    "",
    "Use this as the handoff list for Blender greyboxes, paintovers, and final Godot background imports. The Registrar duel remains a UI/system beat; art can frame the Registry for it, but must not change the accepted duel format.",
    ""
)

foreach ($room in $rooms) {
    $briefLines += "## $($room.room_code) - $($room.title)"
    $briefLines += ""
    $briefLines += "- Source blend: ``$($room.source_blend)``"
    $briefLines += "- Paintover source: ``$($room.paintover_source)``"
    $briefLines += "- Export PNG: ``$($room.export_png)``"
    $briefLines += "- Godot import target: ``$($room.godot_background_resource)``"
    $exitSummary = @($room.exits | ForEach-Object { "$($_.label) -> $($_.target_room)" }) -join '; '
    if ([string]::IsNullOrWhiteSpace($exitSummary)) {
        $scriptedNavigation = @($room.hotspots | Where-Object { "custom_navigation" -in @($_.critical_roles) } | ForEach-Object { $_.label }) -join '; '
        if (-not [string]::IsNullOrWhiteSpace($scriptedNavigation)) {
            $exitSummary = "scripted hotspot: $scriptedNavigation"
        } else {
            $exitSummary = "none"
        }
    }
    $briefLines += "- Exits: $exitSummary"
    $briefLines += ""
    $briefLines += "| Hotspot | Type | Position | Critical Roles | Ink / Duel |"
    $briefLines += "|---|---|---:|---|---|"
    foreach ($hotspot in $room.hotspots) {
        $roles = @($hotspot.critical_roles) -join ", "
        if ([string]::IsNullOrWhiteSpace($roles)) {
            $roles = "scene_texture"
        }
        $inkBits = @($hotspot.ink_knot, $hotspot.wet_ink_knot, $hotspot.blocked_ink_knot, $hotspot.alternate_ink_knot, $hotspot.duel_opponent) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $inkSummary = $inkBits -join ", "
        if ([string]::IsNullOrWhiteSpace($inkSummary)) {
            $inkSummary = "-"
        }
        $briefLines += "| $($hotspot.label) | $($hotspot.type) | $($hotspot.x), $($hotspot.y) | $roles | $inkSummary |"
    }
    $briefLines += ""
}

Set-Content -LiteralPath $briefPath -Value $briefLines -Encoding UTF8

Write-Host "Exported Act I background manifest -> $manifestPath"
Write-Host "Exported Act I background brief -> $briefPath"
