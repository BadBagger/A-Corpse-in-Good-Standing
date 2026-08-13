$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\bone_chandler_openai_props.json"
$mdPath = Join-Path $root "docs\art\bone_chandler_openai_props.md"
$contactSheetPath = Join-Path $root "docs\art\review\bone_chandler_openai_props_contact_sheet.png"
$compositePath = Join-Path $root "docs\art\review\bone_chandler_openai_prop_composite.png"
$scenePath = Join-Path $root "game\rooms\bone_chandler\room_bone_chandler.tscn"
$loaderPath = Join-Path $root "game\rooms\prop_image_loader.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $compositePath, $scenePath, $loaderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Bone Chandler OpenAI prop artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$props = @($report.props)
if ($props.Count -ne 4) {
    throw "Bone Chandler OpenAI prop validation expected 4 props, got $($props.Count)."
}

$requiredIds = @(
    "prosper_watch_display",
    "bone_trade_counter",
    "salt_trade_tray",
    "bone_shelf_cluster"
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
        throw "Unexpected Bone Chandler prop id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Bone Chandler prop id: $id"
    }
    $seen[$id] = $true

    foreach ($field in @("name", "raw_export", "game_resource", "source_sheet", "hotspot")) {
        if ([string]::IsNullOrWhiteSpace([string]$prop.$field)) {
            throw "Bone Chandler prop $id missing required field: $field"
        }
    }

    foreach ($relativePath in @([string]$prop.raw_export, [string]$prop.game_resource, [string]$prop.source_sheet)) {
        $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Bone Chandler prop $id references missing file: $relativePath"
        }
    }

    $gamePath = Join-Path $root ([string]$prop.game_resource -replace "/", "\")
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($gamePath)
        if ($bitmap.Width -lt 40 -or $bitmap.Height -lt 60) {
            throw "Bone Chandler prop $id has implausible runtime dimensions: $($bitmap.Width)x$($bitmap.Height)"
        }
        if ($bitmap.PixelFormat.ToString() -notmatch "Alpha|Argb|PArgb") {
            throw "Bone Chandler prop $id must be an alpha PNG: $($bitmap.PixelFormat)"
        }

        $transparentCorners = 0
        if ($bitmap.GetPixel(0, 0).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel($bitmap.Width - 1, 0).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel(0, $bitmap.Height - 1).A -eq 0) { $transparentCorners += 1 }
        if ($bitmap.GetPixel($bitmap.Width - 1, $bitmap.Height - 1).A -eq 0) { $transparentCorners += 1 }
        if ($transparentCorners -lt 4) {
            throw "Bone Chandler prop $id must have transparent corners."
        }

        $opaqueSamples = 0
        $outOfPaletteSamples = 0
        $greenDominanceSamples = 0
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
                    if ($pixel.G -gt ($pixel.R * 1.05) -and $pixel.G -gt ($pixel.B * 1.03) -and $pixel.G -gt 54) {
                        $greenDominanceSamples += 1
                    }
                    if ($pixel.R -eq 142 -and $pixel.G -eq 27 -and $pixel.B -eq 34) {
                        $redSamples += 1
                    }
                }
            }
        }
        if ($opaqueSamples -lt 8) {
            throw "Bone Chandler prop $id appears blank after alpha extraction."
        }
        if ($outOfPaletteSamples -gt 0) {
            throw "Bone Chandler prop $id has sampled pixels outside the locked palette."
        }
        $greenDominancePercent = ($greenDominanceSamples / $opaqueSamples) * 100.0
        if ($greenDominancePercent -gt 0.5) {
            throw "Bone Chandler prop $id reads too green: $([Math]::Round($greenDominancePercent, 2))% sampled opaque pixels."
        }
        if ($redSamples -gt 0) {
            throw "Bone Chandler prop $id uses arterial red; bone-shop desk clutter must not spend the red budget."
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
        throw "Missing required Bone Chandler prop id: $id"
    }
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredText in @(
    'res://game/rooms/prop_image_loader.gd',
    'BoneTradeCounterProp',
    'ProsperWatchDisplayProp',
    'BoneShelfClusterProp',
    'SaltTradeTrayProp',
    'res://game/rooms/bone_chandler/props/bone_trade_counter.png',
    'res://game/rooms/bone_chandler/props/prosper_watch_display.png',
    'res://game/rooms/bone_chandler/props/bone_shelf_cluster.png',
    'res://game/rooms/bone_chandler/props/salt_trade_tray.png'
)) {
    if (-not $sceneText.Contains($requiredText)) {
        throw "Bone Chandler scene missing runtime prop reference: $requiredText"
    }
}

$loaderText = Get-Content -LiteralPath $loaderPath -Raw
foreach ($requiredText in @("extends Sprite2D", "prop_path", "ImageTexture.create_from_image")) {
    if (-not $loaderText.Contains($requiredText)) {
        throw "Bone Chandler prop loader missing required runtime text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Bone Chandler OpenAI Foreground Props",
    "hard-R, no explicit anatomy, no child figures",
    "game/rooms/bone_chandler/props/prosper_watch_display.png"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Bone Chandler OpenAI prop report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Bone Chandler OpenAI prop report must stay ASCII-only."
}

Write-Host "Bone Chandler OpenAI prop validation passed: props=$($props.Count), runtimePlacement=present."
