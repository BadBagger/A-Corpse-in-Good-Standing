$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\corvin_animation_manifest.json"
$briefPath = Join-Path $root "docs\art\corvin_animation_brief.md"
$statusCsvPath = Join-Path $root "docs\art\corvin_animation_asset_status.csv"
$statusReportPath = Join-Path $root "docs\art\corvin_animation_asset_status.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-CorvinAnimationManifest.ps1")

foreach ($path in @($manifestPath, $briefPath, $statusCsvPath, $statusReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin animation artifact: $path"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.character_id -ne "corvin") {
    throw "Corvin animation manifest has wrong character id: $($manifest.character_id)"
}
if ($manifest.render_fps -ne 12) {
    throw "Corvin animation manifest must render at 12 fps."
}

$directions = @($manifest.directions)
foreach ($requiredDirection in @("front", "side_right", "back", "side_left")) {
    if ($requiredDirection -notin $directions) {
        throw "Corvin animation manifest missing direction: $requiredDirection"
    }
}
if ($directions.Count -ne 4) {
    throw "Corvin animation manifest must contain exactly 4 directions."
}

$variants = @($manifest.variants)
foreach ($requiredVariant in @("act_i_clean", "act_ii_salting", "act_iii_crusted")) {
    if ($requiredVariant -notin @($variants | ForEach-Object { $_.id })) {
        throw "Corvin animation manifest missing variant: $requiredVariant"
    }
}
if ($variants.Count -ne 3) {
    throw "Corvin animation manifest must contain exactly 3 decay variants."
}

$expectedAnimations = @("idle", "walk", "talk", "wet", "use")
foreach ($variant in $variants) {
    foreach ($pathProperty in @("meshy_source", "blender_source", "texture_source")) {
        $value = [string]$variant.$pathProperty
        if ([string]::IsNullOrWhiteSpace($value) -or $value -match "\\") {
            throw "Corvin variant $($variant.id) has invalid $pathProperty path: $value"
        }
    }

    $animations = @($variant.animations)
    if ($animations.Count -ne $expectedAnimations.Count) {
        throw "Corvin variant $($variant.id) animation count mismatch."
    }
    foreach ($animationName in $expectedAnimations) {
        $animation = @($animations | Where-Object { $_.id -eq $animationName })[0]
        if ($null -eq $animation) {
            throw "Corvin variant $($variant.id) missing animation: $animationName"
        }
        if ($animation.fps -ne 12) {
            throw "Corvin variant $($variant.id) animation $animationName must be 12 fps."
        }
        $animationDirections = @($animation.directions)
        if ($animationDirections.Count -ne 4) {
            throw "Corvin variant $($variant.id) animation $animationName must have 4 direction sheets."
        }
        foreach ($directionSpec in $animationDirections) {
            if ($directionSpec.direction -notin $directions) {
                throw "Corvin variant $($variant.id) animation $animationName has invalid direction: $($directionSpec.direction)"
            }
            foreach ($pathProperty in @("sheet_path", "godot_resource")) {
                $value = [string]$directionSpec.$pathProperty
                if ([string]::IsNullOrWhiteSpace($value) -or $value -match "\\") {
                    throw "Corvin variant $($variant.id) animation $animationName has invalid $pathProperty path: $value"
                }
            }
        }
    }
}

$statusRows = @(Import-Csv -LiteralPath $statusCsvPath)
if ($statusRows.Count -ne 129) {
    throw "Corvin animation asset status row count mismatch: expected 129, got $($statusRows.Count)"
}
foreach ($row in $statusRows) {
    if ($row.status -notin @("present", "pending")) {
        throw "Corvin animation asset status has invalid status: $($row.status)"
    }
    if ([string]::IsNullOrWhiteSpace($row.relative_path) -or $row.relative_path -match "\\") {
        throw "Corvin animation asset status has invalid path: $($row.relative_path)"
    }
}

$brief = Get-Content -LiteralPath $briefPath -Raw
$statusReport = Get-Content -LiteralPath $statusReportPath -Raw
foreach ($requiredText in @("Corvin Animation Manifest", "12 fps", "4 directions", "three visual decay variants", "Act I clean", "Act II salting", "Act III crusted")) {
    if ($brief -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin animation brief missing required text: $requiredText"
    }
}
foreach ($requiredText in @("Corvin Animation Asset Status", "production tracker", "129 total asset slots")) {
    if ($statusReport -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin animation asset status report missing required text: $requiredText"
    }
}
foreach ($text in @($brief, $statusReport)) {
    foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
        if ($text.Contains($forbiddenText)) {
            throw "Corvin animation generated report contains malformed Markdown: $forbiddenText"
        }
    }
    if ($text -match "[^\u0000-\u007F]") {
        throw "Corvin animation generated reports must stay ASCII-only."
    }
}

Write-Host "Corvin animation manifest validation passed: variants=$($variants.Count), directions=$($directions.Count), statusRows=$($statusRows.Count)"
