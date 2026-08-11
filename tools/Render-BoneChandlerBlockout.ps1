$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
if (-not (Test-Path -LiteralPath $blender)) {
    throw "Blender executable not found: $blender"
}

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\bone_chandler.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\bone_chandler_bg.png"
$godotPng = Join-Path $root "game\rooms\bone_chandler\background\bone_chandler_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_bone_chandler_blockout.py"

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
bone = material("palette_bone_paper_white_E4DCC8_inventory", (0xE4/255, 0xDC/255, 0xC8/255, 1))
black = material("palette_wet_black_0C1013_deep_shelves", (0x0C/255, 0x10/255, 0x13/255, 1))
slate = material("palette_harbor_slate_2A3A40_shop_wall", (0x2A/255, 0x3A/255, 0x40/255, 1))
amber = material("palette_whale_oil_amber_C98A3C_trade_light", (0xC9/255, 0x8A/255, 0x3C/255, 1))
green = material("palette_absinthe_green_7D9B4E_returned_salt_hint", (0x7D/255, 0x9B/255, 0x4E/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("shop_wall_harbor_slate", 0, 0.55, 18.2, 6.6, slate)
box("walk_band_y650_800_shop_floor", 0, -2.25, 18.4, 2.5, bone)
box("bone_wares_shelf", -4.0, -1.25, 2.4, 2.25, bone)
box("chess_set_old_white_new_dark", -1.7, -1.6, 1.2, 0.72, amber)
box("prosper_watch_under_glass", 0.5, -1.62, 1.15, 0.82, amber)
box("glass_barrier", 0.5, -1.28, 1.35, 0.14, bone)
box("fresh_salt_trade_space", 1.35, -1.85, 0.95, 0.35, green)
box("exit_salt_market", -7.8, -2.0, 1.25, 1.65, amber)
box("exit_almshouse", 7.4, -2.1, 1.3, 1.55, amber)

for name, px, py in [
    ("to_salt_market", 180, 740),
    ("to_almshouse", 1700, 730),
    ("wares", 560, 700),
    ("chess_set", 790, 680),
    ("prosper_watch", 1010, 700),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "watch" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "bone_chandler"
bpy.context.scene["room_code"] = "R06"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["critical_hotspots"] = "Wares, ChessSet, ProsperWatch, ToSaltMarket, ToAlmshouse"
bpy.context.scene["gate_contract"] = "ProsperWatch requires IT_knuckle_salt, awards IT_watch, sets FL_watch_recovered, blocked by chandler_needs_salt."
bpy.context.scene["tone_note"] = "Body-horror artisanal, not gory; no arterial red in this pass."
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Bone Chandler blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseBoneChandlerReviewRaster
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

            // Returned-remains inventory reads before text does.
            g.FillRectangle(bone, 440, 500, 250, 245);
            g.FillRectangle(black, 470, 530, 190, 34);
            g.FillRectangle(black, 470, 590, 190, 34);
            g.FillRectangle(black, 470, 650, 190, 34);
            g.FillRectangle(bone, 500, 548, 26, 28);
            g.FillRectangle(bone, 548, 606, 26, 28);
            g.FillRectangle(bone, 600, 666, 26, 28);

            // Old white pieces versus newer dark pieces.
            g.FillRectangle(amber, 728, 640, 140, 70);
            g.FillRectangle(bone, 754, 610, 20, 62);
            g.FillRectangle(bone, 790, 618, 20, 54);
            g.FillRectangle(black, 826, 620, 20, 52);
            g.FillRectangle(black, 858, 626, 20, 46);

            // Prosper's watch under glass behind the counter.
            g.FillRectangle(amber, 955, 632, 138, 88);
            g.FillRectangle(bone, 940, 612, 168, 20);
            g.FillRectangle(black, 995, 652, 38, 48);
            g.FillRectangle(green, 1118, 698, 92, 28);

            // Exits and Corvin scale.
            g.FillRectangle(amber, 105, 660, 145, 180);
            g.FillRectangle(amber, 1634, 655, 150, 178);
            g.FillRectangle(black, 840, 604, 44, 196);
            g.FillRectangle(green, 866, 760, 8, 42);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseBoneChandlerReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Bone Chandler blockout output was not created: $requiredPath"
    }
}

Write-Host "Bone Chandler blockout blend -> $sourceBlend"
Write-Host "Bone Chandler blockout render -> $exportPng"
Write-Host "Bone Chandler Godot background -> $godotPng"
