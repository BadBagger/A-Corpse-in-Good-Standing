$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIPaintoverPacket.ps1"
$jsonPath = Join-Path $root "docs\art\act_i_paintover_packet.json"
$briefPath = Join-Path $root "docs\art\act_i_paintover_packet.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing paintover packet export script: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I paintover packet export failed."
}

foreach ($path in @($jsonPath, $briefPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated Act I paintover packet artifact: $path"
    }
}

$packet = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rooms = @($packet.rooms)
if ($rooms.Count -ne 11) {
    throw "Act I paintover packet expected 11 rooms, got $($rooms.Count)."
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
    if ($roomId -notin @($rooms.room_id)) {
        throw "Act I paintover packet missing room: $roomId"
    }
}

foreach ($room in $rooms) {
    foreach ($requiredProperty in @("source_blend", "blockout_export", "godot_background", "paintover_source", "review_overlay", "tone")) {
        if ([string]::IsNullOrWhiteSpace([string]$room.$requiredProperty)) {
            throw "Room $($room.room_id) missing paintover property: $requiredProperty"
        }
    }
    if ($room.camera.resolution -ne "1920x1080") {
        throw "Room $($room.room_id) must preserve 1920x1080 camera contract."
    }
    if ($room.camera.walk_band -ne "y 650-800") {
        throw "Room $($room.room_id) must preserve y 650-800 walk band."
    }
    if ($room.palette_audit.status -ne "audited" -or $room.palette_audit.pass -ne "True") {
        throw "Room $($room.room_id) palette audit must be audited/pass."
    }
    if ([string]::IsNullOrWhiteSpace([string]$room.palette_audit.in_gamut_percent)) {
        throw "Room $($room.room_id) palette audit missing in-gamut percentage."
    }
    if ([string]::IsNullOrWhiteSpace([string]$room.palette_audit.arterial_red_pixels)) {
        throw "Room $($room.room_id) palette audit missing arterial red pixel count."
    }
    if (@($room.paintover_rules).Count -lt 5) {
        throw "Room $($room.room_id) paintover rules are incomplete."
    }
}

$wetRooms = @($rooms | Where-Object { "wet_verb" -in @($_.interaction_priorities) })
if ($wetRooms.Count -lt 4) {
    throw "Act I paintover packet must preserve at least four wet-verb room targets."
}

$confessionRooms = @($rooms | Where-Object { "confession_source" -in @($_.interaction_priorities) })
if ($confessionRooms.Count -lt 4) {
    throw "Act I paintover packet must preserve confession-source staging rooms."
}

$greyFloat = @($rooms | Where-Object { $_.room_id -eq "grey_float" })[0]
if ($null -eq $greyFloat -or [string]$greyFloat.tone -notmatch "unsafe amber") {
    throw "Grey Float paintover tone must preserve unsafe amber exception."
}

$registrarRoom = @($rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
$registrarText = (($registrarRoom.critical_hotspots | ConvertTo-Json -Depth 8) + " " + ($registrarRoom.paintover_rules -join " "))
if ($registrarText -notmatch "Litany UI" -or $registrarText -notmatch "second confession-spend interface") {
    throw "Harbor Registry paintover packet must preserve Registrar duel-format lock."
}

$brief = Get-Content -LiteralPath $briefPath -Raw
foreach ($requiredText in @(
    "Act I Paintover Packet",
    "Scope: Act I only",
    "Locked palette",
    "Grey Float",
    "Hard-R line remains locked",
    "Registrar duel art must preserve the accepted Litany UI format",
    "Close-pair review"
)) {
    if ($brief -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover packet brief missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @("System.Object[]", "@{", "ï»¿")) {
    if ($brief.Contains($forbiddenText)) {
        throw "Act I paintover packet brief contains malformed generated Markdown: $forbiddenText"
    }
}
if ($brief -match "[^\u0000-\u007F]") {
    throw "Act I paintover packet brief must stay ASCII-only."
}

Write-Host "Act I paintover packet validation passed: rooms=$($rooms.Count), wetRooms=$($wetRooms.Count), confessionRooms=$($confessionRooms.Count)."
