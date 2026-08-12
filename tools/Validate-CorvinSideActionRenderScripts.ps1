$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$commandsPath = Join-Path $root "docs\art\corvin_side_action_render_commands.json"
$rendererPath = Join-Path $root "art\src\characters\corvin\render_scripts\corvin_side_action_renderer.py"
$statusJsonPath = Join-Path $root "docs\art\corvin_side_action_render_scripts_status.json"
$statusMdPath = Join-Path $root "docs\art\corvin_side_action_render_scripts_status.md"
$timeoutSeconds = 120

. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")

if (-not (Test-Path -LiteralPath $commandsPath)) {
    throw "Missing Corvin side action render scripts input: $commandsPath"
}
if (-not (Test-Path -LiteralPath $rendererPath)) {
    throw "Missing shared Corvin side action renderer: $rendererPath"
}

$commandsPayload = Get-Content -LiteralPath $commandsPath -Raw | ConvertFrom-Json
$commands = @($commandsPayload.commands)
if ($commands.Count -ne 6) {
    throw "Corvin side action render scripts expected 6 command rows."
}

$rendererText = Get-Content -LiteralPath $rendererPath -Raw
foreach ($requiredText in @(
    "ALLOWED",
    "Refusing to overwrite existing render output without review",
    "Required Blender action is missing",
    "No PNG was written",
    "Frame renders complete but sheet assembly is intentionally not automatic yet",
    "audit_contract",
    "film_transparent"
)) {
    if ($rendererText -notmatch [regex]::Escape($requiredText)) {
        throw "Shared Corvin side action renderer missing required guardrail text: $requiredText"
    }
}
if ($rendererText -match "[^\u0000-\u007F]") {
    throw "Shared Corvin side action renderer must stay ASCII-only."
}

$blenderPath = Get-CorpseBlenderPath -Optional
$results = New-Object System.Collections.Generic.List[object]
$auditFailures = New-Object System.Collections.Generic.List[string]

foreach ($command in $commands) {
    $scriptPath = Join-Path $root ([string]$command.render_script -replace "/", "\")
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Missing Corvin side action render script: $($command.render_script)"
    }

    $entryText = Get-Content -LiteralPath $scriptPath -Raw
    foreach ($requiredText in @(
        "from corvin_side_action_renderer import main",
        "expected_animation=""$($command.animation)""",
        "expected_direction=""$($command.direction)"""
    )) {
        if ($entryText -notmatch [regex]::Escape($requiredText)) {
            throw "Corvin side action render script $($command.render_script) missing required text: $requiredText"
        }
    }
    if ($entryText -match "[^\u0000-\u007F]") {
        throw "Corvin side action render script must stay ASCII-only: $($command.render_script)"
    }

    $auditStatus = "not_run"
    $auditNote = ""
    if ($null -ne $blenderPath) {
        $sourceBlend = Join-Path $root ([string]$command.render_source -replace "/", "\")
        $shaderBlend = Join-Path $root ([string]$command.shader_source -replace "/", "\")
        $outPath = Join-Path $root ([string]$command.sheet_export -replace "/", "\")
        $stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) ("corvin_render_script_audit_" + [System.Guid]::NewGuid().ToString("N") + ".stdout.txt")
        $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ("corvin_render_script_audit_" + [System.Guid]::NewGuid().ToString("N") + ".stderr.txt")

        $argumentList = @(
            "--background",
            "--factory-startup",
            "`"$sourceBlend`"",
            "--python",
            "`"$scriptPath`"",
            "--",
            "--action",
            "`"$([string]$command.blender_action)`"",
            "--direction",
            "`"$([string]$command.direction)`"",
            "--frames",
            [string]$command.frames,
            "--fps",
            [string]$command.fps,
            "--cell-width",
            "256",
            "--cell-height",
            "512",
            "--shader-blend",
            "`"$shaderBlend`"",
            "--out",
            "`"$outPath`"",
            "--audit-contract"
        ) -join " "

        $process = Start-Process -FilePath $blenderPath `
            -ArgumentList $argumentList `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
            Stop-Process -Id $process.Id -Force
            $auditStatus = "failed"
            $auditNote = "Timed out after $timeoutSeconds seconds."
        }
        else {
            $process.Refresh()
            $stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -LiteralPath $stdoutPath -Raw } else { "" }
            $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { "" }
            if ($null -eq $stdout) { $stdout = "" }
            if ($null -eq $stderr) { $stderr = "" }
            if (($process.ExitCode -eq 0 -or $null -eq $process.ExitCode) -and $stdout -match [regex]::Escape("Corvin side-action render contract audited")) {
                $auditStatus = "passed"
                $auditNote = "Blender audit-contract completed without writing PNG output."
            }
            elseif ($stderr -match [regex]::Escape("Required Blender action is missing") -and $stderr -match [regex]::Escape("No PNG was written")) {
                $auditStatus = "blocked_missing_keyed_action"
                $auditNote = "Blender executed the entrypoint and refused output because the keyed action is not present yet."
            }
            else {
                $auditStatus = "failed"
                $auditNote = "Exit code $($process.ExitCode). stdout=$($stdout.Trim()) stderr=$($stderr.Trim())"
            }
        }

        if (Test-Path -LiteralPath $outPath) {
            throw "Corvin render script audit must not create sheet output: $($command.sheet_export)"
        }
        if ($auditStatus -eq "failed") {
            $auditFailures.Add("$($command.animation) $($command.direction): $auditNote")
        }
    }

    $results.Add([pscustomobject][ordered]@{
        animation = [string]$command.animation
        direction = [string]$command.direction
        render_script = [string]$command.render_script
        blender_action = [string]$command.blender_action
        frames = [int]$command.frames
        fps = [int]$command.fps
        audit_status = $auditStatus
        audit_note = $auditNote
    })
}

if ($auditFailures.Count -gt 0) {
    throw "Corvin side action render script Blender audits failed: $($auditFailures -join '; ')"
}

$missingActionRows = @($results | Where-Object { $_.audit_status -eq "blocked_missing_keyed_action" })
$passedAuditRows = @($results | Where-Object { $_.audit_status -eq "passed" })
$status = if ($null -eq $blenderPath) {
    "static_ready_blender_not_resolved"
} elseif ($missingActionRows.Count -eq $results.Count) {
    "blocked_pending_keyed_blender_actions"
} elseif ($passedAuditRows.Count -eq $results.Count) {
    "audit_contract_passed"
} else {
    "partial_audit_pending"
}
$payload = [ordered]@{
    generated_from = "docs/art/corvin_side_action_render_commands.json"
    purpose = "Static and Blender audit-contract validation for Corvin side-action render scripts."
    status = $status
    timeout_seconds = $timeoutSeconds
    renderer = "art/src/characters/corvin/render_scripts/corvin_side_action_renderer.py"
    script_count = $results.Count
    missing_keyed_action_count = $missingActionRows.Count
    passed_audit_count = $passedAuditRows.Count
    blender_path = $blenderPath
    rule_locks = @(
        "Audit mode must not create PNG sheet outputs.",
        "Render scripts must refuse to overwrite existing output without review.",
        "Render scripts must fail if the named Blender action is absent.",
        "Sheet assembly remains manual/audited until registration checks exist.",
        "No placeholder PNGs are permitted."
    )
    scripts = @($results.ToArray())
}

$payload | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $statusJsonPath -Encoding UTF8

$lines = @(
    "# Corvin Side Action Render Scripts Status",
    "",
    'Generated by `tools/Validate-CorvinSideActionRenderScripts.ps1`.',
    "",
    "Purpose: static and Blender audit-contract validation for Corvin side-action render scripts.",
    "",
    "Status: $status",
    "Timeout seconds: $timeoutSeconds",
    "Script count: $($results.Count)",
    "Missing keyed Blender actions: $($missingActionRows.Count)",
    "Passed audit-contract rows: $($passedAuditRows.Count)",
    "",
    "Rule locks:",
    "- Audit mode must not create PNG sheet outputs.",
    "- Render scripts must refuse to overwrite existing output without review.",
    "- Render scripts must fail if the named Blender action is absent.",
    "- Sheet assembly remains manual/audited until registration checks exist.",
    "- No placeholder PNGs are permitted.",
    "",
    "| Animation | Direction | Script | Audit |",
    "|---|---|---|---|"
)
foreach ($result in @($results.ToArray())) {
    $lines += "| $($result.animation) | $($result.direction) | ``$($result.render_script)`` | $($result.audit_status) |"
}

Set-Content -LiteralPath $statusMdPath -Value $lines -Encoding UTF8

Write-Host "Corvin side action render scripts validation passed: scripts=$($results.Count), status=$status."
