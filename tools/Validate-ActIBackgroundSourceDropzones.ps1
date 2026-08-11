$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_source_dropzones.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_dropzones.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_dropzones.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundSourceDropzones.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source drop-zone artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw
$dropzones = @($payload.dropzones)

if ($payload.dropzone_count -ne 43 -or $dropzones.Count -ne 43 -or $rows.Count -ne 43) {
    throw "Act I background source dropzones expected 43 rows, got payload=$($payload.dropzone_count), jsonRows=$($dropzones.Count), csv=$($rows.Count)."
}

$expectedKindCounts = @{
    "meshy_source_models" = 11
    "generated_reference_boards" = 11
    "interactive_layer_sources" = 11
    "navigation_silhouette_sources" = 10
}
foreach ($kind in $expectedKindCounts.Keys) {
    $actual = @($rows | Where-Object { $_.dropzone_kind -eq $kind }).Count
    if ($actual -ne $expectedKindCounts[$kind]) {
        throw "Act I background source dropzones expected $($expectedKindCounts[$kind]) $kind rows, got $actual."
    }
}

$readmePaths = @($rows | ForEach-Object { $_.readme_path })
$duplicates = @($readmePaths | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicates.Count -gt 0) {
    throw "Act I background source dropzones contain duplicate README paths: $($duplicates -join ', ')"
}

foreach ($dropzone in $dropzones) {
    foreach ($pathField in @("directory_path", "readme_path")) {
        $value = [string]$dropzone.$pathField
        if ($value -match "\\") {
            throw "Act I background source drop-zone path must use forward slashes in $pathField`: $value"
        }
    }

    $readmeFullPath = Join-Path $root (([string]$dropzone.readme_path) -replace "/", "\")
    if (-not (Test-Path -LiteralPath $readmeFullPath -PathType Leaf)) {
        throw "Missing Act I background source drop-zone README: $($dropzone.readme_path)"
    }

    $readme = Get-Content -LiteralPath $readmeFullPath -Raw
    foreach ($required in @(
        "This directory is an Act I background source drop zone.",
        "Do not create placeholder binary outputs.",
        "Generated source outputs remain pending until real nonzero files appear in intake.",
        "Meshy and generated references still cannot count as final room art.",
        "Interactive and navigation source files still require their later runtime and Godot alignment gates."
    )) {
        if ($readme -notmatch [regex]::Escape($required)) {
            throw "Act I background source drop-zone README $($dropzone.readme_path) missing required text: $required"
        }
    }

    foreach ($file in @($dropzone.expected_files)) {
        if ($readme -notmatch [regex]::Escape([string]$file.source_path)) {
            throw "Act I background source drop-zone README $($dropzone.readme_path) missing expected file: $($file.source_path)"
        }
    }
}

foreach ($required in @(
    "Act I Background Source Dropzones",
    "Drop-zone README files are scaffolds only.",
    "Do not create placeholder binary outputs.",
    "Generated source outputs remain pending until real nonzero files appear in intake.",
    "Meshy and generated references still cannot count as final room art.",
    "Interactive and navigation source files still require their later runtime and Godot alignment gates."
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act I background source drop-zone report missing guardrail: $required"
    }
}

if ($brief -match "[^\u0000-\u007F]") {
    throw "Act I background source drop-zone report must stay ASCII-only."
}

$firstHeading = [string](@([regex]::Matches($brief, "(?m)^##\s+R\d+\s+-\s+.+$") | ForEach-Object { $_.Value })[0]).Trim()
if ($firstHeading -ne "## R01 - Mudflats - meshy_source_models") {
    throw "Act I background source drop-zone report must be ordered by room code and production kind; first heading was: $firstHeading"
}

Write-Host "Act I background source drop-zone validation passed: dropzones=$($payload.dropzone_count), sourceModels=11, references=11, interactive=11, navigation=10."
