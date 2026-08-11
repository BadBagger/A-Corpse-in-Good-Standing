param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\salt_market\room_salt_market.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$market = @($manifest.rooms | Where-Object { $_.room_id -eq "salt_market" })[0]
if ($null -eq $market) {
    throw "Salt Market room is missing from the Act I background manifest."
}

foreach ($relativePath in @($market.source_blend, $market.export_png, $market.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Salt Market blockout is missing expected asset: $relativePath. Run tools\Render-SaltMarketBlockout.ps1."
    }
}

if ($market.export_png -ne "art/export/backgrounds/act_i/salt_market_bg.png") {
    throw "Salt Market export path changed unexpectedly: $($market.export_png)"
}
if ($market.godot_background_resource -ne "game/rooms/salt_market/background/salt_market_bg.png") {
    throw "Salt Market Godot background path changed unexpectedly: $($market.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/salt_market/background/salt_market_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Salt Market room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Salt Market scene must not use the gradient placeholder or introduce a duel."
}

$exitNames = @($market.exits | ForEach-Object { $_.name })
foreach ($requiredExit in @("ToOldQuay", "ToRegistry", "ToChandler", "ToAlmshouse", "ToFishHall", "ToChurch")) {
    if ($requiredExit -notin $exitNames) {
        throw "Salt Market blockout contract is missing hub exit: $requiredExit"
    }
}

$hotspots = @($market.hotspots)
foreach ($requiredHotspot in @("MarketCrowd", "BootStall", "Fishmonger", "ConfessionQueue", "ChurchSign", "WhaleOilLamp")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Salt Market blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Salt Market blockout must not introduce a duel hotspot or confession-spend interface."
}

$churchSign = @($hotspots | Where-Object { $_.name -eq "ChurchSign" })[0]
if ($null -eq $churchSign -or $churchSign.wet_ink_knot -ne "salt_market_church_sign_wet") {
    throw "Salt Market Church sign wet-verb contract changed."
}

$crowd = @($hotspots | Where-Object { $_.name -eq "MarketCrowd" })[0]
if ($null -eq $crowd -or "BorrowedBoots" -notin @($crowd.rewards_items) -or "cf_pride_voice" -notin @($crowd.confessions_discover)) {
    throw "Salt Market crowd reward/confession contract changed."
}

$fishmonger = @($hotspots | Where-Object { $_.name -eq "Fishmonger" })[0]
if ($null -eq $fishmonger -or "cf_greed_scales" -notin @($fishmonger.confessions_discover) -or "cf_cow_drink" -notin @($fishmonger.confessions_discover)) {
    throw "Salt Market fishmonger confession-source contract changed."
}

$queue = @($hotspots | Where-Object { $_.name -eq "ConfessionQueue" })[0]
if ($null -eq $queue -or "cf_cruel_funeral" -notin @($queue.confessions_discover)) {
    throw "Salt Market confession queue contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "salt_market" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Salt Market blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "salt_market" })
if ($paletteRows.Count -ne 1) {
    throw "Salt Market palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Salt Market palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Salt Market G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Salt Market export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Salt Market blockout validation passed: blend=present, export=present, godot=present, exits=6, inGamut=$($paletteRow.in_gamut_percent)%"
