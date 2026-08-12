$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$notesScript = Join-Path $PSScriptRoot "New-ActIHumanPlaytestNotes.ps1"
$validationPath = Join-Path $root "docs\playtest\results\act_i_human_review_validation.md"
$latestPath = Join-Path $root "docs\playtest\results\act_i_human_playtest_latest.md"

if (-not (Test-Path -LiteralPath $notesScript)) {
    throw "Missing Act I human notes generator: $notesScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $notesScript -OutputPath $validationPath
if ($LASTEXITCODE -ne 0) {
    throw "Act I human review notes generation failed."
}

if (-not (Test-Path -LiteralPath $validationPath)) {
    throw "Missing generated Act I human review validation notes: $validationPath"
}

$notes = Get-Content -LiteralPath $validationPath -Raw
[System.IO.File]::WriteAllText($latestPath, $notes, [System.Text.UTF8Encoding]::new($false))

$expectedCommit = (& git -C $root rev-parse --short=12 HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($expectedCommit)) {
    $expectedCommit = "unknown"
} else {
    $expectedCommit = [string]$expectedCommit
}

foreach ($requiredText in @(
    "Act I Human Review Notes",
    "Build commit: $expectedCommit",
    "Greybox Playtest",
    "Act I Human Greybox Playtest",
    "Art Readability Review",
    "Act I Art Readability Review",
    "Proceed to paintovers: yes / no",
    "Contact sheet reviewed: yes / no",
    "Decision CSV date format checked: yes / no",
    "YYYY-MM-DD",
    "Keep / revise before art / stop and redesign:",
    "Registrar duel staging preserves accepted Litany format",
    "Hard-R Float staging stays steam/silhouette/privacy only"
)) {
    if ($notes -notmatch [regex]::Escape($requiredText)) {
        throw "Act I human review notes missing required text: $requiredText"
    }
}

$roomCheckCount = ([regex]::Matches($notes, "Room checks:")).Count
if ($roomCheckCount -ne 11) {
    throw "Act I human review notes expected 11 art room check sections, got $roomCheckCount."
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ï»¿", "`t", "	ools/")) {
    if ($notes.Contains($forbiddenText)) {
        throw "Act I human review notes contain malformed generated Markdown: $forbiddenText"
    }
}
if ($notes -match "[^\u0000-\u007F]") {
    throw "Act I human review notes must stay ASCII-only."
}

if (-not (Test-Path -LiteralPath $latestPath)) {
    throw "Missing stable latest Act I human review notes: $latestPath"
}
$latestNotes = Get-Content -LiteralPath $latestPath -Raw
if ($latestNotes -ne $notes) {
    throw "Stable latest Act I human review notes differ from validated review notes."
}

Write-Host "Act I human review notes validation passed: roomChecks=$roomCheckCount, path=$validationPath"
