$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$hudScenePath = Join-Path $root "game\ui\prologue_hud.tscn"
$hudScriptPath = Join-Path $root "game\ui\prologue_hud.gd"
$narrativePath = Join-Path $root "game\autoloads\narrative_state.gd"
$greyboxRoomPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$mudflatsRoomPath = Join-Path $root "game\rooms\mudflats\room_mudflats.gd"

foreach ($path in @($hudScenePath, $hudScriptPath, $narrativePath, $greyboxRoomPath, $mudflatsRoomPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I objective HUD input: $path"
    }
}

$hudScene = Get-Content -LiteralPath $hudScenePath -Raw
$hudScript = Get-Content -LiteralPath $hudScriptPath -Raw
$narrative = Get-Content -LiteralPath $narrativePath -Raw
$greyboxRoom = Get-Content -LiteralPath $greyboxRoomPath -Raw
$mudflatsRoom = Get-Content -LiteralPath $mudflatsRoomPath -Raw

foreach ($requiredText in @(
    "ObjectivePanel",
    "ObjectiveMargin",
    "Objective",
    "Objective: Reach the Salt Market and find out who recognizes Corvin."
)) {
    if ($hudScene -notmatch [regex]::Escape($requiredText)) {
        throw "Act I objective HUD scene missing required text: $requiredText"
    }
}

foreach ($requiredText in @(
    "@onready var _objective",
    "func set_objective_summary",
    "set_objective_summary(`"Objective: Reach the Salt Market and find out who recognizes Corvin.`")"
)) {
    if ($hudScript -notmatch [regex]::Escape($requiredText)) {
        throw "Act I objective HUD script missing required text: $requiredText"
    }
}

foreach ($requiredText in @(
    "func get_act_i_objective_summary()",
    "FL_act_i_complete",
    "are_act_i_rites_complete()",
    "FL_market_recognized",
    "Standing %d/3 proofs accepted",
    "Find any proof the port will honor"
)) {
    if ($narrative -notmatch [regex]::Escape($requiredText)) {
        throw "Act I objective narrative state missing required text: $requiredText"
    }
}

foreach ($target in @($greyboxRoom, $mudflatsRoom)) {
    foreach ($requiredText in @(
        "set_objective_summary",
        "get_act_i_objective_summary"
    )) {
        if ($target -notmatch [regex]::Escape($requiredText)) {
            throw "Act I room HUD refresh missing required objective hook: $requiredText"
        }
    }
}

foreach ($forbiddenText in @(
    "Borrowed Heartbeat",
    "Name Restored",
    "Debt Forgiven",
    "Registrar counter",
    "category trump",
    "cf_",
    "GREED",
    "LUST",
    "PRIDE",
    "CRUELTY",
    "COWARDICE",
    "BETRAYAL"
)) {
    if ($hudScene.Contains($forbiddenText) -or $hudScript.Contains($forbiddenText) -or $narrative.Contains($forbiddenText)) {
        throw "Act I objective HUD exposes route or duel spoiler text: $forbiddenText"
    }
}

Write-Host "Act I objective HUD validation passed: non-spoiler standing progress is wired into the runtime HUD."
