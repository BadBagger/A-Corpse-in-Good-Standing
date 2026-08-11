$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$confessionPath = Join-Path $root "data\confessions.json"
$inkPath = Join-Path $root "ink\prologue.ink"
$roomsPath = Join-Path $root "game\rooms"

if (-not (Test-Path -LiteralPath $confessionPath)) {
    throw "Missing confession data: $confessionPath"
}

$confessions = Get-Content -LiteralPath $confessionPath -Raw | ConvertFrom-Json
$byId = @{}
foreach ($confession in $confessions) {
    $byId[$confession.id] = $confession
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

Get-ChildItem -LiteralPath $roomsPath -Recurse -Filter "*.tscn" | ForEach-Object {
    $relative = $_.FullName.Substring($root.Length + 1)
    $text = Get-Content -LiteralPath $_.FullName -Raw
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
