param(
    [switch]$RefreshAutomatedReport,
    [switch]$SkipNotes,
    [switch]$Editor,
    [switch]$ResetNarrativeState,
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

function Clear-ActINarrativeState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $projectText = Get-Content -LiteralPath $ProjectPath -Raw
    $nameMatch = [regex]::Match($projectText, 'config/name="([^"]+)"')
    if (-not $nameMatch.Success) {
        throw "Cannot find application config/name in $ProjectPath."
    }

    $projectName = $nameMatch.Groups[1].Value
    $appData = [Environment]::GetFolderPath("ApplicationData")
    if ([string]::IsNullOrWhiteSpace($appData)) {
        throw "Cannot resolve Windows ApplicationData folder for Godot user:// cleanup."
    }

    $appUserDataRoot = [System.IO.Path]::GetFullPath((Join-Path $appData "Godot\app_userdata"))
    $projectUserDataPath = [System.IO.Path]::GetFullPath((Join-Path $appUserDataRoot $projectName))
    $expectedPrefix = $appUserDataRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $projectUserDataPath.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clear narrative state outside Godot app_userdata: $projectUserDataPath"
    }

    $narrativeSavePath = Join-Path $projectUserDataPath "narrative_state.json"
    if (Test-Path -LiteralPath $narrativeSavePath -PathType Container) {
        throw "Refusing to remove narrative state path because it is a directory: $narrativeSavePath"
    }

    if (Test-Path -LiteralPath $narrativeSavePath -PathType Leaf) {
        Remove-Item -LiteralPath $narrativeSavePath -Force
        Write-Host "Removed stale Act I narrative state: $narrativeSavePath"
    } else {
        Write-Host "Act I narrative state already clean: $narrativeSavePath"
    }

    return $narrativeSavePath
}

if ($RefreshAutomatedReport) {
    & (Join-Path $PSScriptRoot "Record-ActIGreyboxPlaytest.ps1")
}

if (-not $SkipNotes) {
    & (Join-Path $PSScriptRoot "New-ActIHumanPlaytestNotes.ps1")
}

& (Join-Path $PSScriptRoot "Validate-ActIBackgroundReadySourcePackets.ps1")
& (Join-Path $PSScriptRoot "Validate-ActIPlayerReviewCard.ps1")
& (Join-Path $PSScriptRoot "Validate-Step5ReviewDashboard.ps1")
& (Join-Path $PSScriptRoot "Validate-Step5HumanReviewBundle.ps1")
& (Join-Path $PSScriptRoot "Validate-ActIReviewHandoffSync.ps1")

if ($ResetNarrativeState) {
    $resetNarrativePath = Clear-ActINarrativeState -ProjectPath $projectPath
}

$launchArgs = @("--path", $root)
if ($Editor) {
    $launchArgs += "--editor"
}

$reviewArtifacts = @(
    "docs/checkpoints/step_5_human_review_bundle.md",
    "docs/playtest/act_i_player_review_card.md",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/playtest/act_i_review_decisions_template.csv",
    "docs/art/act_i_review_contact_sheet.html",
    "docs/art/act_i_hotspot_overlay.svg",
    "docs/art/act_i_background_ready_source_packets.md",
    "docs/art/act_i_look_target_reference.md"
)

if ($NoLaunch) {
    Write-Host "Act I human playtest launch preflight passed."
    Write-Host "Godot: $godotWindowed"
    Write-Host "Args: $($launchArgs -join ' ')"
    if ($ResetNarrativeState) {
        Write-Host "Reset narrative state: $resetNarrativePath"
    }
    Write-Host "Review artifacts:"
    foreach ($relativePath in $reviewArtifacts) {
        Write-Host "- $relativePath"
    }
    exit 0
}

Start-Process -FilePath $godotWindowed -ArgumentList $launchArgs -WorkingDirectory $root
Write-Host "Started Act I human playtest in Godot."
if ($ResetNarrativeState) {
    Write-Host "Reset narrative state: $resetNarrativePath"
}
Write-Host "Review artifacts:"
foreach ($relativePath in $reviewArtifacts) {
    Write-Host "- $relativePath"
}
