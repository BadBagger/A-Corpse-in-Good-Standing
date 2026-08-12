$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$mdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$templateScript = Join-Path $PSScriptRoot "Export-ActIReviewDecisionTemplate.ps1"
$importScript = Join-Path $PSScriptRoot "Import-ActIReviewDecisions.ps1"
$validateStartGateScript = Join-Path $PSScriptRoot "Validate-ActIPaintoverStartGate.ps1"
$fixturePath = Join-Path $root "docs\playtest\results\act_i_review_decision_import_test.csv"

foreach ($path in @($trackerPath, $mdPath, $templateScript, $importScript, $validateStartGateScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I batch import test input: $path"
    }
}

$originalJson = Get-Content -LiteralPath $trackerPath -Raw
$originalMd = Get-Content -LiteralPath $mdPath -Raw

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $templateScript
    if ($LASTEXITCODE -ne 0) {
        throw "Review decision template export failed."
    }

    $tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
    $buildCommit = (& git -C $root rev-parse --short=12 HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($buildCommit)) {
        $buildCommit = "unknown"
    } else {
        $buildCommit = [string]$buildCommit
    }
    $rows = @()
    foreach ($room in @($tracker.rooms)) {
        $decision = "pending_review"
        $layout = ""
        $content = ""
        $duelFormat = ""
        if ($room.room_id -eq "harbor_registry") {
            $decision = "approved"
            $duelFormat = "Accepted Litany/Registrar duel format preserved; no second confession-spend UI added."
        }
        if ($room.room_id -eq "grey_float") {
            $decision = "revise_before_art"
            $content = "Steam silhouettes need stronger privacy staging before paint."
        }
        $reviewer = if ($decision -eq "pending_review") { "" } else { "Automated test" }
        $reviewedAt = if ($decision -eq "pending_review") { "" } else { "2026-08-11" }
        $decisionNote = if ($decision -eq "pending_review") { "" } elseif ($decision -eq "approved") { "Approve Harbor Registry for batch-import simulation; accepted Litany format preserved." } else { "Grey Float needs content staging revision before paint." }
        $rows += [pscustomobject][ordered]@{
            room_id = $room.room_id
            room_code = $room.room_code
            title = $room.title
            build_commit = $buildCommit
            decision = $decision
            reviewer = $reviewer
            reviewed_at = $reviewedAt
            decision_note = $decisionNote
            layout = $layout
            hotspot_readability = ""
            walk_band = ""
            palette_lighting = ""
            content_compliance = $content
            duel_format = $duelFormat
            vo_timing_or_pacing = ""
            risk_tags = (@($room.risk_tags) -join ";")
            critical_hotspots = (@($room.critical_hotspots | ForEach-Object { "$($_.name):$($_.review_status)" }) -join ";")
            close_pairs = (@($room.close_pair_review | ForEach-Object { "$($_.pair):$($_.review_status)" }) -join ";")
        }
    }
    $rows | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8

    $badRows = @($rows | ForEach-Object { $_.PSObject.Copy() })
    $badRegistry = @($badRows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $badRegistry.build_commit = ""
    $badRows | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -DryRun 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Review decision batch import should reject non-pending rows without build_commit."
    }
    if (($badOutput -join "`n") -notmatch "must include build_commit") {
        throw "Review decision batch import build_commit negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $badRows = @($rows | ForEach-Object { $_.PSObject.Copy() })
    $badRegistry = @($badRows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $badRegistry.reviewer = ""
    $badRows | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -DryRun 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Review decision batch import should reject non-pending rows without reviewer metadata."
    }
    if (($badOutput -join "`n") -notmatch "must include reviewer") {
        throw "Review decision batch import metadata negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $badRows = @($rows | ForEach-Object { $_.PSObject.Copy() })
    $badRegistry = @($badRows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $badRegistry.reviewed_at = "August 11"
    $badRows | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -DryRun 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Review decision batch import should reject non-ISO reviewed_at values."
    }
    if (($badOutput -join "`n") -notmatch "reviewed_at must use YYYY-MM-DD") {
        throw "Review decision batch import reviewed_at negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $badRows = @($rows | ForEach-Object { $_.PSObject.Copy() })
    $badRows |
        Select-Object room_id,room_code,title,build_commit,decision,reviewer,reviewed_at,decision_note,layout,hotspot_readability,walk_band,palette_lighting,content_compliance,vo_timing_or_pacing,risk_tags,critical_hotspots,close_pairs |
        Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -DryRun 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Review decision batch import should reject CSV files missing required columns."
    }
    if (($badOutput -join "`n") -notmatch "missing required column: duel_format") {
        throw "Review decision batch import missing-column negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $badRows = @($rows | ForEach-Object { $_.PSObject.Copy() })
    $badFloat = @($badRows | Where-Object { $_.room_id -eq "grey_float" })[0]
    $badFloat.content_compliance = ""
    $badFloat.layout = "Layout revision note keeps the revise decision from failing for missing fix buckets."
    $badRows | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -DryRun 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Review decision batch import should reject Grey Float non-pending rows without content compliance."
    }
    if (($badOutput -join "`n") -notmatch "hard-R content risk") {
        throw "Review decision batch import hard-R negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $badRows = @($rows | ForEach-Object { $_.PSObject.Copy() })
    $badRegistry = @($badRows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $badRegistry.duel_format = ""
    $badRows | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -DryRun 2>&1
    $badExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    if ($badExit -eq 0) {
        throw "Review decision batch import should reject Harbor Registry non-pending rows without duel-format review proof."
    }
    if (($badOutput -join "`n") -notmatch "duel-format risk") {
        throw "Review decision batch import duel-format negative control failed for the wrong reason: $($badOutput -join ' ')"
    }

    $rows | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding UTF8

    & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -DryRun
    if ($LASTEXITCODE -ne 0) {
        throw "Review decision batch import dry-run failed."
    }
    $postDryRun = Get-Content -LiteralPath $trackerPath -Raw
    if ($postDryRun -ne $originalJson) {
        throw "Review decision dry-run changed the tracker JSON."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $importScript -InputCsv "docs\playtest\results\act_i_review_decision_import_test.csv" -Apply
    if ($LASTEXITCODE -ne 0) {
        throw "Review decision batch import apply failed."
    }

    $tracker = Get-Content -LiteralPath $trackerPath -Raw | ConvertFrom-Json
    $registry = @($tracker.rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $float = @($tracker.rooms | Where-Object { $_.room_id -eq "grey_float" })[0]
    if ($registry.review_status -ne "approved" -or -not [bool]$registry.approved_for_paintover) {
        throw "Batch import did not approve Harbor Registry."
    }
    if ($registry.fix_buckets.duel_format -notmatch "Accepted Litany/Registrar duel format preserved") {
        throw "Batch import did not add Registrar duel-format lock note."
    }
    if ($float.review_status -ne "revise_before_art" -or [bool]$float.approved_for_paintover) {
        throw "Batch import did not leave Grey Float blocked for revision."
    }
    if ($float.fix_buckets.content_compliance -notmatch "Steam silhouettes") {
        throw "Batch import did not carry Grey Float content note."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateStartGateScript
    if ($LASTEXITCODE -ne 0) {
        throw "Start gate validation failed after batch import apply."
    }
}
finally {
    Set-Content -LiteralPath $trackerPath -Value $originalJson -Encoding UTF8
    Set-Content -LiteralPath $mdPath -Value $originalMd -Encoding UTF8
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateStartGateScript
    if ($LASTEXITCODE -ne 0) {
        throw "Start gate validation failed while restoring after batch import test."
    }
}

Write-Host "Act I review decision batch import tests passed and restored tracker artifacts, including reviewed_at and missing-column negative controls."
