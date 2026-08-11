$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_source_intake.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_intake.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_intake.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundSourceIntake.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source intake artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw

if ($payload.prompt_count -ne 130 -or @($payload.rows).Count -ne 130 -or $rows.Count -ne 130) {
    throw "Act I background source intake expected 130 rows, got payload=$($payload.prompt_count), jsonRows=$(@($payload.rows).Count), csv=$($rows.Count)."
}

$ids = @($rows | ForEach-Object { $_.id })
$duplicates = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicates.Count -gt 0) {
    throw "Act I background source intake contains duplicate ids: $($duplicates -join ', ')"
}

foreach ($row in $rows) {
    if ($row.source_path -match "\\") {
        throw "Source intake path must use forward slashes: $($row.source_path)"
    }
    if (-not [string]::IsNullOrWhiteSpace($row.runtime_path) -and $row.runtime_path -match "\\") {
        throw "Runtime intake path must use forward slashes: $($row.runtime_path)"
    }
    if ($row.kind -eq "meshy_source_model" -and $row.expected_file_kind -ne "glb") {
        throw "Meshy source item must expect GLB: $($row.id)"
    }
    if ($row.kind -eq "generated_reference" -and $row.expected_file_kind -ne "png") {
        throw "Generated reference item must expect PNG: $($row.id)"
    }
    if ($row.kind -in @("interactive_layer", "navigation_silhouette") -and $row.expected_file_kind -ne "psd") {
        throw "Paintover source item must expect PSD: $($row.id)"
    }
}

$zeroByteRows = @($rows | Where-Object { $_.content_status -eq "zero_byte" })
if ($zeroByteRows.Count -gt 0) {
    throw "Act I background source intake has zero-byte outputs: $($zeroByteRows.id -join ', ')"
}

foreach ($required in @(
    "Source prompt outputs do not count as final background art.",
    "Meshy GLBs are helper geometry until imported through Blender and paintover.",
    "Generated references are paintover references only",
    "Interactive source PSDs require later runtime export",
    "Zero-byte source outputs fail intake."
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act I background source intake report missing guardrail: $required"
    }
}

$firstRoomHeading = [string](@([regex]::Matches($brief, "(?m)^##\s+R\d+\s+-\s+.+$") | ForEach-Object { $_.Value })[0]).Trim()
if ($firstRoomHeading -ne "## R01 - Mudflats") {
    throw "Act I background source intake must be ordered by room code; first heading was: $firstRoomHeading"
}

Write-Host "Act I background source intake validation passed: prompts=$($payload.prompt_count), present=$($payload.present_count), pending=$($payload.pending_count), zeroByte=$($payload.zero_byte_count), status=$($payload.status)."
