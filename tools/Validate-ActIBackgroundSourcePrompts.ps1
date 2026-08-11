$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_background_source_prompts.json"
$csvPath = Join-Path $root "docs\art\act_i_background_source_prompts.csv"
$mdPath = Join-Path $root "docs\art\act_i_background_source_prompts.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Export-ActIBackgroundSourcePrompts.ps1")

foreach ($path in @($jsonPath, $csvPath, $mdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I background source prompt artifact: $path"
    }
}

$payload = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rows = @(Import-Csv -LiteralPath $csvPath)
$brief = Get-Content -LiteralPath $mdPath -Raw
$prompts = @($payload.prompts)

if ($prompts.Count -ne 130 -or $rows.Count -ne 130 -or $payload.prompt_count -ne 130) {
    throw "Act I background source prompts expected 130 prompts, got json=$($prompts.Count), csv=$($rows.Count), payload=$($payload.prompt_count)."
}

$ids = @($prompts | ForEach-Object { $_.id })
$duplicates = @($ids | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
if ($duplicates.Count -gt 0) {
    throw "Act I background source prompts contain duplicate ids: $($duplicates -join ', ')"
}

foreach ($tool in @("Meshy", "imagegen", "paintover")) {
    $toolPrompts = @($prompts | Where-Object { $_.tool -eq $tool })
    if ($toolPrompts.Count -eq 0) {
        throw "Act I background source prompts missing tool group: $tool"
    }
}

foreach ($prompt in $prompts) {
    if ($prompt.status -ne "pending") {
        throw "Prompt $($prompt.id) must start pending, got $($prompt.status)."
    }
    foreach ($field in @("prompt", "negative_prompt", "output_contract", "source_path")) {
        if ([string]::IsNullOrWhiteSpace([string]$prompt.$field)) {
            throw "Prompt $($prompt.id) missing $field."
        }
    }
    if ($prompt.prompt -notmatch "#E4DCC8" -or $prompt.prompt -notmatch "#0C1013" -or $prompt.prompt -notmatch "#2A3A40") {
        throw "Prompt $($prompt.id) missing locked palette anchors."
    }

    if ($prompt.kind -eq "meshy_source_model") {
        if ($prompt.tool -ne "Meshy" -or $prompt.prompt -notmatch "no full room" -or $prompt.output_contract -notmatch "GLB") {
            throw "Meshy prompt $($prompt.id) does not preserve source-helper-only GLB constraints."
        }
    }
    if ($prompt.kind -eq "generated_reference") {
        if ($prompt.tool -ne "imagegen" -or $prompt.prompt -notmatch "Reference image only" -or $prompt.output_contract -notmatch "do not import directly") {
            throw "Generated-reference prompt $($prompt.id) does not preserve reference-only constraints."
        }
    }
    if ($prompt.kind -eq "interactive_layer") {
        if ($prompt.tool -ne "paintover" -or $prompt.prompt -notmatch "Transparent background" -or $prompt.output_contract -notmatch "runtime export") {
            throw "Interactive-layer prompt $($prompt.id) does not preserve runtime separation constraints."
        }
    }
}

foreach ($required in @(
    "Meshy prompts create isolated helper GLB props only",
    "imagegen prompts create reference boards only",
    "Interactive layer prompts preserve existing hotspot centers",
    "Navigation prompts preserve Godot exit metadata",
    "These prompts do not approve final art"
)) {
    if ($brief -notmatch [regex]::Escape($required)) {
        throw "Act I background source prompt report missing required guardrail: $required"
    }
}

$fence = ([string][char]96) * 3
if (-not $brief.Contains("$($fence)text") -or $brief -match "(?m)^``text$") {
    throw "Act I background source prompt report must use valid triple-backtick text fences."
}

$firstRoomHeading = [string](@([regex]::Matches($brief, "(?m)^##\s+R\d+\s+-\s+.+$") | ForEach-Object { $_.Value })[0]).Trim()
if ($firstRoomHeading -ne "## R01 - Mudflats") {
    throw "Act I background source prompts must be ordered by room code; first heading was: $firstRoomHeading"
}

Write-Host "Act I background source prompts validation passed: prompts=$($prompts.Count), meshy=$(@($prompts | Where-Object { $_.tool -eq 'Meshy' }).Count), imagegen=$(@($prompts | Where-Object { $_.tool -eq 'imagegen' }).Count), paintover=$(@($prompts | Where-Object { $_.tool -eq 'paintover' }).Count)."
