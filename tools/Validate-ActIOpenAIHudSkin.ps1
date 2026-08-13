$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_openai_hud_skin.json"
$mdPath = Join-Path $root "docs\art\act_i_openai_hud_skin.md"
$contactPath = Join-Path $root "docs\art\review\act_i_openai_hud_skin_contact_sheet.png"
$hudScriptPath = Join-Path $root "game\ui\prologue_hud.gd"

foreach ($path in @($jsonPath, $mdPath, $contactPath, $hudScriptPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I OpenAI HUD skin artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "imported") {
    throw "Act I HUD skin status must be imported."
}
$assets = @($report.assets)
if ($assets.Count -ne 5 -or [int]$report.asset_count -ne 5) {
    throw "Act I HUD skin expected 5 assets, got report=$($report.asset_count), rows=$($assets.Count)."
}

$requiredIds = @(
    "status_strip",
    "dialogue_panel",
    "verb_button_plate",
    "bottom_inventory_panel",
    "small_icon_frame"
)

Add-Type -AssemblyName System.Drawing
$seen = @{}
foreach ($asset in $assets) {
    $id = [string]$asset.id
    if ($id -notin $requiredIds) {
        throw "Unexpected HUD skin asset id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate HUD skin asset id: $id"
    }
    $seen[$id] = $true
    foreach ($relativePath in @([string]$asset.export_path, [string]$asset.game_resource)) {
        $absolutePath = Join-Path $root ($relativePath -replace '/', '\')
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "HUD skin $id references missing file: $relativePath"
        }
    }
    $bitmap = [System.Drawing.Bitmap]::new((Join-Path $root ([string]$asset.game_resource -replace '/', '\')))
    try {
        if ($bitmap.Width -ne [int]$asset.width -or $bitmap.Height -ne [int]$asset.height) {
            throw "HUD skin $id dimension metadata drifted."
        }
        if ($bitmap.Width -lt 80 -or $bitmap.Height -lt 50) {
            throw "HUD skin $id is implausibly small: $($bitmap.Width)x$($bitmap.Height)."
        }
        $samples = 0
        $greenSamples = 0
        $redSamples = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 12) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 12) {
                $pixel = $bitmap.GetPixel($x, $y)
                $samples += 1
                if ($pixel.G -gt ($pixel.R * 1.2) -and $pixel.G -gt ($pixel.B * 1.1) -and $pixel.G -gt 90) {
                    $greenSamples += 1
                }
                if ($pixel.R -gt ($pixel.G * 3.2) -and $pixel.R -gt ($pixel.B * 3.2) -and $pixel.R -gt 140) {
                    $redSamples += 1
                }
            }
        }
        if ($samples -lt 20) {
            throw "HUD skin $id produced too few validation samples."
        }
        if ($greenSamples -gt 0) {
            throw "HUD skin $id contains green-biased sampled pixels."
        }
        if ($redSamples -gt 0) {
            throw "HUD skin $id contains arterial-red-like sampled pixels."
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

foreach ($id in $requiredIds) {
    if (-not $seen.ContainsKey($id)) {
        throw "Missing HUD skin asset id: $id"
    }
}

$hudScript = Get-Content -LiteralPath $hudScriptPath -Raw
foreach ($requiredText in @(
    "HUD_SKIN_BASE",
    "_apply_noir_skin",
    "status_strip.png",
    "Rect2i(0, 0, 430, 112)",
    "region_enabled",
    "region_rect",
    "Vector2(0.325, 0.50)",
    "dialogue_panel.png",
    "Vector2(1.15, 0.56)",
    "verb_button_plate.png",
    "bottom_inventory_panel.png",
    "small_icon_frame.png"
)) {
    if (-not $hudScript.Contains($requiredText)) {
        throw "Prologue HUD script missing skin runtime text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I OpenAI HUD Skin",
    "OpenAI-generated noir harbor UI texture sheet",
    "decorative HUD frames only",
    "hard-R, no explicit anatomy, no gore, no bodies, no child figures"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "HUD skin report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "HUD skin report must stay ASCII-only."
}

Write-Host "Act I OpenAI HUD skin validation passed: assets=$($assets.Count)."
