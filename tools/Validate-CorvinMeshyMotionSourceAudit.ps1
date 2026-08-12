$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$downloads = Join-Path $env:USERPROFILE "Downloads"
$sourceZip = Join-Path $downloads "Meshy_AI_Drowned_Gentleman_biped.zip"
$motionDir = Join-Path $root "art\src\characters\corvin\meshy\motion_sources"
$jsonPath = Join-Path $root "docs\art\corvin_meshy_motion_source_audit.json"
$mdPath = Join-Path $root "docs\art\corvin_meshy_motion_source_audit.md"
$timeoutSeconds = 120

. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")

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

if (-not (Test-Path -LiteralPath $motionDir)) {
    New-Item -ItemType Directory -Path $motionDir | Out-Null
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $jsonPath))) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $jsonPath) | Out-Null
}

$sources = @(
    [pscustomobject][ordered]@{
        target_animation = "talk"
        source_role = "primary_body_talk_candidate"
        zip_entry_suffix = "Meshy_AI_Drowned_Gentleman_biped_Animation_Listening_Gesture_withSkin.glb"
        target_file = "talk_listening_gesture_withSkin.glb"
        intended_blender_action = "Corvin_act_i_clean_talk_side"
        status_floor = "candidate_only"
        notes = "Candidate body-talk loop only; VO mouth detail remains portrait/face-layer work."
    },
    [pscustomobject][ordered]@{
        target_animation = "use"
        source_role = "primary_reach_candidate"
        zip_entry_suffix = "Meshy_AI_Drowned_Gentleman_biped_Animation_Collect_Object_withSkin.glb"
        target_file = "use_collect_object_withSkin.glb"
        intended_blender_action = "Corvin_act_i_clean_use_side"
        status_floor = "candidate_only"
        notes = "Candidate reach timing only; must be trimmed into a generic point-and-click use action."
    },
    [pscustomobject][ordered]@{
        target_animation = "walk"
        source_role = "side_walk_polish_candidate"
        zip_entry_suffix = "Meshy_AI_Drowned_Gentleman_biped_Animation_Walking_withSkin.glb"
        target_file = "walk_walking_withSkin.glb"
        intended_blender_action = "Corvin_act_i_clean_walk_side_polish"
        status_floor = "candidate_only"
        notes = "Candidate rigged walk polish; root motion must be measured and converted to in-place side locomotion before it can replace the runtime candidate."
    },
    [pscustomobject][ordered]@{
        target_animation = "wet"
        source_role = "custom_required"
        zip_entry_suffix = ""
        target_file = ""
        intended_blender_action = "Corvin_act_i_clean_wet_side"
        status_floor = "custom_required"
        notes = "No Meshy candidate may satisfy wet; author a custom sleeve/coat brine action in the canonical blend."
    }
)

$zipPresent = Test-Path -LiteralPath $sourceZip
$rows = New-Object System.Collections.Generic.List[object]

if ($zipPresent) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = $null
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($sourceZip)
        foreach ($source in $sources) {
            $targetPath = if ([string]::IsNullOrWhiteSpace($source.target_file)) { "" } else { Join-Path $motionDir $source.target_file }
            $entryName = ""
            $extracted = $false

            if (-not [string]::IsNullOrWhiteSpace($source.zip_entry_suffix)) {
                $entry = @($zip.Entries | Where-Object { $_.FullName.EndsWith($source.zip_entry_suffix, [System.StringComparison]::OrdinalIgnoreCase) })[0]
                if ($null -ne $entry) {
                    $entryName = $entry.FullName
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $true)
                    $extracted = $true
                }
            }

            $rows.Add([pscustomobject][ordered]@{
                target_animation = [string]$source.target_animation
                source_role = [string]$source.source_role
                intended_blender_action = [string]$source.intended_blender_action
                source_zip_entry = $entryName
                source_path = if ([string]::IsNullOrWhiteSpace($targetPath)) { "" } else { Get-RelativePath -Path $targetPath }
                source_present = if ([string]::IsNullOrWhiteSpace($targetPath)) { $false } else { Test-Path -LiteralPath $targetPath }
                source_sha256 = if ([string]::IsNullOrWhiteSpace($targetPath)) { $null } else { Get-OptionalHash -Path $targetPath }
                extracted_from_zip = $extracted
                audit_status = "not_run"
                mesh_count = 0
                armature_count = 0
                action_count = 0
                frame_start = $null
                frame_end = $null
                notes = [string]$source.notes
            })
        }
    }
    finally {
        if ($null -ne $zip) {
            $zip.Dispose()
        }
    }
}
else {
    foreach ($source in $sources) {
        $targetPath = if ([string]::IsNullOrWhiteSpace($source.target_file)) { "" } else { Join-Path $motionDir $source.target_file }
        $rows.Add([pscustomobject][ordered]@{
            target_animation = [string]$source.target_animation
            source_role = [string]$source.source_role
            intended_blender_action = [string]$source.intended_blender_action
            source_zip_entry = ""
            source_path = if ([string]::IsNullOrWhiteSpace($targetPath)) { "" } else { Get-RelativePath -Path $targetPath }
            source_present = if ([string]::IsNullOrWhiteSpace($targetPath)) { $false } else { Test-Path -LiteralPath $targetPath }
            source_sha256 = if ([string]::IsNullOrWhiteSpace($targetPath)) { $null } else { Get-OptionalHash -Path $targetPath }
            extracted_from_zip = $false
            audit_status = "not_run"
            mesh_count = 0
            armature_count = 0
            action_count = 0
            frame_start = $null
            frame_end = $null
            notes = [string]$source.notes
        })
    }
}

$blenderPath = Get-CorpseBlenderPath -Optional
if ($null -ne $blenderPath) {
    foreach ($row in @($rows.ToArray() | Where-Object { $_.source_present -eq $true })) {
        $sourcePath = Join-Path $root ($row.source_path -replace "/", "\")
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("corpse_corvin_motion_audit_" + [System.Guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $probeScript = Join-Path $tempDir "audit_motion_source.py"
        $stdoutPath = Join-Path $tempDir "blender_stdout.txt"
        $stderrPath = Join-Path $tempDir "blender_stderr.txt"
        $resultJson = Join-Path $tempDir "audit_result.json"

        $python = @"
import bpy
import json

source_path = r'''$sourcePath'''
result_json = r'''$resultJson'''

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=source_path)

objects = list(bpy.context.scene.objects)
meshes = [obj for obj in objects if obj.type == 'MESH']
armatures = [obj for obj in objects if obj.type == 'ARMATURE']
actions = list(bpy.data.actions)

frame_start = None
frame_end = None
if actions:
    starts = []
    ends = []
    for action in actions:
        starts.append(action.frame_range[0])
        ends.append(action.frame_range[1])
    frame_start = round(min(starts), 3)
    frame_end = round(max(ends), 3)

with open(result_json, "w", encoding="utf-8") as f:
    json.dump({
        "mesh_count": len(meshes),
        "armature_count": len(armatures),
        "action_count": len(actions),
        "action_names": [action.name for action in actions],
        "frame_start": frame_start,
        "frame_end": frame_end
    }, f, indent=2)
"@

        Set-Content -LiteralPath $probeScript -Value $python -Encoding UTF8
        $process = Start-Process -FilePath $blenderPath `
            -ArgumentList @("--background", "--factory-startup", "--python", $probeScript) `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
            Stop-Process -Id $process.Id -Force
            $row.audit_status = "failed_timeout"
        }
        elseif (-not (Test-Path -LiteralPath $resultJson)) {
            $process.Refresh()
            $row.audit_status = "failed_no_result"
        }
        else {
            $result = Get-Content -LiteralPath $resultJson -Raw | ConvertFrom-Json
            $row.mesh_count = [int]$result.mesh_count
            $row.armature_count = [int]$result.armature_count
            $row.action_count = [int]$result.action_count
            $row.frame_start = $result.frame_start
            $row.frame_end = $result.frame_end
            $row.audit_status = if ($row.mesh_count -gt 0 -and $row.armature_count -gt 0 -and $row.action_count -gt 0) {
                "audited_motion_source"
            } else {
                "present_but_not_action_capable"
            }
        }
    }
}

$presentRows = @($rows | Where-Object { $_.source_present -eq $true })
$auditedRows = @($rows | Where-Object { $_.audit_status -eq "audited_motion_source" })
$customRows = @($rows | Where-Object { $_.source_role -eq "custom_required" })
$status = if ($presentRows.Count -lt 3) {
    "blocked_missing_selected_motion_sources"
} elseif ($null -eq $blenderPath) {
    "sources_present_blender_not_resolved"
} elseif ($auditedRows.Count -eq 3 -and $customRows.Count -eq 1) {
    "motion_sources_audited_wet_custom_required"
} else {
    "partial_motion_source_audit"
}

$payload = [ordered]@{
    generated_from = "tools/Validate-CorvinMeshyMotionSourceAudit.ps1"
    purpose = "Extract and audit only the selected Meshy motion GLBs that can feed Corvin's next deterministic side-action work."
    status = $status
    timeout_seconds = $timeoutSeconds
    source_zip = $sourceZip
    source_zip_present = $zipPresent
    source_zip_sha256 = Get-OptionalHash -Path $sourceZip
    motion_source_dir = "art/src/characters/corvin/meshy/motion_sources"
    blender_path = $blenderPath
    rule_locks = @(
        "Selected motion GLBs are source material only, not final sprites.",
        "No PNG sheet is created by this audit.",
        "Wet remains custom-required and cannot be satisfied by an unrelated Meshy motion.",
        "A candidate motion must have mesh, armature, and action data before it can be adapted into the canonical blend."
    )
    rows = @($rows.ToArray())
}

$payload | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Corvin Meshy Motion Source Audit",
    "",
    'Generated by `tools/Validate-CorvinMeshyMotionSourceAudit.ps1`.',
    "",
    "Purpose: selected motion-source intake for Corvin side-action authoring.",
    "",
    "Status: $status",
    "Source ZIP present: $zipPresent",
    "Timeout seconds: $timeoutSeconds",
    "",
    "Rule locks:",
    "- Selected motion GLBs are source material only, not final sprites.",
    "- No PNG sheet is created by this audit.",
    "- Wet remains custom-required and cannot be satisfied by an unrelated Meshy motion.",
    "- A candidate motion must have mesh, armature, and action data before it can be adapted into the canonical blend.",
    "",
    "| Target | Role | Source | Audit | Meshes | Armatures | Actions | Frames | Intended Action |",
    "|---|---|---|---|---:|---:|---:|---|---|"
)
foreach ($row in @($rows.ToArray())) {
    $frameText = if ($null -ne $row.frame_start -and $null -ne $row.frame_end) { "$($row.frame_start)-$($row.frame_end)" } else { "" }
    $sourceText = if ([string]::IsNullOrWhiteSpace([string]$row.source_path)) { "custom" } else { "``$($row.source_path)``" }
    $lines += "| $($row.target_animation) | $($row.source_role) | $sourceText | $($row.audit_status) | $($row.mesh_count) | $($row.armature_count) | $($row.action_count) | $frameText | ``$($row.intended_blender_action)`` |"
}

$lines += @(
    "",
    "Notes:",
    "- Talk/use/walk candidates may inform the canonical Corvin blend after review.",
    "- Wet must be authored as Corvin's physical brine verb; no source GLB is accepted for it yet."
)

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

if ($status -eq "partial_motion_source_audit") {
    throw "Corvin Meshy motion source audit is partial; inspect $mdPath."
}

Write-Host "Corvin Meshy motion source audit passed: status=$status, present=$($presentRows.Count), audited=$($auditedRows.Count), wetCustom=$($customRows.Count)."
