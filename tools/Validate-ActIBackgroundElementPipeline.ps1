$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_element_pipeline.json"
$mdPath = Join-Path $root "docs\art\act_i_background_element_pipeline.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundElementPipeline.ps1")

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background element pipeline artifact: $path"
    }
}

$contract = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$brief = Get-Content -LiteralPath $mdPath -Raw
$rooms = @($contract.rooms)

if ($rooms.Count -ne 11) {
    throw "Act I background element pipeline expected 11 rooms, got $($rooms.Count)."
}

foreach ($required in @(
    "Do not use Meshy as the main background generator.",
    "Generated images are allowed as concept",
    "Final 2D paintover produces the room plate.",
    "Interactive objects stay separate",
    "Registrar art may frame the duel",
    "Grey Float stays hard-R"
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Background element pipeline brief missing required guidance: $required"
    }
}

foreach ($room in $rooms) {
    foreach ($forbidden in @("whole_room_meshy_generation", "generated_final_background_without_paintover", "merged_interactive_object_baked_only")) {
        if ($forbidden -notin @($room.forbidden_routes)) {
            throw "Room $($room.room_id) is missing forbidden route lock: $forbidden"
        }
    }

    if (@($room.meshy_source_model_candidates).Count -lt 3) {
        throw "Room $($room.room_id) has too few Meshy source-model candidates."
    }
    if (@($room.generated_reference_allowed_for).Count -lt 3) {
        throw "Room $($room.room_id) has too few generated-reference categories."
    }

    foreach ($hotspot in @($room.hotspots)) {
        $roles = @($hotspot.critical_roles)
        $isLogicTouched = $false
        foreach ($role in $roles) {
            if ($role -in @("duel", "wet_verb", "conditional_followup", "blocked_feedback", "confession_source", "item_reward", "gated", "custom_navigation")) {
                $isLogicTouched = $true
            }
        }

        if ($isLogicTouched -and $hotspot.pipeline_route -ne "separate_interactive_sprite_or_hotspot_layer") {
            throw "Logic-touched hotspot $($room.room_id)/$($hotspot.name) must stay separate, got $($hotspot.pipeline_route)."
        }

        if (-not $isLogicTouched -and $hotspot.pipeline_route -ne "baked_paintover_dressing") {
            throw "Scene-texture hotspot $($room.room_id)/$($hotspot.name) should be baked dressing, got $($hotspot.pipeline_route)."
        }
    }
}

$registry = @($rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
$registrar = @($registry.hotspots | Where-Object { $_.name -eq "Registrar" })[0]
if ($null -eq $registrar -or $registrar.pipeline_route -ne "separate_interactive_sprite_or_hotspot_layer") {
    throw "Registrar duel hotspot must remain a separate interactive layer."
}

$greyFloat = @($rooms | Where-Object { $_.room_id -eq "grey_float" })[0]
if ($null -eq $greyFloat -or "non-explicit labor staging" -notin @($greyFloat.generated_reference_allowed_for)) {
    throw "Grey Float generated-reference guidance must preserve hard-R non-explicit staging."
}

if ($brief -match "generated_final_background_without_paintover\s+\|\s*allowed") {
    throw "Background element pipeline appears to allow generated final backgrounds."
}

Write-Host "Act I background element pipeline validation passed: rooms=$($rooms.Count), registrar=separate, grey_float=hard_R"
