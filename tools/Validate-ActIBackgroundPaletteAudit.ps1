$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$csvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$reportPath = Join-Path $root "docs\art\act_i_background_palette_audit.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundPaletteAudit.ps1")

if (-not (Test-Path -LiteralPath $csvPath)) {
    throw "Missing Act I background palette audit CSV: $csvPath"
}
if (-not (Test-Path -LiteralPath $reportPath)) {
    throw "Missing Act I background palette audit report: $reportPath"
}

$rows = @(Import-Csv -LiteralPath $csvPath)
if ($rows.Count -ne 11) {
    throw "Act I background palette audit row count mismatch: expected 11, got $($rows.Count)"
}

$roomIds = @($rows | ForEach-Object { $_.room_id })
$duplicateRooms = @($roomIds | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicateRooms.Count -gt 0) {
    throw "Act I background palette audit has duplicate rooms: $($duplicateRooms -join ', ')"
}

$auditedRows = @($rows | Where-Object { $_.status -eq "audited" })
$pendingRows = @($rows | Where-Object { $_.status -eq "pending" })
if (($auditedRows.Count + $pendingRows.Count) -ne $rows.Count) {
    throw "Act I background palette audit contains invalid row statuses."
}

foreach ($row in $rows) {
    if ([string]::IsNullOrWhiteSpace($row.export_png) -or $row.export_png -match "\\") {
        throw "Act I background palette audit has invalid export path for $($row.room_id): $($row.export_png)"
    }
    if ($row.status -eq "audited") {
        $percent = [double]$row.in_gamut_percent
        if ($percent -lt 98.0) {
            throw "Act I background palette audit G9 failed for $($row.room_id): $percent% in gamut."
        }
    }
}

$redSceneCount = @($auditedRows | Where-Object { $_.arterial_red_scene -eq "True" }).Count
if ($redSceneCount -gt 5) {
    throw "Act I background palette audit G10 failed: arterial red appears in $redSceneCount scenes."
}

$report = Get-Content -LiteralPath $reportPath -Raw
foreach ($requiredText in @("Act I Background Palette Audit", "G9 threshold", "G10 threshold", "arterial red", "Pending exports are tracked")) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background palette audit report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I background palette audit report contains malformed generated Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I background palette audit report must stay ASCII-only."
}

Write-Host "Act I background palette audit validation passed: rows=$($rows.Count), audited=$($auditedRows.Count), pending=$($pendingRows.Count), arterialRedScenes=$redSceneCount"
