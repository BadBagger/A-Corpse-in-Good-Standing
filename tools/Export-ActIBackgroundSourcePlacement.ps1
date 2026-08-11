$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$promptsPath = Join-Path $root "docs\art\act_i_background_source_prompts.json"
$intakePath = Join-Path $root "docs\art\act_i_background_source_intake.json"
$jsonPath = Join-Path $root "docs\art\act_i_background_source_placement.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_placement.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_placement.md"

foreach ($path in @($promptsPath, $intakePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source placement input: $path"
    }
}

$promptPayload = Get-Content -LiteralPath $promptsPath -Raw | ConvertFrom-Json
$intakePayload = Get-Content -LiteralPath $intakePath -Raw | ConvertFrom-Json
$intakeById = @{}
foreach ($row in @($intakePayload.rows)) {
    $intakeById[[string]$row.id] = $row
}

function Get-PlacementRule {
    param([Parameter(Mandatory=$true)]$Prompt)

    $roomBlend = "art/src/backgrounds/act_i/blockouts/$($Prompt.room_id).blend"
    switch ($Prompt.kind) {
        "meshy_source_model" {
            return [ordered]@{
                placement_stage = "blender_helper_geometry"
                placement_target = $roomBlend
                destination_layer = "SourceModels_$($Prompt.room_id)"
                final_art_role = "perspective and silhouette reference for paintover"
                runtime_policy = "never_import_directly_to_godot"
                review_gate = "open_room_blend_and_confirm_scale_silhouette_palette_before_paintover"
                required_followup = "append to blockout collection, render a greybox/reference pass, then repaint into final room art"
            }
        }
        "generated_reference" {
            return [ordered]@{
                placement_stage = "reference_board"
                placement_target = "docs/art/reference/act_i/$($Prompt.room_id)"
                destination_layer = "ReferenceBoard_$($Prompt.room_id)"
                final_art_role = "texture, edge, lighting, or dressing reference only"
                runtime_policy = "never_import_directly_to_godot"
                review_gate = "compare_against_locked_palette_and_existing_hotspot_readability"
                required_followup = "extract usable ideas into paintover notes; do not trace layout or replace the room plate"
            }
        }
        "interactive_layer" {
            return [ordered]@{
                placement_stage = "paintover_runtime_layer"
                placement_target = $Prompt.runtime_path
                destination_layer = "Interactive_$($Prompt.room_id)"
                final_art_role = "separate clickable prop or wet/confession object layer"
                runtime_policy = "export_separate_png_and_preserve_godot_hotspot_metadata"
                review_gate = "verify alpha, bounds, hotspot center alignment, and role readability in Godot"
                required_followup = "export transparent runtime PNG, update import metadata only after hotspot map still validates"
            }
        }
        "navigation_silhouette" {
            return [ordered]@{
                placement_stage = "paintover_navigation_readability"
                placement_target = $Prompt.runtime_path
                destination_layer = "Navigation_$($Prompt.room_id)"
                final_art_role = "exit readability and walk-band silhouette support"
                runtime_policy = "preserve_existing_exit_metadata"
                review_gate = "verify visible exit affordance, walk-band clarity, and no new unplanned route"
                required_followup = "paint into approved room pass or export exit visibility layer without moving coordinates"
            }
        }
        default {
            throw "Unknown source placement kind: $($Prompt.kind)"
        }
    }
}

$rows = @()
foreach ($prompt in @($promptPayload.prompts)) {
    if (-not $intakeById.ContainsKey([string]$prompt.id)) {
        throw "Source placement missing intake row for prompt: $($prompt.id)"
    }
    $intake = $intakeById[[string]$prompt.id]
    $rule = Get-PlacementRule $prompt
    $rows += [ordered]@{
        id = $prompt.id
        room_code = $prompt.room_code
        room_id = $prompt.room_id
        room_title = $prompt.room_title
        kind = $prompt.kind
        tool = $prompt.tool
        name = $prompt.name
        source_status = $intake.status
        content_status = $intake.content_status
        source_path = $prompt.source_path
        runtime_path = $prompt.runtime_path
        placement_stage = $rule.placement_stage
        placement_target = $rule.placement_target
        destination_layer = $rule.destination_layer
        final_art_role = $rule.final_art_role
        runtime_policy = $rule.runtime_policy
        review_gate = $rule.review_gate
        required_followup = $rule.required_followup
    }
}

$stageCounts = [ordered]@{}
foreach ($group in @($rows | Group-Object { $_["placement_stage"] } | Sort-Object Name)) {
    $stageCounts[$group.Name] = $group.Count
}

$policyCounts = [ordered]@{}
foreach ($group in @($rows | Group-Object { $_["runtime_policy"] } | Sort-Object Name)) {
    $policyCounts[$group.Name] = $group.Count
}

$payload = [ordered]@{
    generated_from = @(
        "docs/art/act_i_background_source_prompts.json",
        "docs/art/act_i_background_source_intake.json"
    )
    purpose = "Placement map for Act I background source outputs after generation/intake."
    status = "placement_ready_pending_sources"
    guardrails = @(
        "Placement does not approve final art.",
        "Meshy source models enter Blender as helper geometry only.",
        "Generated references enter reference boards only.",
        "Interactive layers must export separate runtime PNGs and preserve Godot hotspot metadata.",
        "Navigation silhouettes must preserve existing exit metadata and walk-band readability."
    )
    row_count = $rows.Count
    stage_counts = $stageCounts
    runtime_policy_counts = $policyCounts
    rows = $rows
}

$payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$csvRows = @()
foreach ($row in $rows) {
    $csvRows += [pscustomobject]$row
}
$csvRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = @(
    "# Act I Background Source Placement",
    "",
    'Generated by `tools/Export-ActIBackgroundSourcePlacement.ps1` from source prompts plus intake status.',
    "",
    "Status: $($payload.status). Placement does not approve final art.",
    "",
    "Guardrails:",
    "- Placement does not approve final art.",
    "- Meshy source models enter Blender as helper geometry only.",
    "- Generated references enter reference boards only.",
    "- Interactive layers must export separate runtime PNGs and preserve Godot hotspot metadata.",
    "- Navigation silhouettes must preserve existing exit metadata and walk-band readability.",
    "",
    "Counts:",
    "- Rows: $($payload.row_count)"
)

foreach ($key in @($stageCounts.Keys)) {
    $lines += "- ${key}: $($stageCounts[$key])"
}

$lines += ""

foreach ($roomGroup in @($rows | Group-Object { $_["room_id"] } | Sort-Object @{ Expression = { [int](($_.Group[0]["room_code"]) -replace "\D", "") } })) {
    $roomRows = @($roomGroup.Group)
    $first = $roomRows[0]
    $lines += "## $($first.room_code) - $($first.room_title)"
    $lines += ""
    $lines += "| ID | Stage | Source Status | Placement Target | Runtime Policy | Review Gate |"
    $lines += "|---|---|---|---|---|---|"
    foreach ($row in @($roomRows | Sort-Object { $_["placement_stage"] }, { $_["name"] })) {
        $lines += "| $($row.id) | $($row.placement_stage) | $($row.source_status) | ``$($row.placement_target)`` | $($row.runtime_policy) | $($row.review_gate) |"
    }
    $lines += ""
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Act I background source placement JSON -> $jsonPath"
Write-Host "Exported Act I background source placement CSV -> $csvPath"
Write-Host "Exported Act I background source placement report -> $mdPath"
