$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ConfessionVoManifest.ps1"
$confessionPath = Join-Path $root "data\confessions.json"
$jsonPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$csvPath = Join-Path $root "docs\vo\confession_vo_manifest.csv"
$mdPath = Join-Path $root "docs\vo\confession_vo_manifest.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing confession VO manifest exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Confession VO manifest export failed."
}

foreach ($path in @($confessionPath, $jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing confession VO manifest input/artifact: $path"
    }
}

$confessionData = Get-Content -LiteralPath $confessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
$confessions = @($confessionData | ForEach-Object { $_ })
$manifest = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$report = Get-Content -LiteralPath $mdPath -Raw
$lines = @($manifest.lines)

if ($confessions.Count -lt 60) {
    throw "Expected at least 60 confessions, got $($confessions.Count)."
}
if ([int]$manifest.confession_count -ne $confessions.Count) {
    throw "Manifest confession_count does not match data/confessions.json."
}
if ($lines.Count -ne ($confessions.Count * 2)) {
    throw "Expected exactly two VO lines per confession, got $($lines.Count) for $($confessions.Count) confessions."
}
if ($rows.Count -ne $lines.Count) {
    throw "CSV row count $($rows.Count) does not match JSON line count $($lines.Count)."
}
if ([int]$manifest.confession_line_count -ne $confessions.Count -or [int]$manifest.elaboration_line_count -ne $confessions.Count) {
    throw "Manifest must contain one confession line and one elaboration line for each confession."
}

$confessionsById = @{}
foreach ($confession in $confessions) {
    $confessionsById[[string]$confession.id] = $confession
}

$ids = @{}
$seenParts = @{}
foreach ($line in $lines) {
    foreach ($field in @("line_id", "confession_id", "part", "speaker", "text", "word_count", "category", "weight", "act_available", "acquisition", "source_file", "source_ref", "audio_path", "recording_status")) {
        if ($null -eq $line.$field -or [string]::IsNullOrWhiteSpace([string]$line.$field)) {
            throw "Confession VO line has empty required field '$field': $($line | ConvertTo-Json -Compress)"
        }
    }
    if ($ids.ContainsKey($line.line_id)) {
        throw "Duplicate confession VO line id: $($line.line_id)"
    }
    $ids[$line.line_id] = $true

    if (-not $confessionsById.ContainsKey([string]$line.confession_id)) {
        throw "Confession VO line references unknown confession: $($line.confession_id)"
    }
    if ($line.part -notin @("confession", "elaboration")) {
        throw "Invalid confession VO part on $($line.line_id): $($line.part)"
    }
    if ($line.speaker -ne "CORVIN" -or $line.character -ne "Corvin Vale") {
        throw "Confession VO line must be Corvin: $($line.line_id)"
    }
    if ($line.source_file -ne "data/confessions.json") {
        throw "Confession VO source must be data/confessions.json: $($line.line_id)"
    }
    if ($line.recording_status -ne "unrecorded") {
        throw "Confession VO manifest should start unrecorded, got $($line.recording_status) on $($line.line_id)."
    }

    $confession = $confessionsById[[string]$line.confession_id]
    $expectedText = if ($line.part -eq "confession") { [string]$confession.text } else { [string]$confession.elaboration }
    $expectedAudio = if ($line.part -eq "confession") { "vo/confessions/$($line.confession_id).mp3" } else { "vo/confessions/$($line.confession_id)_elaboration.mp3" }
    if ([string]$line.text -ne $expectedText) {
        throw "Confession VO text drifted from data/confessions.json for $($line.line_id)."
    }
    if ([string]$line.audio_path -ne $expectedAudio) {
        throw "Confession VO audio path mismatch for $($line.line_id): $($line.audio_path)"
    }
    if ([int]$line.word_count -le 0) {
        throw "Confession VO word_count must be positive: $($line.line_id)"
    }
    if ([int]$line.act_available -ne [int]$confession.act_available -or [string]$line.category -ne [string]$confession.category -or [int]$line.weight -ne [int]$confession.weight) {
        throw "Confession VO metadata drifted from data/confessions.json for $($line.line_id)."
    }

    $partKey = "$($line.confession_id)|$($line.part)"
    if ($seenParts.ContainsKey($partKey)) {
        throw "Duplicate confession VO part: $partKey"
    }
    $seenParts[$partKey] = $true
}

foreach ($confession in $confessions) {
    foreach ($part in @("confession", "elaboration")) {
        $partKey = "$($confession.id)|$part"
        if (-not $seenParts.ContainsKey($partKey)) {
            throw "Missing confession VO part: $partKey"
        }
    }
}

$betrayalConfessions = @($confessions | Where-Object { $_.category -eq "BETRAYAL" })
$betrayalLines = @($lines | Where-Object { $_.category -eq "BETRAYAL" })
if ($betrayalConfessions.Count -ne 4 -or $betrayalLines.Count -ne 8) {
    throw "Confession VO must preserve exactly four BETRAYAL confessions / eight BETRAYAL VO lines."
}

foreach ($requiredText in @(
    "Confession VO Manifest",
    'Generated by `tools/Export-ConfessionVoManifest.ps1` from `data/confessions.json`.',
    "One confession line and one elaboration line are required for every confession.",
    "Audio paths must stay keyed by confession id",
    'Generated text comes from `data/confessions.json`; Ink references confession ids only.',
    "Keep the accepted Litany/Registrar duel format and global spend rules."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Confession VO manifest report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ÃƒÂ¯Ã‚Â»Ã‚Â¿", "`t")) {
    if ($report.Contains($forbiddenText)) {
        throw "Confession VO manifest report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "Confession VO manifest report contains illegal control characters."
}

Write-Host "Confession VO manifest validation passed: confessions=$($confessions.Count), lines=$($lines.Count), words=$($manifest.word_count), betrayalLines=$($betrayalLines.Count)."
