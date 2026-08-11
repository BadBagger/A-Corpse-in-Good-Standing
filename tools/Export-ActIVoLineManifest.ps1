$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$inkDir = Join-Path $root "ink"
$outDir = Join-Path $root "docs\vo"
$jsonPath = Join-Path $outDir "act_i_vo_line_manifest.json"
$csvPath = Join-Path $outDir "act_i_vo_line_manifest.csv"
$mdPath = Join-Path $outDir "act_i_vo_line_manifest.md"

if (-not (Test-Path -LiteralPath $inkDir)) {
    throw "Missing Ink directory: $inkDir"
}
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$castBySpeaker = @{
    CORVIN = @{ character = "Corvin Vale"; voice = "Callum"; voice_id = "N2lVS1w4EtoT3dr4eOWO"; cast_status = "scratch_cast" }
    TOMAS = @{ character = "Tomas"; voice = "Roger"; voice_id = "CwhRBWXzGAHq8TQ4Fs17"; cast_status = "scratch_cast" }
    SABINE = @{ character = "Sabine Croix"; voice = "Charlotte"; voice_id = "XB0fDUnXU5powFXDhCwa"; cast_status = "scratch_cast" }
    KANE = @{ character = "Ossuary Kane"; voice = "Thomas"; voice_id = "GBv7mTt0atIp3Br8iCZE"; cast_status = "scratch_cast" }
    JUNO = @{ character = "Juno Ash"; voice = "Domi"; voice_id = "AZnzlk1XvdvUeBnXmlld"; cast_status = "scratch_cast" }
    TEODOR = @{ character = "Brother Teodor"; voice = "Eric"; voice_id = "cjVigY5qzO86Huf0OWal"; cast_status = "scratch_cast" }
    REGISTRAR = @{ character = "The Registrar"; voice = "Alice"; voice_id = "Xb7hH8MSUJpSbSDYk0k2"; cast_status = "scratch_cast" }
    CHANDLER = @{ character = "Bone Chandler"; voice = "Will"; voice_id = "bIHbv24MWmeRgasZH58o"; cast_status = "scratch_cast" }
    PROSPER = @{ character = "Half-Coin Prosper"; voice = "Bill"; voice_id = "pqHfZKP75CvOlQylNhV4"; cast_status = "scratch_cast" }
}

function Get-WordCount {
    param([string]$Text)
    $matches = [regex]::Matches($Text, "[A-Za-z0-9']+")
    return $matches.Count
}

$voRows = @()
$sequence = 0

foreach ($inkFile in Get-ChildItem -LiteralPath $inkDir -File -Filter "*.ink" | Sort-Object Name) {
    if ($inkFile.Name -eq "confessions.ink") {
        continue
    }

    $relativeFile = "ink/$($inkFile.Name)"
    $currentKnot = ""
    $currentLocation = ""
    $pendingSpeaker = $null
    $rawLines = Get-Content -LiteralPath $inkFile.FullName

    for ($i = 0; $i -lt $rawLines.Count; $i++) {
        $lineNumber = $i + 1
        $raw = [string]$rawLines[$i]
        $trimmed = $raw.Trim()

        if ($trimmed -match "^===\s*([A-Za-z0-9_]+)\s*===") {
            $currentKnot = $Matches[1]
            $currentLocation = ""
            $pendingSpeaker = $null
            continue
        }
        if ($trimmed -match "^#\s*location:([A-Za-z0-9_]+)") {
            $currentLocation = $Matches[1]
            continue
        }
        if ($trimmed -match "^#\s*speaker:([A-Z0-9_]+)") {
            $pendingSpeaker = $Matches[1]
            continue
        }
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#") -or $trimmed.StartsWith("~") -or $trimmed.StartsWith("->") -or $trimmed.StartsWith("VAR ") -or $trimmed.StartsWith("LIST ") -or $trimmed.StartsWith("INCLUDE ") -or $trimmed.StartsWith("//")) {
            continue
        }
        if ($null -eq $pendingSpeaker) {
            continue
        }

        $sequence++
        $speaker = $pendingSpeaker
        $cast = $castBySpeaker[$speaker]
        $recordingScope = "vo_line"
        $castStatus = "needs_cast_decision"
        $character = ""
        $voice = ""
        $voiceId = ""

        if ($speaker -eq "NARRATION") {
            $recordingScope = "stage_direction_review"
            $castStatus = "not_cast_stage_direction"
            $character = "Narration"
        } elseif ($null -ne $cast) {
            $castStatus = $cast.cast_status
            $character = $cast.character
            $voice = $cast.voice
            $voiceId = $cast.voice_id
        }

        $lineId = "vo_act_i_{0:0000}" -f $sequence
        $audioPath = "vo/act_i/$currentLocation/$($currentKnot)_$('{0:000}' -f $sequence)_$($speaker.ToLowerInvariant()).mp3"
        if ([string]::IsNullOrWhiteSpace($currentLocation)) {
            $audioPath = "vo/act_i/unlocated/$($currentKnot)_$('{0:000}' -f $sequence)_$($speaker.ToLowerInvariant()).mp3"
        }

        $voRows += [pscustomobject][ordered]@{
            line_id = $lineId
            act = "Act I"
            source_file = $relativeFile
            line_number = $lineNumber
            source_ref = "$relativeFile`:$lineNumber"
            knot = $currentKnot
            location = $currentLocation
            speaker = $speaker
            character = $character
            text = $trimmed
            word_count = Get-WordCount -Text $trimmed
            recording_scope = $recordingScope
            cast_status = $castStatus
            scratch_voice = $voice
            scratch_voice_id = $voiceId
            audio_path = $audioPath
            recording_status = "unrecorded"
        }

        $pendingSpeaker = $null
    }
}

$lineArray = @($voRows)
$speakerSummary = @(
    $lineArray |
        Group-Object speaker |
        Sort-Object Name |
        ForEach-Object {
            $speaker = $_.Name
            $speakerLines = @($_.Group)
            $cast = $castBySpeaker[$speaker]
            $castStatus = "needs_cast_decision"
            $character = ""
            $voice = ""
            if ($speaker -eq "NARRATION") {
                $castStatus = "not_cast_stage_direction"
                $character = "Narration"
            } elseif ($null -ne $cast) {
                $castStatus = $cast.cast_status
                $character = $cast.character
                $voice = $cast.voice
            }
            [pscustomobject][ordered]@{
                speaker = $speaker
                character = $character
                line_count = $speakerLines.Count
                word_count = ($speakerLines | Measure-Object -Property word_count -Sum).Sum
                recording_scope = if ($speaker -eq "NARRATION") { "stage_direction_review" } else { "vo_line" }
                cast_status = $castStatus
                scratch_voice = $voice
            }
        }
)

$metadata = [ordered]@{
    generated_from = @("ink/prologue.ink")
    purpose = "Act I VO planning manifest generated from Ink speaker tags. This is a recording/editing plan, not a shipping VO claim."
    line_count = $lineArray.Count
    vo_line_count = @($lineArray | Where-Object { $_.recording_scope -eq "vo_line" }).Count
    stage_direction_count = @($lineArray | Where-Object { $_.recording_scope -eq "stage_direction_review" }).Count
    speaker_count = $speakerSummary.Count
    uncast_speaker_count = @($speakerSummary | Where-Object { $_.cast_status -eq "needs_cast_decision" }).Count
    recording_status = "unrecorded"
    rule_locks = @(
        "Dialogue lines are generated from Ink; do not duplicate confession text here.",
        "Confession VO remains keyed by data/confessions.json ids.",
        "Scratch voices are timing/casting references only until commercial licensing is verified.",
        "Keep the accepted Litany/Registrar duel format."
    )
    speakers = $speakerSummary
    lines = $lineArray
}

$metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$lineArray | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$totalWords = ($lineArray | Measure-Object -Property word_count -Sum).Sum
$voWords = ($lineArray | Where-Object { $_.recording_scope -eq "vo_line" } | Measure-Object -Property word_count -Sum).Sum
$stageWords = ($lineArray | Where-Object { $_.recording_scope -eq "stage_direction_review" } | Measure-Object -Property word_count -Sum).Sum
$uncastSpeakers = @($speakerSummary | Where-Object { $_.cast_status -eq "needs_cast_decision" } | Select-Object -ExpandProperty speaker)

$mdLines = @(
    "# Act I VO Line Manifest",
    "",
    'Generated by `tools/Export-ActIVoLineManifest.ps1` from Ink speaker tags.',
    "",
    "Purpose: recording/editing plan for full VO timing. This does not claim shipping audio exists.",
    "",
    "Totals:",
    "- Lines: $($lineArray.Count)",
    "- Words: $totalWords",
    "- VO lines: $($metadata.vo_line_count) ($voWords words)",
    "- Stage-direction review lines: $($metadata.stage_direction_count) ($stageWords words)",
    "- Speakers: $($speakerSummary.Count)",
    "- Speakers needing cast decision: $($metadata.uncast_speaker_count)",
    "",
    "Rule locks:",
    "- Dialogue lines are generated from Ink; do not duplicate confession text here.",
    "- Confession VO remains keyed by `data/confessions.json` ids.",
    "- Scratch voices are timing/casting references only until commercial licensing is verified.",
    "- Keep the accepted Litany/Registrar duel format.",
    "",
    "## Speaker Summary",
    "",
    "| Speaker | Character | Lines | Words | Scope | Cast status | Scratch voice |",
    "|---|---|---:|---:|---|---|---|"
)

foreach ($speaker in $speakerSummary) {
    $mdLines += "| $($speaker.speaker) | $($speaker.character) | $($speaker.line_count) | $($speaker.word_count) | $($speaker.recording_scope) | $($speaker.cast_status) | $($speaker.scratch_voice) |"
}

$mdLines += ""
$mdLines += "## Uncast Speaker Decisions"
$mdLines += ""
if ($uncastSpeakers.Count -eq 0) {
    $mdLines += "- None."
} else {
    foreach ($speaker in $uncastSpeakers) {
        $mdLines += "- ``$speaker`` needs a casting or consolidation decision before final recording."
    }
}

$mdLines += ""
$mdLines += "## First 20 Lines"
$mdLines += ""
$mdLines += "| ID | Source | Speaker | Words | Status | Text |"
$mdLines += "|---|---|---|---:|---|---|"
foreach ($line in @($lineArray | Select-Object -First 20)) {
    $sourceRef = [string]$line.source_ref
    $safeText = $line.text.Replace("|", "\|")
    $mdLines += "| $($line.line_id) | ``$sourceRef`` | $($line.speaker) | $($line.word_count) | $($line.recording_status) | $safeText |"
}

Set-Content -LiteralPath $mdPath -Value $mdLines -Encoding UTF8

Write-Host "Exported Act I VO line manifest JSON -> $jsonPath"
Write-Host "Exported Act I VO line manifest CSV -> $csvPath"
Write-Host "Exported Act I VO line manifest report -> $mdPath"
Write-Host "Act I VO line manifest: lines=$($lineArray.Count), speakers=$($speakerSummary.Count), uncast=$($metadata.uncast_speaker_count), words=$totalWords"
