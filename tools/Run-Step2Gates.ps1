$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    Write-Host "== Step 2 gates: Duel + prologue scaffold =="
    Write-Host ""

    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Run-Step1Gates.ps1")
    Write-Host ""

    Write-Host "[Step 2] Validate Godot/Popochiu prologue scaffold"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-GodotProject.ps1")
    Write-Host ""

    Write-Host "[Step 2] Validate Corvin runtime sprite assets"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-CorvinRuntimeSpriteAssets.ps1")
    Write-Host ""

    Write-Host "Step 2 automated gates passed."
}
finally {
    Pop-Location
}
