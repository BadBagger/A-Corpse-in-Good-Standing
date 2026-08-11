$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$statusPath = Join-Path $root "docs\art\corvin_act_i_clean_side_idle_status.json"
$reportPath = Join-Path $root "docs\art\corvin_act_i_clean_side_idle_status.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Render-CorvinActICleanSideIdleSheet.ps1")

foreach ($path in @($statusPath, $reportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side idle artifact: $path"
    }
}

$status = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
if ($status.status -ne "audited") {
    throw "Corvin side idle sheet must be audited."
}
if ($status.runtime_candidate -ne $true -or $status.final_polish -ne $false) {
    throw "Corvin side idle sheet must be marked runtime candidate, not final polish."
}
if ($status.variant -ne "act_i_clean" -or $status.animation -ne "idle" -or $status.direction -ne "side_right") {
    throw "Corvin side idle sheet has wrong variant/animation/direction."
}
if ([int]$status.frames -ne 12 -or [int]$status.fps -ne 12) {
    throw "Corvin side idle sheet must be 12 frames at 12 fps."
}
if ([int]$status.cell_width -ne 256 -or [int]$status.cell_height -ne 512) {
    throw "Corvin side idle sheet cell size mismatch."
}

$sheetPath = Join-Path $root ([string]$status.sheet_export -replace "/", "\")
$godotPath = Join-Path $root ([string]$status.godot_resource -replace "/", "\")
foreach ($path in @($sheetPath, $godotPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin side idle PNG: $path"
    }
}

Add-Type -AssemblyName System.Drawing
foreach ($path in @($sheetPath, $godotPath)) {
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($path)
        if ($bitmap.Width -ne 3072 -or $bitmap.Height -ne 512) {
            throw "Corvin side idle sheet dimensions must be 3072x512, got $($bitmap.Width)x$($bitmap.Height): $path"
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

$report = Get-Content -LiteralPath $reportPath -Raw
foreach ($requiredText in @("Corvin Act I Clean Side Idle Status", "Runtime candidate: true", "Final polish: false", "side_right", "12 fps")) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side idle report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Corvin side idle report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin side idle report must stay ASCII-only."
}

Write-Host "Corvin Act I clean side idle validation passed: sheet=$($status.sheet_export), godot=$($status.godot_resource)"
