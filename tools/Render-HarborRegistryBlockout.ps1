$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$blender = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
if (-not (Test-Path -LiteralPath $blender)) {
    throw "Blender executable not found: $blender"
}

$sourceBlend = Join-Path $root "art\src\backgrounds\act_i\harbor_registry.blend"
$exportPng = Join-Path $root "art\export\backgrounds\act_i\harbor_registry_bg.png"
$godotPng = Join-Path $root "game\rooms\harbor_registry\background\harbor_registry_bg.png"
$tempScript = Join-Path ([System.IO.Path]::GetTempPath()) "corpse_harbor_registry_blockout.py"

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

public static class CorpseHarborRegistryPaletteSnap
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

public static class CorpseHarborRegistryReviewRaster
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
            g.FillRectangle(slate, 0, 120, 1920, 610);
            g.FillRectangle(black, 0, 0, 1920, 120);
            g.FillRectangle(bone, 0, 650, 1920, 430);

            // Left ledgers wall.
            for (int i = 0; i < 5; i++)
            {
                int x = 125 + (i * 62);
                g.FillRectangle(bone, x, 230, 34, 420);
                g.FillRectangle(black, x + 34, 230, 16, 420);
            }
            g.FillRectangle(slate, 80, 610, 340, 52);

            // Exit, roll book, desk, and shelf staging.
            g.FillRectangle(amber, 105, 660, 120, 165);
            g.FillRectangle(black, 90, 625, 40, 240);
            g.FillRectangle(amber, 565, 682, 155, 48);
            g.FillRectangle(bone, 780, 625, 380, 104);
            g.FillRectangle(slate, 940, 545, 260, 330);
            g.FillRectangle(black, 1210, 520, 70, 170);
            g.FillRectangle(bone, 1275, 516, 22, 30);

            // Wet lamp proof and Registrar duel staging.
            g.FillRectangle(amber, 870, 606, 42, 72);
            g.FillRectangle(green, 884, 544, 18, 92);
            g.FillRectangle(black, 958, 575, 54, 170);
            g.FillRectangle(slate, 705, 240, 620, 126);
            g.FillRectangle(green, 778, 720, 390, 14);

            // Kestrel ledger access and blocked-state review region.
            g.FillRectangle(green, 1175, 565, 96, 112);
            g.FillRectangle(green, 858, 620, 78, 48);
            g.FillRectangle(green, 938, 638, 86, 116);

            // Corvin side-scale proxy.
            g.FillRectangle(black, 675, 608, 44, 190);
            g.FillRectangle(green, 696, 760, 8, 48);

            bitmap.Save(path, ImageFormat.Png);
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

def box(name, x, z, sx, sz, mat, y=0.0):
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

def marker(name, px, py, sx, sz, mat):
    x = (px - 960) / 100.0
    z = (540 - py) / 100.0
    obj = box("hotspot_" + name, x, z, sx, sz, mat, y=-0.04)
    obj["screen_anchor"] = f"{px},{py}"
    return obj

clear_scene()

mat_bone = material("palette_bone_paper_white_E4DCC8", PALETTE["bone"])
mat_black = material("palette_wet_black_0C1013", PALETTE["wet_black"])
mat_slate = material("palette_harbor_slate_2A3A40", PALETTE["slate"])
mat_green = material("palette_absinthe_green_7D9B4E_wrong_light", PALETTE["green"])
mat_amber = material("palette_whale_oil_amber_C98A3C_living_light", PALETTE["amber"])

# Camera-space coordinate guide: 1 Blender unit is 100 screen pixels at 1920x1080.
box("background_wet_black", 0, 0, 19.2, 10.8, mat_black, y=0.08)
box("back_wall_harbor_slate", 0, 0.05, 17.8, 7.2, mat_slate, y=0.04)
box("floor_walk_band_y650_800", 0, -2.1, 17.2, 2.7, mat_bone, y=0.0)
box("ceiling_shadow", 0, 3.95, 19.2, 1.0, mat_black, y=-0.01)

# Architectural framing: tall ledgers left, Registrar desk center-right, ledger shelf behind it.
for i, x in enumerate([-6.4, -5.85, -5.3, -4.75, -4.2]):
    shelf = box(f"ledger_spine_wall_{i+1:02d}", x, -0.35, 0.28, 4.6, mat_bone, y=-0.05)
    shelf["art_role"] = "Ledgers wall; scene texture, not a duel interface."
box("roll_book_table_640_700", -3.2, -1.6, 1.5, 0.55, mat_amber, y=-0.07)
box("registrar_desk_barrier_980_690", 0.2, -1.55, 3.4, 0.9, mat_bone, y=-0.08)
box("registrar_back_shelf", 2.4, -0.05, 2.5, 3.8, mat_slate, y=-0.03)
box("kestrel_ledger_black_binding_1220_610", 2.6, -0.7, 0.55, 1.35, mat_black, y=-0.1)
box("kestrel_ledger_torn_corner", 2.85, -0.05, 0.18, 0.22, mat_bone, y=-0.11)

# Desk lamp and smoke/wet proof. Green is wrong-light and flags the wet verb target.
cylinder("desk_lamp_wet_target_890_650", -0.7, -1.1, 0.18, 0.55, mat_amber, y=-0.12, vertices=12)
box("lamp_smoke_after_wet_proof", -0.7, -0.45, 0.28, 1.2, mat_green, y=-0.13)

# Registrar silhouette and formal duel framing. This frames the duel without becoming UI.
box("registrar_silhouette_duel_anchor_980_690", 0.2, -0.7, 0.48, 1.5, mat_black, y=-0.14)
box("duel_stage_empty_space_for_litany_ui", 0.0, 1.7, 6.6, 1.1, mat_slate, y=-0.02)
box("formal_registry_counter_line_not_ui", 0.2, -2.03, 3.8, 0.12, mat_green, y=-0.15)

# Exit and navigation band.
box("left_exit_to_salt_market_180_740", -7.8, -2.0, 1.0, 1.25, mat_amber, y=-0.08)
box("door_shadow", -8.45, -1.1, 0.5, 2.2, mat_black, y=-0.09)

# Side-on Corvin scale proxy for hand reach and desk blocking review.
box("corvin_side_scale_proxy_not_final_art", -1.15, -1.42, 0.42, 1.9, mat_black, y=-0.16)
box("corvin_drip_proxy", -1.0, -2.42, 0.08, 0.5, mat_green, y=-0.17)

for name, px, py, sx, sz, mat in [
    ("to_salt_market_180_740", 180, 740, 0.16, 0.16, mat_amber),
    ("ledgers_420_660", 420, 660, 0.16, 0.16, mat_amber),
    ("roll_book_640_700", 640, 700, 0.16, 0.16, mat_amber),
    ("desk_lamp_890_650", 890, 650, 0.7, 0.45, mat_green),
    ("registrar_duel_980_690", 980, 690, 0.8, 1.2, mat_green),
    ("kestrel_ledger_1220_610", 1220, 610, 0.8, 1.0, mat_green),
]:
    marker(name, px, py, sx, sz, mat)

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

bpy.context.scene["room_id"] = "harbor_registry"
bpy.context.scene["room_code"] = "R05"
bpy.context.scene["walk_band"] = "y 650-800"
bpy.context.scene["duel_format_lock"] = "Frame Registrar as a formal duel position, but preserve the accepted Litany UI and do not add a second confession-spend interface."
bpy.context.scene["critical_hotspots"] = "Registrar, KestrelLedger, DeskLamp, Ledgers, RollBook, Salt Market exit"

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
    throw "Blender Harbor Registry blockout render failed with exit code $($process.ExitCode)."
}

foreach ($requiredPath in @($sourceBlend, $exportPng, $godotPng)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Expected Harbor Registry blockout output was not created: $requiredPath"
    }
}

[CorpseHarborRegistryPaletteSnap]::Snap($exportPng)
[CorpseHarborRegistryReviewRaster]::Draw($exportPng)
Copy-Item -LiteralPath $exportPng -Destination $godotPng -Force

Write-Host "Harbor Registry blockout blend -> $sourceBlend"
Write-Host "Harbor Registry blockout render -> $exportPng"
Write-Host "Harbor Registry Godot background -> $godotPng"
