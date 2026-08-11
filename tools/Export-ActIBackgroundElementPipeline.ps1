$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$jsonPath = Join-Path $root "docs\art\act_i_background_element_pipeline.json"
$mdPath = Join-Path $root "docs\art\act_i_background_element_pipeline.md"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing Act I background manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

function Get-RoomMeshyCandidates {
    param([Parameter(Mandatory=$true)][string]$RoomId)

    switch ($RoomId) {
        "mudflats" { return @("distant leviathan ribs", "bollard silhouettes", "mud ridge reference forms") }
        "old_quay" { return @("dock pilings", "bollard row", "rope cleat", "harbor rail fragments") }
        "salt_market" { return @("market stall shells", "boot stall", "hanging lamps", "crowd silhouette blockers") }
        "harbor_registry" { return @("Registrar desk", "ledger stacks", "roll book lectern", "window frame") }
        "bone_chandler" { return @("bone shelf units", "trade counter", "chess set scale prop", "Prosper watch display block") }
        "almshouse" { return @("cot rows", "window frame", "privacy screens", "Prosper sitting silhouette block") }
        "fish_hall" { return @("ice table", "drain grate", "visitor book stand", "tagged body-table silhouette") }
        "church_of_the_drowned" { return @("confession booth", "Church ledger desk", "receipt window", "green lamp housings") }
        "grey_float" { return @("barge wall ribs", "steam-screen partitions", "lamp clusters", "bathhouse railings") }
        "harbormaster_office" { return @("office desk", "filing wall", "checklist board", "frosted glass door") }
        "sabine_office" { return @("Sabine desk", "window frame", "Persian rug plane", "wrist-check staging chair") }
        default { return @("large repeatable structural props", "camera-blocking furniture", "lighting fixtures") }
    }
}

function Get-RoomGeneratedReference {
    param([Parameter(Mandatory=$true)][string]$RoomId)

    switch ($RoomId) {
        "grey_float" { return @("steam density", "warm silhouette privacy shapes", "non-explicit labor staging", "amber trap mood") }
        "church_of_the_drowned" { return @("institutional absinthe-green light", "paper bureaucracy texture", "wet stone grime") }
        "mudflats" { return @("wet silt texture", "cold horizon wash", "dawn haze") }
        "salt_market" { return @("public crowd mood", "salt signage grime", "market awning texture") }
        default { return @("grime texture", "ink-wash edge breakup", "palette-safe mood reference", "non-clickable dressing silhouettes") }
    }
}

function Get-HotspotPipeline {
    param($Hotspot)

    $roles = @($Hotspot.critical_roles)
    if ($roles.Count -eq 0) {
        $roles = @("scene_texture")
    }

    $requiresSeparateLayer = $false
    foreach ($role in $roles) {
        if ($role -in @("duel", "wet_verb", "conditional_followup", "blocked_feedback", "confession_source", "item_reward", "gated", "custom_navigation")) {
            $requiresSeparateLayer = $true
        }
    }

    if ($requiresSeparateLayer) {
        return [ordered]@{
            route = "separate_interactive_sprite_or_hotspot_layer"
            reason = "Verb-coin, state, confession, duel, item, wetness, gate, or navigation logic touches this element."
            source = "Blender greybox for position; Meshy only for reusable structural/source-model help; generated images reference only."
        }
    }

    return [ordered]@{
        route = "baked_paintover_dressing"
        reason = "Scene texture only; no verb/state contract depends on it."
        source = "Blender greybox and final paintover. Generated texture reference is allowed if repainted and palette-audited."
    }
}

$rooms = @()
foreach ($room in @($manifest.rooms)) {
    $hotspotPipelines = @()
    foreach ($hotspot in @($room.hotspots)) {
        $pipeline = Get-HotspotPipeline $hotspot
        $hotspotPipelines += [ordered]@{
            name = $hotspot.name
            label = $hotspot.label
            type = $hotspot.type
            position = "$($hotspot.x), $($hotspot.y)"
            critical_roles = @($hotspot.critical_roles)
            pipeline_route = $pipeline.route
            reason = $pipeline.reason
            source_guidance = $pipeline.source
        }
    }

    $exitPipelines = @()
    foreach ($exit in @($room.exits)) {
        $exitPipelines += [ordered]@{
            name = $exit.name
            label = $exit.label
            target_room = $exit.target_room
            position = "$($exit.x), $($exit.y)"
            pipeline_route = "navigation_hotspot_over_locked_background"
            source_guidance = "Keep exit silhouette readable in the paintover, but preserve Godot navigation/hotspot metadata."
        }
    }

    $rooms += [ordered]@{
        room_id = $room.room_id
        room_code = $room.room_code
        title = $room.title
        authoritative_layout = "docs/art/act_i_background_manifest.json"
        camera_and_scale_source = $room.source_blend
        final_plate_source = $room.paintover_source
        final_plate_export = $room.export_png
        godot_import_target = $room.godot_background_resource
        meshy_source_model_candidates = @(Get-RoomMeshyCandidates $room.room_id)
        generated_reference_allowed_for = @(Get-RoomGeneratedReference $room.room_id)
        forbidden_routes = @(
            "whole_room_meshy_generation",
            "generated_final_background_without_paintover",
            "merged_interactive_object_baked_only",
            "palette-unchecked export"
        )
        exits = $exitPipelines
        hotspots = $hotspotPipelines
    }
}

$contract = [ordered]@{
    generated_from = "docs/art/act_i_background_manifest.json"
    purpose = "Act I background element pipeline contract: what is Blender greybox, Meshy source-model helper, generated reference, baked paint, or separate interactive layer."
    global_pipeline_order = @(
        "Godot/Blender greybox locks perspective, walk band, exits, and hotspot readability.",
        "Blender render supplies perspective and lighting base.",
        "Meshy is allowed for reusable source props or structural models, never as the whole finished room.",
        "Generated images are allowed as concept, grime, mood, and dressing reference only; they must be repainted or heavily paintover-integrated.",
        "Final 2D paintover produces the room plate.",
        "Interactive objects stay separate from the baked plate when any verb, state, item, confession, duel, wetness, gate, or navigation logic touches them."
    )
    hard_rules = @(
        "Do not use Meshy as the main background generator.",
        "Do not ship a generated background plate without deterministic layout and paintover review.",
        "Do not bake interactive objects into the background as their only visual representation.",
        "Do not move hotspot centers without regenerating the Godot scene, hotspot map, background manifest, and this contract.",
        "Registrar art may frame the duel but must preserve the accepted Litany UI format.",
        "Grey Float stays hard-R: steam, silhouettes, labor, privacy, no explicit anatomy.",
        "All final exports must pass G9/G10 palette checks before shipping."
    )
    rooms = $rooms
}

$contract | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Act I Background Element Pipeline",
    "",
    'Generated by `tools/Export-ActIBackgroundElementPipeline.ps1` from `docs/art/act_i_background_manifest.json`.',
    "",
    "This answers the art-source decision for Act I: Blender greybox and paintover are authoritative; Meshy helps with reusable source props; generated images are reference only, not finished room plates.",
    "",
    "## Global Order",
    ""
)

foreach ($step in @($contract.global_pipeline_order)) {
    $lines += "- $step"
}

$lines += ""
$lines += "## Hard Rules"
$lines += ""
foreach ($rule in @($contract.hard_rules)) {
    $lines += "- $rule"
}
$lines += ""

foreach ($room in $rooms) {
    $lines += "## $($room.room_code) - $($room.title)"
    $lines += ""
    $lines += "- Layout source: ``$($room.camera_and_scale_source)``"
    $lines += "- Paintover source: ``$($room.final_plate_source)``"
    $lines += "- Export: ``$($room.final_plate_export)``"
    $lines += "- Godot import: ``$($room.godot_import_target)``"
    $lines += "- Meshy candidates: $(@($room.meshy_source_model_candidates) -join '; ')"
    $lines += "- Generated reference only: $(@($room.generated_reference_allowed_for) -join '; ')"
    $lines += ""
    $lines += "| Element | Kind | Position | Route | Why |"
    $lines += "|---|---|---:|---|---|"

    foreach ($exit in @($room.exits)) {
        $lines += "| $($exit.label) | exit | $($exit.position) | $($exit.pipeline_route) | Preserve navigation readability and Godot metadata. |"
    }
    foreach ($hotspot in @($room.hotspots)) {
        $lines += "| $($hotspot.label) | $($hotspot.type) | $($hotspot.position) | $($hotspot.pipeline_route) | $($hotspot.reason) |"
    }
    $lines += ""
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Act I background element pipeline -> $jsonPath"
Write-Host "Exported Act I background element pipeline brief -> $mdPath"
