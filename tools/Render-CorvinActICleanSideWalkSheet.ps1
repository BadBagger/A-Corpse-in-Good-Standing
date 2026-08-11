param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$idleSheetPath = Join-Path $root "art\export\characters\corvin\act_i_clean\idle_side_right.png"
$sheetOutput = Join-Path $root "art\export\characters\corvin\act_i_clean\walk_side_right.png"
$godotOutput = Join-Path $root "game\characters\corvin\sprites\act_i_clean\walk_side_right.png"
$statusPath = Join-Path $root "docs\art\corvin_act_i_clean_side_walk_status.json"
$reportPath = Join-Path $root "docs\art\corvin_act_i_clean_side_walk_status.md"
$frameCount = 8
$cellWidth = 256
$cellHeight = 512
$idleFrames = 12

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    return ($Path.Substring($root.Length + 1) -replace "\\", "/")
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory)) {
        New-Item -ItemType Directory -Path $Directory | Out-Null
    }
}

foreach ($directory in @((Split-Path -Parent $sheetOutput), (Split-Path -Parent $godotOutput), (Split-Path -Parent $statusPath))) {
    Ensure-Directory -Directory $directory
}

if (-not (Test-Path -LiteralPath $idleSheetPath)) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Render-CorvinActICleanSideIdleSheet.ps1")
}

if (-not (Test-Path -LiteralPath $idleSheetPath)) {
    throw "Missing Corvin side idle source sheet: $idleSheetPath"
}

if ((Test-Path -LiteralPath $sheetOutput) -and (Test-Path -LiteralPath $godotOutput) -and -not $Force) {
    Write-Host "Corvin Act I clean side walk sheet already exists. Use -Force to regenerate."
}

Add-Type -AssemblyName System.Drawing

function Get-FrameRegion {
    param(
        [Parameter(Mandatory=$true)][System.Drawing.Bitmap]$Sheet,
        [Parameter(Mandatory=$true)][int]$FrameIndex
    )

    $region = [System.Drawing.Bitmap]::new($cellWidth, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($region)
    try {
        $graphics.Clear([System.Drawing.Color]::FromArgb(0, 12, 16, 19))
        $sourceRect = [System.Drawing.Rectangle]::new($FrameIndex * $cellWidth, 0, $cellWidth, $cellHeight)
        $destRect = [System.Drawing.Rectangle]::new(0, 0, $cellWidth, $cellHeight)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $graphics.DrawImage($Sheet, $destRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
    }
    finally {
        $graphics.Dispose()
    }
    return $region
}

function Add-WalkContactPixels {
    param(
        [Parameter(Mandatory=$true)][System.Drawing.Bitmap]$Bitmap,
        [Parameter(Mandatory=$true)][int]$FrameIndex
    )

    $body = [System.Drawing.Color]::FromArgb(255, 42, 58, 64)
    $hatch = [System.Drawing.Color]::FromArgb(255, 228, 220, 200)
    $drip = [System.Drawing.Color]::FromArgb(255, 125, 155, 78)
    $shadow = [System.Drawing.Color]::FromArgb(155, 12, 16, 19)

    $phase = $FrameIndex % 8
    $frontFoot = 128 + [int][math]::Round([math]::Sin(($phase / 8.0) * [math]::PI * 2.0) * 18.0)
    $backFoot = 128 - [int][math]::Round([math]::Sin(($phase / 8.0) * [math]::PI * 2.0) * 14.0)
    $groundY = 476

    for ($x = 80; $x -lt 178; $x++) {
        if ((($x + $FrameIndex) % 5) -lt 3) {
            $Bitmap.SetPixel($x, $groundY + 8, $shadow)
        }
    }

    foreach ($foot in @($frontFoot, $backFoot)) {
        for ($x = -10; $x -le 10; $x++) {
            $px = $foot + $x
            if ($px -ge 0 -and $px -lt $cellWidth) {
                $Bitmap.SetPixel($px, $groundY, $body)
                if (($x % 4) -eq 0) {
                    $Bitmap.SetPixel($px, $groundY - 1, $hatch)
                }
            }
        }
    }

    $dripX = 149 + (($FrameIndex % 3) - 1)
    $dripTop = 424 + ($FrameIndex % 5)
    for ($i = 0; $i -lt 10; $i++) {
        $y = $dripTop + $i
        if ($y -ge 0 -and $y -lt $cellHeight) {
            $Bitmap.SetPixel($dripX, $y, $drip)
        }
    }
}

function Build-WalkFrame {
    param(
        [Parameter(Mandatory=$true)][System.Drawing.Bitmap]$IdleFrame,
        [Parameter(Mandatory=$true)][int]$FrameIndex
    )

    $walkFrame = [System.Drawing.Bitmap]::new($cellWidth, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $walkFrame.MakeTransparent()
    $phaseRadians = ($FrameIndex / [double]$frameCount) * [math]::PI * 2.0
    $offsetY = [int][math]::Round([math]::Sin($phaseRadians) * 3.0)
    $offsetX = [int][math]::Round([math]::Sin($phaseRadians + ([math]::PI / 2.0)) * 2.0)

    for ($y = 0; $y -lt $cellHeight; $y++) {
        for ($x = 0; $x -lt $cellWidth; $x++) {
            $pixel = $IdleFrame.GetPixel($x, $y)
            if ($pixel.A -lt 10) {
                continue
            }
            $targetX = $x + $offsetX
            $targetY = $y + $offsetY
            if ($targetX -ge 0 -and $targetX -lt $cellWidth -and $targetY -ge 0 -and $targetY -lt $cellHeight) {
                $walkFrame.SetPixel($targetX, $targetY, $pixel)
            }
        }
    }

    Add-WalkContactPixels -Bitmap $walkFrame -FrameIndex $FrameIndex
    return $walkFrame
}

$notes = New-Object System.Collections.Generic.List[string]
$status = "audited"
$idleSheet = $null
$sheet = $null
$graphics = $null

try {
    $idleSheet = [System.Drawing.Bitmap]::new($idleSheetPath)
    if ($idleSheet.Width -ne ($cellWidth * $idleFrames) -or $idleSheet.Height -ne $cellHeight) {
        throw "Corvin idle source sheet dimensions must be $($cellWidth * $idleFrames)x$cellHeight, got $($idleSheet.Width)x$($idleSheet.Height)"
    }

    $sheet = [System.Drawing.Bitmap]::new($cellWidth * $frameCount, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($sheet)
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 12, 16, 19))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    for ($i = 0; $i -lt $frameCount; $i++) {
        $sourceIndex = [int][math]::Floor(($i / [double]$frameCount) * $idleFrames)
        $idleFrame = $null
        $walkFrame = $null
        try {
            $idleFrame = Get-FrameRegion -Sheet $idleSheet -FrameIndex $sourceIndex
            $walkFrame = Build-WalkFrame -IdleFrame $idleFrame -FrameIndex $i
            $graphics.DrawImageUnscaled($walkFrame, $i * $cellWidth, 0)
        }
        finally {
            if ($null -ne $idleFrame) { $idleFrame.Dispose() }
            if ($null -ne $walkFrame) { $walkFrame.Dispose() }
        }
    }

    $sheet.Save($sheetOutput, [System.Drawing.Imaging.ImageFormat]::Png)
    $sheet.Save($godotOutput, [System.Drawing.Imaging.ImageFormat]::Png)
    $notes.Add("Generated first-pass Act I clean side_right walk sprite sheet from the audited idle/shader silhouette.")
    $notes.Add("This is a runtime candidate for scene integration, not final walk polish or rigged locomotion.")
    $notes.Add("Final polish still needs a rigged in-place walk pass from the Meshy biped source.")
}
finally {
    if ($null -ne $graphics) { $graphics.Dispose() }
    if ($null -ne $sheet) { $sheet.Dispose() }
    if ($null -ne $idleSheet) { $idleSheet.Dispose() }
}

$summary = [ordered]@{
    generated_from = "tools/Render-CorvinActICleanSideWalkSheet.ps1"
    status = $status
    runtime_candidate = $true
    final_polish = $false
    needs_rigged_walk_polish = $true
    character_id = "corvin"
    variant = "act_i_clean"
    animation = "walk"
    direction = "side_right"
    fps = 12
    frames = $frameCount
    cell_width = $cellWidth
    cell_height = $cellHeight
    sheet_width = $cellWidth * $frameCount
    sheet_height = $cellHeight
    sheet_export = Get-RelativePath -Path $sheetOutput
    godot_resource = Get-RelativePath -Path $godotOutput
    source_sheet = Get-RelativePath -Path $idleSheetPath
    notes = @($notes)
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statusPath -Encoding UTF8

$reportLines = @(
    "# Corvin Act I Clean Side Walk Status",
    "",
    'Generated by `tools/Render-CorvinActICleanSideWalkSheet.ps1`.',
    "",
    "Status: $status.",
    "Runtime candidate: true.",
    "Final polish: false.",
    "Needs rigged walk polish: true.",
    "Variant: act_i_clean.",
    "Animation: walk.",
    "Direction: side_right.",
    "Frames: $frameCount at 12 fps.",
    "Cell: ${cellWidth}x${cellHeight}.",
    "Sheet: ``$(Get-RelativePath -Path $sheetOutput)``.",
    "Godot resource: ``$(Get-RelativePath -Path $godotOutput)``.",
    "",
    "Notes:"
)
foreach ($note in $notes) {
    $reportLines += "- $note"
}
Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8

Write-Host "Corvin Act I clean side walk sheet: status=$status, sheet=$(Get-RelativePath -Path $sheetOutput), godot=$(Get-RelativePath -Path $godotOutput), frames=$frameCount, cell=${cellWidth}x${cellHeight}"
