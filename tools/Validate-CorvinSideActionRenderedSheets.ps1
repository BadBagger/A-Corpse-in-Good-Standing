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
        for ($frame = 0; $frame -lt $ExpectedFrames; $frame++) {
            $alphaSamples = 0
            $redSamples = 0
            for ($y = 0; $y -lt $CellHeight; $y += 4) {
                for ($x = 0; $x -lt $CellWidth; $x += 4) {
                    $pixel = $bitmap.GetPixel(($frame * $CellWidth) + $x, $y)
                    if ($pixel.A -gt 8) {
                        $alphaSamples++
                    }
                    if ($pixel.A -gt 8 -and [math]::Abs([int]$pixel.R - 142) -le 5 -and [math]::Abs([int]$pixel.G - 27) -le 5 -and [math]::Abs([int]$pixel.B - 34) -le 5) {
                        $redSamples++
                    }
                }
            }
            $frameRows.Add([pscustomobject][ordered]@{
                frame = $frame + 1
                alpha_samples = $alphaSamples
                arterial_red_samples = $redSamples
                nonblank = ($alphaSamples -gt 100)
            })
        }

        return [ordered]@{
            width = [int]$bitmap.Width
            height = [int]$bitmap.Height
            dimension_pass = ([int]$bitmap.Width -eq $ExpectedWidth -and [int]$bitmap.Height -eq $ExpectedHeight)
            nonblank_frame_count = @($frameRows | Where-Object { $_.nonblank }).Count
            arterial_red_sample_count = (@($frameRows | Measure-Object -Property arterial_red_samples -Sum).Sum)
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
    $status = if ($byteMatch -and [bool]$imageAudit.dimension_pass -and $nonblankPass -and $redPass) { "pass" } else { "fail" }

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
    "- This audit does not approve final animation polish.",
    "- Wet sheets must contain zero arterial red samples.",
    "",
    "| Animation | Direction | Status | Size | Frames nonblank | Byte match | Arterial red samples | Sheet | Godot import |",
    "|---|---|---|---|---:|---|---:|---|---|"
)
foreach ($row in @($auditRows.ToArray())) {
    $lines += "| $($row.animation) | $($row.direction) | $($row.status) | $($row.width)x$($row.height) | $($row.nonblank_frame_count)/$($row.frames) | $($row.byte_for_byte_import) | $($row.arterial_red_sample_count) | ``$($row.sheet_export)`` | ``$($row.godot_import)`` |"
}
Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

if ($failedRows.Count -gt 0) {
    throw "Corvin side action rendered-sheet audit failed for: $(@($failedRows | ForEach-Object { "$($_.animation) $($_.direction)" }) -join ', ')"
}

Write-Host "Corvin side action rendered-sheet audit passed: rows=$($auditRows.Count), status=$($payload.status)."
