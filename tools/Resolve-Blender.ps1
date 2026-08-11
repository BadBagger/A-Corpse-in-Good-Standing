$ErrorActionPreference = "Stop"

function Get-CorpseBlenderPath {
    param(
        [switch]$Optional,
        [switch]$SkipProbe
    )

    $root = Split-Path -Parent $PSScriptRoot
    $candidates = New-Object System.Collections.Generic.List[string]

    $explicit = [Environment]::GetEnvironmentVariable("CORPSE_BLENDER")
    if (-not [string]::IsNullOrWhiteSpace($explicit)) {
        $candidates.Add($explicit)
    }

    $blenderDir = [Environment]::GetEnvironmentVariable("CORPSE_BLENDER_DIR")
    if (-not [string]::IsNullOrWhiteSpace($blenderDir)) {
        $candidates.Add((Join-Path $blenderDir "blender.exe"))
    }

    if (-not $SkipProbe) {
        $probePath = Join-Path $root "docs\art\blender_corvin_import_probe.json"
        if (Test-Path -LiteralPath $probePath) {
            try {
                $probe = Get-Content -LiteralPath $probePath -Raw | ConvertFrom-Json
                if (-not [string]::IsNullOrWhiteSpace([string]$probe.blender_path)) {
                    $candidates.Add([string]$probe.blender_path)
                }
            }
            catch {
                # Ignore malformed probe data here; the probe validator owns that artifact.
            }
        }
    }

    $command = Get-Command blender -ErrorAction SilentlyContinue
    if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace([string]$command.Source)) {
        $candidates.Add([string]$command.Source)
    }

    foreach ($path in @(
        "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.1\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.0\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 3.6\blender.exe",
        "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender.exe"
    )) {
        $candidates.Add($path)
    }

    $uniqueCandidates = @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    foreach ($candidate in $uniqueCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    if ($Optional) {
        return $null
    }

    throw "Blender executable not found. Set CORPSE_BLENDER or CORPSE_BLENDER_DIR. Searched: $($uniqueCandidates -join '; ')"
}
