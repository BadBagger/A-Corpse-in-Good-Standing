$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $root "docs\playtest\act_i_player_review_card.md"
$outDir = Split-Path -Parent $outPath

if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$lines = @(
    "# Act I Player Review Card",
    "",
    "Purpose: the short handoff a tester can read before launching Act I. Keep this separate from the internal rubric so the player is not coached through the solution.",
    "",
    "## Player Setup",
    "",
    "You are Corvin Vale. You have washed back from the harbor dead, wet, and missing the last week of memory. Reach Sabine's office by proving you have standing in the port.",
    "",
    "## What To Do",
    "",
    "- Play naturally. Look at things, talk to people, use exits, and try suspicious objects.",
    "- Do not worry about a real-time death clock. Days advance only on story beats.",
    "- Treat Corvin's wet coat, missing pulse, journal, inventory, and Litany as game information.",
    "- If a duel starts, choose one confession from the Litany. Spoken confessions are spent forever.",
    "- Stop when Sabine's Act I office scene ends, or when you are too stuck to keep playing naturally.",
    "",
    "## Do Not Explain Up Front",
    "",
    "- The three Rites.",
    "- The wet verb solution pattern.",
    "- Confession category trump order, weights, or exact counters.",
    "- Expected route order.",
    "- Which rooms are still greybox or pending final paint.",
    "",
    "## Stuck Mark",
    "",
    "If you need help, pause and record the room, hotspot or UI, what you tried, and what you expected to happen. A rescue is review data, not a failure.",
    "",
    "## Finish Mark",
    "",
    "Finished Act I means Corvin reaches Sabine's office after completing the three Rites and the Act I close lands. If the player reaches that point and wants Act II, the playable slice did its main job."
)

Set-Content -LiteralPath $outPath -Value $lines -Encoding UTF8
Write-Host "Exported Act I player review card -> $outPath"
