$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mapPath = Join-Path $root "docs\art\act_i_hotspot_map.csv"
$outDir = Join-Path $root "docs\art"
$outPath = Join-Path $outDir "act_i_hotspot_overlay.svg"

if (-not (Test-Path -LiteralPath $mapPath)) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIHotspotMap.ps1")
}

$rows = @(Import-Csv -LiteralPath $mapPath)
if ($rows.Count -eq 0) {
    throw "Cannot export hotspot overlay from empty map: $mapPath"
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Escape-Svg {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

$roomOrder = @(
    "mudflats",
    "old_quay",
    "salt_market",
    "harbor_registry",
    "bone_chandler",
    "almshouse",
    "fish_hall",
    "church_of_the_drowned",
    "grey_float",
    "harbormaster_office",
    "sabine_office"
)

$panelWidth = 640
$panelHeight = 360
$margin = 28
$gap = 22
$columns = 3
$rowsNeeded = [math]::Ceiling($roomOrder.Count / $columns)
$svgWidth = ($columns * $panelWidth) + (($columns - 1) * $gap) + (2 * $margin)
$svgHeight = ($rowsNeeded * $panelHeight) + (($rowsNeeded - 1) * $gap) + (2 * $margin) + 78
$scaleX = $panelWidth / 1920
$scaleY = $panelHeight / 1080

$svg = New-Object System.Collections.Generic.List[string]
$svg.Add('<?xml version="1.0" encoding="UTF-8"?>')
$svg.Add("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$svgWidth`" height=`"$svgHeight`" viewBox=`"0 0 $svgWidth $svgHeight`">")
$svg.Add('<rect width="100%" height="100%" fill="#0C1013"/>')
$svg.Add('<text x="28" y="36" fill="#E4DCC8" font-family="Consolas, monospace" font-size="24">A Corpse in Good Standing - Act I Hotspot Overlay</text>')
$svg.Add('<text x="28" y="62" fill="#E4DCC8" font-family="Consolas, monospace" font-size="14">Generated from docs/art/act_i_hotspot_map.csv. Coordinates scaled from 1920x1080 greybox room space.</text>')
$svg.Add('<g font-family="Consolas, monospace" font-size="13">')
$legend = @(
    @{ Label="exit"; Color="#4AA3FF" },
    @{ Label="hotspot"; Color="#C98A3C" },
    @{ Label="duel"; Color="#8E1B22" },
    @{ Label="wet"; Color="#7D9B4E" },
    @{ Label="alternate"; Color="#B48CFF" }
)
$legendX = 1410
foreach ($item in $legend) {
    $svg.Add("<circle cx=`"$legendX`" cy=`"34`" r=`"7`" fill=`"$($item.Color)`"/>")
    $svg.Add("<text x=`"$($legendX + 12)`" y=`"39`" fill=`"#E4DCC8`">$($item.Label)</text>")
    $legendX += 106
}
$svg.Add('</g>')

for ($roomIndex = 0; $roomIndex -lt $roomOrder.Count; $roomIndex++) {
    $roomId = $roomOrder[$roomIndex]
    $roomRows = @($rows | Where-Object { $_.room_id -eq $roomId })
    if ($roomRows.Count -eq 0) {
        continue
    }

    $column = $roomIndex % $columns
    $row = [math]::Floor($roomIndex / $columns)
    $panelX = $margin + ($column * ($panelWidth + $gap))
    $panelY = $margin + 78 + ($row * ($panelHeight + $gap))
    $roomTitle = $roomRows[0].room_title
    if ([string]::IsNullOrWhiteSpace($roomTitle)) {
        $roomTitle = $roomId
    }

    $svg.Add("<g id=`"room-$roomId`">")
    $svg.Add("<rect x=`"$panelX`" y=`"$panelY`" width=`"$panelWidth`" height=`"$panelHeight`" rx=`"6`" fill=`"#11181B`" stroke=`"#2A3A40`" stroke-width=`"2`"/>")
    $svg.Add("<rect x=`"$panelX`" y=`"$($panelY + 246)`" width=`"$panelWidth`" height=`"72`" fill=`"#162227`" opacity=`"0.8`"/>")
    $svg.Add("<line x1=`"$panelX`" y1=`"$($panelY + 246)`" x2=`"$($panelX + $panelWidth)`" y2=`"$($panelY + 246)`" stroke=`"#2A3A40`" stroke-width=`"1`" stroke-dasharray=`"8 8`"/>")
    $svg.Add("<text x=`"$($panelX + 14)`" y=`"$($panelY + 24)`" fill=`"#E4DCC8`" font-family=`"Consolas, monospace`" font-size=`"16`">$(Escape-Svg "$($roomRows[0].room_code) / $roomTitle")</text>")
    $svg.Add("<text x=`"$($panelX + 14)`" y=`"$($panelY + 344)`" fill=`"#7D9B4E`" font-family=`"Consolas, monospace`" font-size=`"11`">walk band / player-scale reference</text>")

    foreach ($hotspot in $roomRows) {
        $x = $panelX + ([double]$hotspot.x * $scaleX)
        $y = $panelY + ([double]$hotspot.y * $scaleY)
        $color = "#C98A3C"
        $radius = 7
        if ($hotspot.type -eq "exit") {
            $color = "#4AA3FF"
            $radius = 8
        }
        if ($hotspot.type -eq "duel") {
            $color = "#8E1B22"
            $radius = 9
        }
        $hasWet = -not [string]::IsNullOrWhiteSpace($hotspot.wet_ink_knot)
        $hasAlternate = -not [string]::IsNullOrWhiteSpace($hotspot.alternate_ink_knot)
        $label = Escape-Svg $hotspot.label
        $name = Escape-Svg $hotspot.name
        $metadataParts = @(
            "$($hotspot.type) $($hotspot.name) @ $($hotspot.x),$($hotspot.y)"
        )
        if (-not [string]::IsNullOrWhiteSpace($hotspot.ink_knot)) {
            $metadataParts += "ink=$($hotspot.ink_knot)"
        }
        if (-not [string]::IsNullOrWhiteSpace($hotspot.wet_ink_knot)) {
            $metadataParts += "wet=$($hotspot.wet_ink_knot)"
        }
        if (-not [string]::IsNullOrWhiteSpace($hotspot.blocked_ink_knot)) {
            $metadataParts += "blocked=$($hotspot.blocked_ink_knot)"
        }
        if (-not [string]::IsNullOrWhiteSpace($hotspot.alternate_ink_knot)) {
            $metadataParts += "alternate=$($hotspot.alternate_ink_knot)"
        }
        $metadata = Escape-Svg ($metadataParts -join "; ")

        if ($hasWet) {
            $svg.Add("<circle cx=`"$x`" cy=`"$y`" r=`"$($radius + 5)`" fill=`"none`" stroke=`"#7D9B4E`" stroke-width=`"2`"/>")
        }
        if ($hasAlternate) {
            $svg.Add("<rect x=`"$($x - $radius - 6)`" y=`"$($y - $radius - 6)`" width=`"$($radius * 2 + 12)`" height=`"$($radius * 2 + 12)`" fill=`"none`" stroke=`"#B48CFF`" stroke-width=`"2`"/>")
        }

        $svg.Add("<circle cx=`"$x`" cy=`"$y`" r=`"$radius`" fill=`"$color`"><title>$metadata</title></circle>")
        $textY = $y - 12
        if ($hotspot.type -eq "exit") {
            $textY = $y + 20
        }
        $svg.Add("<text x=`"$($x + 10)`" y=`"$textY`" fill=`"#E4DCC8`" font-family=`"Consolas, monospace`" font-size=`"10`">$label</text>")
        if ($label -ne $name -and -not [string]::IsNullOrWhiteSpace($name)) {
            $svg.Add("<text x=`"$($x + 10)`" y=`"$($textY + 12)`" fill=`"#6F858D`" font-family=`"Consolas, monospace`" font-size=`"9`">$name</text>")
        }
    }
    $svg.Add("</g>")
}

$svg.Add("</svg>")
$svg | Set-Content -LiteralPath $outPath -Encoding UTF8
Write-Host "Exported Act I hotspot overlay -> $outPath"
