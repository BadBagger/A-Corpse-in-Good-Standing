$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")
$blender = Get-CorpseBlenderPath

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\old_quay.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\old_quay_blockout_bg.png"
$godotPng = Join-Path $root "game\rooms\old_quay\background\old_quay_blockout_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_old_quay_blockout.py"

foreach ($dir in @(
    (Split-Path -Parent $sourceBlend),
    (Split-Path -Parent $exportPng),
    (Split-Path -Parent $godotPng)
)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

Add-Type -ReferencedAssemblies "System.Drawing" -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;

public static class CorpsePaletteSnap
{
    private static readonly Color[] Palette = new[] {
        Color.FromArgb(255, 0xE4, 0xDC, 0xC8),
        Color.FromArgb(255, 0x0C, 0x10, 0x13),
        Color.FromArgb(255, 0x2A, 0x3A, 0x40),
        Color.FromArgb(255, 0x7D, 0x9B, 0x4E),
        Color.FromArgb(255, 0xC9, 0x8A, 0x3C),
        Color.FromArgb(255, 0x8E, 0x1B, 0x22)
    };

    public static void Snap(string path)
    {
        string tempPath = path + ".palette_tmp.png";
        byte[] sourceBytes = File.ReadAllBytes(path);
        using (var stream = new MemoryStream(sourceBytes))
        using (var source = new Bitmap(stream))
        {
            var rect = new Rectangle(0, 0, source.Width, source.Height);
            using (var bitmap = source.Clone(rect, PixelFormat.Format32bppArgb))
            {
                var data = bitmap.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                try
                {
                    int stride = Math.Abs(data.Stride);
                    byte[] bytes = new byte[stride * bitmap.Height];
                    Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);

                    for (int y = 0; y < bitmap.Height; y++)
                    {
                        int row = y * stride;
                        for (int x = 0; x < bitmap.Width; x++)
                        {
                            int offset = row + (x * 4);
                            int b = bytes[offset];
                            int g = bytes[offset + 1];
                            int r = bytes[offset + 2];
                            int a = bytes[offset + 3];
                            if (a == 0) { continue; }

                            Color nearest = Palette[0];
                            int best = int.MaxValue;
                            foreach (var color in Palette)
                            {
                                int dr = r - color.R;
                                int dg = g - color.G;
                                int db = b - color.B;
                                int distance = (dr * dr) + (dg * dg) + (db * db);
                                if (distance < best)
                                {
                                    best = distance;
                                    nearest = color;
                                }
                            }

                            bytes[offset] = nearest.B;
                            bytes[offset + 1] = nearest.G;
                            bytes[offset + 2] = nearest.R;
                            bytes[offset + 3] = 255;
                        }
                    }

                    Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
                }
                finally
                {
                    bitmap.UnlockBits(data);
                }

                bitmap.Save(tempPath, ImageFormat.Png);
            }
        }

        for (int attempt = 1; attempt <= 20; attempt++)
        {
            try
            {
                File.Copy(tempPath, path, true);
                File.Delete(tempPath);
                return;
            }
            catch (IOException)
            {
                if (attempt == 20) { throw; }
                GC.Collect();
                GC.WaitForPendingFinalizers();
                Thread.Sleep(250);
            }
        }
    }
}
"@

$python = @'
import bpy
import math
import os

SOURCE_BLEND = r"__SOURCE_BLEND__"
EXPORT_PNG = r"__EXPORT_PNG__"
GODOT_PNG = r"__GODOT_PNG__"

PALETTE = {
    "bone": (0xE4 / 255.0, 0xDC / 255.0, 0xC8 / 255.0, 1.0),
    "wet_black": (0x0C / 255.0, 0x10 / 255.0, 0x13 / 255.0, 1.0),
    "slate": (0x2A / 255.0, 0x3A / 255.0, 0x40 / 255.0, 1.0),
    "green": (0x7D / 255.0, 0x9B / 255.0, 0x4E / 255.0, 1.0),
    "amber": (0xC9 / 255.0, 0x8A / 255.0, 0x3C / 255.0, 1.0),
}

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 1.0
        bsdf.inputs["Metallic"].default_value = 0.0
    mat.diffuse_color = color
    return mat

def plane(name, x, z, sx, sz, mat, y=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, y, z))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (sx, 0.08, sz)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj

def cylinder(name, x, z, radius, depth, mat, y=0.0, rot=(0, 0, 0), vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=(x, y, z), rotation=rot)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj

def marker(name, x, z, sx, sz, mat):
    obj = plane("hotspot_" + name, x, z, sx, sz, mat, y=-0.02)
    obj["hotspot_marker"] = name
    return obj

clear_scene()

mat_bone = material("palette_bone_paper_white_E4DCC8", PALETTE["bone"])
mat_black = material("palette_wet_black_0C1013", PALETTE["wet_black"])
mat_slate = material("palette_harbor_slate_2A3A40", PALETTE["slate"])
mat_green = material("palette_absinthe_green_7D9B4E_hotspot_proof", PALETTE["green"])
mat_amber = material("palette_whale_oil_amber_C98A3C_hotspot_proof", PALETTE["amber"])

# Camera-space coordinate guide: 1 Blender unit is 100 screen pixels at 1920x1080.
plane("background_wet_black", 0, 0, 19.2, 10.8, mat_black, y=0.08)
plane("harbor_slate_water_band", 0, -3.15, 19.2, 2.9, mat_slate, y=0.04)
plane("old_quay_walk_band_y650_800", 0, -2.15, 17.0, 1.5, mat_bone, y=0.0)
plane("front_mud_edge", 0, -4.05, 19.2, 1.1, mat_slate, y=-0.01)

# Leviathan rib silhouettes and quay supports.
for i, x in enumerate([-8.2, -6.9, -5.7, -4.4, -3.2, 5.9, 7.0, 8.0]):
    rib = cylinder(f"leviathan_rib_{i+1:02d}", x, 0.15, 0.055, 4.2, mat_bone, y=-0.04, rot=(math.radians(18 if x < 0 else -18), 0, 0), vertices=12)
    rib.scale.x = 0.7

for x in [-7.1, -5.2, -2.8, 0.2, 3.4, 6.8]:
    cylinder("pier_piling", x, -2.9, 0.12, 2.0, mat_slate, y=-0.03, rot=(math.radians(90), 0, 0), vertices=10)

# Exits and critical interaction silhouettes, converted from manifest pixel positions.
marker("exit_mudflats_180_760", -7.8, -2.2, 1.1, 0.9, mat_amber)
marker("exit_salt_market_1700_700", 7.4, -1.6, 1.1, 0.9, mat_amber)

tom = cylinder("Bollard_Tomas_confession_source_470_720", -4.9, -1.8, 0.22, 1.0, mat_bone, y=-0.08, vertices=16)
tom["hotspot_id"] = "Tomas"
marker("tomas_talk_zone", -4.9, -1.78, 0.8, 1.2, mat_green)

for name, x, z in [
    ("BollardPetra_silent", -5.75, -1.95),
    ("BollardLedger_silent", -5.35, -2.05),
    ("BollardBride_silent", -5.0, -2.05),
]:
    obj = cylinder(name, x, z, 0.13, 0.75, mat_slate, y=-0.08, vertices=12)
    obj["close_pair_review"] = "BollardLedger / SilentBollards"

cleat = cylinder("Rope_cleat_wet_verb_item_reward_720_800", -2.4, -2.6, 0.13, 0.7, mat_amber, y=-0.1, rot=(0, math.radians(90), 0), vertices=12)
cleat["hotspot_id"] = "RopeCleat"
marker("rope_cleat_wet_zone", -2.4, -2.6, 0.7, 0.45, mat_green)

flask = cylinder("Empty_flask_item_reward_1180_760", 2.2, -2.2, 0.12, 0.5, mat_amber, y=-0.09, rot=(0, math.radians(72), 0), vertices=12)
flask["hotspot_id"] = "EmptyFlask"
marker("empty_flask_pickup_zone", 2.2, -2.2, 0.55, 0.45, mat_green)

# Side-on Corvin scale proxy for walk-band and hotspot reach review.
plane("corvin_side_scale_proxy_not_final_art", -0.35, -1.35, 0.42, 1.9, mat_black, y=-0.12)
plane("corvin_wrong_shoulder_proxy", -0.52, -0.68, 0.35, 0.18, mat_black, y=-0.13)
plane("corvin_drip_proxy", -0.3, -2.45, 0.08, 0.55, mat_green, y=-0.14)

# Small tick marks on the walk band prove screen-coordinate targets without adding final UI.
for name, px, py in [
    ("Tomas", 470, 720),
    ("RopeCleat", 720, 800),
    ("EmptyFlask", 1180, 760),
    ("MudflatsExit", 180, 760),
    ("SaltMarketExit", 1700, 700),
]:
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    marker(f"pixel_anchor_{name}_{px}_{py}", x, z, 0.16, 0.16, mat_amber)

bpy.ops.object.camera_add(location=(0, -12, 0), rotation=(math.radians(90), 0, 0))
camera = bpy.context.object
bpy.context.scene.camera = camera
camera.name = "camera_1920x1080_side_orthographic"
camera.data.type = "ORTHO"
camera.data.ortho_scale = 10.8

bpy.context.scene.render.engine = "BLENDER_WORKBENCH"
bpy.context.scene.display.shading.light = "FLAT"
bpy.context.scene.display.shading.color_type = "MATERIAL"
bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene.render.film_transparent = False
bpy.context.scene.view_settings.view_transform = "Standard"
bpy.context.scene.view_settings.look = "None"
bpy.context.scene.view_settings.exposure = 0
bpy.context.scene.view_settings.gamma = 1

bpy.context.scene["room_id"] = "old_quay"
bpy.context.scene["room_code"] = "R02"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["duel_format_lock"] = "No duel UI or confession-spend behavior is introduced by this background blockout."
bpy.context.scene["critical_hotspots"] = "Tomas, EmptyFlask, RopeCleat, Mudflats exit, Salt Market exit"

os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
os.makedirs(os.path.dirname(EXPORT_PNG), exist_ok=True)
os.makedirs(os.path.dirname(GODOT_PNG), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)

bpy.context.scene.render.filepath = EXPORT_PNG
bpy.ops.render.render(write_still=True)

if os.path.exists(EXPORT_PNG):
    import shutil
    shutil.copyfile(EXPORT_PNG, GODOT_PNG)
'@

$python = $python.Replace("__SOURCE_BLEND__", ($sourceBlend -replace "\\", "\\"))
$python = $python.Replace("__EXPORT_PNG__", ($exportPng -replace "\\", "\\"))
$python = $python.Replace("__GODOT_PNG__", ($godotPng -replace "\\", "\\"))
Set-Content -LiteralPath $tempScript -Value $python -Encoding UTF8

$process = Start-Process -FilePath $blender -ArgumentList @("--background", "--python", $tempScript) -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    throw "Blender Old Quay blockout render failed with exit code $($process.ExitCode)."
}

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Old Quay blockout output was not created: $requiredPath"
    }
}

[CorpsePaletteSnap]::Snap($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

Write-Host "Old Quay blockout blend -> $sourceBlend"
Write-Host "Old Quay blockout render -> $exportPng"
Write-Host "Old Quay Godot background -> $godotPng"
