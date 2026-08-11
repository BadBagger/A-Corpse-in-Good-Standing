$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$output = dotnet run --project (Join-Path $root "prototype\Corpse.DuelConsole") -- --scripted-win

if ($LASTEXITCODE -ne 0) {
    throw "Console prototype exited with code $LASTEXITCODE"
}
if (($output -join "`n") -notmatch "RESULT: Corvin wins") {
    throw "Console prototype did not produce the scripted win result"
}
if (($output -join "`n") -match "Hello, World") {
    throw "Console prototype is still the template app"
}

Write-Host "Duel console smoke passed: scripted Registrar win"
