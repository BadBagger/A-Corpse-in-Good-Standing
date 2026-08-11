$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-VoAudioAssetStatus.ps1"
$jsonPath = Join-Path $root "docs\vo\vo_audio_asset_status.json"
$csvPath = Join-Path $root "docs\vo\vo_audio_asset_status.csv"
$mdPath = Join-Path $root "docs\vo\vo_audio_asset_status.md"
$decisionJsonPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"
$actManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$recordingBatchesPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$recordingQueuePath = Join-Path $root "docs\vo\vo_recording_queue.json"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing VO audio asset status exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "VO audio asset status export failed."
}

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO audio asset status artifact: $path"
    }
}

$status = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$report = Get-Content -LiteralPath $mdPath -Raw
$expectedRows = @($status.lines | ForEach-Object { $_ })
$unplannedRows = @($status.unplanned | ForEach-Object { $_ })
$hasAppliedMinorSpeakerDecisions = Test-Path -LiteralPath $decisionJsonPath
$scratchRows = @($expectedRows | Where-Object { $_.recording_queue_status -eq "scratch_ready" })
$blockedRows = @($expectedRows | Where-Object { $_.recording_queue_status -ne "scratch_ready" })
$pendingCastRows = @($expectedRows | Where-Object { $_.recording_queue_status -eq "blocked_pending_cast_decision" })
$cutRewriteRows = @($expectedRows | Where-Object { $_.recording_queue_status -eq "blocked_cut_or_rewrite" })
$expectedGeneratedFrom = @(
    "docs/vo/act_i_vo_line_manifest.json",
    "docs/vo/confession_vo_manifest.json",
    "docs/vo/vo_recording_batches.json",
    "docs/vo/vo_recording_queue.json"
)
$sourcePaths = @{
    "docs/vo/act_i_vo_line_manifest.json" = $actManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
    "docs/vo/vo_recording_batches.json" = $recordingBatchesPath
    "docs/vo/vo_recording_queue.json" = $recordingQueuePath
}

foreach ($relativePath in $expectedGeneratedFrom) {
    if ($relativePath -notin @($status.generated_from | ForEach-Object { [string]$_ })) {
        throw "VO audio status generated_from missing source: $relativePath"
    }
    $actualSourceStamp = [string]$status.source_modified_utc.PSObject.Properties[$relativePath].Value
    $expectedSourceStamp = (Get-Item -LiteralPath $sourcePaths[$relativePath]).LastWriteTimeUtc.ToString("o")
    if ($actualSourceStamp -ne $expectedSourceStamp) {
        throw "VO audio status source_modified_utc is stale or inconsistent for $relativePath."
    }
}
if ([string]::IsNullOrWhiteSpace([string]$status.generated_at_utc)) {
    throw "VO audio status missing generated_at_utc freshness stamp."
}
try {
    $generatedAt = [datetime]::Parse([string]$status.generated_at_utc).ToUniversalTime()
    foreach ($relativePath in $expectedGeneratedFrom) {
        $sourceModified = [datetime]::Parse([string]$status.source_modified_utc.PSObject.Properties[$relativePath].Value).ToUniversalTime()
        if ($generatedAt -lt $sourceModified) {
            throw "VO audio status generated_at_utc predates source $relativePath."
        }
    }
} catch {
    throw "VO audio status freshness stamps must be parseable UTC datetimes and not predate sources."
}

if ([int]$status.expected_count -ne 652) {
    throw "Expected 652 VO audio assets from current manifests, got $($status.expected_count)."
}
if ([int]$status.scratch_ready_expected_count -ne $scratchRows.Count) {
    throw "VO audio scratch-ready expected count mismatch: json=$($status.scratch_ready_expected_count), rows=$($scratchRows.Count)."
}
if ([int]$status.blocked_expected_count -ne $blockedRows.Count) {
    throw "VO audio blocked expected count mismatch: json=$($status.blocked_expected_count), rows=$($blockedRows.Count)."
}
if ([int]$status.pending_cast_blocked_expected_count -ne $pendingCastRows.Count) {
    throw "VO audio pending-cast blocked count mismatch: json=$($status.pending_cast_blocked_expected_count), rows=$($pendingCastRows.Count)."
}
if ([int]$status.cut_rewrite_blocked_expected_count -ne $cutRewriteRows.Count) {
    throw "VO audio cut/rewrite blocked count mismatch: json=$($status.cut_rewrite_blocked_expected_count), rows=$($cutRewriteRows.Count)."
}
if ([int]$status.scratch_ready_expected_count + [int]$status.blocked_expected_count -ne [int]$status.expected_count) {
    throw "VO audio queue counts do not add up to expected_count."
}
if (-not $hasAppliedMinorSpeakerDecisions) {
    if ([int]$status.scratch_ready_expected_count -ne 600) {
        throw "Baseline expected 600 scratch-ready VO audio assets from current recording queue, got $($status.scratch_ready_expected_count)."
    }
    if ([int]$status.blocked_expected_count -ne 52 -or [int]$status.pending_cast_blocked_expected_count -ne 52 -or [int]$status.cut_rewrite_blocked_expected_count -ne 0) {
        throw "Baseline expected 52 pending-cast blocked VO audio assets and 0 cut/rewrite blocked assets."
    }
}
if ($expectedRows.Count -ne [int]$status.expected_count) {
    throw "VO audio status line count does not match expected_count."
}
if ($rows.Count -ne ([int]$status.expected_count + [int]$status.unplanned_count)) {
    throw "VO audio status CSV row count does not match expected plus unplanned."
}
if ([int]$status.zero_byte_count -ne 0) {
    throw "VO audio status found zero-byte expected MP3 files."
}
if ([int]$status.present_blocked_count -ne 0) {
    throw "VO audio status found blocked expected MP3 files before cast decisions are complete."
}
if ([int]$status.unplanned_count -ne 0 -or $unplannedRows.Count -ne 0) {
    throw "VO audio status found unplanned MP3 files under vo/."
}
if ([int]$status.present_count + [int]$status.missing_count + [int]$status.zero_byte_count -ne [int]$status.expected_count) {
    throw "VO audio status counts do not add up."
}
if ($status.status -notin @("no_audio_present", "partial_audio_present", "all_scratch_ready_audio_present")) {
    throw "VO audio status has invalid state for validated intake: $($status.status)"
}

$paths = @{}
foreach ($row in $expectedRows) {
    foreach ($field in @("line_id", "line_type", "speaker", "audio_path", "status", "size_bytes", "recording_queue_status", "packet_status", "source_ref")) {
        if ($null -eq $row.$field -or [string]::IsNullOrWhiteSpace([string]$row.$field)) {
            throw "VO audio status row has empty required field '$field': $($row | ConvertTo-Json -Compress)"
        }
    }
    $audioPath = [string]$row.audio_path
    if (-not $audioPath.StartsWith("vo/") -or -not $audioPath.EndsWith(".mp3")) {
        throw "Invalid expected VO audio path: $audioPath"
    }
    if ($paths.ContainsKey($audioPath)) {
        throw "Duplicate expected VO audio path in status: $audioPath"
    }
    $paths[$audioPath] = $true
    if ($row.status -notin @("missing", "present")) {
        throw "Unexpected VO audio row status after validation: $($row.status) for $audioPath"
    }
    if ($row.recording_queue_status -eq "scratch_ready") {
        if ($row.packet_status -ne "scratch_ready_packeted") {
            throw "Scratch-ready VO audio row must be packeted: $audioPath"
        }
    } elseif ($row.recording_queue_status -in @("blocked_pending_cast_decision", "blocked_cut_or_rewrite")) {
        if ($row.packet_status -ne "blocked_no_packet") {
            throw "Blocked VO audio row must have blocked_no_packet status: $audioPath"
        }
        if ($row.status -ne "missing") {
            throw "Blocked expected MP3 must remain missing until cast decision: $audioPath"
        }
    } else {
        throw "Unexpected VO audio recording queue status: $($row.recording_queue_status) for $audioPath"
    }
    if ($row.status -eq "present" -and [int64]$row.size_bytes -le 0) {
        throw "Present VO audio row must have positive size: $audioPath"
    }
}

foreach ($requiredText in @(
    "VO Audio Asset Status",
    "Generated at UTC: $($status.generated_at_utc)",
    "Source modified UTC:",
    "docs/vo/act_i_vo_line_manifest.json: $($status.source_modified_utc.PSObject.Properties['docs/vo/act_i_vo_line_manifest.json'].Value)",
    "docs/vo/confession_vo_manifest.json: $($status.source_modified_utc.PSObject.Properties['docs/vo/confession_vo_manifest.json'].Value)",
    "docs/vo/vo_recording_batches.json: $($status.source_modified_utc.PSObject.Properties['docs/vo/vo_recording_batches.json'].Value)",
    "docs/vo/vo_recording_queue.json: $($status.source_modified_utc.PSObject.Properties['docs/vo/vo_recording_queue.json'].Value)",
    "Expected audio paths are generated from VO manifests.",
    "Scratch-ready expected MP3s come from the VO recording queue.",
    "Blocked pending-cast and cut/rewrite audio paths must not have MP3 files yet.",
    "Generated recording packets cover scratch-ready batches only.",
    "Scratch-ready expected: $($scratchRows.Count)",
    "Blocked expected: $($blockedRows.Count)",
    "Pending-cast blocked expected: $($pendingCastRows.Count)",
    "Cut/rewrite blocked expected: $($cutRewriteRows.Count)",
    "Present blocked: 0",
    "Missing audio is allowed during planning; it must not be counted as recorded.",
    "Zero-byte expected MP3 files fail validation.",
    'Unplanned MP3 files under `vo/` fail validation.',
    "Scratch voices are not shipping approval."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "VO audio status report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "ÃƒÂ¯Ã‚Â»Ã‚Â¿", "`t")) {
    if ($report.Contains($forbiddenText)) {
        throw "VO audio status report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "VO audio status report contains illegal control characters."
}

Write-Host "VO audio asset status validation passed: status=$($status.status), expected=$($status.expected_count), present=$($status.present_count), missing=$($status.missing_count)."
