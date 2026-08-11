$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$statusPath = Join-Path $root "docs\art\corvin_act_i_clean_side_walk_status.json"
$reportPath = Join-Path $root "docs\art\corvin_act_i_clean_side_walk_status.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Render-CorvinActICleanSideWalkSheet.ps1") -Force

foreach ($path in @($statusPath, $reportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side walk artifact: $path"
    }
}

$status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
if ($status.status -ne "audited") {
    throw "Corvin side walk sheet must be audited."
}
if ($status.runtime_candidate -ne $true -or $status.final_polish -ne $false) {
    throw "Corvin side walk sheet must be marked runtime candidate, not final polish."
}
if ($status.needs_rigged_walk_polish -ne $true) {
    throw "Corvin side walk sheet must record that rigged walk polish is still needed."
}
if ($status.variant -ne "act_i_clean" -or $status.animation -ne "walk" -or $status.direction -ne "side_right") {
    throw "Corvin side walk sheet has wrong variant/animation/direction."
}
if ([int]$status.frames -ne 8 -or [int]$status.fps -ne 12) {
    throw "Corvin side walk sheet must be 8 frames at 12 fps."
}
if ([int]$status.cell_width -ne 256 -or [int]$status.cell_height -ne 512) {
    throw "Corvin side walk sheet cell size mismatch."
}

$sheetPath = Join-Path $root ([string]$status.sheet_export -replace "/", "\")
$godotPath = Join-Path $root ([string]$status.godot_resource -replace "/", "\")
foreach ($path in @($sheetPath, $godotPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side walk PNG: $path"
    }
}

Add-Type -AssemblyName System.Drawing
foreach ($path in @($sheetPath, $godotPath)) {
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($path)
        if ($bitmap.Width -ne 2048 -or $bitmap.Height -ne 512) {
            throw "Corvin side walk sheet dimensions must be 2048x512, got $($bitmap.Width)x$($bitmap.Height): $path"
        }

        $foreground = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 4) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 4) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -gt 10 -and ($pixel.R -gt 10 -or $pixel.G -gt 10 -or $pixel.B -gt 10)) {
                    $foreground++
                }
            }
        }
        if ($foreground -lt 100) {
            throw "Corvin side walk sheet appears blank: $path"
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

$report = Get-Content -LiteralPath $reportPath -Raw
foreach ($requiredText in @("Corvin Act I Clean Side Walk Status", "Runtime candidate: true", "Final polish: false", "Needs rigged walk polish: true", "side_right", "12 fps")) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side walk report missing required text: $requiredText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin side walk report must stay ASCII-only."
}

Write-Host "Corvin Act I clean side walk validation passed: sheet=$($status.sheet_export), godot=$($status.godot_resource)"
