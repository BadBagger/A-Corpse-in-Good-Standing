$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")

$console = Get-CorpseGodotPath -Kind Console
$windowed = Get-CorpseGodotPath -Kind Windowed

foreach ($path in @($console, $windowed)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Resolved Godot path does not exist: $path"
    }
}

if ($console -eq $windowed) {
    throw "Godot console and windowed executables resolved to the same path: $console"
}

if ($console -notmatch "Godot_v4\.6\.3-stable_mono_win64_console\.exe$") {
    throw "Godot console resolver returned unexpected executable: $console"
}

if ($windowed -notmatch "Godot_v4\.6\.3-stable_mono_win64\.exe$") {
    throw "Godot windowed resolver returned unexpected executable: $windowed"
}

Write-Host "Godot resolver validation passed: console=$console, windowed=$windowed"
