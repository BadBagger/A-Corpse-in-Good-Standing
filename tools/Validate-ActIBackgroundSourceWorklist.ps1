$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_source_worklist.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_worklist.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_worklist.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundSourceWorklist.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source worklist artifact: $path"
    }
}

$worklist = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw
$items = @($worklist.items)

if ($worklist.room_count -ne 11) {
    throw "Act I background source worklist expected 11 rooms, got $($worklist.room_count)."
}
if ($items.Count -ne $rows.Count) {
    throw "Act I background source worklist JSON/CSV count mismatch: json=$($items.Count), csv=$($rows.Count)."
}
if ($items.Count -lt 100) {
    throw "Act I background source worklist expected at least 100 source tasks, got $($items.Count)."
}

$ids = @($items | ForEach-Object { $_.id })
$duplicateIds = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicateIds.Count -gt 0) {
    throw "Act I background source worklist contains duplicate ids: $($duplicateIds -join ', ')"
}

$kindCounts = @{}
foreach ($group in @($items | Group-Object { $_.kind })) {
    $kindCounts[$group.Name] = $group.Count
}

foreach ($kind in @("meshy_source_model", "generated_reference", "interactive_layer", "navigation_silhouette")) {
    if (-not $kindCounts.ContainsKey($kind) -or $kindCounts[$kind] -le 0) {
        throw "Act I background source worklist missing required kind: $kind"
    }
}

foreach ($item in $items) {
    if ($item.status -ne "pending") {
        throw "Source worklist item $($item.id) must start pending, got $($item.status)."
    }
    if ($item.source_path -match "\\") {
        throw "Source worklist item $($item.id) source path must use forward slashes: $($item.source_path)"
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$item.runtime_path) -and $item.runtime_path -match "\\") {
        throw "Source worklist item $($item.id) runtime path must use forward slashes: $($item.runtime_path)"
    }

    if ($item.kind -eq "meshy_source_model") {
        if ($item.route -ne "source_model_helper_only" -or $item.source_path -notmatch "\.glb$") {
            throw "Meshy item $($item.id) must be GLB source-model helper only."
        }
    }
    if ($item.kind -eq "generated_reference") {
        if ($item.route -ne "reference_board_only" -or $item.runtime_path) {
            throw "Generated reference item $($item.id) must be reference-only with no runtime path."
        }
    }
    if ($item.kind -eq "interactive_layer") {
        if ($item.route -ne "separate_runtime_sprite_or_hotspot_layer" -or [string]::IsNullOrWhiteSpace([string]$item.runtime_path)) {
            throw "Interactive item $($item.id) must stay separate and provide a runtime path."
        }
    }
}

foreach ($required in @(
    "Meshy source models are helper assets only",
    "Generated references are concept/reference only",
    "Interactive layers must remain separate",
    "Navigation silhouettes are readability tasks",
    "No final background export is accepted without G9/G10 palette audit"
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act I background source worklist report missing required rule: $required"
    }
}

$firstRoomHeading = [string](@([regex]::Matches($brief, "(?m)^##\s+R\d+\s+-\s+.+$") | ForEach-Object { $_.Value })[0]).Trim()
if ($firstRoomHeading -ne "## R01 - Mudflats") {
    throw "Act I background source worklist must be ordered by room code; first heading was: $firstRoomHeading"
}

$greyFloatRows = @($rows | Where-Object { $_.room_id -eq "grey_float" })
if ($greyFloatRows.Count -eq 0 -or -not (@($greyFloatRows.name) -contains "non-explicit labor staging")) {
    throw "Grey Float source worklist must include non-explicit labor staging as generated reference only."
}

$registrarRows = @($rows | Where-Object { $_.room_id -eq "harbor_registry" -and $_.name -eq "Registrar" })
if ($registrarRows.Count -ne 1 -or $registrarRows[0].kind -ne "interactive_layer") {
    throw "Registrar must appear exactly once as an interactive layer."
}

Write-Host "Act I background source worklist validation passed: rooms=$($worklist.room_count), items=$($items.Count), meshy=$($kindCounts['meshy_source_model']), generated=$($kindCounts['generated_reference']), interactive=$($kindCounts['interactive_layer']), navigation=$($kindCounts['navigation_silhouette'])."
