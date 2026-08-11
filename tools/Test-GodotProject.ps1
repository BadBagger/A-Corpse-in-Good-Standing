$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$godot = "C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe"

if (-not (Test-Path -LiteralPath $godot)) {
    throw "Godot 4.6.3 .NET console executable not found: $godot"
}

$required = @(
    "project.godot",
    "addons\popochiu\plugin.cfg",
    "game\main.tscn",
    "game\gui\gui_commands.gd",
    "game\ui\prologue_hud.tscn",
    "game\ui\prologue_hud.gd",
    "game\ui\duel_panel.gd",
    "game\transition_layer\transition_layer.tscn",
    "game\characters\corvin\character_corvin.tscn",
    "game\characters\corvin\character_corvin.gd",
    "game\characters\corvin\polygon_flip_proxy.gd",
    "game\characters\corvin\runtime_sprite_sheet_loader.gd",
    "game\characters\corvin\sprites\act_i_clean\idle_side_right.png",
    "game\characters\corvin\sprites\act_i_clean\idle_side_left.png",
    "game\characters\corvin\sprites\act_i_clean\walk_side_right.png",
    "game\characters\corvin\sprites\act_i_clean\walk_side_left.png",
    "game\inventory_items\harbor_mud\inventory_item_harbor_mud.tscn",
    "game\inventory_items\harbor_mud\inventory_item_harbor_mud.gd",
    "game\inventory_items\borrowed_boots\inventory_item_borrowed_boots.tscn",
    "game\inventory_items\borrowed_boots\inventory_item_borrowed_boots.gd",
    "game\rooms\mudflats\room_mudflats.tscn",
    "game\rooms\mudflats\room_mudflats.gd",
    "game\rooms\mudflats\hotspot_bollard_of_tomas.gd",
    "game\rooms\mudflats\hotspot_missing_boots.gd",
    "game\rooms\mudflats\hotspot_salt_market_exit.gd",
    "game\popochiu_data.cfg",
    "game\autoloads\r.gd",
    "game\autoloads\c.gd",
    "game\autoloads\i.gd",
    "game\autoloads\d.gd",
    "game\autoloads\a.gd",
    "game\autoloads\narrative_state.gd",
    "game\autoloads\ink_bridge.gd",
    "game\popochiu_globals.gd",
    "ink\build\prologue.ink.json"
)

foreach ($relative in $required) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Godot scaffold file: $relative"
    }
}

$mudflatsScene = Get-Content -LiteralPath (Join-Path $root "game\rooms\mudflats\room_mudflats.tscn") -Raw -Encoding UTF8
foreach ($expected in @("BollardOfTomas", "MissingBoots", "SaltMarketExit", "PrologueHud")) {
    if ($mudflatsScene -notmatch [regex]::Escape($expected)) {
        throw "Mudflats scene missing expected scaffold node: $expected"
    }
}

$popochiuData = Get-Content -LiteralPath (Join-Path $root "game\popochiu_data.cfg") -Raw -Encoding UTF8
foreach ($expected in @("HarborMud", "BorrowedBoots", "Corvin", "Mudflats")) {
    if ($popochiuData -notmatch [regex]::Escape($expected)) {
        throw "Popochiu data missing expected registration: $expected"
    }
}

$hudScene = Get-Content -LiteralPath (Join-Path $root "game\ui\prologue_hud.tscn") -Raw -Encoding UTF8
foreach ($expected in @("WalkButton", "LookButton", "UseButton", "TalkButton", "WetButton", "Inventory")) {
    if ($hudScene -notmatch [regex]::Escape($expected)) {
        throw "Prologue HUD missing expected control: $expected"
    }
}

$corvinScene = Get-Content -LiteralPath (Join-Path $root "game\characters\corvin\character_corvin.tscn") -Raw -Encoding UTF8
foreach ($expected in @("RuntimeSprite", "runtime_sprite_sheet_loader.gd", "Sprite2D", "SaltKnuckles", "Drip")) {
    if ($corvinScene -notmatch [regex]::Escape($expected)) {
        throw "Corvin character scene missing expected runtime sprite/fallback node: $expected"
    }
}

$corvinScript = Get-Content -LiteralPath (Join-Path $root "game\characters\corvin\character_corvin.gd") -Raw -Encoding UTF8
foreach ($expected in @("play_runtime_animation", "play_idle_side_right", "play_idle_side_left", "play_walk_side_right", "play_walk_side_left", "play_idle_current_side", "active_side_direction_for_test")) {
    if ($corvinScript -notmatch [regex]::Escape($expected)) {
        throw "Corvin character script missing expected runtime animation bridge: $expected"
    }
}

$actIRoomScript = Get-Content -LiteralPath (Join-Path $root "game\rooms\act_i_greybox_room.gd") -Raw -Encoding UTF8
foreach ($expected in @("_play_corvin_runtime_animation", "transition_animation", "walk_side_right", "idle_current_side", "R.goto_room")) {
    if ($actIRoomScript -notmatch [regex]::Escape($expected)) {
        throw "Act I greybox room script missing expected Corvin transition animation hook: $expected"
    }
}

$exitHotspotScript = Get-Content -LiteralPath (Join-Path $root "game\rooms\act_i_exit_hotspot.gd") -Raw -Encoding UTF8
foreach ($expected in @("transition_animation", "walk_side_left", "walk_side_right", "room_midpoint_x")) {
    if ($exitHotspotScript -notmatch [regex]::Escape($expected)) {
        throw "Act I exit hotspot script missing expected direction-aware transition contract: $expected"
    }
}

foreach ($expected in @("N=`"*res://game/autoloads/narrative_state.gd`"", "JOURNAL_CATALOG", "apply_ink_tag", "discover_confession", "spend_confession", "lock_opponent_spoken_confession", "degrade_journal", "add_item", "to_snapshot", "apply_snapshot", "clear_runtime_state")) {
    $target = if ($expected -like "N=*") {
        Get-Content -LiteralPath (Join-Path $root "project.godot") -Raw -Encoding UTF8
    } else {
        Get-Content -LiteralPath (Join-Path $root "game\autoloads\narrative_state.gd") -Raw -Encoding UTF8
    }
    if ($target -notmatch [regex]::Escape($expected)) {
        throw "Narrative runtime bridge missing expected contract: $expected"
    }
}

$globals = Get-Content -LiteralPath (Join-Path $root "game\popochiu_globals.gd") -Raw -Encoding UTF8
foreach ($expected in @("func on_save()", "func on_load(data: Dictionary)", "narrative.to_snapshot()", "narrative.apply_snapshot")) {
    if ($globals -notmatch [regex]::Escape($expected)) {
        throw "Popochiu Globals narrative save hook missing expected contract: $expected"
    }
}

$project = Get-Content -LiteralPath (Join-Path $root "project.godot") -Raw -Encoding UTF8
if ($project -notmatch [regex]::Escape("InkBridge=`"*res://game/autoloads/ink_bridge.gd`"")) {
    throw "Project autoloads missing InkBridge."
}

$inkBridge = Get-Content -LiteralPath (Join-Path $root "game\autoloads\ink_bridge.gd") -Raw -Encoding UTF8
foreach ($expected in @("apply_knot_tags", "get_knot_tags", "get_knot_lines", "play_knot", "PROLOGUE_STORY", "_collect_tags")) {
    if ($inkBridge -notmatch [regex]::Escape($expected)) {
        throw "Ink bridge missing expected contract: $expected"
    }
}

$mudflatsRoom = Get-Content -LiteralPath (Join-Path $root "game\rooms\mudflats\room_mudflats.gd") -Raw -Encoding UTF8
foreach ($expected in @("_play_ink_knot(`"old_quay_tomas`")", "_play_ink_knot(`"old_quay_equipment`")", "_play_ink_knot(`"salt_market_arrival`")")) {
    if ($mudflatsRoom -notmatch [regex]::Escape($expected)) {
        throw "Mudflats room is not applying expected Ink knot tags: $expected"
    }
}
foreach ($expected in @("_play_corvin_runtime_animation(`"walk_side_right`")", "_play_corvin_runtime_animation(`"idle_current_side`")", "R.goto_room(`"SaltMarket`", false, true)")) {
    if ($mudflatsRoom -notmatch [regex]::Escape($expected)) {
        throw "Mudflats room is missing expected animated Salt Market transition contract: $expected"
    }
}

foreach ($expected in @("Journal", "Litany", "Dialogue")) {
    if ($hudScene -notmatch [regex]::Escape($expected)) {
        throw "Prologue HUD missing narrative control: $expected"
    }
}

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$output = & $godot --headless --path $root --quit 2>&1
$exit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
$output | Write-Host
$unexpectedErrors = @(
    $output |
        Where-Object { $_ -match "^(SCRIPT ERROR|ERROR):" } |
        Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
        Where-Object { $_ -notmatch "resources still in use at exit" }
)
if ($unexpectedErrors.Count -gt 0) {
    throw "Godot headless validation produced errors: $($unexpectedErrors -join ' | ')"
}
if ($exit -ne 0) {
    $knownShutdownOnly = @(
        $output |
            Where-Object { $_ -match "^(ERROR|WARNING):" } |
            Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
            Where-Object { $_ -notmatch "resources still in use at exit" } |
            Where-Object { $_ -notmatch "ObjectDB instances leaked at exit" } |
            Where-Object { $_ -notmatch "RIDs of type `"CanvasItem`" were leaked" }
    )
    if ($knownShutdownOnly.Count -gt 0) {
        throw "Godot headless validation failed with exit code $exit"
    }
    Write-Host "Godot returned exit code $exit from known headless shutdown cleanup noise; continuing."
}

Write-Host "Godot project validation passed."
