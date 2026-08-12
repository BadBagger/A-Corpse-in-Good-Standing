$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$duelPanelPath = Join-Path $root "game\ui\duel_panel.gd"
$remainingBeatsPath = Join-Path $root "docs\playtest\act_i_greybox_remaining_beats.md"

foreach ($path in @($duelPanelPath, $remainingBeatsPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing duel readability input: $path"
    }
}

$duelPanel = Get-Content -LiteralPath $duelPanelPath -Raw -Encoding UTF8
$remainingBeats = Get-Content -LiteralPath $remainingBeatsPath -Raw -Encoding UTF8

foreach ($requiredText in @(
    "const DUEL_RULE_HINT",
    "counter weight must be higher",
    "sin must match or trump",
    "Spoken cards are spent",
    "func _rejection_reason",
    "weight is not higher than the accusation",
    "sin category does not match or trump",
    "Current accusation:",
    "Salt is taken on failed counters"
)) {
    if ($duelPanel -notmatch [regex]::Escape($requiredText)) {
        throw "Duel panel missing readability affordance: $requiredText"
    }
}

foreach ($requiredText in @(
    "Registrar duel readability",
    "attack category, weight pressure, Salt, spent cards",
    "without changing duel rules"
)) {
    if ($remainingBeats -notmatch [regex]::Escape($requiredText)) {
        throw "Remaining-beats review no longer tracks Registrar duel readability need: $requiredText"
    }
}

foreach ($forbiddenText in @(
    "valid counter",
    "correct counter",
    "choose this",
    "cf_bt_manifest is correct",
    "second confession-spend UI"
)) {
    if ($duelPanel.Contains($forbiddenText)) {
        throw "Duel panel readability affordance exposes solution text or adds the wrong interface: $forbiddenText"
    }
}

Write-Host "Duel panel readability validation passed: failure reasons and rule hints are present without exposing exact counters."
