$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$hotspotMapPath = Join-Path $root "docs\art\act_i_hotspot_map.csv"
$htmlPath = Join-Path $root "docs\art\act_i_review_contact_sheet.html"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing Act I background manifest: $manifestPath"
}
if (-not (Test-Path -LiteralPath $hotspotMapPath)) {
    throw "Missing Act I hotspot map: $hotspotMapPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$hotspotRows = @(Import-Csv -LiteralPath $hotspotMapPath)
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

function ConvertTo-HtmlText {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) {
        return ""
    }
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function ConvertTo-RelativeWebPath {
    param([Parameter(Mandatory=$true)][string]$ProjectRelativePath)
    return "../../" + ($ProjectRelativePath -replace "\\", "/")
}

$rooms = @($manifest.rooms)
if ($rooms.Count -ne 11) {
    throw "Act I contact sheet expected 11 manifest rooms, got $($rooms.Count)."
}

$lines = @(
    "<!doctype html>",
    "<html lang=`"en`">",
    "<head>",
    "  <meta charset=`"utf-8`">",
    "  <meta name=`"viewport`" content=`"width=device-width, initial-scale=1`">",
    "  <title>Act I Review Contact Sheet</title>",
    "  <style>",
    "    :root { --paper: #E4DCC8; --black: #0C1013; --slate: #2A3A40; --green: #7D9B4E; --amber: #C98A3C; --red: #8E1B22; }",
    "    * { box-sizing: border-box; }",
    "    body { margin: 0; font-family: Arial, sans-serif; background: var(--black); color: var(--paper); }",
    "    header, main { width: min(1440px, calc(100vw - 32px)); margin: 0 auto; }",
    "    header { padding: 24px 0 12px; }",
    "    h1 { margin: 0 0 8px; font-size: 28px; font-weight: 700; letter-spacing: 0; }",
    "    h2 { margin: 0 0 12px; font-size: 20px; letter-spacing: 0; }",
    "    p { line-height: 1.45; max-width: 960px; }",
    "    code { color: var(--amber); }",
    "    .locks { display: grid; gap: 6px; padding: 12px 0 4px; }",
    "    .room-card { border-top: 1px solid rgba(228, 220, 200, 0.28); padding: 24px 0; }",
    "    .frame { position: relative; width: 100%; aspect-ratio: 16 / 9; background: #111; overflow: hidden; border: 1px solid rgba(228, 220, 200, 0.24); }",
    "    .frame img { width: 100%; height: 100%; display: block; object-fit: contain; }",
    "    .walk-band { position: absolute; left: 0; right: 0; background: rgba(201, 138, 60, 0.20); border-top: 2px solid rgba(201, 138, 60, 0.85); border-bottom: 2px solid rgba(201, 138, 60, 0.85); pointer-events: none; }",
    "    .marker { position: absolute; width: 18px; height: 18px; margin-left: -9px; margin-top: -9px; border-radius: 999px; border: 2px solid var(--paper); background: var(--green); box-shadow: 0 0 0 3px rgba(12, 16, 19, 0.8); }",
    "    .marker.exit { background: var(--amber); }",
    "    .marker.risk { background: var(--red); }",
    "    .meta { margin: 8px 0 12px; color: rgba(228, 220, 200, 0.78); font-size: 14px; }",
    "    table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 14px; }",
    "    th, td { text-align: left; vertical-align: top; padding: 7px 8px; border-bottom: 1px solid rgba(228, 220, 200, 0.16); }",
    "    th { color: var(--amber); font-weight: 700; }",
    "    .muted { color: rgba(228, 220, 200, 0.64); }",
    "  </style>",
    "</head>",
    "<body>",
    "  <header>",
    "    <h1>Act I Review Contact Sheet</h1>",
    "    <p>Generated at UTC: $generatedAtUtc</p>",
    "    <p>Use this during Step 5 human review alongside <code>docs/playtest/results/act_i_human_playtest_latest.md</code> and <code>docs/playtest/act_i_review_decisions_template.csv</code>.</p>",
    "    <div class=`"locks`">",
    "      <div>Rule lock: keep the accepted Litany/Registrar duel format; do not add a second confession-spend UI.</div>",
    "      <div>Rule lock: Grey Float stays hard-R: steam, silhouette, privacy, and agency only.</div>",
    "      <div>Rule lock: this contact sheet is review evidence, not final paintover approval.</div>",
    "    </div>",
    "  </header>",
    "  <main>"
)

foreach ($room in $rooms) {
    $roomRows = @($hotspotRows | Where-Object { $_.room_id -eq $room.room_id })
    $imagePath = Join-Path $root ([string]$room.export_png -replace "/", "\")
    if (-not (Test-Path -LiteralPath $imagePath)) {
        throw "Act I contact sheet missing room export PNG: $($room.export_png)"
    }

    $walkTopPercent = ([double]$room.walk_band.y_min / [double]$room.stage.height) * 100
    $walkHeightPercent = (([double]$room.walk_band.y_max - [double]$room.walk_band.y_min) / [double]$room.stage.height) * 100
    $imageSrc = ConvertTo-RelativeWebPath -ProjectRelativePath ([string]$room.export_png)

    $lines += "    <section class=`"room-card`" id=`"room-$([System.Net.WebUtility]::HtmlEncode([string]$room.room_id))`">"
    $lines += "      <h2>$([System.Net.WebUtility]::HtmlEncode([string]$room.room_code)) $([System.Net.WebUtility]::HtmlEncode([string]$room.title))</h2>"
    $lines += "      <div class=`"meta`">Paintover source: <code>$([System.Net.WebUtility]::HtmlEncode([string]$room.paintover_source))</code> | Overlay anchor: <code>$([System.Net.WebUtility]::HtmlEncode([string]$room.review_overlay))</code></div>"
    $lines += "      <div class=`"frame`">"
    $lines += "        <img src=`"$imageSrc`" alt=`"$([System.Net.WebUtility]::HtmlEncode([string]$room.title)) blockout`">"
    $lines += "        <div class=`"walk-band`" title=`"Walk band`" style=`"top: $($walkTopPercent.ToString("0.###"))%; height: $($walkHeightPercent.ToString("0.###"))%;`"></div>"

    foreach ($row in $roomRows) {
        $xPercent = ([double]$row.x / [double]$room.stage.width) * 100
        $yPercent = ([double]$row.y / [double]$room.stage.height) * 100
        $roles = [string]$row.critical_roles
        $markerClass = if ($row.type -eq "exit") { "marker exit" } elseif ($roles -match "duel|hard_r|wet|confession|blocked") { "marker risk" } else { "marker" }
        $title = "{0}: {1} ({2}, {3}) roles={4}" -f $row.type, $row.label, $row.x, $row.y, $roles
        $lines += "        <span class=`"$markerClass`" style=`"left: $($xPercent.ToString("0.###"))%; top: $($yPercent.ToString("0.###"))%;`" title=`"$([System.Net.WebUtility]::HtmlEncode($title))`"></span>"
    }

    $lines += "      </div>"
    $lines += "      <table>"
    $lines += "        <thead><tr><th>Type</th><th>Name</th><th>Point</th><th>Roles</th><th>Requires</th><th>Rewards</th><th>Ink</th></tr></thead>"
    $lines += "        <tbody>"
    foreach ($row in $roomRows) {
        $requires = @($row.requires_items, $row.requires_flags | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " / "
        $rewards = @($row.items_add, $row.flags_set, $row.confessions_discover | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " / "
        $ink = @($row.ink_knot, $row.wet_ink_knot, $row.blocked_ink_knot, $row.duel_opponent | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join " / "
        $lines += "          <tr><td>$(ConvertTo-HtmlText $row.type)</td><td>$(ConvertTo-HtmlText $row.label)</td><td>$(ConvertTo-HtmlText "$($row.x), $($row.y)")</td><td>$(ConvertTo-HtmlText $row.critical_roles)</td><td>$(ConvertTo-HtmlText $requires)</td><td>$(ConvertTo-HtmlText $rewards)</td><td>$(ConvertTo-HtmlText $ink)</td></tr>"
    }
    $lines += "        </tbody>"
    $lines += "      </table>"
    $lines += "    </section>"
}

$lines += @(
    "  </main>",
    "</body>",
    "</html>"
)

Set-Content -LiteralPath $htmlPath -Value $lines -Encoding UTF8
Write-Host "Exported Act I review contact sheet -> $htmlPath"
Write-Host "Act I review contact sheet: rooms=$($rooms.Count), markers=$($hotspotRows.Count)"
