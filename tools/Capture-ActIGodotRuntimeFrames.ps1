$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

Push-Location $root
try {
    $output = & python tools\Build-ActIGodotRuntimeFrames.py 2>&1
    $exit = $LASTEXITCODE
    $output | Write-Host
    if ($exit -ne 0) {
        throw "Act I Godot runtime-composition frame capture failed with exit code $exit"
    }
}
finally {
    Pop-Location
}
