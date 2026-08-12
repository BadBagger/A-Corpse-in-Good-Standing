$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$queuePath = Join-Path $root "docs\art\corvin_side_action_render_queue.json"
$jsonPath = Join-Path $root "docs\art\corvin_side_action_rendered_sheets_audit.json"
$mdPath = Join-Path $root "docs\art\corvin_side_action_rendered_sheets_audit.md"

if (-not (Test-Path -LiteralPath $queuePath)) {
    throw "Missing Corvin side action rendered-sheet input: $queuePath"
}

Add-Type -AssemblyName System.Drawing

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    return ($Path.Substring($root.Length + 1) -replace "\\", "/")
}

function Get-FileSha256 {
    param([Parameter(Mandatory=$true)][string]$Path)

    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-ImageAudit {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][int]$ExpectedWidth,
        [Parameter(Mandatory=$true)][int]$ExpectedHeight,
        [Parameter(Mandatory=$true)][int]$ExpectedFrames,
        [Parameter(Mandatory=$true)][int]$CellWidth,
        [Parameter(Mandatory=$true)][int]$CellHeight
    )

    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($Path)
        $frameRows = New-Object System.Collections.Generic.List[object]
        $firstFrameSamples = @{}
        for ($frame = 0; $frame -lt $ExpectedFrames; $frame++) {
            $alphaSamples = 0
            $redSamples = 0
            $motionDifferenceSamples = 0
            $motionUnionSamples = 0
            $minX = $CellWidth
            $minY = $CellHeight
            $maxX = -1
            $maxY = -1
            for ($y = 0; $y -lt $CellHeight; $y += 4) {
                for ($x = 0; $x -lt $CellWidth; $x += 4) {
                    $pixel = $bitmap.GetPixel(($frame * $CellWidth) + $x, $y)
                    $sampleKey = "$x,$y"
                    if ($frame -eq 0) {
                        $firstFrameSamples[$sampleKey] = $pixel
                    }
                    else {
                        $firstPixel = $firstFrameSamples[$sampleKey]
                        if ($firstPixel.A -gt 8 -or $pixel.A -gt 8) {
                            $motionUnionSamples++
                        }
                        if (
                            [math]::Abs([int]$firstPixel.A - [int]$pixel.A) -gt 20 -or
                            [math]::Abs([int]$firstPixel.R - [int]$pixel.R) -gt 18 -or
                            [math]::Abs([int]$firstPixel.G - [int]$pixel.G) -gt 18 -or
                            [math]::Abs([int]$firstPixel.B - [int]$pixel.B) -gt 18
                        ) {
                            $motionDifferenceSamples++
                        }
                    }
                    if ($pixel.A -gt 8) {
                        $alphaSamples++
                        if ($x -lt $minX) { $minX = $x }
                        if ($x -gt $maxX) { $maxX = $x }
                        if ($y -lt $minY) { $minY = $y }
                        if ($y -gt $maxY) { $maxY = $y }
                    }
                    if ($pixel.A -gt 8 -and [math]::Abs([int]$pixel.R - 142) -le 5 -and [math]::Abs([int]$pixel.G - 27) -le 5 -and [math]::Abs([int]$pixel.B - 34) -le 5) {
                        $redSamples++
                    }
                }
            }
            $silhouetteWidth = if ($maxX -ge 0) { ($maxX - $minX + 1) } else { 0 }
            $silhouetteHeight = if ($maxY -ge 0) { ($maxY - $minY + 1) } else { 0 }
            $profileRatio = if ($silhouetteHeight -gt 0) { [math]::Round(($silhouetteWidth / $silhouetteHeight), 3) } else { 0.0 }
            $motionDifferencePercent = if ($motionUnionSamples -gt 0) { [math]::Round((100.0 * $motionDifferenceSamples / $motionUnionSamples), 1) } else { 0.0 }
            $frameRows.Add([pscustomobject][ordered]@{
                frame = $frame + 1
                alpha_samples = $alphaSamples
                arterial_red_samples = $redSamples
                nonblank = ($alphaSamples -gt 100)
                silhouette_width = $silhouetteWidth
                silhouette_height = $silhouetteHeight
                profile_ratio = $profileRatio
                motion_difference_percent = $motionDifferencePercent
            })
        }
        $profileRatios = @($frameRows | Where-Object { $_.nonblank } | ForEach-Object { [double]$_.profile_ratio })
        $maxProfileRatio = if ($profileRatios.Count -gt 0) { [math]::Round((@($profileRatios | Measure-Object -Maximum)[0].Maximum), 3) } else { 0.0 }
        $averageProfileRatio = if ($profileRatios.Count -gt 0) { [math]::Round((@($profileRatios | Measure-Object -Average)[0].Average), 3) } else { 0.0 }
        $motionDifferencePercents = @($frameRows | ForEach-Object { [double]$_.motion_difference_percent })
        $maxMotionDifferencePercent = if ($motionDifferencePercents.Count -gt 0) { [math]::Round((@($motionDifferencePercents | Measure-Object -Maximum)[0].Maximum), 1) } else { 0.0 }

        return [ordered]@{
            width = [int]$bitmap.Width
            height = [int]$bitmap.Height
            dimension_pass = ([int]$bitmap.Width -eq $ExpectedWidth -and [int]$bitmap.Height -eq $ExpectedHeight)
            nonblank_frame_count = @($frameRows | Where-Object { $_.nonblank }).Count
            arterial_red_sample_count = (@($frameRows | Measure-Object -Property arterial_red_samples -Sum).Sum)
            average_profile_ratio = $averageProfileRatio
            max_profile_ratio = $maxProfileRatio
            max_motion_difference_percent = $maxMotionDifferencePercent
            frames = @($frameRows.ToArray())
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

$queue = Get-Content -LiteralPath $queuePath -Raw | ConvertFrom-Json
$rows = @($queue.rows)
if ($rows.Count -ne 6) {
    throw "Corvin side action rendered-sheet audit expected 6 queue rows, got $($rows.Count)."
}

$auditRows = New-Object System.Collections.Generic.List[object]
foreach ($row in $rows) {
    $sheetPath = Join-Path $root ([string]$row.sheet_export -replace "/", "\")
    $godotPath = Join-Path $root ([string]$row.godot_import -replace "/", "\")
    if (-not (Test-Path -LiteralPath $sheetPath)) {
        throw "Missing rendered Corvin side action sheet: $($row.sheet_export)"
    }
    if (-not (Test-Path -LiteralPath $godotPath)) {
        throw "Missing imported Corvin side action Godot sprite: $($row.godot_import)"
    }

    $sheetHash = Get-FileSha256 -Path $sheetPath
    $godotHash = Get-FileSha256 -Path $godotPath
    $imageAudit = Get-ImageAudit `
        -Path $sheetPath `
        -ExpectedWidth ([int]$row.expected_sheet_width) `
        -ExpectedHeight ([int]$row.expected_sheet_height) `
        -ExpectedFrames ([int]$row.frames) `
        -CellWidth ([int]$row.cell_width) `
        -CellHeight ([int]$row.cell_height)

    $byteMatch = $sheetHash -eq $godotHash
    $nonblankPass = [int]$imageAudit.nonblank_frame_count -eq [int]$row.frames
    $redPass = if ([string]$row.animation -eq "wet") { [int]$imageAudit.arterial_red_sample_count -eq 0 } else { $true }
    $profilePass = [double]$imageAudit.max_profile_ratio -le 0.42
    $requiredMotionPercent = if ([string]$row.animation -eq "talk") { 12.0 } else { 20.0 }
    $motionPass = [double]$imageAudit.max_motion_difference_percent -ge $requiredMotionPercent
    $status = if ($byteMatch -and [bool]$imageAudit.dimension_pass -and $nonblankPass -and $redPass -and $profilePass -and $motionPass) { "pass" } else { "fail" }

    $auditRows.Add([pscustomobject][ordered]@{
        animation = [string]$row.animation
        direction = [string]$row.direction
        status = $status
        sheet_export = [string]$row.sheet_export
        godot_import = [string]$row.godot_import
        sheet_sha256 = $sheetHash
        godot_sha256 = $godotHash
        byte_for_byte_import = $byteMatch
        expected_width = [int]$row.expected_sheet_width
        expected_height = [int]$row.expected_sheet_height
        width = [int]$imageAudit.width
        height = [int]$imageAudit.height
        frames = [int]$row.frames
        nonblank_frame_count = [int]$imageAudit.nonblank_frame_count
        arterial_red_sample_count = [int]$imageAudit.arterial_red_sample_count
        average_profile_ratio = [double]$imageAudit.average_profile_ratio
        max_profile_ratio = [double]$imageAudit.max_profile_ratio
        profile_silhouette_pass = $profilePass
        required_motion_difference_percent = $requiredMotionPercent
        max_motion_difference_percent = [double]$imageAudit.max_motion_difference_percent
        motion_readability_pass = $motionPass
    })
}

$failedRows = @($auditRows | Where-Object { $_.status -ne "pass" })
$payload = [ordered]@{
    generated_from = "tools/Validate-CorvinSideActionRenderedSheets.ps1"
    source_queue = "docs/art/corvin_side_action_render_queue.json"
    status = if ($failedRows.Count -eq 0) { "rendered_sheets_audited" } else { "failed" }
    row_count = $auditRows.Count
    passed_count = $auditRows.Count - $failedRows.Count
    failed_count = $failedRows.Count
    rule_locks = @(
        "This audit proves dimensions, nonblank frames, and byte-for-byte Godot import parity only.",
        "Side sheets must read as profile silhouettes: max sampled frame width/height <= 0.42.",
        "Action sheets must show readable motion against frame 1: talk >= 12%, use/wet >= 20% sampled pixel delta.",
        "This audit does not approve final animation polish.",
        "Wet sheets must contain zero arterial red samples."
    )
    rows = @($auditRows.ToArray())
}

$payload | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Corvin Side Action Rendered Sheets Audit",
    "",
    'Generated by `tools/Validate-CorvinSideActionRenderedSheets.ps1`.',
    "",
    "Status: $($payload.status)",
    "Rows: $($auditRows.Count)",
    "Passed: $($payload.passed_count)",
    "Failed: $($payload.failed_count)",
    "",
    "Rule locks:",
    "- This audit proves dimensions, nonblank frames, and byte-for-byte Godot import parity only.",
    "- Side sheets must read as profile silhouettes: max sampled frame width/height <= 0.42.",
    "- Action sheets must show readable motion against frame 1: talk >= 12%, use/wet >= 20% sampled pixel delta.",
    "- This audit does not approve final animation polish.",
    "- Wet sheets must contain zero arterial red samples.",
    "",
    "| Animation | Direction | Status | Size | Frames nonblank | Profile max | Motion max | Motion pass | Byte match | Arterial red samples | Sheet | Godot import |",
    "|---|---|---|---|---:|---:|---:|---|---|---:|---|---|"
)
foreach ($row in @($auditRows.ToArray())) {
    $lines += "| $($row.animation) | $($row.direction) | $($row.status) | $($row.width)x$($row.height) | $($row.nonblank_frame_count)/$($row.frames) | $($row.max_profile_ratio) | $($row.max_motion_difference_percent)% | $($row.motion_readability_pass) | $($row.byte_for_byte_import) | $($row.arterial_red_sample_count) | ``$($row.sheet_export)`` | ``$($row.godot_import)`` |"
}
Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

if ($failedRows.Count -gt 0) {
    throw "Corvin side action rendered-sheet audit failed for: $(@($failedRows | ForEach-Object { "$($_.animation) $($_.direction)" }) -join ', ')"
}

Write-Host "Corvin side action rendered-sheet audit passed: rows=$($auditRows.Count), status=$($payload.status)."
