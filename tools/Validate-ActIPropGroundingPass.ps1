$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_prop_grounding_pass.json"
$mdPath = Join-Path $root "docs\art\act_i_prop_grounding_pass.md"
$scriptPath = Join-Path $root "tools\Enhance-ActIOpenAIPropComposites.py"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_openai_prop_composite_contact_sheet.png"

foreach ($path in @($jsonPath, $mdPath, $scriptPath, $contactSheetPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I prop grounding artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "grounded") {
    throw "Act I prop grounding report must have status grounded."
}
if ([int]$report.room_count -ne 11) {
    throw "Act I prop grounding expected 11 rooms, got $($report.room_count)."
}
if ([int]$report.prop_count -lt 40) {
    throw "Act I prop grounding expected at least 40 grounded props, got $($report.prop_count)."
}

$rooms = @($report.rooms)
$requiredRooms = @(
    "mudflats",
    "old_quay",
    "salt_market",
    "harbor_registry",
    "bone_chandler",
    "almshouse",
    "fish_hall",
    "church_of_the_drowned",
    "grey_float",
    "harbormaster_office",
    "sabine_office"
)
$seen = @{}
foreach ($room in $rooms) {
    $roomId = [string]$room.room_id
    if ($roomId -notin $requiredRooms) {
        throw "Unexpected Act I prop grounding room: $roomId"
    }
    if ($seen.ContainsKey($roomId)) {
        throw "Duplicate Act I prop grounding room: $roomId"
    }
    $seen[$roomId] = $true
    $outputPath = Join-Path $root ([string]$room.output -replace "/", "\")
    if (-not (Test-Path -LiteralPath $outputPath)) {
        throw "Missing grounded composite PNG for room $roomId`: $($room.output)"
    }
    if ([int]$room.prop_count -lt 1) {
        throw "Room $roomId must include at least one grounded prop."
    }
    foreach ($prop in @($room.props)) {
        if ([string]$prop.grounding -ne "contact_shadow_and_wet_reflection") {
            throw "Prop $($prop.id) in $roomId missing contact shadow and wet reflection grounding."
        }
    }
}
foreach ($roomId in $requiredRooms) {
    if (-not $seen.ContainsKey($roomId)) {
        throw "Missing Act I prop grounding room: $roomId"
    }
}

$script = Get-Content -LiteralPath $scriptPath -Raw
foreach ($requiredText in @("def contact_shadow", "def reflection", "contact_shadow_and_wet_reflection")) {
    if (-not $script.Contains($requiredText)) {
        throw "Act I prop grounding script missing required text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @("Act I Prop Grounding Pass", "contact shadows", "wet-floor reflections")) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I prop grounding report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I prop grounding report must stay ASCII-only."
}

Write-Host "Act I prop grounding validation passed: rooms=$($rooms.Count), props=$($report.prop_count)."
