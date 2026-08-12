$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-Step5ReviewDashboard.ps1"
$jsonPath = Join-Path $root "docs\checkpoints\step_5_review_dashboard.json"
$mdPath = Join-Path $root "docs\checkpoints\step_5_review_dashboard.md"
$startGatePath = Join-Path $root "docs\art\act_i_paintover_start_gate.json"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Step 5 review dashboard exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Step 5 review dashboard export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated Step 5 review dashboard artifact: $path"
    }
}

$dashboard = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$workflow = @($dashboard.workflow)
$artifacts = @($dashboard.artifacts)
$sourceModifiedUtc = (Get-Item -LiteralPath $startGatePath).LastWriteTimeUtc.ToString("o")

if ([string]$dashboard.generated_from -ne "docs/art/act_i_paintover_start_gate.json") {
    throw "Step 5 dashboard generated_from must point to docs/art/act_i_paintover_start_gate.json."
}
if ([string]::IsNullOrWhiteSpace([string]$dashboard.generated_at_utc)) {
    throw "Step 5 dashboard missing generated_at_utc freshness stamp."
}
if ([string]$dashboard.source_modified_utc -ne $sourceModifiedUtc) {
    throw "Step 5 dashboard source_modified_utc is stale or inconsistent with the paintover start gate."
}
try {
    $generatedAt = [datetime]::Parse([string]$dashboard.generated_at_utc).ToUniversalTime()
    $sourceModified = [datetime]::Parse([string]$dashboard.source_modified_utc).ToUniversalTime()
} catch {
    throw "Step 5 dashboard freshness stamps must be parseable UTC datetimes."
}
if ($generatedAt -lt $sourceModified) {
    throw "Step 5 dashboard generated_at_utc predates its source paintover start gate."
}

if ($dashboard.readiness_state -ne "green_for_review") {
    throw "Step 5 dashboard expected readiness_state green_for_review, got $($dashboard.readiness_state)."
}
if ($dashboard.paintover_gate_status -notin @("ready", "blocked_pending_human_review")) {
    throw "Step 5 dashboard has invalid paintover gate status: $($dashboard.paintover_gate_status)."
}
if ([int]$dashboard.ready_rooms + [int]$dashboard.blocked_rooms -ne 11) {
    throw "Step 5 dashboard ready/blocked room counts must total 11."
}
if ($workflow.Count -ne 30) {
    throw "Step 5 dashboard expected 30 ordered review steps, got $($workflow.Count)."
}
if ($artifacts.Count -lt 31) {
    throw "Step 5 dashboard expected at least 31 artifact references, got $($artifacts.Count)."
}

foreach ($relativePath in $artifacts) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Step 5 dashboard references missing artifact: $relativePath"
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Step 5 Review Dashboard",
    "Generated at UTC: $($dashboard.generated_at_utc)",
    "Source modified UTC: $($dashboard.source_modified_utc)",
    "Readiness state: green_for_review",
    "Paintover gate status: $($dashboard.paintover_gate_status)",
    "Ready rooms: $($dashboard.ready_rooms)",
    "Blocked rooms: $($dashboard.blocked_rooms)",
    "Do not start final paintovers while the start gate reports blocked_pending_human_review.",
    "accepted Litany/Registrar duel format",
    "do not add a second confession-spend UI",
    "Grey Float hard-R",
    "no explicit X content",
    "Review the Act I VO timing manifest before recording locks.",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/vo/act_i_vo_line_manifest.md",
    "Review the Litany confession VO manifest.",
    "docs/vo/confession_vo_manifest.md",
    "Review VO recording batches before any scratch generation.",
    "docs/vo/vo_recording_batches.md",
    "Review the manifest-driven VO cast plan.",
    "docs/vo/vo_cast_plan.md",
    "Review VO commercial readiness before any shipping decision.",
    "docs/vo/vo_commercial_readiness.md",
    "Test VO commercial readiness against stale upstream inputs.",
    "Commercial readiness regenerates cast-plan and audio-status inputs before deciding shipping blockers.",
    "Review the scratch VO recording queue.",
    "docs/vo/vo_recording_queue.md",
    "Review generated scratch VO recording packets.",
    "no packet files for pending-cast or cut/rewrite blocked minor-speaker batches",
    "docs/vo/vo_recording_packets_index.md",
    "Fill or review the minor-speaker casting decision sheet.",
    "docs/vo/vo_minor_speaker_decisions_template.md",
    "Dry-run minor-speaker casting decisions before applying them.",
    "docs/vo/vo_minor_speaker_decision_import_report.md",
    "Check VO audio asset intake status.",
    "unplanned/zero-byte/blocked pending-cast or cut/rewrite MP3s fail",
    "docs/vo/vo_audio_asset_status.md",
    "Open the Act I review contact sheet.",
    "docs/art/act_i_review_contact_sheet.html",
    "Each room blockout appears with walk band, marker positions, hotspot rows, duel-format lock, and Grey Float hard-R lock.",
    "Review Corvin's Act I side-priority animation work order.",
    "docs/art/corvin_side_priority_work_order.md",
    "Act I side talk/use/wet are the next animation targets before front/back or decay sheets.",
    "Review the Act I generated look target reference.",
    "docs/art/act_i_look_target_reference.md",
    "generated harbor image is treated as a mood/readability target only",
    "not final room art, hotspot authority, or diffusion-per-frame character source",
    "Export, validate, and fill the batch review decision sheet.",
    "every non-pending decision includes build_commit, reviewer, reviewed_at, decision_note, and look_target_reviewed=yes",
    "Dry-run the batch review decisions.",
    "Apply the reviewed decision sheet after the dry run is clean.",
    "docs/playtest/act_i_review_decisions_template.csv",
    "docs/playtest/act_i_review_decisions_template.md",
    "docs/playtest/act_i_review_decision_import_report.md",
    "docs/art/act_i_hotspot_overlay.svg",
    "Review the ready background source generation packets.",
    "docs/art/act_i_background_ready_source_packets.md",
    "Packets include only Meshy helper GLBs and imagegen reference boards that are safe to acquire now",
    "they are not final background plates and exclude held interactive/navigation PSD work",
    "docs/playtest/act_i_review_fix_tracker.md",
    "docs/art/act_i_paintover_start_gate.md",
    "Generate the approved-room paintover work order.",
    "preserves build_commit, reviewer, reviewed_at, decision_note, and look_target_reviewed proof",
    "docs/art/act_i_paintover_work_order.md",
    "Validate final PSD source intake against the work order.",
    "approved rows preserve work-order build_commit, reviewer, reviewed_at, decision_note, and look_target_reviewed proof",
    "docs/art/act_i_paintover_source_intake.md",
    "Audit final paintover completion.",
    "completion rows preserve source-intake build_commit, reviewer, reviewed_at, decision_note, and look_target_reviewed proof",
    "docs/art/act_i_final_paintover_completion.md",
    "Audit paintover review provenance across all final-art handoff layers.",
    "docs/art/act_i_paintover_review_provenance.md",
    "Approved rooms carry identical build_commit, reviewer, reviewed_at, decision_note, and look_target_reviewed proof from tracker through completion."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Step 5 review dashboard missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Step 5 review dashboard contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Step 5 review dashboard must stay ASCII-only."
}

Write-Host "Step 5 review dashboard validation passed: steps=$($workflow.Count), artifacts=$($artifacts.Count), ready=$($dashboard.ready_rooms), blocked=$($dashboard.blocked_rooms)."
