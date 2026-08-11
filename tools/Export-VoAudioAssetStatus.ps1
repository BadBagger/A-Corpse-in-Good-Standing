$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$actManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$recordingBatchesPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$recordingQueuePath = Join-Path $root "docs\vo\vo_recording_queue.json"
$outDir = Join-Path $root "docs\vo"
$jsonPath = Join-Path $outDir "vo_audio_asset_status.json"
$csvPath = Join-Path $outDir "vo_audio_asset_status.csv"
$mdPath = Join-Path $outDir "vo_audio_asset_status.md"
$voRoot = Join-Path $root "vo"

foreach ($path in @($actManifestPath, $confessionManifestPath, $recordingBatchesPath, $recordingQueuePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO audio status input: $path"
    }
}

if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$inputPaths = [ordered]@{
    "docs/vo/act_i_vo_line_manifest.json" = $actManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
    "docs/vo/vo_recording_batches.json" = $recordingBatchesPath
    "docs/vo/vo_recording_queue.json" = $recordingQueuePath
}
$sourceModifiedUtc = [ordered]@{}
foreach ($entry in $inputPaths.GetEnumerator()) {
    $sourceModifiedUtc[$entry.Key] = (Get-Item -LiteralPath $entry.Value).LastWriteTimeUtc.ToString("o")
}
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

$actManifest = Get-Content -LiteralPath $actManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$confessionManifest = Get-Content -LiteralPath $confessionManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$recordingBatches = Get-Content -LiteralPath $recordingBatchesPath -Raw -Encoding UTF8 | ConvertFrom-Json
$recordingQueue = Get-Content -LiteralPath $recordingQueuePath -Raw -Encoding UTF8 | ConvertFrom-Json
$actLines = @($actManifest.lines | Where-Object { $_.recording_scope -eq "vo_line" })
$confessionLines = @($confessionManifest.lines | ForEach-Object { $_ })
$expectedLines = @($actLines + $confessionLines)

$batchById = @{}
foreach ($batch in @($recordingBatches.batches | ForEach-Object { $_ })) {
    $batchId = [string]$batch.batch_id
    if ([string]::IsNullOrWhiteSpace($batchId)) {
        throw "VO recording batch has empty batch_id."
    }
    $batchById[$batchId] = $batch
}

$queueStatusByLineId = @{}
$packetStatusByLineId = @{}
foreach ($queueName in @("scratch_ready", "blocked_pending_cast_decision", "blocked_cut_or_rewrite")) {
    $queueRows = @($recordingQueue.queues.$queueName | ForEach-Object { $_ })
    foreach ($queueRow in $queueRows) {
        $batchId = [string]$queueRow.batch_id
        if (-not $batchById.ContainsKey($batchId)) {
            throw "VO recording queue references unknown batch: $batchId"
        }
        $batch = $batchById[$batchId]
        foreach ($lineId in @($batch.source_line_ids | ForEach-Object { [string]$_ })) {
            if ([string]::IsNullOrWhiteSpace($lineId)) {
                throw "VO recording batch $batchId has empty source_line_id."
            }
            if ($queueStatusByLineId.ContainsKey($lineId)) {
                throw "VO line appears in more than one recording queue batch: $lineId"
            }
            $queueStatusByLineId[$lineId] = $queueName
            $packetStatusByLineId[$lineId] = if ($queueName -eq "scratch_ready") { "scratch_ready_packeted" } else { "blocked_no_packet" }
        }
    }
}

if ($queueStatusByLineId.Count -ne $expectedLines.Count) {
    throw "VO recording queue line coverage mismatch: expected $($expectedLines.Count), queued $($queueStatusByLineId.Count)."
}

$rows = @()
$expectedByPath = @{}
foreach ($line in $expectedLines) {
    $audioPath = ([string]$line.audio_path).Replace("\", "/")
    if ([string]::IsNullOrWhiteSpace($audioPath)) {
        throw "VO line has empty audio_path: $($line.line_id)"
    }
    if (-not $audioPath.StartsWith("vo/") -or -not $audioPath.EndsWith(".mp3")) {
        throw "VO line has invalid audio_path: $($line.line_id) -> $audioPath"
    }
    if ($expectedByPath.ContainsKey($audioPath)) {
        throw "Duplicate expected VO audio path: $audioPath"
    }
    $expectedByPath[$audioPath] = [string]$line.line_id

    $lineId = [string]$line.line_id
    if (-not $queueStatusByLineId.ContainsKey($lineId)) {
        throw "VO line is not represented in recording queue: $lineId"
    }
    $recordingQueueStatus = [string]$queueStatusByLineId[$lineId]
    $packetStatus = [string]$packetStatusByLineId[$lineId]

    $absolutePath = Join-Path $root ($audioPath -replace "/", "\")
    $exists = Test-Path -LiteralPath $absolutePath -PathType Leaf
    $sizeBytes = 0
    $status = "missing"
    if ($exists) {
        $item = Get-Item -LiteralPath $absolutePath
        $sizeBytes = [int64]$item.Length
        $status = if ($sizeBytes -gt 0) { "present" } else { "zero_byte" }
    }
    if ($recordingQueueStatus -ne "scratch_ready" -and $status -eq "present") {
        $status = "blocked_audio_present"
    }

    $lineType = if ($audioPath.StartsWith("vo/confessions/")) { "confession" } else { "act_i_scene" }
    $speaker = [string]$line.speaker
    $sourceRef = if ($null -ne $line.source_ref) { [string]$line.source_ref } else { [string]$line.confession_id }

    $rows += [pscustomobject][ordered]@{
        line_id = $lineId
        line_type = $lineType
        speaker = $speaker
        audio_path = $audioPath
        status = $status
        size_bytes = $sizeBytes
        recording_queue_status = $recordingQueueStatus
        packet_status = $packetStatus
        source_ref = $sourceRef
    }
}

$strayRows = @()
if (Test-Path -LiteralPath $voRoot -PathType Container) {
    $mp3Files = @(Get-ChildItem -LiteralPath $voRoot -Recurse -File -Filter "*.mp3")
    foreach ($file in $mp3Files) {
        $rootPrefix = $root.TrimEnd("\") + "\"
        if (-not $file.FullName.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "VO MP3 file is outside project root: $($file.FullName)"
        }
        $relative = $file.FullName.Substring($rootPrefix.Length).Replace("\", "/")
        if (-not $expectedByPath.ContainsKey($relative)) {
            $strayRows += [pscustomobject][ordered]@{
                line_id = ""
                line_type = "unplanned"
                speaker = ""
                audio_path = $relative
                status = "unplanned"
                size_bytes = [int64]$file.Length
                source_ref = ""
            }
        }
    }
}

$allRows = @($rows + $strayRows)
$allRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$presentRows = @($rows | Where-Object { $_.status -eq "present" })
$missingRows = @($rows | Where-Object { $_.status -eq "missing" })
$zeroRows = @($rows | Where-Object { $_.status -eq "zero_byte" })
$blockedAudioRows = @($rows | Where-Object { $_.status -eq "blocked_audio_present" })
$scratchReadyRows = @($rows | Where-Object { $_.recording_queue_status -eq "scratch_ready" })
$blockedExpectedRows = @($rows | Where-Object { $_.recording_queue_status -ne "scratch_ready" })
$pendingCastExpectedRows = @($rows | Where-Object { $_.recording_queue_status -eq "blocked_pending_cast_decision" })
$cutRewriteExpectedRows = @($rows | Where-Object { $_.recording_queue_status -eq "blocked_cut_or_rewrite" })

$typeSummary = @(
    $rows |
        Group-Object line_type |
        Sort-Object Name |
        ForEach-Object {
            $typeRows = @($_.Group)
            [pscustomobject][ordered]@{
                line_type = $_.Name
                expected_count = $typeRows.Count
                present_count = @($typeRows | Where-Object { $_.status -eq "present" }).Count
                missing_count = @($typeRows | Where-Object { $_.status -eq "missing" }).Count
                zero_byte_count = @($typeRows | Where-Object { $_.status -eq "zero_byte" }).Count
            }
        }
)

$metadata = [ordered]@{
    generated_from = @(
        "docs/vo/act_i_vo_line_manifest.json",
        "docs/vo/confession_vo_manifest.json",
        "docs/vo/vo_recording_batches.json",
        "docs/vo/vo_recording_queue.json"
    )
    generated_at_utc = $generatedAtUtc
    source_modified_utc = $sourceModifiedUtc
    purpose = "VO audio asset intake/status report. Tracks expected MP3s and separates scratch-ready paths from blocked pending-cast and cut/rewrite paths."
    expected_count = $rows.Count
    present_count = $presentRows.Count
    missing_count = $missingRows.Count
    zero_byte_count = $zeroRows.Count
    scratch_ready_expected_count = $scratchReadyRows.Count
    blocked_expected_count = $blockedExpectedRows.Count
    pending_cast_blocked_expected_count = $pendingCastExpectedRows.Count
    cut_rewrite_blocked_expected_count = $cutRewriteExpectedRows.Count
    present_blocked_count = $blockedAudioRows.Count
    unplanned_count = $strayRows.Count
    status = if ($strayRows.Count -gt 0) { "unplanned_audio_present" } elseif ($blockedAudioRows.Count -gt 0) { "blocked_audio_present" } elseif ($zeroRows.Count -gt 0) { "zero_byte_audio_present" } elseif ($presentRows.Count -eq 0) { "no_audio_present" } elseif ($presentRows.Count -lt $scratchReadyRows.Count) { "partial_audio_present" } else { "all_scratch_ready_audio_present" }
    rule_locks = @(
        "Expected audio paths are generated from VO manifests.",
        "Scratch-ready expected MP3s come from the VO recording queue.",
        "Blocked pending-cast and cut/rewrite audio paths must not have MP3 files yet.",
        "Generated recording packets cover scratch-ready batches only.",
        "Missing audio is allowed during planning; it must not be counted as recorded.",
        "Zero-byte expected MP3 files fail validation.",
        "Unplanned MP3 files under vo/ fail validation.",
        "Scratch voices are not shipping approval."
    )
    types = $typeSummary
    lines = $rows
    unplanned = $strayRows
}

$metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$mdLines = @(
    "# VO Audio Asset Status",
    "",
    'Generated by `tools/Export-VoAudioAssetStatus.ps1` from the Act I and confession VO manifests.',
    "",
    "Purpose: audio intake/status report for expected VO MP3 files. This does not claim shipping audio exists.",
    "",
    "Generated at UTC: $generatedAtUtc",
    "",
    "Source modified UTC:",
    "- docs/vo/act_i_vo_line_manifest.json: $($sourceModifiedUtc["docs/vo/act_i_vo_line_manifest.json"])",
    "- docs/vo/confession_vo_manifest.json: $($sourceModifiedUtc["docs/vo/confession_vo_manifest.json"])",
    "- docs/vo/vo_recording_batches.json: $($sourceModifiedUtc["docs/vo/vo_recording_batches.json"])",
    "- docs/vo/vo_recording_queue.json: $($sourceModifiedUtc["docs/vo/vo_recording_queue.json"])",
    "",
    "Status: $($metadata.status)",
    "Expected MP3s: $($metadata.expected_count)",
    "Scratch-ready expected: $($metadata.scratch_ready_expected_count)",
    "Blocked expected: $($metadata.blocked_expected_count)",
    "Pending-cast blocked expected: $($metadata.pending_cast_blocked_expected_count)",
    "Cut/rewrite blocked expected: $($metadata.cut_rewrite_blocked_expected_count)",
    "Present: $($metadata.present_count)",
    "Missing: $($metadata.missing_count)",
    "Zero-byte: $($metadata.zero_byte_count)",
    "Present blocked: $($metadata.present_blocked_count)",
    "Unplanned: $($metadata.unplanned_count)",
    "",
    "Rule locks:",
    "- Expected audio paths are generated from VO manifests.",
    "- Scratch-ready expected MP3s come from the VO recording queue.",
    "- Blocked pending-cast and cut/rewrite audio paths must not have MP3 files yet.",
    "- Generated recording packets cover scratch-ready batches only.",
    "- Missing audio is allowed during planning; it must not be counted as recorded.",
    "- Zero-byte expected MP3 files fail validation.",
    '- Unplanned MP3 files under `vo/` fail validation.',
    "- Scratch voices are not shipping approval.",
    "",
    "## Type Summary",
    "",
    "| Type | Expected | Present | Missing | Zero-byte |",
    "|---|---:|---:|---:|---:|"
)

foreach ($type in $typeSummary) {
    $mdLines += "| $($type.line_type) | $($type.expected_count) | $($type.present_count) | $($type.missing_count) | $($type.zero_byte_count) |"
}

$mdLines += ""
$mdLines += "## First 25 Expected Files"
$mdLines += ""
$mdLines += "| Line | Type | Speaker | Queue | Packet | Status | Audio path |"
$mdLines += "|---|---|---|---|---|---|---|"
foreach ($row in @($rows | Select-Object -First 25)) {
    $mdLines += "| $($row.line_id) | $($row.line_type) | $($row.speaker) | $($row.recording_queue_status) | $($row.packet_status) | $($row.status) | ``$($row.audio_path)`` |"
}

if ($strayRows.Count -gt 0) {
    $mdLines += ""
    $mdLines += "## Unplanned MP3 Files"
    $mdLines += ""
    foreach ($row in $strayRows) {
        $mdLines += "- ``$($row.audio_path)`` ($($row.size_bytes) bytes)"
    }
}

Set-Content -LiteralPath $mdPath -Value $mdLines -Encoding UTF8

Write-Host "Exported VO audio asset status JSON -> $jsonPath"
Write-Host "Exported VO audio asset status CSV -> $csvPath"
Write-Host "Exported VO audio asset status report -> $mdPath"
Write-Host "VO audio asset status: status=$($metadata.status), expected=$($metadata.expected_count), scratchReady=$($metadata.scratch_ready_expected_count), blocked=$($metadata.blocked_expected_count), present=$($metadata.present_count), missing=$($metadata.missing_count), zeroByte=$($metadata.zero_byte_count), presentBlocked=$($metadata.present_blocked_count), unplanned=$($metadata.unplanned_count)"
