$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-CorvinSideActionRenderCommands.ps1"
$jsonPath = Join-Path $root "docs\art\corvin_side_action_render_commands.json"
$mdPath = Join-Path $root "docs\art\corvin_side_action_render_commands.md"
$scriptsStatusPath = Join-Path $root "docs\art\corvin_side_action_render_scripts_status.json"
$scriptsStatusMdPath = Join-Path $root "docs\art\corvin_side_action_render_scripts_status.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Corvin side action render commands exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Corvin side action render commands export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side action render commands artifact: $path"
    }
}

if (-not (Test-Path -LiteralPath $scriptsStatusPath) -or -not (Test-Path -LiteralPath $scriptsStatusMdPath)) {
    throw "Corvin side action render commands require render script status artifacts. Run tools\Validate-CorvinSideActionRenderScripts.ps1."
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $mdPath -Raw
$commands = @($payload.commands)
$scriptsStatus = Get-Content -LiteralPath $scriptsStatusPath -Raw | ConvertFrom-Json

if ($payload.status -notin @("ready_for_render_scripts", "blocked_blender_not_resolved")) {
    throw "Corvin side action render commands has unexpected status: $($payload.status)"
}
if ([int]$payload.timeout_seconds -ne 120) {
    throw "Corvin side action render commands must use a 120 second timeout."
}
if ($commands.Count -ne 6 -or [int]$payload.command_count -ne 6) {
    throw "Corvin side action render commands expected 6 commands, got $($commands.Count)."
}
if ($scriptsStatus.status -notin @("blocked_pending_keyed_blender_actions", "audit_contract_passed", "static_ready_blender_not_resolved", "partial_audit_pending")) {
    throw "Corvin side action render scripts status is invalid: $($scriptsStatus.status)"
}
if ([int]$scriptsStatus.script_count -ne 6) {
    throw "Corvin side action render scripts status expected 6 scripts, got $($scriptsStatus.script_count)."
}

$expected = @{
    talk = @{ frames = 6; width = 1536; action = "Corvin_act_i_clean_talk_side" }
    use = @{ frames = 8; width = 2048; action = "Corvin_act_i_clean_use_side" }
    wet = @{ frames = 8; width = 2048; action = "Corvin_act_i_clean_wet_side" }
}

foreach ($animation in @("talk", "use", "wet")) {
    foreach ($direction in @("side_right", "side_left")) {
        $command = @($commands | Where-Object { $_.animation -eq $animation -and $_.direction -eq $direction })[0]
        if ($null -eq $command) {
            throw "Corvin side action render commands missing $animation $direction."
        }
        if ($command.variant -ne "act_i_clean") {
            throw "Corvin side action render command $animation $direction has wrong variant."
        }
        if ($command.blender_action -ne $expected[$animation].action) {
            throw "Corvin side action render command $animation $direction has wrong Blender action: $($command.blender_action)"
        }
        if ([int]$command.frames -ne [int]$expected[$animation].frames -or [int]$command.fps -ne 12) {
            throw "Corvin side action render command $animation $direction has wrong frame/fps values."
        }
        if ([int]$command.expected_sheet_width -ne [int]$expected[$animation].width -or [int]$command.expected_sheet_height -ne 512) {
            throw "Corvin side action render command $animation $direction has wrong expected size."
        }
        if ($command.render_script -ne "art/src/characters/corvin/render_scripts/render_corvin_act_i_clean_$($animation)_$($direction).py") {
            throw "Corvin side action render command $animation $direction has wrong render script: $($command.render_script)"
        }
        if ($command.sheet_export -ne "art/export/characters/corvin/act_i_clean/$($animation)_$($direction).png") {
            throw "Corvin side action render command $animation $direction has wrong sheet target: $($command.sheet_export)"
        }
        if ($command.godot_import -ne "game/characters/corvin/sprites/act_i_clean/$($animation)_$($direction).png") {
            throw "Corvin side action render command $animation $direction has wrong Godot target: $($command.godot_import)"
        }
        $renderScriptCommandPath = ([string]$command.render_script).Replace("/", "\")
        $sheetCommandPath = ([string]$command.sheet_export).Replace("/", "\")
        foreach ($text in @(
            "--background",
            "--factory-startup",
            "--python",
            "--action",
            "--direction",
            "--frames",
            "--fps",
            "--cell-width",
            "--cell-height",
            "--shader-blend",
            "--out",
            $renderScriptCommandPath,
            $sheetCommandPath
        )) {
            if ([string]$command.blender_command -notmatch [regex]::Escape($text) -and [string]$command.powershell_timeout_command -notmatch [regex]::Escape($text)) {
                throw "Corvin side action render command $animation $direction missing command text: $text"
            }
        }
        foreach ($text in @("WaitForExit(120000)", "Stop-Process", "Blender render timed out after 120 seconds")) {
            if ([string]$command.powershell_timeout_command -notmatch [regex]::Escape($text)) {
                throw "Corvin side action render command $animation $direction missing timeout wrapper text: $text"
            }
        }
        $godotImportCommandPath = ([string]$command.godot_import).Replace("/", "\")
        if ([string]$command.import_command -notmatch [regex]::Escape("Copy-Item") -or [string]$command.import_command -notmatch [regex]::Escape($godotImportCommandPath)) {
            throw "Corvin side action render command $animation $direction has invalid import command."
        }
        if ([string]$command.audit_command -ne "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSideActionRenderQueue.ps1") {
            throw "Corvin side action render command $animation $direction has wrong audit command."
        }
        if (@($command.prerequisites).Count -lt 4) {
            throw "Corvin side action render command $animation $direction lost prerequisites."
        }
    }
}

foreach ($requiredText in @(
    "Corvin Side Action Render Commands",
    "dry-run handoff commands",
    "Do not create placeholder PNGs",
    "byte-for-byte",
    "Run the render queue validator after each import",
    "Wet remains physical brine",
    "Timeout-wrapped command",
    "Import command",
    "Audit command",
    "talk side_right",
    "talk side_left",
    "use side_right",
    "use side_left",
    "wet side_right",
    "wet side_left"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action render commands report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Corvin side action render commands report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin side action render commands report must stay ASCII-only."
}

Write-Host "Corvin side action render commands validation passed: commands=$($commands.Count), status=$($payload.status), timeout=$($payload.timeout_seconds)."
