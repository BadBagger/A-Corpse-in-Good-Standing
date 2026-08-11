$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$placementPath = Join-Path $root "docs\art\act_i_background_source_placement.json"
$jsonPath = Join-Path $root "docs\art\act_i_background_source_dropzones.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_dropzones.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_dropzones.md"

if (-not (Test-Path -LiteralPath $placementPath)) {
    throw "Missing Act I background source placement input: $placementPath"
}

$placement = Get-Content -LiteralPath $placementPath -Raw | ConvertFrom-Json
$rows = @($placement.rows)

function Get-SourceDirectory {
    param([Parameter(Mandatory=$true)][string]$SourcePath)
    return ($SourcePath -replace "/[^/]+$", "")
}

function Get-DropzoneKind {
    param([Parameter(Mandatory=$true)][string]$DirectoryPath)

    if ($DirectoryPath -like "art/src/backgrounds/act_i/source_models/*") { return "meshy_source_models" }
    if ($DirectoryPath -like "docs/art/reference/act_i/*") { return "generated_reference_boards" }
    if ($DirectoryPath -like "art/src/backgrounds/act_i/interactive_layers/*") { return "interactive_layer_sources" }
    if ($DirectoryPath -like "art/src/backgrounds/act_i/navigation_silhouettes/*") { return "navigation_silhouette_sources" }
    throw "Unknown Act I background source drop-zone directory: $DirectoryPath"
}

$dropzones = @()
foreach ($group in @($rows | Group-Object { Get-SourceDirectory ([string]$_.source_path) })) {
    $groupRows = @($group.Group | Sort-Object { $_.kind }, { $_.name })
    $first = $groupRows[0]
    $directoryPath = [string]$group.Name
    $dropzoneKind = Get-DropzoneKind $directoryPath
    $extensions = @($groupRows | ForEach-Object { [System.IO.Path]::GetExtension([string]$_.source_path).TrimStart(".").ToLowerInvariant() } | Sort-Object -Unique)
    $placementStages = @($groupRows | ForEach-Object { $_.placement_stage } | Sort-Object -Unique)
    $runtimePolicies = @($groupRows | ForEach-Object { $_.runtime_policy } | Sort-Object -Unique)
    $readmePath = "$directoryPath/README.md"

    $sortOrder = switch ($dropzoneKind) {
        "meshy_source_models" { 0 }
        "generated_reference_boards" { 1 }
        "interactive_layer_sources" { 2 }
        "navigation_silhouette_sources" { 3 }
        default { 99 }
    }

    $dropzones += [ordered]@{
        directory_path = $directoryPath
        readme_path = $readmePath
        room_code = $first.room_code
        room_id = $first.room_id
        room_title = $first.room_title
        dropzone_kind = $dropzoneKind
        sort_order = $sortOrder
        expected_file_count = $groupRows.Count
        expected_extensions = $extensions
        placement_stages = $placementStages
        runtime_policies = $runtimePolicies
        expected_files = @($groupRows | ForEach-Object {
            [ordered]@{
                id = $_.id
                kind = $_.kind
                tool = $_.tool
                name = $_.name
                source_path = $_.source_path
                runtime_path = $_.runtime_path
                placement_target = $_.placement_target
                runtime_policy = $_.runtime_policy
                review_gate = $_.review_gate
            }
        })
    }
}

$dropzones = @($dropzones | Sort-Object @{ Expression = { [int](([string]$_["room_code"]) -replace "\D", "") } }, @{ Expression = { [int]$_["sort_order"] } }, @{ Expression = { [string]$_["directory_path"] } })

$kindCounts = [ordered]@{}
foreach ($group in @($dropzones | Group-Object { $_["dropzone_kind"] } | Sort-Object Name)) {
    $kindCounts[$group.Name] = $group.Count
}

$payload = [ordered]@{
    generated_from = "docs/art/act_i_background_source_placement.json"
    purpose = "Physical drop-zone scaffold for Act I background source outputs."
    status = "dropzones_ready_pending_sources"
    guardrails = @(
        "Drop-zone README files are scaffolds only.",
        "Do not create placeholder binary outputs.",
        "Generated source outputs remain pending until real nonzero files appear in intake.",
        "Meshy and generated references still cannot count as final room art.",
        "Interactive and navigation source files still require their later runtime and Godot alignment gates."
    )
    dropzone_count = $dropzones.Count
    kind_counts = $kindCounts
    dropzones = $dropzones
}

$payload | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$csvRows = @()
foreach ($dropzone in $dropzones) {
    $csvRows += [pscustomobject]@{
        directory_path = $dropzone.directory_path
        readme_path = $dropzone.readme_path
        room_code = $dropzone.room_code
        room_id = $dropzone.room_id
        room_title = $dropzone.room_title
        dropzone_kind = $dropzone.dropzone_kind
        expected_file_count = $dropzone.expected_file_count
        expected_extensions = ($dropzone.expected_extensions -join ";")
        placement_stages = ($dropzone.placement_stages -join ";")
        runtime_policies = ($dropzone.runtime_policies -join ";")
    }
}
$csvRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = @(
    "# Act I Background Source Dropzones",
    "",
    'Generated by `tools/Export-ActIBackgroundSourceDropzones.ps1` from `docs/art/act_i_background_source_placement.json`.',
    "",
    "Status: $($payload.status). Drop-zone README files are scaffolds only.",
    "",
    "Guardrails:",
    "- Drop-zone README files are scaffolds only.",
    "- Do not create placeholder binary outputs.",
    "- Generated source outputs remain pending until real nonzero files appear in intake.",
    "- Meshy and generated references still cannot count as final room art.",
    "- Interactive and navigation source files still require their later runtime and Godot alignment gates.",
    "",
    "Counts:",
    "- Drop zones: $($payload.dropzone_count)"
)

foreach ($key in @($kindCounts.Keys)) {
    $lines += "- ${key}: $($kindCounts[$key])"
}

$lines += ""

foreach ($dropzone in $dropzones) {
    $lines += "## $($dropzone.room_code) - $($dropzone.room_title) - $($dropzone.dropzone_kind)"
    $lines += ""
    $lines += "- Directory: ``$($dropzone.directory_path)``"
    $lines += "- README: ``$($dropzone.readme_path)``"
    $lines += "- Expected files: $($dropzone.expected_file_count)"
    $lines += "- Extensions: $($dropzone.expected_extensions -join ', ')"
    $lines += "- Placement stages: $($dropzone.placement_stages -join ', ')"
    $lines += "- Runtime policies: $($dropzone.runtime_policies -join ', ')"
    $lines += ""
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

foreach ($dropzone in $dropzones) {
    $directoryFullPath = Join-Path $root ($dropzone.directory_path -replace "/", "\")
    if (-not (Test-Path -LiteralPath $directoryFullPath -PathType Container)) {
        New-Item -ItemType Directory -Path $directoryFullPath -Force | Out-Null
    }

    $readmeFullPath = Join-Path $root ($dropzone.readme_path -replace "/", "\")
    $readmeLines = @(
        "# $($dropzone.room_title) - $($dropzone.dropzone_kind)",
        "",
        "This directory is an Act I background source drop zone.",
        "",
        "Guardrails:",
        "- Drop-zone README files are scaffolds only.",
        "- Do not create placeholder binary outputs.",
        "- Generated source outputs remain pending until real nonzero files appear in intake.",
        "- Meshy and generated references still cannot count as final room art.",
        "- Interactive and navigation source files still require their later runtime and Godot alignment gates.",
        "",
        "Expected files:"
    )

    foreach ($file in @($dropzone.expected_files)) {
        $runtimeText = if ([string]::IsNullOrWhiteSpace([string]$file.runtime_path)) { "none" } else { [string]$file.runtime_path }
        $readmeLines += "- ``$($file.source_path)`` - $($file.kind), $($file.tool), runtime: ``$runtimeText``, review: $($file.review_gate)"
    }

    Set-Content -LiteralPath $readmeFullPath -Value $readmeLines -Encoding UTF8
}

Write-Host "Exported Act I background source dropzones JSON -> $jsonPath"
Write-Host "Exported Act I background source dropzones CSV -> $csvPath"
Write-Host "Exported Act I background source dropzones report -> $mdPath"
Write-Host "Ensured Act I background source drop-zone README files: $($dropzones.Count)"
