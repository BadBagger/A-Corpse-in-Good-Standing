$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Resolve-InkCompiler.ps1")

$root = Split-Path -Parent $PSScriptRoot
$compiler = Get-CorpseInkCompilerPath

if (-not (Test-Path -LiteralPath $compiler)) {
    throw "Resolved inklecate path does not exist: $compiler"
}

$info = (Get-Item -LiteralPath $compiler).VersionInfo
if ([string]$info.ProductName -ne "inklecate") {
    throw "Resolved Ink compiler does not identify as inklecate: product=$($info.ProductName), path=$compiler"
}

$hash = (Get-FileHash -LiteralPath $compiler -Algorithm SHA256).Hash.ToUpperInvariant()
$expectedHash = "FE28FD3CBC6C1ADE1EC3FBD76AFAC1DAAC09E2101E699142E2051B838411C608"
if ($hash -ne $expectedHash) {
    throw "inklecate SHA256 mismatch. Expected $expectedHash, got $hash. Path: $compiler"
}

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$usageOutput = & $compiler 2>&1
$usageExit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($usageExit -eq 0) {
    throw "inklecate usage probe unexpectedly exited with success."
}

$usageText = ($usageOutput | Out-String)
foreach ($expected in @("Usage: inklecate <options> <ink file>", "-o <filename>", "-s:")) {
    if (-not $usageText.Contains($expected)) {
        throw "inklecate usage probe missing expected text: $expected"
    }
}

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Compile-Ink.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Ink compiler validation failed during prologue compile."
}

$relative = $compiler.Substring($root.Length + 1).Replace("\", "/")
Write-Host "Ink compiler validation passed: path=$relative, sha256=$hash"
