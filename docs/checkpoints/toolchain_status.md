# Toolchain Status

Local-only audit for Step 2-5 readiness. This report is intentionally not a GitHub Actions gate until CI installs portable Godot and Blender toolchains.

| Tool | Required | Resolved path | Version / proof |
|---|---|---|---|
| Godot console | Godot 4.6.3 .NET | `C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe` | `4.6.3.stable.mono.official.7d41c59c4` |
| Godot windowed | Godot 4.6.3 .NET | `C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64.exe` | executable exists |
| Blender | GLB import and headless render support | `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe` | `Blender 5.2.0 LTS` |
| inklecate | Vendored Ink compiler | `tools/ink/inklecate.exe` | `FE28FD3CBC6C1ADE1EC3FBD76AFAC1DAAC09E2101E699142E2051B838411C608` |

## Environment Overrides

- `CORPSE_GODOT_CONSOLE`
- `CORPSE_GODOT_WINDOWED`
- `CORPSE_GODOT_DIR`
- `CORPSE_BLENDER`
- `CORPSE_BLENDER_DIR`
- `CORPSE_INKLECATE`

## Boundary

This proves local tool discovery only. GitHub Actions still proves repo hygiene and Step 1; Godot/Popochiu rooms, Blender rendering, shader proofs, and Step 2-5 gates remain local-only until portable CI tooling is installed.