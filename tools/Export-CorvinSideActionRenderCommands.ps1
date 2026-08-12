$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$queuePath = Join-Path $root "docs\art\corvin_side_action_render_queue.json"
$jsonPath = Join-Path $root "docs\art\corvin_side_action_render_commands.json"
$mdPath = Join-Path $root "docs\art\corvin_side_action_render_commands.md"

. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")

if (-not (Test-Path -LiteralPath $queuePath)) {
    throw "Missing Corvin side action render commands input: $queuePath"
}

$queue = Get-Content -LiteralPath $queuePath -Raw | ConvertFrom-Json
$rows = @($queue.rows)
if ($rows.Count -ne 6) {
    throw "Corvin side action render commands expected 6 queue rows."
}

$blenderPath = Get-CorpseBlenderPath -Optional
$blenderDisplayPath = if ($null -eq $blenderPath) { "<set CORPSE_BLENDER>" } else { $blenderPath }

function Get-AbsoluteRepoPath {
    param([Parameter(Mandatory=$true)][string]$RelativePath)

    return Join-Path $root ($RelativePath -replace "/", "\")
}

function Get-Quoted {
    param([Parameter(Mandatory=$true)][string]$Value)

    return '"' + ($Value -replace '"', '\"') + '"'
}

function Get-RenderScriptPath {
    param([Parameter(Mandatory=$true)][object]$Row)

    $scriptName = "render_corvin_$($Row.variant)_$($Row.animation)_$($Row.direction).py"
    return "art/src/characters/corvin/render_scripts/$scriptName"
}

$commands = New-Object System.Collections.Generic.List[object]
foreach ($row in $rows) {
    $renderScript = Get-RenderScriptPath -Row $row
    $renderScriptAbs = Get-AbsoluteRepoPath -RelativePath $renderScript
    $sourceAbs = Get-AbsoluteRepoPath -RelativePath ([string]$row.render_source)
    $sheetAbs = Get-AbsoluteRepoPath -RelativePath ([string]$row.sheet_export)
    $godotAbs = Get-AbsoluteRepoPath -RelativePath ([string]$row.godot_import)
    $shaderAbs = Get-AbsoluteRepoPath -RelativePath ([string]$row.shader_source)

    $commands.Add([pscustomobject][ordered]@{
        animation = [string]$row.animation
        direction = [string]$row.direction
        variant = [string]$row.variant
        status = [string]$row.status
        render_source = [string]$row.render_source
        shader_source = [string]$row.shader_source
        blender_action = [string]$row.blender_action
        frames = [int]$row.frames
        fps = [int]$row.fps
        expected_sheet_width = [int]$row.expected_sheet_width
        expected_sheet_height = [int]$row.expected_sheet_height
        render_script = $renderScript
        sheet_export = [string]$row.sheet_export
        godot_import = [string]$row.godot_import
        blender_command = "$([string](Get-Quoted -Value $blenderDisplayPath)) --background --factory-startup $([string](Get-Quoted -Value $sourceAbs)) --python $([string](Get-Quoted -Value $renderScriptAbs)) -- --action $([string](Get-Quoted -Value ([string]$row.blender_action))) --direction $([string](Get-Quoted -Value ([string]$row.direction))) --frames $([int]$row.frames) --fps $([int]$row.fps) --cell-width $([int]$row.cell_width) --cell-height $([int]$row.cell_height) --shader-blend $([string](Get-Quoted -Value $shaderAbs)) --out $([string](Get-Quoted -Value $sheetAbs))"
        powershell_timeout_command = "powershell -NoProfile -ExecutionPolicy Bypass -Command `"& { `$p = Start-Process -FilePath $([string](Get-Quoted -Value $blenderDisplayPath)) -ArgumentList @('--background','--factory-startup',$([string](Get-Quoted -Value $sourceAbs)),'--python',$([string](Get-Quoted -Value $renderScriptAbs)),'--','--action',$([string](Get-Quoted -Value ([string]$row.blender_action))),'--direction',$([string](Get-Quoted -Value ([string]$row.direction))),'--frames','$([int]$row.frames)','--fps','$([int]$row.fps)','--cell-width','$([int]$row.cell_width)','--cell-height','$([int]$row.cell_height)','--shader-blend',$([string](Get-Quoted -Value $shaderAbs)),'--out',$([string](Get-Quoted -Value $sheetAbs))) -PassThru -NoNewWindow; if (-not `$p.WaitForExit(120000)) { Stop-Process -Id `$p.Id -Force; throw 'Blender render timed out after 120 seconds.' }; if (`$p.ExitCode -ne 0) { throw `"Blender render failed with exit code `$(`$p.ExitCode).`" } }`""
        import_command = "Copy-Item -LiteralPath $([string](Get-Quoted -Value $sheetAbs)) -Destination $([string](Get-Quoted -Value $godotAbs)) -Force"
        audit_command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSideActionRenderQueue.ps1"
        prerequisites = @(
            "Create or update the render script before running Blender: $renderScript",
            "Render from canonical source blend: $($row.render_source)",
            "Use shader blend: $($row.shader_source)",
            "Do not create placeholder PNGs if Blender fails."
        )
    })
}

$payload = [ordered]@{
    generated_from = "docs/art/corvin_side_action_render_queue.json"
    purpose = "Operator command sheet for deterministic Corvin Act I clean side talk/use/wet renders."
    status = if ($null -eq $blenderPath) { "blocked_blender_not_resolved" } else { "ready_for_render_scripts" }
    blender_path = $blenderPath
    timeout_seconds = 120
    command_count = $commands.Count
    rule_locks = @(
        "These commands are deterministic render handoff commands; rendered outputs still require sheet audit and final animation review.",
        "Do not create placeholder PNGs to satisfy sheet exports.",
        "Every successful sheet render must be copied byte-for-byte to its Godot import target.",
        "Run the render queue validator after each import.",
        "Wet remains physical brine, not a magic effect."
    )
    commands = @($commands.ToArray())
}

$payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Corvin Side Action Render Commands",
    "",
    'Generated by `tools/Export-CorvinSideActionRenderCommands.ps1`.',
    "",
    "Purpose: operator command sheet for deterministic Corvin Act I clean side talk/use/wet renders.",
    "",
    "Status: $($payload.status)",
    "Timeout seconds: 120",
    "Command count: $($commands.Count)",
    "",
    "Rule locks:",
    "- These commands are deterministic render handoff commands; rendered outputs still require sheet audit and final animation review.",
    "- Do not create placeholder PNGs to satisfy sheet exports.",
    "- Every successful sheet render must be copied byte-for-byte to its Godot import target.",
    "- Run the render queue validator after each import.",
    "- Wet remains physical brine, not a magic effect.",
    "",
    "## Commands",
    ""
)

foreach ($command in @($commands.ToArray())) {
    $lines += "### $($command.animation) $($command.direction)"
    $lines += "- Status: $($command.status)"
    $lines += "- Render script: ``$($command.render_script)``"
    $lines += "- Sheet: ``$($command.sheet_export)``"
    $lines += "- Godot import: ``$($command.godot_import)``"
    $lines += "- Expected size: $($command.expected_sheet_width)x$($command.expected_sheet_height)"
    $lines += "- Blender command:"
    $lines += "  ``$($command.blender_command)``"
    $lines += "- Timeout-wrapped command:"
    $lines += "  ``$($command.powershell_timeout_command)``"
    $lines += "- Import command:"
    $lines += "  ``$($command.import_command)``"
    $lines += "- Audit command:"
    $lines += "  ``$($command.audit_command)``"
    $lines += ""
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Corvin side action render commands JSON -> $jsonPath"
Write-Host "Exported Corvin side action render commands report -> $mdPath"
Write-Host "Corvin side action render commands: status=$($payload.status), commands=$($commands.Count)"
