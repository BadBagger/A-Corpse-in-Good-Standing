$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\checkpoints\toolchain_status.json"
$mdPath = Join-Path $root "docs\checkpoints\toolchain_status.md"
$expectedInkHash = "FE28FD3CBC6C1ADE1EC3FBD76AFAC1DAAC09E2101E699142E2051B838411C608"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ToolchainStatus.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Toolchain status export failed."
}

foreach ($path in @($jsonPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Expected toolchain status artifact missing: $path"
    }
}

$status = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$markdown = Get-Content -LiteralPath $mdPath -Raw

if ($status.tools.godot.console_path -notmatch "Godot_v4\.6\.3-stable_mono_win64_console\.exe$") {
    throw "Godot console path is not the required 4.6.3 .NET console executable: $($status.tools.godot.console_path)"
}

if ($status.tools.godot.windowed_path -notmatch "Godot_v4\.6\.3-stable_mono_win64\.exe$") {
    throw "Godot windowed path is not the required 4.6.3 .NET windowed executable: $($status.tools.godot.windowed_path)"
}

foreach ($path in @($status.tools.godot.console_path, $status.tools.godot.windowed_path, $status.tools.blender.path, $status.tools.inklecate.path)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Resolved toolchain path does not exist: $path"
    }
}

if ([string]$status.tools.godot.version -notmatch "4\.6\.3") {
    throw "Godot version proof does not show 4.6.3: $($status.tools.godot.version)"
}

if ([string]$status.tools.blender.version -notmatch "^Blender ") {
    throw "Blender version proof is missing: $($status.tools.blender.version)"
}

if ([string]$status.tools.inklecate.product_name -ne "inklecate") {
    throw "Ink compiler product name mismatch: $($status.tools.inklecate.product_name)"
}

if ([string]$status.tools.inklecate.sha256 -ne $expectedInkHash) {
    throw "Ink compiler hash mismatch. Expected $expectedInkHash, got $($status.tools.inklecate.sha256)"
}

if ($markdown.Contains('$(')) {
    throw "Toolchain status markdown contains an unresolved PowerShell interpolation placeholder."
}

foreach ($name in @(
    "CORPSE_GODOT_CONSOLE",
    "CORPSE_GODOT_WINDOWED",
    "CORPSE_GODOT_DIR",
    "CORPSE_BLENDER",
    "CORPSE_BLENDER_DIR",
    "CORPSE_INKLECATE"
)) {
    if (-not $markdown.Contains($name)) {
        throw "Toolchain status markdown missing environment override: $name"
    }
}

$nonAscii = [regex]::Match($markdown, "[^\u0000-\u007F]")
if ($nonAscii.Success) {
    throw "Toolchain status markdown contains non-ASCII character at index $($nonAscii.Index)."
}

Write-Host "Toolchain status validation passed."
