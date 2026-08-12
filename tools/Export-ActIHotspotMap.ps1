$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$roomsRoot = Join-Path $root "game\rooms"
$manifestPath = Join-Path $root "docs\art\act_i_background_manifest.json"
$outDir = Join-Path $root "docs\art"
$outPath = Join-Path $outDir "act_i_hotspot_map.csv"

if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing Act I background manifest: $manifestPath"
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Get-QuotedValue {
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string[]]$Lines,
        [Parameter(Mandatory=$true)]
        [int]$Start,
        [Parameter(Mandatory=$true)]
        [string]$Key
    )

    for ($i = $Start; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\[node ') {
            if ($i -ne $Start) { break }
        }
        if ($Lines[$i] -match "^$([regex]::Escape($Key))\s*=\s*`"([^`"]*)`"") {
            return $Matches[1]
        }
    }
    return ""
}

function Get-ArrayValue {
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string[]]$Lines,
        [Parameter(Mandatory=$true)]
        [int]$Start,
        [Parameter(Mandatory=$true)]
        [string]$Key
    )

    for ($i = $Start; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\[node ') {
            if ($i -ne $Start) { break }
        }
        if ($Lines[$i] -match "^$([regex]::Escape($Key))\s*=\s*Array\[String\]\(\[(.*)\]\)") {
            $raw = $Matches[1].Trim()
            if ([string]::IsNullOrWhiteSpace($raw)) {
                return ""
            }
            $items = [regex]::Matches($raw, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value }
            return ($items -join "|")
        }
    }
    return ""
}

function Get-Position {
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string[]]$Lines,
        [Parameter(Mandatory=$true)]
        [int]$Start
    )

    for ($i = $Start; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\[node ') {
            if ($i -ne $Start) { break }
        }
        if ($Lines[$i] -match '^position\s*=\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)') {
            return @{ X = [double]$Matches[1]; Y = [double]$Matches[2] }
        }
    }
    return @{ X = $null; Y = $null }
}

$rows = New-Object System.Collections.Generic.List[object]
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$actIRoomIds = @($manifest.rooms | ForEach-Object { [string]$_.room_id })
if ($actIRoomIds.Count -ne 11) {
    throw "Act I hotspot map expected 11 Act I manifest rooms, got $($actIRoomIds.Count)."
}
$roomMetadataFallback = @{
    mudflats = @{ Code = "R01"; Title = "Mudflats" }
}

Get-ChildItem -LiteralPath $roomsRoot -Recurse -Filter "room_*.tscn" | Sort-Object FullName | ForEach-Object {
    $scenePath = $_.FullName
    $lines = @(Get-Content -LiteralPath $scenePath)
    if ($lines.Count -eq 0) {
        return
    }
    $roomId = Split-Path -Leaf (Split-Path -Parent $scenePath)
    if ($roomId -notin $actIRoomIds) {
        return
    }
    $roomCode = ""
    $roomTitle = ""

    foreach ($line in $lines) {
        if ($line -match '^room_code\s*=\s*"([^"]*)"') { $roomCode = $Matches[1] }
        if ($line -match '^room_title\s*=\s*"([^"]*)"') { $roomTitle = $Matches[1] }
    }

    if ($roomMetadataFallback.ContainsKey($roomId)) {
        if ([string]::IsNullOrWhiteSpace($roomCode)) {
            $roomCode = $roomMetadataFallback[$roomId].Code
        }
        if ([string]::IsNullOrWhiteSpace($roomTitle)) {
            $roomTitle = $roomMetadataFallback[$roomId].Title
        }
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch '^\[node name="([^"]+)" type="Area2D" parent="Hotspots"\]') {
            continue
        }

        $name = $Matches[1]
        $position = Get-Position -Lines $lines -Start $i
        $description = Get-QuotedValue -Lines $lines -Start $i -Key "description"
        $interactionKey = Get-QuotedValue -Lines $lines -Start $i -Key "interaction_key"
        $targetRoom = Get-QuotedValue -Lines $lines -Start $i -Key "target_room"
        $inkKnot = Get-QuotedValue -Lines $lines -Start $i -Key "ink_knot"
        $wetInkKnot = Get-QuotedValue -Lines $lines -Start $i -Key "wet_ink_knot"
        $blockedInkKnot = Get-QuotedValue -Lines $lines -Start $i -Key "blocked_ink_knot"
        $alternateRequiresFlags = Get-ArrayValue -Lines $lines -Start $i -Key "alternate_requires_flags"
        $alternateFlagsSet = Get-ArrayValue -Lines $lines -Start $i -Key "alternate_flags_set"
        $alternateInkKnot = Get-QuotedValue -Lines $lines -Start $i -Key "alternate_ink_knot"
        $duelOpponent = Get-QuotedValue -Lines $lines -Start $i -Key "duel_opponent"
        $requiresItems = Get-ArrayValue -Lines $lines -Start $i -Key "requires_items"
        $requiresFlags = Get-ArrayValue -Lines $lines -Start $i -Key "requires_flags"
        $itemsAdd = Get-ArrayValue -Lines $lines -Start $i -Key "items_add"
        $flagsSet = Get-ArrayValue -Lines $lines -Start $i -Key "flags_set"
        $confessionsDiscover = Get-ArrayValue -Lines $lines -Start $i -Key "confessions_discover"

        $type = "hotspot"
        if (-not [string]::IsNullOrWhiteSpace($targetRoom)) { $type = "exit" }
        if (-not [string]::IsNullOrWhiteSpace($duelOpponent)) { $type = "duel" }

        $rows.Add([pscustomobject]@{
            room_id = $roomId
            room_code = $roomCode
            room_title = $roomTitle
            type = $type
            name = $name
            label = $description
            x = $position.X
            y = $position.Y
            target_room = $targetRoom
            requires_items = $requiresItems
            requires_flags = $requiresFlags
            items_add = $itemsAdd
            flags_set = $flagsSet
            confessions_discover = $confessionsDiscover
            ink_knot = $inkKnot
            wet_ink_knot = $wetInkKnot
            blocked_ink_knot = $blockedInkKnot
            alternate_requires_flags = $alternateRequiresFlags
            alternate_flags_set = $alternateFlagsSet
            alternate_ink_knot = $alternateInkKnot
            duel_opponent = $duelOpponent
        })
    }
}

$rows | ConvertTo-Csv -NoTypeInformation | Set-Content -LiteralPath $outPath -Encoding UTF8
Write-Host "Exported $($rows.Count) Act I hotspot map rows -> $outPath"
