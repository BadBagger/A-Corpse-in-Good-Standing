$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "docs\art\corvin_act_i_palette_despill.json"
$reportMdPath = Join-Path $root "docs\art\corvin_act_i_palette_despill.md"
$contactPath = Join-Path $root "docs\art\review\corvin_act_i_despill_contact_sheet.png"

foreach ($path in @($reportPath, $reportMdPath, $contactPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin green-cast validation input: $path"
    }
}

$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
$reportMd = Get-Content -LiteralPath $reportMdPath -Raw

if ($report.status -ne "despilled") {
    throw "Corvin green-cast report has unexpected status: $($report.status)"
}

$expectedSheets = @(
    "idle_side_left.png",
    "idle_side_right.png",
    "walk_side_left.png",
    "walk_side_right.png",
    "talk_side_left.png",
    "talk_side_right.png",
    "use_side_left.png",
    "use_side_right.png",
    "wet_side_left.png",
    "wet_side_right.png"
)

$rows = @($report.sheets)
if ($rows.Count -ne $expectedSheets.Count) {
    throw "Corvin green-cast report expected $($expectedSheets.Count) rows, got $($rows.Count)."
}

foreach ($sheet in $expectedSheets) {
    $row = @($rows | Where-Object { $_.sheet -eq $sheet })[0]
    if ($null -eq $row) {
        throw "Corvin green-cast report missing sheet: $sheet"
    }

    foreach ($propertyName in @("export_path", "game_path")) {
        $relative = [string]$row.$propertyName
        if ($relative -match "\\") {
            throw "Corvin green-cast $propertyName must be repo-relative with forward slashes: $relative"
        }
        $absolute = Join-Path $root ($relative -replace "/", "\")
        if (-not (Test-Path -LiteralPath $absolute)) {
            throw "Corvin green-cast referenced file missing: $relative"
        }
    }

    if ([double]$row.after_greenish_percent -gt 1.0) {
        throw "Corvin sheet $sheet remains too green: $($row.after_greenish_percent)% greenish pixels."
    }
    if ([double]$row.after_greenish_percent -gt [double]$row.before_greenish_percent) {
        throw "Corvin sheet $sheet green-cast got worse."
    }
}

foreach ($requiredText in @(
    "Corvin Act I Palette Despill",
    "green belongs to wrong-light set dressing, not Corvin's body or coat",
    "game/characters/corvin/sprites/act_i_clean",
    "art/export/characters/corvin/act_i_clean"
)) {
    if ($reportMd -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin green-cast report missing required text: $requiredText"
    }
}

Write-Host "Corvin green-cast validation passed: sheets=$($rows.Count), maxGreen=$([Math]::Round((@($rows | ForEach-Object { [double]$_.after_greenish_percent }) | Measure-Object -Maximum).Maximum, 3))%."
