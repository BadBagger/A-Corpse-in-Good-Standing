$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    "game\ui\prologue_hud.gd",
    "game\ui\prologue_hud.tscn",
    "game\main.gd",
    "game\rooms\mudflats\room_mudflats.gd",
    "game\rooms\act_i_greybox_room.gd"
)

foreach ($relativePath in $requiredFiles) {
    $absolutePath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Missing Act I playable presentation file: $relativePath"
    }
}

$hudScript = Get-Content -LiteralPath (Join-Path $root "game\ui\prologue_hud.gd") -Raw
$hudScene = Get-Content -LiteralPath (Join-Path $root "game\ui\prologue_hud.tscn") -Raw
$mainScript = Get-Content -LiteralPath (Join-Path $root "game\main.gd") -Raw
$mudflatsScript = Get-Content -LiteralPath (Join-Path $root "game\rooms\mudflats\room_mudflats.gd") -Raw
$actIRoomScript = Get-Content -LiteralPath (Join-Path $root "game\rooms\act_i_greybox_room.gd") -Raw

foreach ($source in @($hudScript, $hudScene)) {
    if ($source -match "greybox|hotspot") {
        throw "HUD must not expose greybox/hotspot implementation language to players."
    }
    if ($source -notmatch [regex]::Escape("Choose a verb, then test Mordida's patience.")) {
        throw "HUD missing in-world default verb prompt."
    }
}

if ($mainScript -match "greybox") {
    throw "Main runtime log must not describe the playable scene as greybox."
}
if ($mainScript -notmatch [regex]::Escape("A Corpse in Good Standing: Act I loaded")) {
    throw "Main runtime log missing Act I loaded text."
}

foreach ($requiredText in @(
    "show_debug_layout",
    "_apply_real_art_presentation",
    "_set_debug_layout_visible",
    "GreyboxLabels",
    "Props/CorvinPlaceholder"
)) {
    if (-not $mudflatsScript.Contains($requiredText)) {
        throw "Mudflats runtime presentation script missing required debug-hide text: $requiredText"
    }
}

foreach ($requiredText in @(
    "show_debug_layout",
    "_set_debug_layout_visible",
    "_set_child_labels_visible"
)) {
    if (-not $actIRoomScript.Contains($requiredText)) {
        throw "Shared Act I room presentation script missing required debug-hide text: $requiredText"
    }
}

if ($mudflatsScript -match "PROLOGUE: Wet - mudflats greybox ready") {
    throw "Mudflats runtime must not print the old greybox-ready log line."
}

Write-Host "Act I playable presentation validation passed: HUD copy and debug layout hiding are runtime-safe."
