# CI Gate Boundary

Purpose: define what GitHub Actions currently proves, and what remains local-only.

## GitHub Actions Coverage

Workflow: `.github/workflows/headless-gates.yml`

The `Headless Gates` workflow currently proves:

- Git LFS checkout is enabled for large tracked assets.
- .NET 8 is installed for the standalone duel domain.
- Repo readiness gates pass:
  - source-control and LFS readiness
  - text artifact hygiene
  - production blocker index validation
  - production blocker index negative-control test
- Step 1 Confession Duel gates pass:
  - confession export
  - confession library validation
  - duel content validation
  - `dotnet test CorpseInGoodStanding.sln`
  - duel console smoke test
  - balance report generation

## Local-Only Gates

Step 2 and later gates remain local-only right now because the Godot gate scripts call Kyle's installed Godot 4.6.3 .NET console executable directly:

`C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe`

The local-only boundary covers:

- `tools\Run-Step2Gates.ps1`
- `tools\Run-Step3Gates.ps1`
- `tools\Run-Step4Gates.ps1`
- `tools\Run-Step5ReadinessGates.ps1`
- Godot/Popochiu room, Ink bridge, Corvin runtime sprite, and Act I greybox route validation
- Blender/shader/art-pass readiness checks that depend on local render tooling

## Required Before Broadening CI

Do not add Step 2-5 to GitHub Actions until the workflow installs or restores a portable Godot 4.6.3 .NET executable and any required render tools without relying on Kyle's user-profile path.

When that happens, the workflow must still preserve the project guardrails:

- Keep the accepted Litany/Registrar duel format.
- Do not add a second confession-spend UI.
- Do not treat scratch VO as shipping-approved audio.
- Do not start final Act I paintovers before human review signoff.
