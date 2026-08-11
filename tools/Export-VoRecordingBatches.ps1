$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$actManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$minorSpeakerDecisionPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"
$outDir = Join-Path $root "docs\vo"
$jsonPath = Join-Path $outDir "vo_recording_batches.json"
$csvPath = Join-Path $outDir "vo_recording_batches.csv"
$mdPath = Join-Path $outDir "vo_recording_batches.md"

foreach ($path in @($actManifestPath, $confessionManifestPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO batch input: $path"
    }
}

if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$inputPaths = [ordered]@{
    "docs/vo/act_i_vo_line_manifest.json" = $actManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
}
$sourceModifiedUtc = [ordered]@{}
foreach ($entry in $inputPaths.GetEnumerator()) {
    $sourceModifiedUtc[$entry.Key] = (Get-Item -LiteralPath $entry.Value).LastWriteTimeUtc.ToString("o")
}
$minorDecisionSourceStatus = if (Test-Path -LiteralPath $minorSpeakerDecisionPath) { "present" } else { "absent" }
if ($minorDecisionSourceStatus -eq "present") {
    $sourceModifiedUtc["docs/vo/vo_minor_speaker_decisions.json"] = (Get-Item -LiteralPath $minorSpeakerDecisionPath).LastWriteTimeUtc.ToString("o")
}
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

$actManifest = Get-Content -LiteralPath $actManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$confessionManifest = Get-Content -LiteralPath $confessionManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$actLines = @($actManifest.lines | ForEach-Object { $_ })
$confessionLines = @($confessionManifest.lines | ForEach-Object { $_ })

$minorDecisionsBySpeaker = @{}
if (Test-Path -LiteralPath $minorSpeakerDecisionPath) {
    $minorDecisionArtifact = Get-Content -LiteralPath $minorSpeakerDecisionPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($decision in @($minorDecisionArtifact.decisions)) {
        $minorDecisionsBySpeaker[[string]$decision.speaker] = $decision
    }
}

$scratchVoiceBySpeaker = @{}
foreach ($line in $actLines) {
    $lineSpeaker = [string]$line.speaker
    if (-not $scratchVoiceBySpeaker.ContainsKey($lineSpeaker) -and -not [string]::IsNullOrWhiteSpace([string]$line.scratch_voice_id)) {
        $scratchVoiceBySpeaker[$lineSpeaker] = [ordered]@{
            scratch_voice = [string]$line.scratch_voice
            scratch_voice_id = [string]$line.scratch_voice_id
        }
    }
}
foreach ($decision in $minorDecisionsBySpeaker.Values) {
    if ([string]$decision.decision -eq "cast") {
        $scratchVoiceBySpeaker[[string]$decision.speaker] = [ordered]@{
            scratch_voice = [string]$decision.scratch_voice
            scratch_voice_id = [string]$decision.scratch_voice_id
        }
    }
}

function Resolve-MinorSpeakerDecision {
    param(
        [Parameter(Mandatory=$true)][string]$Speaker,
        [Parameter(Mandatory=$true)][string]$DefaultCastStatus,
        [string]$DefaultScratchVoice = "",
        [string]$DefaultScratchVoiceId = ""
    )

    $default = [ordered]@{
        cast_status = $DefaultCastStatus
        scratch_voice = $DefaultScratchVoice
        scratch_voice_id = $DefaultScratchVoiceId
        notes = "Do not generate these lines as disconnected fragments."
    }

    if (-not $minorDecisionsBySpeaker.ContainsKey($Speaker)) {
        return $default
    }

    $decision = $minorDecisionsBySpeaker[$Speaker]
    if ([string]$decision.decision -eq "pending") {
        return $default
    }
    if ([string]$decision.decision -eq "cast") {
        return [ordered]@{
            cast_status = "scratch_cast"
            scratch_voice = [string]$decision.scratch_voice
            scratch_voice_id = [string]$decision.scratch_voice_id
            notes = "Minor speaker cast as $([string]$decision.cast_as). $([string]$decision.notes) Do not generate these lines as disconnected fragments."
        }
    }
    if ([string]$decision.decision -eq "consolidate") {
        $target = [string]$decision.consolidate_into
        if (-not $scratchVoiceBySpeaker.ContainsKey($target)) {
            throw "Minor speaker $Speaker consolidates into target without a resolved scratch voice: $target"
        }
        $targetVoice = $scratchVoiceBySpeaker[$target]
        return [ordered]@{
            cast_status = "scratch_cast"
            scratch_voice = [string]$targetVoice.scratch_voice
            scratch_voice_id = [string]$targetVoice.scratch_voice_id
            notes = "Minor speaker consolidated into $target. $([string]$decision.notes) Do not generate these lines as disconnected fragments."
        }
    }
    if ([string]$decision.decision -eq "cut_or_rewrite") {
        return [ordered]@{
            cast_status = "blocked_cut_or_rewrite"
            scratch_voice = ""
            scratch_voice_id = ""
            notes = "Cut/rewrite required before VO: $([string]$decision.notes) Do not generate these lines as disconnected fragments."
        }
    }

    throw "Invalid minor speaker decision for $Speaker`: $($decision.decision)"
}

$batches = @()
$sequence = 0

$sceneGroups = @(
    $actLines |
        Where-Object { $_.recording_scope -eq "vo_line" } |
        Group-Object knot, speaker |
        Sort-Object {
            $first = @($_.Group | Sort-Object {[int]$_.line_number})[0]
            [int]$first.line_number
        }
)

foreach ($group in $sceneGroups) {
    $groupLines = @($group.Group | Sort-Object {[int]$_.line_number})
    if ($groupLines.Count -eq 0) {
        continue
    }
    $first = $groupLines[0]
    $knot = [string]$first.knot
    $speaker = [string]$first.speaker
    $contextLines = @($actLines | Where-Object { $_.knot -eq $knot } | Sort-Object {[int]$_.line_number})
    $sequence++
    $decisionState = Resolve-MinorSpeakerDecision -Speaker $speaker -DefaultCastStatus ([string]$first.cast_status) -DefaultScratchVoice ([string]$first.scratch_voice) -DefaultScratchVoiceId ([string]$first.scratch_voice_id)

    $batches += [pscustomobject][ordered]@{
        batch_id = "vo_batch_act_i_{0:0000}" -f $sequence
        batch_type = "scene_speaker_run"
        act = "Act I"
        speaker = $speaker
        scratch_voice = [string]$decisionState.scratch_voice
        scratch_voice_id = [string]$decisionState.scratch_voice_id
        cast_status = [string]$decisionState.cast_status
        location = [string]$first.location
        knot = $knot
        category = ""
        act_available = ""
        source_manifest = "docs/vo/act_i_vo_line_manifest.json"
        line_count = $groupLines.Count
        word_count = ($groupLines | Measure-Object -Property word_count -Sum).Sum
        source_line_ids = @($groupLines | Select-Object -ExpandProperty line_id)
        context_line_ids = @($contextLines | Select-Object -ExpandProperty line_id)
        audio_paths = @($groupLines | Select-Object -ExpandProperty audio_path)
        recording_status = "unrecorded"
        generation_rule = "Generate as one speaker run in scene order with per-line tags; review full scene context before recording."
        notes = [string]$decisionState.notes
    }
}

$confessionGroups = @(
    $confessionLines |
        Group-Object act_available, category |
        Sort-Object {
            $first = @($_.Group | Sort-Object {[int]$_.act_available}, category, confession_id, part)[0]
            "{0}_{1}" -f ([int]$first.act_available), [string]$first.category
        }
)

foreach ($group in $confessionGroups) {
    $groupLines = @($group.Group | Sort-Object {[int]$_.act_available}, category, confession_id, part)
    if ($groupLines.Count -eq 0) {
        continue
    }
    $first = $groupLines[0]
    $sequence++

    $batches += [pscustomobject][ordered]@{
        batch_id = "vo_batch_litany_{0:0000}" -f $sequence
        batch_type = "litany_category_run"
        act = "Act $($first.act_available)"
        speaker = "CORVIN"
        scratch_voice = "Callum"
        scratch_voice_id = "N2lVS1w4EtoT3dr4eOWO"
        cast_status = "scratch_cast"
        location = "confessions"
        knot = ""
        category = [string]$first.category
        act_available = [int]$first.act_available
        source_manifest = "docs/vo/confession_vo_manifest.json"
        line_count = $groupLines.Count
        word_count = ($groupLines | Measure-Object -Property word_count -Sum).Sum
        source_line_ids = @($groupLines | Select-Object -ExpandProperty line_id)
        context_line_ids = @($groupLines | Select-Object -ExpandProperty line_id)
        audio_paths = @($groupLines | Select-Object -ExpandProperty audio_path)
        recording_status = "unrecorded"
        generation_rule = "Generate as a category run; keep each confession immediately followed by its elaboration."
        notes = "Litany text is generated from data/confessions.json only."
    }
}

$batchSummaryRows = @(
    $batches |
        ForEach-Object {
            [pscustomobject][ordered]@{
                batch_id = $_.batch_id
                batch_type = $_.batch_type
                act = $_.act
                speaker = $_.speaker
                cast_status = $_.cast_status
                location = $_.location
                knot = $_.knot
                category = $_.category
                line_count = $_.line_count
                word_count = $_.word_count
                recording_status = $_.recording_status
            }
        }
)

$typeSummary = @(
    $batches |
        Group-Object batch_type |
        Sort-Object Name |
        ForEach-Object {
            $typeBatches = @($_.Group)
            [pscustomobject][ordered]@{
                batch_type = $_.Name
                batch_count = $typeBatches.Count
                line_count = ($typeBatches | Measure-Object -Property line_count -Sum).Sum
                word_count = ($typeBatches | Measure-Object -Property word_count -Sum).Sum
            }
        }
)

$speakerSummary = @(
    $batches |
        Group-Object speaker |
        Sort-Object Name |
        ForEach-Object {
            $speakerBatches = @($_.Group)
            [pscustomobject][ordered]@{
                speaker = $_.Name
                batch_count = $speakerBatches.Count
                line_count = ($speakerBatches | Measure-Object -Property line_count -Sum).Sum
                word_count = ($speakerBatches | Measure-Object -Property word_count -Sum).Sum
                uncast_batch_count = @($speakerBatches | Where-Object { $_.cast_status -eq "needs_cast_decision" }).Count
                blocked_batch_count = @($speakerBatches | Where-Object { $_.cast_status -notin @("scratch_cast", "needs_cast_decision") }).Count
                cast_status = if (@($speakerBatches | Where-Object { $_.cast_status -eq "needs_cast_decision" }).Count -gt 0) {
                    "needs_cast_decision"
                } elseif (@($speakerBatches | Where-Object { $_.cast_status -ne "scratch_cast" }).Count -gt 0) {
                    [string]@($speakerBatches | Where-Object { $_.cast_status -ne "scratch_cast" })[0].cast_status
                } else {
                    "scratch_cast"
                }
            }
        }
)

$metadata = [ordered]@{
    generated_from = @(
        "docs/vo/act_i_vo_line_manifest.json",
        "docs/vo/confession_vo_manifest.json"
    )
    generated_at_utc = $generatedAtUtc
    source_modified_utc = $sourceModifiedUtc
    purpose = "Recording-session batch plan for scratch/full VO. Batches preserve scene order and avoid disconnected one-line generation."
    batch_count = $batches.Count
    line_count = ($batches | Measure-Object -Property line_count -Sum).Sum
    word_count = ($batches | Measure-Object -Property word_count -Sum).Sum
    recording_status = "unrecorded"
    max_batch_word_count = ($batches | Measure-Object -Property word_count -Maximum).Maximum
    minor_speaker_decisions_source = if ($minorDecisionSourceStatus -eq "present") { "docs/vo/vo_minor_speaker_decisions.json" } else { "" }
    minor_speaker_decisions_source_status = $minorDecisionSourceStatus
    uncast_batch_count = @($batches | Where-Object { $_.cast_status -eq "needs_cast_decision" }).Count
    blocked_batch_count = @($batches | Where-Object { $_.cast_status -notin @("scratch_cast", "needs_cast_decision") }).Count
    rule_locks = @(
        "Do not generate VO line-by-line in isolation.",
        "Scene VO batches are speaker runs grouped by Ink knot and kept in source order.",
        "Litany batches keep each confession immediately followed by its elaboration.",
        "Scratch voices are timing/casting references only until commercial licensing is verified.",
        "Applied minor-speaker decisions are read from docs/vo/vo_minor_speaker_decisions.json when present.",
        "Keep the accepted Litany/Registrar duel format."
    )
    types = $typeSummary
    speakers = $speakerSummary
    batches = $batches
}

$metadata | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$batchSummaryRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$minorDecisionSourceDisplay = $minorDecisionSourceStatus
if ($minorDecisionSourceStatus -eq "present") {
    $minorDecisionSourceDisplay = "$minorDecisionSourceStatus / $($sourceModifiedUtc["docs/vo/vo_minor_speaker_decisions.json"])"
}

$mdLines = @(
    "# VO Recording Batches",
    "",
    'Generated by `tools/Export-VoRecordingBatches.ps1` from the Act I and confession VO manifests.',
    "",
    "Purpose: recording-session plan for scratch/full VO. This does not claim shipping audio exists.",
    "",
    "Generated at UTC: $generatedAtUtc",
    "",
    "Source modified UTC:",
    "- docs/vo/act_i_vo_line_manifest.json: $($sourceModifiedUtc["docs/vo/act_i_vo_line_manifest.json"])",
    "- docs/vo/confession_vo_manifest.json: $($sourceModifiedUtc["docs/vo/confession_vo_manifest.json"])",
    "- docs/vo/vo_minor_speaker_decisions.json: $minorDecisionSourceDisplay",
    "",
    "Totals:",
    "- Batches: $($metadata.batch_count)",
    "- Lines: $($metadata.line_count)",
    "- Words: $($metadata.word_count)",
    "- Max batch words: $($metadata.max_batch_word_count)",
    "- Minor-speaker decision source: $($metadata.minor_speaker_decisions_source)",
    "- Uncast batches: $($metadata.uncast_batch_count)",
    "- Blocked non-cast batches: $($metadata.blocked_batch_count)",
    "- Recording status: unrecorded",
    "",
    "Rule locks:",
    "- Do not generate VO line-by-line in isolation.",
    "- Scene VO batches are speaker runs grouped by Ink knot and kept in source order.",
    "- Litany batches keep each confession immediately followed by its elaboration.",
    "- Scratch voices are timing/casting references only until commercial licensing is verified.",
    "- Applied minor-speaker decisions are read from docs/vo/vo_minor_speaker_decisions.json when present.",
    "- Keep the accepted Litany/Registrar duel format.",
    "",
    "## Batch Type Summary",
    "",
    "| Type | Batches | Lines | Words |",
    "|---|---:|---:|---:|"
)

foreach ($type in $typeSummary) {
    $mdLines += "| $($type.batch_type) | $($type.batch_count) | $($type.line_count) | $($type.word_count) |"
}

$mdLines += ""
$mdLines += "## Speaker Summary"
$mdLines += ""
$mdLines += "| Speaker | Batches | Lines | Words | Status | Uncast batches | Blocked batches |"
$mdLines += "|---|---:|---:|---:|---|---:|---:|"
foreach ($speaker in $speakerSummary) {
    $mdLines += "| $($speaker.speaker) | $($speaker.batch_count) | $($speaker.line_count) | $($speaker.word_count) | $($speaker.cast_status) | $($speaker.uncast_batch_count) | $($speaker.blocked_batch_count) |"
}

$mdLines += ""
$mdLines += "## First 30 Batches"
$mdLines += ""
$mdLines += "| Batch | Type | Speaker | Location | Knot/category | Lines | Words | Status |"
$mdLines += "|---|---|---|---|---|---:|---:|---|"
foreach ($batch in @($batches | Select-Object -First 30)) {
    $topic = if ([string]::IsNullOrWhiteSpace([string]$batch.knot)) { [string]$batch.category } else { [string]$batch.knot }
    $mdLines += "| $($batch.batch_id) | $($batch.batch_type) | $($batch.speaker) | $($batch.location) | $topic | $($batch.line_count) | $($batch.word_count) | $($batch.recording_status) |"
}

Set-Content -LiteralPath $mdPath -Value $mdLines -Encoding UTF8

Write-Host "Exported VO recording batches JSON -> $jsonPath"
Write-Host "Exported VO recording batches CSV -> $csvPath"
Write-Host "Exported VO recording batches report -> $mdPath"
Write-Host "VO recording batches: batches=$($metadata.batch_count), lines=$($metadata.line_count), words=$($metadata.word_count), uncastBatches=$($metadata.uncast_batch_count)"
