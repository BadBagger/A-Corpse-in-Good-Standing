$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIArtReadabilityReview.ps1"
$reviewPath = Join-Path $root "docs\playtest\act_i_art_readability_review.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I art readability review exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I art readability review export failed."
}

if (-not (Test-Path -LiteralPath $reviewPath)) {
    throw "Missing generated Act I art readability review: $reviewPath"
}

$review = Get-Content -LiteralPath $reviewPath -Raw

foreach ($requiredText in @(
    "Act I Art Readability Review",
    "Global pass marks:",
    "Puzzle-critical objects are the brightest readable shapes",
    "Corvin's side-on walk path remains clear in the y 650-800 band",
    "Grey Float stays hard-R",
    "Registrar art preserves the accepted Litany UI format",
    "Contact sheet reviewed: yes / no",
    "Decision CSV date format checked: yes / no",
    "YYYY-MM-DD",
    "Final Decision",
    "Proceed to paintovers: yes / no"
)) {
    if ($review -notmatch [regex]::Escape($requiredText)) {
        throw "Act I art readability review missing required text: $requiredText"
    }
}

$requiredRooms = @(
    "R01 - Mudflats",
    "R02 - The Old Quay",
    "R03 - Salt Market",
    "R05 - Harbor Registry",
    "R06 - The Bone Chandler",
    "R07 - The Almshouse",
    "R08 - The Fish Hall",
    "R09 - Church of the Drowned",
    "R10 - The Grey Float",
    "R11 - Harbormaster's Office",
    "R12 - Sabine's Office"
)
foreach ($roomHeading in $requiredRooms) {
    if ($review -notmatch [regex]::Escape("## $roomHeading")) {
        throw "Act I art readability review missing room heading: $roomHeading"
    }
}

foreach ($requiredSpecialCheck in @(
    "Wet target reads as reusable verb target",
    "Confession-source staging reads as overheard/discovered truth, not a duel UI",
    "Registrar duel staging preserves accepted Litany format",
    "Hard-R Float staging stays steam/silhouette/privacy only",
    "Amber reads intentionally unsafe, not cozy/safe"
)) {
    if ($review -notmatch [regex]::Escape($requiredSpecialCheck)) {
        throw "Act I art readability review missing special check: $requiredSpecialCheck"
    }
}

$roomCheckCount = ([regex]::Matches($review, "Room checks:")).Count
if ($roomCheckCount -ne 11) {
    throw "Act I art readability review expected 11 room check sections, got $roomCheckCount."
}

$requiredFixCount = ([regex]::Matches($review, "Required fixes before paint:")).Count
if ($requiredFixCount -ne 11) {
    throw "Act I art readability review expected 11 required-fix sections, got $requiredFixCount."
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ï»¿", "`t", "	ools/")) {
    if ($review.Contains($forbiddenText)) {
        throw "Act I art readability review contains malformed generated Markdown: $forbiddenText"
    }
}
if ($review -match "[^\u0000-\u007F]") {
    throw "Act I art readability review must stay ASCII-only."
}

Write-Host "Act I art readability review validation passed: rooms=$roomCheckCount, requiredFixSections=$requiredFixCount."
