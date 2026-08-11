$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$workflowPath = Join-Path $root ".github\workflows\headless-gates.yml"
$boundaryPath = Join-Path $root "docs\checkpoints\ci_gate_boundary.md"

if (-not (Test-Path -LiteralPath $workflowPath)) {
    throw "Missing GitHub Actions workflow: .github/workflows/headless-gates.yml"
}

if (-not (Test-Path -LiteralPath $boundaryPath)) {
    throw "Missing CI gate boundary checkpoint: docs/checkpoints/ci_gate_boundary.md"
}

$workflow = Get-Content -LiteralPath $workflowPath -Raw
$boundary = Get-Content -LiteralPath $boundaryPath -Raw

$requiredWorkflowPhrases = @(
    "name: Headless Gates",
    "runs-on: windows-latest",
    "lfs: true",
    "dotnet-version: 8.0.x",
    "tools\Run-RepoReadinessGates.ps1",
    "tools\Run-Step1Gates.ps1"
)

foreach ($phrase in $requiredWorkflowPhrases) {
    if (-not $workflow.Contains($phrase)) {
        throw "Headless Gates workflow missing required CI phrase: $phrase"
    }
}

$localOnlyGateNames = @(
    "Run-Step2Gates.ps1",
    "Run-Step3Gates.ps1",
    "Run-Step4Gates.ps1",
    "Run-Step5ReadinessGates.ps1"
)

foreach ($gateName in $localOnlyGateNames) {
    if ($workflow.Contains("tools\$gateName")) {
        throw "Headless Gates workflow must not run local-only Godot gate yet: tools\$gateName"
    }

    if (-not $boundary.Contains("tools\$gateName")) {
        throw "CI gate boundary doc missing local-only gate reference: tools\$gateName"
    }
}

$requiredBoundaryPhrases = @(
    "# CI Gate Boundary",
    "GitHub Actions Coverage",
    "Local-Only Gates",
    "Required Before Broadening CI",
    "tools\Resolve-Godot.ps1",
    "CORPSE_GODOT_CONSOLE",
    "CORPSE_GODOT_WINDOWED",
    "CORPSE_GODOT_DIR",
    "Keep the accepted Litany/Registrar duel format",
    "Do not add a second confession-spend UI",
    "Do not treat scratch VO as shipping-approved audio",
    "Do not start final Act I paintovers before human review signoff"
)

foreach ($phrase in $requiredBoundaryPhrases) {
    if (-not $boundary.Contains($phrase)) {
        throw "CI gate boundary doc missing required phrase: $phrase"
    }
}

$localGodotPath = "C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe"
if (-not $boundary.Contains($localGodotPath)) {
    throw "CI gate boundary doc must name the current local Godot executable path."
}

Write-Host "CI gate boundary validation passed: workflow=repo+step1, localOnlyGates=$($localOnlyGateNames.Count), guardrails=4."
