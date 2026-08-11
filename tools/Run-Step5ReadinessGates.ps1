$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

function Invoke-Step {
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
    Write-Host "== Step 5 readiness gates: Act I art pass =="
    Write-Host "This proves readiness for art-pass review; it does not claim final art is complete."
    Write-Host ""

    Invoke-Step -Name "Refresh automated Act I playtest report" -ScriptName "Record-ActIGreyboxPlaytest.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I background element pipeline" -ScriptName "Validate-ActIBackgroundElementPipeline.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I background source worklist" -ScriptName "Validate-ActIBackgroundSourceWorklist.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I background source prompts" -ScriptName "Validate-ActIBackgroundSourcePrompts.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I paintover packet" -ScriptName "Validate-ActIPaintoverPacket.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I art readability review" -ScriptName "Validate-ActIArtReadabilityReview.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I review contact sheet" -ScriptName "Validate-ActIReviewContactSheet.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I human review notes" -ScriptName "Validate-ActIHumanReviewNotes.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I VO line manifest" -ScriptName "Validate-ActIVoLineManifest.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate confession VO manifest" -ScriptName "Validate-ConfessionVoManifest.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate VO recording batches" -ScriptName "Validate-VoRecordingBatches.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate VO cast plan" -ScriptName "Validate-VoCastPlan.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate VO commercial readiness" -ScriptName "Validate-VoCommercialReadiness.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test VO commercial readiness" -ScriptName "Test-VoCommercialReadiness.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate VO recording queue" -ScriptName "Validate-VoRecordingQueue.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate VO recording packets" -ScriptName "Validate-VoRecordingPackets.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate VO minor speaker decision template" -ScriptName "Validate-VoMinorSpeakerDecisionTemplate.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test VO minor speaker decision import" -ScriptName "Test-VoMinorSpeakerDecisionImport.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test VO audio asset status" -ScriptName "Test-VoAudioAssetStatus.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I review fix tracker" -ScriptName "Validate-ActIReviewFixTracker.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test Act I review decision updater" -ScriptName "Test-ActIReviewDecisionUpdater.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I review decision template" -ScriptName "Validate-ActIReviewDecisionTemplate.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test Act I review decision batch import" -ScriptName "Test-ActIReviewDecisionBatchImport.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I paintover source scaffold" -ScriptName "Validate-ActIPaintoverSourceScaffold.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I paintover start gate" -ScriptName "Validate-ActIPaintoverStartGate.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test Act I paintover work order" -ScriptName "Test-ActIPaintoverWorkOrder.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I paintover work order" -ScriptName "Validate-ActIPaintoverWorkOrder.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test Act I paintover source intake" -ScriptName "Test-ActIPaintoverSourceIntake.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I paintover source intake" -ScriptName "Validate-ActIPaintoverSourceIntake.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test Act I final paintover completion" -ScriptName "Test-ActIFinalPaintoverCompletion.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I final paintover completion" -ScriptName "Validate-ActIFinalPaintoverCompletion.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test Act I paintover review provenance" -ScriptName "Test-ActIPaintoverReviewProvenance.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I paintover review provenance" -ScriptName "Validate-ActIPaintoverReviewProvenance.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Step 5 review dashboard" -ScriptName "Validate-Step5ReviewDashboard.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Step 5 human review bundle" -ScriptName "Validate-Step5HumanReviewBundle.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Act I review handoff sync" -ScriptName "Validate-ActIReviewHandoffSync.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Test Act I review handoff sync" -ScriptName "Test-ActIReviewHandoffSync.ps1" -TimeoutSeconds 120
    Invoke-Step -Name "Validate Step 5 Act I art-pass readiness" -ScriptName "Validate-Step5ActIArtReadiness.ps1" -TimeoutSeconds 120

    Write-Host "Step 5 Act I art-pass readiness gates passed."
}
finally {
    Pop-Location
}
