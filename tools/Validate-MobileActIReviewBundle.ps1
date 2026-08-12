$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$bundlePath = Join-Path $root "docs\playtest\mobile_act_i_review_bundle.md"

if (-not (Test-Path -LiteralPath $bundlePath)) {
    throw "Missing mobile Act I review bundle: $bundlePath"
}

$bundle = Get-Content -LiteralPath $bundlePath -Raw -Encoding UTF8

foreach ($requiredText in @(
    "Mobile Act I Review Bundle",
    "keep going",
    "fix Corvin first",
    "fix rooms first",
    "fix duel/UI first",
    "not this visual direction",
    "Project visual target",
    "Corvin side actions",
    "Act I harbor look target",
    "Full Act I contact sheet",
    "Automated Act I route report",
    'If you say `keep going`'
)) {
    if ($bundle -notmatch [regex]::Escape($requiredText)) {
        throw "Mobile Act I review bundle missing required text: $requiredText"
    }
}

$imageRefs = @(
    "docs\art\review\project_visual_target_mockup_v1.png",
    "docs\art\review\corvin_side_actions_contact_sheet.png",
    "docs\art\reference\look_targets\act_i_harbor_look_target_v1.png",
    "art\export\backgrounds\act_i\mudflats_bg.png",
    "art\export\backgrounds\act_i\old_quay_blockout_bg.png",
    "art\export\backgrounds\act_i\salt_market_bg.png",
    "art\export\backgrounds\act_i\harbor_registry_bg.png",
    "art\export\backgrounds\act_i\grey_float_bg.png",
    "art\export\backgrounds\act_i\sabine_office_bg.png"
)
foreach ($relative in $imageRefs) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Mobile Act I review bundle references missing image: $relative"
    }
    $file = Get-Item -LiteralPath $path
    if ($file.Length -lt 1000) {
        throw "Mobile Act I review bundle image is unexpectedly small: $relative bytes=$($file.Length)"
    }
}

$docRefs = @(
    "docs\art\act_i_review_contact_sheet.html",
    "docs\playtest\act_i_player_review_card.md",
    "docs\playtest\results\act_i_greybox_auto_report.md",
    "docs\playtest\results\act_i_human_playtest_latest.md"
)
foreach ($relative in $docRefs) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Mobile Act I review bundle references missing document: $relative"
    }
}

foreach ($badText in @(
    "approved final shipped backgrounds",
    "production art approved",
    "Act II greybox accepted"
)) {
    if ($bundle -match [regex]::Escape($badText)) {
        throw "Mobile Act I review bundle contains forbidden over-approval text: $badText"
    }
}

Write-Host "Mobile Act I review bundle validation passed: $bundlePath"
