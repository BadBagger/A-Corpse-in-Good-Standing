$ErrorActionPreference = "Stop"

function Get-CorpseInkCompilerPath {
    $root = Split-Path -Parent $PSScriptRoot
    $candidates = New-Object System.Collections.Generic.List[string]

    $explicit = [Environment]::GetEnvironmentVariable("CORPSE_INKLECATE")
    if (-not [string]::IsNullOrWhiteSpace($explicit)) {
        $candidates.Add($explicit)
    }

    $candidates.Add((Join-Path $root "tools\ink\inklecate.exe"))

    $command = Get-Command inklecate -ErrorAction SilentlyContinue
    if ($null -ne $command -and -not [string]::IsNullOrWhiteSpace([string]$command.Source)) {
        $candidates.Add([string]$command.Source)
    }

    $uniqueCandidates = @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    foreach ($candidate in $uniqueCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "inklecate executable not found. Set CORPSE_INKLECATE or restore tools\ink\inklecate.exe. Searched: $($uniqueCandidates -join '; ')"
}
