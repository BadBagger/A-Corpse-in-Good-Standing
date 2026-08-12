$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$castSheetPath = Join-Path $root "docs\VO_cast_sheet.md"
$blockerIndexPath = Join-Path $root "docs\checkpoints\production_blocker_index.md"

if (-not (Test-Path -LiteralPath $castSheetPath)) {
    throw "VO cast sheet is missing: docs/VO_cast_sheet.md"
}

if (-not (Test-Path -LiteralPath $blockerIndexPath)) {
    throw "Production blocker index is missing: docs/checkpoints/production_blocker_index.md"
}

$text = Get-Content -LiteralPath $castSheetPath -Raw -Encoding UTF8

$requiredPhrases = @(
    "## 7. PROJECT BLOCKERS LIVE ELSEWHERE",
    "docs/checkpoints/production_blocker_index.md",
    "Step 5 human review",
    "Corvin production animation",
    "Duel format is locked",
    "3D-to-Blender-to-2D hybrid",
    "diffusion-per-frame character sheets are reference only"
)

foreach ($phrase in $requiredPhrases) {
    if (-not $text.Contains($phrase)) {
        throw "VO cast sheet status section missing required phrase: $phrase"
    }
}

$forbiddenPhrases = @(
    "OPEN BLOCKERS",
    'game/gui/gui.tscn` missing',
    'Duel prototype "is it fun with 12 confessions" checkpoint',
    "Pixel art vs 3D-toon hybrid",
    "Ink-wash shader spike"
)

foreach ($phrase in $forbiddenPhrases) {
    if ($text.Contains($phrase)) {
        throw "VO cast sheet carries stale blocker phrase: $phrase"
    }
}

Write-Host "VO cast sheet status validation passed: stale project blockers removed, blocker index referenced."
