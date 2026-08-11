$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$seedJsonPath = Join-Path $root "docs\art\corvin_shader_sprite_seed.json"
$seedReportPath = Join-Path $root "docs\art\corvin_shader_sprite_seed.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-CorvinShaderSpriteSeed.ps1")

foreach ($path in @($seedJsonPath, $seedReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin shader sprite seed artifact: $path"
    }
}

$seed = Get-Content -LiteralPath $seedJsonPath -Raw | ConvertFrom-Json
if ($seed.status -ne "audited") {
    throw "Corvin shader sprite seed must be audited."
}
if ($seed.runtime_sheet -ne $false) {
    throw "Corvin shader sprite seed must not be marked as a runtime sheet."
}
if ($seed.character_id -ne "corvin" -or $seed.variant -ne "act_i_clean" -or $seed.direction -ne "side_right") {
    throw "Corvin shader sprite seed points at the wrong character/variant/direction."
}
if ([int]$seed.source_frame_count -ne 24) {
    throw "Corvin shader sprite seed must use the 24-frame yaw proof."
}
if ([string]::IsNullOrWhiteSpace([string]$seed.contact_sheet) -or [string]$seed.contact_sheet -match "\\") {
    throw "Corvin shader sprite seed has invalid contact sheet path: $($seed.contact_sheet)"
}
if ([string]$seed.intended_first_runtime_target -ne "art/export/characters/corvin/act_i_clean/idle_side_right.png") {
    throw "Corvin shader sprite seed must target the Act I clean side-right idle sheet first."
}
if ([double]$seed.metrics.object_pairwise_max_percent -gt [double]$seed.metrics.pairwise_threshold_percent) {
    throw "Corvin shader sprite seed object pairwise metric exceeds threshold."
}
if ([double]$seed.metrics.object_first_last_drift_percent -gt [double]$seed.metrics.first_to_last_drift_threshold_percent) {
    throw "Corvin shader sprite seed drift metric exceeds threshold."
}
if ([double]$seed.metrics.bad_control_pairwise_max_percent -le [double]$seed.metrics.object_pairwise_max_percent) {
    throw "Corvin shader sprite seed bad control must measure worse than the candidate."
}

$contactPath = Join-Path $root ([string]$seed.contact_sheet -replace "/", "\")
if (-not (Test-Path -LiteralPath $contactPath)) {
    throw "Missing Corvin shader sprite contact sheet: $contactPath"
}

Add-Type -AssemblyName System.Drawing
$bitmap = $null
try {
    $bitmap = [System.Drawing.Bitmap]::new($contactPath)
    if ($bitmap.Width -ne 1920 -or $bitmap.Height -ne 720) {
        throw "Corvin shader sprite contact sheet dimensions must be 1920x720, got $($bitmap.Width)x$($bitmap.Height)."
    }
}
finally {
    if ($null -ne $bitmap) {
        $bitmap.Dispose()
    }
}

$report = Get-Content -LiteralPath $seedReportPath -Raw
foreach ($requiredText in @("Corvin Shader Sprite Seed", "Runtime sheet: false", "proof seed/contact sheet", "side_right", "do not ship")) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin shader sprite seed report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Corvin shader sprite seed report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin shader sprite seed report must stay ASCII-only."
}

Write-Host "Corvin shader sprite seed validation passed: contact=$($seed.contact_sheet), objectPairwise=$($seed.metrics.object_pairwise_max_percent), badControl=$($seed.metrics.bad_control_pairwise_max_percent)"
