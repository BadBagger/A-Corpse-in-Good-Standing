param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\harbor_registry\room_harbor_registry.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$registry = @($manifest.rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
if ($null -eq $registry) {
    throw "Harbor Registry room is missing from the Act I background manifest."
}

$expectedPaths = @(
    $registry.source_blend,
    $registry.export_png,
    $registry.godot_background_resource
)
foreach ($relativePath in $expectedPaths) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Harbor Registry blockout is missing expected asset: $relativePath. Run tools\Render-HarborRegistryBlockout.ps1."
    }
}

if ($registry.export_png -ne "art/export/backgrounds/act_i/harbor_registry_bg.png") {
    throw "Harbor Registry export path changed unexpectedly: $($registry.export_png)"
}
if ($registry.godot_background_resource -ne "game/rooms/harbor_registry/background/harbor_registry_bg.png") {
    throw "Harbor Registry Godot background path changed unexpectedly: $($registry.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/harbor_registry/background/harbor_registry_bg.png"',
    'duel_opponent = "registrar"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Harbor Registry room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")')) {
    throw "Harbor Registry room scene still uses the gradient background instead of the blockout PNG."
}

$exits = @($registry.exits)
if ("ToSaltMarket" -notin @($exits | ForEach-Object { $_.name })) {
    throw "Harbor Registry blockout contract is missing exit: ToSaltMarket"
}

$hotspots = @($registry.hotspots)
foreach ($requiredHotspot in @("KestrelLedger", "DeskLamp", "Registrar")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Harbor Registry blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$registrar = @($hotspots | Where-Object { $_.name -eq "Registrar" })[0]
if ($null -eq $registrar -or $registrar.type -ne "duel" -or $registrar.duel_opponent -ne "registrar") {
    throw "Harbor Registry blockout contract must preserve Registrar duel metadata."
}
if ("duel" -notin @($registrar.critical_roles)) {
    throw "Harbor Registry Registrar hotspot is not marked as duel-critical."
}

$ledger = @($hotspots | Where-Object { $_.name -eq "KestrelLedger" })[0]
if ($null -eq $ledger -or "FL_registry_lamp_smoked" -notin @($ledger.requires_flags) -or "cf_bt_manifest" -notin @($ledger.confessions_discover)) {
    throw "Harbor Registry Kestrel ledger gating/confession contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "harbor_registry" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Harbor Registry blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "harbor_registry" })
if ($paletteRows.Count -ne 1) {
    throw "Harbor Registry palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Harbor Registry palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Harbor Registry G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Harbor Registry export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Harbor Registry blockout validation passed: blend=present, export=present, godot=present, inGamut=$($paletteRow.in_gamut_percent)%, registrar=duel"
