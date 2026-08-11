$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    Write-Host "== Step 3 gates: Ink + narrative persistence =="
    Write-Host ""

    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Run-Step2Gates.ps1")
    Write-Host ""

    Write-Host "[Step 3] Validate Ink compile and confession references"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-Ink.ps1")
    Write-Host ""

    Write-Host "[Step 3] Validate Godot Ink bridge runtime"
    $godot = "C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe"
    if (-not (Test-Path -LiteralPath $godot)) {
        throw "Godot 4.6.3 .NET console executable not found: $godot"
    }
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $inkBridgeOutput = & $godot --headless --path $root --script "res://tools/godot_validate_ink_bridge.gd" 2>&1
    $inkBridgeExit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $inkBridgeOutput | Write-Host
    $inkBridgeErrors = @(
        $inkBridgeOutput |
            Where-Object { $_ -match "^(SCRIPT ERROR|ERROR):" } |
            Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
            Where-Object { $_ -notmatch "resources still in use at exit" }
    )
    if ($inkBridgeErrors.Count -gt 0) {
        throw "Godot Ink bridge validation produced errors: $($inkBridgeErrors -join ' | ')"
    }
    if ($inkBridgeExit -ne 0) {
        $knownShutdownOnly = @(
            $inkBridgeOutput |
                Where-Object { $_ -match "^(ERROR|WARNING):" } |
                Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
                Where-Object { $_ -notmatch "resources still in use at exit" } |
                Where-Object { $_ -notmatch "ObjectDB instances leaked at exit" } |
                Where-Object { $_ -notmatch "RIDs of type `"CanvasItem`" were leaked" }
        )
        if ($knownShutdownOnly.Count -gt 0) {
            throw "Godot Ink bridge validation failed with exit code $inkBridgeExit"
        }
        Write-Host "Godot Ink bridge returned exit code $inkBridgeExit from known headless shutdown cleanup noise; continuing."
    }
    Write-Host ""

    Write-Host "[Step 3] Run narrative tests"
    dotnet test tests\Corpse.Narrative.Tests\Corpse.Narrative.Tests.csproj
    Write-Host ""

    Write-Host "Step 3 automated gates passed."
}
finally {
    Pop-Location
}
