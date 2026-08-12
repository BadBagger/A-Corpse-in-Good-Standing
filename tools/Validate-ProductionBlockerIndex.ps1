$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $root "docs\checkpoints\production_blocker_index.md"

if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "Production blocker index is missing: docs/checkpoints/production_blocker_index.md"
}

$text = Get-Content -LiteralPath $indexPath -Raw

$requiredSections = @(
    "# Production Blocker Index",
    "## Current State",
    "## Open Blockers",
    "## Verification Commands",
    "## Guardrails"
)

foreach ($section in $requiredSections) {
    if (-not $text.Contains($section)) {
        throw "Production blocker index missing section: $section"
    }
}

$requiredIssues = @(
    @{ Number = "1"; Title = "Step 5 Human Review: Act I art/readability signoff"; Url = "https://github.com/BadBagger/A-Corpse-in-Good-Standing/issues/1" },
    @{ Number = "2"; Title = "VO Readiness: licensing and minor-speaker decisions"; Url = "https://github.com/BadBagger/A-Corpse-in-Good-Standing/issues/2" },
    @{ Number = "3"; Title = "Corvin Animation: complete production sprite contract"; Url = "https://github.com/BadBagger/A-Corpse-in-Good-Standing/issues/3" }
)

foreach ($issue in $requiredIssues) {
    $expectedLink = "[#$($issue.Number) $($issue.Title)]($($issue.Url))"
    if (-not $text.Contains($expectedLink)) {
        throw "Production blocker index missing required GitHub issue link: #$($issue.Number) $($issue.Title)"
    }
}

$requiredEvidencePaths = @(
    "docs/checkpoints/step_4_act_i_greybox_room_graph.md",
    "docs/checkpoints/step_5_act_i_art_pass_readiness.md",
    "docs/vo/vo_commercial_readiness.md",
    "docs/vo/vo_audio_asset_status.md",
    "docs/vo/vo_minor_speaker_decisions_template.csv",
    "docs/art/corvin_runtime_sprite_assets_status.json",
    "docs/art/corvin_side_priority_work_order.md",
    "docs/art/corvin_side_action_render_queue.md",
    "docs/art/corvin_animation_asset_status.md"
)

foreach ($relativePath in $requiredEvidencePaths) {
    $literalRelativePath = $relativePath -replace "/", "\"
    $fullPath = Join-Path $root $literalRelativePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Production blocker index references missing evidence path: $relativePath"
    }

    if (-not $text.Contains($relativePath)) {
        throw "Production blocker index does not mention required evidence path: $relativePath"
    }
}

$requiredCommands = @(
    "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Run-RepoReadinessGates.ps1",
    "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Run-Step4Gates.ps1",
    "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Run-Step5ReadinessGates.ps1",
    "gh issue list --repo BadBagger/A-Corpse-in-Good-Standing --state open --limit 10"
)

foreach ($command in $requiredCommands) {
    if (-not $text.Contains($command)) {
        throw "Production blocker index missing verification command: $command"
    }
}

$requiredPhrases = @(
    "Local Step 2, Step 3, and Step 4 gates are green",
    "read-only Blender import proof",
    "0 ready / 11 blocked",
    "blocked_pending_licensing_review",
    "652 expected MP3s, 0 present",
    "8 present / 12 pending",
    "6 pending deterministic Blender render/import rows",
    "Polish side idle/walk, then complete Act I side talk/use/wet before front/back or Act II-III decay sheets",
    "10 present, 119 pending, 129 total",
    "Do not start final Act I paintovers",
    "Do not treat scratch VO as shipping-approved audio",
    "Do not replace the accepted Litany/Registrar duel format",
    "Do not use diffusion-per-frame character sheets"
)

foreach ($phrase in $requiredPhrases) {
    if (-not $text.Contains($phrase)) {
        throw "Production blocker index missing required blocker/guardrail phrase: $phrase"
    }
}

$blockerRows = @($text -split "`r?`n" | Where-Object { $_ -match "^\| \[#\d " })
if ($blockerRows.Count -ne 3) {
    throw "Production blocker index must contain exactly 3 blocker rows; found $($blockerRows.Count)."
}

Write-Host "Production blocker index validation passed: issues=3, evidencePaths=$($requiredEvidencePaths.Count), commands=$($requiredCommands.Count), guardrails=4."
