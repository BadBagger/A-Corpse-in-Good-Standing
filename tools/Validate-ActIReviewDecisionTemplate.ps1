$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIReviewDecisionTemplate.ps1"
$csvPath = Join-Path $root "docs\playtest\act_i_review_decisions_template.csv"
$mdPath = Join-Path $root "docs\playtest\act_i_review_decisions_template.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I review decision template exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I review decision template export failed."
}

foreach ($path in @($csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated Act I review decision template artifact: $path"
    }
}

$rows = @(Import-Csv -LiteralPath $csvPath)
if ($rows.Count -ne 11) {
    throw "Act I review decision template expected 11 room rows, got $($rows.Count)."
}

$allowedDecisions = @("pending_review", "approved", "revise_before_art", "stop_and_redesign")
$requiredColumns = @(
    "room_id",
    "room_code",
    "title",
    "decision",
    "reviewer",
    "reviewed_at",
    "decision_note",
    "layout",
    "hotspot_readability",
    "walk_band",
    "palette_lighting",
    "content_compliance",
    "duel_format",
    "vo_timing_or_pacing",
    "risk_tags",
    "critical_hotspots",
    "close_pairs"
)

$seenRooms = @{}
foreach ($row in $rows) {
    foreach ($column in $requiredColumns) {
        if (-not ($row.PSObject.Properties.Name -contains $column)) {
            throw "Act I review decision template missing CSV column: $column"
        }
    }
    if ([string]::IsNullOrWhiteSpace($row.room_id) -or [string]::IsNullOrWhiteSpace($row.room_code) -or [string]::IsNullOrWhiteSpace($row.title)) {
        throw "Act I review decision template row has empty room identity: $($row | ConvertTo-Json -Compress)"
    }
    if ($seenRooms.ContainsKey($row.room_id)) {
        throw "Duplicate room in Act I review decision template: $($row.room_id)"
    }
    $seenRooms[$row.room_id] = $true
    if ($row.decision -notin $allowedDecisions) {
        throw "Invalid Act I review decision '$($row.decision)' for $($row.room_id)."
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Review Decision Template",
    "machine-readable batch handoff",
    "Allowed decisions: pending_review, approved, revise_before_art, stop_and_redesign.",
    'Any non-pending decision must include `reviewer`, `reviewed_at`, and `decision_note`; `reviewed_at` must use `YYYY-MM-DD`.',
    '`approved` marks the room as paintover-eligible',
    '`revise_before_art` must include at least one fix bucket note',
    '`stop_and_redesign` blocks final paintover',
    "Harbor Registry approval must preserve the accepted Litany/Registrar duel format.",
    "Harbor Registry non-pending decisions must include a duel_format note confirming the accepted Litany/Registrar duel format remains locked.",
    "Grey Float non-pending decisions must include a content_compliance note confirming hard-R staging: steam, silhouette, privacy, and agency only."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I review decision template report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I review decision template report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I review decision template report must stay ASCII-only."
}

Write-Host "Act I review decision template validation passed: rooms=$($rows.Count), decisions=$((@($rows | Group-Object decision | ForEach-Object { "$($_.Name):$($_.Count)" })) -join ', ')."
