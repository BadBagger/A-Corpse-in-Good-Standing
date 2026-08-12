$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIReviewContactSheet.ps1"
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$hotspotMapPath = Join-Path $root "docs\art\act_i_hotspot_map.csv"
$htmlPath = Join-Path $root "docs\art\act_i_review_contact_sheet.html"
$lookTargetPath = Join-Path $root "docs\art\reference\look_targets\act_i_harbor_look_target_v1.png"
$lookTargetReportPath = Join-Path $root "docs\art\act_i_look_target_reference.md"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I review contact sheet exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I review contact sheet export failed."
}

if (-not (Test-Path -LiteralPath $htmlPath)) {
    throw "Missing generated Act I review contact sheet: $htmlPath"
}
foreach ($path in @($lookTargetPath, $lookTargetReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Act I contact sheet expected look-target artifact: $path"
    }
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$hotspotRows = @(Import-Csv -LiteralPath $hotspotMapPath)
$html = Get-Content -LiteralPath $htmlPath -Raw
$rooms = @($manifest.rooms)

if ($rooms.Count -ne 11) {
    throw "Act I contact sheet expected 11 rooms, got $($rooms.Count)."
}

$roomCardCount = ([regex]::Matches($html, "class=`"room-card`"")).Count
if ($roomCardCount -ne 11) {
    throw "Act I contact sheet expected 11 room cards, got $roomCardCount."
}

$markerCount = ([regex]::Matches($html, "class=`"marker")).Count
if ($markerCount -ne $hotspotRows.Count) {
    throw "Act I contact sheet expected $($hotspotRows.Count) markers, got $markerCount."
}

foreach ($room in $rooms) {
    foreach ($required in @([string]$room.room_code, [string]$room.title, [string]$room.paintover_source, [string]$room.review_overlay)) {
        $encodedRequired = [System.Net.WebUtility]::HtmlEncode($required)
        if ($html -notmatch [regex]::Escape($encodedRequired)) {
            throw "Act I contact sheet missing room text: $required"
        }
    }
    $imageSrc = "../../" + ([string]$room.export_png -replace "\\", "/")
    if ($html -notmatch [regex]::Escape($imageSrc)) {
        throw "Act I contact sheet missing image reference: $imageSrc"
    }
}

foreach ($requiredText in @(
    "Act I Review Contact Sheet",
    "Act I Look Target",
    "../../docs/art/reference/look_targets/act_i_harbor_look_target_v1.png",
    "docs/art/act_i_look_target_reference.md",
    "mood/readability target",
    "side-on Corvin read",
    "wet black coat silhouette",
    "amber/green lighting logic",
    "not final room art",
    "not hotspot authority",
    "not a Blender greybox replacement",
    "not a character sprite source",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/playtest/act_i_review_decisions_template.csv",
    "accepted Litany/Registrar duel format",
    "do not add a second confession-spend UI",
    "Grey Float stays hard-R",
    "steam, silhouette, privacy, and agency only",
    "review evidence, not final paintover approval",
    "Walk band"
)) {
    if ($html -notmatch [regex]::Escape($requiredText)) {
        throw "Act I contact sheet missing required text: $requiredText"
    }
}

foreach ($forbiddenText in @("System.Object[]", "@{", "Ã¯Â»Â¿", "`t", "	ools/")) {
    if ($html.Contains($forbiddenText)) {
        throw "Act I contact sheet contains malformed HTML: $forbiddenText"
    }
}
if ($html -match "[^\u0000-\u007F]") {
    throw "Act I contact sheet must stay ASCII-only."
}

Write-Host "Act I review contact sheet validation passed: rooms=$($rooms.Count), markers=$markerCount."
