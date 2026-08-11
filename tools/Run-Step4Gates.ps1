$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")
$godot = Get-CorpseGodotPath -Kind Console
$gateTimeoutSeconds = 120

function Invoke-ProcessGate {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string[]]$ArgumentList,
        [int]$TimeoutSeconds = $gateTimeoutSeconds,
        [string[]]$AllowedErrorPatterns = @()
    )

    Write-Host "[$Name]"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $job = Start-Job -ScriptBlock {
        param([string]$ChildFilePath, [string[]]$ChildArgumentList, [string]$WorkingDirectory)

        Set-Location -LiteralPath $WorkingDirectory
        & $ChildFilePath @ChildArgumentList 2>&1
        $exit = $LASTEXITCODE
        if ($null -ne $exit -and $exit -ne 0) {
            throw "Native process failed with exit code $exit."
        }
    } -ArgumentList $FilePath, $ArgumentList, $root

    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
    $output = @(Receive-Job -Job $job)
    $output | Write-Host

    if ($null -eq $completed) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        throw "$Name timed out after $TimeoutSeconds seconds."
    }

    if ($job.State -eq "Failed") {
        $reason = if ($null -ne $job.ChildJobs[0].JobStateInfo.Reason) { [string]$job.ChildJobs[0].JobStateInfo.Reason.Message } else { "unknown failure" }
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        throw "$Name failed: $reason"
    }
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

    $unexpectedErrors = @(
        $output |
            Where-Object { $_ -match "^(SCRIPT ERROR|ERROR):" } |
            Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
            Where-Object { $_ -notmatch "resources still in use at exit" }
    )
    foreach ($pattern in $AllowedErrorPatterns) {
        $unexpectedErrors = @($unexpectedErrors | Where-Object { $_ -notmatch $pattern })
    }
    if ($unexpectedErrors.Count -gt 0) {
        throw "$Name produced unexpected errors: $($unexpectedErrors -join ' | ')"
    }

    $stopwatch.Stop()
    Write-Host "$Name passed in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s."
    Write-Host ""
}

function Invoke-PowerShellGate {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$ScriptName,
        [string[]]$ExtraArgs = @(),
        [int]$TimeoutSeconds = $gateTimeoutSeconds
    )

    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "$Name missing script: $scriptPath"
    }

    $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath) + $ExtraArgs
    Invoke-ProcessGate -Name $Name -FilePath "powershell" -ArgumentList $args -TimeoutSeconds $TimeoutSeconds
}

function Invoke-GodotGate {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$ScriptResource
    )

    Invoke-ProcessGate -Name $Name -FilePath $godot -ArgumentList @("--headless", "--path", $root, "--script", $ScriptResource)
}

Push-Location $root
try {
    Write-Host "== Step 4 gates: Act I greybox room graph =="
    Write-Host "Per-gate timeout: $gateTimeoutSeconds seconds."
    Write-Host ""

    Invoke-PowerShellGate -Name "Step 3 prerequisite gates" -ScriptName "Run-Step3Gates.ps1"
    Invoke-PowerShellGate -Name "Validate Act I puzzle dependency graph" -ScriptName "Validate-ActIPuzzleGraph.ps1"
    Invoke-PowerShellGate -Name "Validate Act I confession act gates" -ScriptName "Validate-ActIConfessionActGate.ps1"
    Invoke-PowerShellGate -Name "Validate Act I hotspot map export" -ScriptName "Validate-ActIHotspotMap.ps1"
    Invoke-PowerShellGate -Name "Validate Act I background production manifest" -ScriptName "Validate-ActIBackgroundManifest.ps1"
    Invoke-PowerShellGate -Name "Validate Act I background asset status" -ScriptName "Validate-ActIBackgroundAssetStatus.ps1"
    Invoke-PowerShellGate -Name "Validate Act I Blender blockout tasks" -ScriptName "Validate-ActIBlockoutTasks.ps1"
    Invoke-PowerShellGate -Name "Validate Act I background palette audit" -ScriptName "Validate-ActIBackgroundPaletteAudit.ps1"

    Invoke-PowerShellGate -Name "Validate Mudflats blockout asset" -ScriptName "Validate-MudflatsBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Old Quay blockout asset" -ScriptName "Validate-OldQuayBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Harbor Registry blockout asset" -ScriptName "Validate-HarborRegistryBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Bone Chandler blockout asset" -ScriptName "Validate-BoneChandlerBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Almshouse blockout asset" -ScriptName "Validate-AlmshouseBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Fish Hall blockout asset" -ScriptName "Validate-FishHallBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Salt Market blockout asset" -ScriptName "Validate-SaltMarketBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Church of the Drowned blockout asset" -ScriptName "Validate-ChurchOfTheDrownedBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Grey Float blockout asset" -ScriptName "Validate-GreyFloatBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Harbormaster Office blockout asset" -ScriptName "Validate-HarbormasterOfficeBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")
    Invoke-PowerShellGate -Name "Validate Sabine Office blockout asset" -ScriptName "Validate-SabineOfficeBlockout.ps1" -ExtraArgs @("-SkipSharedValidation")

    Invoke-PowerShellGate -Name "Validate Corvin animation manifest" -ScriptName "Validate-CorvinAnimationManifest.ps1"
    Invoke-PowerShellGate -Name "Validate Corvin Meshy source intake" -ScriptName "Validate-CorvinMeshySourceIntake.ps1"
    Invoke-PowerShellGate -Name "Validate Blender Corvin import preflight" -ScriptName "Validate-BlenderCorvinImport.ps1"
    Invoke-PowerShellGate -Name "Validate ink shader spike still renders" -ScriptName "Validate-InkShaderSpikeStills.ps1"
    Invoke-PowerShellGate -Name "Validate ink shader spike manifest" -ScriptName "Validate-InkShaderSpikeManifest.ps1"

    Invoke-GodotGate -Name "Validate Act I registered room graph" -ScriptResource "res://tools/godot_validate_act_i_rooms.gd"
    Invoke-GodotGate -Name "Validate Corvin room animation hooks" -ScriptResource "res://tools/godot_validate_corvin_room_animation_hooks.gd"
    Invoke-GodotGate -Name "Validate Act I quest flow" -ScriptResource "res://tools/godot_validate_act_i_quest_flow.gd"
    Invoke-GodotGate -Name "Validate Act I Rite order permutations" -ScriptResource "res://tools/godot_validate_act_i_rite_permutations.gd"

    Write-Host "Step 4 Act I greybox gates passed."
}
finally {
    Pop-Location
}
