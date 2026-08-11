$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-InkCompiler.ps1")
$inklecate = Get-CorpseInkCompilerPath
$source = Join-Path $root "ink\prologue.ink"
$outDir = Join-Path $root "ink\build"
$output = Join-Path $outDir "prologue.ink.json"

if (-not (Test-Path -LiteralPath $inklecate)) {
    throw "Missing inklecate: $inklecate"
}
if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing Ink source: $source"
}
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$compileOutput = & $inklecate -o $output $source 2>&1
$exit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
$compileOutput | Write-Host

if ($exit -ne 0) {
    throw "Ink compile failed with exit code $exit"
}
if (-not (Test-Path -LiteralPath $output)) {
    throw "Ink compile did not produce output: $output"
}
if ($compileOutput -match "(?i)(ERROR|WARNING)") {
    throw "Ink compile produced warning/error output."
}

Write-Host "Ink compile passed: $output"
