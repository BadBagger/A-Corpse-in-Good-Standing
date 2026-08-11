# Source Control Readiness

Status: pass

This gate protects the new repo from committing local Godot caches, build output, Blender backups, or large production binaries without Git LFS coverage.

Git LFS: git-lfs/3.7.1 (GitHub; windows amd64; go 1.25.1; git b84b3384)

## Ignore Coverage

- `bin/`
- `obj/`
- `.godot/`
- `.import/`
- `*.tmp`
- `*.bak`
- `*.blend1`
- `*.log`
- `_incoming_*/`

## Git LFS Coverage

- `*.blend`
- `*.glb`
- `*.gltf`
- `*.fbx`
- `*.psd`
- `*.png`
- `*.jpg`
- `*.jpeg`
- `*.webp`
- `*.tif`
- `*.tiff`
- `*.exr`
- `*.hdr`
- `*.wav`
- `*.ogg`
- `*.mp3`
- `*.flac`
- `*.zip`
- `*.7z`
- `*.rar`
- `*.exe`

## Oversized Files Checked

- `art/src/shaders/ink_wash_shader_spike.blend` - 94.69 MB - covered_by_lfs
- `art/src/shaders/ink_wash_shader_spike.blend1` - 94.69 MB - ignored_backup
- `art/src/characters/corvin/corvin_act_i_clean.blend` - 94.69 MB - covered_by_lfs
- `art/src/characters/corvin/corvin_act_i_clean.blend1` - 94.69 MB - ignored_backup
- `art/src/characters/corvin/meshy/corvin_act_i_clean.glb` - 61.2 MB - covered_by_lfs
- `tools/ink/inklecate.exe` - 56.46 MB - covered_by_lfs

Notes:
- `.blend1` files are Blender backups and should stay ignored, not source-tracked.
- `tools/ink/inklecate.exe` is a binary tool and is covered by LFS if committed.
- Source art and exported runtime art are intentionally kept in the repo, but large binary formats must route through LFS.
