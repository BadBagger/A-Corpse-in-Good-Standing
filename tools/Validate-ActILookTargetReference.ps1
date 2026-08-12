$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActILookTargetReference.ps1"
$jsonPath = Join-Path $root "docs\art\act_i_look_target_reference.json"
$mdPath = Join-Path $root "docs\art\act_i_look_target_reference.md"
$imagePath = Join-Path $root "docs\art\reference\look_targets\act_i_harbor_look_target_v1.png"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I look target reference exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I look target reference export failed."
}

foreach ($path in @($jsonPath, $mdPath, $imagePath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing Act I look target reference artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$report = Get-Content -LiteralPath $mdPath -Raw
$imageItem = Get-Item -LiteralPath $imagePath

if ($payload.status -ne "reference_only_review_target") {
    throw "Act I look target reference expected status reference_only_review_target, got $($payload.status)."
}
if ([string]$payload.image_path -ne "docs/art/reference/look_targets/act_i_harbor_look_target_v1.png") {
    throw "Act I look target reference has unexpected image path: $($payload.image_path)"
}
if ([int]$payload.width -ne 1672 -or [int]$payload.height -ne 941) {
    throw "Act I look target reference expected 1672x941 image, got $($payload.width)x$($payload.height)."
}
if ($imageItem.Length -le 0 -or [int64]$payload.size_bytes -ne [int64]$imageItem.Length) {
    throw "Act I look target reference size metadata is missing or stale."
}

foreach ($requiredText in @(
    "Act I Look Target Reference",
    "reference_only_review_target",
    "mood, palette, staging, and side-on adventure-game readability reference",
    "side-on Corvin read",
    "wet black coat silhouette",
    "amber/green lighting logic",
    "Not a final room plate.",
    "Not a paintover approval.",
    "Not a source of hotspot coordinates.",
    "Not a replacement for Blender greybox perspective.",
    "Not a diffusion-per-frame character source.",
    "Blender greybox and paintover remain authoritative",
    "Generated images remain reference only",
    "must not be imported as finished room plates",
    "deterministic 3D-to-Blender-to-2D",
    "Do not start final paintovers while the start gate reports blocked_pending_human_review."
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I look target reference report missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("final room plate source", "approved paintover", "System.Object[]", "@{", "ÃƒÂ¯Ã‚Â»Ã‚Â¿")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I look target reference report contains forbidden text: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I look target reference report must stay ASCII-only."
}

Write-Host "Act I look target reference validation passed: status=$($payload.status), image=$($payload.width)x$($payload.height), bytes=$($payload.size_bytes)."
