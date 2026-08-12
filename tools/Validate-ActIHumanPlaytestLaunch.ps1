$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$startScript = Join-Path $PSScriptRoot "Start-ActIHumanPlaytest.ps1"

if (-not (Test-Path -LiteralPath $startScript)) {
    throw "Missing Act I human playtest launcher: $startScript"
}

$launcherText = Get-Content -LiteralPath $startScript -Raw
foreach ($requiredLauncherText in @(
    "ResetNarrativeState",
    "Clear-ActINarrativeState",
    "config/name",
    "Godot\app_userdata",
    "narrative_state.json",
    "Remove-Item -LiteralPath",
    "Refusing to clear narrative state outside Godot app_userdata"
)) {
    if ($launcherText -notmatch [regex]::Escape($requiredLauncherText)) {
        throw "Act I human playtest launcher missing clean-state reset contract: $requiredLauncherText"
    }
}

$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $startScript -NoLaunch -SkipNotes -ResetNarrativeState 2>&1
$exit = $LASTEXITCODE
if ($null -ne $exit -and $exit -ne 0) {
    throw "Act I human playtest launch preflight failed with exit code $exit. Output: $($output -join ' ')"
}

$text = $output -join "`n"
foreach ($requiredText in @(
    "Act I human playtest launch preflight passed.",
    "Godot:",
    "Args: --path",
    "Reset narrative state:",
    "Review artifacts:",
    "docs/checkpoints/step_5_human_review_bundle.md",
    "docs/playtest/act_i_player_review_card.md",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/playtest/act_i_review_decisions_template.csv",
    "docs/art/act_i_review_contact_sheet.html",
    "docs/art/act_i_hotspot_overlay.svg",
    "docs/art/act_i_background_ready_source_packets.md",
    "Act I ready-source packet validation passed",
    "Act I player review card validation passed",
    "Step 5 review dashboard validation passed",
    "Step 5 human review bundle validation passed",
    "Act I review handoff sync validation passed"
)) {
    if ($text -notmatch [regex]::Escape($requiredText)) {
        throw "Act I human playtest launch preflight missing required output: $requiredText"
    }
}

if ($text -match "Started Act I human playtest in Godot") {
    throw "Act I human playtest preflight must not launch Godot when -NoLaunch is set."
}

foreach ($relativePath in @(
    "docs/checkpoints/step_5_human_review_bundle.md",
    "docs/playtest/act_i_player_review_card.md",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/playtest/act_i_review_decisions_template.csv",
    "docs/art/act_i_review_contact_sheet.html",
    "docs/art/act_i_hotspot_overlay.svg",
    "docs/art/act_i_background_ready_source_packets.md"
)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Act I human playtest launch preflight references missing review artifact: $relativePath"
    }
}

Write-Host "Act I human playtest launch validation passed: no-launch preflight includes clean narrative-state reset, synced review artifacts, and ready-source packet index."
