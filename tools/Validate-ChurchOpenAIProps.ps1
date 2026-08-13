$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\church_of_the_drowned_openai_props.json"
$mdPath = Join-Path $root "docs\art\church_of_the_drowned_openai_props.md"
$contactSheetPath = Join-Path $root "docs\art\review\church_of_the_drowned_openai_props_contact_sheet.png"
$compositePath = Join-Path $root "docs\art\review\church_of_the_drowned_openai_prop_composite.png"
$scenePath = Join-Path $root "game\rooms\church_of_the_drowned\room_church_of_the_drowned.tscn"
$loaderPath = Join-Path $root "game\rooms\prop_image_loader.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $compositePath, $scenePath, $loaderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Church OpenAI prop artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$props = @($report.props)
if ($props.Count -ne 4) {
    throw "Church OpenAI prop validation expected 4 props, got $($props.Count)."
}

$requiredIds = @(
    "confession_booth",
    "church_ledger_desk",
    "church_tariff_sign",
    "poor_box"
)
$allowedColors = @{
    "12,16,19" = $true
    "42,58,64" = $true
    "228,220,200" = $true
    "125,155,78" = $true
    "201,138,60" = $true
    "112,70,44" = $true
    "142,27,34" = $true
}

$seen = @{}
Add-Type -AssemblyName System.Drawing
foreach ($prop in $props) {
    $id = [string]$prop.id
    if ($id -notin $requiredIds) {
        throw "Unexpected Church prop id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Church prop id: $id"
    }
    $seen[$id] = $true

    foreach ($field in @("name", "raw_export", "game_resource", "source_sheet", "hotspot")) {
        if ([string]::IsNullOrWhiteSpace([string]$prop.$field)) {
            throw "Church prop $id missing required field: $field"
        }
    }

    foreach ($relativePath in @([string]$prop.raw_export, [string]$prop.game_resource, [string]$prop.source_sheet)) {
        $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Church prop $id references missing file: $relativePath"
        }
    }

    $gamePath = Join-Path $root ([string]$prop.game_resource -replace "/", "\")
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($gamePath)
        if ($bitmap.Width -lt 40 -or $bitmap.Height -lt 60) {
            throw "Church prop $id has implausible runtime dimensions: $($bitmap.Width)x$($bitmap.Height)"
        }
        if ($bitmap.PixelFormat.ToString() -notmatch "Alpha|Argb|PArgb") {
            throw "Church prop $id must be an alpha PNG: $($bitmap.PixelFormat)"
        }

        $transparentCorners = 0
        if ($bitmap.GetPixel(0, 0).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel($bitmap.Width - 1, 0).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel(0, $bitmap.Height - 1).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel($bitmap.Width - 1, $bitmap.Height - 1).A -eq 0) { $transparentCorners += 1 }
        if ($transparentCorners -lt 4) {
            throw "Church prop $id must have transparent corners."
        }

        $opaqueSamples = 0
        $outOfPaletteSamples = 0
        $greenSamples = 0
        $redSamples = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 8) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 8) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -gt 32) {
                    $opaqueSamples += 1
                    $key = "$($pixel.R),$($pixel.G),$($pixel.B)"
                    if (-not $allowedColors.ContainsKey($key)) {
                        $outOfPaletteSamples += 1
                    }
                    if ($pixel.R -eq 125 -and $pixel.G -eq 155 -and $pixel.B -eq 78) {
                        $greenSamples += 1
                    }
                    if ($pixel.R -eq 142 -and $pixel.G -eq 27 -and $pixel.B -eq 34) {
                        $redSamples += 1
                    }
                }
            }
        }
        if ($opaqueSamples -lt 8) {
            throw "Church prop $id appears blank after alpha extraction."
        }
        if ($outOfPaletteSamples -gt 0) {
            throw "Church prop $id has sampled pixels outside the locked palette."
        }
        $greenPercent = ($greenSamples / $opaqueSamples) * 100.0
        if ($greenPercent -gt 22.0) {
            throw "Church prop $id overuses absinthe green: $([Math]::Round($greenPercent, 2))% sampled opaque pixels."
        }
        if ($redSamples -gt 0) {
            throw "Church prop $id uses arterial red; Church props must not spend the red budget."
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
        throw "Missing required Church prop id: $id"
    }
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredText in @(
    'res://game/rooms/prop_image_loader.gd',
    'PoorBoxProp',
    'ConfessionBoothProp',
    'ChurchLedgerDeskProp',
    'ChurchTariffSignProp',
    'res://game/rooms/church_of_the_drowned/props/poor_box.png',
    'res://game/rooms/church_of_the_drowned/props/confession_booth.png',
    'res://game/rooms/church_of_the_drowned/props/church_ledger_desk.png',
    'res://game/rooms/church_of_the_drowned/props/church_tariff_sign.png'
)) {
    if (-not $sceneText.Contains($requiredText)) {
        throw "Church scene missing runtime prop reference: $requiredText"
    }
}

$loaderText = Get-Content -LiteralPath $loaderPath -Raw
foreach ($requiredText in @("extends Sprite2D", "prop_path", "ImageTexture.create_from_image")) {
    if (-not $loaderText.Contains($requiredText)) {
        throw "Church prop loader missing required runtime text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Church of the Drowned OpenAI Foreground Props",
    "hard-R, no explicit anatomy, no child figures",
    "game/rooms/church_of_the_drowned/props/confession_booth.png"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Church OpenAI prop report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Church OpenAI prop report must stay ASCII-only."
}

Write-Host "Church OpenAI prop validation passed: props=$($props.Count), runtimePlacement=present."
