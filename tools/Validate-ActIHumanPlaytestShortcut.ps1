$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$shortcutPath = Join-Path $root "PLAY_ACT_I_REVIEW.cmd"

if (-not (Test-Path -LiteralPath $shortcutPath -PathType Leaf)) {
    throw "Missing Act I playable review shortcut: $shortcutPath"
}

$text = Get-Content -LiteralPath $shortcutPath -Raw
foreach ($requiredText in @(
    "@echo off",
    "setlocal",
    'set "ROOT=%~dp0"',
    'cd /d "%ROOT%"',
    'powershell -NoProfile -ExecutionPolicy Bypass -File "tools\Start-ActIHumanPlaytest.ps1" -RefreshAutomatedReport -ResetNarrativeState',
    "exit /b %ERRORLEVEL%"
)) {
    if ($text -notmatch [regex]::Escape($requiredText)) {
        throw "Act I playable review shortcut missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @(
    "-NoLaunch",
    "-SkipNotes",
    "--editor",
    "godot",
    "Godot_v"
)) {
    if ($text -match [regex]::Escape($forbiddenText)) {
        throw "Act I playable review shortcut must not bypass the validated launcher with: $forbiddenText"
    }
}

$output = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIHumanPlaytestLaunch.ps1") 2>&1
$exit = $LASTEXITCODE
if ($null -ne $exit -and $exit -ne 0) {
    throw "Act I playable review shortcut target failed launch validation: $($output -join ' ')"
}

Write-Host "Act I playable review shortcut validation passed: PLAY_ACT_I_REVIEW.cmd targets the validated clean-state launch preflight."
