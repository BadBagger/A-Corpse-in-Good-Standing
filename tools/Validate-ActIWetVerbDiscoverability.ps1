$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$narrativePath = Join-Path $root "game\autoloads\narrative_state.gd"
$mudflatsPath = Join-Path $root "game\rooms\mudflats\room_mudflats.gd"
$playerReviewCardPath = Join-Path $root "docs\playtest\act_i_player_review_card.md"

foreach ($path in @($narrativePath, $mudflatsPath, $playerReviewCardPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing wet verb discoverability input: $path"
    }
}

$narrative = Get-Content -LiteralPath $narrativePath -Raw -Encoding UTF8
$mudflats = Get-Content -LiteralPath $mudflatsPath -Raw -Encoding UTF8
$playerReviewCard = Get-Content -LiteralPath $playerReviewCardPath -Raw -Encoding UTF8

foreach ($requiredText in @(
    "`"j_corvin_drips`"",
    "`"Wet Work`"",
    "Corvin's coat does not stop dripping",
    "Paper, lamps, salt, and dignity"
)) {
    if ($narrative -notmatch [regex]::Escape($requiredText)) {
        throw "Narrative state missing reusable wet-verb journal language: $requiredText"
    }
}

foreach ($requiredText in @(
    "func _handle_coat",
    "narrative.add_journal(`"j_corvin_drips`")",
    "Corvin wrings out a sleeve"
)) {
    if ($mudflats -notmatch [regex]::Escape($requiredText)) {
        throw "Mudflats coat tutorial does not teach reusable wet-verb state: $requiredText"
    }
}

$mudflatsCoatBlock = [regex]::Match($mudflats, "func _handle_coat\(verb: String\) -> void:(?<block>[\s\S]*?)func _handle_tomas")
if (-not $mudflatsCoatBlock.Success) {
    throw "Mudflats coat handler block was not found."
}

foreach ($forbiddenText in @(
    "ChurchSign",
    "RopeCleat",
    "DeskLamp",
    "Drain",
    "KestrelLedger",
    "Borrowed Heartbeat",
    "Name Restored",
    "Debt Forgiven",
    "cf_",
    "GREED",
    "LUST",
    "PRIDE",
    "CRUELTY",
    "COWARDICE",
    "BETRAYAL"
)) {
    if ($mudflatsCoatBlock.Groups["block"].Value.Contains($forbiddenText) -or $narrative.Contains($forbiddenText)) {
        throw "Wet-verb tutorial exposes later route or duel spoiler text: $forbiddenText"
    }
}

if ($playerReviewCard -notmatch [regex]::Escape("- The wet verb solution pattern.")) {
    throw "Player review card no-spoiler control no longer tracks the wet verb solution pattern."
}

Write-Host "Act I wet verb discoverability validation passed: Mudflats teaches reusable wetness without naming later solutions."
