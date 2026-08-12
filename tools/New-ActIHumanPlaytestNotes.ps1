param(
    [switch]$GreyboxOnly,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$resultsDir = Join-Path $root "docs\playtest\results"
$templatePath = Join-Path $root "docs\playtest\act_i_human_greybox_playtest.md"
$artReviewPath = Join-Path $root "docs\playtest\act_i_art_readability_review.md"

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Missing Act I human playtest template: $templatePath"
}
if (-not $GreyboxOnly -and -not (Test-Path -LiteralPath $artReviewPath)) {
    throw "Missing Act I art readability review template: $artReviewPath"
}

if (-not (Test-Path -LiteralPath $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$createdAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$gitCommit = (& git -C $root rev-parse --short=12 HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitCommit)) {
    $gitCommit = "unknown"
} else {
    $gitCommit = [string]$gitCommit
}
$outPath = if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    Join-Path $resultsDir "act_i_human_playtest_$timestamp.md"
} else {
    $OutputPath
}
$shouldWriteLatest = [string]::IsNullOrWhiteSpace($OutputPath)
$latestPath = Join-Path $resultsDir "act_i_human_playtest_latest.md"
$outDir = Split-Path -Parent $outPath
if (-not [string]::IsNullOrWhiteSpace($outDir) -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$template = Get-Content -LiteralPath $templatePath -Raw
$sections = @(
    "# Act I Human Review Notes",
    "",
    "Created: $createdAt",
    "Build commit: $gitCommit",
    'Greybox template: `docs/playtest/act_i_human_greybox_playtest.md`',
    'Automated report: `docs/playtest/results/act_i_greybox_auto_report.md`',
    'Paintover packet: `docs/art/act_i_paintover_packet.md`',
    "",
    "Use this file for the Step 5 review run. The greybox playtest decides pacing and comprehension; the art readability review decides whether room layouts are ready for final paintover.",
    "",
    "## Greybox Playtest",
    "",
    $template
)

if (-not $GreyboxOnly) {
    $artReview = Get-Content -LiteralPath $artReviewPath -Raw
    $sections += @(
        "",
        "## Art Readability Review",
        "",
        $artReview
    )
}

$body = @(
    $sections
) -join "`r`n"

[System.IO.File]::WriteAllText($outPath, $body, [System.Text.UTF8Encoding]::new($false))

if ($shouldWriteLatest) {
    [System.IO.File]::WriteAllText($latestPath, $body, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Updated latest Act I human review notes -> $latestPath"
}

Write-Host "Created Act I human review notes -> $outPath"
