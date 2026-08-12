$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $root "docs\checkpoints\production_blocker_index.md"
$validatorPath = Join-Path $PSScriptRoot "Validate-ProductionBlockerIndex.ps1"

function Invoke-ValidatorProcess {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "powershell"
    $escapedValidatorPath = $validatorPath.Replace('"', '\"')
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$escapedValidatorPath`""
    $startInfo.WorkingDirectory = $root
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false

    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    [pscustomobject]@{
        ExitCode = $process.ExitCode
        Output = ($stdout + $stderr)
    }
}

if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "Production blocker index is missing: docs/checkpoints/production_blocker_index.md"
}

if (-not (Test-Path -LiteralPath $validatorPath)) {
    throw "Production blocker index validator is missing: tools/Validate-ProductionBlockerIndex.ps1"
}

$originalText = Get-Content -LiteralPath $indexPath -Raw

try {
    $baseline = Invoke-ValidatorProcess
    $baseline.Output | Write-Host
    if ($baseline.ExitCode -ne 0) {
        throw "Baseline production blocker index validation failed: $($baseline.Output)"
    }

    $mutatedText = $originalText.Replace("- Do not treat scratch VO as shipping-approved audio.", "- Scratch VO timing packets exist.")
    if ($mutatedText -eq $originalText) {
        throw "Mutation failed to alter the production blocker index."
    }

    Set-Content -LiteralPath $indexPath -Value $mutatedText -NoNewline

    $mutation = Invoke-ValidatorProcess
    $failedAsExpected = $mutation.ExitCode -ne 0
    if ($mutation.Output -notlike "*Do not treat scratch VO as shipping-approved audio*") {
        throw "Production blocker index validator failed for the wrong reason after guardrail mutation: $($mutation.Output)"
    }

    if (-not $failedAsExpected) {
        throw "Production blocker index validator accepted a missing scratch-VO shipping guardrail."
    }

    Set-Content -LiteralPath $indexPath -Value $originalText -NoNewline

    $mutatedText = $originalText.Replace("read-only Blender import proof", "Blender probe evidence")
    if ($mutatedText -eq $originalText) {
        throw "Step 4 mutation failed to alter the production blocker index."
    }

    Set-Content -LiteralPath $indexPath -Value $mutatedText -NoNewline

    $step4Mutation = Invoke-ValidatorProcess
    $step4FailedAsExpected = $step4Mutation.ExitCode -ne 0
    if ($step4Mutation.Output -notlike "*read-only Blender import proof*") {
        throw "Production blocker index validator failed for the wrong reason after Step 4 evidence mutation: $($step4Mutation.Output)"
    }

    if (-not $step4FailedAsExpected) {
        throw "Production blocker index validator accepted missing read-only Step 4 Blender proof."
    }
}
finally {
    Set-Content -LiteralPath $indexPath -Value $originalText -NoNewline
}

$restored = Invoke-ValidatorProcess
$restored.Output | Write-Host
if ($restored.ExitCode -ne 0) {
    throw "Production blocker index validation failed after restoring mutation test fixture: $($restored.Output)"
}

Write-Host "Production blocker index tests passed: baseline validates, missing VO guardrail fails, missing Step 4 Blender proof fails, fixture restored."
