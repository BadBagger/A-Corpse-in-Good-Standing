$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")

$blender = Get-CorpseBlenderPath
if (-not (Test-Path -LiteralPath $blender)) {
    throw "Resolved Blender path does not exist: $blender"
}

$versionOutput = & $blender --version 2>&1
$exit = $LASTEXITCODE
if ($exit -ne 0) {
    throw "Blender version probe failed with exit code $exit."
}

$versionLine = @($versionOutput | Where-Object { $_ -match "^Blender " })[0]
if ([string]::IsNullOrWhiteSpace([string]$versionLine)) {
    throw "Blender version probe did not report a Blender version."
}

Write-Host "Blender resolver validation passed: path=$blender, version=$versionLine"
