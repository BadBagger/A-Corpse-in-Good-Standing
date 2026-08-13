$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$hotspotMapPath = Join-Path $root "docs\art\act_i_hotspot_map.csv"
$runtimeReportPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$runtimeReportMdPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.md"
$builderPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_godot_runtime_frame_contact_sheet.png"

foreach ($path in @($hotspotMapPath, $runtimeReportPath, $runtimeReportMdPath, $builderPath, $contactSheetPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I hotspot glint review artifact: $path"
    }
}

$hotspots = @(Import-Csv -LiteralPath $hotspotMapPath)
if ($hotspots.Count -lt 60) {
    throw "Act I hotspot map is unexpectedly small: $($hotspots.Count) rows."
}

$report = Get-Content -LiteralPath $runtimeReportPath -Raw | ConvertFrom-Json
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I hotspot glint review expected 9 runtime proof rooms, got $($rooms.Count)."
}
if ([string]$report.runtime_evidence -notmatch "hotspot glints") {
    throw "Runtime report must state that in-world hotspot glints are included."
}

$requiredRooms = @("mudflats", "old_quay", "salt_market", "harbor_registry", "bone_chandler", "almshouse", "church_of_the_drowned", "grey_float", "sabine_office")
foreach ($roomId in $requiredRooms) {
    $room = $rooms | Where-Object { [string]$_.room_id -eq $roomId } | Select-Object -First 1
    if ($null -eq $room) {
        throw "Missing runtime glint room: $roomId"
    }
    $glints = @($room.hotspot_glints)
    $availableNonExit = @($hotspots | Where-Object { [string]$_.room_id -eq $roomId -and [string]$_.type -ne "exit" })
    if ([int]$room.hotspot_glint_count -ne $glints.Count) {
        throw "Hotspot glint count mismatch for room $roomId."
    }
    $minimumGlints = [Math]::Min(2, $availableNonExit.Count)
    if ($glints.Count -lt $minimumGlints -or $glints.Count -gt 3) {
        throw "Room $roomId must have $minimumGlints-3 in-world hotspot glints, got $($glints.Count)."
    }
    foreach ($glint in $glints) {
        $name = [string]$glint.name
        $matchingHotspot = $hotspots | Where-Object { [string]$_.room_id -eq $roomId -and [string]$_.name -eq $name } | Select-Object -First 1
        if ($null -eq $matchingHotspot) {
            throw "Glint $name in room $roomId is not sourced from the hotspot map."
        }
        if ([string]$matchingHotspot.type -eq "exit") {
            throw "Glint $name in room $roomId must not be an exit/debug navigation marker."
        }
        if ([int]$glint.x -ne [int]$matchingHotspot.x -or [int]$glint.y -ne [int]$matchingHotspot.y) {
            throw "Glint $name in room $roomId does not match hotspot-map coordinates."
        }
    }
}

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @(
    "HOTSPOT_GLINT_PRIORITY",
    "HOTSPOT_GLINT_LIMIT = 3",
    "load_hotspot_glints",
    "draw_hotspot_glints",
    "HOTSPOT_MAP",
    "row.get(`"type`") == `"exit`"",
    "in-world hotspot glints"
)) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I Godot runtime frame builder missing hotspot glint text: $requiredText"
    }
}
if ($builder -match "debug|DEBUG|hotspot label|draw\.rectangle") {
    throw "Hotspot glint builder must not introduce debug boxes or labels into runtime proof frames."
}

$md = Get-Content -LiteralPath $runtimeReportMdPath -Raw
foreach ($requiredText in @("in-world hotspot glints", "| Room | Captured frame | Props | Glints | Living cues | Portrait | Embedded HUD dialogue |")) {
    if (-not $md.Contains($requiredText)) {
        throw "Runtime frame report missing hotspot glint text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Runtime frame report must stay ASCII-only."
}

Write-Host "Act I hotspot glint review validation passed: rooms=$($rooms.Count), sourcedFromHotspotMap=true."
