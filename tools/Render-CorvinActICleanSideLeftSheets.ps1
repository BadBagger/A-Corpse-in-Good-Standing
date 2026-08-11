param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$cellWidth = 256
$cellHeight = 512

$jobs = @(
    [ordered]@{
        animation = "idle"
        frames = 12
        source = Join-Path $root "art\export\characters\corvin\act_i_clean\idle_side_right.png"
        sheet = Join-Path $root "art\export\characters\corvin\act_i_clean\idle_side_left.png"
        godot = Join-Path $root "game\characters\corvin\sprites\act_i_clean\idle_side_left.png"
    },
    [ordered]@{
        animation = "walk"
        frames = 8
        source = Join-Path $root "art\export\characters\corvin\act_i_clean\walk_side_right.png"
        sheet = Join-Path $root "art\export\characters\corvin\act_i_clean\walk_side_left.png"
        godot = Join-Path $root "game\characters\corvin\sprites\act_i_clean\walk_side_left.png"
    }
)

$statusPath = Join-Path $root "docs\art\corvin_act_i_clean_side_left_status.json"
$reportPath = Join-Path $root "docs\art\corvin_act_i_clean_side_left_status.md"

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

function Mirror-Sheet {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Output,
        [Parameter(Mandatory=$true)][int]$Frames
    )

    $expectedWidth = $cellWidth * $Frames
    $sourceBitmap = $null
    $mirroredSheet = $null
    $graphics = $null
    try {
        $sourceBitmap = [System.Drawing.Bitmap]::new($Source)
        if ($sourceBitmap.Width -ne $expectedWidth -or $sourceBitmap.Height -ne $cellHeight) {
            throw "Source sheet dimensions mismatch for $(Get-RelativePath -Path $Source): got $($sourceBitmap.Width)x$($sourceBitmap.Height), expected ${expectedWidth}x${cellHeight}."
        }

        $mirroredSheet = [System.Drawing.Bitmap]::new($expectedWidth, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($mirroredSheet)
        $graphics.Clear([System.Drawing.Color]::FromArgb(0, 12, 16, 19))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

        for ($frameIndex = 0; $frameIndex -lt $Frames; $frameIndex++) {
            $frame = [System.Drawing.Bitmap]::new($cellWidth, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $frameGraphics = [System.Drawing.Graphics]::FromImage($frame)
            try {
                $frameGraphics.Clear([System.Drawing.Color]::FromArgb(0, 12, 16, 19))
                $sourceRect = [System.Drawing.Rectangle]::new($frameIndex * $cellWidth, 0, $cellWidth, $cellHeight)
                $destRect = [System.Drawing.Rectangle]::new(0, 0, $cellWidth, $cellHeight)
                $frameGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $frameGraphics.DrawImage($sourceBitmap, $destRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            }
            finally {
                $frameGraphics.Dispose()
            }

            try {
                $frame.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
                $graphics.DrawImageUnscaled($frame, $frameIndex * $cellWidth, 0)
            }
            finally {
                $frame.Dispose()
            }
        }

        $mirroredSheet.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        if ($null -ne $graphics) { $graphics.Dispose() }
        if ($null -ne $mirroredSheet) { $mirroredSheet.Dispose() }
        if ($null -ne $sourceBitmap) { $sourceBitmap.Dispose() }
    }
}

Add-Type -AssemblyName System.Drawing

foreach ($job in $jobs) {
    foreach ($directory in @((Split-Path -Parent $job.sheet), (Split-Path -Parent $job.godot), (Split-Path -Parent $statusPath))) {
        Ensure-Directory -Directory $directory
    }

    if (-not (Test-Path -LiteralPath $job.source)) {
        $generator = if ($job.animation -eq "idle") { "Render-CorvinActICleanSideIdleSheet.ps1" } else { "Render-CorvinActICleanSideWalkSheet.ps1" }
        powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $generator)
    }
    if (-not (Test-Path -LiteralPath $job.source)) {
        throw "Missing Corvin side_right source sheet for left-facing mirror: $($job.source)"
    }

    if ((Test-Path -LiteralPath $job.sheet) -and (Test-Path -LiteralPath $job.godot) -and -not $Force) {
        Write-Host "Corvin Act I clean $($job.animation) side_left sheet already exists. Use -Force to regenerate."
    }
    else {
        Mirror-Sheet -Source $job.source -Output $job.sheet -Frames $job.frames
        Copy-Item -LiteralPath $job.sheet -Destination $job.godot -Force
    }
}

$summary = [ordered]@{
    generated_from = "tools/Render-CorvinActICleanSideLeftSheets.ps1"
    status = "audited"
    runtime_candidate = $true
    final_polish = $false
    character_id = "corvin"
    variant = "act_i_clean"
    direction = "side_left"
    source_direction = "side_right"
    cell_width = $cellWidth
    cell_height = $cellHeight
    sheets = @(
        [ordered]@{
            animation = "idle"
            frames = 12
            fps = 12
            sheet_export = Get-RelativePath -Path $jobs[0].sheet
            godot_resource = Get-RelativePath -Path $jobs[0].godot
            source_sheet = Get-RelativePath -Path $jobs[0].source
        },
        [ordered]@{
            animation = "walk"
            frames = 8
            fps = 12
            sheet_export = Get-RelativePath -Path $jobs[1].sheet
            godot_resource = Get-RelativePath -Path $jobs[1].godot
            source_sheet = Get-RelativePath -Path $jobs[1].source
        }
    )
    notes = @(
        "Generated deterministic side_left runtime candidates by mirroring the audited side_right sheets per frame.",
        "This keeps early navigation readable while final rigged locomotion polish remains pending.",
        "Asymmetrical coat wear and salt details will need a final art pass after the Meshy/Blender walk cycle is locked."
    )
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statusPath -Encoding UTF8

$reportLines = @(
    "# Corvin Act I Clean Side Left Status",
    "",
    'Generated by `tools/Render-CorvinActICleanSideLeftSheets.ps1`.',
    "",
    "Status: audited.",
    "Runtime candidate: true.",
    "Final polish: false.",
    "Variant: act_i_clean.",
    "Direction: side_left.",
    "Source direction: side_right.",
    "Cell: ${cellWidth}x${cellHeight}.",
    "",
    "| Animation | Frames | Sheet | Godot resource |",
    "|---|---:|---|---|"
)
foreach ($sheet in $summary.sheets) {
    $reportLines += "| $($sheet.animation) | $($sheet.frames) | ``$($sheet.sheet_export)`` | ``$($sheet.godot_resource)`` |"
}
$reportLines += @(
    "",
    "Notes:"
)
foreach ($note in $summary.notes) {
    $reportLines += "- $note"
}
Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8

Write-Host "Corvin Act I clean side_left sheets: status=audited, idle=$(Get-RelativePath -Path $jobs[0].godot), walk=$(Get-RelativePath -Path $jobs[1].godot)"
