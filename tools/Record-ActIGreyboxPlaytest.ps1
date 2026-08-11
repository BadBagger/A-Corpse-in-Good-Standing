$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$godot = "C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe"

if (-not (Test-Path -LiteralPath $godot)) {
    throw "Godot 4.6.3 .NET console executable not found: $godot"
}

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
