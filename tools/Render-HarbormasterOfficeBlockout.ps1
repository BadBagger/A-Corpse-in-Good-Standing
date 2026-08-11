$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")
$blender = Get-CorpseBlenderPath

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\harbormaster_office.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\harbormaster_office_bg.png"
$godotPng = Join-Path $root "game\rooms\harbormaster_office\background\harbormaster_office_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_harbormaster_office_blockout.py"

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
bone = material("palette_bone_paper_white_E4DCC8", (0xE4/255, 0xDC/255, 0xC8/255, 1))
black = material("palette_wet_black_0C1013", (0x0C/255, 0x10/255, 0x13/255, 1))
slate = material("palette_harbor_slate_2A3A40", (0x2A/255, 0x3A/255, 0x40/255, 1))
amber = material("palette_whale_oil_amber_C98A3C_living_bureaucracy", (0xC9/255, 0x8A/255, 0x3C/255, 1))
green = material("palette_absinthe_green_7D9B4E_warmth_failure_hint", (0x7D/255, 0x9B/255, 0x4E/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("office_wall_harbor_slate", 0, 0.55, 18.2, 6.6, slate)
box("walk_band_y650_800_polished_floor", 0, -2.25, 18.4, 2.5, bone)
box("checklist_desk_three_boxes", -2.2, -1.65, 2.45, 0.9, amber)
box("procedural_clerk_obstruction", 0, -1.65, 0.6, 1.5, black)
box("sabine_frosted_glass_door", 5.4, -0.9, 1.75, 2.75, bone)
box("sabine_nameplate_black", 5.4, -0.25, 1.25, 0.22, black)
box("exit_grey_float", -7.8, -2.0, 1.25, 1.65, amber)
box("exit_sabine_gated", 7.4, -2.1, 1.3, 1.55, amber)
box("pulse_check_space", 0.55, -1.85, 1.15, 0.35, green)

for name, px, py in [
    ("to_grey_float", 180, 740),
    ("to_sabine", 1700, 730),
    ("checklist_desk", 740, 690),
    ("checklist_clerk", 960, 700),
    ("sabine_door", 1500, 665),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "clerk" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "harbormaster_office"
bpy.context.scene["room_code"] = "R11"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["critical_hotspots"] = "ChecklistDesk, ChecklistClerk, SabineDoor, ToGreyFloat, ToSabine"
bpy.context.scene["gate_contract"] = "ChecklistClerk requires IT_regulator and FL_float_warmth_active; ToSabine requires all three Act I rites."
bpy.context.scene["staging_note"] = "Clerk reads as procedural obstruction, not villain; Sabine presence is felt through frosted glass before she appears."
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Harbormaster Office blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseHarbormasterOfficeReviewRaster
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

            // Office pressure: narrow process lane, desk, clerk, and the one-room-away door.
            g.FillRectangle(black, 180, 185, 1120, 52);
            g.FillRectangle(amber, 620, 640, 260, 82);
            g.FillRectangle(bone, 675, 600, 122, 42);
            g.FillRectangle(black, 692, 608, 16, 18);
            g.FillRectangle(black, 728, 608, 16, 18);
            g.FillRectangle(black, 764, 608, 16, 18);
            g.FillRectangle(black, 935, 606, 52, 188);
            g.FillRectangle(green, 995, 698, 95, 34);

            // Frosted Sabine door with black name band.
            g.FillRectangle(bone, 1410, 475, 180, 310);
            g.FillRectangle(black, 1438, 545, 126, 34);
            g.FillRectangle(slate, 1464, 595, 74, 122);
            g.FillRectangle(amber, 105, 660, 145, 180);
            g.FillRectangle(amber, 1634, 655, 150, 178);

            // Corvin side-scale proxy at the desk, leaving room for wrist/pulse staging.
            g.FillRectangle(black, 815, 604, 44, 196);
            g.FillRectangle(green, 841, 760, 8, 42);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseHarbormasterOfficeReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Harbormaster Office blockout output was not created: $requiredPath"
    }
}

Write-Host "Harbormaster Office blockout blend -> $sourceBlend"
Write-Host "Harbormaster Office blockout render -> $exportPng"
Write-Host "Harbormaster Office Godot background -> $godotPng"
