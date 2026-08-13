from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "art" / "review" / "act_i_runtime_frames"
CONTACT_PATH = ROOT / "docs" / "art" / "review" / "act_i_runtime_frame_contact_sheet.png"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_runtime_review_frames.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_runtime_review_frames.md"

PALETTE = {
    "bone": (228, 220, 200),
    "black": (12, 16, 19),
    "slate": (42, 58, 64),
    "amber": (201, 138, 60),
}

ROOMS = [
    {
        "code": "R02",
        "title": "The Old Quay",
        "room_id": "old_quay",
        "base": "docs/art/review/old_quay_openai_prop_composite.png",
        "player": (820, 760, "idle_side_right"),
        "standees": [("tomas_bollard", 400, 735, 1.0)],
        "overlays": [("old_quay_water_glint", "game/rooms/old_quay/atmosphere/old_quay_water_glint.png", 0, 650, 1920, 310, 8)],
    },
    {
        "code": "R03",
        "title": "Salt Market",
        "room_id": "salt_market",
        "base": "docs/art/review/salt_market_openai_prop_composite.png",
        "player": (620, 790, "idle_side_right"),
        "standees": [],
        "overlays": [
            ("salt_market_crowd", "game/rooms/salt_market/setpieces/salt_market_crowd_idle_murmur.png", 1070, 455, 520, 330, 8),
            ("salt_market_lamp_flicker", "game/rooms/salt_market/atmosphere/salt_market_lamp_flicker.png", 1210, 210, 540, 500, 8),
        ],
    },
    {
        "code": "R05",
        "title": "Harbor Registry",
        "room_id": "harbor_registry",
        "base": "docs/art/review/harbor_registry_openai_prop_composite.png",
        "player": (760, 780, "idle_side_right"),
        "standees": [("registrar", 1230, 705, 0.78)],
        "overlays": [("harbor_registry_lamp_smoke", "game/rooms/harbor_registry/atmosphere/harbor_registry_lamp_smoke.png", 700, 300, 520, 430, 10)],
    },
    {
        "code": "R06",
        "title": "The Bone Chandler",
        "room_id": "bone_chandler",
        "base": "docs/art/review/bone_chandler_openai_prop_composite.png",
        "player": (720, 780, "idle_side_right"),
        "standees": [("bone_chandler", 1200, 760, 0.78)],
        "overlays": [],
    },
    {
        "code": "R07",
        "title": "The Almshouse",
        "room_id": "almshouse",
        "base": "docs/art/review/almshouse_openai_prop_composite.png",
        "player": (820, 790, "idle_side_right"),
        "standees": [("prosper", 1190, 775, 0.82)],
        "overlays": [],
    },
    {
        "code": "R09",
        "title": "Church of the Drowned",
        "room_id": "church_of_the_drowned",
        "base": "docs/art/review/church_of_the_drowned_openai_prop_composite.png",
        "player": (830, 790, "idle_side_right"),
        "standees": [("teodor", 1230, 740, 0.78)],
        "overlays": [],
    },
    {
        "code": "R10",
        "title": "The Grey Float",
        "room_id": "grey_float",
        "base": "docs/art/review/grey_float_openai_prop_composite.png",
        "player": (800, 780, "idle_side_right"),
        "standees": [("juno", 1250, 745, 0.75)],
        "overlays": [("grey_float_steam_drift", "game/rooms/grey_float/atmosphere/grey_float_steam_drift.png", 120, 330, 1640, 470, 10)],
    },
    {
        "code": "R12",
        "title": "Sabine's Office",
        "room_id": "sabine_office",
        "base": "docs/art/review/sabine_office_openai_prop_composite.png",
        "player": (790, 780, "idle_side_right"),
        "standees": [("sabine", 1260, 735, 0.76)],
        "overlays": [("sabine_office_window_rain", "game/rooms/sabine_office/atmosphere/sabine_office_window_rain.png", 900, 90, 650, 470, 8)],
    },
]


def first_frame(path: Path, frame_w: int, frame_h: int) -> Image.Image:
    sheet = Image.open(path).convert("RGBA")
    return sheet.crop((0, 0, frame_w, frame_h))


def paste_sprite(image: Image.Image, sprite: Image.Image, foot_x: int, foot_y: int, scale: float = 1.0) -> None:
    if scale != 1.0:
        sprite = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.LANCZOS)
    draw_contact_shadow(image, sprite.width, sprite.height, foot_x, foot_y)
    draw_wet_floor_reflection(image, sprite, foot_x, foot_y)
    image.alpha_composite(sprite, (round(foot_x - sprite.width / 2), round(foot_y - sprite.height)))


def paste_corvin(image: Image.Image, foot_x: int, foot_y: int, animation: str) -> None:
    path = ROOT / "game" / "characters" / "corvin" / "sprites" / "act_i_clean" / f"{animation}.png"
    if not path.exists():
        raise FileNotFoundError(f"Missing Corvin runtime sheet: {path}")
    sheet = Image.open(path).convert("RGBA")
    frame_count = 6 if animation.startswith("talk") else 8 if animation.startswith(("use", "wet")) else 12
    frame_w = sheet.width // frame_count
    frame = sheet.crop((0, 0, frame_w, sheet.height))
    paste_corvin_sprite(image, frame, foot_x, foot_y, 0.76)


def paste_corvin_sprite(image: Image.Image, sprite: Image.Image, foot_x: int, foot_y: int, scale: float) -> None:
    sprite = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.LANCZOS)
    draw_contact_shadow(image, sprite.width, sprite.height, foot_x, foot_y)
    x = round(foot_x - sprite.width / 2)
    y = round(foot_y - sprite.height)
    shadow = Image.new("RGBA", sprite.size, (12, 16, 19, 0))
    alpha = sprite.getchannel("A").point(lambda value: round(value * 0.44))
    shadow.putalpha(alpha)
    image.alpha_composite(shadow, (x + 10, y + 14))
    image.alpha_composite(sprite, (x, y))


def draw_contact_shadow(image: Image.Image, width: int, height: int, foot_x: int, foot_y: int) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    shadow_w = max(42, min(128, round(width * 0.30)))
    shadow_h = max(10, min(28, round(height * 0.038)))
    draw.ellipse((foot_x - shadow_w, foot_y - shadow_h, foot_x + shadow_w, foot_y + shadow_h), fill=(12, 16, 19, 132))


def draw_wet_floor_reflection(image: Image.Image, sprite: Image.Image, foot_x: int, foot_y: int) -> None:
    reflection = sprite.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    reflection = reflection.resize((round(reflection.width * 0.88), max(10, round(reflection.height * 0.18))), Image.Resampling.BICUBIC)
    tint = Image.new("RGBA", reflection.size, (42, 58, 64, 0))
    alpha = reflection.getchannel("A").point(lambda value: round(value * 0.18))
    tint.putalpha(alpha)
    image.alpha_composite(tint, (round(foot_x - tint.width / 2), foot_y + 5))


def add_hud(image: Image.Image, room_code: str, title: str) -> None:
    status = Image.open(ROOT / "game" / "ui" / "skins" / "act_i" / "status_strip.png").convert("RGBA")
    dialogue = Image.open(ROOT / "game" / "ui" / "skins" / "act_i" / "dialogue_panel.png").convert("RGBA")
    inventory = Image.open(ROOT / "game" / "ui" / "skins" / "act_i" / "bottom_inventory_panel.png").convert("RGBA")

    status = status.resize((round(status.width * 0.88), round(status.height * 0.36)), Image.Resampling.LANCZOS)
    dialogue = dialogue.resize((round(dialogue.width * 0.50), round(dialogue.height * 0.40)), Image.Resampling.LANCZOS)
    inventory = inventory.resize((round(inventory.width * 0.63), round(inventory.height * 0.34)), Image.Resampling.LANCZOS)

    image.alpha_composite(status, (12, 28))
    image.alpha_composite(dialogue, (752, 902))
    image.alpha_composite(inventory, (24, 928))

    draw = ImageDraw.Draw(image, "RGBA")
    font = ImageFont.load_default()
    draw.rectangle((18, 16, 396, 60), fill=(12, 16, 19, 164), outline=(201, 138, 60, 110))
    draw.text((32, 28), f"{room_code} / {title}", fill=PALETTE["bone"], font=font)
    draw.text((32, 44), "LOOK  USE  TALK  WET", fill=PALETTE["amber"], font=font)
    draw.text((778, 928), "Corvin: dead, damp, and still doing the voice.", fill=PALETTE["bone"], font=font)


def build_frame(room: dict) -> dict:
    base_path = ROOT / room["base"]
    if not base_path.exists():
        raise FileNotFoundError(f"Missing room composite base: {base_path}")
    image = Image.open(base_path).convert("RGBA")

    for overlay_id, rel_path, x, y, width, height, _frames in room["overlays"]:
        frame = first_frame(ROOT / rel_path, width, height)
        image.alpha_composite(frame, (x, y))

    for standee_id, foot_x, foot_y, scale in room["standees"]:
        standee_path = ROOT / "game" / "standees" / "act_i" / f"{standee_id}.png"
        standee = Image.open(standee_path).convert("RGBA")
        paste_sprite(image, standee, foot_x, foot_y, scale)

    player_x, player_y, animation = room["player"]
    paste_corvin(image, player_x, player_y, animation)
    add_hud(image, room["code"], room["title"])

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUT_DIR / f"{room['room_id']}_runtime_frame.png"
    image.save(output, optimize=True)
    return {
        "room_code": room["code"],
        "room_id": room["room_id"],
        "title": room["title"],
        "output": output.relative_to(ROOT).as_posix(),
        "base": room["base"],
        "standee_count": len(room["standees"]),
        "standee_reflection_count": len(room["standees"]),
        "overlay_count": len(room["overlays"]),
        "includes_corvin": True,
        "includes_hud": True,
    }


def build_contact(records: list[dict]) -> None:
    pad = 24
    thumb_w, thumb_h = 480, 270
    label_h = 36
    columns = 2
    rows = (len(records) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_w + (columns + 1) * pad, rows * (thumb_h + label_h) + (rows + 1) * pad), PALETTE["black"])
    draw = ImageDraw.Draw(sheet)
    for index, record in enumerate(records):
        frame = Image.open(ROOT / record["output"]).convert("RGB")
        frame.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = pad + (index % columns) * (thumb_w + pad)
        y = pad + (index // columns) * (thumb_h + label_h + pad)
        sheet.paste(frame, (x, y))
        draw.text((x, y + thumb_h + 8), f"{record['room_code']} / {record['title']}", fill=PALETTE["bone"])
    CONTACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_PATH, optimize=True)


def main() -> None:
    records = [build_frame(room) for room in ROOMS]
    build_contact(records)
    report = {
        "status": "exported",
        "frame_count": len(records),
        "contact_sheet": CONTACT_PATH.relative_to(ROOT).as_posix(),
        "runtime_evidence": "runtime foreground props, prop grounding, Corvin, standees, standee wet-floor reflections, first-frame overlays, and generated HUD skin",
        "rooms": records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Act I Runtime Review Frames",
        "",
        "Generated player-view review frames using runtime foreground prop composites, prop grounding, Corvin side sprites, NPC standees, first-frame atmosphere/setpieces, contact shadows, wet-floor reflections, and the generated noir HUD skin.",
        "",
        f"- Contact sheet: `{report['contact_sheet']}`",
        f"- Frame count: {len(records)}",
        "- Purpose: prove the current Act I presentation looks like an in-game screen, not only isolated art assets.",
        "",
        "| Room | Runtime frame | Includes |",
        "|---|---|---|",
    ]
    for record in records:
        includes = ["Corvin", "HUD"]
        if record["standee_count"]:
            includes.append(f"{record['standee_count']} standee(s)")
            includes.append(f"{record['standee_reflection_count']} standee reflection(s)")
        if record["overlay_count"]:
            includes.append(f"{record['overlay_count']} overlay(s)")
        lines.append(f"| {record['room_code']} / {record['title']} | `{record['output']}` | {', '.join(includes)} |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"runtime_frames={len(records)}")
    print(f"contact_sheet={CONTACT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
