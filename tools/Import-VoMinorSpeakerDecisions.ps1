param(
    [Parameter(Mandatory=$true)][string]$InputCsv,
    [switch]$DryRun,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

if (-not $DryRun -and -not $Apply) {
    throw "Choose -DryRun or -Apply."
}
if ($DryRun -and $Apply) {
    throw "Choose only one mode: -DryRun or -Apply."
}

$root = Split-Path -Parent $PSScriptRoot
$batchManifestPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$actManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$decisionPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"
$reportPath = Join-Path $root "docs\vo\vo_minor_speaker_decision_import_report.md"
$resolvedInput = if ([System.IO.Path]::IsPathRooted($InputCsv)) { $InputCsv } else { Join-Path $root $InputCsv }

foreach ($path in @($batchManifestPath, $actManifestPath, $resolvedInput)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO minor speaker decision import input: $path"
    }
}

$batchManifest = Get-Content -LiteralPath $batchManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$actManifest = Get-Content -LiteralPath $actManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$batches = @($batchManifest.batches | ForEach-Object { $_ })
$uncastSpeakers = @(
    $batches |
        Where-Object { $_.cast_status -eq "needs_cast_decision" } |
        Select-Object -ExpandProperty speaker -Unique |
        Sort-Object
)
$castSpeakers = @(
    $actManifest.speakers |
        Where-Object { $_.cast_status -eq "scratch_cast" } |
        Select-Object -ExpandProperty speaker
)

$rows = @(Import-Csv -LiteralPath $resolvedInput)
$allowed = @("pending", "cast", "consolidate", "cut_or_rewrite")
if ($rows.Count -ne $uncastSpeakers.Count) {
    throw "VO minor speaker import expected $($uncastSpeakers.Count) CSV rows, got $($rows.Count)."
}

$seen = @{}
$incomingCastSpeakers = @()
foreach ($row in $rows) {
    $speaker = [string]$row.speaker
    if ([string]::IsNullOrWhiteSpace($speaker)) {
        throw "VO minor speaker CSV has a row without speaker."
    }
    if ($seen.ContainsKey($speaker)) {
        throw "VO minor speaker CSV contains duplicate speaker: $speaker"
    }
    $seen[$speaker] = $true
    if ($speaker -notin $uncastSpeakers) {
        throw "VO minor speaker CSV has unknown/unexpected speaker: $speaker"
    }
    $decision = [string]$row.decision
    if ([string]::IsNullOrWhiteSpace($decision)) {
        $decision = "pending"
    }
    if ($decision -notin $allowed) {
        throw "Speaker $speaker has invalid decision '$decision'. Allowed: $($allowed -join ', ')"
    }
    if ($decision -eq "cast") {
        foreach ($field in @("cast_as", "scratch_voice", "scratch_voice_id")) {
            if ([string]::IsNullOrWhiteSpace([string]$row.$field)) {
                throw "Speaker $speaker marked cast must include $field."
            }
        }
        $incomingCastSpeakers += $speaker
    }
}

foreach ($speaker in $uncastSpeakers) {
    if (-not $seen.ContainsKey($speaker)) {
        throw "VO minor speaker CSV missing speaker: $speaker"
    }
}

$validConsolidationTargets = @($castSpeakers + $incomingCastSpeakers | Sort-Object -Unique)
$changes = @()
foreach ($row in $rows) {
    $speaker = [string]$row.speaker
    $decision = [string]$row.decision
    if ([string]::IsNullOrWhiteSpace($decision)) { $decision = "pending" }

    if ($decision -eq "consolidate") {
        $target = [string]$row.consolidate_into
        if ([string]::IsNullOrWhiteSpace($target)) {
            throw "Speaker $speaker marked consolidate must include consolidate_into."
        }
        if ($target -notin $validConsolidationTargets) {
            throw "Speaker $speaker consolidates into unknown or uncast target '$target'."
        }
    }
    if ($decision -ne "pending" -and [string]::IsNullOrWhiteSpace([string]$row.notes)) {
        throw "Speaker $speaker marked $decision must include notes explaining the casting, consolidation, or script-change rationale."
    }

    $speakerBatches = @($batches | Where-Object { $_.speaker -eq $speaker -and $_.cast_status -eq "needs_cast_decision" })
    $changes += [pscustomobject][ordered]@{
        speaker = $speaker
        decision = $decision
        cast_as = [string]$row.cast_as
        scratch_voice = [string]$row.scratch_voice
        scratch_voice_id = [string]$row.scratch_voice_id
        consolidate_into = [string]$row.consolidate_into
        notes = [string]$row.notes
        affected_batches = $speakerBatches.Count
        line_count = ($speakerBatches | Measure-Object -Property line_count -Sum).Sum
        word_count = ($speakerBatches | Measure-Object -Property word_count -Sum).Sum
    }
}

if ($Apply) {
    $decisionArtifact = [ordered]@{
        generated_from = $InputCsv
        purpose = "Durable source of truth for applied minor-speaker VO casting, consolidation, and cut/rewrite decisions."
        decision_count = $changes.Count
        applied_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
        rule_locks = @(
            "Regenerate VO batches from this decision file; do not hand-edit generated batch manifests.",
            "Do not start scratch generation for batches whose speaker remains pending.",
            "Cut/rewrite decisions remain blocked until script changes are made."
        )
        decisions = $changes
    }
    $decisionArtifact | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $decisionPath -Encoding UTF8
}

$pendingCount = @($changes | Where-Object { $_.decision -eq "pending" }).Count
$castCount = @($changes | Where-Object { $_.decision -eq "cast" }).Count
$consolidateCount = @($changes | Where-Object { $_.decision -eq "consolidate" }).Count
$cutCount = @($changes | Where-Object { $_.decision -eq "cut_or_rewrite" }).Count
$mode = if ($Apply) { "apply" } else { "dry_run" }

$lines = @(
    "# VO Minor Speaker Decision Import Report",
    "",
    "Mode: $mode",
    "Input CSV: ``$InputCsv``",
    "Decision source: ``docs/vo/vo_minor_speaker_decisions.json``",
    "Rows: $($rows.Count)",
    "Pending: $pendingCount",
    "Cast: $castCount",
    "Consolidate: $consolidateCount",
    "Cut or rewrite: $cutCount",
    "",
    "Rule locks:",
    "- Regenerate VO batches from `docs/vo/vo_minor_speaker_decisions.json`; do not hand-edit generated batch manifests.",
    "- Do not start scratch generation for batches whose speaker remains pending.",
    "- Every non-pending minor-speaker decision requires notes explaining the rationale.",
    "- Do not assign narrator/audiobook voices to minor character parts by default.",
    "- Keep the accepted Litany/Registrar duel format.",
    "",
    "| Speaker | Decision | Batches | Lines | Words |",
    "|---|---|---:|---:|---:|"
)
foreach ($change in $changes) {
    $lines += "| $($change.speaker) | $($change.decision) | $($change.affected_batches) | $($change.line_count) | $($change.word_count) |"
}

Set-Content -LiteralPath $reportPath -Value $lines -Encoding UTF8

Write-Host "VO minor speaker decision import $mode passed: pending=$pendingCount, cast=$castCount, consolidate=$consolidateCount, cutOrRewrite=$cutCount."
Write-Host "Import report -> $reportPath"
