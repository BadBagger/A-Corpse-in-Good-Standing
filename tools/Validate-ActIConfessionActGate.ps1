$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$confessionPath = Join-Path $root "data\confessions.json"
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$inkPath = Join-Path $root "ink\prologue.ink"
$roomsPath = Join-Path $root "game\rooms"

if (-not (Test-Path -LiteralPath $confessionPath)) {
    throw "Missing confession data: $confessionPath"
}
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing Act I background manifest: $manifestPath"
}

$confessions = Get-Content -LiteralPath $confessionPath -Raw | ConvertFrom-Json
$byId = @{}
foreach ($confession in $confessions) {
    $byId[$confession.id] = $confession
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$actIRoomIds = @($manifest.rooms | ForEach-Object { [string]$_.room_id })
if ($actIRoomIds.Count -ne 11) {
    throw "Act I confession act gate expected 11 Act I manifest rooms, got $($actIRoomIds.Count)."
}

$violations = New-Object System.Collections.Generic.List[string]

function Test-ConfessionId {
    param(
        [string] $Id,
        [string] $Source
    )

    if (-not $byId.ContainsKey($Id)) {
        $violations.Add("Unknown confession '$Id' referenced by $Source")
        return
    }

    $act = [int]$byId[$Id].act_available
    if ($act -gt 1) {
        $violations.Add("Act I source references Act $act confession '$Id' in $Source")
    }
}

foreach ($roomId in $actIRoomIds) {
    $scenePath = Join-Path $roomsPath "$roomId\room_$roomId.tscn"
    if (-not (Test-Path -LiteralPath $scenePath)) {
        throw "Act I confession act gate missing room scene: $scenePath"
    }
    $relative = $scenePath.Substring($root.Length + 1)
    $text = Get-Content -LiteralPath $scenePath -Raw
    [regex]::Matches($text, '(?:confessions_discover|wet_confessions_discover) = Array\[String\]\(\[([^\]]*)\]\)') | ForEach-Object {
        $rawList = $_.Groups[1].Value
        [regex]::Matches($rawList, '"([^"]+)"') | ForEach-Object {
            Test-ConfessionId -Id $_.Groups[1].Value -Source $relative
        }
    }
}

if (Test-Path -LiteralPath $inkPath) {
    $inkText = Get-Content -LiteralPath $inkPath -Raw
    [regex]::Matches($inkText, '#\s*confession:discover:([A-Za-z0-9_]+)') | ForEach-Object {
        Test-ConfessionId -Id $_.Groups[1].Value -Source "ink\prologue.ink"
    }
}

if ($violations.Count -gt 0) {
    $violations | ForEach-Object { Write-Error $_ }
    throw "Act I confession act gate failed: $($violations.Count) violation(s)."
}

Write-Host "Act I confession act gate passed: no Act II/III confessions are granted from Act I room scenes or prologue Ink tags."
