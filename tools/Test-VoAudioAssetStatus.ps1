$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$validateScript = Join-Path $PSScriptRoot "Validate-VoAudioAssetStatus.ps1"
$statusJsonPath = Join-Path $root "docs\vo\vo_audio_asset_status.json"
$strayDir = Join-Path $root "vo\_unplanned_test"
$strayFile = Join-Path $strayDir "stray.mp3"

if (-not (Test-Path -LiteralPath $validateScript)) {
    throw "Missing VO audio asset status validator: $validateScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript
if ($LASTEXITCODE -ne 0) {
    throw "Baseline VO audio asset status validation failed."
}

New-Item -ItemType Directory -Path $strayDir -Force | Out-Null
[System.IO.File]::WriteAllBytes($strayFile, [byte[]](1, 2, 3, 4))

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$badOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript 2>&1
$badExit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

Remove-Item -LiteralPath $strayFile -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $strayDir -Force -ErrorAction SilentlyContinue

& powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript
if ($LASTEXITCODE -ne 0) {
    throw "VO audio asset status validation failed after cleaning stray test file."
}

if ($badExit -eq 0) {
    throw "VO audio asset status negative control unexpectedly passed."
}
if (($badOutput -join "`n") -notmatch "unplanned MP3") {
    throw "VO audio asset status negative control failed for the wrong reason: $($badOutput -join ' ')"
}

$status = Get-Content -LiteralPath $statusJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$blockedRow = @($status.lines | Where-Object { $_.recording_queue_status -eq "blocked_pending_cast_decision" } | Select-Object -First 1)[0]
if ($null -eq $blockedRow) {
    throw "VO audio asset status test cannot find a blocked pending-cast expected row."
}

$voRoot = Join-Path $root "vo"
$blockedFile = Join-Path $root (([string]$blockedRow.audio_path) -replace "/", "\")
$blockedDir = Split-Path -Parent $blockedFile
$resolvedVoRoot = [System.IO.Path]::GetFullPath($voRoot).TrimEnd("\") + "\"
$resolvedBlockedFile = [System.IO.Path]::GetFullPath($blockedFile)
if (-not $resolvedBlockedFile.StartsWith($resolvedVoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Blocked-audio negative control resolved outside vo root: $resolvedBlockedFile"
}

New-Item -ItemType Directory -Path $blockedDir -Force | Out-Null
[System.IO.File]::WriteAllBytes($blockedFile, [byte[]](5, 6, 7, 8))

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$blockedOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript 2>&1
$blockedExit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

Remove-Item -LiteralPath $blockedFile -Force -ErrorAction SilentlyContinue

& powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript
if ($LASTEXITCODE -ne 0) {
    throw "VO audio asset status validation failed after cleaning blocked-audio test file."
}

if ($blockedExit -eq 0) {
    throw "VO audio asset status blocked-audio negative control unexpectedly passed."
}
if (($blockedOutput -join "`n") -notmatch "blocked expected MP3") {
    throw "VO audio asset status blocked-audio negative control failed for the wrong reason: $($blockedOutput -join ' ')"
}

Write-Host "VO audio asset status test passed: baseline validates, unplanned MP3 fails, blocked expected MP3 fails, cleanup restores validation."
