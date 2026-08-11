$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root "docs\LITANY_confession_library.md"
$outPath = Join-Path $root "data\confessions.json"

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Missing Litany source: $sourcePath"
}

$actMap = @{
    "I" = 1
    "II" = 2
    "III" = 3
}

$lines = Get-Content -LiteralPath $sourcePath -Encoding UTF8
$entries = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = [string]$lines[$i]
    if ($line -notmatch '^\*\*(cf_[a-z0-9_]+)\*\*') {
        continue
    }

    $id = $matches[1]
    if ($line -cnotmatch '\b(GREED|LUST|PRIDE|CRUELTY|COWARDICE|BETRAYAL)\b') {
        throw "Could not parse category for $id"
    }
    $category = $matches[1]

    if ($line -notmatch '\s(\d+)\s') {
        throw "Could not parse weight for $id"
    }
    $weight = [int]$matches[1]

    if ($line -notmatch 'Act\s+(I{1,3})') {
        throw "Could not parse act for $id"
    }
    $actAvailable = [int]$actMap[$matches[1]]

    if ($line -cnotmatch '\b(OVERHEARD|EXCAVATED|COMMITTED)\b') {
        throw "Could not parse acquisition for $id"
    }
    $acquisition = $matches[1]

    $text = ""
    $elaboration = ""
    for ($j = $i + 1; $j -lt [Math]::Min($i + 8, $lines.Count); $j++) {
        $next = [string]$lines[$j]
        if ($next -match '^\s*>\s+"(.+)"\s*$') {
            $text = $matches[1]
            continue
        }

        # Elaboration lines are the first quoted, non-blockquote line after the confession text.
        # This avoids depending on whether the markdown dash decoded cleanly on Windows.
        if ($text -ne "" -and $next -notmatch '^\s*>' -and $next -match '"(.+)"') {
            $elaboration = $matches[1]
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "Missing confession text for $id"
    }
    if ([string]::IsNullOrWhiteSpace($elaboration)) {
        throw "Missing elaboration for $id"
    }

    $entries.Add([ordered]@{
        id = $id
        text = $text
        elaboration = $elaboration
        category = $category
        weight = $weight
        act_available = $actAvailable
        acquisition = $acquisition
        source_node = ""
        spent = $false
    })
}

if ($entries.Count -eq 0) {
    throw "No confessions parsed from $sourcePath"
}

$json = $entries | ConvertTo-Json -Depth 10
Set-Content -LiteralPath $outPath -Value $json -Encoding UTF8
Write-Host "Exported $($entries.Count) confessions -> $outPath"
