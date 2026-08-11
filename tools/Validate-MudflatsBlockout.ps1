param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\mudflats\room_mudflats.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$mudflats = @($manifest.rooms | Where-Object { $_.room_id -eq "mudflats" })[0]
if ($null -eq $mudflats) {
    throw "Mudflats room is missing from the Act I background manifest."
}

foreach ($relativePath in @($mudflats.source_blend, $mudflats.export_png, $mudflats.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Mudflats blockout is missing expected asset: $relativePath. Run tools\Render-MudflatsBlockout.ps1."
    }
}

if ($mudflats.export_png -ne "art/export/backgrounds/act_i/mudflats_bg.png") {
    throw "Mudflats export path changed unexpectedly: $($mudflats.export_png)"
}
if ($mudflats.godot_background_resource -ne "game/rooms/mudflats/background/mudflats_bg.png") {
    throw "Mudflats Godot background path changed unexpectedly: $($mudflats.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/mudflats/background/mudflats_bg.png"',
    '[node name="Silt" type="Area2D" parent="Hotspots"]',
    '[node name="OwnHands" type="Area2D" parent="Hotspots"]',
    '[node name="HarborView" type="Area2D" parent="Hotspots"]',
    '[node name="Coat" type="Area2D" parent="Hotspots"]',
    '[node name="BollardOfTomas" type="Area2D" parent="Hotspots"]',
    '[node name="MissingBoots" type="Area2D" parent="Hotspots"]',
    '[node name="SaltMarketExit" type="Area2D" parent="Hotspots"]'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Mudflats room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Mudflats scene must not use the gradient placeholder or introduce a duel."
}

if (-not $sceneText.Contains('script = ExtResource("5_xohei")') -or -not $sceneText.Contains('script_name = "SaltMarketExit"')) {
    throw "Mudflats SaltMarketExit must remain the scripted navigation hotspot."
}
if (-not $sceneText.Contains('position = Vector2(1765, 665)')) {
    throw "Mudflats Salt Market path pull moved from the reviewed coordinate."
}
if (-not $sceneText.Contains('position = Vector2(660, 760)') -or -not $sceneText.Contains('position = Vector2(735, 760)')) {
    throw "Mudflats OwnHands/Coat tutorial cluster changed without updating the close-pair review."
}

$hotspots = @($mudflats.hotspots)
$customNav = @($hotspots | Where-Object { $_.name -eq "road to the Salt Market" -or $_.label -eq "road to the Salt Market" })[0]
if ($null -eq $customNav -or "custom_navigation" -notin @($customNav.critical_roles)) {
    throw "Mudflats custom navigation contract is missing from the background manifest."
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Mudflats blockout must not introduce a duel hotspot or confession-spend interface."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "mudflats" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Mudflats blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "mudflats" })
if ($paletteRows.Count -ne 1) {
    throw "Mudflats palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Mudflats palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Mudflats G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Mudflats export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Mudflats blockout validation passed: blend=present, export=present, godot=present, scriptedExit=true, tutorialHotspots=7, inGamut=$($paletteRow.in_gamut_percent)%"
