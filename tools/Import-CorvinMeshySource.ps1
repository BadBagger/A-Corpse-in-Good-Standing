$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$downloads = Join-Path $env:USERPROFILE "Downloads"
$sourceGlb = Join-Path $downloads "Meshy_AI_Drowned_Gentleman_0810232218_texture.glb"
$sourceZip = Join-Path $downloads "Meshy_AI_Drowned_Gentleman_biped.zip"
$meshyDir = Join-Path $root "art\src\characters\corvin\meshy"
$uploadDir = Join-Path $meshyDir "source_uploads"
$textureDir = Join-Path $root "art\src\characters\corvin\textures"
$shaderDir = Join-Path $root "art\src\shaders"
$shaderExportDir = Join-Path $root "art\export\shader_spike"
$targetGlb = Join-Path $meshyDir "corvin_act_i_clean.glb"
$riggedTarget = Join-Path $uploadDir "meshy_biped_character_output.glb"
$intakeJsonPath = Join-Path $root "docs\art\corvin_meshy_source_intake.json"
$intakeReportPath = Join-Path $root "docs\art\corvin_meshy_source_intake.md"

foreach ($directory in @($meshyDir, $uploadDir, $textureDir, $shaderDir, $shaderExportDir)) {
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
}

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    return ($Path.Substring($root.Length + 1) -replace "\\", "/")
}

function Get-OptionalHash {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$sourceGlbExists = Test-Path -LiteralPath $sourceGlb
$sourceZipExists = Test-Path -LiteralPath $sourceZip

if ($sourceGlbExists) {
    $sourceHash = Get-OptionalHash -Path $sourceGlb
    $targetHash = Get-OptionalHash -Path $targetGlb
    if ($sourceHash -ne $targetHash) {
        Copy-Item -LiteralPath $sourceGlb -Destination $targetGlb -Force
    }
}

$zipEntries = @()
if ($sourceZipExists) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = $null
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($sourceZip)
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -like "*.glb") {
                $zipEntries += [ordered]@{
                    name = $entry.FullName
                    length = $entry.Length
                }
            }
        }

        $characterEntry = @($zip.Entries | Where-Object { $_.FullName -like "*Character_output.glb" })[0]
        if ($null -ne $characterEntry) {
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($characterEntry, $riggedTarget, $true)
        }
    }
    finally {
        if ($null -ne $zip) {
            $zip.Dispose()
        }
    }
}

$motionCandidates = @(
    [ordered]@{
        target_animation = "idle"
        source_hint = "Animation_Listening_Gesture_withSkin.glb or Animation_Look_Around_Dumbfounded_withSkin.glb"
        status = "candidate_only"
        notes = "Needs cleanup into a subtle in-place coat-drip idle."
    },
    [ordered]@{
        target_animation = "walk"
        source_hint = "Animation_Walking_withSkin.glb or Animation_Walk_Slowly_and_Look_Around_withSkin.glb"
        status = "candidate_only"
        notes = "Side profile is production priority; root motion must be measured and made exportable in-place."
    },
    [ordered]@{
        target_animation = "talk"
        source_hint = "Animation_Listening_Gesture_withSkin.glb"
        status = "candidate_only"
        notes = "Body-talk loop only; VO mouth detail remains portrait/face-layer work."
    },
    [ordered]@{
        target_animation = "wet"
        source_hint = "No direct Meshy candidate"
        status = "custom_required"
        notes = "Needs a custom sleeve shake / drip action for Corvin's wet verb."
    },
    [ordered]@{
        target_animation = "use"
        source_hint = "Animation_Collect_Object_withSkin.glb or Animation_open_door_1_withSkin.glb"
        status = "candidate_only"
        notes = "Use only as a base for point-and-click reach/pickup timing."
    }
)

$intake = [ordered]@{
    generated_from = "tools/Import-CorvinMeshySource.ps1"
    canonical_act_i_mesh = [ordered]@{
        source_download = $sourceGlb
        source_present = $sourceGlbExists
        source_sha256 = Get-OptionalHash -Path $sourceGlb
        target_path = Get-RelativePath -Path $targetGlb
        target_present = (Test-Path -LiteralPath $targetGlb)
        target_sha256 = Get-OptionalHash -Path $targetGlb
        purpose = "Canonical Act I clean Meshy source for Corvin and the shader spike."
    }
    biped_zip = [ordered]@{
        source_download = $sourceZip
        source_present = $sourceZipExists
        source_sha256 = Get-OptionalHash -Path $sourceZip
        extracted_character_path = Get-RelativePath -Path $riggedTarget
        extracted_character_present = (Test-Path -LiteralPath $riggedTarget)
        purpose = "Rigged/reference motion source. Does not satisfy the full game animation contract by itself."
        glb_entries = $zipEntries
    }
    canonical_drop_paths = [ordered]@{
        act_i_clean = "art/src/characters/corvin/meshy/corvin_act_i_clean.glb"
        act_ii_salting = "art/src/characters/corvin/meshy/corvin_act_ii_salting.glb"
        act_iii_crusted = "art/src/characters/corvin/meshy/corvin_act_iii_crusted.glb"
        shader_spike_blend = "art/src/shaders/ink_wash_shader_spike.blend"
    }
    motion_candidates = $motionCandidates
}

$intake | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $intakeJsonPath -Encoding UTF8

$sourceStatus = if ($sourceGlbExists) { "present" } else { "missing" }
$zipStatus = if ($sourceZipExists) { "present" } else { "missing" }
$targetStatus = if (Test-Path -LiteralPath $targetGlb) { "present" } else { "missing" }
$riggedStatus = if (Test-Path -LiteralPath $riggedTarget) { "present" } else { "missing" }

$reportLines = @(
    "# Corvin Meshy Source Intake",
    "",
    'Generated by `tools/Import-CorvinMeshySource.ps1`.',
    "",
    "Purpose: make Kyle's Meshy downloads explicit source inputs for the deterministic Meshy -> Blender -> sprite-sheet pipeline.",
    "",
    "Canonical Act I source: $targetStatus at ``$(Get-RelativePath -Path $targetGlb)``.",
    "Source textured GLB: $sourceStatus at ``$sourceGlb``.",
    "Source biped ZIP: $zipStatus at ``$sourceZip``.",
    "Extracted rigged character: $riggedStatus at ``$(Get-RelativePath -Path $riggedTarget)``.",
    "",
    "Rules:",
    "- The standalone textured GLB is the canonical Act I clean source.",
    "- The biped ZIP is reference/rig/motion material, not proof that all production animations are done.",
    "- Act II salting and Act III crusted source meshes remain pending until decay variants are produced.",
    "- The accepted Registrar duel format is unrelated to this intake and stays unchanged.",
    "",
    "## Motion Candidates",
    "",
    "| Target | Status | Source Hint | Notes |",
    "|---|---|---|---|"
)

foreach ($candidate in $motionCandidates) {
    $reportLines += "| $($candidate.target_animation) | $($candidate.status) | $($candidate.source_hint) | $($candidate.notes) |"
}

$reportLines += ""
$reportLines += "## ZIP GLB Entries"
$reportLines += ""
$reportLines += "| Entry | Bytes |"
$reportLines += "|---|---:|"
foreach ($entry in $zipEntries) {
    $reportLines += "| $($entry.name) | $($entry.length) |"
}

Set-Content -LiteralPath $intakeReportPath -Value $reportLines -Encoding UTF8

Write-Host "Corvin Meshy intake exported -> $intakeJsonPath"
Write-Host "Corvin Meshy intake report -> $intakeReportPath"
Write-Host "Canonical Act I mesh: $targetStatus"
Write-Host "Biped ZIP: $zipStatus, extracted rigged character: $riggedStatus, zipGlbEntries=$($zipEntries.Count)"
