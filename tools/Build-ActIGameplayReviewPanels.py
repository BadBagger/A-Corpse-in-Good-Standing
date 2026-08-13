from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE_JSON = ROOT / "docs" / "art" / "act_i_godot_runtime_frames.json"
OUT_DIR = ROOT / "docs" / "art" / "review" / "act_i_gameplay_review_panels"
CONTACT_PATH = ROOT / "docs" / "art" / "review" / "act_i_gameplay_review_panels_contact_sheet.png"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_gameplay_review_panels.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_gameplay_review_panels.md"

PALETTE = {
    "bone": (228, 220, 200),
    "black": (12, 16, 19),
    "slate": (42, 58, 64),
    "amber": (201, 138, 60),
}


def crop_gameplay_panel(frame: Image.Image) -> Image.Image:
    # This crop keeps the playable figure band, foreground props, and dialogue HUD
    # readable at review size while preserving the current runtime frame source.
    return frame.crop((480, 360, 1680, 1080))


def build_panel(room: dict) -> dict:
    frame_path = ROOT / str(room["output"])
    if not frame_path.exists():
        raise FileNotFoundError(f"Missing runtime frame for gameplay panel: {frame_path}")
    image = Image.open(frame_path).convert("RGB")
    panel = crop_gameplay_panel(image)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUT_DIR / f"{room['room_id']}_gameplay_panel.png"
    panel.save(output, optimize=True)
    return {
        "room_code": room["room_code"],
        "room_id": room["room_id"],
        "title": room["title"],
        "source_frame": room["output"],
        "output": output.relative_to(ROOT).as_posix(),
        "width": panel.width,
        "height": panel.height,
        "crop_box": [480, 360, 1680, 1080],
        "dialogue_caption": room["dialogue_caption"],
        "includes_hud_crop": True,
        "includes_runtime_art": True,
    }


def build_contact(records: list[dict]) -> None:
    pad = 28
    thumb_w, thumb_h = 600, 360
    label_h = 58
    columns = 2
    rows = (len(records) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_w + (columns + 1) * pad, rows * (thumb_h + label_h) + (rows + 1) * pad), PALETTE["black"])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, record in enumerate(records):
        panel = Image.open(ROOT / record["output"]).convert("RGB")
        panel.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = pad + (index % columns) * (thumb_w + pad)
        y = pad + (index // columns) * (thumb_h + label_h + pad)
        sheet.paste(panel, (x, y))
        draw.text((x, y + thumb_h + 8), f"{record['room_code']} / {record['title']}", fill=PALETTE["bone"], font=font)
        draw.text((x, y + thumb_h + 24), record["dialogue_caption"][:92], fill=PALETTE["amber"], font=font)
    CONTACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_PATH, optimize=True)


def main() -> None:
    source = json.loads(SOURCE_JSON.read_text(encoding="utf-8"))
    rooms = list(source["rooms"])
    records = [build_panel(room) for room in rooms]
    build_contact(records)
    report = {
        "status": "exported",
        "source": SOURCE_JSON.relative_to(ROOT).as_posix(),
        "panel_count": len(records),
        "contact_sheet": CONTACT_PATH.relative_to(ROOT).as_posix(),
        "purpose": "larger cropped gameplay panels for mobile/human review of runtime art, Corvin, NPCs, foreground props, HUD, and room-specific dialogue captions",
        "panels": records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Act I Gameplay Review Panels",
        "",
        "Generated from the current Godot runtime frame proof. These larger crops make the playable band, generated room art, Corvin, NPC standees, foreground props, HUD, and room-specific dialogue captions easier to inspect than the full-room contact sheet.",
        "",
        f"- Contact sheet: `{report['contact_sheet']}`",
        f"- Panel count: {len(records)}",
        "- Crop box: `480,360,1680,1080` from each 1920x1080 frame",
        "",
        "| Room | Panel | Dialogue caption |",
        "|---|---|---|",
    ]
    for record in records:
        lines.append(f"| {record['room_code']} / {record['title']} | `{record['output']}` | {record['dialogue_caption']} |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"gameplay_review_panels={len(records)}")
    print(f"contact_sheet={CONTACT_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
