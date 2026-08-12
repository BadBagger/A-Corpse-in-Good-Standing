$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\checkpoints\step_5_review_dashboard.json"
$mdPath = Join-Path $root "docs\checkpoints\step_5_review_dashboard.md"
$startGatePath = Join-Path $root "docs\art\act_i_paintover_start_gate.json"

if (-not (Test-Path -LiteralPath $startGatePath)) {
    throw "Missing Step 5 review dashboard input: $startGatePath"
}

$startGate = Get-Content -LiteralPath $startGatePath -Raw | ConvertFrom-Json
$startGateItem = Get-Item -LiteralPath $startGatePath
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$startGateModifiedUtc = $startGateItem.LastWriteTimeUtc.ToString("o")

$artifactPaths = @(
    "docs/checkpoints/step_5_act_i_art_pass_readiness.md",
    "docs/playtest/results/act_i_greybox_auto_report.md",
    "docs/playtest/results/act_i_human_review_validation.md",
    "docs/playtest/results/act_i_human_playtest_latest.md",
    "docs/vo/act_i_vo_line_manifest.md",
    "docs/vo/confession_vo_manifest.md",
    "docs/vo/vo_recording_batches.md",
    "docs/vo/vo_cast_plan.md",
    "docs/vo/vo_commercial_readiness.md",
    "docs/vo/vo_recording_queue.md",
    "docs/vo/vo_recording_packets_index.md",
    "docs/vo/vo_minor_speaker_decisions_template.md",
    "docs/vo/vo_minor_speaker_decision_import_report.md",
    "docs/vo/vo_audio_asset_status.md",
    "docs/playtest/act_i_art_readability_review.md",
    "docs/art/act_i_review_contact_sheet.html",
    "docs/art/corvin_side_priority_work_order.md",
    "docs/art/corvin_meshy_motion_source_audit.md",
    "docs/art/corvin_side_action_blend_status.md",
    "docs/art/corvin_side_action_scaffold.md",
    "docs/art/corvin_side_action_render_queue.md",
    "docs/art/corvin_side_action_render_scripts_status.md",
    "docs/art/corvin_side_action_render_commands.md",
    "docs/art/corvin_side_action_rendered_sheets_audit.md",
    "docs/playtest/act_i_review_decisions_template.csv",
    "docs/playtest/act_i_review_decisions_template.md",
    "docs/playtest/act_i_review_decision_import_report.md",
    "docs/playtest/act_i_review_fix_tracker.md",
    "docs/art/act_i_hotspot_overlay.svg",
    "docs/art/act_i_background_ready_source_packets.md",
    "docs/art/act_i_look_target_reference.md",
    "docs/art/act_i_paintover_packet.md",
    "docs/art/act_i_paintover_source_scaffold.md",
    "docs/art/act_i_paintover_start_gate.md",
    "docs/art/act_i_paintover_work_order.md",
    "docs/art/act_i_paintover_source_intake.md",
    "docs/art/act_i_final_paintover_completion.md",
    "docs/art/act_i_paintover_review_provenance.md"
)

foreach ($relativePath in $artifactPaths) {
    $absolutePath = Join-Path $root ($relativePath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Missing Step 5 review dashboard artifact target: $relativePath"
    }
}

$workflow = @(
    [ordered]@{
        step = 1
        action = "Run the full Step 5 readiness gate."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Run-Step5ReadinessGates.ps1"
        artifact = "docs/checkpoints/step_5_act_i_art_pass_readiness.md"
        pass_condition = "Gate output remains green and the checkpoint still says this is readiness, not final art completion."
    },
    [ordered]@{
        step = 2
        action = "Refresh the automated Act I route transcript."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Record-ActIGreyboxPlaytest.ps1"
        artifact = "docs/playtest/results/act_i_greybox_auto_report.md"
        pass_condition = "Transcript still records direction-aware side transitions and the accepted Registrar route."
    },
    [ordered]@{
        step = 3
        action = "Create or open the human review notes."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\New-ActIHumanPlaytestNotes.ps1"
        artifact = "docs/playtest/results/act_i_human_playtest_latest.md"
        pass_condition = "Reviewer records greybox pacing, room readability, and proceed/revise/stop decisions."
    },
    [ordered]@{
        step = 4
        action = "Review the Act I VO timing manifest before recording locks."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIVoLineManifest.ps1"
        artifact = "docs/vo/act_i_vo_line_manifest.md"
        pass_condition = "Manifest is generated from Ink speaker tags, remains unrecorded, and lists uncast minor speakers before final VO."
    },
    [ordered]@{
        step = 5
        action = "Review the Litany confession VO manifest."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ConfessionVoManifest.ps1"
        artifact = "docs/vo/confession_vo_manifest.md"
        pass_condition = "Every confession has exactly one confession VO line and one elaboration VO line keyed by confession id."
    },
    [ordered]@{
        step = 6
        action = "Review VO recording batches before any scratch generation."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-VoRecordingBatches.ps1"
        artifact = "docs/vo/vo_recording_batches.md"
        pass_condition = "Every recordable Act I and Litany line appears in exactly one scene/category batch, not isolated one-line generation."
    },
    [ordered]@{
        step = 7
        action = "Review the manifest-driven VO cast plan."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-VoCastPlan.ps1"
        artifact = "docs/vo/vo_cast_plan.md"
        pass_condition = "Scratch voices remain licensing-unverified, Corvin owns the Litany lines, and pending minor speakers stay blocked."
    },
    [ordered]@{
        step = 8
        action = "Review VO commercial readiness before any shipping decision."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-VoCommercialReadiness.ps1"
        artifact = "docs/vo/vo_commercial_readiness.md"
        pass_condition = "Report remains blocked for shipping until licensing, disclosure, audio, and human VO lock evidence exists."
    },
    [ordered]@{
        step = 9
        action = "Test VO commercial readiness against stale upstream inputs."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Test-VoCommercialReadiness.ps1"
        artifact = "docs/vo/vo_commercial_readiness.md"
        pass_condition = "Commercial readiness regenerates cast-plan and audio-status inputs before deciding shipping blockers."
    },
    [ordered]@{
        step = 10
        action = "Review the scratch VO recording queue."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-VoRecordingQueue.ps1"
        artifact = "docs/vo/vo_recording_queue.md"
        pass_condition = "Only scratch-cast batches appear in the ready queue; pending-cast and cut/rewrite minor-speaker batches remain blocked."
    },
    [ordered]@{
        step = 11
        action = "Review generated scratch VO recording packets."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-VoRecordingPackets.ps1"
        artifact = "docs/vo/vo_recording_packets_index.md"
        pass_condition = "There is one packet per scratch-ready batch and no packet files for pending-cast or cut/rewrite blocked minor-speaker batches."
    },
    [ordered]@{
        step = 12
        action = "Fill or review the minor-speaker casting decision sheet."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-VoMinorSpeakerDecisionTemplate.ps1"
        artifact = "docs/vo/vo_minor_speaker_decisions_template.md"
        pass_condition = "All uncast minor speakers are represented before scratch VO generation starts."
    },
    [ordered]@{
        step = 13
        action = "Dry-run minor-speaker casting decisions before applying them."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Import-VoMinorSpeakerDecisions.ps1 -InputCsv docs\vo\vo_minor_speaker_decisions_template.csv -DryRun"
        artifact = "docs/vo/vo_minor_speaker_decision_import_report.md"
        pass_condition = "Dry run accepts only pending, cast, consolidate, or cut_or_rewrite decisions with required fields."
    },
    [ordered]@{
        step = 14
        action = "Check VO audio asset intake status."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-VoAudioAssetStatus.ps1"
        artifact = "docs/vo/vo_audio_asset_status.md"
        pass_condition = "Expected MP3 paths are tracked, missing files are not counted as recorded, and unplanned/zero-byte/blocked pending-cast or cut/rewrite MP3s fail."
    },
    [ordered]@{
        step = 15
        action = "Open the Act I review contact sheet."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIReviewContactSheet.ps1"
        artifact = "docs/art/act_i_review_contact_sheet.html"
        pass_condition = "Each room blockout appears with walk band, marker positions, hotspot rows, duel-format lock, and Grey Float hard-R lock."
    },
    [ordered]@{
        step = 16
        action = "Review Corvin's Act I side-priority animation work order."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSidePriorityWorkOrder.ps1"
        artifact = "docs/art/corvin_side_priority_work_order.md"
        pass_condition = "Side idle/walk remain runtime candidates, and Act I side talk/use/wet are the next animation targets before front/back or decay sheets."
    },
    [ordered]@{
        step = 17
        action = "Review Corvin's selected Meshy motion source audit."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinMeshyMotionSourceAudit.ps1"
        artifact = "docs/art/corvin_meshy_motion_source_audit.md"
        pass_condition = "Talk/use/walk source GLBs are audited as action-capable source material, wet remains custom-required, and no PNG sheets are created."
    },
    [ordered]@{
        step = 18
        action = "Review Corvin's authored side-action Blender source."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Author-CorvinSideActionBlend.ps1"
        artifact = "docs/art/corvin_side_action_blend_status.md"
        pass_condition = "The authored source blend contains talk/use/wet actions and a valid rig; rendered sheets still require audit and final animation polish review."
    },
    [ordered]@{
        step = 19
        action = "Review Corvin's side-action Blender scaffold."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSideActionScaffold.ps1"
        artifact = "docs/art/corvin_side_action_scaffold.md"
        pass_condition = "Talk/use/wet handoffs name exact Blender actions, frame beats, export targets, and require rendered-sheet audits before final animation polish review."
    },
    [ordered]@{
        step = 20
        action = "Review Corvin's side-action deterministic render queue."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSideActionRenderQueue.ps1"
        artifact = "docs/art/corvin_side_action_render_queue.md"
        pass_condition = "Talk/use/wet side-left and side-right rows track deterministic Blender PNG sheets and byte-for-byte Godot imports; placeholder PNGs stay forbidden."
    },
    [ordered]@{
        step = 21
        action = "Review Corvin's side-action render script status."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSideActionRenderScripts.ps1"
        artifact = "docs/art/corvin_side_action_render_scripts_status.md"
        pass_condition = "All six Blender entrypoints execute in audit mode without creating PNG sheets and report whether keyed talk/use/wet actions still need to be authored in the source blend."
    },
    [ordered]@{
        step = 22
        action = "Review Corvin's side-action render command handoff."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSideActionRenderCommands.ps1"
        artifact = "docs/art/corvin_side_action_render_commands.md"
        pass_condition = "Each queued talk/use/wet side render has a timeout-wrapped Blender command, byte-for-byte Godot import command, and render-queue audit command without creating placeholder PNGs."
    },
    [ordered]@{
        step = 23
        action = "Review Corvin's rendered side-action sheet audit."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-CorvinSideActionRenderedSheets.ps1"
        artifact = "docs/art/corvin_side_action_rendered_sheets_audit.md"
        pass_condition = "All six talk/use/wet side sheets exist in export and Godot paths, match byte-for-byte, have correct dimensions and nonblank frames, and still do not approve final animation polish."
    },
    [ordered]@{
        step = 24
        action = "Inspect the hotspot overlay against each room composition."
        command = ""
        artifact = "docs/art/act_i_hotspot_overlay.svg"
        pass_condition = "Puzzle props, exits, wet targets, and confession-source props read at the intended camera distance."
    },
    [ordered]@{
        step = 25
        action = "Review the Act I generated look target reference."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActILookTargetReference.ps1"
        artifact = "docs/art/act_i_look_target_reference.md"
        pass_condition = "The generated harbor image is treated as a mood/readability target only, not final room art, hotspot authority, or diffusion-per-frame character source."
    },
    [ordered]@{
        step = 26
        action = "Review the ready background source generation packets."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIBackgroundReadySourcePackets.ps1"
        artifact = "docs/art/act_i_background_ready_source_packets.md"
        pass_condition = "Packets include only Meshy helper GLBs and imagegen reference boards that are safe to acquire now; they are not final background plates and exclude held interactive/navigation PSD work."
    },
    [ordered]@{
        step = 27
        action = "Use the paintover packet as the room-by-room final-art brief."
        command = ""
        artifact = "docs/art/act_i_paintover_packet.md"
        pass_condition = "Painter follows the locked palette, walk band, hotspot coordinates, and risk notes."
    },
    [ordered]@{
        step = 28
        action = "Complete the art readability checklist."
        command = ""
        artifact = "docs/playtest/act_i_art_readability_review.md"
        pass_condition = "Every room has a proceed/revise/stop decision before final paint starts."
    },
    [ordered]@{
        step = 29
        action = "Export, validate, and fill the batch review decision sheet."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIReviewDecisionTemplate.ps1"
        artifact = "docs/playtest/act_i_review_decisions_template.csv"
        pass_condition = "Template has all 11 rooms, no malformed Markdown, and reviewer records one decision per room; every non-pending decision includes build_commit, reviewer, reviewed_at, decision_note, look_target_reviewed=yes, and corvin_action_scaffold_reviewed=yes."
    },
    [ordered]@{
        step = 30
        action = "Dry-run the batch review decisions."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Import-ActIReviewDecisions.ps1 -InputCsv docs\playtest\act_i_review_decisions_template.csv -DryRun"
        artifact = "docs/playtest/act_i_review_decision_import_report.md"
        pass_condition = "Dry run reports expected approved/revise/stop/pending counts without changing the tracker."
    },
    [ordered]@{
        step = 31
        action = "Apply the reviewed decision sheet after the dry run is clean."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Import-ActIReviewDecisions.ps1 -InputCsv docs\playtest\act_i_review_decisions_template.csv -Apply"
        artifact = "docs/playtest/act_i_review_fix_tracker.md"
        pass_condition = "Rooms remain pending, revise, stop, or explicitly approved; no approval is implied by scaffold existence."
    },
    [ordered]@{
        step = 32
        action = "Check the safe paintover source scaffolds."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIPaintoverSourceScaffold.ps1"
        artifact = "docs/art/act_i_paintover_source_scaffold.md"
        pass_condition = "Scaffolds exist as handoff notes only and do not count as final PSD paintovers."
    },
    [ordered]@{
        step = 33
        action = "Re-run the paintover start gate."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIPaintoverStartGate.ps1"
        artifact = "docs/art/act_i_paintover_start_gate.md"
        pass_condition = "Final paintovers may start only for rooms that are human-approved and unblocked."
    },
    [ordered]@{
        step = 34
        action = "Generate the approved-room paintover work order."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIPaintoverWorkOrder.ps1"
        artifact = "docs/art/act_i_paintover_work_order.md"
        pass_condition = "Work order includes only start-gate-ready rooms, preserves build_commit, reviewer, reviewed_at, decision_note, look_target_reviewed, and corvin_action_scaffold_reviewed proof, and stays empty while all rooms are blocked."
    },
    [ordered]@{
        step = 35
        action = "Validate final PSD source intake against the work order."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIPaintoverSourceIntake.ps1"
        artifact = "docs/art/act_i_paintover_source_intake.md"
        pass_condition = "No blocked-room PSD can count as final paintover source material, and approved rows preserve work-order build_commit, reviewer, reviewed_at, decision_note, look_target_reviewed, and corvin_action_scaffold_reviewed proof."
    },
    [ordered]@{
        step = 36
        action = "Audit final paintover completion."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIFinalPaintoverCompletion.ps1"
        artifact = "docs/art/act_i_final_paintover_completion.md"
        pass_condition = "A room counts complete only when an accepted PSD has a newer audited final PNG export, and completion rows preserve source-intake build_commit, reviewer, reviewed_at, decision_note, look_target_reviewed, and corvin_action_scaffold_reviewed proof."
    },
    [ordered]@{
        step = 37
        action = "Audit paintover review provenance across all final-art handoff layers."
        command = "powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-ActIPaintoverReviewProvenance.ps1"
        artifact = "docs/art/act_i_paintover_review_provenance.md"
        pass_condition = "Approved rooms carry identical build_commit, reviewer, reviewed_at, decision_note, look_target_reviewed, and corvin_action_scaffold_reviewed proof from tracker through completion."
    }
)

$dashboard = [ordered]@{
    generated_from = "docs/art/act_i_paintover_start_gate.json"
    generated_at_utc = $generatedAtUtc
    source_modified_utc = $startGateModifiedUtc
    purpose = "Ordered Step 5 human-review dashboard and artifact index for Act I final-paintover readiness."
    readiness_state = "green_for_review"
    paintover_gate_status = $startGate.status
    ready_rooms = [int]$startGate.ready_count
    blocked_rooms = [int]$startGate.blocked_count
    rule_locks = @(
        "Keep the accepted Litany/Registrar duel format; do not add a second confession-spend UI.",
        "Keep Grey Float hard-R: steam, silhouette, privacy, and agency; no explicit X content.",
        "Do not start final paintovers while the start gate reports blocked_pending_human_review."
    )
    artifacts = $artifactPaths
    workflow = $workflow
}

$dashboard | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = @(
    "# Step 5 Review Dashboard",
    "",
    'Generated by `tools/Export-Step5ReviewDashboard.ps1` from `docs/art/act_i_paintover_start_gate.json` and the current Step 5 artifact set.',
    "",
    "Purpose: give the reviewer one ordered path through Act I art-pass readiness before any final paintover work starts.",
    "",
    "Generated at UTC: $generatedAtUtc",
    "Source modified UTC: $startGateModifiedUtc",
    "",
    "Readiness state: green_for_review",
    "Paintover gate status: $($startGate.status)",
    "Ready rooms: $([int]$startGate.ready_count)",
    "Blocked rooms: $([int]$startGate.blocked_count)",
    "",
    "Do not start final paintovers while the start gate reports blocked_pending_human_review.",
    "",
    "Rule locks:",
    "- Keep the accepted Litany/Registrar duel format; do not add a second confession-spend UI.",
    "- Keep Grey Float hard-R: steam, silhouette, privacy, and agency; no explicit X content.",
    "- Final PSD targets remain pending until real final room art exists and human review signs off.",
    "",
    "## Review Order",
    ""
)

foreach ($item in $workflow) {
    $lines += "### $($item.step). $($item.action)"
    if ($item.command.Length -gt 0) {
        $lines += "- Command: ``$($item.command)``"
    } else {
        $lines += "- Command: manual review"
    }
    $lines += "- Artifact: ``$($item.artifact)``"
    $lines += "- Pass condition: $($item.pass_condition)"
    $lines += ""
}

$lines += "## Artifact Index"
$lines += ""
foreach ($relativePath in $artifactPaths) {
    $lines += "- ``$relativePath``"
}

Set-Content -LiteralPath $mdPath -Value $lines -Encoding UTF8

Write-Host "Exported Step 5 review dashboard JSON -> $jsonPath"
Write-Host "Exported Step 5 review dashboard report -> $mdPath"
Write-Host "Step 5 review dashboard: status=$($startGate.status), ready=$([int]$startGate.ready_count), blocked=$([int]$startGate.blocked_count)"
