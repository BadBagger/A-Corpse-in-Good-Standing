$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$scaffoldPath = Join-Path $root "docs\art\corvin_side_action_scaffold.json"
$jsonPath = Join-Path $root "docs\art\corvin_side_action_render_queue.json"
$mdPath = Join-Path $root "docs\art\corvin_side_action_render_queue.md"
$cellWidth = 256
$cellHeight = 512

if (-not (Test-Path -LiteralPath $scaffoldPath)) {
    throw "Missing Corvin side action render queue input: $scaffoldPath"
}

$scaffold = Get-Content -LiteralPath $scaffoldPath -Raw | ConvertFrom-Json
$actions = @($scaffold.actions)
if ($actions.Count -ne 3) {
    throw "Corvin side action render queue expected 3 scaffold actions."
}

function Get-TargetStatus {
    param(
        [Parameter(Mandatory=$true)][string]$SheetTarget,
        [Parameter(Mandatory=$true)][string]$GodotTarget,
        [Parameter(Mandatory=$true)][int]$ExpectedWidth,
        [Parameter(Mandatory=$true)][int]$ExpectedHeight
    )

    $sheetPath = Join-Path $root ($SheetTarget -replace "/", "\")
    $godotPath = Join-Path $root ($GodotTarget -replace "/", "\")
    $sheetPresent = Test-Path -LiteralPath $sheetPath
    $godotPresent = Test-Path -LiteralPath $godotPath
    $blockers = New-Object System.Collections.Generic.List[string]

    if (-not $sheetPresent) {
        $blockers.Add("sheet_export_missing")
    }
    if ($sheetPresent -and -not $godotPresent) {
        $blockers.Add("godot_import_missing")
    }
    if (-not $sheetPresent -and $godotPresent) {
        $blockers.Add("godot_import_without_sheet_export")
    }

    $status = if ($sheetPresent -and $godotPresent) {
        "present_pending_dimension_audit"
    } elseif ($sheetPresent) {
        "sheet_present_pending_import"
    } else {
        "pending_render"
    }

    return [ordered]@{
        status = $status
        sheet_present = $sheetPresent
        godot_present = $godotPresent
        expected_width = $ExpectedWidth
        expected_height = $ExpectedHeight
        blockers = @($blockers)
    }
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($action in $actions) {
    $sheetTargets = @($action.sheet_export_targets)
    $godotTargets = @($action.godot_import_targets)
    if ($sheetTargets.Count -ne 2 -or $godotTargets.Count -ne 2) {
        throw "Corvin side action render queue action $($action.animation) must have 2 sheet and 2 Godot targets."
    }

    foreach ($direction in @("side_right", "side_left")) {
        $sheetTarget = @($sheetTargets | Where-Object { $_ -match "_$direction\.png$" })[0]
        $godotTarget = @($godotTargets | Where-Object { $_ -match "_$direction\.png$" })[0]
        if ([string]::IsNullOrWhiteSpace([string]$sheetTarget) -or [string]::IsNullOrWhiteSpace([string]$godotTarget)) {
            throw "Corvin side action render queue missing $direction target for $($action.animation)."
        }

        $expectedWidth = [int]$action.frames * $cellWidth
        $targetStatus = Get-TargetStatus -SheetTarget $sheetTarget -GodotTarget $godotTarget -ExpectedWidth $expectedWidth -ExpectedHeight $cellHeight
        $rows.Add([pscustomobject][ordered]@{
            priority = "P1_next_side_sheet"
            variant = [string]$action.variant
            animation = [string]$action.animation
            direction = $direction
            blender_action = [string]$action.blender_action
            frames = [int]$action.frames
            fps = [int]$action.fps
            loop = [bool]$action.loop
            cell_width = $cellWidth
            cell_height = $cellHeight
            expected_sheet_width = $expectedWidth
            expected_sheet_height = $cellHeight
            sheet_export = [string]$sheetTarget
            godot_import = [string]$godotTarget
            status = [string]$targetStatus.status
            sheet_present = [bool]$targetStatus.sheet_present
            godot_present = [bool]$targetStatus.godot_present
            blockers = @($targetStatus.blockers)
            render_source = [string]$action.source_blend
            shader_source = [string]$action.shader_blend
            acceptance_checks = @($action.acceptance_checks)
        })
    }
}

$pendingRows = @($rows | Where-Object { $_.status -eq "pending_render" })
$sheetPresentRows = @($rows | Where-Object { $_.sheet_present })
$godotPresentRows = @($rows | Where-Object { $_.godot_present })
$status = if ($pendingRows.Count -eq 6) { "pending_deterministic_blender_renders" } elseif ($pendingRows.Count -gt 0) { "partial_pending_review" } else { "render_outputs_present_pending_audit" }

$queue = [ordered]@{
    generated_from = "docs/art/corvin_side_action_scaffold.json"
    purpose = "Deterministic render and import queue for Act I clean side talk/use/wet Corvin sheets."
    status = $status
    cell_width = $cellWidth
    cell_height = $cellHeight
    total_rows = $rows.Count
    pending_render_count = $pendingRows.Count
    sheet_present_count = $sheetPresentRows.Count
    godot_present_count = $godotPresentRows.Count
    rule_locks = @(
        "Do not create placeholder PNGs to clear this queue.",
        "Only deterministic Blender renders from the canonical Act I clean source may satisfy sheet_export rows.",
        "Godot imports must be byte-for-byte copied from matching sheet exports until a reviewed import transform exists.",
        "Wet action must read as physical brine, not magic.",
        "These rows do not approve final animation polish."
    )
    post_render_checks = @(
        "Each PNG must match frames * 256 by 512 pixels.",
        "Each sheet must contain nonblank readable foreground in every frame.",
        "Frame 1 and the final frame must align with side idle registration for use and wet.",
        "Talk must loop cleanly from final frame to frame 1.",
        "No arterial red may appear in wet brine frames."
    )
    rows = @($rows.ToArray())
}

$queue | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Corvin Side Action Render Queue",
    "",
    'Generated by `tools/Export-CorvinSideActionRenderQueue.ps1`.',
    "",
    "Purpose: deterministic render and import queue for Act I clean side talk/use/wet Corvin sheets.",
    "",
    "Status: $status",
    "Total rows: $($rows.Count)",
    "Pending renders: $($pendingRows.Count)",
    "Sheet outputs present: $($sheetPresentRows.Count)",
    "Godot imports present: $($godotPresentRows.Count)",
    "",
    "Rule locks:",
    "- Do not create placeholder PNGs to clear this queue.",
    "- Only deterministic Blender renders from the canonical Act I clean source may satisfy sheet_export rows.",
    "- Godot imports must be byte-for-byte copied from matching sheet exports until a reviewed import transform exists.",
    "- Wet action must read as physical brine, not magic.",
    "- These rows do not approve final animation polish.",
    "",
    "Post-render checks:",
    "- Each PNG must match frames * 256 by 512 pixels.",
    "- Each sheet must contain nonblank readable foreground in every frame.",
    "- Frame 1 and the final frame must align with side idle registration for use and wet.",
    "- Talk must loop cleanly from final frame to frame 1.",
    "- No arterial red may appear in wet brine frames.",
    "",
    "| Animation | Direction | Blender Action | Frames | FPS | Loop | Status | Sheet | Godot Import |",
    "|---|---|---|---:|---:|---|---|---|---|"
)
foreach ($row in @($rows.ToArray())) {
    $lines += "| $($row.animation) | $($row.direction) | ``$($row.blender_action)`` | $($row.frames) | $($row.fps) | $($row.loop) | $($row.status) | ``$($row.sheet_export)`` | ``$($row.godot_import)`` |"
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Corvin side action render queue JSON -> $jsonPath"
Write-Host "Exported Corvin side action render queue report -> $mdPath"
Write-Host "Corvin side action render queue: status=$status, pending=$($pendingRows.Count), sheetPresent=$($sheetPresentRows.Count), godotPresent=$($godotPresentRows.Count)"
