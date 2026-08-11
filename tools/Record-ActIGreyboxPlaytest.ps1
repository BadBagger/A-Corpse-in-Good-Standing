$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Godot.ps1")
$godot = Get-CorpseGodotPath -Kind Console

Push-Location $root
try {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $godot --headless --path $root --script "res://tools/godot_record_act_i_greybox_playtest.gd" 2>&1
    $exit = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $output | Write-Host
    if ($exit -ne 0) {
        throw "Act I greybox playtest recorder failed with exit code $exit"
    }

    $unexpectedErrors = @(
        $output |
            Where-Object { $_ -match "^(SCRIPT ERROR|ERROR):" } |
            Where-Object { $_ -notmatch "RID allocations .* were leaked at exit\.$" } |
            Where-Object { $_ -notmatch "resources still in use at exit" }
    )
    if ($unexpectedErrors.Count -gt 0) {
        throw "Act I greybox playtest recorder produced errors: $($unexpectedErrors -join ' | ')"
    }
}
finally {
    Pop-Location
}
