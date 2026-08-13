$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")
$godot = Get-CorpseGodotPath -Kind Console

Push-Location $root
try {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $godot --path $root --script "res://tools/godot_capture_corvin_action_frames.gd" 2>&1
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $lines = @($output | ForEach-Object { [string]$_ })
    $lines | Write-Host
    if ($exit -ne 0) {
        throw "Corvin action runtime frame capture failed with exit code $exit"
    }

    $unexpectedErrors = @(
        $lines |
            Where-Object { $_ -match "^(SCRIPT ERROR|ERROR):" } |
            Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
            Where-Object { $_ -notmatch "resources still in use at exit" }
    )
    if ($unexpectedErrors.Count -gt 0) {
        throw "Corvin action runtime frame capture produced errors: $($unexpectedErrors -join ' | ')"
    }
}
finally {
    Pop-Location
}
