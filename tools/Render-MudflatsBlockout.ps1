$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")
$blender = Get-CorpseBlenderPath

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\mudflats.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\mudflats_bg.png"
$godotPng = Join-Path $root "game\rooms\mudflats\background\mudflats_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_mudflats_blockout.py"

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
bone = material("palette_bone_paper_white_E4DCC8_leviathan_ribs", (0xE4/255, 0xDC/255, 0xC8/255, 1))
black = material("palette_wet_black_0C1013_harbor_water", (0x0C/255, 0x10/255, 0x13/255, 1))
slate = material("palette_harbor_slate_2A3A40_silt", (0x2A/255, 0x3A/255, 0x40/255, 1))
green = material("palette_absinthe_green_7D9B4E_dead_wetness", (0x7D/255, 0x9B/255, 0x4E/255, 1))
amber = material("palette_whale_oil_amber_C98A3C_market_pull", (0xC9/255, 0x8A/255, 0x3C/255, 1))

box("background_wet_black", 0, 0, 19.2, 10.8, black)
box("distant_harbor_ribcage_slate", 0, 0.6, 18.2, 5.5, slate)
box("mud_silt_foreground", 0, -2.55, 19.2, 3.6, slate)
box("low_harbor_water_band", 0, -1.2, 19.2, 1.05, black)
box("wake_up_silt_foreground", -4.7, -3.3, 4.6, 1.2, slate)
box("corvin_coat_and_hands_cluster", -2.4, -2.2, 1.0, 2.0, black)
box("corvin_hands_read", -3.05, -1.75, 0.35, 0.45, bone)
box("missing_boots_absence", 0.05, -3.7, 1.2, 0.22, bone)
box("salt_market_path_pull", 8.0, -1.8, 1.35, 2.8, amber)

for name, px, py in [
    ("bollard_of_tomas", 390, 702),
    ("silt", 500, 930),
    ("own_hands", 660, 760),
    ("coat", 735, 760),
    ("missing_boots", 965, 910),
    ("harbor_view", 1180, 620),
    ("salt_market_exit", 1765, 665),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    box("screen_anchor_" + name, x, z, 0.3, 0.3, amber if "exit" in name else green)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene["room_id"] = "mudflats"
bpy.context.scene["room_code"] = "R01"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["critical_hotspots"] = "Silt, OwnHands, HarborView, Coat, BollardOfTomas, MissingBoots, SaltMarketExit"
bpy.context.scene["custom_navigation"] = "SaltMarketExit is a scripted navigation hotspot, not a generic exit node."
bpy.context.scene["close_pair_note"] = "OwnHands and Coat are close on purpose as a tutorial cluster; separate by silhouette and color in final paint."
os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Mudflats blockout source creation failed with exit code $($process.ExitCode)."
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class CorpseMudflatsReviewRaster
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
            g.FillRectangle(slate, 0, 130, 1920, 520);
            g.FillRectangle(black, 0, 585, 1920, 160);
            g.FillRectangle(slate, 0, 745, 1920, 335);

            // First world signal: the town inside the leviathan ribcage.
            g.FillRectangle(bone, 240, 120, 46, 665);
            g.FillRectangle(bone, 470, 125, 48, 690);
            g.FillRectangle(bone, 712, 130, 48, 710);
            g.FillRectangle(bone, 944, 145, 48, 690);
            g.FillRectangle(black, 1120, 565, 230, 70);

            // Wake-up tutorial cluster.
            g.FillRectangle(black, 675, 560, 96, 330);
            g.FillRectangle(bone, 628, 742, 38, 52);
            g.FillRectangle(green, 708, 890, 14, 70);
            g.FillRectangle(slate, 260, 870, 520, 110);
            g.FillRectangle(bone, 905, 900, 122, 22);

            // Tomas and path pull.
            g.FillRectangle(bone, 350, 548, 82, 260);
            g.FillRectangle(black, 372, 612, 38, 120);
            g.FillRectangle(amber, 1660, 520, 165, 330);

            bitmap.Save(path, ImageFormat.Png);
        }
    }
}
"@

[CorpseMudflatsReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Mudflats blockout output was not created: $requiredPath"
    }
}

Write-Host "Mudflats blockout blend -> $sourceBlend"
Write-Host "Mudflats blockout render -> $exportPng"
Write-Host "Mudflats Godot background -> $godotPng"
