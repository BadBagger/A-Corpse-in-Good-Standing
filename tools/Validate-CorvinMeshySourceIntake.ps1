$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$intakeJsonPath = Join-Path $root "docs\art\corvin_meshy_source_intake.json"
$intakeReportPath = Join-Path $root "docs\art\corvin_meshy_source_intake.md"

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Import-CorvinMeshySource.ps1")

foreach ($path in @($intakeJsonPath, $intakeReportPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin Meshy intake artifact: $path"
    }
}

$intake = Get-Content -LiteralPath $intakeJsonPath -Raw | ConvertFrom-Json
if ($intake.canonical_act_i_mesh.target_path -ne "art/src/characters/corvin/meshy/corvin_act_i_clean.glb") {
    throw "Corvin Meshy intake has wrong canonical Act I target path."
}
if ($intake.canonical_act_i_mesh.source_present -eq $true -and $intake.canonical_act_i_mesh.target_present -ne $true) {
    throw "Corvin Meshy intake found the source GLB but did not create the canonical target."
}
if ($intake.canonical_act_i_mesh.target_present -eq $true -and $intake.canonical_act_i_mesh.source_present -eq $true) {
    if ($intake.canonical_act_i_mesh.source_sha256 -ne $intake.canonical_act_i_mesh.target_sha256) {
        throw "Corvin canonical Act I mesh hash does not match the source download."
    }
}
if ($intake.biped_zip.source_present -eq $true -and @($intake.biped_zip.glb_entries).Count -lt 1) {
    throw "Corvin biped ZIP is present but no GLB entries were found."
}

$dropPaths = $intake.canonical_drop_paths
foreach ($requiredPath in @(
    "art/src/characters/corvin/meshy/corvin_act_i_clean.glb",
    "art/src/characters/corvin/meshy/corvin_act_ii_salting.glb",
    "art/src/characters/corvin/meshy/corvin_act_iii_crusted.glb",
    "art/src/shaders/ink_wash_shader_spike.blend"
)) {
    if ($requiredPath -notin @($dropPaths.PSObject.Properties | ForEach-Object { $_.Value })) {
        throw "Corvin Meshy intake missing drop path: $requiredPath"
    }
}

$motionCandidates = @($intake.motion_candidates)
foreach ($requiredAnimation in @("idle", "walk", "talk", "wet", "use")) {
    $candidate = @($motionCandidates | Where-Object { $_.target_animation -eq $requiredAnimation })[0]
    if ($null -eq $candidate) {
        throw "Corvin Meshy intake missing motion candidate for $requiredAnimation."
    }
}
$wetCandidate = @($motionCandidates | Where-Object { $_.target_animation -eq "wet" })[0]
if ($wetCandidate.status -ne "custom_required") {
    throw "Corvin wet animation must remain marked custom_required."
}

$report = Get-Content -LiteralPath $intakeReportPath -Raw
foreach ($requiredText in @("Corvin Meshy Source Intake", "Canonical Act I source", "biped ZIP is reference", "accepted Registrar duel format", "Motion Candidates")) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin Meshy intake report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @('$(@{', "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Corvin Meshy intake report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Corvin Meshy intake report must stay ASCII-only."
}

Write-Host "Corvin Meshy source intake validation passed: sourcePresent=$($intake.canonical_act_i_mesh.source_present), targetPresent=$($intake.canonical_act_i_mesh.target_present), zipEntries=$(@($intake.biped_zip.glb_entries).Count)"
