$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$syncScript = Join-Path $PSScriptRoot "Validate-ActIReviewHandoffSync.ps1"
$latestNotesPath = Join-Path $root "docs\playtest\results\act_i_human_playtest_latest.md"
$decisionCsvPath = Join-Path $root "docs\playtest\act_i_review_decisions_template.csv"
$trackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.json"
$trackerMdPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$dashboardPath = Join-Path $root "docs\checkpoints\step_5_review_dashboard.json"
$syncReportPath = Join-Path $root "docs\playtest\act_i_review_handoff_sync.md"
$setDecisionScript = Join-Path $PSScriptRoot "Set-ActIReviewDecision.ps1"

foreach ($path in @($syncScript, $latestNotesPath, $decisionCsvPath, $trackerPath, $trackerMdPath, $dashboardPath, $setDecisionScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I review handoff sync test input: $path"
    }
}

function Normalize-TestRestoreText {
    param([string]$Text)
    return $Text.TrimEnd("`r", "`n") + "`r`n"
}

function Restore-TestText {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Text
    )

    [System.IO.File]::WriteAllText($Path, (Normalize-TestRestoreText $Text), [System.Text.UTF8Encoding]::new($false))
}

$originalNotes = Normalize-TestRestoreText (Get-Content -LiteralPath $latestNotesPath -Raw)
$originalCsv = Normalize-TestRestoreText (Get-Content -LiteralPath $decisionCsvPath -Raw)
$originalTracker = Normalize-TestRestoreText (Get-Content -LiteralPath $trackerPath -Raw)
$originalTrackerMd = Normalize-TestRestoreText (Get-Content -LiteralPath $trackerMdPath -Raw)
$originalDashboard = Normalize-TestRestoreText (Get-Content -LiteralPath $dashboardPath -Raw)
$originalReport = if (Test-Path -LiteralPath $syncReportPath) { Normalize-TestRestoreText (Get-Content -LiteralPath $syncReportPath -Raw) } else { $null }

function Invoke-ExpectSyncFailure {
    param(
        [Parameter(Mandatory=$true)][string]$ExpectedPattern,
        [Parameter(Mandatory=$true)][string]$FailureName
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript 2>&1
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference

    if ($exit -eq 0) {
        throw "$FailureName negative control unexpectedly passed."
    }
    if (($output -join "`n") -notmatch $ExpectedPattern) {
        throw "$FailureName negative control failed for the wrong reason: $($output -join ' ')"
    }
}

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript
    if ($LASTEXITCODE -ne 0) {
        throw "Baseline Act I review handoff sync validation failed."
    }

    $rows = @(Import-Csv -LiteralPath $decisionCsvPath)
    $registry = @($rows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    if ($null -eq $registry) {
        throw "Cannot find Harbor Registry row for handoff sync negative control."
    }
    $registry.decision = "approved"
    $rows | Export-Csv -LiteralPath $decisionCsvPath -NoTypeInformation -Encoding UTF8
    Invoke-ExpectSyncFailure -FailureName "decision mismatch" -ExpectedPattern "decisions differ"

    Restore-TestText -Path $decisionCsvPath -Text $originalCsv
    & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript
    if ($LASTEXITCODE -ne 0) {
        throw "Act I review handoff sync did not recover after restoring CSV."
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $setDecisionScript -RoomId "harbor_registry" -Decision "approved" -BuildCommit "abcdef1" -Reviewer "Automated test" -ReviewedAt "2026-08-11" -DecisionNote "Approve Harbor Registry for handoff proof simulation; accepted Litany format preserved." -LookTargetReviewed "yes" -CorvinActionScaffoldReviewed "yes"
    if ($LASTEXITCODE -ne 0) { throw "Failed to approve Harbor Registry for handoff proof simulation." }
    $rows = @(Import-Csv -LiteralPath $decisionCsvPath)
    $registry = @($rows | Where-Object { $_.room_id -eq "harbor_registry" })[0]
    $registry.decision = "approved"
    $registry.build_commit = "abcdef2"
    $registry.reviewer = "Automated test"
    $registry.reviewed_at = "2026-08-11"
    $registry.decision_note = "Approve Harbor Registry for handoff proof simulation; accepted Litany format preserved."
    $registry.look_target_reviewed = "yes"
    $registry.corvin_action_scaffold_reviewed = "yes"
    $rows | Export-Csv -LiteralPath $decisionCsvPath -NoTypeInformation -Encoding UTF8
    Invoke-ExpectSyncFailure -FailureName "build commit proof mismatch" -ExpectedPattern "proof fields differ"

    Restore-TestText -Path $decisionCsvPath -Text $originalCsv
    Restore-TestText -Path $trackerPath -Text $originalTracker
    Restore-TestText -Path $trackerMdPath -Text $originalTrackerMd

    $notesWithoutSabine = $originalNotes.Replace("R12", "RX2").Replace("Sabine's Office", "Sable Office")
    if ($notesWithoutSabine -eq $originalNotes) {
        throw "Notes negative control could not mutate Sabine's Office title."
    }
    Restore-TestText -Path $latestNotesPath -Text $notesWithoutSabine
    Invoke-ExpectSyncFailure -FailureName "missing latest-notes room" -ExpectedPattern "do not mention every tracker room"

    Restore-TestText -Path $latestNotesPath -Text $originalNotes
    $dashboard = Get-Content -LiteralPath $dashboardPath -Raw | ConvertFrom-Json
    $dashboard.artifacts = @($dashboard.artifacts | Where-Object { [string]$_ -ne "docs/art/act_i_review_contact_sheet.html" })
    $dashboard | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $dashboardPath -Encoding UTF8
    Invoke-ExpectSyncFailure -FailureName "missing contact-sheet dashboard artifact" -ExpectedPattern "missing review handoff artifact"

    Restore-TestText -Path $dashboardPath -Text $originalDashboard
    $dashboard = Get-Content -LiteralPath $dashboardPath -Raw | ConvertFrom-Json
    $dashboard.artifacts = @($dashboard.artifacts | Where-Object { [string]$_ -ne "docs/art/act_i_background_ready_source_packets.md" })
    $dashboard | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $dashboardPath -Encoding UTF8
    Invoke-ExpectSyncFailure -FailureName "missing ready-source-packet dashboard artifact" -ExpectedPattern "missing review handoff artifact"
}
finally {
    Restore-TestText -Path $latestNotesPath -Text $originalNotes
    Restore-TestText -Path $decisionCsvPath -Text $originalCsv
    Restore-TestText -Path $trackerPath -Text $originalTracker
    Restore-TestText -Path $trackerMdPath -Text $originalTrackerMd
    Restore-TestText -Path $dashboardPath -Text $originalDashboard
    if ($null -ne $originalReport) {
        Restore-TestText -Path $syncReportPath -Text $originalReport
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript
    if ($LASTEXITCODE -ne 0) {
        throw "Act I review handoff sync validation failed while restoring after negative controls."
    }
}

Write-Host "Act I review handoff sync tests passed: baseline validates, decision mismatch fails, build-commit proof mismatch fails, missing latest-notes room fails, missing contact-sheet artifact fails, missing ready-source packet artifact fails, cleanup restores validation."
