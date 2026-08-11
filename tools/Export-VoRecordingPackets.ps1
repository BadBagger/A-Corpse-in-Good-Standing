$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$queuePath = Join-Path $root "docs\vo\vo_recording_queue.json"
$batchManifestPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$actIManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$packetRoot = Join-Path $root "docs\vo\recording_packets"
$readyPacketDir = Join-Path $packetRoot "scratch_ready"
$blockedPacketDir = Join-Path $packetRoot "blocked_pending_cast_decision"
$cutRewritePacketDir = Join-Path $packetRoot "blocked_cut_or_rewrite"
$jsonPath = Join-Path $root "docs\vo\vo_recording_packets_index.json"
$csvPath = Join-Path $root "docs\vo\vo_recording_packets_index.csv"
$mdPath = Join-Path $root "docs\vo\vo_recording_packets_index.md"

foreach ($path in @($queuePath, $batchManifestPath, $actIManifestPath, $confessionManifestPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO recording packet input: $path"
    }
}

$inputPaths = [ordered]@{
    "docs/vo/vo_recording_queue.json" = $queuePath
    "docs/vo/vo_recording_batches.json" = $batchManifestPath
    "docs/vo/act_i_vo_line_manifest.json" = $actIManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
}
$sourceModifiedUtc = [ordered]@{}
foreach ($entry in $inputPaths.GetEnumerator()) {
    $sourceModifiedUtc[$entry.Key] = (Get-Item -LiteralPath $entry.Value).LastWriteTimeUtc.ToString("o")
}
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

$queue = Get-Content -LiteralPath $queuePath -Raw | ConvertFrom-Json
$batchManifest = Get-Content -LiteralPath $batchManifestPath -Raw | ConvertFrom-Json
$actIManifest = Get-Content -LiteralPath $actIManifestPath -Raw | ConvertFrom-Json
$confessionManifest = Get-Content -LiteralPath $confessionManifestPath -Raw | ConvertFrom-Json

$lineById = @{}
foreach ($line in @($actIManifest.lines)) {
    $lineById[[string]$line.line_id] = $line
}
foreach ($line in @($confessionManifest.lines)) {
    $lineById[[string]$line.line_id] = $line
}

$batchById = @{}
foreach ($batch in @($batchManifest.batches)) {
    $batchById[[string]$batch.batch_id] = $batch
}

foreach ($dir in @($packetRoot, $readyPacketDir, $blockedPacketDir, $cutRewritePacketDir)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

$resolvedReadyDir = (Resolve-Path -LiteralPath $readyPacketDir).Path
$resolvedBlockedDir = (Resolve-Path -LiteralPath $blockedPacketDir).Path
$resolvedCutRewriteDir = (Resolve-Path -LiteralPath $cutRewritePacketDir).Path
$resolvedPacketRoot = (Resolve-Path -LiteralPath $packetRoot).Path
if (-not $resolvedReadyDir.StartsWith($resolvedPacketRoot) -or -not $resolvedBlockedDir.StartsWith($resolvedPacketRoot) -or -not $resolvedCutRewriteDir.StartsWith($resolvedPacketRoot)) {
    throw "Refusing to clean VO packet directories outside packet root."
}
Get-ChildItem -LiteralPath $readyPacketDir -Filter "*.md" -File | Remove-Item -Force
Get-ChildItem -LiteralPath $blockedPacketDir -Filter "*.md" -File | Remove-Item -Force
Get-ChildItem -LiteralPath $cutRewritePacketDir -Filter "*.md" -File | Remove-Item -Force

$readyRows = @($queue.queues.scratch_ready)
$blockedRows = @($queue.queues.blocked_pending_cast_decision)
$cutRewriteRows = @($queue.queues.blocked_cut_or_rewrite)
$packetRows = @()

foreach ($row in $readyRows) {
    $batchId = [string]$row.batch_id
    if (-not $batchById.ContainsKey($batchId)) {
        throw "VO recording packet queue references unknown batch: $batchId"
    }
    $batch = $batchById[$batchId]
    $packetPath = Join-Path $readyPacketDir "$batchId.md"
    $relativePacketPath = "docs/vo/recording_packets/scratch_ready/$batchId.md"
    $sourceLineIds = @($batch.source_line_ids | ForEach-Object { [string]$_ })
    $contextLineIds = @($batch.context_line_ids | ForEach-Object { [string]$_ })
    $audioPaths = @($batch.audio_paths | ForEach-Object { [string]$_ })

    $packetLines = @(
        "# VO Recording Packet - $batchId",
        "",
        "Queue status: scratch_ready",
        "Shipping status: scratch_only_not_shipping_audio",
        "Batch type: $($batch.batch_type)",
        "Act: $($batch.act)",
        "Speaker: $($batch.speaker)",
        "Scratch voice: $($batch.scratch_voice) / $($batch.scratch_voice_id)",
        "Cast status: $($batch.cast_status)",
        "Location: $($batch.location)",
        "Knot: $($batch.knot)",
        "Category: $($batch.category)",
        "Line count: $($batch.line_count)",
        "Word count: $($batch.word_count)",
        "",
        "Generation rule: $($batch.generation_rule)",
        "Notes: $($batch.notes)",
        "",
        "Rule locks:",
        "- Generate this as one batch in source order, not as disconnected one-line fragments.",
        "- Use this packet for scratch timing only; it is not shipping audio approval.",
        "- Respect the listed audio paths exactly.",
        "- Keep the accepted Litany/Registrar duel format.",
        "",
        "## Target Lines",
        "",
        "| Line ID | Source | Audio path | Text |",
        "|---|---|---|---|"
    )

    for ($i = 0; $i -lt $sourceLineIds.Count; $i++) {
        $lineId = $sourceLineIds[$i]
        if (-not $lineById.ContainsKey($lineId)) {
            throw "VO recording packet references unknown line: $lineId"
        }
        $line = $lineById[$lineId]
        $audioPath = if ($i -lt $audioPaths.Count) { $audioPaths[$i] } else { "" }
        $text = ([string]$line.text).Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
        $packetLines += "| $lineId | $($line.source_ref) | $audioPath | $text |"
    }

    $packetLines += ""
    $packetLines += "## Context Lines"
    $packetLines += ""
    $packetLines += "| Line ID | Speaker | Text |"
    $packetLines += "|---|---|---|"
    foreach ($lineId in $contextLineIds) {
        if (-not $lineById.ContainsKey($lineId)) {
            throw "VO recording packet references unknown context line: $lineId"
        }
        $line = $lineById[$lineId]
        $text = ([string]$line.text).Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
        $packetLines += "| $lineId | $($line.speaker) | $text |"
    }

    Set-Content -LiteralPath $packetPath -Value $packetLines -Encoding UTF8

    $packetRows += [pscustomobject][ordered]@{
        batch_id = $batchId
        packet_path = $relativePacketPath
        queue_status = "scratch_ready"
        batch_type = [string]$batch.batch_type
        speaker = [string]$batch.speaker
        scratch_voice = [string]$batch.scratch_voice
        scratch_voice_id = [string]$batch.scratch_voice_id
        line_count = [int]$batch.line_count
        word_count = [int]$batch.word_count
        source_line_count = $sourceLineIds.Count
        context_line_count = $contextLineIds.Count
        audio_path_count = $audioPaths.Count
    }
}

$index = [ordered]@{
    generated_from = @(
        "docs/vo/vo_recording_queue.json",
        "docs/vo/vo_recording_batches.json",
        "docs/vo/act_i_vo_line_manifest.json",
        "docs/vo/confession_vo_manifest.json"
    )
    generated_at_utc = $generatedAtUtc
    source_modified_utc = $sourceModifiedUtc
    purpose = "Per-batch scratch VO recording packet index. Only scratch-ready batches get packet files."
    packet_directory = "docs/vo/recording_packets/scratch_ready"
    blocked_packet_directory = "docs/vo/recording_packets/blocked_pending_cast_decision"
    cut_rewrite_packet_directory = "docs/vo/recording_packets/blocked_cut_or_rewrite"
    packet_count = $packetRows.Count
    blocked_packet_count = 0
    blocked_queue_batch_count = $blockedRows.Count
    cut_rewrite_packet_count = 0
    cut_rewrite_queue_batch_count = $cutRewriteRows.Count
    line_count = (@($packetRows) | Measure-Object line_count -Sum).Sum
    word_count = (@($packetRows) | Measure-Object word_count -Sum).Sum
    rule_locks = @(
        "Only scratch-ready batches get recording packets.",
        "Blocked pending-cast batches must not get packet files.",
        "Cut/rewrite blocked batches must not get packet files.",
        "Packets preserve source order and context lines.",
        "Scratch packets are not shipping audio approval.",
        "Litany text is pulled from the confession VO manifest generated from data/confessions.json.",
        "Keep the accepted Litany/Registrar duel format."
    )
    packets = $packetRows
}

$index | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$packetRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = @(
    "# VO Recording Packets Index",
    "",
    'Generated by `tools/Export-VoRecordingPackets.ps1` from the scratch VO queue and VO line manifests.',
    "",
    "Purpose: per-batch scratch VO recording packet index. Only scratch-ready batches get packet files.",
    "",
    "Generated at UTC: $generatedAtUtc",
    "",
    "Source modified UTC:",
    "- docs/vo/vo_recording_queue.json: $($sourceModifiedUtc["docs/vo/vo_recording_queue.json"])",
    "- docs/vo/vo_recording_batches.json: $($sourceModifiedUtc["docs/vo/vo_recording_batches.json"])",
    "- docs/vo/act_i_vo_line_manifest.json: $($sourceModifiedUtc["docs/vo/act_i_vo_line_manifest.json"])",
    "- docs/vo/confession_vo_manifest.json: $($sourceModifiedUtc["docs/vo/confession_vo_manifest.json"])",
    "",
    'Packet directory: `docs/vo/recording_packets/scratch_ready`',
    'Blocked packet directory: `docs/vo/recording_packets/blocked_pending_cast_decision`',
    'Cut/rewrite packet directory: `docs/vo/recording_packets/blocked_cut_or_rewrite`',
    "Packet count: $($packetRows.Count)",
    "Blocked packet count: 0",
    "Blocked queue batch count: $($blockedRows.Count)",
    "Cut/rewrite packet count: 0",
    "Cut/rewrite queue batch count: $($cutRewriteRows.Count)",
    "Lines in packets: $($index.line_count)",
    "Words in packets: $($index.word_count)",
    "",
    "Rule locks:",
    "- Only scratch-ready batches get recording packets.",
    "- Blocked pending-cast batches must not get packet files.",
    "- Cut/rewrite blocked batches must not get packet files.",
    "- Packets preserve source order and context lines.",
    "- Scratch packets are not shipping audio approval.",
    "- Litany text is pulled from the confession VO manifest generated from data/confessions.json.",
    "- Keep the accepted Litany/Registrar duel format.",
    "",
    "## First 25 Packets",
    "",
    "| Batch | Speaker | Lines | Words | Packet |",
    "|---|---|---:|---:|---|"
)
foreach ($packet in ($packetRows | Select-Object -First 25)) {
    $packetPathForTable = [string]$packet.packet_path
    $lines += "| $($packet.batch_id) | $($packet.speaker) | $($packet.line_count) | $($packet.word_count) | ``$packetPathForTable`` |"
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported VO recording packet index JSON -> $jsonPath"
Write-Host "Exported VO recording packet index CSV -> $csvPath"
Write-Host "Exported VO recording packet index report -> $mdPath"
Write-Host "VO recording packets: packets=$($packetRows.Count), blockedPackets=0, lines=$($index.line_count), words=$($index.word_count)"
