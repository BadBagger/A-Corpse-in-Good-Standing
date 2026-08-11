$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$csvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$reportPath = Join-Path $root "docs\art\act_i_background_asset_status.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundAssetStatus.ps1")

if (-not (Test-Path -LiteralPath $csvPath)) {
    throw "Missing Act I background asset status CSV: $csvPath"
}
if (-not (Test-Path -LiteralPath $reportPath)) {
    throw "Missing Act I background asset status report: $reportPath"
}

$rows = @(Import-Csv -LiteralPath $csvPath)
if ($rows.Count -ne 44) {
    throw "Act I background asset status row count mismatch: expected 44, got $($rows.Count)"
}

$rooms = @($rows | Group-Object room_id)
if ($rooms.Count -ne 11) {
    throw "Act I background asset status room count mismatch: expected 11, got $($rooms.Count)"
}

foreach ($roomGroup in $rooms) {
    $kinds = @($roomGroup.Group | ForEach-Object { $_.asset_kind })
    foreach ($requiredKind in @("blend_blockout", "paintover_source", "export_png", "godot_import")) {
        if ($requiredKind -notin $kinds) {
            throw "Act I background asset status missing $requiredKind for room $($roomGroup.Name)"
        }
    }
    foreach ($row in $roomGroup.Group) {
        if ($row.status -notin @("present", "pending")) {
            throw "Act I background asset status has invalid status '$($row.status)' for $($row.relative_path)"
        }
        foreach ($requiredColumn in @("content_status", "size_bytes")) {
            if (-not ($row.PSObject.Properties.Name -contains $requiredColumn)) {
                throw "Act I background asset status missing column: $requiredColumn"
            }
        }
        if ([string]::IsNullOrWhiteSpace($row.relative_path) -or $row.relative_path -match "\\") {
            throw "Act I background asset status has invalid relative path for $($row.room_id)/$($row.asset_kind): $($row.relative_path)"
        }
        if ($row.status -eq "pending") {
            if ($row.content_status -ne "missing" -or [int64]$row.size_bytes -ne 0) {
                throw "Pending asset row must have missing content status and zero size: $($row.relative_path)"
            }
        } else {
            if ([int64]$row.size_bytes -le 0) {
                throw "Present asset row has zero size: $($row.relative_path)"
            }
            if ($row.asset_kind -eq "paintover_source" -and $row.content_status -ne "valid_psd_source") {
                throw "Paintover source must be a PSD-like 8BPS file, not a placeholder: $($row.relative_path)"
            }
            if ($row.asset_kind -ne "paintover_source" -and $row.content_status -notin @("present")) {
                throw "Present non-PSD asset row has invalid content status '$($row.content_status)' for $($row.relative_path)"
            }
        }
    }
}

$registrarRows = @($rows | Where-Object { $_.room_id -eq "harbor_registry" })
if ($registrarRows.Count -ne 4) {
    throw "Act I background asset status must include all Harbor Registry art slots."
}

$report = Get-Content -LiteralPath $reportPath -Raw
foreach ($requiredText in @(
    "Act I Background Asset Status",
    "production tracker, not a final-art gate",
    "R05 Harbor Registry",
    "godot_import",
    "Paintover source PSDs must be real PSD-like files with an 8BPS signature",
    "Empty files never count as valid present assets"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background asset status report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I background asset status report contains malformed generated Markdown: $forbiddenText"
    }
}

Write-Host "Act I background asset status validation passed: rooms=$($rooms.Count), rows=$($rows.Count)"
