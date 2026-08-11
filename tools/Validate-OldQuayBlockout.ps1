param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$oldQuayScenePath = Join-Path $root "game\rooms\old_quay\room_old_quay.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$oldQuay = @($manifest.rooms | Where-Object { $_.room_id -eq "old_quay" })[0]
if ($null -eq $oldQuay) {
    throw "Old Quay room is missing from the Act I background manifest."
}

$expectedPaths = @(
    $oldQuay.source_blend,
    $oldQuay.export_png,
    $oldQuay.godot_background_resource
)
foreach ($relativePath in $expectedPaths) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Old Quay blockout is missing expected asset: $relativePath. Run tools\Render-OldQuayBlockout.ps1."
    }
}

if ($oldQuay.export_png -ne "art/export/backgrounds/act_i/old_quay_blockout_bg.png") {
    throw "Old Quay blockout export path changed unexpectedly: $($oldQuay.export_png)"
}
if ($oldQuay.godot_background_resource -ne "game/rooms/old_quay/background/old_quay_blockout_bg.png") {
    throw "Old Quay Godot background path changed unexpectedly: $($oldQuay.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $oldQuayScenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/old_quay/background/old_quay_blockout_bg.png"'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Old Quay room scene does not reference the active blockout background: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or
    $sceneText.Contains('path="res://game/rooms/old_quay/background/old_quay_blockout_bg.png"')) {
    throw "Old Quay room scene still uses the gradient background instead of the blockout PNG."
}

$exits = @($oldQuay.exits)
foreach ($requiredExit in @("ToSaltMarket", "ToMudflats")) {
    if ($requiredExit -notin @($exits | ForEach-Object { $_.name })) {
        throw "Old Quay blockout contract is missing exit: $requiredExit"
    }
}

$hotspots = @($oldQuay.hotspots)
foreach ($requiredHotspot in @("Tomas", "Flask", "RopeCleat")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Old Quay blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Old Quay blockout must not introduce a duel hotspot or confession-spend interface."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "old_quay" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Old Quay blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "old_quay" })
if ($paletteRows.Count -ne 1) {
    throw "Old Quay palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Old Quay palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Old Quay G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Old Quay export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Old Quay blockout validation passed: blend=present, export=present, godot=present, inGamut=$($paletteRow.in_gamut_percent)%"
