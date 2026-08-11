$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$summaryPath = Join-Path $root "docs\art\ink_shader_spike_still_image_audit.json"
$reportPath = Join-Path $root "docs\art\ink_shader_spike_still_image_audit.md"

$stillRows = @(
    @{ id = "raw"; label = "R1 raw side-profile"; path = "art/export/shader_spike/corvin_act_i_clean_side_raw.png"; requires_palette_gate = $false },
    @{ id = "ramp"; label = "R2 two-tone ink ramp"; path = "art/export/shader_spike/corvin_act_i_clean_side_ink_ramp.png"; requires_palette_gate = $false }
)

$palette = @(
    @{ Name = "bone_paper_white"; Hex = "#E4DCC8"; R = 0xE4; G = 0xDC; B = 0xC8 },
    @{ Name = "wet_black"; Hex = "#0C1013"; R = 0x0C; G = 0x10; B = 0x13 },
    @{ Name = "harbor_slate"; Hex = "#2A3A40"; R = 0x2A; G = 0x3A; B = 0x40 },
    @{ Name = "absinthe_green"; Hex = "#7D9B4E"; R = 0x7D; G = 0x9B; B = 0x4E },
    @{ Name = "whale_oil_amber"; Hex = "#C98A3C"; R = 0xC9; G = 0x8A; B = 0x3C },
    @{ Name = "arterial_red"; Hex = "#8E1B22"; R = 0x8E; G = 0x1B; B = 0x22 }
)

$tolerance = 13
$minimumNonTransparentPercent = 1.0
$minimumDistinctOpaqueColors = 8
$sampleStride = 4

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

$rows = New-Object System.Collections.Generic.List[object]
$failedRows = New-Object System.Collections.Generic.List[object]

foreach ($still in $stillRows) {
    $absolutePath = Resolve-RepoPath $still.path
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        $rows.Add([pscustomobject]@{
            id = $still.id
            label = $still.label
            status = "pending"
            width = 0
            height = 0
            opaque_pixels = 0
            opaque_percent = 0
            distinct_opaque_colors = 0
            in_palette_percent = 0
            pass = ""
            path = $still.path
        })
        continue
    }

    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($absolutePath)
        $totalPixels = [int64]$bitmap.Width * [int64]$bitmap.Height
        $sampledPixels = [int64]0
        $opaquePixels = [int64]0
        $inPalettePixels = [int64]0
        $distinct = New-Object 'System.Collections.Generic.HashSet[string]'

        for ($y = 0; $y -lt $bitmap.Height; $y += $sampleStride) {
            for ($x = 0; $x -lt $bitmap.Width; $x += $sampleStride) {
                $sampledPixels += 1
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -eq 0) {
                    continue
                }

                $opaquePixels += 1
                $distinct.Add("$($pixel.R),$($pixel.G),$($pixel.B),$($pixel.A)") | Out-Null

                foreach ($color in $palette) {
                    if (Test-ColorNear -R $pixel.R -G $pixel.G -B $pixel.B -Target $color) {
                        $inPalettePixels += 1
                        break
                    }
                }
            }
        }

        $opaquePercent = if ($sampledPixels -gt 0) { [math]::Round(($opaquePixels / $sampledPixels) * 100.0, 3) } else { 0.0 }
        $palettePercent = if ($opaquePixels -gt 0) { [math]::Round(($inPalettePixels / $opaquePixels) * 100.0, 3) } else { 0.0 }
        $pass = ($bitmap.Width -eq 1920 -and
            $bitmap.Height -eq 1080 -and
            $opaquePercent -ge $minimumNonTransparentPercent -and
            $distinct.Count -ge $minimumDistinctOpaqueColors)

        $row = [pscustomobject]@{
            id = $still.id
            label = $still.label
            status = "audited"
            width = $bitmap.Width
            height = $bitmap.Height
            sampled_pixels = $sampledPixels
            opaque_sample_pixels = $opaquePixels
            opaque_percent = $opaquePercent
            distinct_opaque_colors = $distinct.Count
            in_palette_percent = $palettePercent
            pass = $pass
            path = $still.path
        }
        $rows.Add($row)
        if (-not $pass) {
            $failedRows.Add($row)
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

$auditedRows = @($rows | Where-Object { $_.status -eq "audited" })
$pendingRows = @($rows | Where-Object { $_.status -eq "pending" })
$rowArray = $rows.ToArray()

$summary = [ordered]@{
    generated_from = "tools/Test-InkShaderSpikeStillImages.ps1"
    sample_stride = [int]$sampleStride
    tolerance = [int]$tolerance
    audited = [int]$auditedRows.Count
    pending = [int]$pendingRows.Count
    failed = [int]$failedRows.Count
    rows = $rowArray
}

$summary |
    ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportLines = @(
    "# Ink Shader Spike Still Image Audit",
    "",
    'Generated by `tools/Test-InkShaderSpikeStillImages.ps1`.',
    "",
    "This audit checks the R1/R2 still proof PNGs for dimensions and nonblank visual content. Palette proximity is reported for tuning, not treated as the final G9 gate.",
    "",
    "Thresholds: 1920x1080, at least $minimumNonTransparentPercent percent opaque sampled pixels, at least $minimumDistinctOpaqueColors distinct sampled opaque colors.",
    "Sampling: every $sampleStride pixels on x and y.",
    "Palette tolerance: +/-$tolerance per RGB channel against the locked project palette.",
    "",
    "Summary: audited=$($auditedRows.Count), pending=$($pendingRows.Count), failed=$($failedRows.Count).",
    "",
    "| Still | Status | Size | Opaque | Distinct Colors | Palette Proximity | Pass | Path |",
    "|---|---|---:|---:|---:|---:|---|---|"
)

foreach ($row in $rows) {
    $size = if ($row.status -eq "audited") { "$($row.width)x$($row.height)" } else { "-" }
    $opaque = if ($row.status -eq "audited") { "$($row.opaque_percent)%" } else { "-" }
    $distinctColors = if ($row.status -eq "audited") { $row.distinct_opaque_colors } else { "-" }
    $paletteNear = if ($row.status -eq "audited") { "$($row.in_palette_percent)%" } else { "-" }
    $passText = if ($row.status -eq "audited") { [string]$row.pass } else { "pending" }
    $reportLines += "| $($row.label) | $($row.status) | $size | $opaque | $distinctColors | $paletteNear | $passText | ``$($row.path)`` |"
}

Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8

if ($failedRows.Count -gt 0) {
    throw "Ink shader spike still image audit failed for: $(@($failedRows | ForEach-Object { $_.id }) -join ', ')"
}

Write-Host "Ink shader spike still image audit passed: audited=$($auditedRows.Count), pending=$($pendingRows.Count), failed=$($failedRows.Count)"
