$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$pipelinePath = Join-Path $root "docs\art\act_i_background_element_pipeline.json"
$jsonPath = Join-Path $root "docs\art\act_i_background_source_worklist.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_worklist.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_worklist.md"

if (-not (Test-Path -LiteralPath $pipelinePath)) {
    throw "Missing Act I background element pipeline: $pipelinePath"
}

$pipeline = Get-Content -LiteralPath $pipelinePath -Raw | ConvertFrom-Json

function Convert-ToSlug {
    param([Parameter(Mandatory=$true)][string]$Value)

    $slug = $Value.ToLowerInvariant()
    $slug = $slug -replace "[^a-z0-9]+", "_"
    $slug = $slug.Trim("_")
    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw "Cannot build slug for value: $Value"
    }
    return $slug
}

function New-WorkItem {
    param(
        [Parameter(Mandatory=$true)]$Room,
        [Parameter(Mandatory=$true)][string]$Kind,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Route,
        [Parameter(Mandatory=$true)][string]$Purpose,
        [Parameter(Mandatory=$true)][string]$SourcePath,
        [string]$RuntimePath = "",
        [string]$Position = "",
        [string[]]$CriticalRoles = @()
    )

    $id = "$(Convert-ToSlug $Room.room_id)_$(Convert-ToSlug $Kind)_$(Convert-ToSlug $Name)"
    return [ordered]@{
        id = $id
        room_code = $Room.room_code
        room_id = $Room.room_id
        room_title = $Room.title
        kind = $Kind
        name = $Name
        route = $Route
        status = "pending"
        purpose = $Purpose
        source_path = $SourcePath
        runtime_path = $RuntimePath
        position = $Position
        critical_roles = @($CriticalRoles)
    }
}

$items = @()
foreach ($room in @($pipeline.rooms)) {
    foreach ($candidate in @($room.meshy_source_model_candidates)) {
        $slug = Convert-ToSlug $candidate
        $items += New-WorkItem `
            -Room $room `
            -Kind "meshy_source_model" `
            -Name $candidate `
            -Route "source_model_helper_only" `
            -Purpose "Create or collect a reusable source model for Blender blockout/paintover reference; do not use it as the whole room." `
            -SourcePath "art/src/backgrounds/act_i/source_models/$($room.room_id)/$slug.glb"
    }

    foreach ($reference in @($room.generated_reference_allowed_for)) {
        $slug = Convert-ToSlug $reference
        $items += New-WorkItem `
            -Room $room `
            -Kind "generated_reference" `
            -Name $reference `
            -Route "reference_board_only" `
            -Purpose "Use generated imagery only for mood, texture, silhouette, or dressing reference that is repainted into the locked layout." `
            -SourcePath "docs/art/reference/act_i/$($room.room_id)/$slug.png"
    }

    foreach ($hotspot in @($room.hotspots | Where-Object { $_.pipeline_route -eq "separate_interactive_sprite_or_hotspot_layer" })) {
        $slug = Convert-ToSlug $hotspot.name
        $items += New-WorkItem `
            -Room $room `
            -Kind "interactive_layer" `
            -Name $hotspot.label `
            -Route "separate_runtime_sprite_or_hotspot_layer" `
            -Purpose "Paint/export separately from the baked background because game logic touches this element." `
            -SourcePath "art/src/backgrounds/act_i/interactive_layers/$($room.room_id)/$slug.psd" `
            -RuntimePath "game/rooms/$($room.room_id)/props/$slug.png" `
            -Position $hotspot.position `
            -CriticalRoles @($hotspot.critical_roles)
    }

    foreach ($exit in @($room.exits)) {
        $slug = Convert-ToSlug $exit.name
        $items += New-WorkItem `
            -Room $room `
            -Kind "navigation_silhouette" `
            -Name $exit.label `
            -Route "painted_readability_plus_godot_hotspot" `
            -Purpose "Keep the exit readable in the paintover while preserving Godot navigation metadata." `
            -SourcePath "art/src/backgrounds/act_i/navigation_silhouettes/$($room.room_id)/$slug.psd" `
            -RuntimePath "game/rooms/$($room.room_id)/background/$($room.room_id)_bg.png" `
            -Position $exit.position
    }
}

$kindCounts = [ordered]@{}
foreach ($group in @($items | Group-Object { $_["kind"] } | Sort-Object Name)) {
    $kindCounts[$group.Name] = $group.Count
}

$worklist = [ordered]@{
    generated_from = "docs/art/act_i_background_element_pipeline.json"
    purpose = "Concrete Act I background source-art worklist for Meshy helper models, generated references, interactive prop layers, and navigation silhouettes."
    status = "pending_sources"
    rules = @(
        "Meshy source models are helper assets only and must be brought through Blender/paintover.",
        "Generated references are concept/reference only and must not be imported as final room plates.",
        "Interactive layers must remain separate from baked backgrounds when logic touches them.",
        "Navigation silhouettes are readability tasks; Godot hotspot metadata remains authoritative.",
        "No final background export is accepted without G9/G10 palette audit."
    )
    room_count = @($pipeline.rooms).Count
    item_count = $items.Count
    kind_counts = $kindCounts
    items = $items
}

$worklist | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$csvRows = @()
foreach ($item in $items) {
    $csvRows += [pscustomobject]@{
        id = $item.id
        room_code = $item.room_code
        room_id = $item.room_id
        room_title = $item.room_title
        kind = $item.kind
        name = $item.name
        route = $item.route
        status = $item.status
        source_path = $item.source_path
        runtime_path = $item.runtime_path
        position = $item.position
        critical_roles = (@($item.critical_roles) -join "|")
    }
}
$csvRows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$lines = @(
    "# Act I Background Source Worklist",
    "",
    'Generated by `tools/Export-ActIBackgroundSourceWorklist.ps1` from `docs/art/act_i_background_element_pipeline.json`.',
    "",
    "Status: pending source assets. This is a worklist, not proof that final art exists.",
    "",
    "Rules:",
    "- Meshy source models are helper assets only and must be brought through Blender/paintover.",
    "- Generated references are concept/reference only and must not be imported as final room plates.",
    "- Interactive layers must remain separate from baked backgrounds when logic touches them.",
    "- Navigation silhouettes are readability tasks; Godot hotspot metadata remains authoritative.",
    "- No final background export is accepted without G9/G10 palette audit.",
    "",
    "Counts:",
    "- Rooms: $($worklist.room_count)",
    "- Items: $($worklist.item_count)"
)

foreach ($key in @($kindCounts.Keys)) {
    $lines += "- ${key}: $($kindCounts[$key])"
}

$lines += ""

foreach ($roomGroup in @($items | Group-Object { $_["room_id"] } | Sort-Object @{ Expression = { [int](($_.Group[0]["room_code"]) -replace "\D", "") } })) {
    $roomItems = @($roomGroup.Group)
    $first = $roomItems[0]
    $lines += "## $($first.room_code) - $($first.room_title)"
    $lines += ""
    $lines += "| ID | Kind | Name | Route | Source | Runtime |"
    $lines += "|---|---|---|---|---|---|"
    foreach ($item in @($roomItems | Sort-Object { $_["kind"] }, { $_["name"] })) {
        $runtime = if ([string]::IsNullOrWhiteSpace($item.runtime_path)) { "-" } else { $item.runtime_path }
        $lines += "| $($item.id) | $($item.kind) | $($item.name) | $($item.route) | ``$($item.source_path)`` | ``$runtime`` |"
    }
    $lines += ""
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Act I background source worklist JSON -> $jsonPath"
Write-Host "Exported Act I background source worklist CSV -> $csvPath"
Write-Host "Exported Act I background source worklist report -> $mdPath"
