$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_ii_background_source_worklist.json"
$csvPath = Join-Path $root "docs\art\act_ii_background_source_worklist.csv"
$mdPath = Join-Path $root "docs\art\act_ii_background_source_worklist.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIIBackgroundSourceWorklist.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act II background source worklist artifact: $path"
    }
}

$worklist = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw -Encoding UTF8
$items = @($worklist.items)

if ($worklist.status -ne "planning_only_pending_act_i_human_review") {
    throw "Act II background worklist must remain planning-only until Act I human review."
}
if ($worklist.room_count -ne 5) {
    throw "Act II background worklist expected 5 rooms, got $($worklist.room_count)."
}
if ($items.Count -ne $rows.Count) {
    throw "Act II background source worklist JSON/CSV count mismatch: json=$($items.Count), csv=$($rows.Count)."
}
if ($items.Count -lt 40) {
    throw "Act II background source worklist expected at least 40 source tasks, got $($items.Count)."
}

$ids = @($items | ForEach-Object { $_.id })
$duplicateIds = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicateIds.Count -gt 0) {
    throw "Act II background source worklist contains duplicate ids: $($duplicateIds -join ', ')"
}

$kindCounts = @{}
foreach ($group in @($items | Group-Object { $_.kind })) {
    $kindCounts[$group.Name] = $group.Count
}

foreach ($kind in @("meshy_source_model", "generated_reference", "interactive_layer", "navigation_silhouette")) {
    if (-not $kindCounts.ContainsKey($kind) -or $kindCounts[$kind] -le 0) {
        throw "Act II background source worklist missing required kind: $kind"
    }
}

foreach ($item in $items) {
    if ($item.status -ne "pending") {
        throw "Act II source worklist item $($item.id) must start pending, got $($item.status)."
    }
    if ($item.source_path -match "\\") {
        throw "Act II source worklist item $($item.id) source path must use forward slashes: $($item.source_path)"
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$item.runtime_path) -and $item.runtime_path -match "\\") {
        throw "Act II source worklist item $($item.id) runtime path must use forward slashes: $($item.runtime_path)"
    }

    if ($item.kind -eq "meshy_source_model") {
        if ($item.route -ne "source_model_helper_only" -or $item.source_path -notmatch "\.glb$" -or $item.runtime_path) {
            throw "Act II Meshy item $($item.id) must be GLB source-model helper only with no runtime path."
        }
    }
    if ($item.kind -eq "generated_reference") {
        if ($item.route -ne "reference_board_only" -or $item.runtime_path) {
            throw "Act II generated reference item $($item.id) must be reference-only with no runtime path."
        }
    }
    if ($item.kind -eq "interactive_layer") {
        if ($item.route -ne "separate_runtime_sprite_or_hotspot_layer" -or [string]::IsNullOrWhiteSpace([string]$item.runtime_path)) {
            throw "Act II interactive item $($item.id) must stay separate and provide a runtime path."
        }
    }
}

foreach ($required in @(
    "Meshy source models are helper assets only",
    "Generated references are concept/reference only",
    "Interactive layers must remain separate",
    "Navigation silhouettes are readability tasks",
    "No Act II final art export is accepted before Act I human review",
    "The Float remains hard-R non-explicit"
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act II background source worklist report missing required rule: $required"
    }
}

$requiredHeadings = @(
    "## R12 - Sabine's Office, Return",
    "## R13 - Kane's Parlour",
    "## R14 - Below Decks, The Grey Float",
    "## R15 - Customs House",
    "## R16 - The Kestrel at Low Tide"
)
foreach ($heading in $requiredHeadings) {
    if ($brief -notmatch [regex]::Escape($heading)) {
        throw "Act II background source worklist report missing room heading: $heading"
    }
}
foreach ($badToken in @(".Add(", "	ools/", "# Act II Background Source Worklist  Generated")) {
    if ($brief -match [regex]::Escape($badToken)) {
        throw "Act II background source worklist report contains generated markdown corruption token: $badToken"
    }
}

$requiredRooms = @("kane_parlour", "float_lower", "customs_house", "kestrel_wreck", "sabine_office_return")
foreach ($roomId in $requiredRooms) {
    if (@($rows | Where-Object { $_.room_id -eq $roomId }).Count -eq 0) {
        throw "Act II background source worklist missing room rows: $roomId"
    }
}

$floatRows = @($rows | Where-Object { $_.room_id -eq "float_lower" })
if ($floatRows.Count -eq 0) {
    throw "Act II Float rows missing."
}
if (-not (@($floatRows.name) -contains "hard-R non-explicit steam silhouettes")) {
    throw "Act II Float source worklist must include hard-R non-explicit steam silhouettes as reference only."
}

$interactiveNames = @($rows | Where-Object { $_.kind -eq "interactive_layer" } | ForEach-Object { $_.name })
foreach ($requiredInteractive in @("Kane's wax seal", "Mireille memory book", "cut paper transaction record", "Tomas papers strongbox", "cut paper on desk")) {
    if ($requiredInteractive -notin $interactiveNames) {
        throw "Act II background source worklist missing required interactive layer: $requiredInteractive"
    }
}

Write-Host "Act II background source worklist validation passed: rooms=$($worklist.room_count), items=$($items.Count), meshy=$($kindCounts['meshy_source_model']), generated=$($kindCounts['generated_reference']), interactive=$($kindCounts['interactive_layer']), navigation=$($kindCounts['navigation_silhouette'])."
