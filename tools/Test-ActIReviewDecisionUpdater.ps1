$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$mdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$setScript = Join-Path $PSScriptRoot "Set-ActIReviewDecision.ps1"
$validateTrackerScript = Join-Path $PSScriptRoot "Validate-ActIReviewFixTracker.ps1"

foreach ($path in @($trackerPath, $mdPath, $setScript, $validateTrackerScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I review updater test input: $path"
    }
}

$originalJson = Get-Content -LiteralPath $trackerPath -Raw
$originalMd = Get-Content -LiteralPath $mdPath -Raw
$buildCommit = (& git -C $root rev-parse --short=12 HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($buildCommit)) {
    $buildCommit = "unknown"
} else {
    $buildCommit = [string]$buildCommit
}

try {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -RoomId "harbor_registry" -Decision "approved" -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Missing build commit negative control." 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Set-ActIReviewDecision should reject non-pending decisions without BuildCommit."
    }
    if (($badOutput -join "`n") -notmatch "must include -BuildCommit") {
        throw "Review updater BuildCommit negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit $buildCommit -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Approve Harbor Registry for paintover simulation; accepted Litany format preserved." -LookTargetReviewed "yes" -CorvinActionScaffoldReviewed "yes"
    if ($LASTEXITCODE -ne 0) {
        throw "Set-ActIReviewDecision approved smoke failed."
    }

    $tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
    $registry = @($tracker.rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    if ($registry.review_status -ne "approved" -or $registry.reviewer_decision -ne "approved") {
        throw "Review updater did not set Harbor Registry approved status."
    }
    if (-not [bool]$registry.approved_for_paintover) {
        throw "Review updater did not set approved_for_paintover for Harbor Registry."
    }
    if ($registry.fix_buckets.duel_format -notmatch "Accepted Litany/Registrar duel format preserved") {
        throw "Review updater did not preserve the Registrar duel-format approval note."
    }
    if ($registry.look_target_reviewed -ne "yes") {
        throw "Review updater did not persist look-target acknowledgement for Harbor Registry."
    }
    if ($registry.corvin_action_scaffold_reviewed -ne "yes") {
        throw "Review updater did not persist Corvin action scaffold acknowledgement for Harbor Registry."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateTrackerScript
    if ($LASTEXITCODE -ne 0) {
        throw "Tracker validation failed after approved smoke."
    }

    $tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
    $registry = @($tracker.rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $registry.reviewer = ""
    $registry.reviewed_at = ""
    $registry.decision_note = ""
    $tracker | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $trackerPath -Encoding UTF8

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $validateTrackerScript 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Tracker validation should reject approved rooms without reviewer metadata."
    }
    if (($badOutput -join "`n") -notmatch "must include reviewer") {
        throw "Tracker metadata negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
    $registry = @($tracker.rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $registry.reviewer = "Automated test"
    $registry.reviewed_at = "August 11"
    $registry.decision_note = "Bad date negative control."
    $tracker | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $trackerPath -Encoding UTF8

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $validateTrackerScript 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Tracker validation should reject non-ISO reviewed_at values."
    }
    if (($badOutput -join "`n") -notmatch "reviewed_at must use YYYY-MM-DD") {
        throw "Tracker reviewed_at negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit $buildCommit -Reviewer "Automated test" -ReviewedAt "August 11" -DecisionNote "Bad date negative control." -LookTargetReviewed "yes" -CorvinActionScaffoldReviewed "yes" 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Set-ActIReviewDecision should reject non-ISO ReviewedAt values."
    }
    if (($badOutput -join "`n") -notmatch "ReviewedAt must use YYYY-MM-DD") {
        throw "Review updater ReviewedAt negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit $buildCommit -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Missing look-target negative control." 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Set-ActIReviewDecision should reject non-pending decisions without LookTargetReviewed yes."
    }
    if (($badOutput -join "`n") -notmatch "LookTargetReviewed yes") {
        throw "Review updater LookTargetReviewed negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit $buildCommit -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Missing Corvin scaffold negative control." -LookTargetReviewed "yes" 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Set-ActIReviewDecision should reject non-pending decisions without CorvinActionScaffoldReviewed yes."
    }
    if (($badOutput -join "`n") -notmatch "CorvinActionScaffoldReviewed yes") {
        throw "Review updater CorvinActionScaffoldReviewed negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit $buildCommit -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Approve Harbor Registry for paintover simulation; accepted Litany format preserved." -LookTargetReviewed "yes" -CorvinActionScaffoldReviewed "yes"
    if ($LASTEXITCODE -ne 0) {
        throw "Set-ActIReviewDecision failed while restoring approved metadata after negative control."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -RoomId "grey_float" -Decision "revise_before_art" -BuildCommit $buildCommit -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Grey Float needs content staging revision before paint." -LookTargetReviewed "yes" -CorvinActionScaffoldReviewed "yes" -ContentCompliance "Steam silhouettes need stronger privacy staging before paint."
    if ($LASTEXITCODE -ne 0) {
        throw "Set-ActIReviewDecision revise smoke failed."
    }

    $tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
    $float = @($tracker.rooms | Where-Object { $_.room_id -eq "grey_float" })[0]
    if ($float.review_status -ne "revise_before_art") {
        throw "Review updater did not set Grey Float revise_before_art status."
    }
    if ([bool]$float.approved_for_paintover) {
        throw "Review updater must not approve Grey Float when marked revise_before_art."
    }
    if ($float.fix_buckets.content_compliance -notmatch "Steam silhouettes") {
        throw "Review updater did not record Grey Float content compliance fix note."
    }
    if ($float.look_target_reviewed -ne "yes") {
        throw "Review updater did not persist look-target acknowledgement for Grey Float."
    }
    if ($float.corvin_action_scaffold_reviewed -ne "yes") {
        throw "Review updater did not persist Corvin action scaffold acknowledgement for Grey Float."
    }
}
finally {
    Set-Content -LiteralPath $trackerPath -Value $originalJson -Encoding UTF8
    Set-Content -LiteralPath $mdPath -Value $originalMd -Encoding UTF8
}

Write-Host "Act I review decision updater tests passed and restored tracker artifacts, including reviewed_at negative controls."
