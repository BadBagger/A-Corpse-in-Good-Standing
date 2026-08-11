$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$actIManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$batchManifestPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$jsonPath = Join-Path $root "docs\vo\vo_cast_plan.json"
$csvPath = Join-Path $root "docs\vo\vo_cast_plan.csv"
$mdPath = Join-Path $root "docs\vo\vo_cast_plan.md"

foreach ($path in @($actIManifestPath, $confessionManifestPath, $batchManifestPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO cast plan input: $path"
    }
}

$inputPaths = [ordered]@{
    "docs/vo/act_i_vo_line_manifest.json" = $actIManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
    "docs/vo/vo_recording_batches.json" = $batchManifestPath
}
$sourceModifiedUtc = [ordered]@{}
foreach ($entry in $inputPaths.GetEnumerator()) {
    $sourceModifiedUtc[$entry.Key] = (Get-Item -LiteralPath $entry.Value).LastWriteTimeUtc.ToString("o")
}
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

$actIManifest = Get-Content -LiteralPath $actIManifestPath -Raw | ConvertFrom-Json
$confessionManifest = Get-Content -LiteralPath $confessionManifestPath -Raw | ConvertFrom-Json
$batchManifest = Get-Content -LiteralPath $batchManifestPath -Raw | ConvertFrom-Json
$actISpeakers = @($actIManifest.speakers)
$batchSpeakers = @($batchManifest.speakers)
$actILines = @($actIManifest.lines)

$directionBySpeaker = @{
    CORVIN = "Dry, fast, funny at his own wake. No wet/dead vocal effect; he sounds normal and forgets to fake breathing."
    TOMAS = "Casual, confident, warm enough to make the bollard joke hurt later."
    SABINE = "Low, controlled, amused more than angry. Never apologizes, never softens the line for Corvin."
    KANE = "Warm recruiter, not a monster. Courteous and reasonable; menace ruins the scene."
    JUNO = "Hospitable and bitter at once. Strong edge, no cartoon bawdiness."
    TEODOR = "Young, sincere, financially doomed. Comic surface, real kindness underneath."
    REGISTRAR = "Clipped, administrative, exact. Forty years of striking names off rolls."
    CHANDLER = "Cheerful about horrifying things. Let one genuine moment through cleanly."
    PROSPER = "Warm, blank, delighted. Never play the tragedy; let the writing do it."
    ADELA = "Minor role pending cast/consolidation decision."
    BOOT_SELLER = "Minor role pending cast/consolidation decision."
    BOY = "Minor role pending cast/consolidation decision; keep child role plainly non-sexualized."
    CLERK = "Minor role pending cast/consolidation decision."
    MAN = "Minor role pending cast/consolidation decision."
    MARIN = "Minor role pending cast/consolidation decision."
    MONGER = "Minor role pending cast/consolidation decision."
    WOMAN = "Minor role pending cast/consolidation decision."
    NARRATION = "Stage direction review only; do not record as VO."
}

$scratchVoiceIdBySpeaker = @{}
foreach ($line in $actILines) {
    if (-not [string]::IsNullOrWhiteSpace([string]$line.scratch_voice_id) -and -not $scratchVoiceIdBySpeaker.ContainsKey([string]$line.speaker)) {
        $scratchVoiceIdBySpeaker[[string]$line.speaker] = [string]$line.scratch_voice_id
    }
}
if (-not [string]::IsNullOrWhiteSpace([string]$confessionManifest.scratch_voice_id)) {
    $scratchVoiceIdBySpeaker[[string]$confessionManifest.speaker] = [string]$confessionManifest.scratch_voice_id
}

$batchSpeakerByName = @{}
foreach ($speaker in $batchSpeakers) {
    $batchSpeakerByName[[string]$speaker.speaker] = $speaker
}

$castRows = @()
foreach ($speaker in $actISpeakers) {
    $speakerId = [string]$speaker.speaker
    $batchSpeaker = if ($batchSpeakerByName.ContainsKey($speakerId)) { $batchSpeakerByName[$speakerId] } else { $null }
    $totalLineCount = if ($null -ne $batchSpeaker) { [int]$batchSpeaker.line_count } else { [int]$speaker.line_count }
    $totalWordCount = if ($null -ne $batchSpeaker) { [int]$batchSpeaker.word_count } else { [int]$speaker.word_count }
    $batchCount = if ($null -ne $batchSpeaker) { [int]$batchSpeaker.batch_count } else { 0 }
    $uncastBatchCount = if ($null -ne $batchSpeaker) { [int]$batchSpeaker.uncast_batch_count } else { 0 }
    $effectiveCastStatus = if ($null -ne $batchSpeaker -and -not [string]::IsNullOrWhiteSpace([string]$batchSpeaker.cast_status)) { [string]$batchSpeaker.cast_status } else { [string]$speaker.cast_status }
    $scratchVoice = [string]$speaker.scratch_voice
    $scratchVoiceId = if ($scratchVoiceIdBySpeaker.ContainsKey($speakerId)) { $scratchVoiceIdBySpeaker[$speakerId] } else { "" }
    if ($effectiveCastStatus -eq "scratch_cast" -and $null -ne $batchSpeaker) {
        $firstScratchBatch = @($batchManifest.batches | Where-Object { $_.speaker -eq $speakerId -and $_.cast_status -eq "scratch_cast" })[0]
        if ($null -ne $firstScratchBatch) {
            $scratchVoice = [string]$firstScratchBatch.scratch_voice
            $scratchVoiceId = [string]$firstScratchBatch.scratch_voice_id
        }
    }
    $litanyLines = if ($speakerId -eq [string]$confessionManifest.speaker) { [int]$confessionManifest.line_count } else { 0 }
    $castRows += [pscustomobject][ordered]@{
        speaker = $speakerId
        character = [string]$speaker.character
        cast_status = $effectiveCastStatus
        scratch_voice = $scratchVoice
        scratch_voice_id = $scratchVoiceId
        act_i_lines = [int]$speaker.line_count
        litany_lines = $litanyLines
        total_recordable_lines = $totalLineCount
        total_words = $totalWordCount
        batch_count = $batchCount
        uncast_batch_count = $uncastBatchCount
        voice_direction = if ($directionBySpeaker.ContainsKey($speakerId)) { $directionBySpeaker[$speakerId] } else { "Needs voice direction." }
        shipping_status = if ($effectiveCastStatus -eq "scratch_cast") { "scratch_only_licensing_unverified" } elseif ($effectiveCastStatus -eq "needs_cast_decision") { "blocked_pending_cast_decision" } else { "blocked_pending_script_or_cast_work" }
    }
}

$scratchCastCount = @($castRows | Where-Object { $_.cast_status -eq "scratch_cast" }).Count
$needsDecisionCount = @($castRows | Where-Object { $_.cast_status -eq "needs_cast_decision" }).Count
$stageDirectionCount = @($castRows | Where-Object { $_.cast_status -eq "not_cast_stage_direction" }).Count
$totalRecordableLines = [int]$batchManifest.line_count
$totalWordCount = [int]$batchManifest.word_count

$plan = [ordered]@{
    generated_from = @(
        "docs/vo/act_i_vo_line_manifest.json",
        "docs/vo/confession_vo_manifest.json",
        "docs/vo/vo_recording_batches.json"
    )
    generated_at_utc = $generatedAtUtc
    source_modified_utc = $sourceModifiedUtc
    purpose = "Manifest-driven scratch VO cast plan for Act I and Litany recording batches."
    recording_status = "unrecorded"
    shipping_status = "scratch_only_licensing_unverified"
    speaker_count = $castRows.Count
    scratch_cast_count = $scratchCastCount
    needs_cast_decision_count = $needsDecisionCount
    stage_direction_count = $stageDirectionCount
    total_recordable_lines = $totalRecordableLines
    total_words = $totalWordCount
    rule_locks = @(
        "Scratch voices are timing/casting references only until commercial licensing is verified.",
        "Do not generate VO line-by-line in isolation.",
        "Scene VO batches stay grouped by Ink knot and speaker.",
        "Litany confession and elaboration lines stay adjacent and keyed by confession id.",
        "Do not start scratch generation for batches whose speaker remains pending.",
        "Keep the accepted Litany/Registrar duel format."
    )
    cast = $castRows
}

$plan | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$castRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = @(
    "# VO Cast Plan",
    "",
    'Generated by `tools/Export-VoCastPlan.ps1` from the current VO manifests and recording batches.',
    "",
    "Purpose: manifest-driven scratch VO cast plan for Act I and Litany recording batches.",
    "",
    "Generated at UTC: $generatedAtUtc",
    "",
    "Source modified UTC:",
    "- docs/vo/act_i_vo_line_manifest.json: $($sourceModifiedUtc["docs/vo/act_i_vo_line_manifest.json"])",
    "- docs/vo/confession_vo_manifest.json: $($sourceModifiedUtc["docs/vo/confession_vo_manifest.json"])",
    "- docs/vo/vo_recording_batches.json: $($sourceModifiedUtc["docs/vo/vo_recording_batches.json"])",
    "",
    "Recording status: unrecorded",
    "Shipping status: scratch_only_licensing_unverified",
    "Speakers: $($castRows.Count)",
    "Scratch-cast speakers: $scratchCastCount",
    "Minor speakers needing cast/consolidation: $needsDecisionCount",
    "Stage-direction speakers not recorded: $stageDirectionCount",
    "Recordable lines: $totalRecordableLines",
    "Words: $totalWordCount",
    "",
    "Rule locks:",
    "- Scratch voices are timing/casting references only until commercial licensing is verified.",
    "- Do not generate VO line-by-line in isolation.",
    "- Scene VO batches stay grouped by Ink knot and speaker.",
    "- Litany confession and elaboration lines stay adjacent and keyed by confession id.",
    "- Do not start scratch generation for batches whose speaker remains pending.",
    "- Keep the accepted Litany/Registrar duel format.",
    "",
    "## Cast Table",
    "",
    "| Speaker | Character | Status | Scratch Voice | Lines | Batches | Direction |",
    "|---|---|---|---|---:|---:|---|"
)

foreach ($row in ($castRows | Sort-Object speaker)) {
    $character = if ([string]::IsNullOrWhiteSpace($row.character)) { "-" } else { $row.character }
    $scratch = if ([string]::IsNullOrWhiteSpace($row.scratch_voice)) { "-" } else { "$($row.scratch_voice) / $($row.scratch_voice_id)" }
    $lines += "| $($row.speaker) | $character | $($row.cast_status) | $scratch | $($row.total_recordable_lines) | $($row.batch_count) | $($row.voice_direction) |"
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported VO cast plan JSON -> $jsonPath"
Write-Host "Exported VO cast plan CSV -> $csvPath"
Write-Host "Exported VO cast plan report -> $mdPath"
Write-Host "VO cast plan: speakers=$($castRows.Count), scratchCast=$scratchCastCount, needsDecision=$needsDecisionCount, lines=$totalRecordableLines, words=$totalWordCount"
