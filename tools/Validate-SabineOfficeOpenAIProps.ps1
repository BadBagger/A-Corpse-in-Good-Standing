$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\sabine_office_openai_props.json"
$mdPath = Join-Path $root "docs\art\sabine_office_openai_props.md"
$contactSheetPath = Join-Path $root "docs\art\review\sabine_office_openai_props_contact_sheet.png"
$compositePath = Join-Path $root "docs\art\review\sabine_office_openai_prop_composite.png"
$scenePath = Join-Path $root "game\rooms\sabine_office\room_sabine_office.tscn"
$loaderPath = Join-Path $root "game\rooms\prop_image_loader.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $compositePath, $scenePath, $loaderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Sabine Office OpenAI prop artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$props = @($report.props)
if ($props.Count -ne 4) {
    throw "Sabine Office OpenAI prop validation expected 4 props, got $($props.Count)."
}

$requiredIds = @("harbormaster_desk", "frosted_sabine_door", "damp_persian_rug", "harbor_chart_board")
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
        throw "Unexpected Sabine Office prop id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Sabine Office prop id: $id"
    }
    $seen[$id] = $true

    foreach ($field in @("name", "raw_export", "game_resource", "source_sheet")) {
        if ([string]::IsNullOrWhiteSpace([string]$prop.$field)) {
            throw "Sabine Office prop $id missing required field: $field"
        }
    }

    foreach ($relativePath in @([string]$prop.raw_export, [string]$prop.game_resource, [string]$prop.source_sheet)) {
        $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Sabine Office prop $id references missing file: $relativePath"
        }
    }

    $gamePath = Join-Path $root ([string]$prop.game_resource -replace "/", "\")
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($gamePath)
        if ($bitmap.Width -lt 80 -or $bitmap.Height -lt 120) {
            throw "Sabine Office prop $id has implausible runtime dimensions: $($bitmap.Width)x$($bitmap.Height)"
        }
        if ($bitmap.PixelFormat.ToString() -notmatch "Alpha|Argb|PArgb") {
            throw "Sabine Office prop $id must be an alpha PNG: $($bitmap.PixelFormat)"
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
            throw "Sabine Office prop $id appears blank after alpha extraction."
        }
        $opaqueCoverage = $opaqueSamples / [Math]::Max(1, $sampleCount)
        if ($opaqueCoverage -gt 0.88) {
            throw "Sabine Office prop $id still looks like a rectangular matte: sampled opaque coverage $([Math]::Round($opaqueCoverage, 3))."
        }
        if ($outOfPaletteSamples -gt 0) {
            throw "Sabine Office prop $id has sampled pixels outside the locked non-red palette."
        }
        if ($redSamples -gt 0) {
            throw "Sabine Office prop $id contains arterial-red-like sampled pixels; red is not allowed in this room prop pass."
        }
        if ($greenishSamples -gt 0) {
            throw "Sabine Office prop $id contains green-biased sampled pixels; Sabine Office foreground props must grade to slate/amber, not absinthe wrong-light."
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
        throw "Missing required Sabine Office prop id: $id"
    }
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredText in @(
    'res://game/rooms/prop_image_loader.gd',
    'HarbormasterDeskProp',
    'FrostedSabineDoorProp',
    'DampPersianRugProp',
    'HarborChartBoardProp',
    'res://game/rooms/sabine_office/props/harbormaster_desk.png',
    'res://game/rooms/sabine_office/props/frosted_sabine_door.png',
    'res://game/rooms/sabine_office/props/damp_persian_rug.png',
    'res://game/rooms/sabine_office/props/harbor_chart_board.png'
)) {
    if (-not $sceneText.Contains($requiredText)) {
        throw "Sabine Office scene missing runtime prop reference: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Sabine Office OpenAI Foreground Props",
    "hard-R, no explicit anatomy, no characters",
    "no absinthe green",
    "game/rooms/sabine_office/props/harbormaster_desk.png"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Sabine Office OpenAI prop report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Sabine Office OpenAI prop report must stay ASCII-only."
}

Write-Host "Sabine Office OpenAI prop validation passed: props=$($props.Count), runtimePlacement=present."
