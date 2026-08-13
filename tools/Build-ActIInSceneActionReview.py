from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


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
}

CASES = [
    {
        "id": "salt_market_talk_crowd_turn",
        "room_code": "R03",
        "title": "Salt Market",
        "base": "docs/art/review/salt_market_openai_prop_composite.png",
        "corvin": (720, 770, "talk_side_right"),
        "setpieces": [
            ("salt_market_crowd_turn_to_corvin", "game/rooms/salt_market/setpieces/salt_market_crowd_turn_to_corvin.png", 1070, 455, 520, 330, 10, 4),
            ("salt_market_lamp_flicker", "game/rooms/salt_market/atmosphere/salt_market_lamp_flicker.png", 1210, 210, 540, 500, 8, 0),
        ],
        "caption": "Talk: crowd turns toward Corvin.",
        "expected_setpiece_state": "turn_to_corvin",
    },
    {
        "id": "salt_market_use_crowd_turn",
        "room_code": "R03",
        "title": "Salt Market",
        "base": "docs/art/review/salt_market_openai_prop_composite.png",
        "corvin": (720, 770, "use_side_right"),
        "setpieces": [
            ("salt_market_crowd_turn_to_corvin", "game/rooms/salt_market/setpieces/salt_market_crowd_turn_to_corvin.png", 1070, 455, 520, 330, 10, 7),
            ("salt_market_lamp_flicker", "game/rooms/salt_market/atmosphere/salt_market_lamp_flicker.png", 1210, 210, 540, 500, 8, 2),
        ],
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
        "caption": "Wet: Corvin's supernatural verb reads in the room.",
        "expected_setpiece_state": "water_glint_loop",
    },
    {
        "id": "grey_float_talk_action",
        "room_code": "R10",
        "title": "The Grey Float",
        "base": "docs/art/review/grey_float_openai_prop_composite.png",
        "corvin": (800, 780, "talk_side_right"),
        "setpieces": [
            ("grey_float_steam_drift", "game/rooms/grey_float/atmosphere/grey_float_steam_drift.png", 120, 330, 1640, 470, 10, 5),
        ],
        "caption": "Talk: action silhouette remains readable through steam.",
        "expected_setpiece_state": "steam_loop",
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
    image.alpha_composite(sprite, (x, y))
    return {"animation": animation, "frame_count": frame_count, "scaled_size": [sprite.width, sprite.height]}


def draw_contact_shadow(image: Image.Image, width: int, height: int, foot_x: int, foot_y: int) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    shadow_w = max(42, min(128, round(width * 0.30)))
    shadow_h = max(10, min(28, round(height * 0.038)))
    draw.ellipse((foot_x - shadow_w, foot_y - shadow_h, foot_x + shadow_w, foot_y + shadow_h), fill=(12, 16, 19, 132))


def add_compact_hud(image: Image.Image, room_code: str, title: str, caption: str) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    font = ImageFont.load_default()
    draw.rectangle((18, 16, 490, 66), fill=(12, 16, 19, 174), outline=(201, 138, 60, 110))
    draw.text((32, 28), f"{room_code} / {title}", fill=PALETTE["bone"], font=font)
    draw.text((32, 46), caption, fill=PALETTE["amber"], font=font)


def build_frame(case: dict[str, object]) -> dict[str, object]:
    base = Image.open(ROOT / str(case["base"])).convert("RGBA")
    for _overlay_id, rel_path, x, y, width, height, frames, frame_index in case["setpieces"]:
        overlay = sheet_frame(ROOT / rel_path, width, height, frames, frame_index)
        base.alpha_composite(overlay, (x, y))
    foot_x, foot_y, animation = case["corvin"]
    corvin_meta = paste_corvin(base, int(foot_x), int(foot_y), str(animation))
    add_compact_hud(base, str(case["room_code"]), str(case["title"]), str(case["caption"]))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUT_DIR / f"{case['id']}.png"
    base.save(output, optimize=True)
    return {
        "id": case["id"],
        "room_code": case["room_code"],
        "title": case["title"],
        "output": output.relative_to(ROOT).as_posix(),
        "corvin_animation": corvin_meta["animation"],
        "corvin_frame_count": corvin_meta["frame_count"],
        "corvin_scaled_size": corvin_meta["scaled_size"],
        "corvin_foot": [int(foot_x), int(foot_y)],
        "expected_setpiece_state": case["expected_setpiece_state"],
        "uses_in_scene_corvin_action": True,
        "uses_sectional_setpiece_frame": True,
        "uses_compact_hud": True,
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
        crop_box = (
            max(0, int(foot_x) - 170),
            max(0, int(foot_y) - 360),
            min(frame.width, int(foot_x) + 170),
            min(frame.height, int(foot_y) + 90),
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
        "runtime_evidence": "In-scene action review frames show Corvin talk/use/wet side actions inside Act I rooms, including the Salt Market crowd turn_to_corvin sectional setpiece state.",
        "frames": records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Act I In-Scene Action Review",
        "",
        "Generated by `tools/Build-ActIInSceneActionReview.py`.",
        "",
        "These review frames show Corvin's talk, use, and wet side actions inside Act I room compositions. The Salt Market cases use the crowd `turn_to_corvin` sectional setpiece state, so the review proof covers the planned crowd reaction instead of only static idle room shots.",
        "",
        f"- Contact sheet: `{report['contact_sheet']}`",
        f"- Frame count: {len(records)}",
        "",
        "| Frame | Room | Corvin action | Setpiece state | Output |",
        "|---|---|---|---|---|",
    ]
    for record in records:
        lines.append(f"| {record['id']} | {record['room_code']} / {record['title']} | `{record['corvin_animation']}` | `{record['expected_setpiece_state']}` | `{record['output']}` |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"in_scene_action_frames={len(records)}")
    print(f"contact_sheet={CONTACT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
