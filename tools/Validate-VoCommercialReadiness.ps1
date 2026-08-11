$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$castPlanValidator = Join-Path $PSScriptRoot "Validate-VoCastPlan.ps1"
$audioStatusValidator = Join-Path $PSScriptRoot "Validate-VoAudioAssetStatus.ps1"
$exportScript = Join-Path $PSScriptRoot "Export-VoCommercialReadiness.ps1"
$jsonPath = Join-Path $root "docs\vo\vo_commercial_readiness.json"
$mdPath = Join-Path $root "docs\vo\vo_commercial_readiness.md"
$decisionJsonPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions.json"

foreach ($script in @($castPlanValidator, $audioStatusValidator, $exportScript)) {
    if (-not (Test-Path -LiteralPath $script)) {
        throw "Missing VO commercial readiness dependency: $script"
    }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $castPlanValidator
if ($LASTEXITCODE -ne 0) {
    throw "VO cast plan validation failed before commercial readiness export."
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $audioStatusValidator
if ($LASTEXITCODE -ne 0) {
    throw "VO audio asset status validation failed before commercial readiness export."
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "VO commercial readiness export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing generated VO commercial readiness artifact: $path"
    }
}

$readiness = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$blockers = @($readiness.blockers)
$hasAppliedMinorSpeakerDecisions = Test-Path -LiteralPath $decisionJsonPath
$expectedGeneratedFrom = @(
    "docs/vo/vo_cast_plan.json",
    "docs/vo/vo_audio_asset_status.json"
)
$sourcePaths = @{
    "docs/vo/vo_cast_plan.json" = Join-Path $root "docs\vo\vo_cast_plan.json"
    "docs/vo/vo_audio_asset_status.json" = Join-Path $root "docs\vo\vo_audio_asset_status.json"
}

foreach ($relativePath in $expectedGeneratedFrom) {
    if ($relativePath -notin @($readiness.generated_from | ForEach-Object { [string]$_ })) {
        throw "VO commercial readiness generated_from missing source: $relativePath"
    }
    $actualSourceStamp = [string]$readiness.source_modified_utc.PSObject.Properties[$relativePath].Value
    $expectedSourceStamp = (Get-Item -LiteralPath $sourcePaths[$relativePath]).LastWriteTimeUtc.ToString("o")
    if ($actualSourceStamp -ne $expectedSourceStamp) {
        throw "VO commercial readiness source_modified_utc is stale or inconsistent for $relativePath."
    }
}
if ([string]::IsNullOrWhiteSpace([string]$readiness.generated_at_utc)) {
    throw "VO commercial readiness missing generated_at_utc freshness stamp."
}
try {
    $generatedAt = [datetime]::Parse([string]$readiness.generated_at_utc).ToUniversalTime()
    foreach ($relativePath in $expectedGeneratedFrom) {
        $sourceModified = [datetime]::Parse([string]$readiness.source_modified_utc.PSObject.Properties[$relativePath].Value).ToUniversalTime()
        if ($generatedAt -lt $sourceModified) {
            throw "VO commercial readiness generated_at_utc predates source $relativePath."
        }
    }
} catch {
    throw "VO commercial readiness freshness stamps must be parseable UTC datetimes and not predate sources."
}

if ($readiness.status -ne "blocked_pending_licensing_review") {
    throw "VO commercial readiness must remain blocked_pending_licensing_review until licensing evidence exists, got $($readiness.status)."
}
if ([bool]$readiness.shipping_approved) {
    throw "VO commercial readiness must not mark scratch VO as shipping-approved."
}
if ($readiness.recording_status -ne "unrecorded") {
    throw "VO commercial readiness expected unrecorded status, got $($readiness.recording_status)."
}
if ([int]$readiness.expected_audio_count -ne 652 -or [int]$readiness.present_audio_count -ne 0 -or [int]$readiness.missing_audio_count -ne 652) {
    throw "VO commercial readiness audio counts drifted: expected=$($readiness.expected_audio_count), present=$($readiness.present_audio_count), missing=$($readiness.missing_audio_count)."
}
if ([int]$readiness.licensing_unverified_scratch_cast_count -ne [int]$readiness.scratch_cast_count) {
    throw "VO commercial readiness expected all scratch-cast speakers to remain licensing-unverified."
}
if ([int]$readiness.needs_cast_decision_count + [int]$readiness.cut_rewrite_blocked_speaker_count -ne [int]$readiness.minor_speaker_work_blocked_count) {
    throw "VO commercial readiness minor speaker blocked counts do not add up."
}
if (-not $hasAppliedMinorSpeakerDecisions) {
    if ([int]$readiness.scratch_cast_count -ne 9) {
        throw "Baseline VO commercial readiness expected 9 scratch-cast speakers, got $($readiness.scratch_cast_count)."
    }
    if ([int]$readiness.needs_cast_decision_count -ne 8) {
        throw "Baseline VO commercial readiness expected 8 pending minor speaker decisions, got $($readiness.needs_cast_decision_count)."
    }
    if ([int]$readiness.cut_rewrite_blocked_speaker_count -ne 0 -or [int]$readiness.minor_speaker_work_blocked_count -ne 8) {
        throw "Baseline VO commercial readiness expected 0 cut/rewrite speakers and 8 total minor-speaker blockers."
    }
}
if ([int]$readiness.total_recordable_lines -ne 652 -or [int]$readiness.total_words -ne 5206) {
    throw "VO commercial readiness line/word counts drifted."
}
if ($blockers.Count -ne 5) {
    throw "VO commercial readiness expected 5 blockers, got $($blockers.Count)."
}
foreach ($blocker in $blockers) {
    if ($blocker.status -ne "blocked") {
        throw "VO commercial readiness blocker must be blocked: $($blocker.id)"
    }
}

$requiredBlockers = @(
    "voice_license_unverified",
    "ai_voice_disclosure_unreviewed",
    "minor_speakers_pending",
    "final_audio_missing",
    "human_vo_lock_pending"
)
foreach ($id in $requiredBlockers) {
    if (-not @($blockers | Where-Object { $_.id -eq $id }).Count) {
        throw "VO commercial readiness missing blocker: $id"
    }
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "VO Commercial Readiness",
    "Generated at UTC: $($readiness.generated_at_utc)",
    "Source modified UTC:",
    "docs/vo/vo_cast_plan.json: $($readiness.source_modified_utc.PSObject.Properties['docs/vo/vo_cast_plan.json'].Value)",
    "docs/vo/vo_audio_asset_status.json: $($readiness.source_modified_utc.PSObject.Properties['docs/vo/vo_audio_asset_status.json'].Value)",
    "Status: blocked_pending_licensing_review",
    "Shipping approved: false",
    "Scratch voices are timing/casting references only until commercial licensing is verified.",
    "Do not count present audio as shippable without licensing/disclosure evidence.",
    "Do not start scratch generation for batches whose speaker remains pending or blocked for cut/rewrite.",
    "Keep the accepted Litany/Registrar duel format.",
    "voice_license_unverified",
    "ai_voice_disclosure_unreviewed",
    "minor_speakers_pending",
    "final_audio_missing",
    "human_vo_lock_pending",
    "Written confirmation that each scratch/final voice may be used in a commercial game",
    "Minor speakers needing cast/consolidation: $($readiness.needs_cast_decision_count)",
    "Minor speakers blocked for cut/rewrite: $($readiness.cut_rewrite_blocked_speaker_count)",
    "Minor speaker work blockers: $($readiness.minor_speaker_work_blocked_count)"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "VO commercial readiness report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "VO commercial readiness report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[\x00-\x08\x0B\x0C\x0E-\x1F]") {
    throw "VO commercial readiness report contains illegal control characters."
}

Write-Host "VO commercial readiness validation passed: status=$($readiness.status), shippingApproved=$($readiness.shipping_approved), blockers=$($blockers.Count)."
