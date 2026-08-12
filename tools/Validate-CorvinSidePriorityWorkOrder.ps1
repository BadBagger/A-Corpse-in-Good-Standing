$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\corvin_side_priority_work_order.json"
$csvPath = Join-Path $root "docs\art\corvin_side_priority_work_order.csv"
$mdPath = Join-Path $root "docs\art\corvin_side_priority_work_order.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-CorvinSidePriorityWorkOrder.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side-priority work order artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$report = Get-Content -LiteralPath $mdPath -Raw
$workOrder = @($payload.work_order)
$sideSheetSpecs = $payload.side_sheet_specs

if ($payload.status -ne "side_action_sheets_present_pending_polish") {
    throw "Corvin side-priority work order has unexpected status: $($payload.status)"
}
if ($rows.Count -ne 20 -or $workOrder.Count -ne 20 -or $payload.counts.total -ne 20) {
    throw "Corvin side-priority work order expected 20 rows, got csv=$($rows.Count), json=$($workOrder.Count), total=$($payload.counts.total)."
}
if ($payload.counts.present -ne 20 -or $payload.counts.pending -ne 0) {
    throw "Corvin side-priority counts expected 20 present and 0 pending, got present=$($payload.counts.present), pending=$($payload.counts.pending)."
}
if ($payload.counts.runtime_present -ne 8 -or $payload.counts.side_action_present -ne 12 -or $payload.counts.next_pending -ne 0) {
    throw "Corvin side-priority expected 8 runtime-present rows, 12 side-action rows, and 0 next-pending rows, got runtime=$($payload.counts.runtime_present), action=$($payload.counts.side_action_present), next=$($payload.counts.next_pending)."
}
if ($null -eq $sideSheetSpecs) {
    throw "Corvin side-priority work order missing side_sheet_specs."
}

$allowedDirections = @("side_right", "side_left")
$allowedAnimations = @("idle", "walk", "talk", "use", "wet")
$allowedKinds = @("sheet_export", "godot_import")
foreach ($row in $rows) {
    if ($row.variant -ne "act_i_clean") {
        throw "Corvin side-priority work order must only target act_i_clean, got $($row.variant)."
    }
    if ($row.direction -notin $allowedDirections) {
        throw "Corvin side-priority work order contains non-side direction: $($row.direction)."
    }
    if ($row.animation -notin $allowedAnimations) {
        throw "Corvin side-priority work order contains unexpected animation: $($row.animation)."
    }
    if ($row.asset_kind -notin $allowedKinds) {
        throw "Corvin side-priority work order contains unexpected asset kind: $($row.asset_kind)."
    }
    if ($row.status -notin @("present", "pending")) {
        throw "Corvin side-priority work order contains unexpected status: $($row.status)."
    }
    if ([string]::IsNullOrWhiteSpace($row.relative_path) -or $row.relative_path -match "\\") {
        throw "Corvin side-priority work order path must be repo-relative with forward slashes: $($row.relative_path)"
    }
}

$presentRuntime = @($rows | Where-Object { $_.priority -eq "P0_polish_runtime_candidate" -and $_.status -eq "present" })
$presentSideActions = @($rows | Where-Object { $_.priority -eq "P1_side_action_present_pending_polish" -and $_.status -eq "present" })
$pendingNext = @($rows | Where-Object { $_.priority -eq "P1_next_side_sheet" -and $_.status -eq "pending" })
if ($presentRuntime.Count -ne 8) {
    throw "Corvin side-priority work order expected 8 present runtime polish rows, got $($presentRuntime.Count)."
}
if ($presentSideActions.Count -ne 12 -or $pendingNext.Count -ne 0) {
    throw "Corvin side-priority work order expected 12 present side-action rows and 0 pending next rows, got action=$($presentSideActions.Count), pending=$($pendingNext.Count)."
}

$requiredSpecs = [ordered]@{
    talk = @{
        order = 1
        action = "Corvin_act_i_clean_talk_side"
        frames = 6
        phrases = @("full-VO dialogue", "feet remain planted", "first and last frame register cleanly")
    }
    use = @{
        order = 2
        action = "Corvin_act_i_clean_use_side"
        frames = 8
        phrases = @("Generic side-view item interaction", "contact frame", "generic hotspot response")
    }
    wet = @{
        order = 3
        action = "Corvin_act_i_clean_wet_side"
        frames = 8
        phrases = @("Signature wet-verb", "physical brine", "does not obscure hotspot feedback")
    }
}

foreach ($entry in $requiredSpecs.GetEnumerator()) {
    $name = $entry.Key
    $expected = $entry.Value
    $spec = $sideSheetSpecs.$name
    if ($null -eq $spec) {
        throw "Corvin side-priority side_sheet_specs missing: $name"
    }
    if ([int]$spec.production_order -ne [int]$expected.order) {
        throw "Corvin side-priority spec $name has wrong production_order: $($spec.production_order)"
    }
    if ([string]$spec.blender_action -ne [string]$expected.action) {
        throw "Corvin side-priority spec $name has wrong blender_action: $($spec.blender_action)"
    }
    if (@($spec.frame_beats).Count -ne [int]$expected.frames) {
        throw "Corvin side-priority spec $name expected $($expected.frames) frame beats, got $(@($spec.frame_beats).Count)."
    }
    if (@($spec.acceptance_checks).Count -lt 5) {
        throw "Corvin side-priority spec $name expected at least 5 acceptance checks."
    }
    if ([string]::IsNullOrWhiteSpace([string]$spec.motion_intent) -or [string]::IsNullOrWhiteSpace([string]$spec.mirror_policy)) {
        throw "Corvin side-priority spec $name must include motion_intent and mirror_policy."
    }
    foreach ($phrase in @($expected.phrases)) {
        if ($report -notmatch [regex]::Escape($phrase)) {
            throw "Corvin side-priority report missing required $name spec phrase: $phrase"
        }
    }
}

foreach ($required in @(
    "idle_side_right",
    "idle_side_left",
    "walk_side_right",
    "walk_side_left",
    "talk_side_right",
    "talk_side_left",
    "use_side_right",
    "use_side_left",
    "wet_side_right",
    "wet_side_left"
)) {
    if ($report -notmatch [regex]::Escape($required)) {
        throw "Corvin side-priority report missing required animation direction: $required"
    }
}
foreach ($requiredText in @(
    "Corvin Side Priority Work Order",
    "Current playable side locomotion",
    "Side action sheets present pending polish",
    "Side sheet specs",
    "Blender action",
    "Frame beats",
    "Acceptance checks",
    "full-VO dialogue",
    "permanent wet verb",
    "Do not use diffusion-per-frame character sheets"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side-priority report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "System.Object[]", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Corvin side-priority report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin side-priority report must stay ASCII-only."
}

Write-Host "Corvin side-priority work order validation passed: rows=$($rows.Count), present=$($payload.counts.present), pending=$($payload.counts.pending)."
