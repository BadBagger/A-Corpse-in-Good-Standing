$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$sharedRoomPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$mudflatsRoomPath = Join-Path $root "game\rooms\mudflats\room_mudflats.gd"

foreach ($path in @($sharedRoomPath, $mudflatsRoomPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I playable hover focus input: $path"
    }
}

$sharedRoom = Get-Content -LiteralPath $sharedRoomPath -Raw
$mudflatsRoom = Get-Content -LiteralPath $mudflatsRoomPath -Raw

foreach ($requiredText in @(
    "_add_act_i_hover_focus_layer",
    "ActIHoverFocus",
    "_show_hover_focus",
    "_hide_hover_focus",
    "_make_hover_focus_polygon",
    "HoverFocusRing",
    "HoverFocusGlint",
    "mouse_entered",
    "mouse_exited",
    "Color(0.788235, 0.541176, 0.235294"
)) {
    if (-not $sharedRoom.Contains($requiredText)) {
        throw "Shared Act I room missing playable hover focus text: $requiredText"
    }
}

foreach ($requiredText in @(
    "_add_mudflats_hover_focus_layer",
    "ActIHoverFocus",
    "_show_hover_focus",
    "_hide_hover_focus",
    "_make_hover_focus_polygon",
    "HoverFocusRing",
    "HoverFocusGlint",
    "SaltMarketExit",
    "mouse_entered",
    "mouse_exited"
)) {
    if (-not $mudflatsRoom.Contains($requiredText)) {
        throw "Mudflats room missing playable hover focus text: $requiredText"
    }
}

foreach ($source in @($sharedRoom, $mudflatsRoom)) {
    $hoverFocusLines = ($source -split "`r?`n") | Where-Object {
        $_ -match "hover_focus|HoverFocus|focus_ring|focus_glint"
    }
    $hoverFocusText = $hoverFocusLines -join "`n"

    if ($hoverFocusText -match "debug|DEBUG|Debug") {
        throw "Playable hover focus must not introduce debug naming or debug-only presentation text."
    }
    if ($hoverFocusText -match "cf_|GREED|LUST|PRIDE|CRUELTY|COWARDICE|BETRAYAL|category trump") {
        throw "Playable hover focus must not expose duel/confession implementation text."
    }
    if ($source -notmatch "_hover_focus_tween\.kill\(\)") {
        throw "Playable hover focus must kill the hover tween on exit/re-entry."
    }
    if ($source -notmatch "queue_free\(\)") {
        throw "Playable hover focus must clear old hover nodes."
    }
}

Write-Host "Act I playable hover focus validation passed: shared rooms and Mudflats have transient in-world hover rings."
