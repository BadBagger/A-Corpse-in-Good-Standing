param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\fish_hall\room_fish_hall.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$hall = @($manifest.rooms | Where-Object { $_.room_id -eq "fish_hall" })[0]
if ($null -eq $hall) {
    throw "Fish Hall room is missing from the Act I background manifest."
}

foreach ($relativePath in @($hall.source_blend, $hall.export_png, $hall.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Fish Hall blockout is missing expected asset: $relativePath. Run tools\Render-FishHallBlockout.ps1."
    }
}

if ($hall.export_png -ne "art/export/backgrounds/act_i/fish_hall_bg.png") {
    throw "Fish Hall export path changed unexpectedly: $($hall.export_png)"
}
if ($hall.godot_background_resource -ne "game/rooms/fish_hall/background/fish_hall_bg.png") {
    throw "Fish Hall Godot background path changed unexpectedly: $($hall.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/fish_hall/background/fish_hall_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Fish Hall room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Fish Hall scene must not use the gradient placeholder or introduce a duel."
}
if ($sceneText.Contains('confessions_spend = Array[String](["')) {
    throw "Fish Hall must not add a second confession-spend interface."
}

$exitNames = @($hall.exits | ForEach-Object { $_.name })
if ("ToSaltMarket" -notin $exitNames) {
    throw "Fish Hall blockout contract is missing exit: ToSaltMarket"
}

$hotspots = @($hall.hotspots)
foreach ($requiredHotspot in @("IceTable", "CoronerTag", "VisitorBook", "Drain")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Fish Hall blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Fish Hall blockout must not introduce a duel hotspot or confession-spend interface."
}

$iceTable = @($hotspots | Where-Object { $_.name -eq "IceTable" })[0]
if ($null -eq $iceTable -or "FL_body_fit_confirmed" -notin @($iceTable.sets_flags) -or $iceTable.ink_knot -ne "fish_hall_ice_table") {
    throw "Fish Hall ice-table body-fit contract changed."
}

$tag = @($hotspots | Where-Object { $_.name -eq "CoronerTag" })[0]
if (
    $null -eq $tag -or
    "IT_coroner_tag" -notin @($tag.rewards_items) -or
    "FL_day_count_proven" -notin @($tag.sets_flags) -or
    "FL_knows_daycount" -notin @($tag.sets_flags) -or
    $tag.ink_knot -ne "fish_hall_coroner_tag"
) {
    throw "Fish Hall coroner-tag day-count contract changed."
}

$book = @($hotspots | Where-Object { $_.name -eq "VisitorBook" })[0]
if (
    $null -eq $book -or
    "FL_sabine_absent_from_book" -notin @($book.sets_flags) -or
    "cf_pride_twice" -notin @($book.confessions_discover) -or
    $book.ink_knot -ne "fish_hall_visitor_book"
) {
    throw "Fish Hall visitor-book proof/confession contract changed."
}

$drain = @($hotspots | Where-Object { $_.name -eq "Drain" })[0]
if (
    $null -eq $drain -or
    "wet_verb" -notin @($drain.critical_roles) -or
    $drain.wet_ink_knot -ne "fish_hall_drain"
) {
    throw "Fish Hall drain wet-verb contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "fish_hall" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Fish Hall blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "fish_hall" })
if ($paletteRows.Count -ne 1) {
    throw "Fish Hall palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Fish Hall palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Fish Hall G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Fish Hall export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Fish Hall blockout validation passed: blend=present, export=present, godot=present, exits=1, inGamut=$($paletteRow.in_gamut_percent)%, dayCountProof=true, drainWetVerb=true"
