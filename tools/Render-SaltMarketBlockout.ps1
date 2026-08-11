$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")
$blender = Get-CorpseBlenderPath

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\salt_market.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\salt_market_bg.png"
$godotPng = Join-Path $root "game\rooms\salt_market\background\salt_market_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_salt_market_blockout.py"

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
green = material("palette_absinthe_green_7D9B4E_hotspot_proof", (0x7D/255, 0x9B/255, 0x4E/255, 1))
amber = material("palette_whale_oil_amber_C98A3C_living_light", (0xC9/255, 0x8A/255, 0x3C/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("market_back_wall_harbor_slate", 0, 0.6, 19.2, 7.2, slate)
box("walk_band_y650_800", 0, -2.2, 18.4, 2.6, bone)

for name, px, py in [
    ("to_old_quay", 180, 740),
    ("to_registry", 520, 650),
    ("to_chandler", 820, 655),
    ("to_almshouse", 1120, 655),
    ("to_fish_hall", 1390, 655),
    ("to_church", 1660, 650),
    ("boot_stall", 300, 720),
    ("fishmonger", 520, 720),
    ("market_crowd", 960, 760),
    ("confession_queue", 1180, 720),
    ("church_sign_wet", 1380, 540),
    ("whale_oil_lamp", 1520, 620),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "wet" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "salt_market"
bpy.context.scene["room_code"] = "R03"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["duel_format_lock"] = "Salt Market is a hub and confession-source room only; no duel or confession-spend interface is introduced."
bpy.context.scene["critical_hotspots"] = "six hub exits, MarketCrowd, BootStall, Fishmonger, ConfessionQueue, ChurchSign wet verb, WhaleOilLamp"
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Salt Market blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseSaltMarketReviewRaster
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
            g.FillRectangle(slate, 0, 120, 1920, 530);
            g.FillRectangle(bone, 0, 650, 1920, 430);

            // Six readable hub exits across the back of the market.
            g.FillRectangle(amber, 115, 660, 130, 160);
            g.FillRectangle(bone, 460, 545, 118, 140);
            g.FillRectangle(bone, 760, 552, 118, 135);
            g.FillRectangle(bone, 1060, 552, 118, 135);
            g.FillRectangle(bone, 1330, 552, 118, 135);
            g.FillRectangle(green, 1600, 515, 120, 170);

            // Market stalls and confession-source beats.
            g.FillRectangle(amber, 245, 680, 150, 80);
            g.FillRectangle(black, 270, 760, 70, 72);
            g.FillRectangle(amber, 470, 690, 130, 52);
            g.FillRectangle(black, 502, 742, 42, 78);
            g.FillRectangle(slate, 890, 670, 175, 112);
            g.FillRectangle(bone, 922, 640, 86, 50);
            g.FillRectangle(green, 1125, 665, 142, 116);
            g.FillRectangle(bone, 1160, 628, 72, 40);

            // Church sign wet target and whale-oil warmth.
            g.FillRectangle(green, 1328, 500, 104, 80);
            g.FillRectangle(amber, 1490, 565, 54, 115);
            g.FillRectangle(amber, 1468, 548, 98, 28);

            // Corvin side-scale proxy and public recognition spacing.
            g.FillRectangle(black, 725, 612, 44, 190);
            g.FillRectangle(green, 748, 764, 8, 44);
            g.FillRectangle(black, 912, 720, 24, 70);
            g.FillRectangle(black, 970, 720, 24, 70);
            g.FillRectangle(black, 1028, 720, 24, 70);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseSaltMarketReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Salt Market blockout output was not created: $requiredPath"
    }
}

Write-Host "Salt Market blockout blend -> $sourceBlend"
Write-Host "Salt Market blockout render -> $exportPng"
Write-Host "Salt Market Godot background -> $godotPng"
