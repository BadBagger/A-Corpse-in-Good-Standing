$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\harbormaster_office_openai_props.json"
$reportPath = Join-Path $root "docs\art\harbormaster_office_openai_props.md"
$contactPath = Join-Path $root "docs\art\review\harbormaster_office_openai_props_contact_sheet.png"
$compositePath = Join-Path $root "docs\art\review\harbormaster_office_openai_prop_composite.png"
$scenePath = Join-Path $root "game\rooms\harbormaster_office\room_harbormaster_office.tscn"
$loaderPath = Join-Path $root "game\rooms\prop_image_loader.gd"

foreach ($path in @($manifestPath, $reportPath, $contactPath, $compositePath, $scenePath, $loaderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Harbormaster Office OpenAI prop validation input: $path"
    }
}

$payload = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $reportPath -Raw
$scene = Get-Content -LiteralPath $scenePath -Raw
$loader = Get-Content -LiteralPath $loaderPath -Raw

$requiredIds = @(
    "checklist_desk",
    "sabine_door_panel",
    "clerk_counter",
    "permit_board",
    "queue_rail_sign"
)

$props = @($payload.props)
if ($props.Count -ne $requiredIds.Count) {
    throw "Harbormaster Office expected $($requiredIds.Count) props, got $($props.Count)."
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
        throw "Harbormaster Office manifest missing prop id: $id"
    }
    foreach ($propertyName in @("source_sheet", "raw_export", "game_resource")) {
        $relative = [string]$row.$propertyName
        if ($relative -match "\\") {
            throw "Harbormaster Office $propertyName must be repo-relative with forward slashes: $relative"
        }
        $absolute = Join-Path $root ($relative -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolute)) {
            throw "Harbormaster Office referenced asset missing: $relative"
        }
    }

    $gamePath = Join-Path $root ([string]$row.game_resource -replace "/", "\")
    $bitmap = [System.Drawing.Bitmap]::new($gamePath)
    try {
        if ($bitmap.Width -lt 40 -or $bitmap.Height -lt 40) {
            throw "Harbormaster Office prop $id has implausible dimensions: $($bitmap.Width)x$($bitmap.Height)"
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
            throw "Harbormaster Office prop $id is visually blank or mostly transparent."
        }
        if ($badPaletteSamples -gt 0) {
            throw "Harbormaster Office prop $id has sampled pixels outside the locked palette."
        }
        if ($greenSamples -gt 0) {
            throw "Harbormaster Office prop $id contains green-biased sampled pixels."
        }
        if ($redSamples -gt 0) {
            throw "Harbormaster Office prop $id contains red-biased sampled pixels."
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

foreach ($requiredNode in @(
    "ChecklistDeskProp",
    "SabineDoorPanelProp",
    "ClerkCounterProp",
    "PermitBoardProp",
    "QueueRailSignProp"
)) {
    if ($scene -notmatch [regex]::Escape("node name=`"$requiredNode`" type=`"Sprite2D`" parent=`"Props`"")) {
        throw "Harbormaster Office scene missing prop node: $requiredNode"
    }
}

foreach ($requiredPath in @(
    "res://game/rooms/harbormaster_office/props/checklist_desk.png",
    "res://game/rooms/harbormaster_office/props/sabine_door_panel.png",
    "res://game/rooms/harbormaster_office/props/clerk_counter.png",
    "res://game/rooms/harbormaster_office/props/permit_board.png",
    "res://game/rooms/harbormaster_office/props/queue_rail_sign.png"
)) {
    if ($scene -notmatch [regex]::Escape($requiredPath)) {
        throw "Harbormaster Office scene missing runtime prop path: $requiredPath"
    }
}

foreach ($requiredText in @("extends Sprite2D", "prop_path", "ImageTexture.create_from_image")) {
    if ($loader -notmatch [regex]::Escape($requiredText)) {
        throw "Prop loader missing required text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Harbormaster Office OpenAI Foreground Props",
    "hard-R, no explicit anatomy, no gore, no bodies, no child figures",
    "avoid absinthe green and arterial red",
    "abstract official iconography only"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Harbormaster Office prop report missing required text: $requiredText"
    }
}

Write-Host "Harbormaster Office OpenAI prop validation passed: props=$($props.Count), palette=locked, scene=registered."
