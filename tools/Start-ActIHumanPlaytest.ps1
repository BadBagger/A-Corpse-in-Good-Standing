param(
    [switch]$RefreshAutomatedReport,
    [switch]$SkipNotes,
    [switch]$Editor,
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$godotDir = "C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64"
$godotWindowed = Join-Path $godotDir "Godot_v4.6.3-stable_mono_win64.exe"
$godotConsole = Join-Path $godotDir "Godot_v4.6.3-stable_mono_win64_console.exe"

if (-not (Test-Path -LiteralPath $godotWindowed)) {
    throw "Godot 4.6.3 .NET windowed executable not found: $godotWindowed"
}

if (-not (Test-Path -LiteralPath $godotConsole)) {
    throw "Godot 4.6.3 .NET console executable not found: $godotConsole"
}

$projectPath = Join-Path $root "project.godot"
if (-not (Test-Path -LiteralPath $projectPath)) {
    throw "Missing Godot project file: $projectPath"
}

if ($RefreshAutomatedReport) {
    & (Join-Path $PSScriptRoot "Record-ActIGreyboxPlaytest.ps1")
}

if (-not $SkipNotes) {
    & (Join-Path $PSScriptRoot "New-ActIHumanPlaytestNotes.ps1")
}

$launchArgs = @("--path", $root)
if ($Editor) {
    $launchArgs += "--editor"
}

if ($NoLaunch) {
    Write-Host "Act I human playtest launch preflight passed."
    Write-Host "Godot: $godotWindowed"
    Write-Host "Args: $($launchArgs -join ' ')"
    exit 0
}

Start-Process -FilePath $godotWindowed -ArgumentList $launchArgs -WorkingDirectory $root
Write-Host "Started Act I human playtest in Godot."
