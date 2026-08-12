$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\checkpoints\step_5_human_review_bundle.json"
$mdPath = Join-Path $root "docs\checkpoints\step_5_human_review_bundle.md"

$sourcePaths = [ordered]@{
    "docs/checkpoints/step_5_review_dashboard.json" = Join-Path $root "docs\checkpoints\step_5_review_dashboard.json"
    "docs/checkpoints/step_5_act_i_art_pass_readiness.md" = Join-Path $root "docs\checkpoints\step_5_act_i_art_pass_readiness.md"
    "docs/playtest/act_i_player_review_card.md" = Join-Path $root "docs\playtest\act_i_player_review_card.md"
    "docs/playtest/results/act_i_human_playtest_latest.md" = Join-Path $root "docs\playtest\results\act_i_human_playtest_latest.md"
    "docs/playtest/act_i_review_decisions_template.csv" = Join-Path $root "docs\playtest\act_i_review_decisions_template.csv"
    "docs/playtest/act_i_review_handoff_sync.md" = Join-Path $root "docs\playtest\act_i_review_handoff_sync.md"
    "docs/art/act_i_paintover_start_gate.json" = Join-Path $root "docs\art\act_i_paintover_start_gate.json"
    "docs/art/act_i_review_contact_sheet.html" = Join-Path $root "docs\art\act_i_review_contact_sheet.html"
    "docs/art/act_i_hotspot_overlay.svg" = Join-Path $root "docs\art\act_i_hotspot_overlay.svg"
    "docs/art/act_i_background_ready_source_packets.md" = Join-Path $root "docs\art\act_i_background_ready_source_packets.md"
    "docs/art/act_i_paintover_packet.md" = Join-Path $root "docs\art\act_i_paintover_packet.md"
}

foreach ($entry in $sourcePaths.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $entry.Value)) {
        throw "Missing Step 5 human review bundle source: $($entry.Key)"
    }
}

$dashboard = Get-Content -LiteralPath $sourcePaths["docs/checkpoints/step_5_review_dashboard.json"] -Raw | ConvertFrom-Json
$startGate = Get-Content -LiteralPath $sourcePaths["docs/art/act_i_paintover_start_gate.json"] -Raw | ConvertFrom-Json
$decisionRows = @(Import-Csv -LiteralPath $sourcePaths["docs/playtest/act_i_review_decisions_template.csv"])
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

$sourceStamps = @()
foreach ($entry in $sourcePaths.GetEnumerator()) {
    $item = Get-Item -LiteralPath $entry.Value
    $sourceStamps += [ordered]@{
        path = $entry.Key
        modified_utc = $item.LastWriteTimeUtc.ToString("o")
    }
}

$rooms = @($startGate.rooms | ForEach-Object {
    [ordered]@{
        room_id = [string]$_.room_id
        room_code = [string]$_.room_code
        title = [string]$_.title
        review_status = [string]$_.review_status
        ready_for_paintover = [bool]$_.ready_for_paintover
        target_paintover_source = [string]$_.target_paintover_source
        blockers = @($_.blockers)
    }
})

$bundle = [ordered]@{
    generated_from = @($sourcePaths.Keys)
    generated_at_utc = $generatedAtUtc
    source_modified_utc = $sourceStamps
    purpose = "Compact Step 5 human-review launch bundle for Act I art-pass review."
    readiness_state = [string]$dashboard.readiness_state
    paintover_gate_status = [string]$startGate.status
    ready_rooms = [int]$startGate.ready_count
    blocked_rooms = [int]$startGate.blocked_count
    decision_rows = $decisionRows.Count
    launch_command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Start-ActIHumanPlaytest.ps1 -RefreshAutomatedReport"
    no_launch_preflight_command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Start-ActIHumanPlaytest.ps1 -RefreshAutomatedReport -NoLaunch"
    dry_run_decisions_command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Import-ActIReviewDecisions.ps1 -InputCsv docs\playtest\act_i_review_decisions_template.csv -DryRun"
    apply_decisions_command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Import-ActIReviewDecisions.ps1 -InputCsv docs\playtest\act_i_review_decisions_template.csv -Apply"
    rule_locks = @(
        "Keep the accepted Litany/Registrar duel format; do not add a second confession-spend UI.",
        "Keep Grey Float hard-R: steam, silhouette, privacy, and agency only.",
        "Do not start final paintovers while paintover_gate_status is blocked_pending_human_review."
    )
    review_artifacts = @(
        "docs/checkpoints/step_5_act_i_art_pass_readiness.md",
        "docs/checkpoints/step_5_review_dashboard.md",
        "docs/playtest/act_i_player_review_card.md",
        "docs/playtest/results/act_i_human_playtest_latest.md",
        "docs/playtest/act_i_review_decisions_template.csv",
        "docs/playtest/act_i_review_handoff_sync.md",
        "docs/art/act_i_review_contact_sheet.html",
        "docs/art/act_i_hotspot_overlay.svg",
        "docs/art/act_i_background_ready_source_packets.md",
        "docs/art/act_i_paintover_packet.md",
        "docs/art/act_i_paintover_start_gate.md"
    )
    rooms = $rooms
}

$bundle | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Step 5 Human Review Bundle",
    "",
    'Generated by `tools/Export-Step5HumanReviewBundle.ps1` from the current Step 5 dashboard, start gate, latest notes, decision CSV, handoff sync, contact sheet, hotspot overlay, ready-source packets, and paintover packet.',
    "",
    "Purpose: one compact launch and review index for Act I art-pass human review.",
    "",
    "Generated at UTC: $generatedAtUtc",
    "",
    "Readiness state: $($bundle.readiness_state)",
    "Paintover gate status: $($bundle.paintover_gate_status)",
    "Ready rooms: $($bundle.ready_rooms)",
    "Blocked rooms: $($bundle.blocked_rooms)",
    "Decision CSV rows: $($bundle.decision_rows)",
    "",
    "## Commands",
    "",
    "- Launch review: ``$($bundle.launch_command)``",
    "- Preflight without launch: ``$($bundle.no_launch_preflight_command)``",
    "- Dry-run decisions: ``$($bundle.dry_run_decisions_command)``",
    "- Apply decisions after a clean dry run: ``$($bundle.apply_decisions_command)``",
    "",
    "## Rule Locks",
    "",
    "- Keep the accepted Litany/Registrar duel format; do not add a second confession-spend UI.",
    "- Keep Grey Float hard-R: steam, silhouette, privacy, and agency only.",
    "- Treat ready-source packets as Meshy/imagegen source acquisition only; they do not approve final background plates.",
    "- Do not start final paintovers while paintover_gate_status is blocked_pending_human_review.",
    "",
    "## Review Artifacts",
    ""
)

foreach ($artifact in $bundle.review_artifacts) {
    $lines += "- ``$artifact``"
}

$lines += @(
    "",
    "## Source Modified UTC",
    ""
)
foreach ($stamp in $sourceStamps) {
    $lines += "- ``$($stamp.path)``: $($stamp.modified_utc)"
}

$lines += @(
    "",
    "## Room Status",
    "",
    "| Room | Review | Ready | Paintover Source | Blockers |",
    "|---|---|---:|---|---|"
)
foreach ($room in $rooms) {
    $blockers = if ($room.blockers.Count -gt 0) { $room.blockers -join ", " } else { "none" }
    $lines += "| $($room.room_code) $($room.title) | $($room.review_status) | $($room.ready_for_paintover) | ``$($room.target_paintover_source)`` | $blockers |"
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Step 5 human review bundle JSON -> $jsonPath"
Write-Host "Exported Step 5 human review bundle report -> $mdPath"
Write-Host "Step 5 human review bundle: status=$($bundle.paintover_gate_status), ready=$($bundle.ready_rooms), blocked=$($bundle.blocked_rooms), decisionRows=$($bundle.decision_rows)"
