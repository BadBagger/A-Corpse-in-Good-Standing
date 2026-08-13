$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_openai_standees.json"
$mdPath = Join-Path $root "docs\art\act_i_openai_standees.md"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_openai_standees_contact_sheet.png"
$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $roomScriptPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I OpenAI standee artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$standees = @($report.standees)
if ($standees.Count -ne 8) {
    throw "Act I OpenAI standee validation expected 8 standees, got $($standees.Count)."
}

$requiredIds = @(
    "registrar",
    "juno",
    "prosper",
    "tomas_bollard",
    "sabine",
    "teodor",
    "bone_chandler",
    "market_crowd"
)

$seen = @{}
Add-Type -AssemblyName System.Drawing
foreach ($standee in $standees) {
    $id = [string]$standee.id
    if ($id -notin $requiredIds) {
        throw "Unexpected Act I standee id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Act I standee id: $id"
    }
    $seen[$id] = $true

    foreach ($field in @("name", "raw_export", "game_resource", "source_sheet")) {
        if ([string]::IsNullOrWhiteSpace([string]$standee.$field)) {
            throw "Act I standee $id missing required field: $field"
        }
    }

    foreach ($relativePath in @([string]$standee.raw_export, [string]$standee.game_resource, [string]$standee.source_sheet)) {
        $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Act I standee $id references missing file: $relativePath"
        }
    }

    $gamePath = Join-Path $root ([string]$standee.game_resource -replace "/", "\")
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($gamePath)
        if ($bitmap.Width -lt 100 -or $bitmap.Height -lt 300) {
            throw "Act I standee $id has implausible runtime dimensions: $($bitmap.Width)x$($bitmap.Height)"
        }
        if ($bitmap.PixelFormat.ToString() -notmatch "Alpha|Argb|PArgb") {
            throw "Act I standee $id must be an alpha PNG: $($bitmap.PixelFormat)"
        }

        $transparentCorners = 0
        if ($bitmap.GetPixel(0, 0).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel($bitmap.Width - 1, 0).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel(0, $bitmap.Height - 1).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel($bitmap.Width - 1, $bitmap.Height - 1).A -eq 0) { $transparentCorners += 1 }
        if ($transparentCorners -lt 4) {
            throw "Act I standee $id must have transparent corners after chroma-key removal."
        }

        $opaqueSamples = 0
        $greenLeakSamples = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 12) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 12) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -gt 32) {
                    $opaqueSamples += 1
                    if ($pixel.G -gt 180 -and $pixel.R -lt 80 -and $pixel.B -lt 80) {
                        $greenLeakSamples += 1
                    }
                }
            }
        }
        if ($opaqueSamples -lt 20) {
            throw "Act I standee $id appears blank after chroma-key removal."
        }
        if ($greenLeakSamples -gt 0) {
            throw "Act I standee $id has bright chroma-green leakage in opaque pixels."
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

foreach ($id in $requiredIds) {
    if (-not $seen.ContainsKey($id)) {
        throw "Missing required Act I standee id: $id"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @(
    "ACT_I_STANDEES_BY_ROOM",
    "show_debug_layout",
    "_set_debug_layout_visible",
    "_add_act_i_standees",
    "res://game/standees/act_i/%s.png",
    "tomas_bollard",
    "market_crowd",
    "registrar",
    "bone_chandler",
    "prosper",
    "teodor",
    "juno",
    "sabine"
)) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I room script missing standee/runtime presentation text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I OpenAI Standees",
    "hard-R, no explicit anatomy, no child figures",
    "game/standees/act_i/sabine.png"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I standee report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I standee report must stay ASCII-only."
}

Write-Host "Act I OpenAI standee validation passed: standees=$($standees.Count), runtimePlacement=present."
