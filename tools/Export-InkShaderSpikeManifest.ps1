$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $root "docs\art\ink_shader_spike_manifest.json"
$briefPath = Join-Path $root "docs\art\ink_shader_spike_brief.md"
$statusCsvPath = Join-Path $root "docs\art\ink_shader_spike_status.csv"
$statusReportPath = Join-Path $root "docs\art\ink_shader_spike_status.md"

$palette = @(
    @{ name = "bone_paper_white"; hex = "#E4DCC8" },
    @{ name = "wet_black"; hex = "#0C1013" },
    @{ name = "harbor_slate"; hex = "#2A3A40" },
    @{ name = "absinthe_green"; hex = "#7D9B4E" },
    @{ name = "whale_oil_amber"; hex = "#C98A3C" },
    @{ name = "arterial_red"; hex = "#8E1B22" }
)

$tests = @(
    [ordered]@{
        id = "r1_raw_side_profile"
        gate = "R1"
        label = "Raw side-profile render"
        required = $true
        source_path = "art/src/shaders/ink_wash_shader_spike.blend"
        output_path = "art/export/shader_spike/corvin_act_i_clean_side_raw.png"
        notes = "Establishes unprocessed Corvin Act I clean side-right framing at 2x target."
    },
    [ordered]@{
        id = "r2_two_tone_ink_ramp"
        gate = "R2"
        label = "Two-tone ink ramp still"
        required = $true
        source_path = "art/src/shaders/ink_wash_shader_spike.blend"
        output_path = "art/export/shader_spike/corvin_act_i_clean_side_ink_ramp.png"
        notes = "Proves the flat toon ramp has been replaced by wet black plus highlight ink bands."
    },
    [ordered]@{
        id = "r3_object_anchored_hatching_sequence"
        gate = "R3"
        label = "Object-anchored hatching yaw sequence"
        required = $true
        source_path = "art/src/shaders/ink_wash_shader_spike.blend"
        output_path = "art/export/shader_spike/yaw_object_anchored/frame_0001.png"
        frame_count = 24
        motion = "yaw_turn"
        notes = "The production candidate. Hatching must stick to Corvin through a yaw turn, not just a walk translation."
    },
    [ordered]@{
        id = "r4_screen_space_bad_control"
        gate = "R4"
        label = "Screen-space hatching bad control"
        required = $true
        source_path = "art/src/shaders/ink_wash_shader_spike.blend"
        output_path = "art/export/shader_spike/yaw_screen_space_bad_control/frame_0001.png"
        frame_count = 24
        motion = "yaw_turn"
        notes = "Known-bad control for calibrating shimmer. This must not become a production path."
    },
    [ordered]@{
        id = "r5_pairwise_hatching_delta"
        gate = "R5"
        label = "Pairwise hatching stability report"
        required = $true
        source_path = "art/export/shader_spike/yaw_object_anchored/"
        output_path = "docs/art/ink_shader_spike_pairwise_delta.json"
        frame_count = 24
        provisional_threshold_percent = 6.0
        notes = "6 percent is provisional until measured against the known-bad and known-good controls."
    },
    [ordered]@{
        id = "r6_first_last_hatching_drift"
        gate = "R6"
        label = "First-to-last hatch drift report"
        required = $true
        source_path = "art/export/shader_spike/yaw_object_anchored/"
        output_path = "docs/art/ink_shader_spike_first_last_drift.json"
        frame_count = 24
        notes = "Catches slow crawl that can pass consecutive-frame checks."
    },
    [ordered]@{
        id = "r7_palette_mapped_sequence"
        gate = "R7"
        label = "Locked-palette mapped sequence"
        required = $true
        source_path = "art/export/shader_spike/yaw_object_anchored/"
        output_path = "art/export/shader_spike/yaw_palette_mapped/frame_0001.png"
        frame_count = 24
        notes = "Rendered sequence must be mapped to the locked project palette before sprite-sheet production."
    }
)

$manifest = [ordered]@{
    generated_from = "AGENTS.md section 8.3 and Corvin animation manifest"
    purpose = "Prove the Blender ink-wash render stack before final sprite-sheet or background art production."
    pipeline = "Meshy source -> Blender two-tone ink ramp and object-anchored hatching -> locked-palette 2D sprite sheets"
    runtime_scope = "The game still imports only 2D sprites and backgrounds; no live Godot 3D is introduced."
    duel_format_locked = $true
    no_diffusion_per_frame = $true
    test_subject = [ordered]@{
        character_id = "corvin"
        variant = "act_i_clean"
        preferred_direction = "side_right"
        source_model = "art/src/characters/corvin/meshy/corvin_act_i_clean.glb"
        blender_source = "art/src/shaders/ink_wash_shader_spike.blend"
    }
    render_contract = [ordered]@{
        fps = 12
        sequence_frames = 24
        render_scale = "2x target"
        camera = "orthographic side-on adventure-game camera"
        stress_motion = "yaw_turn"
        pairwise_delta_threshold_percent = 6.0
        pairwise_threshold_status = "provisional until calibrated by good and bad controls"
        first_to_last_drift_required = $true
        first_to_last_drift_threshold_percent = 9.0
        hatching_space = "object_or_world_anchored"
        forbidden_hatching_space = "screen_space_only"
    }
    palette = $palette
    tests = $tests
}

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$briefLines = @(
    "# Ink Shader Spike Brief",
    "",
    'Generated by `tools/Export-InkShaderSpikeManifest.ps1`.',
    "",
    "Purpose: prove the ink-wash render stack on Corvin before final sprite-sheet or background production.",
    "Pipeline: Meshy source -> Blender two-tone ink ramp and object-anchored hatching -> locked-palette 2D sprite sheets.",
    "Runtime boundary: Godot imports 2D sprites/backgrounds only. No live 3D renderer is introduced.",
    "Duel lock: this spike must not alter the accepted Registrar Litany UI, route, counter math, or global spend behavior.",
    "Source-art lock: no diffusion-per-frame production art. Generated images may be reference only.",
    "",
    "Render contract: 12 fps, 24-frame yaw turn, 2x target render, orthographic side-on camera.",
    "Hatching contract: object/world-anchored hatching is required; screen-space-only hatching is allowed only as the known-bad control.",
    "Stability contract: pairwise hatch delta target is provisionally 6 percent until the bad-control and known-good renders calibrate it; first-to-last drift is also required.",
    'Measurement command: `tools/Test-InkShaderSpikeMetrics.ps1` writes `docs/art/ink_shader_spike_metrics_status.json` and `.md` once the yaw-turn renders exist.',
    "",
    "Locked palette: $(@($palette | ForEach-Object { $_.hex }) -join ', ').",
    "",
    "| Gate | Test | Required | Frames | Output | Notes |",
    "|---|---|---|---:|---|---|"
)

foreach ($test in $tests) {
    $frames = if ($test.Contains("frame_count")) { $test.frame_count } else { "" }
    $briefLines += "| $($test.gate) | $($test.label) | $($test.required) | $frames | ``$($test.output_path)`` | $($test.notes) |"
}

Set-Content -LiteralPath $briefPath -Value $briefLines -Encoding UTF8

function Resolve-RepoPath {
    param([Parameter(Mandatory=$true)][string]$RelativePath)

    return Join-Path $root ($RelativePath -replace "/", "\")
}

$statusRows = New-Object System.Collections.Generic.List[object]
foreach ($test in $tests) {
    $exists = Test-Path -LiteralPath (Resolve-RepoPath $test.output_path)
    $statusRows.Add([pscustomobject]@{
        gate = $test.gate
        test_id = $test.id
        status = $(if ($exists) { "present" } else { "pending" })
        required = $test.required
        frame_count = $(if ($test.Contains("frame_count")) { $test.frame_count } else { "" })
        motion = $(if ($test.Contains("motion")) { $test.motion } else { "" })
        source_path = $test.source_path
        output_path = $test.output_path
    })
}

$statusRows |
    Sort-Object gate |
    ConvertTo-Csv -NoTypeInformation |
    Set-Content -LiteralPath $statusCsvPath -Encoding UTF8

$presentCount = @($statusRows | Where-Object { $_.status -eq "present" }).Count
$pendingCount = @($statusRows | Where-Object { $_.status -eq "pending" }).Count

$statusLines = @(
    "# Ink Shader Spike Status",
    "",
    'Generated by `tools/Export-InkShaderSpikeManifest.ps1` from `docs/art/ink_shader_spike_manifest.json`.',
    "",
    "This is a shader proof tracker, not a greybox gameplay failure. Pending means the render proof still has to be produced.",
    "",
    "Summary: $presentCount present, $pendingCount pending, $($statusRows.Count) total shader proof slots.",
    "",
    "| Gate | Test | Status | Frames | Motion | Output |",
    "|---|---|---|---:|---|---|"
)

foreach ($row in ($statusRows | Sort-Object gate)) {
    $statusLines += "| $($row.gate) | $($row.test_id) | $($row.status) | $($row.frame_count) | $($row.motion) | ``$($row.output_path)`` |"
}

Set-Content -LiteralPath $statusReportPath -Value $statusLines -Encoding UTF8

Write-Host "Exported ink shader spike manifest -> $manifestPath"
Write-Host "Exported ink shader spike brief -> $briefPath"
Write-Host "Exported ink shader spike status CSV -> $statusCsvPath"
Write-Host "Exported ink shader spike status report -> $statusReportPath"
Write-Host "Ink shader spike proof slots: present=$presentCount, pending=$pendingCount, total=$($statusRows.Count)"
