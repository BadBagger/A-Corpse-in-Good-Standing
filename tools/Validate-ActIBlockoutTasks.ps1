$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_blockout_tasks.json"
$briefPath = Join-Path $root "docs\art\act_i_blockout_tasks.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBlockoutTasks.ps1")

if (-not (Test-Path -LiteralPath $jsonPath)) {
    throw "Missing Act I blockout task JSON: $jsonPath"
}
if (-not (Test-Path -LiteralPath $briefPath)) {
    throw "Missing Act I blockout task brief: $briefPath"
}

$tasks = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rooms = @($tasks.rooms)
if ($rooms.Count -ne 11) {
    throw "Act I blockout task room count mismatch: expected 11, got $($rooms.Count)"
}
if ($tasks.close_pair_threshold_px -ne 90) {
    throw "Act I blockout task close-pair threshold must be 90px."
}

foreach ($room in $rooms) {
    if ([string]::IsNullOrWhiteSpace($room.room_code) -or [string]::IsNullOrWhiteSpace($room.title)) {
        throw "Act I blockout task room is missing code/title: $($room.room_id)"
    }
    if ($room.camera.resolution -ne "1920x1080") {
        throw "Act I blockout task room $($room.room_id) has invalid camera resolution."
    }
    if ($room.camera.walk_band -ne "y 650-800") {
        throw "Act I blockout task room $($room.room_id) has invalid walk band."
    }
    if (@($room.navigation_tasks).Count -eq 0) {
        throw "Act I blockout task room $($room.room_id) has no navigation task summary."
    }
}

$registry = @($rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
if ($null -eq $registry) {
    throw "Act I blockout tasks missing Harbor Registry."
}
$registrar = @($registry.critical_hotspots | Where-Object { $_.name -eq "Registrar" })[0]
if ($null -eq $registrar -or "duel" -notin @($registrar.roles)) {
    throw "Act I blockout tasks do not preserve Registrar duel role."
}
$registrarText = (@($registrar.tasks) -join " ")
if ($registrarText -notmatch "do not add a second confession-spend interface") {
    throw "Registrar blockout task does not preserve the duel-format lock."
}

$wetCount = 0
$closePairCount = 0
foreach ($room in $rooms) {
    foreach ($hotspot in @($room.critical_hotspots)) {
        if ("wet_verb" -in @($hotspot.roles)) {
            $wetCount += 1
        }
    }
    $closePairCount += @($room.close_pair_review).Count
}
if ($wetCount -ne 4) {
    throw "Act I blockout task wet hotspot count mismatch: expected 4, got $wetCount"
}
if ($closePairCount -ne 4) {
    throw "Act I blockout task close-pair count mismatch: expected 4, got $closePairCount"
}

$brief = Get-Content -LiteralPath $briefPath -Raw
foreach ($requiredText in @("Act I Blender Blockout Tasks", "Duel lock", "R01 - Mudflats", "R05 - Harbor Registry", "do not add a second confession-spend interface")) {
    if ($brief -notmatch [regex]::Escape($requiredText)) {
        throw "Act I blockout task brief missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($brief.Contains($forbiddenText)) {
        throw "Act I blockout task brief contains malformed generated Markdown: $forbiddenText"
    }
}

Write-Host "Act I blockout task validation passed: rooms=$($rooms.Count), wet=$wetCount, closePairs=$closePairCount"
