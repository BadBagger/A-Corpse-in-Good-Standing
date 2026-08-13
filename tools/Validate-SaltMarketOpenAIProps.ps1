$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\salt_market_openai_props.json"
$mdPath = Join-Path $root "docs\art\salt_market_openai_props.md"
$contactSheetPath = Join-Path $root "docs\art\review\salt_market_openai_props_contact_sheet.png"
$compositePath = Join-Path $root "docs\art\review\salt_market_openai_prop_composite.png"
$scenePath = Join-Path $root "game\rooms\salt_market\room_salt_market.tscn"
$loaderPath = Join-Path $root "game\rooms\prop_image_loader.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $compositePath, $scenePath, $loaderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Salt Market OpenAI prop artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$props = @($report.props)
if ($props.Count -ne 5) {
    throw "Salt Market OpenAI prop validation expected 5 props, got $($props.Count)."
}

$requiredIds = @("boot_stall", "church_sign", "confession_queue", "fishmonger", "market_crowd_dressing")
$allowedColors = @{
    "12,16,19" = $true
    "42,58,64" = $true
    "228,220,200" = $true
    "201,138,60" = $true
    "112,70,44" = $true
}

$seen = @{}
Add-Type -AssemblyName System.Drawing
foreach ($prop in $props) {
    $id = [string]$prop.id
    if ($id -notin $requiredIds) {
        throw "Unexpected Salt Market prop id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Salt Market prop id: $id"
    }
    $seen[$id] = $true

    foreach ($field in @("name", "raw_export", "game_resource", "source_sheet")) {
        if ([string]::IsNullOrWhiteSpace([string]$prop.$field)) {
            throw "Salt Market prop $id missing required field: $field"
        }
    }

    foreach ($relativePath in @([string]$prop.raw_export, [string]$prop.game_resource, [string]$prop.source_sheet)) {
        $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Salt Market prop $id references missing file: $relativePath"
        }
    }

    $gamePath = Join-Path $root ([string]$prop.game_resource -replace "/", "\")
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($gamePath)
        if ($bitmap.Width -lt 80 -or $bitmap.Height -lt 120) {
            throw "Salt Market prop $id has implausible runtime dimensions: $($bitmap.Width)x$($bitmap.Height)"
        }
        if ($bitmap.PixelFormat.ToString() -notmatch "Alpha|Argb|PArgb") {
            throw "Salt Market prop $id must be an alpha PNG: $($bitmap.PixelFormat)"
        }

        $opaqueSamples = 0
        $outOfPaletteSamples = 0
        $redSamples = 0
        $greenishSamples = 0
        $sampleCount = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 8) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 8) {
                $sampleCount += 1
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -gt 32) {
                    $opaqueSamples += 1
                    $key = "$($pixel.R),$($pixel.G),$($pixel.B)"
                    if (-not $allowedColors.ContainsKey($key)) {
                        $outOfPaletteSamples += 1
                    }
                    if ($pixel.R -gt 120 -and $pixel.G -lt 60 -and $pixel.B -lt 70) {
                        $redSamples += 1
                    }
                    if ($pixel.G -gt ($pixel.R * 1.10) -and $pixel.G -gt ($pixel.B * 1.03) -and $pixel.G -gt 60) {
                        $greenishSamples += 1
                    }
                }
            }
        }
        if ($opaqueSamples -lt 20) {
            throw "Salt Market prop $id appears blank after alpha extraction."
        }
        $opaqueCoverage = $opaqueSamples / [Math]::Max(1, $sampleCount)
        if ($opaqueCoverage -gt 0.78) {
            throw "Salt Market prop $id still looks like a rectangular matte: sampled opaque coverage $([Math]::Round($opaqueCoverage, 3))."
        }
        if ($outOfPaletteSamples -gt 0) {
            throw "Salt Market prop $id has sampled pixels outside the locked non-red palette."
        }
        if ($redSamples -gt 0) {
            throw "Salt Market prop $id contains arterial-red-like sampled pixels; red is not allowed in this room prop pass."
        }
        if ($greenishSamples -gt 0) {
            throw "Salt Market prop $id contains green-biased sampled pixels; Salt Market people and stalls must grade to slate/amber, not absinthe wrong-light."
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
        throw "Missing required Salt Market prop id: $id"
    }
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredText in @(
    'res://game/rooms/prop_image_loader.gd',
    'BootStallProp',
    'MarketCrowdDressingProp',
    'ChurchSignProp',
    'ConfessionQueueProp',
    'FishmongerProp',
    'res://game/rooms/salt_market/props/boot_stall.png',
    'res://game/rooms/salt_market/props/market_crowd_dressing.png',
    'res://game/rooms/salt_market/props/church_sign.png',
    'res://game/rooms/salt_market/props/confession_queue.png',
    'res://game/rooms/salt_market/props/fishmonger.png'
)) {
    if (-not $sceneText.Contains($requiredText)) {
        throw "Salt Market scene missing runtime prop reference: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Salt Market OpenAI Foreground Props",
    "hard-R, no explicit anatomy, adult figures only, no child figures",
    "game/rooms/salt_market/props/boot_stall.png"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Salt Market OpenAI prop report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Salt Market OpenAI prop report must stay ASCII-only."
}

Write-Host "Salt Market OpenAI prop validation passed: props=$($props.Count), runtimePlacement=present."
