$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_atmosphere_setpieces.json"
$mdPath = Join-Path $root "docs\art\act_i_atmosphere_setpieces.md"
$reviewPath = Join-Path $root "docs\art\review\act_i_atmosphere_setpieces_contact_sheet.png"
$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$playerScriptPath = Join-Path $root "game\rooms\sectional_setpiece_player.gd"

foreach ($path in @($jsonPath, $mdPath, $reviewPath, $roomScriptPath, $playerScriptPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I atmosphere setpiece input: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "exported") {
    throw "Act I atmosphere setpiece status must be exported."
}
$setpieces = @($report.setpieces)
if ($setpieces.Count -ne 5 -or [int]$report.count -ne 5) {
    throw "Act I atmosphere expected 5 setpieces, got report=$($report.count), rows=$($setpieces.Count)."
}

$requiredIds = @(
    "old_quay_water_glint",
    "salt_market_lamp_flicker",
    "harbor_registry_lamp_smoke",
    "grey_float_steam_drift",
    "sabine_office_window_rain"
)

Add-Type -AssemblyName System.Drawing
$seen = @{}
foreach ($item in $setpieces) {
    $id = [string]$item.id
    if ($id -notin $requiredIds) {
        throw "Unexpected Act I atmosphere id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Act I atmosphere id: $id"
    }
    $seen[$id] = $true
    foreach ($field in @("room_code", "room_folder", "background", "runtime_path", "export_path", "x", "y", "width", "height", "frames", "fps", "z", "kind")) {
        if ($null -eq $item.$field -or [string]::IsNullOrWhiteSpace([string]$item.$field)) {
            throw "Act I atmosphere $id missing field: $field"
        }
    }

    foreach ($relativePath in @([string]$item.background, [string]$item.runtime_path, [string]$item.export_path)) {
        $absolutePath = Join-Path $root ($relativePath -replace '/', '\')
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            throw "Act I atmosphere $id references missing file: $relativePath"
        }
    }

    $runtimePath = Join-Path $root ([string]$item.runtime_path -replace '/', '\')
    $bitmap = [System.Drawing.Bitmap]::new($runtimePath)
    try {
        $expectedWidth = [int]$item.width * [int]$item.frames
        if ($bitmap.Width -ne $expectedWidth -or $bitmap.Height -ne [int]$item.height) {
            throw "Act I atmosphere $id dimensions $($bitmap.Width)x$($bitmap.Height), expected ${expectedWidth}x$($item.height)."
        }
        if ($bitmap.PixelFormat.ToString() -notmatch "Alpha|Argb|PArgb") {
            throw "Act I atmosphere $id must be alpha PNG: $($bitmap.PixelFormat)."
        }
        $transparentCorners = 0
        foreach ($point in @(
            @{ X = 0; Y = 0 },
            @{ X = $bitmap.Width - 1; Y = 0 },
            @{ X = 0; Y = $bitmap.Height - 1 },
            @{ X = $bitmap.Width - 1; Y = $bitmap.Height - 1 }
        )) {
            $pixel = $bitmap.GetPixel([int]$point.X, [int]$point.Y)
            if ($pixel.A -eq 0) { $transparentCorners += 1 }
        }
        if ($transparentCorners -lt 4) {
            throw "Act I atmosphere $id has opaque sheet corners; this would look pasted."
        }

        $opaqueSamples = 0
        $tooRedSamples = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 16) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 16) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -gt 24) {
                    $opaqueSamples += 1
                    if ($pixel.R -gt ($pixel.G * 2.6) -and $pixel.R -gt ($pixel.B * 2.6) -and $pixel.R -gt 120) {
                        $tooRedSamples += 1
                    }
                }
            }
        }
        if ($opaqueSamples -lt 20) {
            throw "Act I atmosphere $id appears blank."
        }
        if ($tooRedSamples -gt 0) {
            throw "Act I atmosphere $id contains red-biased sampled pixels."
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

foreach ($id in $requiredIds) {
    if (-not $seen.ContainsKey($id)) {
        throw "Missing Act I atmosphere id: $id"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @(
    "ACT_I_ATMOSPHERE_BY_ROOM",
    "_add_act_i_atmosphere",
    "old_quay_water_glint",
    "salt_market_lamp_flicker",
    "harbor_registry_lamp_smoke",
    "grey_float_steam_drift",
    "sabine_office_window_rain"
)) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I room script missing atmosphere runtime text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Atmosphere Setpieces",
    "OpenAI room plates",
    "hard-R, no explicit anatomy, no gore, no child figures",
    "water glint, lamp flicker, smoke, steam, and window rain"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I atmosphere report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I atmosphere report must stay ASCII-only."
}

Write-Host "Act I atmosphere setpiece validation passed: setpieces=$($setpieces.Count)."
