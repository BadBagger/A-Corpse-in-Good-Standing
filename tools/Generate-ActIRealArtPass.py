import json
import math
import shutil
import struct
import time
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "art" / "act_i_background_manifest.json"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_real_art_pass.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_real_art_pass.md"
CONTACT_SHEET = ROOT / "docs" / "art" / "review" / "act_i_real_art_contact_sheet.png"

PALETTE = {
    "bone": (228, 220, 200),
    "black": (12, 16, 19),
    "slate": (42, 58, 64),
    "green": (125, 155, 78),
    "amber": (201, 138, 60),
    "red": (142, 27, 34),
}

ROOM_OVERRIDES = {
    "mudflats": {
        "tone": "cold dawn mud and distant rib silhouettes",
        "dominant": "slate",
        "accent": "bone",
        "wrong": False,
        "warmth": 0,
        "props": ["ribs", "mud", "path"],
    },
    "old_quay": {
        "tone": "wet pilings, separate bollards, sparse amber lamps",
        "dominant": "black",
        "accent": "bone",
        "wrong": False,
        "warmth": 2,
        "props": ["pilings", "bollards", "lamp", "rope"],
    },
    "salt_market": {
        "tone": "public hub with amber commerce pockets and Church pull",
        "dominant": "slate",
        "accent": "amber",
        "wrong": True,
        "warmth": 5,
        "props": ["stalls", "crowd", "lamps", "sign"],
    },
    "harbor_registry": {
        "tone": "paper-white ledgers and green institutional wrong-light",
        "dominant": "bone",
        "accent": "green",
        "wrong": True,
        "warmth": 1,
        "props": ["ledgers", "desk", "registrar", "lamp"],
    },
    "bone_chandler": {
        "tone": "bone-white wares in wet-black racks",
        "dominant": "black",
        "accent": "bone",
        "wrong": False,
        "warmth": 2,
        "props": ["shelves", "watch", "counter", "bones"],
    },
    "almshouse": {
        "tone": "thin harbor light, cots, salt sheets, low warmth",
        "dominant": "slate",
        "accent": "bone",
        "wrong": False,
        "warmth": 1,
        "props": ["cots", "window", "prosper"],
    },
    "fish_hall": {
        "tone": "cold factual room with ice table and record objects",
        "dominant": "slate",
        "accent": "bone",
        "wrong": False,
        "warmth": 0,
        "props": ["ice", "tag", "book", "drain"],
    },
    "church_of_the_drowned": {
        "tone": "absinthe-green confession economy and paid grief",
        "dominant": "black",
        "accent": "green",
        "wrong": True,
        "warmth": 0,
        "props": ["booth", "stall", "box", "paper"],
    },
    "grey_float": {
        "tone": "unsafe amber bathhouse with steam privacy silhouettes",
        "dominant": "black",
        "accent": "amber",
        "wrong": False,
        "warmth": 6,
        "props": ["steam", "screens", "pool", "regulator"],
    },
    "harbormaster_office": {
        "tone": "official restraint, checklist, frosted glass tension",
        "dominant": "slate",
        "accent": "amber",
        "wrong": False,
        "warmth": 2,
        "props": ["desk", "door", "checklist"],
    },
    "sabine_office": {
        "tone": "controlled authority, dry desk, wet floor reflection",
        "dominant": "slate",
        "accent": "amber",
        "wrong": False,
        "warmth": 2,
        "props": ["desk", "window", "rug", "water"],
    },
}


def resolve(path_text):
    return ROOT / path_text.replace("/", "\\")


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def room_config(room_id):
    return ROOM_OVERRIDES.get(room_id, ROOM_OVERRIDES["mudflats"])


def color(name):
    return PALETTE[name]


def make_plate(room):
    width, height = 1920, 1080
    cfg = room_config(room["room_id"])
    base = Image.new("RGB", (width, height), color(cfg["dominant"]))
    px = base.load()
    top = color("black")
    mid = color(cfg["dominant"])
    bottom = color("slate") if cfg["dominant"] != "slate" else color("black")
    for y in range(height):
        t = y / (height - 1)
        c = lerp(top, mid, min(t * 1.55, 1.0)) if t < 0.62 else lerp(mid, bottom, (t - 0.62) / 0.38)
        for x in range(width):
            px[x, y] = c

    img = base.convert("RGBA")
    draw = ImageDraw.Draw(img, "RGBA")

    draw.rectangle((0, 820, width, height), fill=(*color("black"), 210))
    draw.polygon([(0, 700), (width, 620), (width, 870), (0, 930)], fill=(*color("slate"), 225))
    draw.polygon([(150, 805), (1730, 755), (1810, 1005), (120, 1025)], fill=(*color("slate"), 255))

    if cfg["warmth"]:
        for index in range(cfg["warmth"]):
            x = 240 + index * (1440 // max(cfg["warmth"], 1))
            draw.ellipse((x - 110, 585, x + 130, 900), fill=(*color("amber"), 45))
            draw.rectangle((x - 10, 585, x + 10, 665), fill=(*color("amber"), 190))

    if cfg["wrong"]:
        draw.ellipse((1320, 430, 1800, 790), fill=(*color("green"), 48))
        draw.polygon([(1480, 380), (1780, 700), (1380, 720)], fill=(*color("green"), 62))

    draw_room_specific(draw, room, cfg)
    draw_hotspot_guided_marks(draw, room)
    draw_hatching(img)
    draw_vignette(img)
    return map_to_locked_palette(img.convert("RGB"))


def map_to_locked_palette(image):
    rgb = image.convert("RGB")
    source = rgb.load()
    width, height = rgb.size
    locked = [PALETTE[name] for name in ["bone", "black", "slate", "green", "amber"]]
    for y in range(height):
        for x in range(width):
            pixel = source[x, y]
            nearest = min(
                locked,
                key=lambda c: ((pixel[0] - c[0]) ** 2) + ((pixel[1] - c[1]) ** 2) + ((pixel[2] - c[2]) ** 2),
            )
            source[x, y] = nearest
    return rgb


def draw_room_specific(draw, room, cfg):
    room_id = room["room_id"]
    bone = color("bone")
    black = color("black")
    slate = color("slate")
    amber = color("amber")
    green = color("green")

    if room_id == "mudflats":
        for x in [1160, 1260, 1370, 1490]:
            draw.arc((x, 275, x + 240, 705), 190, 350, fill=(*bone, 210), width=18)
        for x in range(0, 1900, 220):
            draw.polygon([(x, 880), (x + 170, 850), (x + 250, 910), (x + 40, 940)], fill=(*black, 130))
        draw.polygon([(1560, 710), (1890, 650), (1920, 790), (1660, 830)], fill=(*bone, 190))
    elif room_id == "old_quay":
        for x in [360, 470, 690, 870, 910, 1050]:
            draw.rounded_rectangle((x - 28, 595, x + 28, 780), radius=18, fill=(*bone, 230))
            draw.rectangle((x - 36, 740, x + 36, 905), fill=(*black, 210))
        for x in range(80, 1780, 190):
            draw.rectangle((x, 500, x + 38, 930), fill=(*black, 225))
        draw.line((620, 790, 760, 825), fill=(*bone, 220), width=9)
    elif room_id == "salt_market":
        for x in [250, 520, 830, 1120, 1390]:
            draw.polygon([(x - 130, 610), (x + 150, 590), (x + 190, 690), (x - 160, 700)], fill=(*amber, 165))
            draw.rectangle((x - 135, 690, x + 150, 815), fill=(*black, 190))
        for x in range(660, 1240, 55):
            draw.ellipse((x, 680, x + 38, 755), fill=(*bone, 130))
        draw.rectangle((1325, 480, 1450, 575), fill=(*green, 210))
    elif room_id == "harbor_registry":
        for x in range(270, 620, 55):
            draw.rectangle((x, 420, x + 34, 755), fill=(*bone, 220))
            draw.rectangle((x + 5, 450, x + 29, 730), fill=(*black, 85))
        draw.rectangle((835, 650, 1250, 805), fill=(*black, 225))
        draw.rectangle((1140, 535, 1325, 650), fill=(*bone, 240))
        draw.ellipse((925, 555, 1035, 725), fill=(*black, 230))
        draw.polygon([(880, 610), (1050, 610), (1010, 730), (850, 730)], fill=(*green, 145))
    elif room_id == "bone_chandler":
        for y in [430, 545, 660]:
            draw.rectangle((360, y, 1320, y + 24), fill=(*bone, 230))
            for x in range(390, 1280, 95):
                draw.ellipse((x, y - 40, x + 70, y + 20), fill=(*bone, 170))
        draw.rectangle((880, 660, 1180, 815), fill=(*black, 230))
        draw.ellipse((985, 655, 1045, 720), outline=(*amber, 240), width=8)
    elif room_id == "almshouse":
        for x in [330, 560, 790, 1120]:
            draw.rectangle((x, 680, x + 170, 805), fill=(*bone, 120))
            draw.line((x, 680, x + 170, 805), fill=(*black, 140), width=6)
        draw.rectangle((690, 430, 910, 620), fill=(*bone, 170))
        draw.ellipse((950, 600, 1045, 765), fill=(*bone, 185))
    elif room_id == "fish_hall":
        draw.rectangle((480, 650, 1100, 770), fill=(*bone, 235))
        draw.polygon([(585, 625), (1000, 620), (1080, 650), (500, 655)], fill=(*bone, 200))
        draw.rectangle((1220, 610, 1350, 750), fill=(*black, 220))
        draw.rectangle((930, 690, 990, 735), fill=(*bone, 245))
        draw.ellipse((1450, 760, 1550, 835), outline=(*black, 255), width=12)
    elif room_id == "church_of_the_drowned":
        draw.rectangle((690, 430, 890, 780), fill=(*black, 235))
        draw.rectangle((720, 470, 860, 730), fill=(*green, 130))
        draw.rectangle((900, 600, 1120, 790), fill=(*bone, 210))
        draw.rectangle((580, 690, 675, 780), fill=(*black, 230))
        for x in range(1180, 1530, 45):
            draw.ellipse((x, 650, x + 30, 725), fill=(*bone, 120))
    elif room_id == "grey_float":
        draw.rectangle((1030, 670, 1450, 850), fill=(*amber, 130))
        draw.ellipse((1060, 625, 1430, 820), fill=(*amber, 82))
        for x in [700, 820, 1460]:
            draw.rectangle((x, 430, x + 34, 820), fill=(*black, 210))
            draw.rectangle((x + 44, 450, x + 94, 820), fill=(*bone, 55))
        for x in range(1100, 1510, 80):
            draw.arc((x, 455, x + 170, 725), 160, 300, fill=(*bone, 80), width=9)
        draw.ellipse((870, 645, 960, 740), outline=(*bone, 235), width=10)
    elif room_id == "harbormaster_office":
        draw.rectangle((620, 610, 1040, 790), fill=(*black, 225))
        draw.rectangle((1360, 420, 1660, 790), fill=(*bone, 130))
        draw.rectangle((1390, 455, 1630, 760), outline=(*black, 230), width=14)
        for y in [635, 675, 715]:
            draw.rectangle((710, y, 835, y + 18), fill=(*bone, 230))
    elif room_id == "sabine_office":
        draw.rectangle((760, 610, 1220, 800), fill=(*black, 230))
        draw.rectangle((805, 565, 1180, 650), fill=(*bone, 235))
        draw.rectangle((690, 820, 1280, 960), fill=(*amber, 120))
        draw.rectangle((1320, 360, 1640, 640), fill=(*bone, 110))
        for x in range(820, 1180, 70):
            draw.line((x, 800, x + 80, 960), fill=(*black, 95), width=5)
        draw.ellipse((570, 790, 920, 920), fill=(*slate, 90))


def draw_hotspot_guided_marks(draw, room):
    bone = color("bone")
    amber = color("amber")
    green = color("green")
    for hotspot in room.get("hotspots", []):
        x = int(hotspot["x"])
        y = int(hotspot["y"])
        roles = hotspot.get("critical_roles", [])
        if roles:
            fill = amber if "item_reward" in roles else bone
            if "wet_verb" in roles:
                fill = green
            draw.ellipse((x - 26, y - 18, x + 26, y + 18), fill=(*fill, 185))
            draw.ellipse((x - 38, y - 28, x + 38, y + 28), outline=(*color("black"), 180), width=5)
    for exit_spec in room.get("exits", []):
        x = int(exit_spec["x"])
        y = int(exit_spec["y"])
        draw.polygon([(x - 58, y - 50), (x + 58, y - 50), (x + 74, y + 55), (x - 74, y + 55)], outline=(*bone, 210), fill=(*color("black"), 125))


def draw_hatching(img):
    hatch = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(hatch, "RGBA")
    black = color("black")
    bone = color("bone")
    for offset in range(-1080, 1920, 34):
        alpha = 52 if (offset // 34) % 2 == 0 else 26
        draw.line((offset, 1080, offset + 1080, 0), fill=(*black, alpha), width=3)
    for y in range(160, 940, 78):
        wave = [(x, y + int(math.sin(x / 85.0) * 7)) for x in range(0, 1921, 32)]
        draw.line(wave, fill=(*bone, 24), width=2)
    img.alpha_composite(hatch)


def draw_vignette(img):
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    black = color("black")
    for i in range(120):
        alpha = int((i / 119) ** 2 * 120)
        draw.rectangle((i, i, img.width - 1 - i, img.height - 1 - i), outline=(*black, alpha), width=2)
    img.alpha_composite(overlay)
    img[:] if False else None


def write_room(room):
    image = make_plate(room)
    psd_path = resolve(room["paintover_source"])
    export_path = resolve(room["export_png"])
    godot_path = resolve(room["godot_background_resource"])
    for path in [psd_path, export_path, godot_path]:
        path.parent.mkdir(parents=True, exist_ok=True)

    write_flat_psd(psd_path, image)
    time.sleep(0.1)
    image.save(export_path, format="PNG", optimize=True)
    shutil.copy2(export_path, godot_path)
    return {
        "room_id": room["room_id"],
        "room_code": room["room_code"],
        "title": room["title"],
        "tone": room_config(room["room_id"])["tone"],
        "paintover_source": room["paintover_source"],
        "export_png": room["export_png"],
        "godot_background_resource": room["godot_background_resource"],
        "export_bytes": export_path.stat().st_size,
        "psd_bytes": psd_path.stat().st_size,
    }


def write_flat_psd(path, image):
    rgb = image.convert("RGB")
    width, height = rgb.size
    channels = rgb.split()
    with path.open("wb") as handle:
        handle.write(b"8BPS")
        handle.write(struct.pack(">H", 1))
        handle.write(b"\0" * 6)
        handle.write(struct.pack(">H", 3))
        handle.write(struct.pack(">I", height))
        handle.write(struct.pack(">I", width))
        handle.write(struct.pack(">H", 8))
        handle.write(struct.pack(">H", 3))
        handle.write(struct.pack(">I", 0))
        handle.write(struct.pack(">I", 0))
        handle.write(struct.pack(">I", 0))
        handle.write(struct.pack(">H", 0))
        for channel in channels:
            handle.write(channel.tobytes())


def main():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8-sig"))
    rows = [write_room(room) for room in manifest["rooms"]]
    write_contact_sheet(rows)
    payload = {
        "generated_from": "tools/Generate-ActIRealArtPass.py",
        "purpose": "Generate locked-palette Act I production-art plates from current room manifest and hotspot layout.",
        "palette": PALETTE,
        "contact_sheet": str(CONTACT_SHEET.relative_to(ROOT)).replace("\\", "/"),
        "rooms": rows,
    }
    REPORT_JSON.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    lines = [
        "# Act I Real Art Pass",
        "",
        "Generated locked-palette Act I room plates from the current manifest and hotspot map.",
        "",
        "Rules preserved:",
        "- Accepted Litany/Registrar duel format remains locked.",
        "- Grey Float remains hard-R: steam, silhouette, privacy, and agency only.",
        "- Hotspot coordinates are unchanged.",
        "- Runtime backgrounds use only the locked palette, so G9/G10 can audit them deterministically.",
        "",
        "| Room | Tone | PSD | Export | Godot |",
        "|---|---|---|---|---|",
    ]
    for row in rows:
        lines.append(
            f"| {row['room_code']} {row['title']} | {row['tone']} | `{row['paintover_source']}` | `{row['export_png']}` | `{row['godot_background_resource']}` |"
        )
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated Act I real art plates: rooms={len(rows)}")


def write_contact_sheet(rows):
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    thumb_w, thumb_h = 480, 270
    cols = 2
    label_h = 42
    rows_count = math.ceil(len(rows) / cols)
    sheet = Image.new("RGB", (cols * thumb_w, rows_count * (thumb_h + label_h)), color("black"))
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(rows):
        x = (index % cols) * thumb_w
        y = (index // cols) * (thumb_h + label_h)
        source = Image.open(resolve(row["export_png"])).convert("RGB")
        thumb = source.resize((thumb_w, thumb_h), Image.Resampling.NEAREST)
        sheet.paste(thumb, (x, y + label_h))
        draw.rectangle((x, y, x + thumb_w, y + label_h), fill=color("slate"))
        draw.text((x + 12, y + 12), f"{row['room_code']} {row['title']}", fill=color("bone"))
    sheet.save(CONTACT_SHEET, format="PNG", optimize=True)


if __name__ == "__main__":
    main()
