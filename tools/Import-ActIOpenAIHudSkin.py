from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_yeV3qX6BCO5WvV79B5NhfCQ3.png"
)
SRC_DIR = ROOT / "art" / "src" / "ui" / "act_i" / "openai"
EXPORT_DIR = ROOT / "art" / "export" / "ui" / "act_i"
GAME_DIR = ROOT / "game" / "ui" / "skins" / "act_i"
REVIEW_DIR = ROOT / "docs" / "art" / "review"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_openai_hud_skin.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_openai_hud_skin.md"

ASSETS = [
    {
        "id": "status_strip",
        "name": "Top status strip",
        "box": (52, 16, 1516, 151),
        "runtime_width": 1200,
        "runtime_height": 112,
        "target": "StatusPanel",
    },
    {
        "id": "dialogue_panel",
        "name": "Dialogue parchment panel",
        "box": (44, 167, 1216, 514),
        "runtime_width": 780,
        "runtime_height": 230,
        "target": "DialoguePanel",
    },
    {
        "id": "verb_button_plate",
        "name": "Verb button plate",
        "box": (631, 548, 903, 632),
        "runtime_width": 154,
        "runtime_height": 54,
        "target": "Verb buttons",
    },
    {
        "id": "bottom_inventory_panel",
        "name": "Bottom inventory panel",
        "box": (19, 668, 1517, 986),
        "runtime_width": 980,
        "runtime_height": 208,
        "target": "Inventory and lower HUD",
    },
    {
        "id": "small_icon_frame",
        "name": "Small icon frame",
        "box": (1272, 233, 1497, 439),
        "runtime_width": 112,
        "runtime_height": 104,
        "target": "Litany icon frame",
    },
]


def save_runtime_asset(sheet: Image.Image, asset: dict[str, object]) -> dict[str, object]:
    crop = sheet.crop(asset["box"]).convert("RGBA")
    runtime = crop.resize((int(asset["runtime_width"]), int(asset["runtime_height"])), Image.Resampling.LANCZOS)
    export_path = EXPORT_DIR / f"{asset['id']}.png"
    game_path = GAME_DIR / f"{asset['id']}.png"
    export_path.parent.mkdir(parents=True, exist_ok=True)
    game_path.parent.mkdir(parents=True, exist_ok=True)
    runtime.save(export_path, optimize=True)
    runtime.save(game_path, optimize=True)
    return {
        "id": asset["id"],
        "name": asset["name"],
        "target": asset["target"],
        "source_box": list(asset["box"]),
        "export_path": export_path.relative_to(ROOT).as_posix(),
        "game_resource": game_path.relative_to(ROOT).as_posix(),
        "width": runtime.width,
        "height": runtime.height,
    }


def make_contact_sheet(records: list[dict[str, object]]) -> Image.Image:
    thumb_w = 420
    thumb_h = 180
    pad = 24
    label_h = 38
    rows = len(records)
    canvas = Image.new("RGB", (thumb_w + pad * 2, rows * (thumb_h + label_h) + pad), (12, 16, 19))
    draw = ImageDraw.Draw(canvas)
    for index, record in enumerate(records):
        image = Image.open(ROOT / record["game_resource"]).convert("RGBA")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = pad + (thumb_w - image.width) // 2
        y = pad + index * (thumb_h + label_h)
        back = Image.new("RGB", (thumb_w, thumb_h), (42, 58, 64))
        back.paste(image.convert("RGB"), ((thumb_w - image.width) // 2, (thumb_h - image.height) // 2))
        canvas.paste(back, (pad, y))
        draw.text((pad, y + thumb_h + 10), f"{record['id']} -> {record['target']}", fill=(228, 220, 200))
    return canvas


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing generated HUD skin source: {SOURCE}")
    SRC_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    source_copy = SRC_DIR / "act_i_hud_skin_openai_raw.png"
    shutil.copyfile(SOURCE, source_copy)

    sheet = Image.open(SOURCE).convert("RGBA")
    records = [save_runtime_asset(sheet, asset) for asset in ASSETS]

    contact_path = REVIEW_DIR / "act_i_openai_hud_skin_contact_sheet.png"
    make_contact_sheet(records).save(contact_path, optimize=True)

    report = {
        "status": "imported",
        "source_sheet": source_copy.relative_to(ROOT).as_posix(),
        "contact_sheet": contact_path.relative_to(ROOT).as_posix(),
        "asset_count": len(records),
        "assets": records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Act I OpenAI HUD Skin",
        "",
        "OpenAI-generated noir harbor UI texture sheet cropped into runtime HUD skin assets.",
        "",
        f"- Source sheet: `{report['source_sheet']}`",
        f"- Contact sheet: `{report['contact_sheet']}`",
        "- Content line: hard-R, no explicit anatomy, no gore, no bodies, no child figures",
        "- Runtime use: decorative HUD frames only; no puzzle state or dialogue text is stored in the image.",
        "",
        "| Asset | Runtime PNG | Size | Target |",
        "|---|---|---:|---|",
    ]
    for record in records:
        lines.append(f"| {record['name']} | `{record['game_resource']}` | {record['width']}x{record['height']} | {record['target']} |")
    lines.append("")
    REPORT_MD.write_text("\n".join(lines), encoding="utf-8")

    print(f"hud_skin_assets={len(records)}")
    print(f"contact={contact_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
