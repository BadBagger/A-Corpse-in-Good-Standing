param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\grey_float\room_grey_float.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$float = @($manifest.rooms | Where-Object { $_.room_id -eq "grey_float" })[0]
if ($null -eq $float) {
    throw "Grey Float room is missing from the Act I background manifest."
}

foreach ($relativePath in @($float.source_blend, $float.export_png, $float.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Grey Float blockout is missing expected asset: $relativePath. Run tools\Render-GreyFloatBlockout.ps1."
    }
}

if ($float.export_png -ne "art/export/backgrounds/act_i/grey_float_bg.png") {
    throw "Grey Float export path changed unexpectedly: $($float.export_png)"
}
if ($float.godot_background_resource -ne "game/rooms/grey_float/background/grey_float_bg.png") {
    throw "Grey Float Godot background path changed unexpectedly: $($float.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/grey_float/background/grey_float_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Grey Float room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Grey Float scene must not use the gradient placeholder or introduce a duel."
}
if ($sceneText.Contains('confessions_spend = Array[String](["')) {
    throw "Grey Float must not add a second confession-spend interface."
}

$exitNames = @($float.exits | ForEach-Object { $_.name })
foreach ($requiredExit in @("ToChurch", "ToHarbormaster")) {
    if ($requiredExit -notin $exitNames) {
        throw "Grey Float blockout contract is missing exit: $requiredExit"
    }
}

$hotspots = @($float.hotspots)
foreach ($requiredHotspot in @("JunoTable", "SteamScreen", "BilgeRegulator", "StaffCorner", "HotPool")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Grey Float blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Grey Float blockout must not introduce a duel hotspot or confession-spend interface."
}

$juno = @($hotspots | Where-Object { $_.name -eq "JunoTable" })[0]
if ($null -eq $juno -or "FL_float_juno_table_seen" -notin @($juno.sets_flags) -or $juno.ink_knot -ne "float_juno_table") {
    throw "Grey Float Juno table staging contract changed."
}

$steam = @($hotspots | Where-Object { $_.name -eq "SteamScreen" })[0]
if ($null -eq $steam -or "FL_float_steam_seen" -notin @($steam.sets_flags) -or $steam.ink_knot -ne "float_steam_screen") {
    throw "Grey Float steam-screen hard-R staging contract changed."
}

$regulator = @($hotspots | Where-Object { $_.name -eq "BilgeRegulator" })[0]
if (
    $null -eq $regulator -or
    "IT_rate_card" -notin @($regulator.requires_items) -or
    "IT_regulator" -notin @($regulator.rewards_items) -or
    "FL_juno_met" -notin @($regulator.sets_flags) -or
    "FL_regulator_acquired" -notin @($regulator.sets_flags) -or
    $regulator.blocked_ink_knot -ne "juno_needs_rate_card"
) {
    throw "Grey Float bilge regulator gate contract changed."
}

$staff = @($hotspots | Where-Object { $_.name -eq "StaffCorner" })[0]
if ($null -eq $staff -or "cf_lust_float" -notin @($staff.confessions_discover) -or "cf_cow_apologize" -notin @($staff.confessions_discover)) {
    throw "Grey Float staff-corner confession-source contract changed."
}

$pool = @($hotspots | Where-Object { $_.name -eq "HotPool" })[0]
if (
    $null -eq $pool -or
    "FL_juno_met" -notin @($pool.requires_flags) -or
    "FL_float_warmth_active" -notin @($pool.sets_flags) -or
    $pool.blocked_ink_knot -ne "juno_pool_before_permission" -or
    $pool.ink_knot -ne "juno_hot_pool_soak"
) {
    throw "Grey Float hot-pool warmth gate contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "grey_float" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Grey Float blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "grey_float" })
if ($paletteRows.Count -ne 1) {
    throw "Grey Float palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Grey Float palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Grey Float G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Grey Float export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Grey Float blockout validation passed: blend=present, export=present, godot=present, exits=2, inGamut=$($paletteRow.in_gamut_percent)%, hardRStaging=true, noSecondDuel=true"
