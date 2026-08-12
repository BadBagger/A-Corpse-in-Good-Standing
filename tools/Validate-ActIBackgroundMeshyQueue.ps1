$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_meshy_queue.json"
$csvPath = Join-Path $root "docs\art\act_i_background_meshy_queue.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_meshy_queue.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundMeshyQueue.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I Meshy queue artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw
$items = @($payload.items)

if ($payload.model_count -ne 43 -or $items.Count -ne 43 -or $rows.Count -ne 43) {
    throw "Act I Meshy queue expected 43 helper models, got payload=$($payload.model_count), json=$($items.Count), csv=$($rows.Count)."
}

$ids = @($rows | ForEach-Object { $_.id })
$duplicates = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicates.Count -gt 0) {
    throw "Act I Meshy queue contains duplicate ids: $($duplicates -join ', ')"
}

foreach ($row in $rows) {
    if ($row.id -notmatch "_meshy_source_model_") {
        throw "Act I Meshy queue contains non-Meshy item: $($row.id)"
    }
    if ($row.source_path -match "\\" -or $row.source_path -notmatch "\.glb$") {
        throw "Act I Meshy queue source must be a forward-slash GLB path: $($row.source_path)"
    }
    if ($row.output_contract -notmatch [regex]::Escape($row.source_path)) {
        throw "Act I Meshy queue output contract missing exact source path for $($row.id)."
    }
    foreach ($required in @(
        "single reusable 3D source prop",
        "strong silhouette",
        "simple readable geometry",
        "neutral grey material groups",
        "no scene floor",
        "no full room",
        "no characters",
        "no text labels"
    )) {
        if ($row.prompt -notmatch [regex]::Escape($required)) {
            throw "Act I Meshy prompt $($row.id) missing guardrail: $required"
        }
    }
}

foreach ($required in @(
    "Act I Background Meshy Queue",
    "Meshy outputs are helper geometry only.",
    "Download GLB files exactly to the listed source paths.",
    "Do not import Meshy GLBs directly into Godot.",
    "Do not generate final background plates from this queue.",
    "Run source intake after every downloaded GLB.",
    "Preview generation spends Meshy credits and requires explicit user approval before API calls."
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act I Meshy queue report missing guardrail: $required"
    }
}

if ([string]::IsNullOrWhiteSpace($env:MESHY_API_KEY)) {
    if ([string]$payload.status -ne "blocked_no_meshy_key") {
        throw "Act I Meshy queue must report blocked_no_meshy_key when MESHY_API_KEY is absent."
    }
    if ($brief -notmatch [regex]::Escape("Do not create placeholder GLBs.")) {
        throw "Act I Meshy queue must warn against placeholder GLBs when blocked."
    }
}

if ($brief -match "[^\u0000-\u007F]") {
    throw "Act I Meshy queue report must stay ASCII-only."
}

Write-Host "Act I Meshy queue validation passed: models=$($payload.model_count), present=$($payload.present_count), pending=$($payload.pending_count), status=$($payload.status)."
