$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
if (-not (Test-Path -LiteralPath $blender)) {
    throw "Blender executable not found: $blender"
}

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\almshouse.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\almshouse_bg.png"
$godotPng = Join-Path $root "game\rooms\almshouse\background\almshouse_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_almshouse_blockout.py"

foreach ($dir in @(
    (Split-Path -Parent $sourceBlend),
    (Split-Path -Parent $exportPng),
    (Split-Path -Parent $godotPng)
)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

$python = @'
import bpy
import math
import os

SOURCE_BLEND = r"__SOURCE_BLEND__"

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    return mat

def box(name, x, z, sx, sz, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 0, z))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (sx, 0.08, sz)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj

clear_scene()
bone = material("palette_bone_paper_white_E4DCC8_cots", (0xE4/255, 0xDC/255, 0xC8/255, 1))
black = material("palette_wet_black_0C1013_still_occupants", (0x0C/255, 0x10/255, 0x13/255, 1))
slate = material("palette_harbor_slate_2A3A40_charity_room", (0x2A/255, 0x3A/255, 0x40/255, 1))
amber = material("palette_whale_oil_amber_C98A3C_kindness_light", (0xC9/255, 0x8A/255, 0x3C/255, 1))
green = material("palette_absinthe_green_7D9B4E_memory_rot_hint", (0x7D/255, 0x9B/255, 0x4E/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("almshouse_wall_harbor_slate", 0, 0.55, 18.2, 6.6, slate)
box("walk_band_y650_800_worn_floor", 0, -2.25, 18.4, 2.5, bone)
box("cot_row_three_too_still", -4.0, -1.7, 2.4, 1.2, bone)
box("harbor_window_cruel_light", -1.8, -0.8, 1.5, 1.65, bone)
box("prosper_remeeting_chair", 0.2, -1.85, 0.65, 1.2, black)
box("forgiveness_writing_surface", 1.0, -1.65, 1.65, 0.75, amber)
box("hand_memory_signing_space", 1.45, -1.25, 0.75, 0.18, green)
box("exit_bone_chandler", -7.8, -2.0, 1.25, 1.65, amber)
box("exit_salt_market", 7.4, -2.1, 1.3, 1.55, amber)

for name, px, py in [
    ("to_bone_chandler", 180, 740),
    ("to_salt_market", 1700, 730),
    ("cots", 560, 720),
    ("window", 780, 650),
    ("half_coin_prosper", 980, 700),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "prosper" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "almshouse"
bpy.context.scene["room_code"] = "R07"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["critical_hotspots"] = "Cots, Window, HalfCoinProsper, ToBoneChandler, ToSaltMarket"
bpy.context.scene["gate_contract"] = "HalfCoinProsper requires IT_watch, awards IT_forgiveness, sets FL_rite_debt, blocked by prosper_before_watch."
bpy.context.scene["staging_note"] = "Prosper is pleasant and unstable; reserve writing surface and hand-memory hesitation before signature."
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Almshouse blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseAlmshouseReviewRaster
{
    private static readonly Color Bone = Color.FromArgb(255, 0xE4, 0xDC, 0xC8);
    private static readonly Color WetBlack = Color.FromArgb(255, 0x0C, 0x10, 0x13);
    private static readonly Color Slate = Color.FromArgb(255, 0x2A, 0x3A, 0x40);
    private static readonly Color Green = Color.FromArgb(255, 0x7D, 0x9B, 0x4E);
    private static readonly Color Amber = Color.FromArgb(255, 0xC9, 0x8A, 0x3C);

    public static void Draw(string path)
    {
        using (var bitmap = new Bitmap(1920, 1080, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(bitmap))
        using (var bone = new SolidBrush(Bone))
        using (var black = new SolidBrush(WetBlack))
        using (var slate = new SolidBrush(Slate))
        using (var green = new SolidBrush(Green))
        using (var amber = new SolidBrush(Amber))
        {
            g.Clear(WetBlack);
            g.FillRectangle(slate, 55, 120, 1810, 540);
            g.FillRectangle(bone, 0, 650, 1920, 430);

            // Rows of cots with three quiet, maybe-too-still occupants.
            g.FillRectangle(bone, 440, 670, 250, 58);
            g.FillRectangle(bone, 440, 740, 250, 58);
            g.FillRectangle(bone, 440, 810, 250, 58);
            g.FillRectangle(black, 485, 682, 48, 28);
            g.FillRectangle(black, 550, 752, 48, 28);
            g.FillRectangle(black, 610, 822, 48, 28);

            // Window facing the harbor.
            g.FillRectangle(bone, 700, 495, 155, 210);
            g.FillRectangle(black, 726, 525, 103, 150);
            g.FillRectangle(slate, 744, 545, 68, 112);

            // Prosper's fresh-meeting/signature staging.
            g.FillRectangle(black, 948, 600, 46, 190);
            g.FillRectangle(green, 974, 758, 8, 42);
            g.FillRectangle(amber, 1035, 645, 175, 78);
            g.FillRectangle(bone, 1080, 610, 95, 35);
            g.FillRectangle(green, 1130, 630, 58, 14);

            // Exits and Corvin scale.
            g.FillRectangle(amber, 105, 660, 145, 180);
            g.FillRectangle(amber, 1634, 655, 150, 178);
            g.FillRectangle(black, 850, 604, 44, 196);
            g.FillRectangle(green, 876, 760, 8, 42);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseAlmshouseReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Almshouse blockout output was not created: $requiredPath"
    }
}

Write-Host "Almshouse blockout blend -> $sourceBlend"
Write-Host "Almshouse blockout render -> $exportPng"
Write-Host "Almshouse Godot background -> $godotPng"
