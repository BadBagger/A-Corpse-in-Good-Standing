$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_openai_portraits.json"
$mdPath = Join-Path $root "docs\art\act_i_openai_portraits.md"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_openai_portraits_contact_sheet.png"
$corvinScenePath = Join-Path $root "game\characters\corvin\character_corvin.tscn"
$corvinScriptPath = Join-Path $root "game\characters\corvin\character_corvin.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $corvinScenePath, $corvinScriptPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I OpenAI portrait artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$portraits = @($report.portraits)
if ($portraits.Count -ne 6) {
    throw "Act I OpenAI portrait validation expected 6 portraits, got $($portraits.Count)."
}

$requiredIds = @("corvin", "sabine", "registrar", "juno", "tomas", "prosper")
$seen = @{}
Add-Type -AssemblyName System.Drawing
foreach ($portrait in $portraits) {
    $id = [string]$portrait.character_id
    if ($id -notin $requiredIds) {
        throw "Unexpected Act I portrait id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Act I portrait id: $id"
    }
    $seen[$id] = $true

    foreach ($field in @("display_name", "role", "emotion", "raw_export", "game_resource", "content_note")) {
        if ([string]::IsNullOrWhiteSpace([string]$portrait.$field)) {
            throw "Act I portrait $id missing required field: $field"
        }
    }

    foreach ($relativePath in @([string]$portrait.raw_export, [string]$portrait.game_resource)) {
        $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Act I portrait $id references missing image: $relativePath"
        }
        $bitmap = $null
        try {
            $bitmap = [System.Drawing.Bitmap]::new($absolutePath)
            if ($bitmap.Width -ne 720 -or $bitmap.Height -ne 720) {
                throw "Act I portrait $id must be 720x720, got $($bitmap.Width)x$($bitmap.Height): $relativePath"
            }
        }
        finally {
            if ($null -ne $bitmap) {
                $bitmap.Dispose()
            }
        }
    }
}

foreach ($id in $requiredIds) {
    if (-not $seen.ContainsKey($id)) {
        throw "Missing required Act I portrait id: $id"
    }
}

$corvinScene = Get-Content -LiteralPath $corvinScenePath -Raw
if ($corvinScene.Contains("res://game/portraits/act_i/corvin_neutral.png")) {
    throw "Corvin scene must not reference raw portrait PNGs directly; .png.import files are not tracked."
}

$corvinScript = Get-Content -LiteralPath $corvinScriptPath -Raw
foreach ($requiredText in @(
    "res://game/portraits/act_i/corvin_neutral.png",
    "Image.load_from_file",
    "ImageTexture.create_from_image",
    "avatars.append"
)) {
    if (-not $corvinScript.Contains($requiredText)) {
        throw "Corvin script is missing portrait wiring text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I OpenAI Portraits",
    "hard-R, no explicit anatomy, no child figures",
    "game/portraits/act_i/corvin_neutral.png"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I portrait report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I portrait report must stay ASCII-only."
}

Write-Host "Act I OpenAI portrait validation passed: portraits=$($portraits.Count), corvinAvatar=present."
