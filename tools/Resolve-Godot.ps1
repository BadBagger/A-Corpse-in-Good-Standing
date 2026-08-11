$ErrorActionPreference = "Stop"

function Get-CorpseGodotPath {
    param(
        [ValidateSet("Console", "Windowed")]
        [string]$Kind = "Console"
    )

    $exeName = if ($Kind -eq "Console") {
        "Godot_v4.6.3-stable_mono_win64_console.exe"
    } else {
        "Godot_v4.6.3-stable_mono_win64.exe"
    }

    $explicitEnvName = if ($Kind -eq "Console") { "CORPSE_GODOT_CONSOLE" } else { "CORPSE_GODOT_WINDOWED" }
    $candidates = New-Object System.Collections.Generic.List[string]

    $explicit = [Environment]::GetEnvironmentVariable($explicitEnvName)
    if (-not [string]::IsNullOrWhiteSpace($explicit)) {
        $candidates.Add($explicit)
    }

    $godotDir = [Environment]::GetEnvironmentVariable("CORPSE_GODOT_DIR")
    if (-not [string]::IsNullOrWhiteSpace($godotDir)) {
        $candidates.Add((Join-Path $godotDir $exeName))
    }

    $wingetDir = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64"
    $candidates.Add((Join-Path $wingetDir $exeName))

    $uniqueCandidates = @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    foreach ($candidate in $uniqueCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $downloadDir = Join-Path $env:USERPROFILE "Downloads"
    if (Test-Path -LiteralPath $downloadDir) {
        $downloadsMatch = Get-ChildItem -LiteralPath $downloadDir -Filter $exeName -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -ne $downloadsMatch) {
            return $downloadsMatch.FullName
        }
    }

    throw "Godot 4.6.3 .NET $($Kind.ToLowerInvariant()) executable not found. Set $explicitEnvName or CORPSE_GODOT_DIR. Searched: $($uniqueCandidates -join '; ')"
}
