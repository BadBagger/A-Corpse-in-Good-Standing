$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-Step5HumanReviewBundle.ps1"
$jsonPath = Join-Path $root "docs\checkpoints\step_5_human_review_bundle.json"
$mdPath = Join-Path $root "docs\checkpoints\step_5_human_review_bundle.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Step 5 human review bundle exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Step 5 human review bundle export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated Step 5 human review bundle artifact: $path"
    }
}

$bundle = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$sourceStamps = @($bundle.source_modified_utc)
$rooms = @($bundle.rooms)
$reviewArtifacts = @($bundle.review_artifacts)
$report = Get-Content -LiteralPath $mdPath -Raw

if ([string]::IsNullOrWhiteSpace([string]$bundle.generated_at_utc)) {
    throw "Step 5 human review bundle missing generated_at_utc."
}
try {
    [void][datetime]::Parse([string]$bundle.generated_at_utc)
} catch {
    throw "Step 5 human review bundle generated_at_utc must be parseable."
}

if ($bundle.readiness_state -ne "green_for_review") {
    throw "Step 5 human review bundle expected readiness_state green_for_review, got $($bundle.readiness_state)."
}
if ($bundle.paintover_gate_status -notin @("ready", "blocked_pending_human_review")) {
    throw "Step 5 human review bundle has invalid paintover gate status: $($bundle.paintover_gate_status)."
}
if ([int]$bundle.ready_rooms + [int]$bundle.blocked_rooms -ne 11) {
    throw "Step 5 human review bundle ready/blocked room counts must total 11."
}
if ([int]$bundle.decision_rows -ne 11) {
    throw "Step 5 human review bundle expected 11 decision CSV rows, got $($bundle.decision_rows)."
}
if ($rooms.Count -ne 11) {
    throw "Step 5 human review bundle expected 11 rooms, got $($rooms.Count)."
}
if ($sourceStamps.Count -lt 10) {
    throw "Step 5 human review bundle expected at least 10 source stamps, got $($sourceStamps.Count)."
}

foreach ($stamp in $sourceStamps) {
    $relativePath = [string]$stamp.path
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Step 5 human review bundle source is missing: $relativePath"
    }
    $actualModifiedUtc = (Get-Item -LiteralPath $absolutePath).LastWriteTimeUtc.ToString("o")
    if ([string]$stamp.modified_utc -ne $actualModifiedUtc) {
        throw "Step 5 human review bundle source stamp is stale for $relativePath."
    }
}

foreach ($artifact in $reviewArtifacts) {
    $absolutePath = Join-Path $root ([string]$artifact -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Step 5 human review bundle references missing artifact: $artifact"
    }
}

foreach ($requiredText in @(
    "Step 5 Human Review Bundle",
    "Generated at UTC: $($bundle.generated_at_utc)",
    "Readiness state: green_for_review",
    "Paintover gate status: $($bundle.paintover_gate_status)",
    "Decision CSV rows: 11",
    "Launch review:",
    "Preflight without launch:",
    'Copy the generated `Build commit:` value',
    'into `build_commit` for every non-pending decision row',
    "Dry-run decisions:",
    "Apply decisions after a clean dry run:",
    "accepted Litany/Registrar duel format",
    "do not add a second confession-spend UI",
    "Grey Float hard-R",
    "steam, silhouette, privacy, and agency only",
    "Treat ready-source packets as Meshy/imagegen source acquisition only; they do not approve final background plates.",
    "Treat the generated look target as mood/readability reference only",
    "it is not final room art, hotspot authority, or character sprite source",
    "Do not start final paintovers while paintover_gate_status is blocked_pending_human_review.",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/playtest/act_i_player_review_card.md",
    "docs/playtest/act_i_review_decisions_template.csv",
    "docs/playtest/act_i_review_handoff_sync.md",
    "docs/art/act_i_review_contact_sheet.html",
    "docs/art/act_i_hotspot_overlay.svg",
    "docs/art/act_i_background_ready_source_packets.md",
    "docs/art/act_i_look_target_reference.md",
    "docs/art/act_i_paintover_packet.md",
    "docs/art/act_i_paintover_start_gate.md",
    "Room Status"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Step 5 human review bundle missing required text: $requiredText"
    }
}

$playerCardPath = Join-Path $root "docs\playtest\act_i_player_review_card.md"
$playerCard = Get-Content -LiteralPath $playerCardPath -Raw
foreach ($requiredText in @(
    "Act I Player Review Card",
    "Do Not Explain Up Front",
    "Spoken confessions are spent forever.",
    "Finished Act I means Corvin reaches Sabine's office"
)) {
    if ($playerCard -notmatch [regex]::Escape($requiredText)) {
        throw "Step 5 human review bundle player card source missing required text: $requiredText"
    }
}

foreach ($room in $rooms) {
    if ([string]::IsNullOrWhiteSpace([string]$room.room_code) -or [string]::IsNullOrWhiteSpace([string]$room.title)) {
        throw "Step 5 human review bundle has a room without room_code/title."
    }
    if ($report -notmatch [regex]::Escape([string]$room.room_code) -or $report -notmatch [regex]::Escape([string]$room.title)) {
        throw "Step 5 human review bundle report missing room row for $($room.room_code) $($room.title)."
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Step 5 human review bundle contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Step 5 human review bundle must stay ASCII-only."
}

Write-Host "Step 5 human review bundle validation passed: rooms=$($rooms.Count), ready=$($bundle.ready_rooms), blocked=$($bundle.blocked_rooms), sources=$($sourceStamps.Count)."
