$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-VoRecordingBatches.ps1"
$actManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$minorSpeakerDecisionPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"
$jsonPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$csvPath = Join-Path $root "docs\vo\vo_recording_batches.csv"
$mdPath = Join-Path $root "docs\vo\vo_recording_batches.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing VO recording batch exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "VO recording batch export failed."
}

foreach ($path in @($actManifestPath, $confessionManifestPath, $jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO recording batch input/artifact: $path"
    }
}

$actManifest = Get-Content -LiteralPath $actManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$confessionManifest = Get-Content -LiteralPath $confessionManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$batchManifest = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$csvRows = @(Import-Csv -LiteralPath $csvPath)
$report = Get-Content -LiteralPath $mdPath -Raw
$expectedGeneratedFrom = @(
    "docs/vo/act_i_vo_line_manifest.json",
    "docs/vo/confession_vo_manifest.json"
)
$sourcePaths = @{
    "docs/vo/act_i_vo_line_manifest.json" = $actManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
}

foreach ($relativePath in $expectedGeneratedFrom) {
    if ($relativePath -notin @($batchManifest.generated_from | ForEach-Object { [string]$_ })) {
        throw "VO recording batch manifest generated_from missing source: $relativePath"
    }
    $actualSourceStamp = [string]$batchManifest.source_modified_utc.PSObject.Properties[$relativePath].Value
    $expectedSourceStamp = (Get-Item -LiteralPath $sourcePaths[$relativePath]).LastWriteTimeUtc.ToString("o")
    if ($actualSourceStamp -ne $expectedSourceStamp) {
        throw "VO recording batch manifest source_modified_utc is stale or inconsistent for $relativePath."
    }
}
$hasMinorDecisionFile = Test-Path -LiteralPath $minorSpeakerDecisionPath
if ($hasMinorDecisionFile) {
    if ([string]$batchManifest.minor_speaker_decisions_source_status -ne "present") {
        throw "VO recording batch manifest must mark minor-speaker decision source present when the decision file exists."
    }
    if ([string]$batchManifest.minor_speaker_decisions_source -ne "docs/vo/vo_minor_speaker_decisions.json") {
        throw "VO recording batch manifest has wrong minor-speaker decision source."
    }
    $actualDecisionStamp = [string]$batchManifest.source_modified_utc.PSObject.Properties["docs/vo/vo_minor_speaker_decisions.json"].Value
    $expectedDecisionStamp = (Get-Item -LiteralPath $minorSpeakerDecisionPath).LastWriteTimeUtc.ToString("o")
    if ($actualDecisionStamp -ne $expectedDecisionStamp) {
        throw "VO recording batch manifest source_modified_utc is stale or inconsistent for minor-speaker decisions."
    }
} else {
    if ([string]$batchManifest.minor_speaker_decisions_source_status -ne "absent") {
        throw "VO recording batch manifest must mark minor-speaker decision source absent when no decision file exists."
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$batchManifest.minor_speaker_decisions_source)) {
        throw "VO recording batch manifest must not name a minor-speaker decision source when no decision file exists."
    }
}
if ([string]::IsNullOrWhiteSpace([string]$batchManifest.generated_at_utc)) {
    throw "VO recording batch manifest missing generated_at_utc freshness stamp."
}
try {
    $generatedAt = [datetime]::Parse([string]$batchManifest.generated_at_utc).ToUniversalTime()
    foreach ($relativePath in $expectedGeneratedFrom) {
        $sourceModified = [datetime]::Parse([string]$batchManifest.source_modified_utc.PSObject.Properties[$relativePath].Value).ToUniversalTime()
        if ($generatedAt -lt $sourceModified) {
            throw "VO recording batch manifest generated_at_utc predates source $relativePath."
        }
    }
    if ($hasMinorDecisionFile) {
        $decisionModified = [datetime]::Parse([string]$batchManifest.source_modified_utc.PSObject.Properties["docs/vo/vo_minor_speaker_decisions.json"].Value).ToUniversalTime()
        if ($generatedAt -lt $decisionModified) {
            throw "VO recording batch manifest generated_at_utc predates minor-speaker decision source."
        }
    }
} catch {
    throw "VO recording batch manifest freshness stamps must be parseable UTC datetimes and not predate sources."
}

$actVoLines = @($actManifest.lines | Where-Object { $_.recording_scope -eq "vo_line" })
$stageLines = @($actManifest.lines | Where-Object { $_.recording_scope -eq "stage_direction_review" })
$confessionLines = @($confessionManifest.lines | ForEach-Object { $_ })
$batches = @($batchManifest.batches | ForEach-Object { $_ })

if ($batches.Count -lt 80) {
    throw "Expected at least 80 VO recording batches, got $($batches.Count)."
}
if ($csvRows.Count -ne $batches.Count) {
    throw "CSV batch row count $($csvRows.Count) does not match JSON batch count $($batches.Count)."
}
if ([int]$batchManifest.batch_count -ne $batches.Count) {
    throw "VO batch manifest batch_count does not match batches array."
}

$expectedLineIds = @{}
foreach ($line in @($actVoLines + $confessionLines)) {
    $expectedLineIds[[string]$line.line_id] = $false
}
$stageLineIds = @{}
foreach ($line in $stageLines) {
    $stageLineIds[[string]$line.line_id] = $true
}

$batchIds = @{}
foreach ($batch in $batches) {
    foreach ($field in @("batch_id", "batch_type", "speaker", "source_manifest", "line_count", "word_count", "source_line_ids", "audio_paths", "recording_status", "generation_rule", "notes")) {
        if ($null -eq $batch.$field -or [string]::IsNullOrWhiteSpace([string]$batch.$field)) {
            throw "VO batch has empty required field '$field': $($batch | ConvertTo-Json -Compress)"
        }
    }
    if ($batchIds.ContainsKey($batch.batch_id)) {
        throw "Duplicate VO batch id: $($batch.batch_id)"
    }
    $batchIds[$batch.batch_id] = $true

    if ($batch.batch_type -notin @("scene_speaker_run", "litany_category_run")) {
        throw "Invalid VO batch type: $($batch.batch_type)"
    }
    if ($batch.recording_status -ne "unrecorded") {
        throw "VO recording batches should start unrecorded, got $($batch.recording_status) on $($batch.batch_id)."
    }
    if ($batch.generation_rule -notmatch "Generate as") {
        throw "VO batch missing concrete generation rule: $($batch.batch_id)"
    }
    if ([int]$batch.line_count -ne @($batch.source_line_ids).Count) {
        throw "VO batch line_count/source_line_ids mismatch: $($batch.batch_id)"
    }
    if ([int]$batch.line_count -ne @($batch.audio_paths).Count) {
        throw "VO batch line_count/audio_paths mismatch: $($batch.batch_id)"
    }
    if ([int]$batch.word_count -le 0) {
        throw "VO batch word_count must be positive: $($batch.batch_id)"
    }

    foreach ($lineId in @($batch.source_line_ids)) {
        $lineKey = [string]$lineId
        if (-not $expectedLineIds.ContainsKey($lineKey)) {
            throw "VO batch references unknown or non-recordable line id: $lineKey"
        }
        if ($expectedLineIds[$lineKey]) {
            throw "VO line appears in more than one recording batch: $lineKey"
        }
        $expectedLineIds[$lineKey] = $true
    }

    foreach ($contextId in @($batch.context_line_ids)) {
        $contextKey = [string]$contextId
        if (-not $expectedLineIds.ContainsKey($contextKey) -and -not $stageLineIds.ContainsKey($contextKey)) {
            throw "VO batch references unknown context line id: $contextKey"
        }
    }

    if ($batch.batch_type -eq "scene_speaker_run") {
        if ([string]::IsNullOrWhiteSpace([string]$batch.knot)) {
            throw "Scene VO batch must have knot: $($batch.batch_id)"
        }
        if ($batch.notes -notmatch "disconnected fragments") {
            throw "Scene VO batch must warn against disconnected fragments: $($batch.batch_id)"
        }
        if ($batch.source_manifest -ne "docs/vo/act_i_vo_line_manifest.json") {
            throw "Scene VO batch has wrong source manifest: $($batch.batch_id)"
        }
    } else {
        if ([string]::IsNullOrWhiteSpace([string]$batch.category) -or [string]::IsNullOrWhiteSpace([string]$batch.act_available)) {
            throw "Litany VO batch must have category and act_available: $($batch.batch_id)"
        }
        if ($batch.generation_rule -notmatch "confession immediately followed by its elaboration") {
            throw "Litany VO batch must preserve confession/elaboration adjacency: $($batch.batch_id)"
        }
        if ($batch.source_manifest -ne "docs/vo/confession_vo_manifest.json") {
            throw "Litany VO batch has wrong source manifest: $($batch.batch_id)"
        }
    }
}

$missing = @($expectedLineIds.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key)
if ($missing.Count -gt 0) {
    throw "VO recording batches did not cover all recordable lines: $($missing -join ', ')"
}

$typeSummary = @($batchManifest.types)
$sceneSummary = @($typeSummary | Where-Object { $_.batch_type -eq "scene_speaker_run" })[0]
$litanySummary = @($typeSummary | Where-Object { $_.batch_type -eq "litany_category_run" })[0]
if ($null -eq $sceneSummary -or [int]$sceneSummary.line_count -ne $actVoLines.Count) {
    throw "Scene VO batch summary must cover all Act I recordable VO lines."
}
if ($null -eq $litanySummary -or [int]$litanySummary.line_count -ne $confessionLines.Count) {
    throw "Litany VO batch summary must cover all confession VO lines."
}

foreach ($requiredText in @(
    "VO Recording Batches",
    "Generated at UTC: $($batchManifest.generated_at_utc)",
    "Source modified UTC:",
    "docs/vo/act_i_vo_line_manifest.json: $($batchManifest.source_modified_utc.PSObject.Properties['docs/vo/act_i_vo_line_manifest.json'].Value)",
    "docs/vo/confession_vo_manifest.json: $($batchManifest.source_modified_utc.PSObject.Properties['docs/vo/confession_vo_manifest.json'].Value)",
    "docs/vo/vo_minor_speaker_decisions.json: $($batchManifest.minor_speaker_decisions_source_status)",
    "Do not generate VO line-by-line in isolation.",
    "Scene VO batches are speaker runs grouped by Ink knot and kept in source order.",
    "Litany batches keep each confession immediately followed by its elaboration.",
    "Scratch voices are timing/casting references only until commercial licensing is verified.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "VO recording batch report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ÃƒÂ¯Ã‚Â»Ã‚Â¿", "`t")) {
    if ($report.Contains($forbiddenText)) {
        throw "VO recording batch report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "VO recording batch report contains illegal control characters."
}

Write-Host "VO recording batch validation passed: batches=$($batches.Count), lines=$($batchManifest.line_count), words=$($batchManifest.word_count), sceneLines=$($sceneSummary.line_count), litanyLines=$($litanySummary.line_count)."
