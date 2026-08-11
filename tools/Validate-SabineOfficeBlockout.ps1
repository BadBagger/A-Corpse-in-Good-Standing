param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\sabine_office\room_sabine_office.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$office = @($manifest.rooms | Where-Object { $_.room_id -eq "sabine_office" })[0]
if ($null -eq $office) {
    throw "Sabine Office room is missing from the Act I background manifest."
}

foreach ($relativePath in @($office.source_blend, $office.export_png, $office.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Sabine Office blockout is missing expected asset: $relativePath. Run tools\Render-SabineOfficeBlockout.ps1."
    }
}

if ($office.export_png -ne "art/export/backgrounds/act_i/sabine_office_bg.png") {
    throw "Sabine Office export path changed unexpectedly: $($office.export_png)"
}
if ($office.godot_background_resource -ne "game/rooms/sabine_office/background/sabine_office_bg.png") {
    throw "Sabine Office Godot background path changed unexpectedly: $($office.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/sabine_office/background/sabine_office_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Sabine Office room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Sabine Office scene must not use the gradient placeholder or introduce a duel."
}
if ($sceneText.Contains('confessions_spend = Array[String](["')) {
    throw "Sabine Office must not add a second confession-spend interface."
}

$exitNames = @($office.exits | ForEach-Object { $_.name })
if ("ToHarbormaster" -notin $exitNames) {
    throw "Sabine Office blockout contract is missing exit: ToHarbormaster"
}

$hotspots = @($office.hotspots)
if ("SabineDesk" -notin @($hotspots | ForEach-Object { $_.name })) {
    throw "Sabine Office blockout contract is missing critical hotspot: SabineDesk"
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Sabine Office blockout must not introduce a duel hotspot or confession-spend interface."
}

$desk = @($hotspots | Where-Object { $_.name -eq "SabineDesk" })[0]
foreach ($requiredFlag in @("FL_rite_name", "FL_rite_debt", "FL_rite_heartbeat")) {
    if ($requiredFlag -notin @($desk.requires_flags)) {
        throw "Sabine Office desk gate is missing required Rite flag: $requiredFlag"
    }
}
if (
    $null -eq $desk -or
    "gated" -notin @($desk.critical_roles) -or
    "FL_act_i_complete" -notin @($desk.sets_flags) -or
    $desk.ink_knot -ne "sabine_act_i_audience"
) {
    throw "Sabine Office Act I audience gate contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "sabine_office" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Sabine Office blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "sabine_office" })
if ($paletteRows.Count -ne 1) {
    throw "Sabine Office palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Sabine Office palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Sabine Office G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Sabine Office export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Sabine Office blockout validation passed: blend=present, export=present, godot=present, exits=1, inGamut=$($paletteRow.in_gamut_percent)%, actIGate=threeRites, noApologyStaging=true"
