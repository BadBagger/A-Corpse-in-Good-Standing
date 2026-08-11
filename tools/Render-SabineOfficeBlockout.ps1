$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")
$blender = Get-CorpseBlenderPath

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\sabine_office.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\sabine_office_bg.png"
$godotPng = Join-Path $root "game\rooms\sabine_office\background\sabine_office_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_sabine_office_blockout.py"

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
amber = material("palette_whale_oil_amber_C98A3C_living_office", (0xC9/255, 0x8A/255, 0x3C/255, 1))
green = material("palette_absinthe_green_7D9B4E_dead_water_hint", (0x7D/255, 0x9B/255, 0x4E/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("office_wall_harbor_slate", 0, 0.55, 18.2, 6.6, slate)
box("walk_band_y650_800_dry_floor", 0, -2.25, 18.4, 2.5, bone)
box("sabine_dominant_dry_desk", 0, -1.65, 3.6, 1.05, amber)
box("desk_ordered_papers", -0.65, -1.0, 1.05, 0.28, bone)
box("marlinspike_anchor", 0.9, -1.02, 0.45, 0.12, black)
box("corvin_water_pool", -1.15, -2.15, 1.75, 0.25, green)
box("wrist_check_silence_space", 0.75, -2.05, 1.2, 0.3, green)
box("exit_harbormaster", -7.8, -2.0, 1.25, 1.65, amber)

for name, px, py in [
    ("to_harbormaster", 180, 740),
    ("sabine_desk", 960, 690),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "desk" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "sabine_office"
bpy.context.scene["room_code"] = "R12"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["critical_hotspots"] = "SabineDesk, ToHarbormaster"
bpy.context.scene["gate_contract"] = "SabineDesk requires FL_rite_name, FL_rite_debt, and FL_rite_heartbeat; use sets FL_act_i_complete."
bpy.context.scene["staging_note"] = "Dominant dry desk, Corvin water pooling, Sabine crosses water without reacting, wrist-check silence space."
bpy.context.scene["character_rule"] = "Sabine explains and never apologizes."
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Sabine Office blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseSabineOfficeReviewRaster
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

            // The desk is dry, ordered, and dominant.
            g.FillRectangle(amber, 740, 620, 445, 92);
            g.FillRectangle(amber, 800, 575, 320, 58);
            g.FillRectangle(bone, 850, 590, 120, 28);
            g.FillRectangle(bone, 986, 588, 84, 24);
            g.FillRectangle(black, 1100, 596, 48, 12);

            // Corvin's water and the wrist-check silence space.
            g.FillRectangle(green, 770, 762, 172, 28);
            g.FillRectangle(green, 1000, 726, 120, 30);
            g.FillRectangle(black, 836, 604, 44, 196);
            g.FillRectangle(green, 862, 760, 8, 42);

            // Sabine staging: close enough for wrist check, never apologetic.
            g.FillRectangle(black, 1040, 600, 46, 190);
            g.FillRectangle(amber, 1058, 760, 14, 42);

            // Controlled office composition and return exit.
            g.FillRectangle(black, 260, 180, 920, 52);
            g.FillRectangle(amber, 105, 660, 145, 180);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseSabineOfficeReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Sabine Office blockout output was not created: $requiredPath"
    }
}

Write-Host "Sabine Office blockout blend -> $sourceBlend"
Write-Host "Sabine Office blockout render -> $exportPng"
Write-Host "Sabine Office Godot background -> $godotPng"
