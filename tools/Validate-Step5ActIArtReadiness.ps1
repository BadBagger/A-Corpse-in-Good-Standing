$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

$backgroundStatusPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"
$paletteAuditPath = Join-Path $root "docs\art\act_i_background_palette_audit.csv"
$corvinStatusPath = Join-Path $root "docs\art\corvin_animation_asset_status.csv"
$shaderMetricsPath = Join-Path $root "docs\art\ink_shader_spike_metrics_status.json"
$runtimeSpriteReportPath = Join-Path $root "docs\art\corvin_runtime_sprite_assets_status.md"
$corvinSidePriorityPath = Join-Path $root "docs\art\corvin_side_priority_work_order.md"
$corvinSidePriorityJsonPath = Join-Path $root "docs\art\corvin_side_priority_work_order.json"
$corvinMotionAuditPath = Join-Path $root "docs\art\corvin_meshy_motion_source_audit.md"
$corvinMotionAuditJsonPath = Join-Path $root "docs\art\corvin_meshy_motion_source_audit.json"
$corvinSideActionBlendPath = Join-Path $root "docs\art\corvin_side_action_blend_status.md"
$corvinSideActionBlendJsonPath = Join-Path $root "docs\art\corvin_side_action_blend_status.json"
$corvinSideActionRenderQueuePath = Join-Path $root "docs\art\corvin_side_action_render_queue.md"
$corvinSideActionRenderQueueJsonPath = Join-Path $root "docs\art\corvin_side_action_render_queue.json"
$corvinSideActionRenderCommandsPath = Join-Path $root "docs\art\corvin_side_action_render_commands.md"
$corvinSideActionRenderCommandsJsonPath = Join-Path $root "docs\art\corvin_side_action_render_commands.json"
$corvinSideActionRenderScriptsPath = Join-Path $root "docs\art\corvin_side_action_render_scripts_status.md"
$corvinSideActionRenderScriptsJsonPath = Join-Path $root "docs\art\corvin_side_action_render_scripts_status.json"
$corvinSideActionRenderedSheetsPath = Join-Path $root "docs\art\corvin_side_action_rendered_sheets_audit.md"
$corvinSideActionRenderedSheetsJsonPath = Join-Path $root "docs\art\corvin_side_action_rendered_sheets_audit.json"
$playtestReportPath = Join-Path $root "docs\playtest\results\act_i_greybox_auto_report.md"
$backgroundElementPipelinePath = Join-Path $root "docs\art\act_i_background_element_pipeline.md"
$backgroundSourceWorklistPath = Join-Path $root "docs\art\act_i_background_source_worklist.md"
$backgroundSourcePromptsPath = Join-Path $root "docs\art\act_i_background_source_prompts.md"
$backgroundSourceIntakePath = Join-Path $root "docs\art\act_i_background_source_intake.md"
$lookTargetReferencePath = Join-Path $root "docs\art\act_i_look_target_reference.md"
$lookTargetReferenceJsonPath = Join-Path $root "docs\art\act_i_look_target_reference.json"
$backgroundSourcePlacementPath = Join-Path $root "docs\art\act_i_background_source_placement.md"
$backgroundSourceDropzonesPath = Join-Path $root "docs\art\act_i_background_source_dropzones.md"
$backgroundSourceAcquisitionPath = Join-Path $root "docs\art\act_i_background_source_acquisition.md"
$backgroundReadySourcePacketsPath = Join-Path $root "docs\art\act_i_background_ready_source_packets.md"
$paintoverPacketPath = Join-Path $root "docs\art\act_i_paintover_packet.md"
$artReadabilityReviewPath = Join-Path $root "docs\playtest\act_i_art_readability_review.md"
$reviewContactSheetPath = Join-Path $root "docs\art\act_i_review_contact_sheet.html"
$propCompositeContactSheetPath = Join-Path $root "docs\art\act_i_openai_prop_composite_contact_sheet.md"
$propCompositeContactSheetJsonPath = Join-Path $root "docs\art\act_i_openai_prop_composite_contact_sheet.json"
$propCompositeContactSheetImagePath = Join-Path $root "docs\art\review\act_i_openai_prop_composite_contact_sheet.png"
$propCompositeContactSheetValidatorPath = Join-Path $root "tools\Validate-ActIOpenAIPropCompositeContactSheet.ps1"
$atmosphereSetpiecesPath = Join-Path $root "docs\art\act_i_atmosphere_setpieces.md"
$atmosphereSetpiecesJsonPath = Join-Path $root "docs\art\act_i_atmosphere_setpieces.json"
$atmosphereSetpiecesImagePath = Join-Path $root "docs\art\review\act_i_atmosphere_setpieces_contact_sheet.png"
$atmosphereSetpiecesValidatorPath = Join-Path $root "tools\Validate-ActIAtmosphereSetpieces.ps1"
$hudSkinPath = Join-Path $root "docs\art\act_i_openai_hud_skin.md"
$hudSkinJsonPath = Join-Path $root "docs\art\act_i_openai_hud_skin.json"
$hudSkinImagePath = Join-Path $root "docs\art\review\act_i_openai_hud_skin_contact_sheet.png"
$hudSkinValidatorPath = Join-Path $root "tools\Validate-ActIOpenAIHudSkin.ps1"
$runtimeReviewFramesPath = Join-Path $root "docs\art\act_i_runtime_review_frames.md"
$runtimeReviewFramesJsonPath = Join-Path $root "docs\art\act_i_runtime_review_frames.json"
$runtimeReviewFramesImagePath = Join-Path $root "docs\art\review\act_i_runtime_frame_contact_sheet.png"
$runtimeReviewFramesValidatorPath = Join-Path $root "tools\Validate-ActIRuntimeReviewFrames.ps1"
$humanReviewNotesPath = Join-Path $root "docs\playtest\results\act_i_human_review_validation.md"
$voLineManifestPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.json"
$voLineManifestReportPath = Join-Path $root "docs\vo\act_i_vo_line_manifest.md"
$confessionVoManifestPath = Join-Path $root "docs\vo\confession_vo_manifest.json"
$confessionVoManifestReportPath = Join-Path $root "docs\vo\confession_vo_manifest.md"
$voRecordingBatchesPath = Join-Path $root "docs\vo\vo_recording_batches.json"
$voRecordingBatchesReportPath = Join-Path $root "docs\vo\vo_recording_batches.md"
$voCastPlanPath = Join-Path $root "docs\vo\vo_cast_plan.json"
$voCastPlanReportPath = Join-Path $root "docs\vo\vo_cast_plan.md"
$voCommercialReadinessPath = Join-Path $root "docs\vo\vo_commercial_readiness.json"
$voCommercialReadinessReportPath = Join-Path $root "docs\vo\vo_commercial_readiness.md"
$voRecordingQueuePath = Join-Path $root "docs\vo\vo_recording_queue.json"
$voRecordingQueueReportPath = Join-Path $root "docs\vo\vo_recording_queue.md"
$voRecordingPacketsPath = Join-Path $root "docs\vo\vo_recording_packets_index.json"
$voRecordingPacketsReportPath = Join-Path $root "docs\vo\vo_recording_packets_index.md"
$voMinorSpeakerTemplatePath = Join-Path $root "docs\vo\vo_minor_speaker_decisions_template.csv"
$voMinorSpeakerTemplateReportPath = Join-Path $root "docs\vo\vo_minor_speaker_decisions_template.md"
$voMinorSpeakerImportReportPath = Join-Path $root "docs\vo\vo_minor_speaker_decision_import_report.md"
$voAudioStatusPath = Join-Path $root "docs\vo\vo_audio_asset_status.json"
$voAudioStatusReportPath = Join-Path $root "docs\vo\vo_audio_asset_status.md"
$reviewDecisionTemplatePath = Join-Path $root "docs\playtest\act_i_review_decisions_template.csv"
$reviewDecisionTemplateReportPath = Join-Path $root "docs\playtest\act_i_review_decisions_template.md"
$reviewFixTrackerPath = Join-Path $root "docs\playtest\act_i_review_fix_tracker.md"
$reviewHandoffSyncPath = Join-Path $root "docs\playtest\act_i_review_handoff_sync.md"
$paintoverSourceScaffoldPath = Join-Path $root "docs\art\act_i_paintover_source_scaffold.md"
$paintoverStartGatePath = Join-Path $root "docs\art\act_i_paintover_start_gate.md"
$paintoverWorkOrderPath = Join-Path $root "docs\art\act_i_paintover_work_order.md"
$paintoverSourceIntakePath = Join-Path $root "docs\art\act_i_paintover_source_intake.md"
$finalPaintoverCompletionPath = Join-Path $root "docs\art\act_i_final_paintover_completion.md"
$paintoverReviewProvenancePath = Join-Path $root "docs\art\act_i_paintover_review_provenance.md"
$paintoverWorkOrderJsonPath = Join-Path $root "docs\art\act_i_paintover_work_order.json"
$paintoverSourceIntakeJsonPath = Join-Path $root "docs\art\act_i_paintover_source_intake.json"
$finalPaintoverCompletionJsonPath = Join-Path $root "docs\art\act_i_final_paintover_completion.json"
$paintoverReviewProvenanceJsonPath = Join-Path $root "docs\art\act_i_paintover_review_provenance.json"
$reviewDashboardPath = Join-Path $root "docs\checkpoints\step_5_review_dashboard.md"
$humanReviewBundlePath = Join-Path $root "docs\checkpoints\step_5_human_review_bundle.md"
$humanPlaytestLaunchScriptPath = Join-Path $root "tools\Validate-ActIHumanPlaytestLaunch.ps1"
$humanPlaytestShortcutPath = Join-Path $root "PLAY_ACT_I_REVIEW.cmd"
$humanPlaytestShortcutValidatorPath = Join-Path $root "tools\Validate-ActIHumanPlaytestShortcut.ps1"
$playerReviewCardPath = Join-Path $root "docs\playtest\act_i_player_review_card.md"
$playerReviewCardValidatorPath = Join-Path $root "tools\Validate-ActIPlayerReviewCard.ps1"
$checkpointPath = Join-Path $root "docs\checkpoints\step_5_act_i_art_pass_readiness.md"

foreach ($path in @(
    $backgroundStatusPath,
    $paletteAuditPath,
    $corvinStatusPath,
    $shaderMetricsPath,
    $runtimeSpriteReportPath,
    $corvinSidePriorityPath,
    $corvinSidePriorityJsonPath,
    $corvinMotionAuditPath,
    $corvinMotionAuditJsonPath,
    $corvinSideActionBlendPath,
    $corvinSideActionBlendJsonPath,
    $corvinSideActionRenderQueuePath,
    $corvinSideActionRenderQueueJsonPath,
    $corvinSideActionRenderScriptsPath,
    $corvinSideActionRenderScriptsJsonPath,
    $corvinSideActionRenderedSheetsPath,
    $corvinSideActionRenderedSheetsJsonPath,
    $corvinSideActionRenderCommandsPath,
    $corvinSideActionRenderCommandsJsonPath,
    $playtestReportPath,
    $backgroundElementPipelinePath,
    $backgroundSourceWorklistPath,
    $backgroundSourcePromptsPath,
    $backgroundSourceIntakePath,
    $lookTargetReferencePath,
    $lookTargetReferenceJsonPath,
    $backgroundSourcePlacementPath,
    $backgroundSourceDropzonesPath,
    $backgroundSourceAcquisitionPath,
    $backgroundReadySourcePacketsPath,
    $paintoverPacketPath,
    $artReadabilityReviewPath,
    $reviewContactSheetPath,
    $propCompositeContactSheetPath,
    $propCompositeContactSheetJsonPath,
    $propCompositeContactSheetImagePath,
    $propCompositeContactSheetValidatorPath,
    $atmosphereSetpiecesPath,
    $atmosphereSetpiecesJsonPath,
    $atmosphereSetpiecesImagePath,
    $atmosphereSetpiecesValidatorPath,
    $hudSkinPath,
    $hudSkinJsonPath,
    $hudSkinImagePath,
    $hudSkinValidatorPath,
    $runtimeReviewFramesPath,
    $runtimeReviewFramesJsonPath,
    $runtimeReviewFramesImagePath,
    $runtimeReviewFramesValidatorPath,
    $humanReviewNotesPath,
    $voLineManifestPath,
    $voLineManifestReportPath,
    $confessionVoManifestPath,
    $confessionVoManifestReportPath,
    $voRecordingBatchesPath,
    $voRecordingBatchesReportPath,
    $voCastPlanPath,
    $voCastPlanReportPath,
    $voCommercialReadinessPath,
    $voCommercialReadinessReportPath,
    $voRecordingQueuePath,
    $voRecordingQueueReportPath,
    $voRecordingPacketsPath,
    $voRecordingPacketsReportPath,
    $voMinorSpeakerTemplatePath,
    $voMinorSpeakerTemplateReportPath,
    $voMinorSpeakerImportReportPath,
    $voAudioStatusPath,
    $voAudioStatusReportPath,
    $reviewDecisionTemplatePath,
    $reviewDecisionTemplateReportPath,
    $reviewFixTrackerPath,
    $reviewHandoffSyncPath,
    $paintoverSourceScaffoldPath,
    $paintoverStartGatePath,
    $paintoverWorkOrderPath,
    $paintoverSourceIntakePath,
    $finalPaintoverCompletionPath,
    $paintoverReviewProvenancePath,
    $paintoverWorkOrderJsonPath,
    $paintoverSourceIntakeJsonPath,
    $finalPaintoverCompletionJsonPath,
    $paintoverReviewProvenanceJsonPath,
    $reviewDashboardPath,
    $humanReviewBundlePath,
    $humanPlaytestLaunchScriptPath,
    $humanPlaytestShortcutPath,
    $humanPlaytestShortcutValidatorPath,
    $playerReviewCardPath,
    $playerReviewCardValidatorPath
)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Step 5 readiness input: $path"
    }
}

$backgroundRows = @(Import-Csv -LiteralPath $backgroundStatusPath)
$paletteRows = @(Import-Csv -LiteralPath $paletteAuditPath)
$corvinRows = @(Import-Csv -LiteralPath $corvinStatusPath)
$shaderMetrics = Get-Content -LiteralPath $shaderMetricsPath -Raw | ConvertFrom-Json
$runtimeSpriteReport = Get-Content -LiteralPath $runtimeSpriteReportPath -Raw
$corvinSidePriority = Get-Content -LiteralPath $corvinSidePriorityPath -Raw
$corvinSidePriorityJson = Get-Content -LiteralPath $corvinSidePriorityJsonPath -Raw | ConvertFrom-Json
$corvinMotionAudit = Get-Content -LiteralPath $corvinMotionAuditPath -Raw
$corvinMotionAuditJson = Get-Content -LiteralPath $corvinMotionAuditJsonPath -Raw | ConvertFrom-Json
$corvinSideActionBlend = Get-Content -LiteralPath $corvinSideActionBlendPath -Raw
$corvinSideActionBlendJson = Get-Content -LiteralPath $corvinSideActionBlendJsonPath -Raw | ConvertFrom-Json
$corvinSideActionRenderQueue = Get-Content -LiteralPath $corvinSideActionRenderQueuePath -Raw
$corvinSideActionRenderQueueJson = Get-Content -LiteralPath $corvinSideActionRenderQueueJsonPath -Raw | ConvertFrom-Json
$corvinSideActionRenderScripts = Get-Content -LiteralPath $corvinSideActionRenderScriptsPath -Raw
$corvinSideActionRenderScriptsJson = Get-Content -LiteralPath $corvinSideActionRenderScriptsJsonPath -Raw | ConvertFrom-Json
$corvinSideActionRenderedSheets = Get-Content -LiteralPath $corvinSideActionRenderedSheetsPath -Raw
$corvinSideActionRenderedSheetsJson = Get-Content -LiteralPath $corvinSideActionRenderedSheetsJsonPath -Raw | ConvertFrom-Json
$corvinSideActionRenderCommands = Get-Content -LiteralPath $corvinSideActionRenderCommandsPath -Raw
$corvinSideActionRenderCommandsJson = Get-Content -LiteralPath $corvinSideActionRenderCommandsJsonPath -Raw | ConvertFrom-Json
$playtestReport = Get-Content -LiteralPath $playtestReportPath -Raw
$backgroundElementPipeline = Get-Content -LiteralPath $backgroundElementPipelinePath -Raw
$backgroundSourceWorklist = Get-Content -LiteralPath $backgroundSourceWorklistPath -Raw
$backgroundSourcePrompts = Get-Content -LiteralPath $backgroundSourcePromptsPath -Raw
$backgroundSourceIntake = Get-Content -LiteralPath $backgroundSourceIntakePath -Raw
$lookTargetReference = Get-Content -LiteralPath $lookTargetReferencePath -Raw
$lookTargetReferenceJson = Get-Content -LiteralPath $lookTargetReferenceJsonPath -Raw | ConvertFrom-Json
$backgroundSourcePlacement = Get-Content -LiteralPath $backgroundSourcePlacementPath -Raw
$backgroundSourceDropzones = Get-Content -LiteralPath $backgroundSourceDropzonesPath -Raw
$backgroundSourceAcquisition = Get-Content -LiteralPath $backgroundSourceAcquisitionPath -Raw
$backgroundReadySourcePackets = Get-Content -LiteralPath $backgroundReadySourcePacketsPath -Raw
$paintoverPacketReport = Get-Content -LiteralPath $paintoverPacketPath -Raw
$artReadabilityReview = Get-Content -LiteralPath $artReadabilityReviewPath -Raw
$reviewContactSheet = Get-Content -LiteralPath $reviewContactSheetPath -Raw
$propCompositeContactSheet = Get-Content -LiteralPath $propCompositeContactSheetPath -Raw
$propCompositeContactSheetJson = Get-Content -LiteralPath $propCompositeContactSheetJsonPath -Raw | ConvertFrom-Json
$atmosphereSetpieces = Get-Content -LiteralPath $atmosphereSetpiecesPath -Raw
$atmosphereSetpiecesJson = Get-Content -LiteralPath $atmosphereSetpiecesJsonPath -Raw | ConvertFrom-Json
$hudSkin = Get-Content -LiteralPath $hudSkinPath -Raw
$hudSkinJson = Get-Content -LiteralPath $hudSkinJsonPath -Raw | ConvertFrom-Json
$runtimeReviewFrames = Get-Content -LiteralPath $runtimeReviewFramesPath -Raw
$runtimeReviewFramesJson = Get-Content -LiteralPath $runtimeReviewFramesJsonPath -Raw | ConvertFrom-Json
$humanReviewNotes = Get-Content -LiteralPath $humanReviewNotesPath -Raw
$voLineManifest = Get-Content -LiteralPath $voLineManifestPath -Raw | ConvertFrom-Json
$voLineManifestReport = Get-Content -LiteralPath $voLineManifestReportPath -Raw
$confessionVoManifest = Get-Content -LiteralPath $confessionVoManifestPath -Raw | ConvertFrom-Json
$confessionVoManifestReport = Get-Content -LiteralPath $confessionVoManifestReportPath -Raw
$voRecordingBatches = Get-Content -LiteralPath $voRecordingBatchesPath -Raw | ConvertFrom-Json
$voRecordingBatchesReport = Get-Content -LiteralPath $voRecordingBatchesReportPath -Raw
$voCastPlan = Get-Content -LiteralPath $voCastPlanPath -Raw | ConvertFrom-Json
$voCastPlanReport = Get-Content -LiteralPath $voCastPlanReportPath -Raw
$voCommercialReadiness = Get-Content -LiteralPath $voCommercialReadinessPath -Raw | ConvertFrom-Json
$voCommercialReadinessReport = Get-Content -LiteralPath $voCommercialReadinessReportPath -Raw
$voRecordingQueue = Get-Content -LiteralPath $voRecordingQueuePath -Raw | ConvertFrom-Json
$voRecordingQueueReport = Get-Content -LiteralPath $voRecordingQueueReportPath -Raw
$voRecordingPackets = Get-Content -LiteralPath $voRecordingPacketsPath -Raw | ConvertFrom-Json
$voRecordingPacketsReport = Get-Content -LiteralPath $voRecordingPacketsReportPath -Raw
$voMinorSpeakerRows = @(Import-Csv -LiteralPath $voMinorSpeakerTemplatePath)
$voMinorSpeakerTemplateReport = Get-Content -LiteralPath $voMinorSpeakerTemplateReportPath -Raw
$voMinorSpeakerImportReport = Get-Content -LiteralPath $voMinorSpeakerImportReportPath -Raw
$voAudioStatus = Get-Content -LiteralPath $voAudioStatusPath -Raw | ConvertFrom-Json
$voAudioStatusReport = Get-Content -LiteralPath $voAudioStatusReportPath -Raw
$reviewDecisionRows = @(Import-Csv -LiteralPath $reviewDecisionTemplatePath)
$reviewDecisionTemplateReport = Get-Content -LiteralPath $reviewDecisionTemplateReportPath -Raw
$reviewFixTracker = Get-Content -LiteralPath $reviewFixTrackerPath -Raw
$reviewHandoffSync = Get-Content -LiteralPath $reviewHandoffSyncPath -Raw
$paintoverSourceScaffold = Get-Content -LiteralPath $paintoverSourceScaffoldPath -Raw
$paintoverStartGate = Get-Content -LiteralPath $paintoverStartGatePath -Raw
$paintoverWorkOrder = Get-Content -LiteralPath $paintoverWorkOrderPath -Raw
$paintoverSourceIntake = Get-Content -LiteralPath $paintoverSourceIntakePath -Raw
$finalPaintoverCompletion = Get-Content -LiteralPath $finalPaintoverCompletionPath -Raw
$paintoverReviewProvenance = Get-Content -LiteralPath $paintoverReviewProvenancePath -Raw
$paintoverWorkOrderJson = Get-Content -LiteralPath $paintoverWorkOrderJsonPath -Raw | ConvertFrom-Json
$paintoverSourceIntakeJson = Get-Content -LiteralPath $paintoverSourceIntakeJsonPath -Raw | ConvertFrom-Json
$finalPaintoverCompletionJson = Get-Content -LiteralPath $finalPaintoverCompletionJsonPath -Raw | ConvertFrom-Json
$paintoverReviewProvenanceJson = Get-Content -LiteralPath $paintoverReviewProvenanceJsonPath -Raw | ConvertFrom-Json
$reviewDashboard = Get-Content -LiteralPath $reviewDashboardPath -Raw
$humanReviewBundle = Get-Content -LiteralPath $humanReviewBundlePath -Raw

if ($backgroundRows.Count -ne 44) {
    throw "Act I background asset tracker expected 44 rows, got $($backgroundRows.Count)."
}

$rooms = @($backgroundRows | Group-Object room_id)
if ($rooms.Count -ne 11) {
    throw "Act I background readiness expected 11 rooms, got $($rooms.Count)."
}

foreach ($room in $rooms) {
    foreach ($kind in @("blend_blockout", "export_png", "godot_import")) {
        $row = @($room.Group | Where-Object { $_.asset_kind -eq $kind })[0]
        if ($null -eq $row) {
            throw "Room $($room.Name) is missing art asset slot $kind."
        }
        if ($row.status -ne "present") {
            throw "Room $($room.Name) art asset $kind must be present before Act I art-pass review."
        }
    }
}

$paintoverRows = @($backgroundRows | Where-Object { $_.asset_kind -eq "paintover_source" })
if ($paintoverRows.Count -ne 11) {
    throw "Expected 11 Act I paintover source rows, got $($paintoverRows.Count)."
}
$pendingPaintovers = @($paintoverRows | Where-Object { $_.status -eq "pending" })

if ($paletteRows.Count -ne 11) {
    throw "Act I palette audit expected 11 rows, got $($paletteRows.Count)."
}
$failedPaletteRows = @($paletteRows | Where-Object { $_.status -ne "audited" -or $_.pass -ne "True" })
if ($failedPaletteRows.Count -gt 0) {
    throw "Act I palette audit has failed or pending rows: $($failedPaletteRows.room_id -join ', ')"
}

$requiredCorvinAssets = @(
    "art/export/characters/corvin/act_i_clean/idle_side_right.png",
    "art/export/characters/corvin/act_i_clean/idle_side_left.png",
    "art/export/characters/corvin/act_i_clean/walk_side_right.png",
    "art/export/characters/corvin/act_i_clean/walk_side_left.png",
    "game/characters/corvin/sprites/act_i_clean/idle_side_right.png",
    "game/characters/corvin/sprites/act_i_clean/idle_side_left.png",
    "game/characters/corvin/sprites/act_i_clean/walk_side_right.png",
    "game/characters/corvin/sprites/act_i_clean/walk_side_left.png"
)
foreach ($relativePath in $requiredCorvinAssets) {
    $row = @($corvinRows | Where-Object { $_.relative_path -eq $relativePath })[0]
    if ($null -eq $row) {
        throw "Corvin animation tracker missing required side locomotion asset: $relativePath"
    }
    if ($row.status -ne "present") {
        throw "Corvin required side locomotion asset is not present: $relativePath"
    }
}

if ($shaderMetrics.status -ne "audited") {
    throw "Ink shader yaw metrics must be audited before Act I art-pass readiness: $($shaderMetrics.status)"
}
$objectPairwiseMax = [double]$shaderMetrics.object_sequence.pairwise_max_percent
$objectFirstLastDrift = [double]$shaderMetrics.object_sequence.first_to_last_drift_percent
$badControlPairwiseMax = [double]$shaderMetrics.bad_control_sequence.pairwise_max_percent
$pairwiseThreshold = [double]$shaderMetrics.pairwise_threshold_percent
$firstLastThreshold = [double]$shaderMetrics.first_to_last_drift_threshold_percent
if ($objectPairwiseMax -gt $pairwiseThreshold) {
    throw "Ink shader object-anchored pairwise delta exceeds threshold."
}
if ($objectFirstLastDrift -gt $firstLastThreshold) {
    throw "Ink shader object-anchored first-last drift exceeds threshold."
}

foreach ($requiredText in @(
    "side_right_side_left_idle_walk_talk_use_wet_switchable_with_current_side_actions",
    "Current-side idle: implemented_character_bridge_alias",
    "Current-side actions: implemented_character_bridge_aliases"
)) {
    if ($runtimeSpriteReport -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin runtime sprite report missing required readiness text: $requiredText"
    }
}

$corvinSidePriorityRows = @($corvinSidePriorityJson.work_order)
if ($corvinSidePriorityJson.status -ne "side_action_sheets_present_pending_polish") {
    throw "Corvin side-priority work order has unexpected status: $($corvinSidePriorityJson.status)"
}
if ($corvinSidePriorityRows.Count -ne 20 -or [int]$corvinSidePriorityJson.counts.present -ne 20 -or [int]$corvinSidePriorityJson.counts.pending -ne 0) {
    throw "Corvin side-priority work order expected 20 rows, 20 present, 0 pending."
}
if ([int]$corvinSidePriorityJson.counts.runtime_present -ne 8 -or [int]$corvinSidePriorityJson.counts.side_action_present -ne 12 -or [int]$corvinSidePriorityJson.counts.next_pending -ne 0) {
    throw "Corvin side-priority work order expected 8 runtime-present rows, 12 side-action-present rows, and 0 next-pending rows."
}
foreach ($requiredText in @(
    "Corvin Side Priority Work Order",
    "Current playable side locomotion",
    "Side action sheets present pending polish",
    "talk_side_right",
    "use_side_left",
    "wet_side_right",
    "Do not use diffusion-per-frame character sheets"
)) {
    if ($corvinSidePriority -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side-priority work order missing readiness text: $requiredText"
    }
}

$corvinMotionRows = @($corvinMotionAuditJson.rows)
if ($corvinMotionAuditJson.status -ne "motion_sources_audited_wet_custom_required") {
    throw "Corvin Meshy motion source audit has unexpected status: $($corvinMotionAuditJson.status)"
}
foreach ($requiredMotion in @("talk", "use", "walk")) {
    $row = @($corvinMotionRows | Where-Object { $_.target_animation -eq $requiredMotion })[0]
    if ($null -eq $row -or $row.audit_status -ne "audited_motion_source" -or [int]$row.mesh_count -lt 1 -or [int]$row.armature_count -lt 1 -or [int]$row.action_count -lt 1) {
        throw "Corvin Meshy motion source audit must prove action-capable $requiredMotion source material."
    }
}
$wetMotion = @($corvinMotionRows | Where-Object { $_.target_animation -eq "wet" })[0]
if ($null -eq $wetMotion -or $wetMotion.source_role -ne "custom_required" -or $wetMotion.audit_status -ne "not_run") {
    throw "Corvin wet motion must remain custom_required."
}
foreach ($requiredText in @(
    "Corvin Meshy Motion Source Audit",
    "No PNG sheet is created by this audit",
    "Wet remains custom-required",
    "talk",
    "use",
    "walk",
    "wet"
)) {
    if ($corvinMotionAudit -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin Meshy motion source audit missing readiness text: $requiredText"
    }
}

$corvinSideActionBlendRows = @($corvinSideActionBlendJson.actions)
if ($corvinSideActionBlendJson.status -ne "authored_actions_pending_render_audit") {
    throw "Corvin side action blend has unexpected status: $($corvinSideActionBlendJson.status)"
}
if ($corvinSideActionBlendJson.blend_path -ne "art/src/characters/corvin/corvin_act_i_clean_side_actions.blend" -or [int]$corvinSideActionBlendJson.armature_count -ne 1 -or [int]$corvinSideActionBlendJson.mesh_count -lt 1 -or [int]$corvinSideActionBlendJson.bone_count -lt 20) {
    throw "Corvin side action blend must prove a valid authored action rig."
}
foreach ($requiredAction in @("Corvin_act_i_clean_talk_side", "Corvin_act_i_clean_use_side", "Corvin_act_i_clean_wet_side")) {
    if ($requiredAction -notin @($corvinSideActionBlendRows | ForEach-Object { $_.name })) {
        throw "Corvin side action blend missing action: $requiredAction"
    }
}
foreach ($requiredText in @(
    "Corvin Side Action Blend Status",
    "This tool authors Blender action source only",
    "Talk and use are hand-authored readable side-view gameplay poses after Meshy motion proved too subtle",
    "Wet is hand-authored as a custom physical brine action",
    "corvin_act_i_clean_side_actions.blend"
)) {
    if ($corvinSideActionBlend -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action blend report missing readiness text: $requiredText"
    }
}

$corvinSideActionRows = @($corvinSideActionRenderQueueJson.rows)
if ($corvinSideActionRenderQueueJson.status -ne "render_outputs_present_pending_audit") {
    throw "Corvin side action render queue has unexpected status: $($corvinSideActionRenderQueueJson.status)"
}
if ($corvinSideActionRows.Count -ne 6 -or [int]$corvinSideActionRenderQueueJson.pending_render_count -ne 0 -or [int]$corvinSideActionRenderQueueJson.sheet_present_count -ne 6 -or [int]$corvinSideActionRenderQueueJson.godot_present_count -ne 6) {
    throw "Corvin side action render queue expected 6 rendered sheet/import rows."
}
foreach ($requiredText in @(
    "Corvin Side Action Render Queue",
    "Do not create placeholder PNGs",
    "Only deterministic Blender renders",
    "Godot imports must be byte-for-byte copied",
    "No arterial red may appear in wet brine frames",
    "Sheet outputs present: 6",
    "Godot imports present: 6",
    "talk",
    "use",
    "wet"
)) {
    if ($corvinSideActionRenderQueue -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action render queue missing readiness text: $requiredText"
    }
}

$corvinSideActionScriptRows = @($corvinSideActionRenderScriptsJson.scripts)
if ($corvinSideActionRenderScriptsJson.status -notin @("blocked_pending_keyed_blender_actions", "audit_contract_passed", "static_ready_blender_not_resolved", "partial_audit_pending")) {
    throw "Corvin side action render scripts has unexpected status: $($corvinSideActionRenderScriptsJson.status)"
}
if ($corvinSideActionScriptRows.Count -ne 6 -or [int]$corvinSideActionRenderScriptsJson.script_count -ne 6) {
    throw "Corvin side action render scripts expected 6 script rows."
}
foreach ($requiredText in @(
    "Corvin Side Action Render Scripts Status",
    "Audit mode must not create PNG sheet outputs",
    "Render scripts must fail if the named Blender action is absent",
    "Sheet assembly must refuse blank frame outputs",
    "No placeholder PNGs are permitted",
    "talk",
    "use",
    "wet"
)) {
    if ($corvinSideActionRenderScripts -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action render scripts missing readiness text: $requiredText"
    }
}

$corvinSideActionRenderedSheetRows = @($corvinSideActionRenderedSheetsJson.rows)
if ($corvinSideActionRenderedSheetsJson.status -ne "rendered_sheets_audited") {
    throw "Corvin side action rendered-sheet audit has unexpected status: $($corvinSideActionRenderedSheetsJson.status)"
}
if ($corvinSideActionRenderedSheetRows.Count -ne 6 -or [int]$corvinSideActionRenderedSheetsJson.passed_count -ne 6 -or [int]$corvinSideActionRenderedSheetsJson.failed_count -ne 0) {
    throw "Corvin side action rendered-sheet audit expected 6 passing rows."
}
foreach ($row in $corvinSideActionRenderedSheetRows) {
    if (-not [bool]$row.byte_for_byte_import -or [int]$row.nonblank_frame_count -ne [int]$row.frames -or -not [bool]$row.profile_silhouette_pass -or -not [bool]$row.motion_readability_pass) {
        throw "Corvin side action rendered-sheet audit row failed import/nonblank/profile/motion proof: $($row.animation) $($row.direction)"
    }
}
foreach ($requiredText in @(
    "Corvin Side Action Rendered Sheets Audit",
    "Status: rendered_sheets_audited",
    "Side sheets must read as profile silhouettes",
    "Action sheets must show readable motion",
    "This audit does not approve final animation polish",
    "Wet sheets must contain zero arterial red samples",
    "talk",
    "use",
    "wet"
)) {
    if ($corvinSideActionRenderedSheets -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action rendered-sheet audit missing readiness text: $requiredText"
    }
}

$corvinSideActionCommandsRows = @($corvinSideActionRenderCommandsJson.commands)
if ($corvinSideActionRenderCommandsJson.status -notin @("ready_for_render_scripts", "blocked_blender_not_resolved")) {
    throw "Corvin side action render commands has unexpected status: $($corvinSideActionRenderCommandsJson.status)"
}
if ($corvinSideActionCommandsRows.Count -ne 6 -or [int]$corvinSideActionRenderCommandsJson.command_count -ne 6 -or [int]$corvinSideActionRenderCommandsJson.timeout_seconds -ne 120) {
    throw "Corvin side action render commands expected 6 commands with 120 second timeout."
}
foreach ($requiredText in @(
    "Corvin Side Action Render Commands",
    "deterministic render handoff commands",
    "Do not create placeholder PNGs",
    "byte-for-byte",
    "Run the render queue validator after each import",
    "Timeout-wrapped command",
    "talk side_right",
    "use side_left",
    "wet side_right"
)) {
    if ($corvinSideActionRenderCommands -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin side action render commands missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    'Transition animation: `walk_side_right`',
    'direction-aware transition animations',
    'idle_current_side'
)) {
    if ($playtestReport -notmatch [regex]::Escape($requiredText)) {
        throw "Automated Act I report missing required animation-readiness evidence: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Element Pipeline",
    "Meshy helps with reusable source props",
    "generated images are reference only",
    "Interactive objects stay separate",
    "Do not use Meshy as the main background generator.",
    "Grey Float stays hard-R"
)) {
    if ($backgroundElementPipeline -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background element pipeline missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Source Worklist",
    "Status: pending source assets",
    "Meshy source models are helper assets only",
    "Generated references are concept/reference only",
    "Interactive layers must remain separate",
    "Navigation silhouettes are readability tasks"
)) {
    if ($backgroundSourceWorklist -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background source worklist missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Source Prompts",
    "Status: pending generation",
    "Meshy prompts create isolated helper GLB props only",
    "imagegen prompts create reference boards only",
    "Interactive layer prompts preserve existing hotspot centers",
    "These prompts do not approve final art"
)) {
    if ($backgroundSourcePrompts -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background source prompts missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Source Intake",
    "Source prompt outputs do not count as final background art",
    "Meshy GLBs are helper geometry",
    "Generated references are paintover references only",
    "Zero-byte source outputs fail intake"
)) {
    if ($backgroundSourceIntake -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background source intake missing readiness text: $requiredText"
    }
}

if ($lookTargetReferenceJson.status -ne "reference_only_review_target") {
    throw "Act I look target reference has unexpected status: $($lookTargetReferenceJson.status)"
}
if ([int]$lookTargetReferenceJson.width -ne 1672 -or [int]$lookTargetReferenceJson.height -ne 941) {
    throw "Act I look target reference expected 1672x941 image."
}
foreach ($requiredText in @(
    "Act I Look Target Reference",
    "mood, palette, staging, and side-on adventure-game readability reference",
    "Not a final room plate.",
    "Generated images remain reference only",
    "Blender greybox and paintover remain authoritative",
    "deterministic 3D-to-Blender-to-2D"
)) {
    if ($lookTargetReference -notmatch [regex]::Escape($requiredText)) {
        throw "Act I look target reference missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Source Placement",
    "Placement does not approve final art",
    "Meshy source models enter Blender as helper geometry only",
    "Generated references enter reference boards only",
    "Interactive layers must export separate runtime PNGs and preserve Godot hotspot metadata",
    "Navigation silhouettes must preserve existing exit metadata and walk-band readability"
)) {
    if ($backgroundSourcePlacement -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background source placement missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Source Dropzones",
    "Drop-zone README files are scaffolds only",
    "Do not create placeholder binary outputs",
    "Generated source outputs remain pending until real nonzero files appear in intake",
    "Meshy and generated references still cannot count as final room art",
    "Interactive and navigation source files still require their later runtime and Godot alignment gates"
)) {
    if ($backgroundSourceDropzones -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background source dropzones missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Source Acquisition Checklist",
    "Acquire Meshy helper GLBs and generated reference boards before room approval if useful",
    "Hold interactive and navigation PSD source work until the room passes human art review",
    "Do not batch-generate final backgrounds",
    "Do not create placeholder binary outputs",
    "A received source file remains unreviewed until intake, placement, and its handoff gate pass"
)) {
    if ($backgroundSourceAcquisition -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background source acquisition missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Background Ready Source Packets",
    "Packets include ready-to-generate source assets only",
    "Packets exclude interactive and navigation PSD work",
    "Packets must not be used to generate final background plates",
    "Outputs must be saved exactly to the listed source paths",
    "Run source intake again after files are saved"
)) {
    if ($backgroundReadySourcePackets -notmatch [regex]::Escape($requiredText)) {
        throw "Act I background ready source packets missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Paintover Packet",
    "Scope: Act I only",
    "Registrar duel art must preserve the accepted Litany UI format",
    "Hard-R line remains locked"
)) {
    if ($paintoverPacketReport -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover packet missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Art Readability Review",
    "Proceed to paintovers: yes / no",
    "Contact sheet reviewed: yes / no",
    "Corvin side-action contact sheet reviewed: yes / no",
    "Corvin live verb animations tested in room: yes / no",
    "Decision CSV date format checked: yes / no",
    "Corvin's live side actions read in context: talk gestures, use reach, and wet brine/drip intent.",
    "Corvin talk/use/wet side actions read without scale jitter or wrong-facing snaps",
    "Registrar duel staging preserves accepted Litany format",
    "Hard-R Float staging stays steam/silhouette/privacy only"
)) {
    if ($artReadabilityReview -notmatch [regex]::Escape($requiredText)) {
        throw "Act I art readability review missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Review Contact Sheet",
    "accepted Litany/Registrar duel format",
    "Grey Float stays hard-R",
    "review evidence, not final paintover approval"
)) {
    if ($reviewContactSheet -notmatch [regex]::Escape($requiredText)) {
        throw "Act I review contact sheet missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Human Review Notes",
    "Greybox Playtest",
    "Art Readability Review",
    "Proceed to paintovers: yes / no"
)) {
    if ($humanReviewNotes -notmatch [regex]::Escape($requiredText)) {
        throw "Act I human review notes missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I VO Line Manifest",
    "recording/editing plan for full VO timing",
    "Dialogue lines are generated from Ink; do not duplicate confession text here.",
    "Confession VO remains keyed by `data/confessions.json` ids.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($voLineManifestReport -notmatch [regex]::Escape($requiredText)) {
        throw "Act I VO line manifest report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Confession VO Manifest",
    "One confession line and one elaboration line are required for every confession.",
    "Audio paths must stay keyed by confession id",
    'Generated text comes from `data/confessions.json`; Ink references confession ids only.',
    "Keep the accepted Litany/Registrar duel format and global spend rules."
)) {
    if ($confessionVoManifestReport -notmatch [regex]::Escape($requiredText)) {
        throw "Confession VO manifest report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Recording Batches",
    "Generated at UTC:",
    "Source modified UTC:",
    "Do not generate VO line-by-line in isolation.",
    "Scene VO batches are speaker runs grouped by Ink knot and kept in source order.",
    "Litany batches keep each confession immediately followed by its elaboration.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($voRecordingBatchesReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO recording batch report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Cast Plan",
    "Generated at UTC:",
    "Source modified UTC:",
    "manifest-driven scratch VO cast plan",
    "Shipping status: scratch_only_licensing_unverified",
    "Scratch voices are timing/casting references only until commercial licensing is verified.",
    "Do not start scratch generation for batches whose speaker remains pending.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($voCastPlanReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO cast plan report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Commercial Readiness",
    "Generated at UTC:",
    "Source modified UTC:",
    "Status: blocked_pending_licensing_review",
    "Shipping approved: false",
    "Scratch voices are timing/casting references only until commercial licensing is verified.",
    "Do not count present audio as shippable without licensing/disclosure evidence.",
    "Do not start scratch generation for batches whose speaker remains pending or blocked for cut/rewrite.",
    "Minor speakers blocked for cut/rewrite: 0",
    "Minor speaker work blockers: 8",
    "Written confirmation that each scratch/final voice may be used in a commercial game"
)) {
    if ($voCommercialReadinessReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO commercial readiness report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Recording Queue",
    "Generated at UTC:",
    "Source modified UTC:",
    "Scratch-ready batches: 119",
    "Blocked batches: 17",
    "Cut/rewrite blocked batches: 0",
    "Only scratch_ready batches may be generated for timing tests.",
    "blocked_pending_cast_decision batches must not be generated.",
    "blocked_cut_or_rewrite batches must not be generated until script changes are made.",
    "Scratch output is not shipping audio and remains blocked by VO commercial readiness.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($voRecordingQueueReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO recording queue report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Recording Packets Index",
    "Generated at UTC:",
    "Source modified UTC:",
    "Packet count: 119",
    "Blocked packet count: 0",
    "Cut/rewrite packet count: 0",
    "Lines in packets: 600",
    "Only scratch-ready batches get recording packets.",
    "Blocked pending-cast batches must not get packet files.",
    "Cut/rewrite blocked batches must not get packet files.",
    "Scratch packets are not shipping audio approval.",
    "Keep the accepted Litany/Registrar duel format."
)) {
    if ($voRecordingPacketsReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO recording packet index report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Minor Speaker Decision Template",
    "make minor-speaker casting and consolidation decisions explicit",
    "Every non-pending decision requires notes explaining the casting, consolidation, or script-change rationale.",
    "Do not start scratch generation for batches whose speaker remains pending."
)) {
    if ($voMinorSpeakerTemplateReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO minor speaker decision template missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Minor Speaker Decision Import Report",
    "Mode: dry_run",
    "Rule locks:",
    "Do not start scratch generation for batches whose speaker remains pending."
)) {
    if ($voMinorSpeakerImportReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO minor speaker decision import report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "VO Audio Asset Status",
    "Generated at UTC:",
    "Source modified UTC:",
    "Expected audio paths are generated from VO manifests.",
    "Scratch-ready expected MP3s come from the VO recording queue.",
    "Blocked pending-cast and cut/rewrite audio paths must not have MP3 files yet.",
    "Generated recording packets cover scratch-ready batches only.",
    "Scratch-ready expected: 600",
    "Blocked expected: 52",
    "Pending-cast blocked expected: 52",
    "Cut/rewrite blocked expected: 0",
    "Present blocked: 0",
    "Missing audio is allowed during planning; it must not be counted as recorded.",
    "Zero-byte expected MP3 files fail validation.",
    'Unplanned MP3 files under `vo/` fail validation.'
)) {
    if ($voAudioStatusReport -notmatch [regex]::Escape($requiredText)) {
        throw "VO audio status report missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Review Fix Tracker",
    "Global unresolved state",
    "duel_format_lock",
    "hard_r_float_staging"
)) {
    if ($reviewFixTracker -notmatch [regex]::Escape($requiredText)) {
        throw "Act I review fix tracker missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Review Handoff Sync",
    "Tracker rooms: 11",
    "Decision CSV rows: 11",
    "Latest notes must include the accepted Litany/Registrar duel-format prompt.",
    "Latest notes must include the Grey Float hard-R staging prompt.",
    "Dashboard must list the stable latest notes, decision CSV, review tracker, contact sheet, Corvin side-action contact sheet, and ready-source packet artifacts."
)) {
    if ($reviewHandoffSync -notmatch [regex]::Escape($requiredText)) {
        throw "Act I review handoff sync missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Review Decision Template",
    "machine-readable batch handoff",
    "Allowed decisions: pending_review, approved, revise_before_art, stop_and_redesign.",
    "YYYY-MM-DD",
    "corvin_action_scaffold_reviewed",
    "Harbor Registry approval must preserve the accepted Litany/Registrar duel format.",
    "Harbor Registry non-pending decisions must include a duel_format note",
    "Grey Float non-pending decisions must include a content_compliance note confirming hard-R staging"
)) {
    if ($reviewDecisionTemplateReport -notmatch [regex]::Escape($requiredText)) {
        throw "Act I review decision template missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Paintover Source Scaffold",
    "must not be counted as paintover completion",
    "Status Remains"
)) {
    if ($paintoverSourceScaffold -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover source scaffold missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Paintover Start Gate",
    "Status:",
    "Ready rooms:",
    "Blocked rooms:"
)) {
    if ($paintoverStartGate -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover start gate missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Paintover Work Order",
    "Ready rooms in work order:",
    "Do not create placeholder PSDs",
    "Accepted Litany/Registrar duel format remains locked",
    "Grey Float remains hard-R"
)) {
    if ($paintoverWorkOrder -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover work order missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Paintover Source Intake",
    "Unapproved present:",
    "A PSD can count only when the room appears in the approved-room work order",
    "Accepted Litany/Registrar duel format remains locked",
    "Grey Float remains hard-R"
)) {
    if ($paintoverSourceIntake -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover source intake missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Final Paintover Completion",
    "Existing greybox PNGs do not count as final paintover exports",
    "exported PNG is newer than that PSD",
    "Accepted Litany/Registrar duel format remains locked",
    "Grey Float remains hard-R"
)) {
    if ($finalPaintoverCompletion -notmatch [regex]::Escape($requiredText)) {
        throw "Act I final paintover completion missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Act I Paintover Review Provenance",
    "human-review proof survives every final-art handoff layer",
    "Start gate, work order, source intake, and final completion proof must match the tracker proof exactly"
)) {
    if ($paintoverReviewProvenance -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover review provenance missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Step 5 Review Dashboard",
    "Generated at UTC:",
    "Source modified UTC:",
    "Readiness state: green_for_review",
    "Paintover gate status:",
    "Do not start final paintovers while the start gate reports blocked_pending_human_review.",
    "accepted Litany/Registrar duel format",
    "Grey Float hard-R",
    "Test VO commercial readiness against stale upstream inputs."
)) {
    if ($reviewDashboard -notmatch [regex]::Escape($requiredText)) {
        throw "Step 5 review dashboard missing readiness text: $requiredText"
    }
}

foreach ($requiredText in @(
    "Step 5 Human Review Bundle",
    "Readiness state: green_for_review",
    "Launch review:",
    "Dry-run decisions:",
    "accepted Litany/Registrar duel format",
    "Grey Float hard-R",
    "Room Status"
)) {
    if ($humanReviewBundle -notmatch [regex]::Escape($requiredText)) {
        throw "Step 5 human review bundle missing readiness text: $requiredText"
    }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $propCompositeContactSheetValidatorPath
if ($LASTEXITCODE -ne 0) {
    throw "Act I OpenAI prop composite contact-sheet validator failed."
}

if ($propCompositeContactSheetJson.status -ne "exported" -or [int]$propCompositeContactSheetJson.room_count -ne 11) {
    throw "Act I OpenAI prop composite contact sheet must export 11 Act I room composites."
}
foreach ($requiredText in @(
    "Act I OpenAI Prop Composite Contact Sheet",
    "runtime-room composite",
    "Act I background rooms only",
    "hard-R, no explicit anatomy, no gore, no bodies, no child figures"
)) {
    if ($propCompositeContactSheet -notmatch [regex]::Escape($requiredText)) {
        throw "Act I OpenAI prop composite contact-sheet report missing required text: $requiredText"
    }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $atmosphereSetpiecesValidatorPath
if ($LASTEXITCODE -ne 0) {
    throw "Act I atmosphere setpiece validator failed."
}

if ($atmosphereSetpiecesJson.status -ne "exported" -or [int]$atmosphereSetpiecesJson.count -ne 5) {
    throw "Act I atmosphere setpieces must export 5 runtime overlays."
}
foreach ($requiredText in @(
    "Act I Atmosphere Setpieces",
    "OpenAI room plates",
    "water glint, lamp flicker, smoke, steam, and window rain",
    "hard-R, no explicit anatomy, no gore, no child figures"
)) {
    if ($atmosphereSetpieces -notmatch [regex]::Escape($requiredText)) {
        throw "Act I atmosphere setpiece report missing required text: $requiredText"
    }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $hudSkinValidatorPath
if ($LASTEXITCODE -ne 0) {
    throw "Act I OpenAI HUD skin validator failed."
}

if ($hudSkinJson.status -ne "imported" -or [int]$hudSkinJson.asset_count -ne 5) {
    throw "Act I OpenAI HUD skin must import 5 runtime UI assets."
}
foreach ($requiredText in @(
    "Act I OpenAI HUD Skin",
    "OpenAI-generated noir harbor UI texture sheet",
    "decorative HUD frames only",
    "hard-R, no explicit anatomy, no gore, no bodies, no child figures"
)) {
    if ($hudSkin -notmatch [regex]::Escape($requiredText)) {
        throw "Act I HUD skin report missing required text: $requiredText"
    }
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $runtimeReviewFramesValidatorPath
if ($LASTEXITCODE -ne 0) {
    throw "Act I runtime review frame validator failed."
}

if ($runtimeReviewFramesJson.status -ne "exported" -or [int]$runtimeReviewFramesJson.frame_count -ne 8) {
    throw "Act I runtime review frames must export 8 player-view frames."
}
foreach ($requiredText in @(
    "Act I Runtime Review Frames",
    "runtime room composites",
    "Corvin side sprites",
    "generated noir HUD skin",
    "looks like an in-game screen"
)) {
    if ($runtimeReviewFrames -notmatch [regex]::Escape($requiredText)) {
        throw "Act I runtime review frame report missing required text: $requiredText"
    }
}

$backgroundPresent = @($backgroundRows | Where-Object { $_.status -eq "present" }).Count
$backgroundPending = @($backgroundRows | Where-Object { $_.status -eq "pending" }).Count
$corvinPresent = @($corvinRows | Where-Object { $_.status -eq "present" }).Count
$corvinPending = @($corvinRows | Where-Object { $_.status -eq "pending" }).Count
$redSceneCount = @($paletteRows | Where-Object { [int]$_.arterial_red_pixels -gt 0 }).Count
$workOrderReadyCount = [int]$paintoverWorkOrderJson.ready_room_count
$workOrderBlockedCount = [int]$paintoverWorkOrderJson.blocked_room_count
$intakeAcceptedCount = [int]$paintoverSourceIntakeJson.accepted_present_count
$intakeUnapprovedCount = [int]$paintoverSourceIntakeJson.unapproved_present_count
$completionCompleteCount = [int]$finalPaintoverCompletionJson.complete_count
$completionPendingExportCount = [int]$finalPaintoverCompletionJson.pending_final_export_count
$completionBlockedCount = [int]$finalPaintoverCompletionJson.blocked_not_started_count
$provenanceApprovedCount = [int]$paintoverReviewProvenanceJson.approved_count
$provenanceWorkOrderCount = [int]$paintoverReviewProvenanceJson.work_order_count
$provenanceAcceptedCount = [int]$paintoverReviewProvenanceJson.accepted_source_count
$provenanceCompletionApprovedCount = [int]$paintoverReviewProvenanceJson.completion_approved_count
$voLineCount = [int]$voLineManifest.line_count
$voRecordableLineCount = [int]$voLineManifest.vo_line_count
$voStageDirectionCount = [int]$voLineManifest.stage_direction_count
$voSpeakerCount = [int]$voLineManifest.speaker_count
$voUncastSpeakerCount = [int]$voLineManifest.uncast_speaker_count
$confessionVoConfessionCount = [int]$confessionVoManifest.confession_count
$confessionVoLineCount = [int]$confessionVoManifest.line_count
$confessionVoWordCount = [int]$confessionVoManifest.word_count
$confessionVoElaborationLineCount = [int]$confessionVoManifest.elaboration_line_count
$voBatchCount = [int]$voRecordingBatches.batch_count
$voBatchLineCount = [int]$voRecordingBatches.line_count
$voBatchWordCount = [int]$voRecordingBatches.word_count
$voUncastBatchCount = [int]$voRecordingBatches.uncast_batch_count
$voCastSpeakerCount = [int]$voCastPlan.speaker_count
$voScratchCastCount = [int]$voCastPlan.scratch_cast_count
$voNeedsCastDecisionCount = [int]$voCastPlan.needs_cast_decision_count
$voCommercialStatus = [string]$voCommercialReadiness.status
$voCommercialBlockerCount = @($voCommercialReadiness.blockers).Count
$voQueueReadyBatchCount = [int]$voRecordingQueue.scratch_ready_batch_count
$voQueueBlockedBatchCount = [int]$voRecordingQueue.blocked_batch_count
$voQueueReadyLineCount = [int]$voRecordingQueue.scratch_ready_line_count
$voQueueBlockedLineCount = [int]$voRecordingQueue.blocked_line_count
$voPacketCount = [int]$voRecordingPackets.packet_count
$voBlockedPacketCount = [int]$voRecordingPackets.blocked_packet_count
$voPacketLineCount = [int]$voRecordingPackets.line_count
$voMinorSpeakerCount = $voMinorSpeakerRows.Count
$voAudioExpectedCount = [int]$voAudioStatus.expected_count
$voAudioScratchReadyCount = [int]$voAudioStatus.scratch_ready_expected_count
$voAudioBlockedCount = [int]$voAudioStatus.blocked_expected_count
$voAudioPresentBlockedCount = [int]$voAudioStatus.present_blocked_count
$voAudioPresentCount = [int]$voAudioStatus.present_count
$voAudioMissingCount = [int]$voAudioStatus.missing_count
$reviewDecisionRoomCount = $reviewDecisionRows.Count
$propCompositeRoomCount = [int]$propCompositeContactSheetJson.room_count
$atmosphereSetpieceCount = [int]$atmosphereSetpiecesJson.count
$hudSkinAssetCount = [int]$hudSkinJson.asset_count
$runtimeReviewFrameCount = [int]$runtimeReviewFramesJson.frame_count

$lines = @(
    "CHECKPOINT: Step 5 entry - Act I Art-Pass Readiness",
    "GATES:",
    "- Act I background blockouts: pass, 11 rooms have present Blender blockout, exported PNG, and Godot import slots.",
    "- Act I background asset tracker: pass, $backgroundPresent present / $backgroundPending pending / $($backgroundRows.Count) total; pending rows are paintover sources, not missing greybox blockouts.",
    "- G9/G10 palette audit: pass, $($paletteRows.Count) exported backgrounds audited, 0 failed, arterial red appears in $redSceneCount scenes against the 5-scene limit.",
    "- Corvin Act I side locomotion: pass, side-left and side-right idle/walk sheet exports and Godot imports are present and runtime-validated.",
    "- Corvin side-priority work order: pass, 8 side idle/walk runtime rows and 12 Act I side talk/use/wet rows are present; talk/use/wet now need Godot registration and final animation polish before front/back or decay work.",
    "- Corvin Meshy motion source audit: pass, talk/use/walk source GLBs are action-capable and wet remains custom-required before canonical Blender action authoring.",
    "- Corvin side-action blend: pass, authored side-action Blender source contains talk/use/wet actions and a valid 24-bone rig; rendered PNG sheets are audited separately.",
    "- Corvin side-action render queue: pass, 6 deterministic Blender render/import rows for Act I talk/use/wet are present and pending final polish review with placeholder PNGs forbidden and post-render checks defined.",
    "- Corvin side-action render scripts: pass, 6 Blender entrypoints exist, refuse blank sheet assembly, and audit clean; status is $($corvinSideActionRenderScriptsJson.status) with $([int]$corvinSideActionRenderScriptsJson.missing_keyed_action_count) missing keyed actions.",
    "- Corvin side-action render commands: pass, 6 deterministic Blender command handoffs exist with 120-second timeout wrapping, byte-for-byte Godot import commands, and queue audit commands.",
    "- Corvin side-action rendered sheets: pass, 6 exported sheets and 6 byte-for-byte Godot imports pass dimension, nonblank-frame, profile-silhouette, motion-readability, and wet arterial-red audits; final animation polish is still not approved.",
    "- Corvin animation tracker: pass, $corvinPresent present / $corvinPending pending / $($corvinRows.Count) total; remaining pending rows are the broader production contract, not required for side-on Act I greybox review.",
    "- Ink shader yaw metrics: pass, status audited, object pairwise max $objectPairwiseMax% against threshold $pairwiseThreshold%, first-last drift $objectFirstLastDrift% against threshold $firstLastThreshold%; bad-control pairwise max $badControlPairwiseMax% remains the calibration contrast.",
    "- Automated Act I playtest evidence: pass, the report records direction-aware transition animation evidence and current-side idle arrival behavior.",
    "- Act I background element pipeline: pass, generated source contract keeps Blender greybox/paintover authoritative, limits Meshy to source-prop help, limits generated images to reference, and keeps logic-touched elements separate.",
    "- Act I background source worklist: pass, generated pending task list tracks Meshy helper models, generated reference boards, separate interactive layers, and navigation silhouettes before final paintover starts.",
    "- Act I background source prompts: pass, generated guarded prompts cover Meshy helper GLBs, imagegen reference boards, and paintover/runtime-layer tasks without approving final art.",
    "- Act I background source intake: pass, generated source-output intake keeps prompt outputs pending/present without treating Meshy, imagegen, or paintover sources as final room art.",
    "- Act I look target reference: pass, generated harbor reference is tracked as a $($lookTargetReferenceJson.status) at $($lookTargetReferenceJson.width)x$($lookTargetReferenceJson.height), with guardrails against final-room-plate, hotspot-coordinate, Blender-greybox, or diffusion-per-frame character use.",
    "- Act I background source placement: pass, generated placement map routes source outputs into Blender helper geometry, reference boards, separate runtime layers, or navigation readability review without approving final art.",
    "- Act I background source dropzones: pass, generated source-output folders and README scaffolds exist without creating placeholder binary files or approving final art.",
    "- Act I background source acquisition: pass, generated per-room checklist marks Meshy/reference outputs ready to acquire now and holds interactive/navigation PSD work for human room review.",
    "- Act I background ready source packets: pass, generated 22 room/tool packets for the 84 Meshy/imagegen source items safe to acquire now while excluding held interactive/navigation PSD work.",
    "- Act I paintover packet: pass, generated per-room final-paintover instructions preserve hotspot coordinates, walk-band constraints, palette rules, Grey Float hard-R staging, and Registrar duel-format lock.",
    "- Act I art readability review: pass, generated room-by-room review checklist covers brightest-object readability, walk-band clarity, wet targets, confession-source staging, Grey Float hard-R checks, and Registrar duel-format risk.",
    "- Act I review contact sheet: pass, generated browser contact sheet shows all 11 blockouts with walk bands, marker positions, hotspot tables, duel-format lock, and Grey Float hard-R lock.",
    "- Act I OpenAI prop composite contact sheet: pass, generated review PNG shows $propCompositeRoomCount runtime room composites with palette-locked OpenAI foreground props across every Act I background room.",
    "- Act I atmosphere setpieces: pass, $atmosphereSetpieceCount transparent runtime overlays add water glint, lamp flicker, smoke, steam, and window rain to OpenAI room plates without changing puzzle coordinates.",
    "- Act I OpenAI HUD skin: pass, $hudSkinAssetCount generated noir UI texture assets are imported and wired into the playable prologue HUD without storing dialogue or puzzle state in image files.",
    "- Act I runtime review frames: pass, $runtimeReviewFrameCount player-view frames composite runtime room art, Corvin side sprites, NPC standees, first-frame atmosphere/setpieces, contact shadows, and the generated HUD skin.",
    "- Act I human review notes: pass, generated combined review notes include the greybox playtest rubric and the art readability checklist for the same Step 5 run.",
    "- Act I VO timing manifest: pass, $voLineCount Ink-derived lines across $voSpeakerCount speakers; $voRecordableLineCount recordable VO lines, $voStageDirectionCount stage-direction review lines, and $voUncastSpeakerCount minor speakers needing cast/consolidation decisions before final recording.",
    "- Confession VO manifest: pass, $confessionVoConfessionCount confessions produce $confessionVoLineCount unrecorded Corvin VO lines, including $confessionVoElaborationLineCount elaboration lines, with $confessionVoWordCount words keyed by confession id.",
    "- VO recording batches: pass, $voBatchCount batches cover $voBatchLineCount recordable lines and $voBatchWordCount words, with $voUncastBatchCount batches blocked on minor-speaker cast/consolidation decisions.",
    "- VO cast plan: pass, $voCastSpeakerCount speakers tracked, $voScratchCastCount scratch-cast and $voNeedsCastDecisionCount needing cast/consolidation decisions; scratch voices remain licensing-unverified and pending speakers block scratch generation.",
    "- VO commercial readiness: pass, status $voCommercialStatus with $voCommercialBlockerCount explicit shipping blockers; scratch VO remains useful for timing but cannot be treated as shipping-approved audio.",
    "- VO recording queue: pass, $voQueueReadyBatchCount scratch-ready batches / $voQueueReadyLineCount lines and $voQueueBlockedBatchCount blocked batches / $voQueueBlockedLineCount lines; blocked minor-speaker batches cannot be generated.",
    "- VO recording packets: pass, $voPacketCount scratch-ready packet files cover $voPacketLineCount lines and $voBlockedPacketCount blocked packet files exist.",
    "- VO minor-speaker decision template: pass, $voMinorSpeakerCount uncast speakers represented and importer dry-run report present; scratch generation remains blocked for pending speakers.",
    "- VO audio asset status: pass, $voAudioExpectedCount expected MP3s tracked, $voAudioScratchReadyCount scratch-ready, $voAudioBlockedCount blocked pending cast, $voAudioPresentBlockedCount blocked present, $voAudioPresentCount present, $voAudioMissingCount missing; missing audio is not counted as recorded and unplanned/zero-byte/blocked-pending MP3s fail validation.",
    "- Act I review decision template: pass, $reviewDecisionRoomCount rooms represented with allowed proceed/revise/stop decisions, YYYY-MM-DD review dates, the Registrar duel lock, and explicit Grey Float content-compliance signoff before any non-pending decision.",
    "- Act I review fix tracker: pass, generated room-level tracker starts all rooms pending_review and preserves fix buckets, close-pair risks, wet/confession readability risks, Grey Float hard-R tags, and Harbor Registry duel-format lock.",
    "- Act I review handoff sync: pass, latest human notes, decision CSV, review tracker, contact sheet, ready-source packet index, and Step 5 dashboard all reference the same 11 Act I rooms before approvals are imported.",
    "- Act I paintover source scaffold: pass, generated per-room source scaffolds provide layer stacks and handoff notes while final PSD paintover sources remain pending until real final art exists.",
    "- Act I paintover start gate: pass, reports 0 ready / 11 blocked rooms with blocked_pending_human_review as the expected pre-signoff state.",
    "- Act I paintover work order: pass, reports $workOrderReadyCount ready / $workOrderBlockedCount blocked rooms, includes only start-gate-ready rooms, and preserves reviewer metadata for every approved room.",
    "- Act I paintover source intake: pass, reports $intakeAcceptedCount accepted present PSDs and $intakeUnapprovedCount unapproved present PSDs; blocked-room PSDs cannot count as final art, and approved rows preserve work-order reviewer metadata.",
    "- Act I final paintover completion: pass, reports $completionCompleteCount complete / $completionPendingExportCount pending final export / $completionBlockedCount blocked rooms, preserves source-intake reviewer metadata for approved rows, and existing greybox PNGs do not count as final paintover exports.",
    "- Act I paintover review provenance: pass, reports $provenanceApprovedCount approved tracker rooms / $provenanceWorkOrderCount work-order rooms / $provenanceAcceptedCount accepted sources / $provenanceCompletionApprovedCount completion-approved rows with matching reviewer proof across the final-art handoff chain.",
    "- Step 5 review dashboard: pass, generated ordered reviewer workflow and artifact index, including the ready-source packet review step and the VO commercial stale-input guard, while paintover start gate remains blocked pending human review.",
    "- Step 5 human review bundle: pass, generated compact launch/index handoff keeps the latest notes, decision CSV, contact sheet, Corvin side-action contact sheet, hotspot overlay, ready-source packet index at docs/art/act_i_background_ready_source_packets.md, paintover packet, duel-format lock, and Grey Float hard-R lock in one review path.",
    "- Act I human playtest launch preflight: pass, no-launch validator proves the launcher refreshes synced review materials and prints the review bundle, latest notes, decision CSV, contact sheet, Corvin side-action contact sheet, hotspot overlay, Corvin side-action scaffold, and ready-source packet index before Godot launch.",
    "- Act I player review card: pass, player-facing handoff exists separately from the internal rubric and withholds Rite names, route order, and duel math while defining the Act I finish mark.",
    "- Act I playable review shortcut: pass, root PLAY_ACT_I_REVIEW.cmd targets the validated launch script with automated report refresh and cannot bypass review preflight.",
    "BLOCKERS:",
    "1. Final paintover source files are still pending for all 11 Act I rooms. This is the next real Step 5 production task, not a Step 4 regression.",
    "2. Corvin talk/use/wet side sheets are rendered, audited, and Godot-registered, but still need final animation polish review; front/back and later decay variants remain pending.",
    "3. A human Act I art/readability playtest has not signed off the blockout compositions, hotspot silhouettes, and prop readability for final paintover.",
    "DEVIATIONS:",
    "- None to the accepted Registrar duel format. This checkpoint only audits art-pipeline readiness and runtime animation evidence.",
    "- This is an entry/readiness checkpoint, not a claim that Step 5 final art is complete.",
    "NEXT:",
    'Run `tools/Start-ActIHumanPlaytest.ps1 -RefreshAutomatedReport` and review `docs/art/act_i_review_contact_sheet.html`, `docs/art/act_i_hotspot_overlay.svg`, and this readiness report before starting room paintovers.'
)

Set-Content -LiteralPath $checkpointPath -Value $lines -Encoding UTF8

$checkpoint = Get-Content -LiteralPath $checkpointPath -Raw
foreach ($requiredText in @(
    "CHECKPOINT: Step 5 entry - Act I Art-Pass Readiness",
    "Act I background blockouts: pass",
    "Corvin Act I side locomotion: pass",
    "Corvin side-priority work order: pass",
    "Corvin Meshy motion source audit: pass",
    "Corvin side-action blend: pass",
    "Corvin side-action render queue: pass",
    "Corvin side-action render scripts: pass",
    "Corvin side-action render commands: pass",
    "Corvin side-action rendered sheets: pass",
    "Ink shader yaw metrics: pass",
    "Act I background element pipeline: pass",
    "Act I background source worklist: pass",
    "Act I background source prompts: pass",
    "Act I background source intake: pass",
    "Act I look target reference: pass",
    "Act I background source placement: pass",
    "Act I background source dropzones: pass",
    "Act I background source acquisition: pass",
    "Act I background ready source packets: pass",
    "Act I review contact sheet: pass",
    "Act I OpenAI prop composite contact sheet: pass",
    "Act I atmosphere setpieces: pass",
    "Act I OpenAI HUD skin: pass",
    "Act I runtime review frames: pass",
    "Step 5 review dashboard: pass",
    "ready-source packet review step",
    "Step 5 human review bundle: pass",
    "Corvin side-action contact sheet",
    "Corvin side-action scaffold",
    "docs/art/act_i_background_ready_source_packets.md",
    "Act I human playtest launch preflight: pass",
    "Act I player review card: pass",
    "Act I playable review shortcut: pass",
    "Act I VO timing manifest: pass",
    "Confession VO manifest: pass",
    "VO recording batches: pass",
    "VO cast plan: pass",
    "VO commercial readiness: pass",
    "VO recording queue: pass",
    "VO recording packets: pass",
    "VO minor-speaker decision template: pass",
    "VO audio asset status: pass",
    "Act I review decision template: pass",
    "Act I review handoff sync: pass",
    "Act I paintover source intake: pass",
    "Act I final paintover completion: pass",
    "Act I paintover review provenance: pass",
    "None to the accepted Registrar duel format"
)) {
    if ($checkpoint -notmatch [regex]::Escape($requiredText)) {
        throw "Step 5 readiness checkpoint missing required text: $requiredText"
    }
}
if ($checkpoint -match "[^\u0000-\u007F]") {
    throw "Step 5 readiness checkpoint must stay ASCII-only."
}

Write-Host "Step 5 Act I art-pass readiness validation passed: rooms=$($rooms.Count), backgrounds=$backgroundPresent/$($backgroundRows.Count) present, corvin=$corvinPresent/$($corvinRows.Count) present."
