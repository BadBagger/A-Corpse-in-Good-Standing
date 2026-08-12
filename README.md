# A Corpse in Good Standing

[![Headless Gates](https://github.com/BadBagger/A-Corpse-in-Good-Standing/actions/workflows/headless-gates.yml/badge.svg)](https://github.com/BadBagger/A-Corpse-in-Good-Standing/actions/workflows/headless-gates.yml)

Godot 4.6.3 .NET point-and-click adventure prototype.

This repo is intentionally separate from `C:\dev\mha` and *Lost & Underfound*.

## Current Source Documents

- `AGENTS.md` - build brief and guardrails
- `docs/LITANY_confession_library.md` - authored confession library
- `docs/script/act_i_full_script_build_document.md` - Act I build document
- `docs/script/script_prologue_act1.md` - prologue/Act I script excerpt
- `docs/VO_cast_sheet.md` and `docs/VO_test_script.md` - full VO planning inputs
- `docs/vo/act_i_vo_line_manifest.json`, `.csv`, and `.md` - generated Act I Ink-derived VO recording/timing manifest
- `docs/vo/confession_vo_manifest.json`, `.csv`, and `.md` - generated Litany confession/elaboration VO manifest
- `docs/vo/vo_recording_batches.json`, `.csv`, and `.md` - generated session-style VO recording batch plan
- `docs/vo/vo_cast_plan.json`, `.csv`, and `.md` - generated scratch VO cast plan tied to current manifests and recording batches
- `docs/vo/vo_commercial_readiness.json` and `.md` - generated commercial-readiness blocker report for scratch/full VO shipping decisions
- `docs/vo/vo_recording_queue.json`, `.csv`, and `.md` - generated scratch-ready vs blocked VO batch queue
- `docs/checkpoints/step_5_human_review_bundle.json` and `.md` - compact Step 5 human-review launch bundle and artifact index
- `docs/playtest/act_i_player_review_card.md` - player-facing Act I review handoff that avoids route spoilers while defining setup, stuck marks, and the finish mark
- `docs/checkpoints/production_blocker_index.md` - stable index of current GitHub production blockers and the evidence/commands tied to each one
- `docs/checkpoints/ci_gate_boundary.md` - explicit split between GitHub Actions coverage and local-only Godot/Step 2-5 gates
- `docs/checkpoints/toolchain_status.json` and `.md` - generated local-only Godot/Blender/Ink toolchain audit
- `docs/art/act_i_review_contact_sheet.html` - browser review sheet combining Act I blockout images, walk bands, hotspot markers, and room tables
- `docs/vo/vo_recording_packets_index.json`, `.csv`, and `.md` plus `docs/vo/recording_packets/scratch_ready/*.md` - generated per-batch scratch VO recording packets
- `docs/vo/vo_minor_speaker_decisions_template.csv` and `.md` - generated minor-speaker VO casting/consolidation decision handoff
- `docs/vo/vo_audio_asset_status.json`, `.csv`, and `.md` - generated expected/present/missing VO MP3 asset status
- `docs/art/act_i_location_art_targets.md` - Act I greybox-to-final-art location map
- `docs/art/act_i_hotspot_map.csv` - generated Act I room/hotspot coordinate map
- `docs/art/act_i_hotspot_overlay.svg` - generated visual overlay of Act I hotspot positions
- `docs/art/act_i_hotspot_layout_audit.md` - generated hotspot bounds/proximity audit for final-art staging
- `docs/art/act_i_background_manifest.json` - generated Act I background source/export contract
- `docs/art/act_i_background_brief.md` - generated room-by-room background production brief
- `docs/art/act_i_background_element_pipeline.json` and `.md` - generated Act I background element source contract for Blender, Meshy helper models, generated reference, baked paint, and interactive layers
- `docs/art/act_i_background_source_worklist.json`, `.csv`, and `.md` - generated source-art task list for Act I Meshy helper models, generated reference boards, interactive layers, and navigation silhouettes
- `docs/art/act_i_background_source_prompts.json`, `.csv`, and `.md` - generated guarded prompt packets for Act I Meshy helper models, imagegen reference boards, and paintover/runtime layer tasks
- `docs/art/act_i_background_source_intake.json`, `.csv`, and `.md` - generated intake/status report for Act I prompt output files, keeping Meshy, imagegen, and paintover sources separate from final art acceptance
- `docs/art/act_i_background_source_placement.json`, `.csv`, and `.md` - generated placement map for routing Act I prompt outputs into Blender helper geometry, reference boards, separate runtime layers, or navigation readability review
- `docs/art/act_i_background_source_dropzones.json`, `.csv`, and `.md` - generated source-output drop-zone scaffold, with per-folder README files for where Act I Meshy, imagegen, interactive-layer, and navigation-source files should land
- `docs/art/act_i_background_source_acquisition.json`, `.csv`, and `.md` - generated per-room acquisition checklist that separates source files safe to generate now from PSD layer work held for human room review
- `docs/art/act_i_background_ready_source_packets.json`, `.csv`, and `.md` plus `docs/art/generation_packets/act_i_background_ready_sources/*.md` - generated ready-source packet index and per-room/tool prompt packets for the 84 Meshy/imagegen source items safe to acquire before human room review
- `docs/art/act_i_background_asset_status.csv` and `.md` - generated present/pending tracker for Act I background assets
- `docs/art/act_i_blockout_tasks.json` and `.md` - generated Blender blockout proof tasks for Act I rooms
- `docs/art/act_i_background_palette_audit.csv` and `.md` - generated G9/G10 palette audit for exported Act I backgrounds
- `docs/art/corvin_animation_manifest.json` and `.md` - generated Corvin sprite-sheet production contract
- `docs/art/corvin_animation_asset_status.csv` and `.md` - generated present/pending tracker for Corvin animation assets
- `docs/art/corvin_meshy_source_intake.json` and `.md` - generated intake record for Kyle's Meshy Corvin GLB/ZIP downloads
- `docs/art/blender_corvin_import_probe.json` and `.md` - generated Blender import preflight for the canonical Corvin GLB
- `docs/art/corvin_shader_sprite_seed.json` and `.md` - generated bridge from the audited shader proof to Corvin Act I side-profile sprite production
- `docs/art/corvin_act_i_clean_side_idle_status.json` and `.md` - generated first-pass Act I clean side-right idle runtime candidate status
- `docs/art/corvin_act_i_clean_side_walk_status.json` and `.md` - generated first-pass Act I clean side-right walk runtime candidate status
- `docs/art/corvin_runtime_sprite_assets_status.json` and `.md` - generated Godot load proof for the first-pass Corvin runtime sprite PNGs
- `docs/art/ink_shader_spike_still_render_status.json` and `.md` - generated R1/R2 still-render proof status
- `docs/art/ink_shader_spike_still_image_audit.json` and `.md` - generated R1/R2 still PNG audit for nonblank content and palette proximity
- `docs/art/ink_shader_spike_manifest.json`, `.md`, and status files - generated Blender ink-wash shader proof contract
- `docs/art/ink_shader_spike_yaw_render_status.json` and `.md` - generated 24-frame yaw-turn hatch render status
- `docs/art/ink_shader_spike_metrics_status.json` and `.md` - generated motion-compensated hatching stability metrics
- `docs/checkpoints/step_1_confession_duel_prototype.md` - current Step 1 review handoff
- `docs/playtest/registrar_duel_playtest.md` - blind playtest rubric for the fun gate
- `docs/playtest/act_i_greybox_remaining_beats.md` - concrete before-final-art greybox review list
- `docs/playtest/act_i_human_greybox_playtest.md` - human Act I greybox playtest rubric and decision rule
- `docs/checkpoints/step_3_ink_journal_persistence.md` - current Ink/journal/persistence handoff
- `docs/checkpoints/step_4_act_i_greybox_room_graph.md` - Act I greybox quest-flow handoff
- `docs/act_i_puzzle_dependency_graph.json` - machine-readable Act I puzzle dependency graph
- `docs/checkpoints/source_control_readiness.md` - generated source-control hygiene report for ignore rules, LFS coverage, and oversized binary assets

## Generated Data

- `data/confessions.json` is generated from `docs/LITANY_confession_library.md`.
- Run `tools\Export-Confessions.ps1` after editing the Litany markdown.
- Run `tools\Validate-Confessions.ps1` before wiring duel content.
- `docs\art\act_i_hotspot_map.csv` is generated from the current Godot room scenes with `tools\Export-ActIHotspotMap.ps1`.
- `tools\Validate-ActIHotspotMap.ps1` regenerates and validates that CSV, the SVG overlay, and the layout audit as part of the Step 4 gates.
- `tools\Validate-ActIBackgroundManifest.ps1` regenerates and validates the Act I background manifest and production brief from the hotspot map.
- `tools\Validate-ActIBackgroundElementPipeline.ps1` regenerates and validates the Act I background element source contract: Blender greybox/paintover are authoritative, Meshy is source-prop help only, generated images are reference only, and logic-touched elements stay separate.
- `tools\Validate-ActIBackgroundSourceWorklist.ps1` regenerates and validates the concrete Act I source-art task list: Meshy GLB helpers, generated reference boards, separate interactive layers, and navigation silhouettes all start pending and preserve the background pipeline rules.
- `tools\Validate-ActIBackgroundSourcePrompts.ps1` regenerates and validates guarded prompts for the Act I source-art worklist, keeping Meshy helper prompts, imagegen reference prompts, and paintover/runtime-layer prompts inside the accepted pipeline.
- `tools\Validate-ActIBackgroundSourceIntake.ps1` regenerates and validates source prompt output intake, marking files present/pending without treating Meshy GLBs, imagegen references, or paintover PSDs as final room art.
- `tools\Validate-ActIBackgroundSourcePlacement.ps1` regenerates and validates the placement map for source prompt outputs after intake, keeping Meshy, imagegen, interactive, and navigation outputs routed through their proper review gates.
- `tools\Validate-ActIBackgroundSourceDropzones.ps1` regenerates and validates source-output drop-zone READMEs. These create folders only; they must not create placeholder `.glb`, `.png`, or `.psd` files.
- `tools\Validate-ActIBackgroundSourceAcquisition.ps1` regenerates and validates the per-room acquisition checklist: Meshy/reference source files can be generated now, while interactive/navigation PSD work stays held until human room approval.
- `tools\Validate-ActIBackgroundReadySourcePackets.ps1` regenerates and validates the ready-source generation packets. These include only Meshy/imagegen source items marked `ready_to_generate` and exclude held interactive/navigation PSD work.
- `tools\Validate-ActIObjectiveHud.ps1` validates the non-spoiler Act I objective HUD contract: standing progress appears in-game without exposing Rite names, route order, or duel math.
- `tools\Validate-ActIBackgroundAssetStatus.ps1` regenerates the background asset tracker. Pending art is allowed here; malformed or incomplete tracking is not.
- `tools\Validate-ActIBlockoutTasks.ps1` regenerates the Blender blockout task brief and validates room coverage, wet-verb tasks, close-pair review, and Registrar duel-format lock.
- `tools\Validate-ActIBackgroundPaletteAudit.ps1` regenerates the palette audit. Pending exports are allowed; existing exported PNGs must satisfy G9/G10.
- `tools\Validate-CorvinAnimationManifest.ps1` regenerates the Corvin animation contract and asset tracker. Pending sprite assets are allowed; missing variants/directions/12 fps sheet contracts are not.
- `tools\Validate-CorvinMeshySourceIntake.ps1` imports the current Corvin Meshy download into the canonical Act I source path when available and records the biped ZIP as reference/rig/motion material.
- `tools\Validate-BlenderCorvinImport.ps1` runs a 120 second headless Blender preflight. If Blender is available, it imports Corvin's canonical GLB and saves starter character/shader `.blend` files; if Blender is missing, the preflight remains pending.
- `tools\Validate-CorvinShaderSpriteSeed.ps1` exports and validates the Act I side-profile shader-proof contact sheet seed. This is not a runtime animation sheet.
- `tools\Validate-CorvinActICleanSideIdleSheet.ps1` renders and validates the first-pass Act I clean `side_right` idle runtime candidate sheet at 12 fps. This is not final animation polish.
- `tools\Validate-CorvinActICleanSideWalkSheet.ps1` renders and validates the first-pass Act I clean `side_right` walk runtime candidate sheet at 12 fps. This is not final animation polish; rigged in-place walk polish is still required.
- `tools\Validate-CorvinRuntimeSpriteAssets.ps1` proves Godot can load the first-pass Corvin runtime sprite PNGs, that they have the expected dimensions/frame counts, and that Corvin's `RuntimeSprite` scene node uses the idle sheet with the polygon fallback hidden.
- `tools\Validate-InkShaderSpikeStills.ps1` renders the R1/R2 shader-spike still proofs from Blender at 1920x1080.
- `tools\Render-InkShaderSpikeYawSequences.ps1` renders the R3/R4/R7 24-frame yaw-turn shader proof sequences from Blender and controlled hatch passes.
- `tools\Test-InkShaderSpikeStillImages.ps1` audits the R1/R2 still proof PNGs for 1920x1080 dimensions, nonblank content, and locked-palette proximity.
- `tools\Validate-InkShaderSpikeManifest.ps1` regenerates the ink shader spike contract. Pending renders are allowed; missing 24-frame yaw-turn, object-anchored hatching, bad-control, drift, palette, or duel-lock requirements are not.
- `tools\Test-InkShaderSpikeMetrics.ps1` measures the shader spike yaw-turn renders with foreground-bounds-aligned hatch-pixel deltas. Missing render folders stay pending; incomplete sequences or over-threshold hatching motion fail.
- `tools\Validate-ActIPaintoverPacket.ps1` regenerates and validates `docs\art\act_i_paintover_packet.json` and `.md`, a per-room final-paintover packet derived from validated blockouts, hotspot roles, palette audit, and close-pair warnings.
- `tools\Validate-ActIArtReadabilityReview.ps1` regenerates and validates `docs\playtest\act_i_art_readability_review.md`, a room-by-room art review checklist for hotspot readability, walk-band clarity, contact-sheet review, special content risks, decision CSV date format, and proceed/revise/stop decisions before paint.
- `tools\Validate-ActIHumanReviewNotes.ps1` validates that `tools\New-ActIHumanPlaytestNotes.ps1` produces a combined Step 5 human review notes file with both the greybox playtest rubric and art readability checklist, including contact-sheet and `YYYY-MM-DD` decision-date prompts.
- `tools\Validate-ActIPlayerReviewCard.ps1` regenerates and validates `docs\playtest\act_i_player_review_card.md`, keeping route spoilers, Rite names, exact duel math, and final-art status out of the tester handoff.
- `tools\Validate-ActIVoLineManifest.ps1` regenerates and validates `docs\vo\act_i_vo_line_manifest.json`, `.csv`, and `.md` from Ink speaker tags; it tracks unrecorded Act I VO lines, stage-direction review lines, scratch-cast speakers, and minor speakers needing cast decisions without duplicating confession text.
- `tools\Validate-ConfessionVoManifest.ps1` regenerates and validates `docs\vo\confession_vo_manifest.json`, `.csv`, and `.md` from `data\confessions.json`, requiring one confession VO line and one elaboration VO line per confession with audio paths keyed by confession id.
- `tools\Validate-VoRecordingBatches.ps1` regenerates and validates `docs\vo\vo_recording_batches.json`, `.csv`, and `.md`, grouping Act I scene VO by Ink knot/speaker and Litany VO by act/category so scratch generation does not happen as disconnected one-line fragments.
- `tools\Validate-VoCastPlan.ps1` regenerates and validates `docs\vo\vo_cast_plan.json`, `.csv`, and `.md`, tying scratch voice choices to current Act I/Litany line counts while keeping pending minor speakers and commercial licensing as explicit blockers.
- `tools\Validate-VoCommercialReadiness.ps1` regenerates and validates `docs\vo\vo_commercial_readiness.json` and `.md`, keeping scratch VO blocked for shipping until licensing, disclosure, final audio, pending-cast/cut-rewrite minor-speaker, and human VO-lock evidence exists.
- `tools\Test-VoCommercialReadiness.ps1` proves the commercial readiness gate regenerates VO cast-plan and audio-status inputs before export, so stale upstream JSON cannot make scratch VO look shippable.
- `tools\Validate-VoRecordingQueue.ps1` regenerates and validates `docs\vo\vo_recording_queue.json`, `.csv`, and `.md`, exposing only scratch-cast batches as timing-test ready while keeping pending-cast and cut/rewrite minor-speaker batches blocked.
- `tools\Validate-VoRecordingPackets.ps1` regenerates and validates per-batch scratch VO recording packets, requiring one packet per scratch-ready batch and none for pending-cast or cut/rewrite blocked minor-speaker batches.
- `tools\Validate-Step5HumanReviewBundle.ps1` regenerates and validates the compact Step 5 human-review bundle, keeping the launch command, latest notes, decision CSV, contact sheet, hotspot overlay, ready-source packet index, paintover packet, duel-format lock, and Grey Float hard-R lock together.
- `tools\Validate-ActIHumanPlaytestLaunch.ps1` validates the no-launch Act I playtest preflight, including the synced review bundle, latest notes, decision CSV, contact sheet, hotspot overlay, and ready-source packet index.
- `tools\Validate-ActIHumanPlaytestShortcut.ps1` validates `PLAY_ACT_I_REVIEW.cmd`, the root Windows shortcut for the preflighted Act I playable-review launcher.
- `tools\Validate-ActIReviewContactSheet.ps1` regenerates and validates the Act I browser contact sheet for human review, proving all 11 blockouts, marker counts, walk bands, duel-format lock, and Grey Float hard-R lock are present.
- `tools\Validate-VoMinorSpeakerDecisionTemplate.ps1` regenerates and validates `docs\vo\vo_minor_speaker_decisions_template.csv` and `.md` for minor speakers still blocking VO batch generation.
- `tools\Test-VoMinorSpeakerDecisionImport.ps1` proves minor-speaker cast/consolidate/cut decisions can be dry-run/applied into durable `docs\vo\vo_minor_speaker_decisions.json`, regenerated into VO batches, queue, packets, audio status, and commercial readiness, restored, and that incomplete cast rows fail.
- `tools\Validate-VoAudioAssetStatus.ps1` regenerates and validates `docs\vo\vo_audio_asset_status.json`, `.csv`, and `.md`, tracking all expected VO MP3s while separating scratch-ready queue paths from blocked pending-cast and cut/rewrite paths; zero-byte, unplanned, and blocked-path MP3s fail validation.
- `tools\Test-VoAudioAssetStatus.ps1` proves the VO audio status gate accepts the current no-audio state and rejects both a temporary unplanned MP3 and a blocked pending-cast MP3 negative control.
- `tools\Validate-ActIReviewFixTracker.ps1` regenerates and validates `docs\playtest\act_i_review_fix_tracker.json` and `.md`, the room-level fix tracker for turning human review findings into layout, hotspot, palette, content, duel-format, and pacing tasks before final paint; non-pending tracker rows must keep reviewer metadata and `reviewed_at` as `YYYY-MM-DD`.
- `tools\Set-ActIReviewDecision.ps1` records a human review decision for one Act I room and refreshes the tracker while preserving existing review notes; non-pending `-ReviewedAt` values must use `YYYY-MM-DD`.
- `tools\Test-ActIReviewDecisionUpdater.ps1` smoke-tests room approval/revision decisions, tracker metadata/date negative controls, and restores the tracker artifacts afterward.
- `tools\Export-ActIReviewDecisionTemplate.ps1` generates `docs\playtest\act_i_review_decisions_template.csv` and `.md` for batch human-review signoff.
- `tools\Validate-ActIReviewDecisionTemplate.ps1` regenerates and validates the Act I review decision template, requiring all 11 rooms, reviewer metadata columns, allowed decision values, ASCII-only Markdown, and the Registrar/Grey Float rule locks.
- `tools\Import-ActIReviewDecisions.ps1` imports the review decision CSV in `-DryRun` or `-Apply` mode and writes `docs\playtest\act_i_review_decision_import_report.md`; any non-pending decision must include `reviewer`, `reviewed_at` as `YYYY-MM-DD`, and `decision_note`.
- `tools\Test-ActIReviewDecisionBatchImport.ps1` smoke-tests dry-run/apply batch decisions, required CSV columns, ISO review dates, and restores the tracker artifacts afterward.
- `tools\Validate-ActIReviewHandoffSync.ps1` validates that the latest human review notes, decision CSV, review tracker, contact sheet, ready-source packet index, and Step 5 dashboard all reference the same 11 Act I rooms before approvals are imported.
- `tools\Test-ActIReviewHandoffSync.ps1` proves the review handoff sync gate accepts the current handoff and rejects decision-mismatch, missing-room, missing-contact-sheet, and missing-ready-source-packet negative controls before restoring artifacts.
- `tools\Validate-ActIPaintoverSourceScaffold.ps1` regenerates and validates `docs\art\act_i_paintover_source_scaffold.json` and `.md` plus per-room scaffold notes under `art\src\backgrounds\act_i\paintover_scaffolds`, without marking final PSD paintover sources complete.
- `tools\Validate-ActIPaintoverStartGate.ps1` regenerates and validates `docs\art\act_i_paintover_start_gate.json` and `.md`; before human signoff it should report `blocked_pending_human_review`, 0 ready rooms, and 11 blocked rooms.
- `tools\Validate-ActIPaintoverWorkOrder.ps1` regenerates and validates `docs\art\act_i_paintover_work_order.json` and `.md`, listing only rooms approved by the paintover start gate for final PSD work and requiring reviewer metadata for every approved room.
- `tools\Test-ActIPaintoverWorkOrder.ps1` proves the work order is empty before review, includes only a simulated approved room, preserves reviewer metadata, and restores tracker/start-gate/work-order artifacts afterward.
- `tools\Validate-ActIPaintoverSourceIntake.ps1` regenerates and validates `docs\art\act_i_paintover_source_intake.json` and `.md`, refusing final PSD sources for rooms not approved by the work order, rejecting text/empty placeholder PSDs, and preserving reviewer metadata for approved rows.
- `tools\Test-ActIPaintoverSourceIntake.ps1` proves a blocked-room PSD fails intake, an approved PSD-signature source passes with reviewer metadata intact, a text placeholder fails, and temporary source artifacts are removed afterward.
- `tools\Validate-ActIFinalPaintoverCompletion.ps1` regenerates and validates `docs\art\act_i_final_paintover_completion.json` and `.md`, counting a room complete only when an accepted PSD-signature source has a newer audited final PNG export and preserving source-intake reviewer/source-proof metadata for approved rows.
- `tools\Test-ActIFinalPaintoverCompletion.ps1` proves an accepted PSD-signature source alone does not let an existing greybox PNG count as final paintover completion and preserves reviewer/source-proof metadata through the completion audit.
- `tools\Validate-ActIPaintoverReviewProvenance.ps1` regenerates and validates `docs\art\act_i_paintover_review_provenance.json` and `.md`, proving approved-room reviewer metadata matches from tracker through start gate, work order, source intake, and final completion.
- `tools\Test-ActIPaintoverReviewProvenance.ps1` simulates an approved Harbor Registry PSD, proves provenance survives the whole final-art handoff chain, and restores tracker/source/provenance artifacts afterward.
- `tools\Validate-Step5ReviewDashboard.ps1` regenerates and validates `docs\checkpoints\step_5_review_dashboard.json` and `.md`, the ordered human-review workflow and artifact index for Act I paintover signoff.
- `tools\Validate-Step5ActIArtReadiness.ps1` writes and validates `docs\checkpoints\step_5_act_i_art_pass_readiness.md` from the current background blockouts, palette audit, Corvin runtime side locomotion, shader metrics, and automated playtest evidence. It proves readiness for art-pass review, not final art completion.
- `tools\Validate-SourceControlReadiness.ps1` validates `.gitignore` and `.gitattributes`, checks LFS coverage for art/audio/archive/tool binaries, rejects uncovered files over 50 MB, and writes `docs\checkpoints\source_control_readiness.md`.
- `tools\Validate-TextArtifactHygiene.ps1` checks source, narrative, Godot text resources, docs, and repo metadata for illegal control characters.
- `tools\Validate-ProductionBlockerIndex.ps1` validates that `docs\checkpoints\production_blocker_index.md` keeps the three live production blockers, evidence paths, verification commands, and stop-point guardrails visible.
- `tools\Test-ProductionBlockerIndex.ps1` proves the blocker-index validator accepts the current index and rejects a missing scratch-VO shipping guardrail before restoring the fixture.
- `tools\Validate-CiGateBoundary.ps1` validates that GitHub Actions still proves repo hygiene plus Step 1 only, while Step 2-5 remain documented as local-only until portable Godot/render tooling is added to CI.
- `tools\Export-ToolchainStatus.ps1` writes `docs\checkpoints\toolchain_status.json` and `.md`, a local-only audit of the resolved Godot, Blender, and Ink compiler paths.
- `tools\Validate-ToolchainStatus.ps1` regenerates and validates the local toolchain audit; it is intentionally not part of GitHub Actions until CI installs portable Godot and Blender.
- `tools\Resolve-Godot.ps1` centralizes local Godot 4.6.3 .NET executable discovery for Step 2-5 scripts. It honors `CORPSE_GODOT_CONSOLE`, `CORPSE_GODOT_WINDOWED`, or `CORPSE_GODOT_DIR` before checking the current WinGet and Downloads locations.
- `tools\Validate-GodotResolver.ps1` validates the local Godot resolver on this machine; it is intentionally not part of GitHub Actions until CI installs portable Godot.
- `tools\Resolve-Blender.ps1` centralizes local Blender executable discovery for blockout, shader, and Corvin source/render scripts. It honors `CORPSE_BLENDER` or `CORPSE_BLENDER_DIR`, then existing probe data, PATH, and standard Windows install locations.
- `tools\Validate-BlenderResolver.ps1` validates the local Blender resolver and version probe; it is intentionally not part of GitHub Actions until CI installs portable Blender/render tooling.
- `tools\Resolve-InkCompiler.ps1` centralizes `inklecate` discovery. It honors `CORPSE_INKLECATE`, then the vendored `tools\ink\inklecate.exe`, then PATH.
- `tools\Validate-InkCompiler.ps1` validates the vendored Ink compiler identity, SHA256, usage text, and prologue compile path.
- `tools\Run-RepoReadinessGates.ps1` runs the source-control/LFS and text-artifact gates for commit/package hygiene. It does not replace the Step 1-5 build gates.
- `tools\Validate-StagedSourceSnapshot.ps1` validates a staged initial snapshot, rejecting build output, Godot cache files, Blender backups, temp files, and missing root handoff artifacts while reporting commit identity/remote blockers.
- `.github\pull_request_template.md` and `.github\ISSUE_TEMPLATE\*.yml` keep GitHub review/work items aligned with the duel-format lock, Grey Float hard-R line, Act I confession gates, and Step 5 human-review/paintover ordering.

## First Gates

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step1Gates.ps1
```

After the duel format is accepted, run the Step 2 scaffold gates:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step2Gates.ps1
```

After the prologue scaffold is in place, run the Step 3 Ink/persistence gates:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step3Gates.ps1
```

After the Ink/persistence layer is in place, run the Step 4 room graph gates:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step4Gates.ps1
```

After Step 4 is green, refresh the Act I art-pass readiness checkpoint:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step5ReadinessGates.ps1
```

Before the first commit or a source snapshot handoff, run the repo hygiene gate:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\Run-RepoReadinessGates.ps1
```

After staging a source snapshot, validate the staged tree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\Validate-StagedSourceSnapshot.ps1
```

To record the current automated Act I greybox playtest transcript:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Record-ActIGreyboxPlaytest.ps1
```

To create a timestamped human Act I review notes file with the greybox rubric and art readability checklist, plus a stable latest copy at `docs\playtest\results\act_i_human_playtest_latest.md`:

```powershell
powershell -ExecutionPolicy Bypass -File tools\New-ActIHumanPlaytestNotes.ps1
```

To refresh the automated transcript, create combined human review notes, and launch the playable Godot build:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Start-ActIHumanPlaytest.ps1 -RefreshAutomatedReport
```

Or run the root Windows shortcut:

```cmd
PLAY_ACT_I_REVIEW.cmd
```

For a dry preflight without opening Godot:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Start-ActIHumanPlaytest.ps1 -NoLaunch
```

The corrected Litany gate is `GREED/LUST/PRIDE/CRUELTY/COWARDICE >= 11`, `BETRAYAL == 4`, and `total >= 60`.

## Current Implementation Status

- Step 1 has started as a standalone `net8.0` duel domain library.
- `duels/Corpse.Duels` has no Godot package references.
- `tests/Corpse.Duels.Tests` covers strict weight comparison, category trumping, spend-on-failure, spent/locked rejection, elaboration damage, and session advancement.
- `duels/opponents/registrar.json` defines the 8-attack Registrar prototype opponent.
- `prototype/Corpse.DuelConsole` is a playable console Registrar duel with a `--scripted-win` smoke mode.
- Step 1 fun gate decision: keep the duel format.
- Godot 4.6.3 .NET project shell is present in `project.godot`.
- Popochiu 2.1.1 is vendored in `addons/popochiu`.
- Prologue Mudflats greybox is present in `game/rooms/mudflats`, including the authored silt, own-hands, harbor-view, and coat/wet tutorial hotspots; custom Mudflats handlers are validated for explicit look/use/talk/walk/wet coverage.
- Corvin placeholder player character is present in `game/characters/corvin`.
- Corvin's production animation contract is generated in `docs/art/corvin_animation_manifest.json`: three decay variants, four directions, 12 fps, and deterministic Meshy/Blender-to-sprite-sheet paths.
- Corvin's Meshy source intake is generated in `docs/art/corvin_meshy_source_intake.json`; the standalone textured Meshy GLB is the canonical Act I clean source, while the biped ZIP is tracked as reference motion material rather than proof of finished game animations.
- The Blender import probe is generated in `docs/art/blender_corvin_import_probe.json`; it proves whether Blender can import `corvin_act_i_clean.glb` and save starter `.blend` files for the character and shader spike.
- The ink shader still-render proof is generated in `docs/art/ink_shader_spike_still_render_status.json`; it renders R1/R2 stills.
- The still image audit is generated in `docs/art/ink_shader_spike_still_image_audit.json`; it proves the R1/R2 PNGs are nonblank 1920x1080 renders and reports palette proximity for tuning.
- The ink-wash shader spike contract is generated in `docs/art/ink_shader_spike_manifest.json`: 12 fps, 24-frame yaw turn, object/world-anchored hatching, screen-space bad control, pairwise delta plus first-to-last drift checks, locked palette mapping, and the accepted Registrar duel-format lock.
- The yaw shader proof is generated in `docs/art/ink_shader_spike_yaw_render_status.md`: 24 object-anchored frames, 24 screen-space bad-control frames, and 24 locked-palette mapped frames.
- The shader metrics runner writes `docs/art/ink_shader_spike_metrics_status.md`; it currently audits the yaw proof with foreground-bounds-aligned hatch-pixel deltas, with object-anchored pairwise max at 0 percent and the bad control at 28.512 percent.
- Prologue verb coin and inventory strip are present in `game/ui/prologue_hud.tscn`.
- Prologue Popochiu inventory placeholders are registered: `HarborMud` and `BorrowedBoots`.
- Prologue Ink compiles through `tools\Compile-Ink.ps1`.
- Ink validation checks gameplay tags against runtime handlers, journal IDs, confession IDs, and Popochiu item IDs.
- `narrative/Corpse.Narrative` stores journal and global confession state without Godot references.
- Godot autoload `N` mirrors journal and global confession state for the playable prologue scaffold.
- Godot autoload `InkBridge` applies compiled Ink knot tags into `N`.
- Godot autoload `InkBridge` extracts speaker/text lines from compiled Ink knots for prologue dialogue playback.
- Popochiu Globals save/load hooks roundtrip `N` narrative snapshots.
- Step 3 runtime validation writes Popochiu slot 4 and loads it through `E.load_game()` to prove narrative custom data reaches and returns from the save file.
- Corvin's greybox polygon sprite has a flip proxy so Popochiu can load him as the player placeholder.
- Mudflats verb interactions now populate the HUD dialogue, journal, and Litany summary from Ink; the automated report captures the tutorial/environment beats before the Act I route begins, and the room graph validator protects all custom tutorial hotspots from missing verb responses.
- Act I greybox room graph is registered for Old Quay, Salt Market, Harbor Registry, Bone Chandler, Almshouse, Fish Hall, Church of the Drowned, Grey Float, Harbormaster Office, and Sabine Office.
- `tools\New-ActIRoomScaffold.ps1` regenerates the Act I greybox room scenes/resources with UTF-8 no-BOM text resources for Godot compatibility.
- `tools\Run-Step4Gates.ps1` runs the full Step 1-3 chain, validates the Act I puzzle dependency graph, validates all Act I room resources/scenes/exits/reachability in Godot, and simulates the greybox Act I quest flow from no Rites complete to Sabine's office.
- Act I quest flags and greybox item state now persist through Godot autoload `N`.
- Act I Rites are greybox-playable via authored hotspots: Name Restored, Debt Forgiven, and Borrowed Heartbeat can all be completed in any order before entering Sabine's office.
- Old Quay now has first-pass authored Tomas hint-hub, a three-bollard silent row, conditional all-three-bollards Tomas follow-up, flask pickup, and rope-cleat salt beats in Ink; the automated route captures `FL_tomas_topics_seen`, the Appendix B Tomas confessions `cf_pride_list` / `cf_cow_leftroom` / `cf_greed_widows`, `FL_silent_bollards_seen`, `FL_bollard_petra_seen`, `FL_bollard_ledger_seen`, `FL_bollard_bride_seen`, `FL_bollard_row_reported`, `IT_flask`, and `FL_flask_taken`.
- Salt Market now functions as the Act I navigation hub with exits to Old Quay, Harbor Registry, Bone Chandler, Almshouse, Fish Hall, and the Church of the Drowned; `tools\godot_validate_act_i_rooms.gd` proves every registered room is reachable from Mudflats through actual exits. Its public-recognition beat now includes the seller face-change, scattered boots, frozen street, and crowd-parting staging that turns the market from intro bottleneck into hub.
- Salt Market now has authored public-recognition, boot-stall aftermath, fishmonger, confession-queue, and whale-oil lamp beats in `salt_market_public_recognition`, `salt_market_boot_stall_after`, `salt_market_fishmonger`, `salt_market_confession_queue`, and `salt_market_lamp`; the greybox route awards `BorrowedBoots`, gates the aftermath behind `FL_market_recognized`, sets `FL_boot_stall_after_seen` / `FL_fishmonger_seen` / `FL_market_day_hint` / `FL_market_lamp_checked`, and seeds early overheard confessions including `cf_pride_voice`, `cf_cow_drink`, `cf_greed_scales`, and `cf_cruel_funeral` before the three Rites.
- Fish Hall now has expanded authored day-count and emotional proof beats for the ice table, coroner tag, visitor book, and wet-only drain; the greybox route awards `IT_coroner_tag`, sets `FL_body_fit_confirmed`, `FL_day_count_proven` / `FL_knows_daycount`, `FL_sabine_absent_from_book`, and `FL_fish_hall_drain_seen`, discovers Act I-safe `cf_pride_twice`, and explicitly guards against early `cf_pride_eulogy` / `cf_cow_didntfight` acquisition.
- Registrar now opens `game/ui/duel_panel.gd`, an in-Godot Litany selector that loads `data/confessions.json` and `duels/opponents/registrar.json`, applies strict weight/category rules, spends chosen confessions globally, locks opponent-spoken confessions, and emits win/loss before awarding `IT_name_writ`.
- The Registrar duel panel has a readable greybox layout with title, round counter, Salt counter, accusation metadata, status feedback, stable option buttons, and tooltips; the Act I quest-flow validator snapshots those UI fields during the scripted Registrar route.
- Registrar duel start/win/loss beats live in `ink/prologue.ink` as `registrar_duel_start`, `registrar_duel_win`, and `registrar_duel_loss`; `registrar_duel_start` now carries the authored Vale-boy pre-duel exchange before the Litany opens, and `tools\godot_validate_ink_bridge.gd` verifies those knots are available at runtime.
- The Harbor Registry now has an expanded greybox ledgers read plus the Kestrel ledger sub-puzzle: `Ledgers` sets `FL_registry_ledgers_seen`, the roll book carries the scored-paper strike-through as an art anchor without granting `cf_pride_handwriting` early, the Kestrel ledger blocks before the lamp is smoked, the Registrar blocks before `FL_manifest_known`, `IT_ledger_page` discovers `cf_bt_manifest`, and the accepted Registrar duel route spends it before setting `IT_name_writ`, `FL_rite_name`, and the Act II hook `FL_registrar_sold_manifest`. The page pickup now carries the Registrar's silent "she knows" staging: she sees the torn corner, does not rise, and files the moment for the duel.
- Corvin's permanent `wet` verb is now first-class in the greybox HUD and hotspot contract. The automated route exercises `wet` on the Church sign, Fish Hall drain, Old Quay rope cleat, and Registry desk lamp; validator negative checks prove plain `use` does not set the wet-only sign/drain/lamp flags.
- Debt Forgiven and Borrowed Heartbeat now have first-pass authored Ink beats for blocked and successful interactions at the Bone Chandler, Almshouse, Grey Float, and Harbormaster Office; the Step 4 quest-flow validator verifies those knots are available while simulating the full Act I route. The Bone Chandler watch gate now blocks before `IT_knuckle_salt` with the under-glass/watch-chain read, Prosper's before-watch scene carries the fresh-every-morning memory-rot beat, the watch trade includes the authored fresh-salt-from-a-walking-returned scene beat plus the Chandler's reluctant come-back line, and Prosper's forgiveness scene now includes the hand-memory and truth-lock beats without awarding any Act II confession early.
- The Act I Rites now have an automated non-linear order gate: `tools\godot_validate_act_i_rite_permutations.gd` runs all six Name/Debt/Heartbeat orderings and confirms Sabine stays blocked until the third Rite completes.
- The Debt Forgiven room texture now includes Bone Chandler `Wares` / `ChessSet` and Almshouse `Cots` / `Window` hotspots. `ChessSet` carries the returned-calcification aging read without awarding the script-mentioned `cf_cruel_receipts`; the Almshouse cots/window carry salt-sheet and harbor-light art anchors without awarding `cf_cow_father`, because the Litany source of truth marks those confessions as Act II.
- Borrowed Heartbeat now models the authored pulse-plus-warmth timing requirement: Juno's table conversation names the Church rate card as the price of the pump governor, the regulator trade grants pool permission without awarding overheard confessions, `HotPool` starts a three-room-transition `FL_float_warmth_active` window with amber-screen/steam privacy staging and a no-sensation body read, the Harbormaster anteroom carries checklist-desk and Sabine-door art anchors, the Harbormaster clerk blocks without warmth, the validator proves wandering three transitions expires it, returning to the pool triggers `juno_warmth_expired`, and the direct/re-soaked Float-to-clerk route completes.
- The Grey Float pump governor now has captured blocked setup before `IT_rate_card`; the automated route proves `BilgeRegulator` cannot grant `IT_regulator` early, then later records Juno's rate-card trade as the actual acquisition.
- The Grey Float staff corner now lives in Ink as `float_staff_corner`, is wired to `StaffCorner`, gives the staff names/opinions/tip grievances per the hard-R content line, and offers `cf_lust_float` plus `cf_cow_apologize` as Act I-safe overheard pickups without adding any confession-spend interaction. The permutation validator proves `cf_lust_float` is discovered there when Heartbeat precedes Name; the critical Name-first route proves it stays locked if the Registrar has already spoken it.
- The Grey Float rate-card/regulator trade now preserves Juno's long look at the Church rate card before she gives up the pump governor, so the scene carries her displaced information-trade history as visual staging instead of just an item swap.
- The Grey Float now has an authored Juno negotiation at `JunoTable` and a hard-R steam silhouette staging anchor at `SteamScreen`; `JunoTable` points the player toward the rate-card trade without opening the hot pool early, and `SteamScreen` frames privacy as heat/shadow/consent rather than explicit depiction.
- The Harbormaster anteroom now has authored `ChecklistDesk` and `SabineDoor` hotspots in `harbormaster_checklist_desk` and `harbormaster_sabine_door`, capturing the three-box Rite checklist, frosted-glass Sabine door, and one-room-away staging before the fake-pulse check.
- The Harbormaster clerk heartbeat check now captures the fake-pulse read in Ink as staged physical action: the clerk takes Corvin's wrist, the regulator ticks four inches off under the coat, the pool warmth passes the hand check, and failed attempts remain repeatable/no-penalty.
- The Act I Sabine office close now preserves the authored physical staging: pen-down first look, water pooling on the floor, Sabine crossing through it, and the extended wrist check. The validator still enforces that Sabine never apologizes.
- Sabine's Act I office scene now lives in Ink as `sabine_act_i_audience`, is wired to `SabineDesk`, and appears in the automated greybox playtest report with the public Kestrel-confession aftermath, wrist/no-pulse beat, final Six/Five exchange, and a scoped validator that keeps Sabine from apologizing.
- The Church poor-box support beat now lives in Ink as `church_poor_box`, is wired to `PoorBox`, stages the crooked-lock/missing-notes theft read, discovers `cf_greed_plate`, and is intentionally captured before the Registrar can lock that confession as opponent-spoken.
- The Church stall sign now lives in Ink as `church_stall_sign`, is wired to a non-progress `ChurchStallSign` hotspot, and captures the one-shilling paid-truth/eleven-deep queue read separately from Teodor's gated rate-card exchange.
- The Salt Market confession queue now stages the eleven-person paid-truth line in Ink before awarding the Act I-safe `cf_cruel_funeral` eavesdrop pickup.
- The Church confession booth now lives in Ink as `church_confession_booth`, is wired to `ConfessionBooth`, awards `IT_chit`, and sets `FL_church_booth_seen` / `FL_chit_acquired`; the fuller petitioner/confession-spend booth sequence remains deferred.
- Teodor's rate-card booth scene now lives in Ink as `teodor_rate_card_booth`, is wired to the Church `RateCard` hotspot, requires `IT_chit`, sets `FL_teodor_owes` / `FL_rate_card` / `FL_kane_seen`, discovers `cf_cruel_sentences`, captures Teodor's posting panic, the three fixed petitioner beats, and Kane's day-six pressure line, and keeps the fuller petitioner-choice/confession-spend booth sequence deferred so the accepted duel format stays intact.
- Generated Act I hotspots and exits are now checked for look/use/talk/walk/wet response coverage, non-placeholder copy, and blocked feedback for gated interactions; Mudflats custom tutorial handlers are statically checked for the same verb set.
- `tools\Record-ActIGreyboxPlaytest.ps1` writes `docs\playtest\results\act_i_greybox_auto_report.md`, a deterministic critical-path transcript for comparing the greybox build against the authored Act I script.
- `tools\Validate-ActIPuzzleGraph.ps1` validates `docs\act_i_puzzle_dependency_graph.json` for unique nodes, valid edges, acyclicity, required Rite nodes, Act I completion prerequisites, and non-linear Rite independence.
- `tools\Validate-ActIConfessionActGate.ps1` validates that Act I room scenes and prologue Ink `confession:discover` tags do not grant Act II/III confessions.
- `tools\Run-Step4Gates.ps1` now includes the dependency graph, room graph/reachability, single critical route, and six-order Rite permutation validation.
- The Confession Duel format is locked as accepted for this prototype; room work should preserve the current Litany selector flow, strict counter math, global spend state, and Registrar route unless a separate balance pass explicitly changes it.
- `cf_pride_eulogy`, `cf_cow_didntfight`, `cf_cruel_receipts`, `cf_cruel_names`, `cf_cow_father`, `cf_greed_ring`, `cf_pride_handwriting`, and `cf_lust_hands` remain deferred despite script/source mentions, because the Litany source of truth marks those confessions Act II or Act III.

Run it manually:

```powershell
dotnet run --project prototype\Corpse.DuelConsole
dotnet run --project prototype\Corpse.DuelConsole -- --debug-valid
dotnet run --project prototype\Corpse.DuelConsole -- --balance
dotnet run --project prototype\Corpse.DuelConsole -- --record-playtest
```
