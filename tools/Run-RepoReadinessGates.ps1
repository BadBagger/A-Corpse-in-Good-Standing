$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

function Invoke-RepoGate {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$ScriptName,
        [int]$TimeoutSeconds = 120
    )

    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "$Name missing script: $scriptPath"
    }

    Write-Host "[$Name]"
    $job = Start-Job -ScriptBlock {
        param([string]$Path, [string]$WorkingDirectory)
        Set-Location -LiteralPath $WorkingDirectory
        powershell -NoProfile -ExecutionPolicy Bypass -File $Path 2>&1
        $exit = $LASTEXITCODE
        if ($null -ne $exit -and $exit -ne 0) {
            throw "Native process failed with exit code $exit."
        }
    } -ArgumentList $scriptPath, $root

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

Push-Location $root
try {
    Write-Host "== Repo readiness gates =="
    Write-Host "This proves commit/package hygiene only; it does not replace Step 1-5 build gates."
    Write-Host ""

    Invoke-RepoGate -Name "Validate source-control and LFS readiness" -ScriptName "Validate-SourceControlReadiness.ps1"
    Invoke-RepoGate -Name "Validate text artifact hygiene" -ScriptName "Validate-TextArtifactHygiene.ps1"
    Invoke-RepoGate -Name "Validate production blocker index" -ScriptName "Validate-ProductionBlockerIndex.ps1"
    Invoke-RepoGate -Name "Test production blocker index" -ScriptName "Test-ProductionBlockerIndex.ps1"
    Invoke-RepoGate -Name "Validate CI gate boundary" -ScriptName "Validate-CiGateBoundary.ps1"
    Invoke-RepoGate -Name "Validate Ink compiler" -ScriptName "Validate-InkCompiler.ps1"
    Invoke-RepoGate -Name "Validate Act I background source intake" -ScriptName "Validate-ActIBackgroundSourceIntake.ps1"
    Invoke-RepoGate -Name "Validate Act I ready source packets" -ScriptName "Validate-ActIBackgroundReadySourcePackets.ps1"
    Invoke-RepoGate -Name "Validate Act I Meshy queue" -ScriptName "Validate-ActIBackgroundMeshyQueue.ps1"

    Write-Host "Repo readiness gates passed."
}
finally {
    Pop-Location
}
