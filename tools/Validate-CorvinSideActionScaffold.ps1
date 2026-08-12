$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\corvin_side_action_scaffold.json"
$mdPath = Join-Path $root "docs\art\corvin_side_action_scaffold.md"
$actionDir = Join-Path $root "art\src\characters\corvin\actions\act_i_clean"
$actionBlendStatusPath = Join-Path $root "docs\art\corvin_side_action_blend_status.json"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Author-CorvinSideActionBlend.ps1")
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-CorvinSideActionScaffold.ps1")

foreach ($path in @($jsonPath, $mdPath, $actionDir, $actionBlendStatusPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side action scaffold artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $mdPath -Raw
$blendStatus = Get-Content -LiteralPath $actionBlendStatusPath -Raw | ConvertFrom-Json
$actions = @($payload.actions)

if ($payload.status -ne "source_action_scaffold_ready_pending_render") {
    throw "Corvin side action scaffold has unexpected status: $($payload.status)"
}
if ([int]$payload.created_sheet_exports -ne 0 -or [int]$payload.created_godot_imports -ne 0) {
    throw "Corvin side action scaffold must not create PNG exports or Godot imports."
}
foreach ($source in @($payload.source_blend, $payload.shader_blend)) {
    $absoluteSource = Join-Path $root ([string]$source -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absoluteSource)) {
        throw "Corvin side action scaffold source missing: $source"
    }
}
if ($payload.render_source_blend -ne "art/src/characters/corvin/corvin_act_i_clean_side_actions.blend") {
    throw "Corvin side action scaffold must use the authored side-action render source blend."
}
if ($blendStatus.status -ne "authored_actions_pending_render_audit" -or $blendStatus.blend_path -ne $payload.render_source_blend) {
    throw "Corvin side action blend status does not match scaffold render source."
}
$authoredActionNames = @($blendStatus.actions | ForEach-Object { $_.name })
if ($actions.Count -ne 3) {
    throw "Corvin side action scaffold expected 3 actions, got $($actions.Count)."
}

$expected = [ordered]@{
    talk = @{
        action_id = "act_i_clean_talk_side"
        blender_action = "Corvin_act_i_clean_talk_side"
        frames = 6
        loop = $true
        phrases = @("full-VO dialogue", "first and last frame register cleanly", "feet remain planted")
    }
    use = @{
        action_id = "act_i_clean_use_side"
        blender_action = "Corvin_act_i_clean_use_side"
        frames = 8
        loop = $false
        phrases = @("Generic side-view item interaction", "contact frame", "generic hotspot response")
    }
    wet = @{
        action_id = "act_i_clean_wet_side"
        blender_action = "Corvin_act_i_clean_wet_side"
        frames = 8
        loop = $false
        phrases = @("Signature wet-verb", "physical brine", "does not obscure hotspot feedback")
    }
}

$sheetTargetCount = 0
$godotTargetCount = 0
foreach ($entry in $expected.GetEnumerator()) {
    $animation = $entry.Key
    $expect = $entry.Value
    $action = @($actions | Where-Object { $_.animation -eq $animation })[0]
    if ($null -eq $action) {
        throw "Corvin side action scaffold missing action: $animation"
    }
    if ($action.action_id -ne $expect.action_id) {
        throw "Corvin side action scaffold action $animation has wrong id: $($action.action_id)"
    }
    if ($action.blender_action -ne $expect.blender_action) {
        throw "Corvin side action scaffold action $animation has wrong Blender action: $($action.blender_action)"
    }
    if ($action.blender_action -notin $authoredActionNames) {
        throw "Corvin side action scaffold action $animation missing from authored side-action blend: $($action.blender_action)"
    }
    if ($action.render_source_blend -ne $payload.render_source_blend) {
        throw "Corvin side action scaffold action $animation has wrong render source blend."
    }
    if ([int]$action.frames -ne [int]$expect.frames -or @($action.frame_beats).Count -ne [int]$expect.frames) {
        throw "Corvin side action scaffold action $animation has wrong frame count."
    }
    if ([bool]$action.loop -ne [bool]$expect.loop) {
        throw "Corvin side action scaffold action $animation has wrong loop flag."
    }
    if ($action.scaffold_status -ne "source_action_scaffold_ready_pending_render") {
        throw "Corvin side action scaffold action $animation has unexpected status: $($action.scaffold_status)"
    }
    if ($action.sheet_status -ne "pending") {
        throw "Corvin side action scaffold action $animation should still have pending sheets, got $($action.sheet_status)."
    }
    if (@($action.directions).Count -ne 2 -or "side_right" -notin @($action.directions) -or "side_left" -notin @($action.directions)) {
        throw "Corvin side action scaffold action $animation must target side_right and side_left."
    }
    if (@($action.acceptance_checks).Count -lt 5) {
        throw "Corvin side action scaffold action $animation must include at least 5 acceptance checks."
    }
    if ([string]::IsNullOrWhiteSpace([string]$action.motion_intent) -or [string]::IsNullOrWhiteSpace([string]$action.mirror_policy)) {
        throw "Corvin side action scaffold action $animation must include motion intent and mirror policy."
    }

    $sheetTargets = @($action.sheet_export_targets)
    $godotTargets = @($action.godot_import_targets)
    if ($sheetTargets.Count -ne 2 -or $godotTargets.Count -ne 2) {
        throw "Corvin side action scaffold action $animation must include 2 sheet targets and 2 Godot targets."
    }
    $sheetTargetCount += $sheetTargets.Count
    $godotTargetCount += $godotTargets.Count
    foreach ($target in $sheetTargets + $godotTargets) {
        if ([string]::IsNullOrWhiteSpace([string]$target) -or [string]$target -match "\\") {
            throw "Corvin side action scaffold target must be repo-relative with forward slashes: $target"
        }
        $absoluteTarget = Join-Path $root ([string]$target -replace "/", "\")
        if (Test-Path -LiteralPath $absoluteTarget) {
            throw "Corvin side action scaffold must not report existing pending target: $target"
        }
    }

    $actionReportPath = Join-Path $actionDir "$animation`_side.action.md"
    if (-not (Test-Path -LiteralPath $actionReportPath)) {
        throw "Missing Corvin side action handoff: $actionReportPath"
    }
    $actionReport = Get-Content -LiteralPath $actionReportPath -Raw
    foreach ($phrase in @($expect.phrases + @($expect.blender_action, "No PNG sheet is created by this scaffold", "Do not create diffusion-per-frame production art"))) {
        if ($actionReport -notmatch [regex]::Escape($phrase)) {
            throw "Corvin side action handoff $animation missing required phrase: $phrase"
        }
    }
    if ($actionReport -match "[^\u0000-\u007F]") {
        throw "Corvin side action handoff $animation must stay ASCII-only."
    }
}

if ($sheetTargetCount -ne 6 -or $godotTargetCount -ne 6) {
    throw "Corvin side action scaffold expected 6 sheet targets and 6 Godot targets."
}
foreach ($requiredText in @(
    "Corvin Side Action Scaffold",
    "No PNG sheet is created by this scaffold",
    "Do not create diffusion-per-frame production art",
    "Corvin_act_i_clean_talk_side",
    "Corvin_act_i_clean_use_side",
    "Corvin_act_i_clean_wet_side",
    "Render source blend",
    "corvin_act_i_clean_side_actions.blend",
    "physical brine",
    "side talk/use/wet remain pending"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action scaffold report missing required text: $requiredText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin side action scaffold report must stay ASCII-only."
}

Write-Host "Corvin side action scaffold validation passed: actions=$($actions.Count), sheetTargets=$sheetTargetCount, importTargets=$godotTargetCount, status=$($payload.status)."
