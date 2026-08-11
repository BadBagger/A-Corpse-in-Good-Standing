$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$probeJsonPath = Join-Path $root "docs\art\blender_corvin_import_probe.json"
$probeReportPath = Join-Path $root "docs\art\blender_corvin_import_probe.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-BlenderCorvinImport.ps1")

foreach ($path in @($probeJsonPath, $probeReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Blender Corvin import probe artifact: $path"
    }
}

$probe = Get-Content -LiteralPath $probeJsonPath -Raw | ConvertFrom-Json
if ($probe.status -notin @("pending", "audited")) {
    throw "Blender Corvin import probe must be pending or audited after validation: $($probe.status)"
}
if ($probe.timeout_seconds -ne 120) {
    throw "Blender Corvin import probe must use a 120 second timeout."
}
if ($probe.source_glb -ne "art/src/characters/corvin/meshy/corvin_act_i_clean.glb") {
    throw "Blender Corvin import probe uses wrong source GLB path."
}
if ($probe.character_blend -ne "art/src/characters/corvin/corvin_act_i_clean.blend") {
    throw "Blender Corvin import probe uses wrong character blend path."
}
if ($probe.shader_spike_blend -ne "art/src/shaders/ink_wash_shader_spike.blend") {
    throw "Blender Corvin import probe uses wrong shader spike blend path."
}

if ($probe.status -eq "audited") {
    if ($probe.source_glb_present -ne $true -or $probe.character_blend_present -ne $true -or $probe.shader_spike_blend_present -ne $true) {
        throw "Blender Corvin import probe audited but required source/blend files are not present."
    }
    if ([int]$probe.mesh_count -lt 1) {
        throw "Blender Corvin import probe audited but no meshes were found."
    }
    if ($null -eq $probe.imported_bounds -or $null -eq $probe.imported_bounds.size) {
        throw "Blender Corvin import probe audited but mesh bounds were not recorded."
    }
    if ([string]::IsNullOrWhiteSpace([string]$probe.blender_version)) {
        throw "Blender Corvin import probe audited but Blender version was not recorded."
    }
}

$report = Get-Content -LiteralPath $probeReportPath -Raw
foreach ($requiredText in @("Blender Corvin Import Probe", "headless Blender preflight", "Source GLB", "Shader spike blend", "Notes")) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Blender Corvin import probe report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Blender Corvin import probe report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Blender Corvin import probe report must stay ASCII-only."
}

Write-Host "Blender Corvin import validation passed: status=$($probe.status), meshes=$($probe.mesh_count), armatures=$($probe.armature_count), actions=$($probe.action_count)"
