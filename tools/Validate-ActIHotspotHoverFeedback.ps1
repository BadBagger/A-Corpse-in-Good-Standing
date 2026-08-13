$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$interactionHotspotPath = Join-Path $root "game\rooms\act_i_interaction_hotspot.gd"
$exitHotspotPath = Join-Path $root "game\rooms\act_i_exit_hotspot.gd"
$greyboxRoomPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$mudflatsRoomPath = Join-Path $root "game\rooms\mudflats\room_mudflats.gd"

foreach ($path in @($interactionHotspotPath, $exitHotspotPath, $greyboxRoomPath, $mudflatsRoomPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I hotspot hover feedback input: $path"
    }
}

$interactionHotspot = Get-Content -LiteralPath $interactionHotspotPath -Raw -Encoding UTF8
$exitHotspot = Get-Content -LiteralPath $exitHotspotPath -Raw -Encoding UTF8
$greyboxRoom = Get-Content -LiteralPath $greyboxRoomPath -Raw -Encoding UTF8
$mudflatsRoom = Get-Content -LiteralPath $mudflatsRoomPath -Raw -Encoding UTF8

foreach ($requiredText in @(
    "@export var display_name",
    "func get_hover_label()",
    "interaction_key",
    "_format_hover_label"
)) {
    if ($interactionHotspot -notmatch [regex]::Escape($requiredText)) {
        throw "Act I interaction hotspot missing hover label contract: $requiredText"
    }
}

foreach ($requiredText in @(
    "@export var display_name",
    "func get_hover_label()",
    "target_room",
    "_format_hover_label"
)) {
    if ($exitHotspot -notmatch [regex]::Escape($requiredText)) {
        throw "Act I exit hotspot missing hover label contract: $requiredText"
    }
}

foreach ($requiredText in @(
    "_bind_hotspot_feedback",
    "mouse_entered",
    "mouse_exited",
    "_on_hotspot_mouse_entered",
    "_on_hotspot_mouse_exited",
    "selected_verb",
    "get_hover_label",
    "_refresh_status()"
)) {
    if ($greyboxRoom -notmatch [regex]::Escape($requiredText)) {
        throw "Act I greybox room missing runtime hover feedback hook: $requiredText"
    }
}

foreach ($requiredText in @(
    "HOVER_LABELS",
    "mouse_entered",
    "mouse_exited",
    "_on_hotspot_mouse_entered",
    "_on_hotspot_mouse_exited",
    "selected_verb",
    "_hover_label"
)) {
    if ($mudflatsRoom -notmatch [regex]::Escape($requiredText)) {
        throw "Mudflats tutorial room missing runtime hover feedback hook: $requiredText"
    }
}

$hoverLabelBlock = [regex]::Match($mudflatsRoom, "const HOVER_LABELS := \{(?<block>[\s\S]*?)\}")
if (-not $hoverLabelBlock.Success) {
    throw "Mudflats hover labels block was not found."
}

foreach ($forbiddenText in @(
    "cf_",
    "GREED",
    "LUST",
    "PRIDE",
    "CRUELTY",
    "COWARDICE",
    "BETRAYAL",
    "Borrowed Heartbeat",
    "Name Restored",
    "Debt Forgiven",
    "Registrar counter",
    "category trump"
)) {
    if ($hoverLabelBlock.Groups["block"].Value.Contains($forbiddenText)) {
        throw "Mudflats hover labels expose route or duel spoiler text: $forbiddenText"
    }
}

Write-Host "Act I hotspot hover feedback validation passed: verb-target labels are wired without route or duel spoilers."
