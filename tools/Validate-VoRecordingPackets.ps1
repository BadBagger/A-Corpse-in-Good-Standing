$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-VoRecordingPackets.ps1"
$jsonPath = Join-Path $root "docs\vo\vo_recording_packets_index.json"
$csvPath = Join-Path $root "docs\vo\vo_recording_packets_index.csv"
$mdPath = Join-Path $root "docs\vo\vo_recording_packets_index.md"
$readyPacketDir = Join-Path $root "docs\vo\recording_packets\scratch_ready"
$blockedPacketDir = Join-Path $root "docs\vo\recording_packets\blocked_pending_cast_decision"
$cutRewritePacketDir = Join-Path $root "docs\vo\recording_packets\blocked_cut_or_rewrite"
$queuePath = Join-Path $root "docs\vo\vo_recording_queue.json"
$batchManifestPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$actIManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing VO recording packet exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "VO recording packet export failed."
}

foreach ($path in @($jsonPath, $csvPath, $mdPath, $readyPacketDir, $blockedPacketDir, $cutRewritePacketDir, $queuePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated VO recording packet artifact: $path"
    }
}

$index = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$queue = Get-Content -LiteralPath $queuePath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$readyFiles = @(Get-ChildItem -LiteralPath $readyPacketDir -Filter "*.md" -File)
$blockedFiles = @(Get-ChildItem -LiteralPath $blockedPacketDir -Filter "*.md" -File)
$cutRewriteFiles = @(Get-ChildItem -LiteralPath $cutRewritePacketDir -Filter "*.md" -File)
$expectedReadyBatches = [int]$queue.scratch_ready_batch_count
$expectedBlockedBatches = [int]$queue.blocked_batch_count
$expectedCutRewriteBatches = [int]$queue.cut_rewrite_blocked_batch_count
$expectedReadyLines = [int]$queue.scratch_ready_line_count
$expectedReadyWords = [int]$queue.scratch_ready_word_count
$expectedGeneratedFrom = @(
    "docs/vo/vo_recording_queue.json",
    "docs/vo/vo_recording_batches.json",
    "docs/vo/act_i_vo_line_manifest.json",
    "docs/vo/confession_vo_manifest.json"
)
$sourcePaths = @{
    "docs/vo/vo_recording_queue.json" = $queuePath
    "docs/vo/vo_recording_batches.json" = $batchManifestPath
    "docs/vo/act_i_vo_line_manifest.json" = $actIManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
}

foreach ($relativePath in $expectedGeneratedFrom) {
    if ($relativePath -notin @($index.generated_from | ForEach-Object { [string]$_ })) {
        throw "VO recording packet index generated_from missing source: $relativePath"
    }
    $actualSourceStamp = [string]$index.source_modified_utc.$relativePath
    $expectedSourceStamp = (Get-Item -LiteralPath $sourcePaths[$relativePath]).LastWriteTimeUtc.ToString("o")
    if ($actualSourceStamp -ne $expectedSourceStamp) {
        throw "VO recording packet index source_modified_utc is stale or inconsistent for $relativePath."
    }
}
if ([string]::IsNullOrWhiteSpace([string]$index.generated_at_utc)) {
    throw "VO recording packet index missing generated_at_utc freshness stamp."
}
try {
    $generatedAt = [datetime]::Parse([string]$index.generated_at_utc).ToUniversalTime()
    foreach ($relativePath in $expectedGeneratedFrom) {
        $sourceModified = [datetime]::Parse([string]$index.source_modified_utc.$relativePath).ToUniversalTime()
        if ($generatedAt -lt $sourceModified) {
            throw "VO recording packet index generated_at_utc predates source $relativePath."
        }
    }
} catch {
    throw "VO recording packet index freshness stamps must be parseable UTC datetimes and not predate sources."
}

if ([int]$index.packet_count -ne $expectedReadyBatches -or $rows.Count -ne $expectedReadyBatches -or $readyFiles.Count -ne $expectedReadyBatches) {
    throw "VO recording packets expected $expectedReadyBatches packet rows/files from queue, got json=$($index.packet_count), csv=$($rows.Count), files=$($readyFiles.Count)."
}
if ([int]$index.blocked_packet_count -ne 0 -or $blockedFiles.Count -ne 0) {
    throw "Blocked VO packet directory must stay empty."
}
if ([int]$index.cut_rewrite_packet_count -ne 0 -or $cutRewriteFiles.Count -ne 0) {
    throw "Cut/rewrite VO packet directory must stay empty."
}
if ([int]$index.blocked_queue_batch_count -ne $expectedBlockedBatches) {
    throw "VO recording packet index expected $expectedBlockedBatches blocked queue batches, got $($index.blocked_queue_batch_count)."
}
if ([int]$index.cut_rewrite_queue_batch_count -ne $expectedCutRewriteBatches) {
    throw "VO recording packet index expected $expectedCutRewriteBatches cut/rewrite queue batches, got $($index.cut_rewrite_queue_batch_count)."
}
if ([int]$index.line_count -ne $expectedReadyLines -or [int]$index.word_count -ne $expectedReadyWords) {
    throw "VO recording packet line/word counts drifted: lines=$($index.line_count), words=$($index.word_count)."
}

$seenPackets = @{}
foreach ($row in $rows) {
    if ($row.queue_status -ne "scratch_ready") {
        throw "VO recording packet row is not scratch-ready: $($row.batch_id)"
    }
    if ($seenPackets.ContainsKey($row.batch_id)) {
        throw "Duplicate VO recording packet row: $($row.batch_id)"
    }
    $seenPackets[$row.batch_id] = $true
    if ([int]$row.line_count -le 0 -or [int]$row.word_count -le 0) {
        throw "VO recording packet row has invalid counts: $($row.batch_id)"
    }
    if ([int]$row.source_line_count -ne [int]$row.line_count -or [int]$row.audio_path_count -ne [int]$row.line_count) {
        throw "VO recording packet row source/audio counts mismatch: $($row.batch_id)"
    }
    if ([int]$row.context_line_count -lt [int]$row.line_count) {
        throw "VO recording packet row context count should cover at least target lines: $($row.batch_id)"
    }
    $packetPath = Join-Path $root ($row.packet_path -replace "/", "\")
    if (-not (Test-Path -LiteralPath $packetPath)) {
        throw "VO recording packet row references missing packet file: $($row.packet_path)"
    }
    $packet = Get-Content -LiteralPath $packetPath -Raw
    foreach ($requiredText in @(
        "VO Recording Packet - $($row.batch_id)",
        "Queue status: scratch_ready",
        "Shipping status: scratch_only_not_shipping_audio",
        "## Target Lines",
        "## Context Lines",
        "Generate this as one batch in source order",
        "Scratch timing only",
        "Keep the accepted Litany/Registrar duel format."
    )) {
        if ($packet -notmatch [regex]::Escape($requiredText)) {
            throw "VO recording packet $($row.batch_id) missing required text: $requiredText"
        }
    }
    if ($packet -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
        throw "VO recording packet contains illegal control characters: $($row.batch_id)"
    }
}

foreach ($blockedRow in @($queue.queues.blocked_pending_cast_decision + $queue.queues.blocked_cut_or_rewrite)) {
    if (@($rows | Where-Object { $_.batch_id -eq $blockedRow.batch_id }).Count -ne 0) {
        throw "Blocked VO batch should not have scratch-ready recording packet: $($blockedRow.batch_id)"
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "VO Recording Packets Index",
    "Generated at UTC: $($index.generated_at_utc)",
    "Source modified UTC:",
    "docs/vo/vo_recording_queue.json: $($index.source_modified_utc.'docs/vo/vo_recording_queue.json')",
    "docs/vo/vo_recording_batches.json: $($index.source_modified_utc.'docs/vo/vo_recording_batches.json')",
    "docs/vo/act_i_vo_line_manifest.json: $($index.source_modified_utc.'docs/vo/act_i_vo_line_manifest.json')",
    "docs/vo/confession_vo_manifest.json: $($index.source_modified_utc.'docs/vo/confession_vo_manifest.json')",
    "Packet count: $expectedReadyBatches",
    "Blocked packet count: 0",
    "Blocked queue batch count: $expectedBlockedBatches",
    "Cut/rewrite packet count: 0",
    "Cut/rewrite queue batch count: $expectedCutRewriteBatches",
    "Lines in packets: $expectedReadyLines",
    "Words in packets: $expectedReadyWords",
    "Only scratch-ready batches get recording packets.",
    "Blocked pending-cast batches must not get packet files.",
    "Cut/rewrite blocked batches must not get packet files.",
    "Packets preserve source order and context lines.",
    "Scratch packets are not shipping audio approval.",
    "Litany text is pulled from the confession VO manifest generated from data/confessions.json.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "VO recording packet index report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "VO recording packet index report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "VO recording packet index report contains illegal control characters."
}

Write-Host "VO recording packets validation passed: packets=$($index.packet_count), blockedPackets=$($index.blocked_packet_count), lines=$($index.line_count), words=$($index.word_count)."
