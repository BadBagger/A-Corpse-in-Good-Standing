$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")
$blender = Get-CorpseBlenderPath

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\grey_float.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\grey_float_bg.png"
$godotPng = Join-Path $root "game\rooms\grey_float\background\grey_float_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_grey_float_blockout.py"

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
amber = material("palette_whale_oil_amber_C98A3C_float_unsafe_warmth", (0xC9/255, 0x8A/255, 0x3C/255, 1))
green = material("palette_absinthe_green_7D9B4E_regulator_hint", (0x7D/255, 0x9B/255, 0x4E/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("barge_hull_interior_harbor_slate", 0, 0.45, 18.2, 6.5, slate)
box("walk_band_y650_800_wet_deck", 0, -2.25, 18.4, 2.5, bone)
box("amber_unsafe_float_lamplight", 2.2, -0.6, 8.2, 3.3, amber)
box("juno_power_table", -5.1, -1.55, 2.15, 0.95, amber)
box("staff_corner_backbench", -3.35, -1.75, 1.8, 0.75, slate)
box("clockwork_bilge_regulator_heart", -0.6, -1.78, 0.82, 0.82, green)
box("hot_pool_amber_warmth", 2.6, -1.9, 2.15, 0.92, amber)
box("steam_screen_backlight_silhouettes", 4.9, -1.12, 2.15, 2.2, amber)
box("exit_church", -7.8, -2.0, 1.25, 1.65, amber)
box("exit_harbormaster", 7.4, -2.1, 1.3, 1.55, amber)

for name, px, py in [
    ("to_church", 180, 740),
    ("to_harbormaster", 1700, 730),
    ("juno_table", 450, 675),
    ("staff_corner", 620, 710),
    ("bilge_regulator", 900, 700),
    ("hot_pool", 1220, 720),
    ("steam_screen", 1450, 650),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, green if "regulator" in name else amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "grey_float"
bpy.context.scene["room_code"] = "R10"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["content_line"] = "Hard R only: steam, backlight, silhouettes; no explicit anatomy or sex-act depiction."
bpy.context.scene["palette_exception"] = "The Grey Float is amber-lit but unsafe."
bpy.context.scene["duel_format_lock"] = "Grey Float contains confession-source and item-gated beats only; no duel or confession-spend interface is introduced."
bpy.context.scene["critical_hotspots"] = "JunoTable, SteamScreen, BilgeRegulator, StaffCorner, HotPool, ToChurch, ToHarbormaster"
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Grey Float blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseGreyFloatReviewRaster
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

            // Barge hull, amber warmth, and exits.
            g.FillRectangle(black, 120, 190, 1680, 82);
            g.FillRectangle(amber, 820, 440, 760, 355);
            g.FillRectangle(amber, 105, 660, 145, 180);
            g.FillRectangle(amber, 1634, 655, 150, 178);

            // Juno's table: ledgers, rings, and the chair nobody borrows.
            g.FillRectangle(amber, 350, 632, 220, 82);
            g.FillRectangle(black, 382, 606, 78, 34);
            g.FillRectangle(bone, 470, 604, 46, 30);
            g.FillRectangle(black, 505, 718, 42, 74);

            // Staff corner: workers with grievances, staged as people, not ornament.
            g.FillRectangle(slate, 560, 690, 155, 72);
            g.FillRectangle(black, 592, 660, 24, 105);
            g.FillRectangle(black, 636, 668, 24, 96);
            g.FillRectangle(black, 681, 674, 24, 88);

            // Clockwork bilge regulator, readable as a heart substitute.
            g.FillRectangle(green, 866, 662, 82, 82);
            g.FillRectangle(black, 892, 684, 30, 38);
            g.FillRectangle(bone, 896, 646, 24, 18);

            // Hot pool and warmth route.
            g.FillRectangle(amber, 1110, 684, 230, 96);
            g.FillRectangle(bone, 1140, 704, 168, 32);
            g.FillRectangle(amber, 1160, 630, 28, 48);
            g.FillRectangle(amber, 1230, 624, 28, 54);

            // Steam screen: hard-R silhouette/backlight, no anatomy detail.
            g.FillRectangle(amber, 1360, 492, 220, 260);
            g.FillRectangle(bone, 1396, 475, 38, 292);
            g.FillRectangle(bone, 1508, 475, 38, 292);
            g.FillRectangle(black, 1438, 610, 28, 120);
            g.FillRectangle(black, 1484, 622, 28, 108);

            // Corvin side-scale proxy near the edge of the unsafe amber.
            g.FillRectangle(black, 742, 604, 44, 196);
            g.FillRectangle(green, 768, 760, 8, 42);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseGreyFloatReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Grey Float blockout output was not created: $requiredPath"
    }
}

Write-Host "Grey Float blockout blend -> $sourceBlend"
Write-Host "Grey Float blockout render -> $exportPng"
Write-Host "Grey Float Godot background -> $godotPng"
