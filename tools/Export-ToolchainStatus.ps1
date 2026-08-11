$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")
. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")
. (Join-Path $PSScriptRoot "Resolve-InkCompiler.ps1")

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\checkpoints\toolchain_status.json"
$mdPath = Join-Path $root "docs\checkpoints\toolchain_status.md"

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    if ($Path.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Substring($root.Length + 1).Replace("\", "/")
    }

    return $Path
}

function Invoke-VersionProbe {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [Parameter(Mandatory=$true)][string]$Pattern
    )

    $output = & $Path @Arguments 2>&1
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
        throw "Version probe failed for $Path with exit code $exit."
    }

    $line = @($output | Where-Object { $_ -match $Pattern })[0]
    if ([string]::IsNullOrWhiteSpace([string]$line)) {
        throw "Version probe for $Path did not match pattern: $Pattern"
    }

    return [string]$line
}

$godotConsole = Get-CorpseGodotPath -Kind Console
$godotWindowed = Get-CorpseGodotPath -Kind Windowed
$blender = Get-CorpseBlenderPath
$inkCompiler = Get-CorpseInkCompilerPath

$inkInfo = (Get-Item -LiteralPath $inkCompiler).VersionInfo
$inkHash = (Get-FileHash -LiteralPath $inkCompiler -Algorithm SHA256).Hash.ToUpperInvariant()

$status = [ordered]@{
    project = "A Corpse in Good Standing"
    purpose = "Local-only toolchain audit for Step 2-5 readiness"
    ci_boundary = "Not part of GitHub Actions until portable Godot and Blender installs are available in CI"
    tools = [ordered]@{
        godot = [ordered]@{
            required = "Godot 4.6.3 .NET"
            console_path = $godotConsole
            console_path_display = Get-RelativePath -Path $godotConsole
            windowed_path = $godotWindowed
            windowed_path_display = Get-RelativePath -Path $godotWindowed
            version = Invoke-VersionProbe -Path $godotConsole -Arguments @("--version") -Pattern "4\.6\.3|Godot"
            env_overrides = @("CORPSE_GODOT_CONSOLE", "CORPSE_GODOT_WINDOWED", "CORPSE_GODOT_DIR")
        }
        blender = [ordered]@{
            required = "Blender with GLB import and headless render support"
            path = $blender
            path_display = Get-RelativePath -Path $blender
            version = Invoke-VersionProbe -Path $blender -Arguments @("--version") -Pattern "^Blender "
            env_overrides = @("CORPSE_BLENDER", "CORPSE_BLENDER_DIR")
        }
        inklecate = [ordered]@{
            required = "Vendored Ink compiler"
            path = $inkCompiler
            path_display = Get-RelativePath -Path $inkCompiler
            product_name = [string]$inkInfo.ProductName
            product_version = [string]$inkInfo.ProductVersion
            sha256 = $inkHash
            env_overrides = @("CORPSE_INKLECATE")
        }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsonPath, ($status | ConvertTo-Json -Depth 8), $utf8NoBom)

$godotStatus = $status["tools"]["godot"]
$blenderStatus = $status["tools"]["blender"]
$inkStatus = $status["tools"]["inklecate"]

$md = @"
# Toolchain Status

Local-only audit for Step 2-5 readiness. This report is intentionally not a GitHub Actions gate until CI installs portable Godot and Blender toolchains.

| Tool | Required | Resolved path | Version / proof |
|---|---|---|---|
| Godot console | Godot 4.6.3 .NET | ``$($godotStatus["console_path_display"])`` | ``$($godotStatus["version"])`` |
| Godot windowed | Godot 4.6.3 .NET | ``$($godotStatus["windowed_path_display"])`` | executable exists |
| Blender | GLB import and headless render support | ``$($blenderStatus["path_display"])`` | ``$($blenderStatus["version"])`` |
| inklecate | Vendored Ink compiler | ``$($inkStatus["path_display"])`` | ``$($inkStatus["sha256"])`` |

## Environment Overrides

- ``CORPSE_GODOT_CONSOLE``
- ``CORPSE_GODOT_WINDOWED``
- ``CORPSE_GODOT_DIR``
- ``CORPSE_BLENDER``
- ``CORPSE_BLENDER_DIR``
- ``CORPSE_INKLECATE``

## Boundary

This proves local tool discovery only. GitHub Actions still proves repo hygiene and Step 1; Godot/Popochiu rooms, Blender rendering, shader proofs, and Step 2-5 gates remain local-only until portable CI tooling is installed.
"@

[System.IO.File]::WriteAllText($mdPath, $md, $utf8NoBom)

Write-Host "Toolchain status exported:"
Write-Host "  $jsonPath"
Write-Host "  $mdPath"
