$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$csvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$reportPath = Join-Path $root "docs\art\act_i_background_palette_audit.md"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing Act I background manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$rooms = @($manifest.rooms)
if ($rooms.Count -eq 0) {
    throw "Act I background manifest has no rooms."
}

$palette = @(
    @{ Name = "bone_paper_white"; Hex = "#E4DCC8"; R = 0xE4; G = 0xDC; B = 0xC8 },
    @{ Name = "wet_black"; Hex = "#0C1013"; R = 0x0C; G = 0x10; B = 0x13 },
    @{ Name = "harbor_slate"; Hex = "#2A3A40"; R = 0x2A; G = 0x3A; B = 0x40 },
    @{ Name = "absinthe_green"; Hex = "#7D9B4E"; R = 0x7D; G = 0x9B; B = 0x4E },
    @{ Name = "whale_oil_amber"; Hex = "#C98A3C"; R = 0xC9; G = 0x8A; B = 0x3C },
    @{ Name = "arterial_red"; Hex = "#8E1B22"; R = 0x8E; G = 0x1B; B = 0x22 }
)

$tolerance = 13
$minimumInGamut = 98.0
$maxRedScenes = 5

function Resolve-RepoPath {
    param([Parameter(Mandatory=$true)][string]$RelativePath)

    return Join-Path $root ($RelativePath -replace "/", "\")
}

function Test-ColorNear {
    param(
        [Parameter(Mandatory=$true)] [int]$R,
        [Parameter(Mandatory=$true)] [int]$G,
        [Parameter(Mandatory=$true)] [int]$B,
        [Parameter(Mandatory=$true)] $Target
    )

    return ([math]::Abs($R - $Target.R) -le $tolerance -and
        [math]::Abs($G - $Target.G) -le $tolerance -and
        [math]::Abs($B - $Target.B) -le $tolerance)
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Runtime
Add-Type -TypeDefinition @"
using System;

public static class CorpsePaletteAuditScanner
{
    public static long[] Scan(byte[] bytes, int width, int height, int stride, int[] ranges, int[] redRange)
    {
        long inGamutPixels = 0;
        long redPixels = 0;
        int rangeCount = ranges.Length / 6;

        for (int y = 0; y < height; y++)
        {
            int rowOffset = y * stride;
            for (int x = 0; x < width; x++)
            {
                int offset = rowOffset + (x * 4);
                int b = bytes[offset];
                int g = bytes[offset + 1];
                int r = bytes[offset + 2];
                int a = bytes[offset + 3];

                if (a == 0)
                {
                    inGamutPixels++;
                    continue;
                }

                bool matched = false;
                for (int i = 0; i < rangeCount; i++)
                {
                    int baseIndex = i * 6;
                    if (r >= ranges[baseIndex] && r <= ranges[baseIndex + 1] &&
                        g >= ranges[baseIndex + 2] && g <= ranges[baseIndex + 3] &&
                        b >= ranges[baseIndex + 4] && b <= ranges[baseIndex + 5])
                    {
                        matched = true;
                        break;
                    }
                }
                if (matched)
                {
                    inGamutPixels++;
                }

                if (r >= redRange[0] && r <= redRange[1] &&
                    g >= redRange[2] && g <= redRange[3] &&
                    b >= redRange[4] && b <= redRange[5])
                {
                    redPixels++;
                }
            }
        }

        return new long[] { inGamutPixels, redPixels };
    }
}
"@

$rows = New-Object System.Collections.Generic.List[object]
$redSceneCount = 0
$paletteRanges = @(
    $palette | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            RMin = [math]::Max(0, $_.R - $tolerance)
            RMax = [math]::Min(255, $_.R + $tolerance)
            GMin = [math]::Max(0, $_.G - $tolerance)
            GMax = [math]::Min(255, $_.G + $tolerance)
            BMin = [math]::Max(0, $_.B - $tolerance)
            BMax = [math]::Min(255, $_.B + $tolerance)
        }
    }
)
$redRange = @($paletteRanges | Where-Object { $_.Name -eq "arterial_red" })[0]
$flatRanges = [int[]]@(
    $paletteRanges | ForEach-Object {
        [int]$_.RMin
        [int]$_.RMax
        [int]$_.GMin
        [int]$_.GMax
        [int]$_.BMin
        [int]$_.BMax
    }
)
$flatRedRange = [int[]]@(
    [int]$redRange.RMin,
    [int]$redRange.RMax,
    [int]$redRange.GMin,
    [int]$redRange.GMax,
    [int]$redRange.BMin,
    [int]$redRange.BMax
)

foreach ($room in $rooms) {
    $relativePath = [string]$room.export_png
    $absolutePath = Resolve-RepoPath $relativePath
    $exists = Test-Path -LiteralPath $absolutePath

    if (-not $exists) {
        $rows.Add([pscustomobject]@{
            room_code = $room.room_code
            room_id = $room.room_id
            title = $room.title
            status = "pending"
            width = ""
            height = ""
            total_pixels = 0
            in_gamut_pixels = 0
            in_gamut_percent = ""
            arterial_red_pixels = 0
            arterial_red_scene = $false
            pass = ""
            export_png = $relativePath
        })
        continue
    }

    $sourceBitmap = $null
    $bitmap = $null
    $bitmapData = $null
    try {
        $sourceBitmap = [System.Drawing.Bitmap]::new($absolutePath)
        $rect = [System.Drawing.Rectangle]::new(0, 0, $sourceBitmap.Width, $sourceBitmap.Height)
        $bitmap = $sourceBitmap.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $totalPixels = [int64]$bitmap.Width * [int64]$bitmap.Height
        $inGamutPixels = [int64]0
        $redPixels = [int64]0

        $bitmapData = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $stride = [math]::Abs($bitmapData.Stride)
        $bytes = New-Object byte[] ($stride * $bitmap.Height)
        [System.Runtime.InteropServices.Marshal]::Copy($bitmapData.Scan0, $bytes, 0, $bytes.Length)

        $scan = [CorpsePaletteAuditScanner]::Scan($bytes, $bitmap.Width, $bitmap.Height, $stride, $flatRanges, $flatRedRange)
        $inGamutPixels = [int64]$scan[0]
        $redPixels = [int64]$scan[1]

        $inGamutPercent = if ($totalPixels -gt 0) { [math]::Round(($inGamutPixels / $totalPixels) * 100.0, 3) } else { 0.0 }
        $redScene = $redPixels -gt 0
        if ($redScene) {
            $redSceneCount += 1
        }

        $rows.Add([pscustomobject]@{
            room_code = $room.room_code
            room_id = $room.room_id
            title = $room.title
            status = "audited"
            width = $bitmap.Width
            height = $bitmap.Height
            total_pixels = $totalPixels
            in_gamut_pixels = $inGamutPixels
            in_gamut_percent = $inGamutPercent
            arterial_red_pixels = $redPixels
            arterial_red_scene = $redScene
            pass = ($inGamutPercent -ge $minimumInGamut)
            export_png = $relativePath
        })
    }
    finally {
        if ($null -ne $bitmapData -and $null -ne $bitmap) {
            $bitmap.UnlockBits($bitmapData)
        }
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
        if ($null -ne $sourceBitmap) {
            $sourceBitmap.Dispose()
        }
    }
}

$rows |
    Sort-Object room_code |
    ConvertTo-Csv -NoTypeInformation |
    Set-Content -LiteralPath $csvPath -Encoding UTF8

$auditedRows = @($rows | Where-Object { $_.status -eq "audited" })
$pendingRows = @($rows | Where-Object { $_.status -eq "pending" })
$failedRows = @($auditedRows | Where-Object { $_.pass -ne $true })
$redScenePass = $redSceneCount -le $maxRedScenes

$reportLines = @(
    "# Act I Background Palette Audit",
    "",
    'Generated by `tools/Export-ActIBackgroundPaletteAudit.ps1` from `docs/art/act_i_background_manifest.json`.',
    "",
    "This audit enforces G9/G10 for exported background PNGs when they exist. Pending exports are tracked, not treated as Step 4 failures.",
    "",
    "Palette tolerance: +/-$tolerance per RGB channel.",
    "G9 threshold: at least $minimumInGamut% in-gamut pixels per shipped background.",
    "G10 threshold: arterial red ``#8E1B22`` in at most $maxRedScenes distinct scenes.",
    "",
    "Summary: audited=$($auditedRows.Count), pending=$($pendingRows.Count), failed=$($failedRows.Count), arterialRedScenes=$redSceneCount, redSceneLimit=$maxRedScenes.",
    "",
    "| Room | Status | In Gamut | Red Pixels | Pass | Export |",
    "|---|---|---:|---:|---|---|"
)

foreach ($row in ($rows | Sort-Object room_code)) {
    $inGamut = if ($row.status -eq "audited") { "$($row.in_gamut_percent)%" } else { "-" }
    $redPixels = if ($row.status -eq "audited") { $row.arterial_red_pixels } else { "-" }
    $passText = if ($row.status -eq "audited") { [string]$row.pass } else { "pending" }
    $reportLines += "| $($row.room_code) $($row.title) | $($row.status) | $inGamut | $redPixels | $passText | ``$($row.export_png)`` |"
}

Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8

Write-Host "Exported Act I background palette audit CSV -> $csvPath"
Write-Host "Exported Act I background palette audit report -> $reportPath"
Write-Host "Act I background palette audit: audited=$($auditedRows.Count), pending=$($pendingRows.Count), failed=$($failedRows.Count), arterialRedScenes=$redSceneCount"

if ($failedRows.Count -gt 0) {
    throw "Act I background palette audit failed G9 for: $(@($failedRows | ForEach-Object { $_.room_id }) -join ', ')"
}
if (-not $redScenePass) {
    throw "Act I background palette audit failed G10: arterial red appears in $redSceneCount scenes; limit is $maxRedScenes."
}
