param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\church_of_the_drowned\room_church_of_the_drowned.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$church = @($manifest.rooms | Where-Object { $_.room_id -eq "church_of_the_drowned" })[0]
if ($null -eq $church) {
    throw "Church of the Drowned room is missing from the Act I background manifest."
}

foreach ($relativePath in @($church.source_blend, $church.export_png, $church.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Church of the Drowned blockout is missing expected asset: $relativePath. Run tools\Render-ChurchOfTheDrownedBlockout.ps1."
    }
}

if ($church.export_png -ne "art/export/backgrounds/act_i/church_of_the_drowned_bg.png") {
    throw "Church of the Drowned export path changed unexpectedly: $($church.export_png)"
}
if ($church.godot_background_resource -ne "game/rooms/church_of_the_drowned/background/church_of_the_drowned_bg.png") {
    throw "Church of the Drowned Godot background path changed unexpectedly: $($church.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/church_of_the_drowned/background/church_of_the_drowned_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Church of the Drowned room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Church of the Drowned scene must not use the gradient placeholder or introduce a duel."
}
if ($sceneText.Contains('confessions_spend = Array[String](["')) {
    throw "Church of the Drowned must not add a second confession-spend interface."
}

$exitNames = @($church.exits | ForEach-Object { $_.name })
foreach ($requiredExit in @("ToSaltMarket", "ToGreyFloat")) {
    if ($requiredExit -notin $exitNames) {
        throw "Church of the Drowned blockout contract is missing exit: $requiredExit"
    }
}

$hotspots = @($church.hotspots)
foreach ($requiredHotspot in @("PoorBox", "ConfessionBooth", "ChurchStallSign", "RateCard")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Church of the Drowned blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Church of the Drowned blockout must not introduce a duel hotspot or confession-spend interface."
}

$poorBox = @($hotspots | Where-Object { $_.name -eq "PoorBox" })[0]
if ($null -eq $poorBox -or "cf_greed_plate" -notin @($poorBox.confessions_discover) -or $poorBox.ink_knot -ne "church_poor_box") {
    throw "Church poor-box confession-source contract changed."
}

$booth = @($hotspots | Where-Object { $_.name -eq "ConfessionBooth" })[0]
if ($null -eq $booth -or "IT_chit" -notin @($booth.rewards_items) -or "FL_chit_acquired" -notin @($booth.sets_flags)) {
    throw "Church confession booth chit contract changed."
}

$rateCard = @($hotspots | Where-Object { $_.name -eq "RateCard" })[0]
if (
    $null -eq $rateCard -or
    "IT_chit" -notin @($rateCard.requires_items) -or
    "IT_rate_card" -notin @($rateCard.rewards_items) -or
    "FL_kane_seen" -notin @($rateCard.sets_flags) -or
    "cf_cruel_sentences" -notin @($rateCard.confessions_discover) -or
    $rateCard.blocked_ink_knot -ne "teodor_needs_chit"
) {
    throw "Church Teodor rate-card gate contract changed."
}

$stallSign = @($hotspots | Where-Object { $_.name -eq "ChurchStallSign" })[0]
if ($null -eq $stallSign -or "FL_church_stall_sign_seen" -notin @($stallSign.sets_flags) -or $stallSign.ink_knot -ne "church_stall_sign") {
    throw "Church stall-sign staging contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "church_of_the_drowned" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Church of the Drowned blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "church_of_the_drowned" })
if ($paletteRows.Count -ne 1) {
    throw "Church of the Drowned palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Church of the Drowned palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Church of the Drowned G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Church of the Drowned export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Church of the Drowned blockout validation passed: blend=present, export=present, godot=present, exits=2, inGamut=$($paletteRow.in_gamut_percent)%, noSecondDuel=true"
