$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$castPlanPath = Join-Path $root "docs\vo\vo_cast_plan.json"
$audioStatusPath = Join-Path $root "docs\vo\vo_audio_asset_status.json"
$jsonPath = Join-Path $root "docs\vo\vo_commercial_readiness.json"
$mdPath = Join-Path $root "docs\vo\vo_commercial_readiness.md"

foreach ($path in @($castPlanPath, $audioStatusPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing VO commercial readiness input: $path"
    }
}

$inputPaths = [ordered]@{
    "docs/vo/vo_cast_plan.json" = $castPlanPath
    "docs/vo/vo_audio_asset_status.json" = $audioStatusPath
}
$sourceModifiedUtc = [ordered]@{}
foreach ($entry in $inputPaths.GetEnumerator()) {
    $sourceModifiedUtc[$entry.Key] = (Get-Item -LiteralPath $entry.Value).LastWriteTimeUtc.ToString("o")
}
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

$castPlan = Get-Content -LiteralPath $castPlanPath -Raw | ConvertFrom-Json
$audioStatus = Get-Content -LiteralPath $audioStatusPath -Raw | ConvertFrom-Json
$castRows = @($castPlan.cast)

$scratchCastRows = @($castRows | Where-Object { $_.cast_status -eq "scratch_cast" })
$pendingCastRows = @($castRows | Where-Object { $_.cast_status -eq "needs_cast_decision" })
$cutRewriteRows = @($castRows | Where-Object { $_.cast_status -eq "blocked_cut_or_rewrite" })
$licensingUnverifiedRows = @($scratchCastRows | Where-Object { $_.shipping_status -eq "scratch_only_licensing_unverified" })

$blockers = @(
    [ordered]@{
        id = "voice_license_unverified"
        status = "blocked"
        detail = "Scratch voice/provider commercial-game licensing has not been verified for any scratch-cast role."
    },
    [ordered]@{
        id = "ai_voice_disclosure_unreviewed"
        status = "blocked"
        detail = "Storefront, credits, and player-facing disclosure requirements have not been reviewed for AI/scratch voice use."
    },
    [ordered]@{
        id = "minor_speakers_pending"
        status = "blocked"
        detail = "$($pendingCastRows.Count) minor speakers still need cast/consolidation decisions and $($cutRewriteRows.Count) minor speakers require script cut/rewrite before full scratch generation."
    },
    [ordered]@{
        id = "final_audio_missing"
        status = "blocked"
        detail = "$([int]$audioStatus.present_count) of $([int]$audioStatus.expected_count) expected MP3 files are present; missing audio cannot count as recorded or licensed."
    },
    [ordered]@{
        id = "human_vo_lock_pending"
        status = "blocked"
        detail = "Human Act I review has not locked script cuts, pacing, or line timing before recording."
    }
)

$readiness = [ordered]@{
    generated_from = @(
        "docs/vo/vo_cast_plan.json",
        "docs/vo/vo_audio_asset_status.json"
    )
    generated_at_utc = $generatedAtUtc
    source_modified_utc = $sourceModifiedUtc
    purpose = "Commercial-readiness gate for full VO. This report keeps scratch VO useful for timing while preventing accidental shipping approval."
    status = "blocked_pending_licensing_review"
    shipping_approved = $false
    recording_status = "unrecorded"
    expected_audio_count = [int]$audioStatus.expected_count
    present_audio_count = [int]$audioStatus.present_count
    missing_audio_count = [int]$audioStatus.missing_count
    scratch_cast_count = [int]$castPlan.scratch_cast_count
    licensing_unverified_scratch_cast_count = $licensingUnverifiedRows.Count
    needs_cast_decision_count = [int]$castPlan.needs_cast_decision_count
    cut_rewrite_blocked_speaker_count = $cutRewriteRows.Count
    minor_speaker_work_blocked_count = ([int]$castPlan.needs_cast_decision_count + $cutRewriteRows.Count)
    total_recordable_lines = [int]$castPlan.total_recordable_lines
    total_words = [int]$castPlan.total_words
    blockers = $blockers
    required_evidence_before_shipping = @(
        "Written confirmation that each scratch/final voice may be used in a commercial game under the chosen provider/account terms.",
        "Credits/disclosure text reviewed for the storefront and in-game credits.",
        "Minor-speaker cast/consolidation decisions applied, and cut/rewrite rows resolved through script changes, then regenerated through the VO batch plan.",
        "Final audio files present only at expected manifest paths with no zero-byte or unplanned MP3s.",
        "Human Act I review has locked script cuts before recording."
    )
    rule_locks = @(
        "Scratch voices are timing/casting references only until commercial licensing is verified.",
        "Do not count missing audio as recorded.",
        "Do not count present audio as shippable without licensing/disclosure evidence.",
        "Do not start scratch generation for batches whose speaker remains pending or blocked for cut/rewrite.",
        "Keep the accepted Litany/Registrar duel format."
    )
}

$readiness | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# VO Commercial Readiness",
    "",
    'Generated by `tools/Export-VoCommercialReadiness.ps1` from `docs/vo/vo_cast_plan.json` and `docs/vo/vo_audio_asset_status.json`.',
    "",
    "Purpose: commercial-readiness gate for full VO. This report keeps scratch VO useful for timing while preventing accidental shipping approval.",
    "",
    "Generated at UTC: $generatedAtUtc",
    "",
    "Source modified UTC:",
    "- docs/vo/vo_cast_plan.json: $($sourceModifiedUtc["docs/vo/vo_cast_plan.json"])",
    "- docs/vo/vo_audio_asset_status.json: $($sourceModifiedUtc["docs/vo/vo_audio_asset_status.json"])",
    "",
    "Status: blocked_pending_licensing_review",
    "Shipping approved: false",
    "Recording status: unrecorded",
    "Expected audio files: $([int]$audioStatus.expected_count)",
    "Present audio files: $([int]$audioStatus.present_count)",
    "Missing audio files: $([int]$audioStatus.missing_count)",
    "Scratch-cast speakers: $([int]$castPlan.scratch_cast_count)",
    "Licensing-unverified scratch-cast speakers: $($licensingUnverifiedRows.Count)",
    "Minor speakers needing cast/consolidation: $([int]$castPlan.needs_cast_decision_count)",
    "Minor speakers blocked for cut/rewrite: $($cutRewriteRows.Count)",
    "Minor speaker work blockers: $([int]$castPlan.needs_cast_decision_count + $cutRewriteRows.Count)",
    "Recordable lines: $([int]$castPlan.total_recordable_lines)",
    "Words: $([int]$castPlan.total_words)",
    "",
    "Rule locks:",
    "- Scratch voices are timing/casting references only until commercial licensing is verified.",
    "- Do not count missing audio as recorded.",
    "- Do not count present audio as shippable without licensing/disclosure evidence.",
    "- Do not start scratch generation for batches whose speaker remains pending or blocked for cut/rewrite.",
    "- Keep the accepted Litany/Registrar duel format.",
    "",
    "## Blockers",
    "",
    "| ID | Status | Detail |",
    "|---|---|---|"
)

foreach ($blocker in $blockers) {
    $lines += "| $($blocker.id) | $($blocker.status) | $($blocker.detail) |"
}

$lines += ""
$lines += "## Required Evidence Before Shipping"
$lines += ""
foreach ($item in $readiness.required_evidence_before_shipping) {
    $lines += "- $item"
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported VO commercial readiness JSON -> $jsonPath"
Write-Host "Exported VO commercial readiness report -> $mdPath"
Write-Host "VO commercial readiness: status=blocked_pending_licensing_review, shippingApproved=False, expected=$([int]$audioStatus.expected_count), present=$([int]$audioStatus.present_count), scratchCast=$([int]$castPlan.scratch_cast_count)"
