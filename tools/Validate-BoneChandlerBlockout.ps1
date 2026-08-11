param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\bone_chandler\room_bone_chandler.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$chandler = @($manifest.rooms | Where-Object { $_.room_id -eq "bone_chandler" })[0]
if ($null -eq $chandler) {
    throw "Bone Chandler room is missing from the Act I background manifest."
}

foreach ($relativePath in @($chandler.source_blend, $chandler.export_png, $chandler.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Bone Chandler blockout is missing expected asset: $relativePath. Run tools\Render-BoneChandlerBlockout.ps1."
    }
}

if ($chandler.export_png -ne "art/export/backgrounds/act_i/bone_chandler_bg.png") {
    throw "Bone Chandler export path changed unexpectedly: $($chandler.export_png)"
}
if ($chandler.godot_background_resource -ne "game/rooms/bone_chandler/background/bone_chandler_bg.png") {
    throw "Bone Chandler Godot background path changed unexpectedly: $($chandler.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/bone_chandler/background/bone_chandler_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Bone Chandler room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Bone Chandler scene must not use the gradient placeholder or introduce a duel."
}
if ($sceneText.Contains('confessions_spend = Array[String](["')) {
    throw "Bone Chandler must not add a second confession-spend interface."
}
if ($sceneText.Contains('cf_cruel_names') -or $sceneText.Contains('cf_greed_ring')) {
    throw "Bone Chandler must not grant deferred Act II confession content in Act I."
}

$exitNames = @($chandler.exits | ForEach-Object { $_.name })
foreach ($requiredExit in @("ToSaltMarket", "ToAlmshouse")) {
    if ($requiredExit -notin $exitNames) {
        throw "Bone Chandler blockout contract is missing exit: $requiredExit"
    }
}

$hotspots = @($chandler.hotspots)
foreach ($requiredHotspot in @("Wares", "ChessSet", "ProsperWatch")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Bone Chandler blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Bone Chandler blockout must not introduce a duel hotspot or confession-spend interface."
}

$wares = @($hotspots | Where-Object { $_.name -eq "Wares" })[0]
if ($null -eq $wares -or "FL_chandler_wares_seen" -notin @($wares.sets_flags) -or $wares.ink_knot -ne "chandler_wares") {
    throw "Bone Chandler wares staging contract changed."
}

$chess = @($hotspots | Where-Object { $_.name -eq "ChessSet" })[0]
if ($null -eq $chess -or "FL_chandler_chess_seen" -notin @($chess.sets_flags) -or $chess.ink_knot -ne "chandler_chess_set") {
    throw "Bone Chandler chess-set staging contract changed."
}

$watch = @($hotspots | Where-Object { $_.name -eq "ProsperWatch" })[0]
if (
    $null -eq $watch -or
    "IT_knuckle_salt" -notin @($watch.requires_items) -or
    "IT_watch" -notin @($watch.rewards_items) -or
    "FL_watch_recovered" -notin @($watch.sets_flags) -or
    $watch.ink_knot -ne "chandler_watch_trade" -or
    $watch.blocked_ink_knot -ne "chandler_needs_salt"
) {
    throw "Bone Chandler Prosper watch gate contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "bone_chandler" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Bone Chandler blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "bone_chandler" })
if ($paletteRows.Count -ne 1) {
    throw "Bone Chandler palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Bone Chandler palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Bone Chandler G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Bone Chandler export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}
if ([int64]$paletteRow.arterial_red_pixels -ne 0) {
    throw "Bone Chandler must not use arterial red in this blockout pass."
}

Write-Host "Bone Chandler blockout validation passed: blend=present, export=present, godot=present, exits=2, inGamut=$($paletteRow.in_gamut_percent)%, watchGate=freshSalt, noRed=true"
