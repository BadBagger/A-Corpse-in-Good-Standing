$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$syncScript = Join-Path $PSScriptRoot "Validate-ActIReviewHandoffSync.ps1"
$latestNotesPath = Join-Path $root "docs\playtest\results\act_i_human_playtest_latest.md"
$decisionCsvPath = Join-Path $root "docs\playtest\act_i_review_decisions_template.csv"
$dashboardPath = Join-Path $root "docs\checkpoints\step_5_review_dashboard.json"
$syncReportPath = Join-Path $root "docs\playtest\act_i_review_handoff_sync.md"

foreach ($path in @($syncScript, $latestNotesPath, $decisionCsvPath, $dashboardPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I review handoff sync test input: $path"
    }
}

$originalNotes = Get-Content -LiteralPath $latestNotesPath -Raw
$originalCsv = Get-Content -LiteralPath $decisionCsvPath -Raw
$originalDashboard = Get-Content -LiteralPath $dashboardPath -Raw
$originalReport = if (Test-Path -LiteralPath $syncReportPath) { Get-Content -LiteralPath $syncReportPath -Raw } else { $null }

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

    Set-Content -LiteralPath $decisionCsvPath -Value $originalCsv -Encoding UTF8
    & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript
    if ($LASTEXITCODE -ne 0) {
        throw "Act I review handoff sync did not recover after restoring CSV."
    }

    $notesWithoutSabine = $originalNotes.Replace("R12", "RX2").Replace("Sabine's Office", "Sable Office")
    if ($notesWithoutSabine -eq $originalNotes) {
        throw "Notes negative control could not mutate Sabine's Office title."
    }
    Set-Content -LiteralPath $latestNotesPath -Value $notesWithoutSabine -Encoding UTF8
    Invoke-ExpectSyncFailure -FailureName "missing latest-notes room" -ExpectedPattern "do not mention every tracker room"

    Set-Content -LiteralPath $latestNotesPath -Value $originalNotes -Encoding UTF8
    $dashboard = Get-Content -LiteralPath $dashboardPath -Raw | ConvertFrom-Json
    $dashboard.artifacts = @($dashboard.artifacts | Where-Object { [string]$_ -ne "docs/art/act_i_review_contact_sheet.html" })
    $dashboard | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $dashboardPath -Encoding UTF8
    Invoke-ExpectSyncFailure -FailureName "missing contact-sheet dashboard artifact" -ExpectedPattern "missing review handoff artifact"

    Set-Content -LiteralPath $dashboardPath -Value $originalDashboard -Encoding UTF8
    $dashboard = Get-Content -LiteralPath $dashboardPath -Raw | ConvertFrom-Json
    $dashboard.artifacts = @($dashboard.artifacts | Where-Object { [string]$_ -ne "docs/art/act_i_background_ready_source_packets.md" })
    $dashboard | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $dashboardPath -Encoding UTF8
    Invoke-ExpectSyncFailure -FailureName "missing ready-source-packet dashboard artifact" -ExpectedPattern "missing review handoff artifact"
}
finally {
    Set-Content -LiteralPath $latestNotesPath -Value $originalNotes -Encoding UTF8
    Set-Content -LiteralPath $decisionCsvPath -Value $originalCsv -Encoding UTF8
    Set-Content -LiteralPath $dashboardPath -Value $originalDashboard -Encoding UTF8
    if ($null -ne $originalReport) {
        Set-Content -LiteralPath $syncReportPath -Value $originalReport -Encoding UTF8
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $syncScript
    if ($LASTEXITCODE -ne 0) {
        throw "Act I review handoff sync validation failed while restoring after negative controls."
    }
}

Write-Host "Act I review handoff sync tests passed: baseline validates, decision mismatch fails, missing latest-notes room fails, missing contact-sheet artifact fails, missing ready-source packet artifact fails, cleanup restores validation."
