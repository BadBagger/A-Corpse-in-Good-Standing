$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\ink_shader_spike_manifest.json"
$metricsPath = Join-Path $root "docs\art\ink_shader_spike_metrics_status.json"
$metricsReportPath = Join-Path $root "docs\art\ink_shader_spike_metrics_status.md"
$pairwiseReportPath = Join-Path $root "docs\art\ink_shader_spike_pairwise_delta.json"
$driftReportPath = Join-Path $root "docs\art\ink_shader_spike_first_last_drift.json"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing ink shader spike manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$requiredFrameCount = [int]$manifest.render_contract.sequence_frames
$pairwiseThreshold = [double]$manifest.render_contract.pairwise_delta_threshold_percent
$driftThreshold = [double]$manifest.render_contract.first_to_last_drift_threshold_percent
$sampleStride = 4
if ($driftThreshold -le 0) {
    $driftThreshold = 9.0
}

function Resolve-RepoPath {
    param([Parameter(Mandatory=$true)][string]$RelativePath)

    return Join-Path $root ($RelativePath -replace "/", "\")
}

function Get-TestById {
    param([Parameter(Mandatory=$true)][string]$Id)

    $test = @($manifest.tests | Where-Object { $_.id -eq $Id })[0]
    if ($null -eq $test) {
        throw "Ink shader spike manifest missing test: $Id"
    }
    return $test
}

function Get-SequenceDirectory {
    param([Parameter(Mandatory=$true)]$Test)

    $outputPath = [string]$Test.output_path
    $absoluteOutput = Resolve-RepoPath $outputPath
    return Split-Path -Parent $absoluteOutput
}

function Get-SequenceFrames {
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [Parameter(Mandatory=$true)][int]$ExpectedCount,
        [Parameter(Mandatory=$true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Directory)) {
        return @()
    }

    $frames = @(Get-ChildItem -LiteralPath $Directory -Filter "frame_*.png" | Sort-Object Name)
    if ($frames.Count -gt 0 -and $frames.Count -lt $ExpectedCount) {
        throw "$Label sequence is incomplete: expected at least $ExpectedCount frame_*.png files, got $($frames.Count)."
    }
    return @($frames | Select-Object -First $ExpectedCount)
}

function Get-ForegroundBounds {
    param([Parameter(Mandatory=$true)][System.Drawing.Bitmap]$Bitmap)

    $minX = $Bitmap.Width
    $minY = $Bitmap.Height
    $maxX = -1
    $maxY = -1
    for ($y = 0; $y -lt $Bitmap.Height; $y += 2) {
        for ($x = 0; $x -lt $Bitmap.Width; $x += 2) {
            $pixel = $Bitmap.GetPixel($x, $y)
            $isBackground = ($pixel.R -eq 12 -and $pixel.G -eq 16 -and $pixel.B -eq 19)
            if (-not $isBackground) {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($maxX -lt 0) {
        return $null
    }
    return [ordered]@{
        MinX = $minX
        MinY = $minY
        MaxX = $maxX
        MaxY = $maxY
        Width = ($maxX - $minX + 1)
        Height = ($maxY - $minY + 1)
    }
}

function Test-HatchPixel {
    param([Parameter(Mandatory=$true)][System.Drawing.Color]$Pixel)

    return ($Pixel.R -gt 200 -and $Pixel.G -gt 190 -and $Pixel.B -gt 170)
}

function Test-ForegroundPixel {
    param([Parameter(Mandatory=$true)][System.Drawing.Color]$Pixel)

    return -not ($Pixel.R -eq 12 -and $Pixel.G -eq 16 -and $Pixel.B -eq 19)
}

function Measure-HatchingDeltaPercent {
    param(
        [Parameter(Mandatory=$true)][string]$FirstPath,
        [Parameter(Mandatory=$true)][string]$SecondPath
    )

    $first = $null
    $second = $null
    try {
        $first = [System.Drawing.Bitmap]::new($FirstPath)
        $second = [System.Drawing.Bitmap]::new($SecondPath)
        if ($first.Width -ne $second.Width -or $first.Height -ne $second.Height) {
            throw "Frame dimensions differ: $FirstPath is $($first.Width)x$($first.Height), $SecondPath is $($second.Width)x$($second.Height)."
        }

        $firstBounds = Get-ForegroundBounds -Bitmap $first
        $secondBounds = Get-ForegroundBounds -Bitmap $second
        if ($null -eq $firstBounds -or $null -eq $secondBounds) {
            throw "Unable to detect foreground bounds for hatching delta."
        }

        $width = [math]::Min([int]$firstBounds.Width, [int]$secondBounds.Width)
        $height = [math]::Min([int]$firstBounds.Height, [int]$secondBounds.Height)
        $sampledPixels = [int64]0
        $changedPixels = [int64]0

        for ($localY = 0; $localY -lt $height; $localY += $sampleStride) {
            for ($localX = 0; $localX -lt $width; $localX += $sampleStride) {
                $firstPixel = $first.GetPixel(([int]$firstBounds.MinX + $localX), ([int]$firstBounds.MinY + $localY))
                $secondPixel = $second.GetPixel(([int]$secondBounds.MinX + $localX), ([int]$secondBounds.MinY + $localY))
                if ((Test-ForegroundPixel -Pixel $firstPixel) -and (Test-ForegroundPixel -Pixel $secondPixel)) {
                    $sampledPixels += 1
                    if ((Test-HatchPixel -Pixel $firstPixel) -ne (Test-HatchPixel -Pixel $secondPixel)) {
                        $changedPixels += 1
                    }
                }
            }
        }

        if ($sampledPixels -eq 0) {
            throw "No overlapping foreground pixels found for hatching delta."
        }
        return [math]::Round(($changedPixels / $sampledPixels) * 100.0, 3)
    }
    finally {
        if ($null -ne $first) {
            $first.Dispose()
        }
        if ($null -ne $second) {
            $second.Dispose()
        }
    }
}

Add-Type -AssemblyName System.Drawing

$objectTest = Get-TestById -Id "r3_object_anchored_hatching_sequence"
$badControlTest = Get-TestById -Id "r4_screen_space_bad_control"
$objectDir = Get-SequenceDirectory -Test $objectTest
$badControlDir = Get-SequenceDirectory -Test $badControlTest
$objectFrames = Get-SequenceFrames -Directory $objectDir -ExpectedCount $requiredFrameCount -Label "Object-anchored hatching"
$badControlFrames = Get-SequenceFrames -Directory $badControlDir -ExpectedCount $requiredFrameCount -Label "Screen-space bad-control hatching"

$status = "pending"
$pairwiseMax = $null
$pairwiseAverage = $null
$firstLastDrift = $null
$badControlPairwiseMax = $null
$pairwiseValueArray = @()
$badPairwiseValueArray = @()
$notes = New-Object System.Collections.Generic.List[string]

if ($objectFrames.Count -eq 0) {
    $notes.Add("Object-anchored sequence is pending.")
}
if ($badControlFrames.Count -eq 0) {
    $notes.Add("Screen-space bad-control sequence is pending.")
}

if ($objectFrames.Count -ge $requiredFrameCount) {
    $pairwiseValues = New-Object System.Collections.Generic.List[double]
    for ($i = 0; $i -lt ($requiredFrameCount - 1); $i++) {
        $pairwiseValues.Add((Measure-HatchingDeltaPercent -FirstPath $objectFrames[$i].FullName -SecondPath $objectFrames[$i + 1].FullName))
    }

    $pairwiseValueArray = @($pairwiseValues)
    $pairwiseMax = [math]::Round((($pairwiseValues | Measure-Object -Maximum).Maximum), 3)
    $pairwiseAverage = [math]::Round((($pairwiseValues | Measure-Object -Average).Average), 3)
    $firstLastDrift = Measure-HatchingDeltaPercent -FirstPath $objectFrames[0].FullName -SecondPath $objectFrames[$requiredFrameCount - 1].FullName
}

if ($badControlFrames.Count -ge $requiredFrameCount) {
    $badValues = New-Object System.Collections.Generic.List[double]
    for ($i = 0; $i -lt ($requiredFrameCount - 1); $i++) {
        $badValues.Add((Measure-HatchingDeltaPercent -FirstPath $badControlFrames[$i].FullName -SecondPath $badControlFrames[$i + 1].FullName))
    }
    $badPairwiseValueArray = @($badValues)
    $badControlPairwiseMax = [math]::Round((($badValues | Measure-Object -Maximum).Maximum), 3)
}

if ($objectFrames.Count -ge $requiredFrameCount -and $badControlFrames.Count -ge $requiredFrameCount) {
    $status = "audited"
    if ($pairwiseMax -gt $pairwiseThreshold) {
        $status = "failed"
        $notes.Add("Pairwise delta exceeds provisional threshold.")
    }
    if ($firstLastDrift -gt $driftThreshold) {
        $status = "failed"
        $notes.Add("First-to-last drift exceeds provisional threshold.")
    }
    if ($badControlPairwiseMax -le $pairwiseMax) {
        $status = "failed"
        $notes.Add("Bad control does not measure worse than the object-anchored candidate.")
    }
    if ($notes.Count -eq 0) {
        $notes.Add("Object-anchored candidate passed provisional hatching stability metrics.")
    }
}

$metrics = [ordered]@{
    generated_from = "tools/Test-InkShaderSpikeMetrics.ps1"
    status = $status
    required_frame_count = $requiredFrameCount
    pairwise_threshold_percent = $pairwiseThreshold
    first_to_last_drift_threshold_percent = $driftThreshold
    measurement = "foreground-bounds-aligned hatch-pixel delta"
    sample_stride_pixels = $sampleStride
    object_sequence = [ordered]@{
        directory = ($objectDir.Substring($root.Length + 1) -replace "\\", "/")
        frames_found = $objectFrames.Count
        pairwise_max_percent = $pairwiseMax
        pairwise_average_percent = $pairwiseAverage
        first_to_last_drift_percent = $firstLastDrift
    }
    bad_control_sequence = [ordered]@{
        directory = ($badControlDir.Substring($root.Length + 1) -replace "\\", "/")
        frames_found = $badControlFrames.Count
        pairwise_max_percent = $badControlPairwiseMax
    }
    notes = @($notes)
}

$metrics | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metricsPath -Encoding UTF8

$pairwiseReport = [ordered]@{
    generated_from = "tools/Test-InkShaderSpikeMetrics.ps1"
    measurement = "foreground-bounds-aligned hatch-pixel delta"
    sample_stride_pixels = $sampleStride
    threshold_percent = $pairwiseThreshold
    object_sequence = [ordered]@{
        frames_found = $objectFrames.Count
        values_percent = @($pairwiseValueArray)
        max_percent = $pairwiseMax
        average_percent = $pairwiseAverage
    }
    bad_control_sequence = [ordered]@{
        frames_found = $badControlFrames.Count
        values_percent = @($badPairwiseValueArray)
        max_percent = $badControlPairwiseMax
    }
}
$pairwiseReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $pairwiseReportPath -Encoding UTF8

$driftReport = [ordered]@{
    generated_from = "tools/Test-InkShaderSpikeMetrics.ps1"
    measurement = "foreground-bounds-aligned hatch-pixel delta"
    sample_stride_pixels = $sampleStride
    threshold_percent = $driftThreshold
    frames_found = $objectFrames.Count
    first_frame = $(if ($objectFrames.Count -gt 0) { $objectFrames[0].Name } else { $null })
    last_frame = $(if ($objectFrames.Count -ge $requiredFrameCount) { $objectFrames[$requiredFrameCount - 1].Name } else { $null })
    first_to_last_drift_percent = $firstLastDrift
}
$driftReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $driftReportPath -Encoding UTF8

$metricLines = @(
    "# Ink Shader Spike Metrics Status",
    "",
    'Generated by `tools/Test-InkShaderSpikeMetrics.ps1`.',
    "",
    "This measures hatching stability only after the 24-frame yaw-turn renders exist. Missing renders remain pending; incomplete sequences fail.",
    "Measurement: foreground-bounds-aligned hatch-pixel delta.",
    "Sample stride: $sampleStride px.",
    "",
    "Status: $status.",
    "Required frames: $requiredFrameCount.",
    "Pairwise threshold: $pairwiseThreshold percent.",
    "First-to-last drift threshold: $driftThreshold percent.",
    "",
    "| Sequence | Frames | Pairwise Max | Pairwise Avg | First-Last Drift |",
    "|---|---:|---:|---:|---:|",
    "| object anchored | $($objectFrames.Count) | $pairwiseMax | $pairwiseAverage | $firstLastDrift |",
    "| bad control | $($badControlFrames.Count) | $badControlPairwiseMax |  |  |",
    "",
    "Notes:"
)

foreach ($note in $notes) {
    $metricLines += "- $note"
}

Set-Content -LiteralPath $metricsReportPath -Value $metricLines -Encoding UTF8

if ($status -eq "failed") {
    throw "Ink shader spike metrics failed: $(@($notes) -join ' ')"
}

Write-Host "Ink shader spike metrics status: $status, objectFrames=$($objectFrames.Count), badControlFrames=$($badControlFrames.Count), pairwiseMax=$pairwiseMax, firstLastDrift=$firstLastDrift"
