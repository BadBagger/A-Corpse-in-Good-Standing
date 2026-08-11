$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    Write-Host "== Step 1 gates: Confession Duel prototype =="
    Write-Host ""

    Write-Host "[1/6] Export confessions"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-Confessions.ps1")
    Write-Host ""

    Write-Host "[2/6] Validate confession library"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-Confessions.ps1")
    Write-Host ""

    Write-Host "[3/6] Validate duel content"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-DuelContent.ps1")
    Write-Host ""

    Write-Host "[4/6] Run unit tests"
    dotnet test CorpseInGoodStanding.sln
    Write-Host ""

    Write-Host "[5/6] Run console smoke"
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Test-DuelConsole.ps1")
    Write-Host ""

    Write-Host "[6/6] Print balance report"
    dotnet run --project prototype\Corpse.DuelConsole -- --balance
    Write-Host ""

    Write-Host "Step 1 automated gates passed."
}
finally {
    Pop-Location
}
