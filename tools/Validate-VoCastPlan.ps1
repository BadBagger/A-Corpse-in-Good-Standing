$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-VoCastPlan.ps1"
$jsonPath = Join-Path $root "docs\vo\vo_cast_plan.json"
$csvPath = Join-Path $root "docs\vo\vo_cast_plan.csv"
$mdPath = Join-Path $root "docs\vo\vo_cast_plan.md"
$minorDecisionPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"
$actIManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$confessionManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$batchManifestPath = Join-Path $root "docs\vo\vo_recording_batches.json"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing VO cast plan exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "VO cast plan export failed."
}

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated VO cast plan artifact: $path"
    }
}

$plan = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$expectedGeneratedFrom = @(
    "docs/vo/act_i_vo_line_manifest.json",
    "docs/vo/confession_vo_manifest.json",
    "docs/vo/vo_recording_batches.json"
)
$sourcePaths = @{
    "docs/vo/act_i_vo_line_manifest.json" = $actIManifestPath
    "docs/vo/confession_vo_manifest.json" = $confessionManifestPath
    "docs/vo/vo_recording_batches.json" = $batchManifestPath
}

foreach ($relativePath in $expectedGeneratedFrom) {
    if ($relativePath -notin @($plan.generated_from | ForEach-Object { [string]$_ })) {
        throw "VO cast plan generated_from missing source: $relativePath"
    }
    $actualSourceStamp = [string]$plan.source_modified_utc.PSObject.Properties[$relativePath].Value
    $expectedSourceStamp = (Get-Item -LiteralPath $sourcePaths[$relativePath]).LastWriteTimeUtc.ToString("o")
    if ($actualSourceStamp -ne $expectedSourceStamp) {
        throw "VO cast plan source_modified_utc is stale or inconsistent for $relativePath."
    }
}
if ([string]::IsNullOrWhiteSpace([string]$plan.generated_at_utc)) {
    throw "VO cast plan missing generated_at_utc freshness stamp."
}
try {
    $generatedAt = [datetime]::Parse([string]$plan.generated_at_utc).ToUniversalTime()
    foreach ($relativePath in $expectedGeneratedFrom) {
        $sourceModified = [datetime]::Parse([string]$plan.source_modified_utc.PSObject.Properties[$relativePath].Value).ToUniversalTime()
        if ($generatedAt -lt $sourceModified) {
            throw "VO cast plan generated_at_utc predates source $relativePath."
        }
    }
} catch {
    throw "VO cast plan freshness stamps must be parseable UTC datetimes and not predate sources."
}

if ([int]$plan.speaker_count -ne 18) {
    throw "VO cast plan expected 18 speakers from Act I manifest, got $($plan.speaker_count)."
}
if ($rows.Count -ne [int]$plan.speaker_count) {
    throw "VO cast plan CSV row count does not match speaker_count."
}
$hasMinorDecisions = Test-Path -LiteralPath $minorDecisionPath
if (-not $hasMinorDecisions -and [int]$plan.scratch_cast_count -ne 9) {
    throw "VO cast plan expected 9 scratch-cast speakers without applied minor-speaker decisions, got $($plan.scratch_cast_count)."
}
if (-not $hasMinorDecisions -and [int]$plan.needs_cast_decision_count -ne 8) {
    throw "VO cast plan expected 8 minor speakers needing decisions without applied minor-speaker decisions, got $($plan.needs_cast_decision_count)."
}
if ($hasMinorDecisions -and ([int]$plan.scratch_cast_count -lt 9 -or [int]$plan.needs_cast_decision_count -gt 8)) {
    throw "VO cast plan applied minor-speaker decisions moved counts in the wrong direction: scratch=$($plan.scratch_cast_count), needs=$($plan.needs_cast_decision_count)."
}
if ([int]$plan.stage_direction_count -ne 1) {
    throw "VO cast plan expected 1 stage-direction speaker, got $($plan.stage_direction_count)."
}
if ([int]$plan.total_recordable_lines -ne 652) {
    throw "VO cast plan expected 652 recordable lines, got $($plan.total_recordable_lines)."
}
if ([int]$plan.total_words -ne 5206) {
    throw "VO cast plan expected 5206 words, got $($plan.total_words)."
}

$requiredColumns = @(
    "speaker",
    "character",
    "cast_status",
    "scratch_voice",
    "scratch_voice_id",
    "act_i_lines",
    "litany_lines",
    "total_recordable_lines",
    "total_words",
    "batch_count",
    "uncast_batch_count",
    "voice_direction",
    "shipping_status"
)

$seenSpeakers = @{}
foreach ($row in $rows) {
    foreach ($column in $requiredColumns) {
        if (-not ($row.PSObject.Properties.Name -contains $column)) {
            throw "VO cast plan CSV missing column: $column"
        }
    }
    if ([string]::IsNullOrWhiteSpace($row.speaker)) {
        throw "VO cast plan row has empty speaker."
    }
    if ($seenSpeakers.ContainsKey($row.speaker)) {
        throw "Duplicate speaker in VO cast plan: $($row.speaker)"
    }
    $seenSpeakers[$row.speaker] = $true
    if ($row.cast_status -notin @("scratch_cast", "needs_cast_decision", "not_cast_stage_direction", "blocked_cut_or_rewrite")) {
        throw "Invalid VO cast status '$($row.cast_status)' for $($row.speaker)."
    }
    if ($row.cast_status -eq "scratch_cast") {
        if ([string]::IsNullOrWhiteSpace($row.scratch_voice) -or [string]::IsNullOrWhiteSpace($row.scratch_voice_id)) {
            throw "Scratch-cast speaker missing voice or voice id: $($row.speaker)"
        }
        if ($row.shipping_status -ne "scratch_only_licensing_unverified") {
            throw "Scratch-cast speaker must remain licensing-unverified: $($row.speaker)"
        }
    }
    if ($row.cast_status -eq "needs_cast_decision" -and $row.shipping_status -ne "blocked_pending_cast_decision") {
        throw "Pending minor speaker must stay blocked: $($row.speaker)"
    }
    if ($row.cast_status -eq "blocked_cut_or_rewrite" -and $row.shipping_status -ne "blocked_pending_script_or_cast_work") {
        throw "Cut/rewrite speaker must stay blocked for script work: $($row.speaker)"
    }
}

$corvin = @($rows | Where-Object { $_.speaker -eq "CORVIN" })[0]
if ($null -eq $corvin) {
    throw "VO cast plan missing CORVIN."
}
if ([int]$corvin.litany_lines -ne 124 -or [int]$corvin.total_recordable_lines -ne 400) {
    throw "VO cast plan must bind 124 Litany lines and 400 total recordable lines to Corvin."
}
if ([int]$corvin.act_i_lines -ne 276) {
    throw "VO cast plan expected 276 Act I Corvin lines, got $($corvin.act_i_lines)."
}

foreach ($speaker in @("ADELA", "BOOT_SELLER", "BOY", "CLERK", "MAN", "MARIN", "MONGER", "WOMAN")) {
    $row = @($rows | Where-Object { $_.speaker -eq $speaker })[0]
    if ($null -eq $row) {
        throw "VO cast plan missing pending minor speaker: $speaker"
    }
    if (-not $hasMinorDecisions -and $row.cast_status -ne "needs_cast_decision") {
        throw "Minor speaker should still need cast/consolidation decision: $speaker"
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "VO Cast Plan",
    "Generated at UTC: $($plan.generated_at_utc)",
    "Source modified UTC:",
    "docs/vo/act_i_vo_line_manifest.json: $($plan.source_modified_utc.PSObject.Properties['docs/vo/act_i_vo_line_manifest.json'].Value)",
    "docs/vo/confession_vo_manifest.json: $($plan.source_modified_utc.PSObject.Properties['docs/vo/confession_vo_manifest.json'].Value)",
    "docs/vo/vo_recording_batches.json: $($plan.source_modified_utc.PSObject.Properties['docs/vo/vo_recording_batches.json'].Value)",
    "manifest-driven scratch VO cast plan",
    "Shipping status: scratch_only_licensing_unverified",
    "Scratch voices are timing/casting references only until commercial licensing is verified.",
    "Do not generate VO line-by-line in isolation.",
    "Litany confession and elaboration lines stay adjacent and keyed by confession id.",
    "Do not start scratch generation for batches whose speaker remains pending.",
    "Keep the accepted Litany/Registrar duel format.",
    "CORVIN",
    "No wet/dead vocal effect",
    "KANE",
    "Warm recruiter, not a monster"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "VO cast plan report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "VO cast plan report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "VO cast plan report must stay ASCII-only."
}

Write-Host "VO cast plan validation passed: speakers=$($plan.speaker_count), scratchCast=$($plan.scratch_cast_count), needsDecision=$($plan.needs_cast_decision_count), lines=$($plan.total_recordable_lines)."
