$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_source_placement.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_placement.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_placement.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundSourcePlacement.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source placement artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw

if ($payload.row_count -ne 130 -or @($payload.rows).Count -ne 130 -or $rows.Count -ne 130) {
    throw "Act I background source placement expected 130 rows, got payload=$($payload.row_count), jsonRows=$(@($payload.rows).Count), csv=$($rows.Count)."
}

$ids = @($rows | ForEach-Object { $_.id })
$duplicates = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicates.Count -gt 0) {
    throw "Act I background source placement contains duplicate ids: $($duplicates -join ', ')"
}

$expectedStages = @{
    "meshy_source_model" = "blender_helper_geometry"
    "generated_reference" = "reference_board"
    "interactive_layer" = "paintover_runtime_layer"
    "navigation_silhouette" = "paintover_navigation_readability"
}

foreach ($row in $rows) {
    if (-not $expectedStages.ContainsKey($row.kind)) {
        throw "Unknown Act I background source placement kind: $($row.kind)"
    }
    if ($row.placement_stage -ne $expectedStages[$row.kind]) {
        throw "Placement $($row.id) has wrong stage for $($row.kind): $($row.placement_stage)"
    }
    foreach ($pathField in @("source_path", "runtime_path", "placement_target")) {
        $value = [string]$row.$pathField
        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -match "\\") {
            throw "Source placement path must use forward slashes in $pathField for $($row.id): $value"
        }
    }
    foreach ($field in @("final_art_role", "runtime_policy", "review_gate", "required_followup")) {
        if ([string]::IsNullOrWhiteSpace([string]$row.$field)) {
            throw "Source placement $($row.id) missing $field."
        }
    }
    if ($row.kind -eq "meshy_source_model" -and $row.runtime_policy -ne "never_import_directly_to_godot") {
        throw "Meshy placement must never import directly to Godot: $($row.id)"
    }
    if ($row.kind -eq "generated_reference" -and $row.runtime_policy -ne "never_import_directly_to_godot") {
        throw "Generated reference placement must never import directly to Godot: $($row.id)"
    }
    if ($row.kind -eq "interactive_layer" -and $row.runtime_policy -ne "export_separate_png_and_preserve_godot_hotspot_metadata") {
        throw "Interactive placement must preserve separate runtime PNG and hotspot metadata: $($row.id)"
    }
    if ($row.kind -eq "navigation_silhouette" -and $row.runtime_policy -ne "preserve_existing_exit_metadata") {
        throw "Navigation placement must preserve exit metadata: $($row.id)"
    }
}

foreach ($required in @(
    "Act I Background Source Placement",
    "Placement does not approve final art.",
    "Meshy source models enter Blender as helper geometry only.",
    "Generated references enter reference boards only.",
    "Interactive layers must export separate runtime PNGs and preserve Godot hotspot metadata.",
    "Navigation silhouettes must preserve existing exit metadata and walk-band readability."
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act I background source placement report missing guardrail: $required"
    }
}

$firstRoomHeading = [string](@([regex]::Matches($brief, "(?m)^##\s+R\d+\s+-\s+.+$") | ForEach-Object { $_.Value })[0]).Trim()
if ($firstRoomHeading -ne "## R01 - Mudflats") {
    throw "Act I background source placement must be ordered by room code; first heading was: $firstRoomHeading"
}

Write-Host "Act I background source placement validation passed: rows=$($payload.row_count), meshy=$(@($rows | Where-Object { $_.kind -eq 'meshy_source_model' }).Count), imagegen=$(@($rows | Where-Object { $_.kind -eq 'generated_reference' }).Count), interactive=$(@($rows | Where-Object { $_.kind -eq 'interactive_layer' }).Count), navigation=$(@($rows | Where-Object { $_.kind -eq 'navigation_silhouette' }).Count)."
