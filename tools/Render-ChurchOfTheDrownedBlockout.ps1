$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
if (-not (Test-Path -LiteralPath $blender)) {
    throw "Blender executable not found: $blender"
}

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\church_of_the_drowned.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\church_of_the_drowned_bg.png"
$godotPng = Join-Path $root "game\rooms\church_of_the_drowned\background\church_of_the_drowned_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_church_of_the_drowned_blockout.py"

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
green = material("palette_absinthe_green_7D9B4E_church_economy", (0x7D/255, 0x9B/255, 0x4E/255, 1))
amber = material("palette_whale_oil_amber_C98A3C_exit_warmth", (0xC9/255, 0x8A/255, 0x3C/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("bone_rib_nave_wall", 0, 0.7, 17.8, 6.7, slate)
box("walk_band_y650_800_worn_stone", 0, -2.25, 18.2, 2.5, bone)
box("leviathan_rib_arch_left", -5.4, 1.2, 0.26, 6.2, bone)
box("leviathan_rib_arch_right", 5.4, 1.2, 0.26, 6.2, bone)
box("confession_booth_green_box", -1.8, -1.1, 1.3, 2.2, green)
box("teodor_rate_card_stall", -0.2, -1.55, 1.7, 1.35, green)
box("poor_box_bad_lock", -3.4, -1.9, 0.9, 0.75, amber)
box("stall_sign_paid_truth", 1.4, -0.45, 1.65, 0.58, bone)
box("exit_salt_market", -7.8, -2.0, 1.25, 1.65, amber)
box("exit_grey_float", 7.4, -2.1, 1.3, 1.55, amber)

for name, px, py in [
    ("to_salt_market", 180, 740),
    ("to_grey_float", 1700, 730),
    ("poor_box", 620, 720),
    ("confession_booth", 780, 650),
    ("teodor_rate_card_stall", 940, 700),
    ("church_stall_sign", 1100, 585),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "booth" in name or "stall" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "church_of_the_drowned"
bpy.context.scene["room_code"] = "R09"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["duel_format_lock"] = "Church contains confession-source and item-gated beats only; no duel or confession-spend interface is introduced."
bpy.context.scene["critical_hotspots"] = "PoorBox, ConfessionBooth, ChurchStallSign, RateCard, ToSaltMarket, ToGreyFloat"
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Church of the Drowned blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseChurchOfTheDrownedReviewRaster
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
            g.FillRectangle(slate, 70, 115, 1780, 540);
            g.FillRectangle(bone, 0, 650, 1920, 430);

            // Whale-rib church architecture, kept blocky for paintover and path reads.
            g.FillRectangle(bone, 235, 160, 38, 520);
            g.FillRectangle(bone, 1648, 155, 38, 525);
            g.FillRectangle(bone, 430, 130, 32, 470);
            g.FillRectangle(bone, 1456, 130, 32, 470);
            g.FillRectangle(black, 305, 185, 92, 340);
            g.FillRectangle(black, 1525, 185, 92, 340);

            // Navigation exits.
            g.FillRectangle(amber, 105, 660, 145, 180);
            g.FillRectangle(amber, 1634, 655, 150, 178);

            // Confession economy anchors.
            g.FillRectangle(green, 705, 505, 150, 235);
            g.FillRectangle(black, 748, 555, 62, 142);
            g.FillRectangle(green, 872, 615, 175, 126);
            g.FillRectangle(bone, 910, 575, 115, 42);
            g.FillRectangle(bone, 1026, 545, 150, 58);
            g.FillRectangle(green, 1044, 608, 112, 92);
            g.FillRectangle(amber, 575, 685, 92, 88);
            g.FillRectangle(black, 628, 688, 28, 18);

            // Queue silhouettes: suggest pressure without creating a second duel UI.
            g.FillRectangle(black, 1110, 700, 24, 76);
            g.FillRectangle(black, 1160, 704, 24, 72);
            g.FillRectangle(black, 1210, 710, 24, 66);
            g.FillRectangle(black, 1260, 716, 24, 60);

            // Corvin side-scale proxy, standing just outside the green institutional light.
            g.FillRectangle(black, 495, 604, 44, 196);
            g.FillRectangle(green, 520, 760, 8, 42);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseChurchOfTheDrownedReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Church of the Drowned blockout output was not created: $requiredPath"
    }
}

Write-Host "Church of the Drowned blockout blend -> $sourceBlend"
Write-Host "Church of the Drowned blockout render -> $exportPng"
Write-Host "Church of the Drowned Godot background -> $godotPng"
