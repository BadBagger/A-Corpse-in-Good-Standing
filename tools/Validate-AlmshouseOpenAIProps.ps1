$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\almshouse_openai_props.json"
$reportPath = Join-Path $root "docs\art\almshouse_openai_props.md"
$contactPath = Join-Path $root "docs\art\review\almshouse_openai_props_contact_sheet.png"
$compositePath = Join-Path $root "docs\art\review\almshouse_openai_prop_composite.png"
$scenePath = Join-Path $root "game\rooms\almshouse\room_almshouse.tscn"
$loaderPath = Join-Path $root "game\rooms\prop_image_loader.gd"

foreach ($path in @($manifestPath, $reportPath, $contactPath, $compositePath, $scenePath, $loaderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Almshouse OpenAI prop validation input: $path"
    }
}

$payload = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $reportPath -Raw
$scene = Get-Content -LiteralPath $scenePath -Raw
$loader = Get-Content -LiteralPath $loaderPath -Raw

$requiredIds = @(
    "cot_row",
    "salt_window",
    "prosper_chair_table",
    "forgiveness_watch_tray",
    "privacy_screen_laundry"
)

$props = @($payload.props)
if ($props.Count -ne $requiredIds.Count) {
    throw "Almshouse expected $($requiredIds.Count) props, got $($props.Count)."
}

Add-Type -AssemblyName System.Drawing
$allowed = @(
    "12,16,19",
    "42,58,64",
    "228,220,200",
    "201,138,60",
    "112,70,44"
)

foreach ($id in $requiredIds) {
    $row = @($props | Where-Object { $_.id -eq $id })[0]
    if ($null -eq $row) {
        throw "Almshouse manifest missing prop id: $id"
    }
    foreach ($propertyName in @("source_sheet", "raw_export", "game_resource")) {
        $relative = [string]$row.$propertyName
        if ($relative -match "\\") {
            throw "Almshouse $propertyName must be repo-relative with forward slashes: $relative"
        }
        $absolute = Join-Path $root ($relative -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolute)) {
            throw "Almshouse referenced asset missing: $relative"
        }
    }

    $gamePath = Join-Path $root ([string]$row.game_resource -replace "/", "\")
    $bitmap = [System.Drawing.Bitmap]::new($gamePath)
    try {
        if ($bitmap.Width -lt 40 -or $bitmap.Height -lt 40) {
            throw "Almshouse prop $id has implausible dimensions: $($bitmap.Width)x$($bitmap.Height)"
        }
        $opaqueSamples = 0
        $badPaletteSamples = 0
        $greenSamples = 0
        $redSamples = 0
        $stepX = [Math]::Max(1, [int]($bitmap.Width / 60))
        $stepY = [Math]::Max(1, [int]($bitmap.Height / 60))
        for ($y = 0; $y -lt $bitmap.Height; $y += $stepY) {
            for ($x = 0; $x -lt $bitmap.Width; $x += $stepX) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -lt 32) { continue }
                $opaqueSamples += 1
                $key = "$($pixel.R),$($pixel.G),$($pixel.B)"
                if ($key -notin $allowed) { $badPaletteSamples += 1 }
                if ($pixel.G -gt ($pixel.R * 1.15) -and $pixel.G -gt ($pixel.B * 1.05) -and $pixel.G -gt 55) { $greenSamples += 1 }
                if ($pixel.R -gt 120 -and $pixel.G -lt 80 -and $pixel.B -lt 80 -and $pixel.R -gt ($pixel.G * 1.7) -and $pixel.R -gt ($pixel.B * 1.7)) { $redSamples += 1 }
            }
        }
        if ($opaqueSamples -lt 20) {
            throw "Almshouse prop $id is visually blank or mostly transparent."
        }
        if ($badPaletteSamples -gt 0) {
            throw "Almshouse prop $id has sampled pixels outside the locked palette."
        }
        if ($greenSamples -gt 0) {
            throw "Almshouse prop $id contains green-biased sampled pixels."
        }
        if ($redSamples -gt 0) {
            throw "Almshouse prop $id contains red-biased sampled pixels."
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

foreach ($requiredNode in @(
    "CotRowProp",
    "SaltWindowProp",
    "ProsperChairTableProp",
    "ForgivenessWatchTrayProp",
    "PrivacyScreenLaundryProp"
)) {
    if ($scene -notmatch [regex]::Escape("node name=`"$requiredNode`" type=`"Sprite2D`" parent=`"Props`"")) {
        throw "Almshouse scene missing prop node: $requiredNode"
    }
}

foreach ($requiredPath in @(
    "res://game/rooms/almshouse/props/cot_row.png",
    "res://game/rooms/almshouse/props/salt_window.png",
    "res://game/rooms/almshouse/props/prosper_chair_table.png",
    "res://game/rooms/almshouse/props/forgiveness_watch_tray.png",
    "res://game/rooms/almshouse/props/privacy_screen_laundry.png"
)) {
    if ($scene -notmatch [regex]::Escape($requiredPath)) {
        throw "Almshouse scene missing runtime prop path: $requiredPath"
    }
}

foreach ($requiredText in @("extends Sprite2D", "prop_path", "ImageTexture.create_from_image")) {
    if ($loader -notmatch [regex]::Escape($requiredText)) {
        throw "Prop loader missing required text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Almshouse OpenAI Foreground Props",
    "hard-R, no explicit anatomy, no gore, no bodies, no child figures",
    "avoid absinthe green and arterial red"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Almshouse prop report missing required text: $requiredText"
    }
}

Write-Host "Almshouse OpenAI prop validation passed: props=$($props.Count), palette=locked, scene=registered."
