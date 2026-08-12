$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $root "docs\art\review\corvin_side_actions_contact_sheet.png"
$sheetRoot = Join-Path $root "game\characters\corvin\sprites\act_i_clean"

Add-Type -AssemblyName System.Drawing

$rows = @(
    @{ label = "talk side right"; path = Join-Path $sheetRoot "talk_side_right.png"; frames = 6 },
    @{ label = "talk side left"; path = Join-Path $sheetRoot "talk_side_left.png"; frames = 6 },
    @{ label = "use side right"; path = Join-Path $sheetRoot "use_side_right.png"; frames = 8 },
    @{ label = "use side left"; path = Join-Path $sheetRoot "use_side_left.png"; frames = 8 },
    @{ label = "wet side right"; path = Join-Path $sheetRoot "wet_side_right.png"; frames = 8 },
    @{ label = "wet side left"; path = Join-Path $sheetRoot "wet_side_left.png"; frames = 8 }
)

$cellWidth = 256
$cellHeight = 512
$labelWidth = 190
$padding = 24
$rowGap = 18
$scale = 0.35
$previewCellWidth = [int]($cellWidth * $scale)
$previewCellHeight = [int]($cellHeight * $scale)
$maxFrames = 8
$canvasWidth = $labelWidth + ($maxFrames * $previewCellWidth) + ($padding * 2)
$canvasHeight = 54 + ($rows.Count * $previewCellHeight) + (($rows.Count - 1) * $rowGap) + $padding

$bitmap = [System.Drawing.Bitmap]::new($canvasWidth, $canvasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$font = $null
$smallFont = $null
try {
    $graphics.Clear([System.Drawing.Color]::FromArgb(255, 12, 16, 19))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $font = [System.Drawing.Font]::new("Consolas", 13, [System.Drawing.FontStyle]::Bold)
    $smallFont = [System.Drawing.Font]::new("Consolas", 9, [System.Drawing.FontStyle]::Regular)
    $boneBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 228, 220, 200))
    $slatePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 42, 58, 64), 1)

    $graphics.DrawString("Corvin Act I clean side-action runtime sheets", $font, $boneBrush, $padding, 14)
    $graphics.DrawString("Generated from current Godot imports; facing/profile proof, not final animation polish.", $smallFont, $boneBrush, $padding, 34)

    $y = 64
    foreach ($row in $rows) {
        if (-not (Test-Path -LiteralPath $row.path)) {
            throw "Missing Corvin side-action sheet for contact sheet: $($row.path)"
        }

        $graphics.DrawString($row.label, $font, $boneBrush, $padding, $y + 8)
        $source = [System.Drawing.Bitmap]::new($row.path)
        try {
            if ($source.Width -ne ($row.frames * $cellWidth) -or $source.Height -ne $cellHeight) {
                throw "Unexpected sheet size for $($row.label): $($source.Width)x$($source.Height)"
            }
            for ($frame = 0; $frame -lt $row.frames; $frame++) {
                $sourceRect = [System.Drawing.Rectangle]::new($frame * $cellWidth, 0, $cellWidth, $cellHeight)
                $destRect = [System.Drawing.Rectangle]::new($labelWidth + ($frame * $previewCellWidth), $y, $previewCellWidth, $previewCellHeight)
                $graphics.DrawImage($source, $destRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
                $graphics.DrawRectangle($slatePen, $destRect)
            }
        }
        finally {
            $source.Dispose()
        }
        $y += $previewCellHeight + $rowGap
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $outPath) -Force | Out-Null
    $bitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    if ($null -ne $font) { $font.Dispose() }
    if ($null -ne $smallFont) { $smallFont.Dispose() }
    if ($null -ne $graphics) { $graphics.Dispose() }
    if ($null -ne $bitmap) { $bitmap.Dispose() }
}

Write-Host "Exported Corvin side-action contact sheet -> $outPath"
