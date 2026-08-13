from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "docs" / "art" / "review"
OUTPUT = REVIEW_DIR / "act_i_openai_prop_composite_contact_sheet.png"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_openai_prop_composite_contact_sheet.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_openai_prop_composite_contact_sheet.md"

ROOMS = [
    ("mudflats", "Mudflats", "mudflats_openai_prop_composite.png"),
    ("old_quay", "Old Quay", "old_quay_openai_prop_composite.png"),
    ("salt_market", "Salt Market", "salt_market_openai_prop_composite.png"),
    ("harbor_registry", "Harbor Registry", "harbor_registry_openai_prop_composite.png"),
    ("bone_chandler", "Bone Chandler", "bone_chandler_openai_prop_composite.png"),
    ("almshouse", "Almshouse", "almshouse_openai_prop_composite.png"),
    ("fish_hall", "Fish Hall", "fish_hall_openai_prop_composite.png"),
    ("church_of_the_drowned", "Church", "church_of_the_drowned_openai_prop_composite.png"),
    ("grey_float", "Grey Float", "grey_float_openai_prop_composite.png"),
    ("harbormaster_office", "Harbormaster Office", "harbormaster_office_openai_prop_composite.png"),
    ("sabine_office", "Sabine Office", "sabine_office_openai_prop_composite.png"),
]


def open_thumbnail(path: Path, size: tuple[int, int]) -> Image.Image:
    image = Image.open(path).convert("RGB")
    image.thumbnail(size, Image.Resampling.LANCZOS)
    thumb = Image.new("RGB", size, (12, 16, 19))
    thumb.paste(image, ((size[0] - image.width) // 2, (size[1] - image.height) // 2))
    return thumb


def main() -> None:
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    cell_w = 480
    cell_h = 270
    label_h = 38
    pad = 18
    columns = 2
    rows = 6
    header_h = 78
    canvas_w = columns * cell_w + (columns + 1) * pad
    canvas_h = header_h + rows * (cell_h + label_h) + (rows + 1) * pad
    canvas = Image.new("RGB", (canvas_w, canvas_h), (12, 16, 19))
    draw = ImageDraw.Draw(canvas)
    bone = (228, 220, 200)
    amber = (201, 138, 60)
    slate = (42, 58, 64)

    draw.text((pad, 18), "A Corpse in Good Standing - Act I OpenAI Foreground Prop Composites", fill=bone)
    draw.text(
        (pad, 42),
        "Runtime room composites after generated prop cutout, palette lock, and Godot registration.",
        fill=amber,
    )

    entries: list[dict[str, object]] = []
    for index, (room_id, label, filename) in enumerate(ROOMS):
        source = REVIEW_DIR / filename
        if not source.exists():
            raise FileNotFoundError(f"Missing Act I composite for {room_id}: {source}")
        thumb = open_thumbnail(source, (cell_w, cell_h))
        col = index % columns
        row = index // columns
        x = pad + col * (cell_w + pad)
        y = header_h + pad + row * (cell_h + label_h + pad)
        canvas.paste(thumb, (x, y))
        draw.rectangle((x, y, x + cell_w - 1, y + cell_h - 1), outline=slate)
        draw.text((x, y + cell_h + 10), label, fill=bone)
        entries.append(
            {
                "room_id": room_id,
                "label": label,
                "composite": source.relative_to(ROOT).as_posix(),
                "contact_sheet": OUTPUT.relative_to(ROOT).as_posix(),
            }
        )

    canvas.save(OUTPUT)
    REPORT_JSON.write_text(
        json.dumps(
            {
                "status": "exported",
                "room_count": len(entries),
                "background_room_count": len(entries),
                "output": OUTPUT.relative_to(ROOT).as_posix(),
                "rooms": entries,
                "note": "Act I background rooms with OpenAI foreground prop composites.",
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Act I OpenAI Prop Composite Contact Sheet",
        "",
        "Single review image for the Act I foreground prop pass. Each tile is a runtime-room composite generated from the current background plus palette-locked OpenAI foreground props.",
        "",
        f"- Contact sheet: `{OUTPUT.relative_to(ROOT).as_posix()}`",
        f"- Room count: {len(entries)}",
        "- Scope: Act I background rooms only; future Act II rooms are intentionally excluded.",
        "- Content line: hard-R, no explicit anatomy, no gore, no bodies, no child figures in prop sheets.",
        "",
        "| Room | Composite |",
        "|---|---|",
    ]
    for entry in entries:
        lines.append(f"| {entry['label']} | `{entry['composite']}` |")
    lines.append("")
    REPORT_MD.write_text("\n".join(lines), encoding="utf-8")

    print(f"Exported Act I OpenAI prop composite contact sheet -> {OUTPUT}")


if __name__ == "__main__":
    main()
