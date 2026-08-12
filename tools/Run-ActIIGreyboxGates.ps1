$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$gateTimeoutSeconds = 120

function Invoke-ProcessGate {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string[]]$ArgumentList,
        [int]$TimeoutSeconds = $gateTimeoutSeconds
    )

    Write-Host "[$Name]"
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
    Write-Host "$Name passed."
    Write-Host ""
}

function Invoke-PowerShellGate {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$ScriptName
    )

    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "$Name missing script: $scriptPath"
    }

    Invoke-ProcessGate -Name $Name -FilePath "powershell" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath)
}

Push-Location $root
try {
    Write-Host "== Act II greybox gates =="
    Write-Host "Per-gate timeout: $gateTimeoutSeconds seconds."
    Write-Host ""

    Invoke-PowerShellGate -Name "Act II planning gates" -ScriptName "Run-ActIIPlanningGates.ps1"
    Invoke-PowerShellGate -Name "Validate Act II greybox rooms" -ScriptName "Validate-ActIIGreyboxRooms.ps1"

    Write-Host "Act II greybox gates passed."
}
finally {
    Pop-Location
}
