from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "art" / "review" / "act_i_in_scene_action_frames"
CONTACT_PATH = ROOT / "docs" / "art" / "review" / "act_i_in_scene_action_contact_sheet.png"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_in_scene_action_review.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_in_scene_action_review.md"

PALETTE = {
    "bone": (228, 220, 200),
    "black": (12, 16, 19),
    "slate": (42, 58, 64),
    "amber": (201, 138, 60),
    "ink": (52, 32, 22),
}

CASES = [
    {
        "id": "salt_market_talk_crowd_turn",
        "room_code": "R03",
        "title": "Salt Market",
        "base": "docs/art/review/salt_market_openai_prop_composite.png",
        "corvin": (620, 790, "talk_side_right"),
        "crowd_hotspot": (960, 760),
        "action_focus": {"position": (960, 760), "verb": "talk"},
        "setpieces": [
            ("salt_market_crowd_turn_to_corvin", "game/rooms/salt_market/setpieces/salt_market_crowd_turn_to_corvin.png", 1070, 455, 520, 330, 10, 4),
            ("salt_market_lamp_flicker", "game/rooms/salt_market/atmosphere/salt_market_lamp_flicker.png", 1210, 210, 540, 500, 8, 0),
        ],
        "standees": [],
        "caption": "Talk: crowd turns toward Corvin.",
        "expected_setpiece_state": "turn_to_corvin",
    },
    {
        "id": "salt_market_use_crowd_turn",
        "room_code": "R03",
        "title": "Salt Market",
        "base": "docs/art/review/salt_market_openai_prop_composite.png",
        "corvin": (620, 790, "use_side_right"),
        "crowd_hotspot": (960, 760),
        "action_focus": {"position": (960, 760), "verb": "use"},
        "setpieces": [
            ("salt_market_crowd_turn_to_corvin", "game/rooms/salt_market/setpieces/salt_market_crowd_turn_to_corvin.png", 1070, 455, 520, 330, 10, 7),
            ("salt_market_lamp_flicker", "game/rooms/salt_market/atmosphere/salt_market_lamp_flicker.png", 1210, 210, 540, 500, 8, 2),
        ],
        "standees": [],
        "caption": "Use: public recognition has a visible crowd reaction.",
        "expected_setpiece_state": "turn_to_corvin",
    },
    {
        "id": "old_quay_wet_action",
        "room_code": "R02",
        "title": "The Old Quay",
        "base": "docs/art/review/old_quay_openai_prop_composite.png",
        "corvin": (820, 760, "wet_side_right"),
        "setpieces": [
            ("old_quay_water_glint", "game/rooms/old_quay/atmosphere/old_quay_water_glint.png", 0, 650, 1920, 310, 8, 3),
        ],
        "standees": [("tomas_bollard", 400, 735, 1.0)],
        "action_focus": {"position": (655, 740), "verb": "wet"},
        "pulse": {"position": (655, 740), "radius": 82, "color": (228, 220, 200, 148), "effect": "rope"},
        "caption": "Wet: Corvin's supernatural verb reads in the room.",
        "expected_setpiece_state": "water_glint_loop",
    },
    {
        "id": "harbor_registry_talk_registrar",
        "room_code": "R05",
        "title": "Harbor Registry",
        "base": "docs/art/review/harbor_registry_openai_prop_composite.png",
        "corvin": (760, 780, "talk_side_right"),
        "standees": [("registrar", 1230, 705, 0.78)],
        "setpieces": [
            ("harbor_registry_lamp_smoke", "game/rooms/harbor_registry/atmosphere/harbor_registry_lamp_smoke.png", 700, 300, 520, 430, 10, 5),
        ],
        "action_focus": {"position": (1230, 585), "verb": "talk"},
        "pulse": {"position": (890, 650), "radius": 108, "color": (228, 220, 200, 118), "effect": "smoke"},
        "caption": "Talk: Registrar duel staging keeps both speakers readable.",
        "expected_setpiece_state": "lamp_smoke_loop",
    },
    {
        "id": "bone_chandler_use_counter",
        "room_code": "R06",
        "title": "The Bone Chandler",
        "base": "docs/art/review/bone_chandler_openai_prop_composite.png",
        "corvin": (720, 780, "use_side_right"),
        "standees": [("bone_chandler", 1200, 760, 0.78)],
        "setpieces": [],
        "action_focus": {"position": (1018, 612), "verb": "use"},
        "caption": "Use: counter interaction keeps prop, hand, and shopkeeper clear.",
        "expected_setpiece_state": "npc_counter_staging",
    },
    {
        "id": "almshouse_talk_prosper",
        "room_code": "R07",
        "title": "The Almshouse",
        "base": "docs/art/review/almshouse_openai_prop_composite.png",
        "corvin": (820, 790, "talk_side_right"),
        "standees": [("prosper", 1190, 775, 0.82)],
        "setpieces": [],
        "action_focus": {"position": (1190, 610), "verb": "talk"},
        "caption": "Talk: Prosper's debt-forgiveness beat has readable eyelines.",
        "expected_setpiece_state": "npc_dialogue_staging",
    },
    {
        "id": "grey_float_talk_action",
        "room_code": "R10",
        "title": "The Grey Float",
        "base": "docs/art/review/grey_float_openai_prop_composite.png",
        "corvin": (800, 780, "talk_side_right"),
        "standees": [("juno", 1250, 745, 0.75)],
        "setpieces": [
            ("grey_float_steam_drift", "game/rooms/grey_float/atmosphere/grey_float_steam_drift.png", 120, 330, 1640, 470, 10, 5),
        ],
        "action_focus": {"position": (1250, 585), "verb": "talk"},
        "caption": "Talk: action silhouette remains readable through steam.",
        "expected_setpiece_state": "steam_loop",
    },
    {
        "id": "sabine_office_talk_sabine",
        "room_code": "R12",
        "title": "Sabine's Office",
        "base": "docs/art/review/sabine_office_openai_prop_composite.png",
        "corvin": (790, 780, "talk_side_right"),
        "standees": [("sabine", 1260, 735, 0.76)],
        "setpieces": [
            ("sabine_office_window_rain", "game/rooms/sabine_office/atmosphere/sabine_office_window_rain.png", 900, 90, 650, 470, 8, 4),
        ],
        "action_focus": {"position": (1260, 575), "verb": "talk"},
        "caption": "Talk: Sabine's office reads as a two-character scene.",
        "expected_setpiece_state": "window_rain_loop",
    },
    {
        "id": "fish_hall_wet_drain",
        "room_code": "R08",
        "title": "The Fish Hall",
        "base": "docs/art/review/fish_hall_openai_prop_composite.png",
        "corvin": (800, 780, "wet_side_right"),
        "standees": [],
        "setpieces": [],
        "action_focus": {"position": (1410, 725), "verb": "wet"},
        "pulse": {"position": (1410, 725), "radius": 96, "color": (228, 220, 200, 138), "effect": "drain"},
        "caption": "Wet: drain reaction gives the puzzle verb a visible effect.",
        "expected_setpiece_state": "wet_pulse_drain",
    },
]


def sheet_frame(path: Path, frame_w: int, frame_h: int, frame_count: int, frame_index: int) -> Image.Image:
    sheet = Image.open(path).convert("RGBA")
    index = max(0, min(frame_count - 1, frame_index))
    return sheet.crop((index * frame_w, 0, index * frame_w + frame_w, frame_h))


def paste_corvin(image: Image.Image, foot_x: int, foot_y: int, animation: str) -> dict[str, object]:
    path = ROOT / "game" / "characters" / "corvin" / "sprites" / "act_i_clean" / f"{animation}.png"
    if not path.exists():
        raise FileNotFoundError(f"Missing Corvin runtime sheet: {path}")
    frame_count = 6 if animation.startswith("talk") else 8 if animation.startswith(("use", "wet")) else 12
    with Image.open(path) as sheet:
        frame = sheet_frame(path, sheet.width // frame_count, sheet.height, frame_count, max(1, frame_count // 2))
    sprite = frame.resize((round(frame.width * 0.76), round(frame.height * 0.76)), Image.Resampling.LANCZOS)
    draw_contact_shadow(image, sprite.width, sprite.height, foot_x, foot_y)
    x = round(foot_x - sprite.width / 2)
    y = round(foot_y - sprite.height)
    shadow = Image.new("RGBA", sprite.size, (12, 16, 19, 0))
    alpha = sprite.getchannel("A").point(lambda value: round(value * 0.42))
    shadow.putalpha(alpha)
    image.alpha_composite(shadow, (x + 10, y + 14))
    if animation in {"talk_side_right", "use_side_right"} and foot_x == 620:
        edge_alpha = sprite.getchannel("A").filter(ImageFilter.MaxFilter(5)).point(lambda value: round(value * 0.18))
        warm = Image.new("RGBA", sprite.size, (201, 138, 60, 0))
        warm.putalpha(edge_alpha)
        image.alpha_composite(warm, (x + 5, y + 2))
    image.alpha_composite(sprite, (x, y))
    return {"animation": animation, "frame_count": frame_count, "scaled_size": [sprite.width, sprite.height]}


def paste_standee(image: Image.Image, standee_id: str, foot_x: int, foot_y: int, scale: float) -> dict[str, object]:
    path = ROOT / "game" / "standees" / "act_i" / f"{standee_id}.png"
    if not path.exists():
        raise FileNotFoundError(f"Missing Act I standee: {path}")
    sprite = Image.open(path).convert("RGBA")
    if scale != 1.0:
        sprite = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.LANCZOS)
    draw_contact_shadow(image, sprite.width, sprite.height, foot_x, foot_y)
    reflection = sprite.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    reflection = reflection.resize((round(reflection.width * 0.88), max(10, round(reflection.height * 0.18))), Image.Resampling.BICUBIC)
    tint = Image.new("RGBA", reflection.size, (42, 58, 64, 0))
    alpha = reflection.getchannel("A").point(lambda value: round(value * 0.16))
    tint.putalpha(alpha)
    image.alpha_composite(tint, (round(foot_x - tint.width / 2), foot_y + 5))
    image.alpha_composite(sprite, (round(foot_x - sprite.width / 2), round(foot_y - sprite.height)))
    return {"id": standee_id, "foot": [foot_x, foot_y], "scaled_size": [sprite.width, sprite.height]}


def draw_contact_shadow(image: Image.Image, width: int, height: int, foot_x: int, foot_y: int) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    shadow_w = max(42, min(128, round(width * 0.30)))
    shadow_h = max(10, min(28, round(height * 0.038)))
    draw.ellipse((foot_x - shadow_w, foot_y - shadow_h, foot_x + shadow_w, foot_y + shadow_h), fill=(12, 16, 19, 132))


def draw_interaction_pulse(image: Image.Image, pulse: dict[str, object]) -> dict[str, object]:
    x, y = pulse["position"]
    radius = int(pulse["radius"])
    color = tuple(pulse["color"])
    effect = str(pulse.get("effect", "ripple"))
    draw = ImageDraw.Draw(image, "RGBA")
    draw.ellipse((x - radius, y - radius * 0.38, x + radius, y + radius * 0.38), outline=color, width=5)
    draw.ellipse((x - radius * 0.58, y - radius * 0.22, x + radius * 0.58, y + radius * 0.22), fill=(color[0], color[1], color[2], max(26, color[3] // 4)))
    if effect == "rope":
        for index in range(3):
            ox = -36 + index * 32
            oy = -18 + index * 11
            draw.line((x + ox, y + oy, x + ox + 34, y + oy + 9), fill=(228, 220, 200, 132 - index * 18), width=5 - index)
    elif effect == "smoke":
        for index in range(3):
            puff_radius = max(18, int(radius * (0.24 - index * 0.025)))
            px = x - 30 + index * 32
            py = y - 28 - index * 20
            draw.ellipse((px - puff_radius, py - puff_radius * 0.38, px + puff_radius, py + puff_radius * 0.38), fill=(228, 220, 200, 76 - index * 12))
    elif effect == "drain":
        for index in range(4):
            sx = x - 90 + index * 38
            sy = y - 18 + (index % 2) * 16
            draw.line((sx, sy, x - 12 + index * 6, y + 4), fill=(228, 220, 200, 112), width=3)
    elif effect == "ink":
        for index in range(4):
            top_x = x - 40 + index * 26
            top_y = y - 38
            draw.line((top_x, top_y, top_x - 5 + (index % 2) * 8, top_y + 62 + index * 9), fill=(201, 138, 60, 158), width=4)
    return {"position": [int(x), int(y)], "radius": radius, "effect": effect, "visible_text": False}


def draw_action_focus(image: Image.Image, focus: dict[str, object]) -> dict[str, object]:
    x, y = focus["position"]
    verb = str(focus.get("verb", "look"))
    radius = 52 if verb == "wet" else 44 if verb == "talk" else 36
    draw = ImageDraw.Draw(image, "RGBA")
    draw.ellipse((x - radius, y - radius * 0.34, x + radius, y + radius * 0.34), outline=(201, 138, 60, 138), width=3)
    draw.line((x - radius * 0.52, y - radius * 0.10, x + radius * 0.52, y + radius * 0.10), fill=(228, 220, 200, 184), width=2)
    return {"position": [int(x), int(y)], "verb": verb, "radius": radius, "visible_text": False}


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        bbox = draw.textbbox((0, 0), candidate, font=font)
        if bbox[2] - bbox[0] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines[:2]


def load_font(size: int) -> ImageFont.ImageFont:
    for font_name in ("arial.ttf", "segoeui.ttf"):
        try:
            return ImageFont.truetype(font_name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def add_game_hud(image: Image.Image, room_code: str, title: str, caption: str) -> None:
    status = Image.open(ROOT / "game" / "ui" / "skins" / "act_i" / "status_strip.png").convert("RGBA")
    dialogue = Image.open(ROOT / "game" / "ui" / "skins" / "act_i" / "dialogue_panel.png").convert("RGBA")
    inventory = Image.open(ROOT / "game" / "ui" / "skins" / "act_i" / "bottom_inventory_panel.png").convert("RGBA")

    status = prepare_status_strip(status)
    dialogue = dialogue.resize((900, 128), Image.Resampling.LANCZOS)
    inventory = inventory.resize((round(inventory.width * 0.63), round(inventory.height * 0.34)), Image.Resampling.LANCZOS)

    image.alpha_composite(status, (12, 24))
    image.alpha_composite(dialogue, (530, 882))
    image.alpha_composite(inventory, (24, 928))

    draw = ImageDraw.Draw(image, "RGBA")
    font = ImageFont.load_default()
    caption_font = load_font(20)
    draw.text((48, 39), f"{room_code} / {title}", fill=PALETTE["bone"], font=font)
    draw.text((48, 56), "LOOK  USE  TALK  WET", fill=PALETTE["amber"], font=font)
    for index, line in enumerate(wrap_text(draw, caption, caption_font, 700)):
        draw.text((650, 908 + index * 25), line, fill=PALETTE["ink"], font=caption_font)


def prepare_status_strip(status: Image.Image) -> Image.Image:
    status = status.crop((0, 0, 430, status.height))
    status = status.resize((390, 56), Image.Resampling.LANCZOS)
    pixels = status.load()
    for y in range(status.height):
        for x in range(status.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha and red < 18 and green < 20 and blue < 22:
                pixels[x, y] = (red, green, blue, 0)
    return status


def build_frame(case: dict[str, object]) -> dict[str, object]:
    base = Image.open(ROOT / str(case["base"])).convert("RGBA")
    for _overlay_id, rel_path, x, y, width, height, frames, frame_index in case["setpieces"]:
        overlay = sheet_frame(ROOT / rel_path, width, height, frames, frame_index)
        base.alpha_composite(overlay, (x, y))
    standee_records = []
    for standee_id, standee_x, standee_y, standee_scale in case.get("standees", []):
        standee_records.append(paste_standee(base, str(standee_id), int(standee_x), int(standee_y), float(standee_scale)))
    foot_x, foot_y, animation = case["corvin"]
    corvin_meta = paste_corvin(base, int(foot_x), int(foot_y), str(animation))
    pulse_record = {}
    if "pulse" in case:
        pulse_record = draw_interaction_pulse(base, case["pulse"])
    action_focus = draw_action_focus(base, case["action_focus"])
    add_game_hud(base, str(case["room_code"]), str(case["title"]), str(case["caption"]))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUT_DIR / f"{case['id']}.png"
    base.save(output, optimize=True)
    crowd_hotspot = list(case.get("crowd_hotspot", ()))
    crowd_distance = None
    if crowd_hotspot:
        crowd_distance = round(((int(foot_x) - int(crowd_hotspot[0])) ** 2 + (int(foot_y) - int(crowd_hotspot[1])) ** 2) ** 0.5, 1)
    return {
        "id": case["id"],
        "room_code": case["room_code"],
        "title": case["title"],
        "output": output.relative_to(ROOT).as_posix(),
        "corvin_animation": corvin_meta["animation"],
        "corvin_frame_count": corvin_meta["frame_count"],
        "corvin_scaled_size": corvin_meta["scaled_size"],
        "corvin_foot": [int(foot_x), int(foot_y)],
        "standees": standee_records,
        "standee_count": len(standee_records),
        "interaction_pulse": pulse_record,
        "action_focus": action_focus,
        "uses_action_focus_mark": True,
        "uses_interaction_pulse": bool(pulse_record),
        "crowd_hotspot": crowd_hotspot,
        "crowd_distance_px": crowd_distance,
        "expected_setpiece_state": case["expected_setpiece_state"],
        "uses_in_scene_corvin_action": True,
        "uses_sectional_setpiece_frame": bool(case["setpieces"]),
        "uses_named_npc_standee": len(standee_records) > 0,
        "uses_generated_game_hud": True,
        "dialogue_text_embedded_in_hud": True,
        "status_text_embedded_in_generated_hud": True,
    }


def build_contact(records: list[dict[str, object]]) -> None:
    pad = 24
    room_w, room_h = 480, 270
    crop_w, crop_h = 220, 270
    panel_w = room_w + 12 + crop_w
    label_h = 38
    columns = 2
    rows = (len(records) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * panel_w + (columns + 1) * pad, rows * (room_h + label_h) + (rows + 1) * pad), PALETTE["black"])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, record in enumerate(records):
        frame = Image.open(ROOT / str(record["output"])).convert("RGB")
        room_thumb = frame.copy()
        room_thumb.thumbnail((room_w, room_h), Image.Resampling.LANCZOS)
        foot_x, foot_y = record["corvin_foot"]
        focus_points = [(int(foot_x), int(foot_y) - 170)]
        for standee in record.get("standees", []):
            standee_foot = standee.get("foot", [])
            if len(standee_foot) == 2:
                focus_points.append((int(standee_foot[0]), int(standee_foot[1]) - 170))
        crowd_hotspot = record.get("crowd_hotspot", [])
        if len(crowd_hotspot) == 2:
            focus_points.append((int(crowd_hotspot[0]), int(crowd_hotspot[1]) - 140))
        min_x = min(point[0] for point in focus_points)
        max_x = max(point[0] for point in focus_points)
        min_y = min(point[1] for point in focus_points)
        max_y = max(point[1] for point in focus_points)
        crop_box = (
            max(0, min_x - 120),
            max(0, min_y - 180),
            min(frame.width, max_x + 120),
            min(frame.height, max_y + 230),
        )
        action_crop = frame.crop(crop_box)
        action_crop.thumbnail((crop_w, crop_h), Image.Resampling.LANCZOS)
        x = pad + (index % columns) * (panel_w + pad)
        y = pad + (index // columns) * (room_h + label_h + pad)
        sheet.paste(room_thumb, (x, y))
        crop_x = x + room_w + 12
        sheet.paste(action_crop, (crop_x, y))
        draw.rectangle((crop_x, y, crop_x + crop_w - 1, y + crop_h - 1), outline=PALETTE["amber"])
        draw.text((x, y + room_h + 8), f"{record['room_code']} / {record['corvin_animation']} / {record['expected_setpiece_state']}", fill=PALETTE["bone"], font=font)
    CONTACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_PATH, optimize=True)


def main() -> None:
    records = [build_frame(case) for case in CASES]
    build_contact(records)
    report = {
        "status": "exported",
        "frame_count": len(records),
        "contact_sheet": CONTACT_PATH.relative_to(ROOT).as_posix(),
        "runtime_evidence": "In-scene action review frames show Corvin talk/use/wet side actions inside Act I rooms, including the Salt Market crowd turn_to_corvin sectional setpiece state, named NPC standee dialogue/counter staging, generated game HUD with embedded status and dialogue text, text-free action focus marks, and text-free wet interaction effects.",
        "frames": records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Act I In-Scene Action Review",
        "",
        "Generated by `tools/Build-ActIInSceneActionReview.py`.",
        "",
        "These review frames show Corvin's talk, use, and wet side actions inside Act I room compositions. The Salt Market cases use the crowd `turn_to_corvin` sectional setpiece state, the named NPC cases include standees, contact shadows, and wet-floor reflections, the frames use the generated game HUD with embedded status and dialogue text, every case includes a text-free action focus mark at the clicked target, and the wet cases include text-free interaction effects, so the review proof covers interaction staging instead of only static idle room shots.",
        "",
        f"- Contact sheet: `{report['contact_sheet']}`",
        f"- Frame count: {len(records)}",
        "",
        "| Frame | Room | Corvin action | NPCs | Focus | Pulse | Setpiece state | Output |",
        "|---|---|---|---:|---|---|---|---|",
    ]
    for record in records:
        pulse = record.get("interaction_pulse", {})
        pulse_effect = pulse.get("effect", "-") if pulse else "-"
        focus = record.get("action_focus", {})
        focus_verb = focus.get("verb", "-") if focus else "-"
        lines.append(f"| {record['id']} | {record['room_code']} / {record['title']} | `{record['corvin_animation']}` | {record['standee_count']} | {focus_verb} | {pulse_effect} | `{record['expected_setpiece_state']}` | `{record['output']}` |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"in_scene_action_frames={len(records)}")
    print(f"contact_sheet={CONTACT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
