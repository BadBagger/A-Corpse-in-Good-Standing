$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIVoLineManifest.ps1"
$jsonPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$csvPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.csv"
$mdPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I VO manifest exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I VO manifest export failed."
}

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I VO manifest artifact: $path"
    }
}

$manifest = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$report = Get-Content -LiteralPath $mdPath -Raw
$lines = @($manifest.lines)
$speakers = @($manifest.speakers)

if ($lines.Count -lt 300) {
    throw "Expected at least 300 Act I Ink dialogue lines, got $($lines.Count)."
}
if ($rows.Count -ne $lines.Count) {
    throw "CSV row count $($rows.Count) does not match JSON line count $($lines.Count)."
}
if ([int]$manifest.line_count -ne $lines.Count) {
    throw "Manifest line_count does not match lines array."
}
if ([int]$manifest.vo_line_count + [int]$manifest.stage_direction_count -ne $lines.Count) {
    throw "VO plus stage-direction counts must equal total line count."
}
if ($speakers.Count -lt 10) {
    throw "Expected at least 10 speakers in Act I manifest, got $($speakers.Count)."
}

$ids = @{}
foreach ($line in $lines) {
    foreach ($field in @("line_id", "source_file", "line_number", "source_ref", "knot", "speaker", "text", "word_count", "recording_scope", "cast_status", "audio_path", "recording_status")) {
        if ($null -eq $line.$field -or [string]::IsNullOrWhiteSpace([string]$line.$field)) {
            throw "VO line has empty required field '$field': $($line | ConvertTo-Json -Compress)"
        }
    }
    if ($ids.ContainsKey($line.line_id)) {
        throw "Duplicate VO line id: $($line.line_id)"
    }
    $ids[$line.line_id] = $true
    if ($line.source_file -notmatch "^ink/.*\.ink$") {
        throw "VO line source must come from Ink only: $($line.source_file)"
    }
    if ($line.source_file -match "confessions\.ink" -or $line.text -match "^>\s") {
        throw "VO manifest must not duplicate Litany/confession prose: $($line.line_id)"
    }
    if ($line.recording_status -ne "unrecorded") {
        throw "Act I VO manifest should start unrecorded, got $($line.recording_status) on $($line.line_id)."
    }
    if ($line.recording_scope -notin @("vo_line", "stage_direction_review")) {
        throw "Invalid VO recording scope on $($line.line_id): $($line.recording_scope)"
    }
    if ([int]$line.word_count -lt 0) {
        throw "VO line word_count must not be negative: $($line.line_id)"
    }
    if ([int]$line.word_count -eq 0 -and $line.text -notmatch "^[\.\- ]+$") {
        throw "Zero-word VO line must be an explicit pause/ellipsis beat: $($line.line_id)"
    }
}

foreach ($speaker in @("CORVIN", "TOMAS", "REGISTRAR", "JUNO", "TEODOR", "SABINE", "KANE")) {
    $summary = @($speakers | Where-Object { $_.speaker -eq $speaker })[0]
    if ($null -eq $summary) {
        throw "Act I VO manifest missing expected speaker summary: $speaker"
    }
    if ($summary.cast_status -ne "scratch_cast") {
        throw "Expected scratch cast for $speaker, got $($summary.cast_status)."
    }
}

$narration = @($speakers | Where-Object { $_.speaker -eq "NARRATION" })[0]
if ($null -eq $narration -or $narration.cast_status -ne "not_cast_stage_direction") {
    throw "NARRATION must be present and marked not_cast_stage_direction."
}

$uncastCount = @($speakers | Where-Object { $_.cast_status -eq "needs_cast_decision" }).Count
if ([int]$manifest.uncast_speaker_count -ne $uncastCount) {
    throw "Uncast speaker count mismatch."
}

foreach ($speaker in $speakers) {
    $speakerLines = @($lines | Where-Object { $_.speaker -eq $speaker.speaker })
    $speakerWords = ($speakerLines | Measure-Object -Property word_count -Sum).Sum
    if ([int]$speaker.line_count -ne $speakerLines.Count) {
        throw "Speaker line count mismatch for $($speaker.speaker)."
    }
    if ([int]$speaker.word_count -ne [int]$speakerWords) {
        throw "Speaker word count mismatch for $($speaker.speaker)."
    }
}

foreach ($requiredText in @(
    "Act I VO Line Manifest",
    "recording/editing plan for full VO timing",
    "Dialogue lines are generated from Ink; do not duplicate confession text here.",
    "Confession VO remains keyed by `data/confessions.json` ids.",
    "Keep the accepted Litany/Registrar duel format.",
    "Speakers needing cast decision:"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I VO manifest report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ÃƒÂ¯Ã‚Â»Ã‚Â¿", "`t")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I VO manifest report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "Act I VO manifest report contains illegal control characters."
}

Write-Host "Act I VO line manifest validation passed: lines=$($lines.Count), speakers=$($speakers.Count), uncast=$uncastCount, vo=$($manifest.vo_line_count), stage=$($manifest.stage_direction_count)."
