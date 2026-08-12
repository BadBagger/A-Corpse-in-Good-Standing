$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\review\project_visual_target_reference.json"
$mdPath = Join-Path $root "docs\art\review\project_visual_target_reference.md"
$imagePath = Join-Path $root "docs\art\review\project_visual_target_mockup_v1.png"

foreach ($path in @($jsonPath, $mdPath, $imagePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing project visual target reference artifact: $path"
    }
}

$reference = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$brief = Get-Content -LiteralPath $mdPath -Raw -Encoding UTF8
$image = Get-Item -LiteralPath $imagePath

if ($reference.status -ne "reference_only") {
    throw "Project visual target must stay reference_only, got: $($reference.status)"
}
if ($reference.image_path -ne "docs/art/review/project_visual_target_mockup_v1.png") {
    throw "Project visual target image_path must use the repo-relative review image path."
}
if ($image.Length -lt 500000) {
    throw "Project visual target mockup image is unexpectedly small: $($image.Length) bytes."
}

foreach ($allowed in @(
    "mood reference",
    "composition reference",
    "amber_green_lighting_reference",
    "side_view_readability_reference",
    "ui_density_reference"
)) {
    if ($allowed -notin @($reference.allowed_uses)) {
        throw "Project visual target missing allowed use: $allowed"
    }
}

foreach ($forbidden in @(
    "runtime_background",
    "final_room_art",
    "sprite_source",
    "hotspot_authority",
    "palette_gate_proof",
    "blender_greybox_replacement"
)) {
    if ($forbidden -notin @($reference.forbidden_uses)) {
        throw "Project visual target missing forbidden use: $forbidden"
    }
}

foreach ($required in @(
    "reference only",
    "not final room art",
    "not a runtime background",
    "not a sprite source",
    "not palette-gate proof",
    "Corvin is a little too three-quarter",
    "actual animation sheets should keep him stricter side-on",
    "Meshy helper geometry / Blender greybox -> ink-wash render pass -> paintover -> Godot 2D room"
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Project visual target report missing required text: $required"
    }
}

foreach ($badToken in @("final asset approved", "ship this background", "runtime-ready", "palette proof passed")) {
    if ($brief -match [regex]::Escape($badToken)) {
        throw "Project visual target report contains forbidden approval language: $badToken"
    }
}

Write-Host "Project visual target reference validation passed: image=$($image.Name), bytes=$($image.Length), status=$($reference.status)."
