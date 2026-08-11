param(
    [switch]$RefreshAutomatedReport,
    [switch]$SkipNotes,
    [switch]$Editor,
    [switch]$NoLaunch
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")
$godotWindowed = Get-CorpseGodotPath -Kind Windowed
$godotConsole = Get-CorpseGodotPath -Kind Console

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
