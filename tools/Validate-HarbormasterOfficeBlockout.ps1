param(
    [switch]$SkipSharedValidation
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$assetCsvPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteCsvPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$scenePath = Join-Path $root "game\rooms\harbormaster_office\room_harbormaster_office.tscn"

if (-not $SkipSharedValidation) {
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundManifest.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundAssetStatus.ps1")
    powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Validate-ActIBackgroundPaletteAudit.ps1")
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$office = @($manifest.rooms | Where-Object { $_.room_id -eq "harbormaster_office" })[0]
if ($null -eq $office) {
    throw "Harbormaster Office room is missing from the Act I background manifest."
}

foreach ($relativePath in @($office.source_blend, $office.export_png, $office.godot_background_resource)) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Harbormaster Office blockout is missing expected asset: $relativePath. Run tools\Render-HarbormasterOfficeBlockout.ps1."
    }
}

if ($office.export_png -ne "art/export/backgrounds/act_i/harbormaster_office_bg.png") {
    throw "Harbormaster Office export path changed unexpectedly: $($office.export_png)"
}
if ($office.godot_background_resource -ne "game/rooms/harbormaster_office/background/harbormaster_office_bg.png") {
    throw "Harbormaster Office Godot background path changed unexpectedly: $($office.godot_background_resource)"
}

$sceneText = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredSceneText in @(
    'path="res://game/rooms/background_image_loader.gd"',
    'background_path = "res://game/rooms/harbormaster_office/background/harbormaster_office_bg.png"',
    'confessions_spend = Array[String]([])'
)) {
    if (-not $sceneText.Contains($requiredSceneText)) {
        throw "Harbormaster Office room scene is missing required integration text: $requiredSceneText"
    }
}
if ($sceneText.Contains('texture = SubResource("GradientTexture2D_bg")') -or $sceneText.Contains('duel_opponent = "registrar"')) {
    throw "Harbormaster Office scene must not use the gradient placeholder or introduce a duel."
}
if ($sceneText.Contains('confessions_spend = Array[String](["')) {
    throw "Harbormaster Office must not add a second confession-spend interface."
}

$exitNames = @($office.exits | ForEach-Object { $_.name })
foreach ($requiredExit in @("ToGreyFloat", "ToSabine")) {
    if ($requiredExit -notin $exitNames) {
        throw "Harbormaster Office blockout contract is missing exit: $requiredExit"
    }
}

$sabineExit = @($office.exits | Where-Object { $_.name -eq "ToSabine" })[0]
foreach ($requiredFlag in @("FL_rite_name", "FL_rite_debt", "FL_rite_heartbeat")) {
    if ($requiredFlag -notin @($sabineExit.requires_flags)) {
        throw "Harbormaster Office Sabine exit is missing required Rite flag: $requiredFlag"
    }
}

$hotspots = @($office.hotspots)
foreach ($requiredHotspot in @("ChecklistDesk", "ChecklistClerk", "SabineDoor")) {
    if ($requiredHotspot -notin @($hotspots | ForEach-Object { $_.name })) {
        throw "Harbormaster Office blockout contract is missing critical hotspot: $requiredHotspot"
    }
}

$duelHotspots = @($hotspots | Where-Object { $_.type -eq "duel" -or -not [string]::IsNullOrWhiteSpace($_.duel_opponent) })
if ($duelHotspots.Count -ne 0) {
    throw "Harbormaster Office blockout must not introduce a duel hotspot or confession-spend interface."
}

$desk = @($hotspots | Where-Object { $_.name -eq "ChecklistDesk" })[0]
if ($null -eq $desk -or "FL_harbormaster_checklist_seen" -notin @($desk.sets_flags) -or $desk.ink_knot -ne "harbormaster_checklist_desk") {
    throw "Harbormaster Office checklist-desk staging contract changed."
}

$door = @($hotspots | Where-Object { $_.name -eq "SabineDoor" })[0]
if ($null -eq $door -or "FL_harbormaster_sabine_door_seen" -notin @($door.sets_flags) -or $door.ink_knot -ne "harbormaster_sabine_door") {
    throw "Harbormaster Office Sabine-door staging contract changed."
}

$clerk = @($hotspots | Where-Object { $_.name -eq "ChecklistClerk" })[0]
if (
    $null -eq $clerk -or
    "IT_regulator" -notin @($clerk.requires_items) -or
    "FL_float_warmth_active" -notin @($clerk.requires_flags) -or
    "FL_rite_heartbeat" -notin @($clerk.sets_flags) -or
    $clerk.ink_knot -ne "heartbeat_check_pass" -or
    $clerk.blocked_ink_knot -ne "heartbeat_check_fail"
) {
    throw "Harbormaster Office checklist clerk heartbeat gate contract changed."
}

$assetRows = @(Import-Csv -LiteralPath $assetCsvPath | Where-Object { $_.room_id -eq "harbormaster_office" })
$presentRows = @($assetRows | Where-Object { $_.status -eq "present" })
foreach ($requiredKind in @("blend_blockout", "export_png", "godot_import")) {
    $row = @($presentRows | Where-Object { $_.asset_kind -eq $requiredKind })[0]
    if ($null -eq $row) {
        throw "Harbormaster Office blockout asset status does not show present $requiredKind."
    }
}

$paletteRows = @(Import-Csv -LiteralPath $paletteCsvPath | Where-Object { $_.room_id -eq "harbormaster_office" })
if ($paletteRows.Count -ne 1) {
    throw "Harbormaster Office palette audit row count mismatch: $($paletteRows.Count)"
}
$paletteRow = $paletteRows[0]
if ($paletteRow.status -ne "audited" -or $paletteRow.pass -ne "True") {
    throw "Harbormaster Office palette audit must be audited and passing."
}
if ([double]$paletteRow.in_gamut_percent -lt 98.0) {
    throw "Harbormaster Office G9 palette audit below threshold: $($paletteRow.in_gamut_percent)%"
}
if ($paletteRow.width -ne "1920" -or $paletteRow.height -ne "1080") {
    throw "Harbormaster Office export resolution mismatch: $($paletteRow.width)x$($paletteRow.height)"
}

Write-Host "Harbormaster Office blockout validation passed: blend=present, export=present, godot=present, exits=2, inGamut=$($paletteRow.in_gamut_percent)%, heartbeatGate=true, sabineGate=threeRites"
