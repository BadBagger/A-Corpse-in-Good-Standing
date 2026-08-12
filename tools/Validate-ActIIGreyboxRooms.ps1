$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")
$godot = Get-CorpseGodotPath -Kind Console

Push-Location $root
try {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $godot --headless --path $root --script "res://tools/godot_validate_act_ii_rooms.gd" 2>&1
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $output | Write-Host
    if ($exit -ne 0) {
        throw "Act II greybox room validator failed with exit code $exit"
    }

    $unexpectedErrors = @(
        $output |
            Where-Object { $_ -match "^(SCRIPT ERROR|ERROR):" } |
            Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
            Where-Object { $_ -notmatch "resources still in use at exit" }
    )
    if ($unexpectedErrors.Count -gt 0) {
        throw "Act II greybox room validator produced errors: $($unexpectedErrors -join ' | ')"
    }
}
finally {
    Pop-Location
}
