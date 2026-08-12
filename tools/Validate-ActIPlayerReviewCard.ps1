$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIPlayerReviewCard.ps1"
$cardPath = Join-Path $root "docs\playtest\act_i_player_review_card.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I player review card exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I player review card export failed."
}

if (-not (Test-Path -LiteralPath $cardPath)) {
    throw "Missing Act I player review card: $cardPath"
}

$card = Get-Content -LiteralPath $cardPath -Raw

foreach ($requiredText in @(
    "Act I Player Review Card",
    "You are Corvin Vale.",
    "Reach Sabine's office by proving you have standing in the port.",
    "Do not worry about a real-time death clock.",
    "Days advance only on story beats.",
    "wet coat, missing pulse, journal, inventory, and Litany",
    "Spoken confessions are spent forever.",
    "Do Not Explain Up Front",
    "The three Rites.",
    "The wet verb solution pattern.",
    "Confession category trump order, weights, or exact counters.",
    "Expected route order.",
    "A rescue is review data, not a failure.",
    "Finished Act I means Corvin reaches Sabine's office after completing the three Rites"
)) {
    if ($card -notmatch [regex]::Escape($requiredText)) {
        throw "Act I player review card missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @(
    "Borrowed Heartbeat",
    "Name Restored",
    "Debt Forgiven",
    "Registrar counter",
    "cf_",
    "BETRAYAL",
    "GREED",
    "LUST",
    "PRIDE",
    "CRUELTY",
    "COWARDICE",
    "System.Object[]",
    "@{",
    "ÃƒÂ¯Ã‚Â»Ã‚Â¿",
    "`t"
)) {
    if ($card.Contains($forbiddenText)) {
        throw "Act I player review card contains forbidden spoiler or malformed text: $forbiddenText"
    }
}

if ($card -match "[^\u0000-\u007F]") {
    throw "Act I player review card must stay ASCII-only."
}

Write-Host "Act I player review card validation passed: $cardPath"
