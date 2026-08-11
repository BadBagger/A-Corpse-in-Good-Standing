# Step 2 Checkpoint - Prologue Scaffold

## Scope

This checkpoint starts Step 2 after Kyle accepted the Confession Duel format.

Implemented now:

- Godot project shell pinned to Godot 4.6.3 .NET.
- Popochiu 2.1.1 addon vendored under `addons/popochiu`.
- Popochiu autoloads declared in `project.godot`.
- Temporary high-resolution simple-click GUI template selected for scaffolding.
- Prologue verb coin overlay with Walk, Look, Use, Talk.
- Prologue inventory strip with stateful item display.
- Real Popochiu inventory item placeholders:
  - HarborMud
  - BorrowedBoots
- Prologue greybox room: `game/rooms/mudflats/room_mudflats.tscn`.
- Placeholder player character: `game/characters/corvin/character_corvin.tscn`.
- First key hotspots staged as greybox placeholders:
  - Bollard-of-Tomas
  - Missing Boots
  - Salt Market exit

Not implemented yet:

- Final verb coin UI.
- Final inventory UI art and animations.
- Popochiu editor-generated room/object metadata beyond the Mudflats starter room.
- Ink runtime binding.
- Final art.

## Toolchain

Godot executable found:

```text
C:\Users\KyleB\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine.Mono_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64_console.exe
```

Popochiu release:

```text
v2.1.1
```

## Automated Gate Command

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step2Gates.ps1
```

Known validation noise:

- Popochiu UID fallback warnings after vendoring the addon.
- Godot headless teardown leak reports after `--quit`.

The validation script still fails on runtime `SCRIPT ERROR` lines and non-teardown `ERROR` lines.
