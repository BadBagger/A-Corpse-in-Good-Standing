# Production Blocker Index

Purpose: keep the current production blockers visible without weakening the Step 5 stop point.

This is a stable handoff index, not a generated gate report. The authoritative gate artifacts remain the Step 1-5 checkpoint files and the GitHub issues linked below.

## Current State

- Repo source snapshot is published to `BadBagger/A-Corpse-in-Good-Standing`.
- Headless GitHub Actions gates are green for repo readiness and Step 1.
- Local Step 5 readiness gate is green for human review.
- Final Act I paintover work is intentionally blocked until human art/readability signoff.
- Full VO is selected, but shipping VO remains blocked until licensing and minor-speaker decisions are resolved.
- Corvin side idle/walk runtime candidates are validated, but the full production sprite contract is not complete.

## Open Blockers

| Issue | Owner Decision | Current Evidence | Next Action |
|---|---|---|---|
| [#1 Step 5 Human Review: Act I art/readability signoff](https://github.com/BadBagger/A-Corpse-in-Good-Standing/issues/1) | Human review of all 11 Act I rooms before final paintover | `docs/checkpoints/step_5_act_i_art_pass_readiness.md` reports green for review and `0 ready / 11 blocked` for paintover | Run the human review route, fill the decision CSV, dry-run import, then apply approvals/revisions |
| [#2 VO Readiness: licensing and minor-speaker decisions](https://github.com/BadBagger/A-Corpse-in-Good-Standing/issues/2) | Commercial VO licensing/disclosure plus cast/consolidate/cut decisions for 8 minor speakers | `docs/vo/vo_commercial_readiness.md` reports `blocked_pending_licensing_review`; `docs/vo/vo_audio_asset_status.md` tracks 652 expected MP3s, 0 present | Resolve licensing, fill `docs/vo/vo_minor_speaker_decisions_template.csv`, dry-run import, then generate scratch timing audio only for allowed batches |
| [#3 Corvin Animation: complete production sprite contract](https://github.com/BadBagger/A-Corpse-in-Good-Standing/issues/3) | Production animation scope and polish for Corvin beyond side-view prototype | `docs/art/corvin_runtime_sprite_assets_status.json` validates side idle/walk; `docs/art/corvin_animation_asset_status.md` reports `10 present, 119 pending, 129 total` | Polish side walk, then complete agreed front/back/talk/use/wet/decay sheets through the deterministic Meshy/Blender-to-sprite pipeline |

## Verification Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\Run-RepoReadinessGates.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\Run-Step5ReadinessGates.ps1
gh issue list --repo BadBagger/A-Corpse-in-Good-Standing --state open --limit 10
```

## Guardrails

- Do not start final Act I paintovers while the paintover start gate reports `blocked_pending_human_review`.
- Do not treat scratch VO as shipping-approved audio.
- Do not replace the accepted Litany/Registrar duel format or add a second confession-spend UI.
- Do not use diffusion-per-frame character sheets for production animation.
