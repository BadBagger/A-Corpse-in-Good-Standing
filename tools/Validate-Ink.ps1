$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$inkDir = Join-Path $root "ink"
$confessionPath = Join-Path $root "data\confessions.json"
$narrativeStatePath = Join-Path $root "game\autoloads\narrative_state.gd"
$popochiuDataPath = Join-Path $root "game\popochiu_data.cfg"

powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Compile-Ink.ps1")

$confessions = Get-Content -LiteralPath $confessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
$confessionIds = @{}
foreach ($confession in $confessions) {
    $confessionIds[[string]$confession.id] = $true
}

$narrativeState = Get-Content -LiteralPath $narrativeStatePath -Raw -Encoding UTF8
$journalIds = @{}
foreach ($match in [regex]::Matches($narrativeState, "`"(j_[A-Za-z0-9_]+)`"\s*:")) {
    $journalIds[$match.Groups[1].Value] = $true
}
if ($journalIds.Count -eq 0) {
    throw "No journal ids found in $narrativeStatePath"
}

$popochiuData = Get-Content -LiteralPath $popochiuDataPath -Raw -Encoding UTF8
$itemIds = @{}
$inInventorySection = $false
foreach ($line in $popochiuData -split "`r?`n") {
    if ($line -match "^\[inventory_items\]") {
        $inInventorySection = $true
        continue
    }
    if ($line -match "^\[") {
        $inInventorySection = $false
    }
    if ($inInventorySection -and $line -match "^([A-Za-z0-9_]+)=") {
        $itemIds[$Matches[1]] = $true
    }
}

$unknown = @()
$unknownTags = @()
$unknownJournal = @()
$unknownItems = @()
$duplicatedTextHits = @()
foreach ($file in Get-ChildItem -LiteralPath $inkDir -Filter "*.ink" -File) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

    $lineNumber = 0
    foreach ($line in $text -split "`r?`n") {
        $lineNumber += 1
        $tagMatch = [regex]::Match($line, "^\s*#\s+(.+?)\s*$")
        if (-not $tagMatch.Success) {
            continue
        }
        $tag = $tagMatch.Groups[1].Value
        $location = "$($file.Name):$lineNumber"

        if ($tag -match "^speaker:[A-Z0-9_]+$") {
            continue
        }
        if ($tag -match "^location:[a-z0-9_]+$") {
            continue
        }
        if ($tag -match "^journal:(add|degrade):([A-Za-z0-9_]+)$") {
            $id = $Matches[2]
            if (-not $journalIds.ContainsKey($id)) {
                $unknownJournal += "${location}:$id"
            }
            continue
        }
        if ($tag -match "^confession:(discover|spent|opponent_spoken):([A-Za-z0-9_]+)$") {
            $id = $Matches[2]
            if (-not $confessionIds.ContainsKey($id)) {
                $unknown += "${location}:$id"
            }
            continue
        }
        if ($tag -match "^item:add:([A-Za-z0-9_]+)$") {
            $id = $Matches[1]
            if (-not $itemIds.ContainsKey($id)) {
                $unknownItems += "${location}:$id"
            }
            continue
        }

        $unknownTags += "${location}:$tag"
    }

    foreach ($confession in $confessions) {
        $line = [string]$confession.text
        if (-not [string]::IsNullOrWhiteSpace($line) -and $text.Contains($line)) {
            $duplicatedTextHits += "$($file.Name):$($confession.id)"
        }
    }
}

if ($unknown.Count -gt 0) {
    throw "Ink references unknown confession ids: $($unknown -join ', ')"
}
if ($unknownJournal.Count -gt 0) {
    throw "Ink references unknown journal ids: $($unknownJournal -join ', ')"
}
if ($unknownItems.Count -gt 0) {
    throw "Ink references unknown item ids: $($unknownItems -join ', ')"
}
if ($unknownTags.Count -gt 0) {
    throw "Ink uses unsupported gameplay tags: $($unknownTags -join ', ')"
}
if ($duplicatedTextHits.Count -gt 0) {
    throw "Ink duplicates confession text instead of id references: $($duplicatedTextHits -join ', ')"
}

Write-Host "Ink validation passed: tags checked against runtime contract."
