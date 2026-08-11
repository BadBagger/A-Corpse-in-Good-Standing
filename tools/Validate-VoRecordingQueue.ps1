$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-VoRecordingQueue.ps1"
$jsonPath = Join-Path $root "docs\vo\vo_recording_queue.json"
$csvPath = Join-Path $root "docs\vo\vo_recording_queue.csv"
$mdPath = Join-Path $root "docs\vo\vo_recording_queue.md"
$decisionJsonPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"
$batchManifestPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$castPlanPath = Join-Path $root "docs\vo\vo_cast_plan.json"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing VO recording queue exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "VO recording queue export failed."
}

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated VO recording queue artifact: $path"
    }
}

$queue = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$readyRows = @($rows | Where-Object { $_.queue_status -eq "scratch_ready" })
$blockedRows = @($rows | Where-Object { $_.queue_status -eq "blocked_pending_cast_decision" })
$cutRewriteRows = @($rows | Where-Object { $_.queue_status -eq "blocked_cut_or_rewrite" })
$hasAppliedMinorSpeakerDecisions = Test-Path -LiteralPath $decisionJsonPath
$expectedGeneratedFrom = @(
    "docs/vo/vo_recording_batches.json",
    "docs/vo/vo_cast_plan.json"
)
$sourcePaths = @{
    "docs/vo/vo_recording_batches.json" = $batchManifestPath
    "docs/vo/vo_cast_plan.json" = $castPlanPath
}
$expectedReadyBatchCount = $readyRows.Count
$expectedBlockedBatchCount = $blockedRows.Count
$expectedCutRewriteBatchCount = $cutRewriteRows.Count
$expectedReadyLineCount = [int]((@($readyRows) | Measure-Object line_count -Sum).Sum)
$expectedBlockedLineCount = [int]((@($blockedRows) | Measure-Object line_count -Sum).Sum)
$expectedReadyWordCount = [int]((@($readyRows) | Measure-Object word_count -Sum).Sum)
$expectedBlockedWordCount = [int]((@($blockedRows) | Measure-Object word_count -Sum).Sum)

foreach ($relativePath in $expectedGeneratedFrom) {
    if ($relativePath -notin @($queue.generated_from | ForEach-Object { [string]$_ })) {
        throw "VO recording queue generated_from missing source: $relativePath"
    }
    $actualSourceStamp = [string]$queue.source_modified_utc.PSObject.Properties[$relativePath].Value
    $expectedSourceStamp = (Get-Item -LiteralPath $sourcePaths[$relativePath]).LastWriteTimeUtc.ToString("o")
    if ($actualSourceStamp -ne $expectedSourceStamp) {
        throw "VO recording queue source_modified_utc is stale or inconsistent for $relativePath."
    }
}
if ([string]::IsNullOrWhiteSpace([string]$queue.generated_at_utc)) {
    throw "VO recording queue missing generated_at_utc freshness stamp."
}
try {
    $generatedAt = [datetime]::Parse([string]$queue.generated_at_utc).ToUniversalTime()
    foreach ($relativePath in $expectedGeneratedFrom) {
        $sourceModified = [datetime]::Parse([string]$queue.source_modified_utc.PSObject.Properties[$relativePath].Value).ToUniversalTime()
        if ($generatedAt -lt $sourceModified) {
            throw "VO recording queue generated_at_utc predates source $relativePath."
        }
    }
} catch {
    throw "VO recording queue freshness stamps must be parseable UTC datetimes and not predate sources."
}

if ([int]$queue.batch_count -ne 136 -or $rows.Count -ne 136) {
    throw "VO recording queue expected 136 batches, got json=$($queue.batch_count), csv=$($rows.Count)."
}
if ([int]$queue.scratch_ready_batch_count -ne $expectedReadyBatchCount) {
    throw "VO recording queue scratch-ready batch count mismatch: json=$($queue.scratch_ready_batch_count), rows=$expectedReadyBatchCount."
}
if ([int]$queue.blocked_batch_count -ne $expectedBlockedBatchCount) {
    throw "VO recording queue blocked batch count mismatch: json=$($queue.blocked_batch_count), rows=$expectedBlockedBatchCount."
}
if ([int]$queue.cut_rewrite_blocked_batch_count -ne $expectedCutRewriteBatchCount) {
    throw "VO recording queue cut/rewrite batch count mismatch: json=$($queue.cut_rewrite_blocked_batch_count), rows=$expectedCutRewriteBatchCount."
}
if ([int]$queue.scratch_ready_line_count -ne $expectedReadyLineCount -or [int]$queue.blocked_line_count -ne $expectedBlockedLineCount) {
    throw "VO recording queue line split drifted: ready=$($queue.scratch_ready_line_count), blocked=$($queue.blocked_line_count)."
}
if ([int]$queue.scratch_ready_word_count -ne $expectedReadyWordCount -or [int]$queue.blocked_word_count -ne $expectedBlockedWordCount) {
    throw "VO recording queue word split drifted: ready=$($queue.scratch_ready_word_count), blocked=$($queue.blocked_word_count)."
}
if ([int]$queue.total_line_count -ne 652 -or [int]$queue.total_word_count -ne 5206) {
    throw "VO recording queue total line/word counts drifted."
}
if ($queue.shipping_status -ne "scratch_only_not_shipping_audio") {
    throw "VO recording queue must not imply shipping audio: $($queue.shipping_status)"
}

$requiredColumns = @(
    "batch_id",
    "queue_status",
    "batch_type",
    "act",
    "speaker",
    "scratch_voice",
    "scratch_voice_id",
    "cast_status",
    "line_count",
    "word_count",
    "first_line_id",
    "audio_path_count",
    "generation_rule",
    "block_reason"
)

$seenBatchIds = @{}
foreach ($row in $rows) {
    foreach ($column in $requiredColumns) {
        if (-not ($row.PSObject.Properties.Name -contains $column)) {
            throw "VO recording queue CSV missing column: $column"
        }
    }
    if ($seenBatchIds.ContainsKey($row.batch_id)) {
        throw "Duplicate VO recording queue batch id: $($row.batch_id)"
    }
    $seenBatchIds[$row.batch_id] = $true
    if ($row.queue_status -notin @("scratch_ready", "blocked_pending_cast_decision", "blocked_cut_or_rewrite")) {
        throw "Invalid VO recording queue status '$($row.queue_status)' on $($row.batch_id)."
    }
    if ($row.queue_status -eq "scratch_ready") {
        if ($row.cast_status -ne "scratch_cast") {
            throw "Scratch-ready queue row is not scratch-cast: $($row.batch_id)"
        }
        if ([string]::IsNullOrWhiteSpace($row.scratch_voice) -or [string]::IsNullOrWhiteSpace($row.scratch_voice_id)) {
            throw "Scratch-ready queue row missing scratch voice: $($row.batch_id)"
        }
        if (-not [string]::IsNullOrWhiteSpace($row.block_reason)) {
            throw "Scratch-ready queue row should not have block reason: $($row.batch_id)"
        }
    }
    if ($row.queue_status -eq "blocked_pending_cast_decision") {
        if ($row.cast_status -ne "needs_cast_decision") {
            throw "Blocked queue row must need cast decision: $($row.batch_id)"
        }
        if ([string]::IsNullOrWhiteSpace($row.block_reason)) {
            throw "Blocked queue row missing block reason: $($row.batch_id)"
        }
    }
    if ($row.queue_status -eq "blocked_cut_or_rewrite") {
        if ($row.cast_status -ne "blocked_cut_or_rewrite") {
            throw "Cut/rewrite queue row must have blocked_cut_or_rewrite cast status: $($row.batch_id)"
        }
        if ($row.block_reason -notmatch "cut or rewrite") {
            throw "Cut/rewrite queue row missing script block reason: $($row.batch_id)"
        }
    }
    if ([int]$row.line_count -le 0 -or [int]$row.word_count -le 0 -or [int]$row.audio_path_count -ne [int]$row.line_count) {
        throw "VO recording queue row has invalid counts: $($row.batch_id)"
    }
    if ($row.generation_rule -notmatch "scene order|confession") {
        throw "VO recording queue row missing useful generation rule: $($row.batch_id)"
    }
}

if (-not $hasAppliedMinorSpeakerDecisions) {
    if ([int]$queue.scratch_ready_batch_count -ne 119 -or [int]$queue.blocked_batch_count -ne 17 -or [int]$queue.cut_rewrite_blocked_batch_count -ne 0) {
        throw "Baseline VO recording queue expected 119 ready, 17 pending-cast, 0 cut/rewrite batches."
    }
    if ([int]$queue.scratch_ready_line_count -ne 600 -or [int]$queue.blocked_line_count -ne 52) {
        throw "Baseline VO recording queue expected 600 ready lines and 52 blocked lines."
    }
    if ([int]$queue.scratch_ready_word_count -ne 4929 -or [int]$queue.blocked_word_count -ne 277) {
        throw "Baseline VO recording queue expected 4929 ready words and 277 blocked words."
    }
    foreach ($speaker in @("ADELA", "BOOT_SELLER", "BOY", "CLERK", "MAN", "MARIN", "MONGER", "WOMAN")) {
        if (@($readyRows | Where-Object { $_.speaker -eq $speaker }).Count -ne 0) {
            throw "Pending minor speaker appears in scratch-ready queue: $speaker"
        }
        if (@($blockedRows | Where-Object { $_.speaker -eq $speaker }).Count -lt 1) {
            throw "Pending minor speaker missing from blocked queue: $speaker"
        }
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "VO Recording Queue",
    "Generated at UTC: $($queue.generated_at_utc)",
    "Source modified UTC:",
    "docs/vo/vo_recording_batches.json: $($queue.source_modified_utc.PSObject.Properties['docs/vo/vo_recording_batches.json'].Value)",
    "docs/vo/vo_cast_plan.json: $($queue.source_modified_utc.PSObject.Properties['docs/vo/vo_cast_plan.json'].Value)",
    "Scratch-ready batches: $expectedReadyBatchCount",
    "Blocked batches: $expectedBlockedBatchCount",
    "Cut/rewrite blocked batches: $expectedCutRewriteBatchCount",
    "Scratch-ready lines: $expectedReadyLineCount",
    "Blocked lines: $expectedBlockedLineCount",
    "Only scratch_ready batches may be generated for timing tests.",
    "blocked_pending_cast_decision batches must not be generated.",
    "blocked_cut_or_rewrite batches must not be generated until script changes are made.",
    "Do not generate VO line-by-line in isolation.",
    "Litany batches keep confession and elaboration lines adjacent.",
    "Scratch output is not shipping audio and remains blocked by VO commercial readiness.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "VO recording queue report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "VO recording queue report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "VO recording queue report contains illegal control characters."
}

Write-Host "VO recording queue validation passed: ready=$($queue.scratch_ready_batch_count) batches/$($queue.scratch_ready_line_count) lines, blocked=$($queue.blocked_batch_count) batches/$($queue.blocked_line_count) lines."
