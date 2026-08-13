$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\mudflats_openai_props.json"
$mdPath = Join-Path $root "docs\art\mudflats_openai_props.md"
$contactSheetPath = Join-Path $root "docs\art\review\mudflats_openai_props_contact_sheet.png"
$compositePath = Join-Path $root "docs\art\review\mudflats_openai_prop_composite.png"
$scenePath = Join-Path $root "game\rooms\mudflats\room_mudflats.tscn"
$loaderPath = Join-Path $root "game\rooms\prop_image_loader.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $compositePath, $scenePath, $loaderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing mudflats OpenAI prop artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$props = @($report.props)
if ($props.Count -ne 3) {
    throw "Mudflats OpenAI prop validation expected 3 props, got $($props.Count)."
}

$requiredIds = @("tomas_bollard", "missing_boots", "brine_silt")
$allowedColors = @{
    "12,16,19" = $true
    "42,58,64" = $true
    "228,220,200" = $true
    "125,155,78" = $true
    "201,138,60" = $true
    "142,27,34" = $true
}

$seen = @{}
Add-Type -AssemblyName System.Drawing
foreach ($prop in $props) {
    $id = [string]$prop.id
    if ($id -notin $requiredIds) {
        throw "Unexpected mudflats prop id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate mudflats prop id: $id"
    }
    $seen[$id] = $true

    foreach ($field in @("name", "raw_export", "game_resource", "source_sheet")) {
        if ([string]::IsNullOrWhiteSpace([string]$prop.$field)) {
            throw "Mudflats prop $id missing required field: $field"
        }
    }

    foreach ($relativePath in @([string]$prop.raw_export, [string]$prop.game_resource, [string]$prop.source_sheet)) {
        $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Mudflats prop $id references missing file: $relativePath"
        }
    }

    $gamePath = Join-Path $root ([string]$prop.game_resource -replace "/", "\")
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($gamePath)
        if ($bitmap.Width -lt 40 -or $bitmap.Height -lt 60) {
            throw "Mudflats prop $id has implausible runtime dimensions: $($bitmap.Width)x$($bitmap.Height)"
        }
        if ($bitmap.PixelFormat.ToString() -notmatch "Alpha|Argb|PArgb") {
            throw "Mudflats prop $id must be an alpha PNG: $($bitmap.PixelFormat)"
        }

        $opaqueSamples = 0
        $outOfPaletteSamples = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 8) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 8) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -gt 32) {
                    $opaqueSamples += 1
                    $key = "$($pixel.R),$($pixel.G),$($pixel.B)"
                    if (-not $allowedColors.ContainsKey($key)) {
                        $outOfPaletteSamples += 1
                    }
                }
            }
        }
        if ($opaqueSamples -lt 8) {
            throw "Mudflats prop $id appears blank after alpha extraction."
        }
        if ($outOfPaletteSamples -gt 0) {
            throw "Mudflats prop $id has sampled pixels outside the locked palette."
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
        throw "Missing required mudflats prop id: $id"
    }
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredText in @(
    'res://game/rooms/prop_image_loader.gd',
    'BrineSiltProp',
    'TomasBollardProp',
    'MissingBootsProp',
    'res://game/rooms/mudflats/props/brine_silt.png',
    'res://game/rooms/mudflats/props/tomas_bollard.png',
    'res://game/rooms/mudflats/props/missing_boots.png'
)) {
    if (-not $sceneText.Contains($requiredText)) {
        throw "Mudflats scene missing runtime prop reference: $requiredText"
    }
}

$loaderText = Get-Content -LiteralPath $loaderPath -Raw
foreach ($requiredText in @("extends Sprite2D", "prop_path", "ImageTexture.create_from_image")) {
    if (-not $loaderText.Contains($requiredText)) {
        throw "Mudflats prop loader missing required runtime text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Mudflats OpenAI Foreground Props",
    "hard-R, no explicit anatomy, no child figures",
    "game/rooms/mudflats/props/tomas_bollard.png"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Mudflats OpenAI prop report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Mudflats OpenAI prop report must stay ASCII-only."
}

Write-Host "Mudflats OpenAI prop validation passed: props=$($props.Count), runtimePlacement=present."
