from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_vKiKItmoAMivaAvGEOU6IqUE.png"
)

PALETTE = [
    (0x0C, 0x10, 0x13),
    (0x2A, 0x3A, 0x40),
    (0xE4, 0xDC, 0xC8),
    (0x7D, 0x9B, 0x4E),
    (0xC9, 0x8A, 0x3C),
    (0x8E, 0x1B, 0x22),
]

PROPS = [
    {
        "id": "confession_booth",
        "name": "Confession booth",
        "cell": (0, 0),
        "target_height": 230,
        "position": (705, 535),
        "z": 4,
        "hotspot": "ConfessionBooth",
    },
    {
        "id": "church_ledger_desk",
        "name": "Church ledger desk",
        "cell": (1, 0),
        "target_height": 155,
        "position": (875, 665),
        "z": 4,
        "hotspot": "RateCard",
    },
    {
        "id": "church_tariff_sign",
        "name": "Church tariff sign",
        "cell": (0, 1),
        "target_height": 150,
        "position": (1105, 645),
        "z": 5,
        "hotspot": "ChurchStallSign",
    },
    {
        "id": "poor_box",
        "name": "Poor box",
        "cell": (1, 1),
        "target_height": 145,
        "position": (545, 690),
        "z": 4,
        "hotspot": "PoorBox",
    },
]


def crop_cell(sheet: Image.Image, column: int, row: int) -> Image.Image:
    cell_width = sheet.width // 2
    cell_height = sheet.height // 2
    return sheet.crop(
        (
            column * cell_width,
            row * cell_height,
            (column + 1) * cell_width,
            (row + 1) * cell_height,
        )
    )


def trim_alpha(image: Image.Image, margin: int = 8) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    left = max(0, bbox[0] - margin)
    top = max(0, bbox[1] - margin)
    right = min(image.width, bbox[2] + margin)
    bottom = min(image.height, bbox[3] + margin)
    return image.crop((left, top, right, bottom))


def resize_to_height(image: Image.Image, target_height: int) -> Image.Image:
    if image.height == target_height:
        return image
    scale = target_height / image.height
    target_width = max(1, round(image.width * scale))
    return image.resize((target_width, target_height), Image.Resampling.LANCZOS)


def nearest_palette_color(r: int, g: int, b: int) -> tuple[int, int, int]:
    return min(
        PALETTE,
        key=lambda color: (r - color[0]) ** 2 + (g - color[1]) ** 2 + (b - color[2]) ** 2,
    )


def should_keep_church_green(r: int, g: int, b: int) -> bool:
    # Keep explicit absinthe light, not olive paper/wood highlights.
    return g > 120 and g > r * 1.20 and g > b * 1.06


def palette_lock(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if a < 12:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            nr, ng, nb = nearest_palette_color(r, g, b)
            if (nr, ng, nb) == (0x7D, 0x9B, 0x4E) and not should_keep_church_green(r, g, b):
                nr, ng, nb = (0xC9, 0x8A, 0x3C)
            if (nr, ng, nb) == (0x8E, 0x1B, 0x22):
                nr, ng, nb = (112, 70, 44)
            pixels[x, y] = (nr, ng, nb, a)
    return rgba


def make_contact_sheet(entries: list[dict[str, object]]) -> Image.Image:
    thumb_w, thumb_h = 360, 250
    pad = 28
    label_h = 44
    canvas = Image.new("RGB", (2 * thumb_w + 3 * pad, 2 * (thumb_h + label_h) + 3 * pad), (12, 16, 19))
    draw = ImageDraw.Draw(canvas)
    for index, entry in enumerate(entries):
        image = Image.open(ROOT / str(entry["game_resource"])).convert("RGBA")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        col = index % 2
        row = index // 2
        x = pad + col * (thumb_w + pad)
        y = pad + row * (thumb_h + label_h + pad)
        back = Image.new("RGBA", (thumb_w, thumb_h), (42, 58, 64, 255))
        back.alpha_composite(image, ((thumb_w - image.width) // 2, thumb_h - image.height))
        canvas.paste(back.convert("RGB"), (x, y))
        draw.text((x, y + thumb_h + 8), str(entry["name"]), fill=(228, 220, 200))
    return canvas


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing OpenAI Church prop sheet: {SOURCE}")

    src_dir = ROOT / "art" / "src" / "props" / "church_of_the_drowned" / "openai"
    export_dir = ROOT / "art" / "export" / "props" / "church_of_the_drowned"
    game_dir = ROOT / "game" / "rooms" / "church_of_the_drowned" / "props"
    review_dir = ROOT / "docs" / "art" / "review"
    for directory in (src_dir, export_dir, game_dir, review_dir):
        directory.mkdir(parents=True, exist_ok=True)

    source_copy = src_dir / "church_of_the_drowned_props_openai_raw.png"
    shutil.copyfile(SOURCE, source_copy)
    sheet = Image.open(SOURCE).convert("RGBA")
    manifest: list[dict[str, object]] = []

    for prop in PROPS:
        column, row = prop["cell"]
        raw = trim_alpha(crop_cell(sheet, column, row))
        alpha = resize_to_height(raw, int(prop["target_height"]))
        locked = palette_lock(alpha)

        raw_path = export_dir / f"{prop['id']}_raw.png"
        game_path = game_dir / f"{prop['id']}.png"
        alpha.save(raw_path)
        locked.save(game_path)

        manifest.append(
            {
                "id": prop["id"],
                "name": prop["name"],
                "source_sheet": source_copy.relative_to(ROOT).as_posix(),
                "raw_export": raw_path.relative_to(ROOT).as_posix(),
                "game_resource": game_path.relative_to(ROOT).as_posix(),
                "width": locked.width,
                "height": locked.height,
                "target_height": prop["target_height"],
                "position": prop["position"],
                "z": prop["z"],
                "hotspot": prop["hotspot"],
                "palette_locked": True,
                "alpha_cutout": True,
            }
        )

    contact_path = review_dir / "church_of_the_drowned_openai_props_contact_sheet.png"
    make_contact_sheet(manifest).save(contact_path)

    json_path = ROOT / "docs" / "art" / "church_of_the_drowned_openai_props.json"
    json_path.write_text(json.dumps({"props": manifest}, indent=2) + "\n", encoding="utf-8")

    md_lines = [
        "# Church of the Drowned OpenAI Foreground Props",
        "",
        "Foreground prop cutouts extracted from an OpenAI-generated Church source sheet, alpha-preserved, palette-locked, and staged for runtime use.",
        "",
        f"- Source sheet: `{source_copy.relative_to(ROOT).as_posix()}`",
        f"- Contact sheet: `{contact_path.relative_to(ROOT).as_posix()}`",
        "- Content line: hard-R, no explicit anatomy, no child figures",
        "",
        "| Prop | Runtime PNG | Size | Position | Hotspot |",
        "|---|---|---:|---:|---|",
    ]
    for entry in manifest:
        md_lines.append(
            f"| {entry['name']} | `{entry['game_resource']}` | {entry['width']}x{entry['height']} | {entry['position']} | {entry['hotspot']} |"
        )
    md_lines.append("")
    (ROOT / "docs" / "art" / "church_of_the_drowned_openai_props.md").write_text(
        "\n".join(md_lines), encoding="utf-8"
    )

    print(f"Imported Church of the Drowned OpenAI props: count={len(manifest)}, contact={contact_path}")


if __name__ == "__main__":
    main()
