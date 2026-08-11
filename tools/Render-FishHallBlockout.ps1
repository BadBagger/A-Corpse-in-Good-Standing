$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
if (-not (Test-Path -LiteralPath $blender)) {
    throw "Blender executable not found: $blender"
}

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\fish_hall.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\fish_hall_bg.png"
$godotPng = Join-Path $root "game\rooms\fish_hall\background\fish_hall_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_fish_hall_blockout.py"

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
bone = material("palette_bone_paper_white_E4DCC8_ice_records", (0xE4/255, 0xDC/255, 0xC8/255, 1))
black = material("palette_wet_black_0C1013_cold_void", (0x0C/255, 0x10/255, 0x13/255, 1))
slate = material("palette_harbor_slate_2A3A40_cold_room", (0x2A/255, 0x3A/255, 0x40/255, 1))
amber = material("palette_whale_oil_amber_C98A3C_exit_lamp", (0xC9/255, 0x8A/255, 0x3C/255, 1))
green = material("palette_absinthe_green_7D9B4E_wet_return", (0x7D/255, 0x9B/255, 0x4E/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("fish_hall_wall_harbor_slate", 0, 0.55, 18.2, 6.6, slate)
box("walk_band_y650_800_cold_floor", 0, -2.25, 18.4, 2.5, bone)
box("ice_table_corvin_absence", -3.5, -1.85, 2.25, 0.88, bone)
box("body_shape_in_ice", -3.45, -1.58, 1.15, 0.26, black)
box("coroner_tag_pickup", 0, -1.78, 0.72, 0.42, amber)
box("visitor_book_official_record", 3.0, -1.56, 1.25, 0.78, bone)
box("harbor_return_drain", 5.4, -2.52, 0.85, 0.35, green)
box("exit_salt_market", -7.8, -2.0, 1.25, 1.65, amber)

for name, px, py in [
    ("to_salt_market", 180, 740),
    ("ice_table", 610, 720),
    ("coroner_tag", 960, 710),
    ("visitor_book", 1260, 690),
    ("drain_wet_verb", 1500, 780),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "drain" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "fish_hall"
bpy.context.scene["room_code"] = "R08"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["critical_hotspots"] = "IceTable, CoronerTag, VisitorBook, Drain, ToSaltMarket"
bpy.context.scene["gate_contract"] = "CoronerTag awards IT_coroner_tag and day-count flags; VisitorBook discovers cf_pride_twice and Sabine absence; Drain is wet-verb only."
bpy.context.scene["staging_note"] = "Cold and factual: ice-table absence, official visitor book, visible drain tied to harbor return."
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Fish Hall blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseFishHallReviewRaster
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

            // Ice table with Corvin-shaped absence.
            g.FillRectangle(bone, 500, 662, 240, 78);
            g.FillRectangle(black, 552, 685, 136, 24);
            g.FillRectangle(slate, 515, 740, 210, 34);

            // Coroner tag as a clear pickup silhouette.
            g.FillRectangle(amber, 918, 676, 82, 54);
            g.FillRectangle(black, 950, 688, 22, 28);

            // Visitor book as official record, not loose clutter.
            g.FillRectangle(bone, 1202, 642, 140, 78);
            g.FillRectangle(black, 1220, 664, 102, 12);
            g.FillRectangle(black, 1220, 690, 82, 12);

            // Wet-verb drain tied visually to harbor return.
            g.FillRectangle(green, 1455, 770, 92, 34);
            g.FillRectangle(black, 1478, 780, 48, 14);

            // Exit and Corvin scale.
            g.FillRectangle(amber, 105, 660, 145, 180);
            g.FillRectangle(black, 805, 604, 44, 196);
            g.FillRectangle(green, 831, 760, 8, 42);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseFishHallReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Fish Hall blockout output was not created: $requiredPath"
    }
}

Write-Host "Fish Hall blockout blend -> $sourceBlend"
Write-Host "Fish Hall blockout render -> $exportPng"
Write-Host "Fish Hall Godot background -> $godotPng"
