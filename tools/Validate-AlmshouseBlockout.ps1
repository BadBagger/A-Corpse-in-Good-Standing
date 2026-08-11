param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\almshouse\room_almshouse.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$almshouse = @($manifest.rooms | Where-Object { $_.room_id -eq "almshouse" })[0]
if ($null -eq $almshouse) {
    throw "Almshouse room is missing from the Act I background manifest."
}

foreach ($relativePath in @($almshouse.source_blend, $almshouse.export_png, $almshouse.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Almshouse blockout is missing expected asset: $relativePath. Run tools\Render-AlmshouseBlockout.ps1."
    }
}

if ($almshouse.export_png -ne "art/export/backgrounds/act_i/almshouse_bg.png") {
    throw "Almshouse export path changed unexpectedly: $($almshouse.export_png)"
}
if ($almshouse.godot_background_resource -ne "game/rooms/almshouse/background/almshouse_bg.png") {
    throw "Almshouse Godot background path changed unexpectedly: $($almshouse.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/almshouse/background/almshouse_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Almshouse room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Almshouse scene must not use the gradient placeholder or introduce a duel."
}
if ($sceneText.Contains('confessions_spend = Array[String](["')) {
    throw "Almshouse must not add a second confession-spend interface."
}
if ($sceneText.Contains('cf_greed_ring')) {
    throw "Almshouse must not grant deferred Act II confession content in Act I."
}

$exitNames = @($almshouse.exits | ForEach-Object { $_.name })
foreach ($requiredExit in @("ToBoneChandler", "ToSaltMarket")) {
    if ($requiredExit -notin $exitNames) {
        throw "Almshouse blockout contract is missing exit: $requiredExit"
    }
}

$hotspots = @($almshouse.hotspots)
foreach ($requiredHotspot in @("Cots", "Window", "HalfCoinProsper")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Almshouse blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Almshouse blockout must not introduce a duel hotspot or confession-spend interface."
}

$cots = @($hotspots | Where-Object { $_.name -eq "Cots" })[0]
if ($null -eq $cots -or "FL_almshouse_cots_seen" -notin @($cots.sets_flags) -or $cots.ink_knot -ne "almshouse_cots") {
    throw "Almshouse cots staging contract changed."
}

$window = @($hotspots | Where-Object { $_.name -eq "Window" })[0]
if ($null -eq $window -or "FL_almshouse_window_seen" -notin @($window.sets_flags) -or $window.ink_knot -ne "almshouse_window") {
    throw "Almshouse window staging contract changed."
}

$prosper = @($hotspots | Where-Object { $_.name -eq "HalfCoinProsper" })[0]
if (
    $null -eq $prosper -or
    "IT_watch" -notin @($prosper.requires_items) -or
    "IT_forgiveness" -notin @($prosper.rewards_items) -or
    "FL_rite_debt" -notin @($prosper.sets_flags) -or
    $prosper.ink_knot -ne "prosper_forgiveness" -or
    $prosper.blocked_ink_knot -ne "prosper_before_watch"
) {
    throw "Almshouse Half-Coin Prosper debt-forgiveness gate contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "almshouse" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Almshouse blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "almshouse" })
if ($paletteRows.Count -ne 1) {
    throw "Almshouse palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Almshouse palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Almshouse G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Almshouse export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Almshouse blockout validation passed: blend=present, export=present, godot=present, exits=2, inGamut=$($paletteRow.in_gamut_percent)%, debtGate=watchForForgiveness"
