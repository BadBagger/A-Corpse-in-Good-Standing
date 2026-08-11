$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$briefPath = Join-Path $root "docs\art\act_i_background_brief.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundManifest.ps1")

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing Act I background manifest: $manifestPath"
}
if (-not (Test-Path -LiteralPath $briefPath)) {
    throw "Missing Act I background brief: $briefPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$rooms = @($manifest.rooms)

if ($manifest.native_resolution.width -ne 1920 -or $manifest.native_resolution.height -ne 1080) {
    throw "Act I background manifest native resolution must be 1920x1080."
}
if ($manifest.default_walk_band.y_min -ne 650 -or $manifest.default_walk_band.y_max -ne 800) {
    throw "Act I background manifest default walk band must be y 650-800."
}
if ($rooms.Count -ne 11) {
    throw "Act I background manifest room count mismatch: expected 11, got $($rooms.Count)"
}

$roomIds = @($rooms | ForEach-Object { $_.room_id })
$duplicateRoomIds = @($roomIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicateRoomIds.Count -gt 0) {
    throw "Act I background manifest has duplicate room ids: $($duplicateRoomIds -join ', ')"
}

$exportPaths = @($rooms | ForEach-Object { $_.export_png })
$duplicateExportPaths = @($exportPaths | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicateExportPaths.Count -gt 0) {
    throw "Act I background manifest has duplicate export paths: $($duplicateExportPaths -join ', ')"
}

foreach ($room in $rooms) {
    if ([string]::IsNullOrWhiteSpace($room.room_code) -or [string]::IsNullOrWhiteSpace($room.title)) {
        throw "Room $($room.room_id) is missing room_code or title in the background manifest."
    }
    if ($room.stage.width -ne 1920 -or $room.stage.height -ne 1080) {
        throw "Room $($room.room_id) has invalid stage size."
    }
    foreach ($pathProperty in @("source_blend", "paintover_source", "export_png", "godot_background_resource")) {
        $value = $room.$pathProperty
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Room $($room.room_id) is missing $pathProperty."
        }
        if ($value -match "\\") {
            throw "Room $($room.room_id) $pathProperty should use forward slashes for tool portability: $value"
        }
    }
    $customNavigationHotspots = @($room.hotspots | Where-Object { "custom_navigation" -in @($_.critical_roles) })
    if (@($room.exits).Count -eq 0 -and $customNavigationHotspots.Count -eq 0 -and $room.room_id -ne "sabine_office") {
        throw "Room $($room.room_id) has no exits in the background manifest."
    }
    if (@($room.hotspots).Count -eq 0) {
        throw "Room $($room.room_id) has no hotspots in the background manifest."
    }
}

$registry = @($rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
if ($null -eq $registry) {
    throw "Act I background manifest missing Harbor Registry."
}
$registrarHotspot = @($registry.hotspots | Where-Object { $_.name -eq "Registrar" })[0]
if ($null -eq $registrarHotspot -or $registrarHotspot.type -ne "duel" -or $registrarHotspot.duel_opponent -ne "registrar") {
    throw "Act I background manifest does not preserve Registrar duel metadata."
}
if ("duel" -notin @($registrarHotspot.critical_roles)) {
    throw "Registrar hotspot is not marked as a duel-critical art role."
}

$wetHotspots = @()
foreach ($room in $rooms) {
    $wetHotspots += @($room.hotspots | Where-Object { -not [string]::IsNullOrWhiteSpace($_.wet_ink_knot) })
}
if ($wetHotspots.Count -ne 4) {
    throw "Act I background manifest wet hotspot count mismatch: expected 4, got $($wetHotspots.Count)"
}
foreach ($wetHotspot in $wetHotspots) {
    if ("wet_verb" -notin @($wetHotspot.critical_roles)) {
        throw "Wet hotspot $($wetHotspot.name) is not marked as wet_verb."
    }
}

$brief = Get-Content -LiteralPath $briefPath -Raw
foreach ($requiredText in @("Act I Background Production Brief", "Registrar duel remains a UI/system beat", "R05 - Harbor Registry", "Registrar")) {
    if ($brief -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background brief missing required text: $requiredText"
    }
}
if ($brief -match "(?m)^- Exits:\s*$") {
    throw "Act I background brief contains a blank Exits line."
}

Write-Host "Act I background manifest validation passed: rooms=$($rooms.Count), wet=$($wetHotspots.Count), registrar=duel"
