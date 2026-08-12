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

& (Join-Path $PSScriptRoot "Validate-ActIBackgroundReadySourcePackets.ps1")
& (Join-Path $PSScriptRoot "Validate-Step5ReviewDashboard.ps1")
& (Join-Path $PSScriptRoot "Validate-Step5HumanReviewBundle.ps1")
& (Join-Path $PSScriptRoot "Validate-ActIReviewHandoffSync.ps1")

$launchArgs = @("--path", $root)
if ($Editor) {
    $launchArgs += "--editor"
}

$reviewArtifacts = @(
    "docs/checkpoints/step_5_human_review_bundle.md",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/playtest/act_i_review_decisions_template.csv",
    "docs/art/act_i_review_contact_sheet.html",
    "docs/art/act_i_hotspot_overlay.svg",
    "docs/art/act_i_background_ready_source_packets.md"
)

if ($NoLaunch) {
    Write-Host "Act I human playtest launch preflight passed."
    Write-Host "Godot: $godotWindowed"
    Write-Host "Args: $($launchArgs -join ' ')"
    Write-Host "Review artifacts:"
    foreach ($relativePath in $reviewArtifacts) {
        Write-Host "- $relativePath"
    }
    exit 0
}

Start-Process -FilePath $godotWindowed -ArgumentList $launchArgs -WorkingDirectory $root
Write-Host "Started Act I human playtest in Godot."
Write-Host "Review artifacts:"
foreach ($relativePath in $reviewArtifacts) {
    Write-Host "- $relativePath"
}
