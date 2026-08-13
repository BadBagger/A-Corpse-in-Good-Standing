from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_IrobvALqCrymsU10MuDxrsS1.png"
)

PALETTE = [
    (0x0C, 0x10, 0x13),
    (0x2A, 0x3A, 0x40),
    (0xE4, 0xDC, 0xC8),
    (0xC9, 0x8A, 0x3C),
    (0x70, 0x46, 0x2C),
]

PROPS = [
    {
        "id": "juno_ledger_table",
        "name": "Juno ledger table",
        "crop": (0.00, 0.00, 0.50, 0.48),
        "target_height": 215,
        "position": (290, 560),
        "z": 4,
    },
    {
        "id": "bilge_regulator",
        "name": "Bilge regulator",
        "crop": (0.52, 0.00, 1.00, 0.50),
        "target_height": 320,
        "position": (860, 465),
        "z": 4,
    },
    {
        "id": "privacy_screen",
        "name": "Privacy screen",
        "crop": (0.00, 0.48, 0.50, 1.00),
        "target_height": 310,
        "position": (1335, 440),
        "z": 4,
    },
    {
        "id": "hot_pool_steps",
        "name": "Hot pool steps",
        "crop": (0.50, 0.50, 1.00, 1.00),
        "target_height": 235,
        "position": (1135, 665),
        "z": 5,
    },
]


def crop_relative(sheet: Image.Image, crop: tuple[float, float, float, float]) -> Image.Image:
    left = round(crop[0] * sheet.width)
    top = round(crop[1] * sheet.height)
    right = round(crop[2] * sheet.width)
    bottom = round(crop[3] * sheet.height)
    return sheet.crop((left, top, right, bottom))


def trim_alpha(image: Image.Image, margin: int = 8) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    return image.crop(
        (
            max(0, bbox[0] - margin),
            max(0, bbox[1] - margin),
            min(image.width, bbox[2] + margin),
            min(image.height, bbox[3] + margin),
        )
    )


def resize_to_height(image: Image.Image, target_height: int) -> Image.Image:
    if image.height == target_height:
        return image
    scale = target_height / image.height
    return image.resize((max(1, round(image.width * scale)), target_height), Image.Resampling.LANCZOS)


def nearest_palette_color(r: int, g: int, b: int) -> tuple[int, int, int]:
    return min(
        PALETTE,
        key=lambda color: (r - color[0]) ** 2 + (g - color[1]) ** 2 + (b - color[2]) ** 2,
    )


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
            pixels[x, y] = (nr, ng, nb, a)
    return rgba


def make_contact_sheet(entries: list[dict[str, object]]) -> Image.Image:
    thumb_w, thumb_h = 360, 240
    pad = 24
    label_h = 40
    columns = 2
    rows = 2
    canvas = Image.new(
        "RGB",
        (columns * thumb_w + (columns + 1) * pad, rows * (thumb_h + label_h) + (rows + 1) * pad),
        (12, 16, 19),
    )
    draw = ImageDraw.Draw(canvas)
    for index, entry in enumerate(entries):
        image = Image.open(ROOT / str(entry["game_resource"])).convert("RGBA")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        col = index % columns
        row = index // columns
        x = pad + col * (thumb_w + pad)
        y = pad + row * (thumb_h + label_h + pad)
        back = Image.new("RGBA", (thumb_w, thumb_h), (42, 58, 64, 255))
        back.alpha_composite(image, ((thumb_w - image.width) // 2, thumb_h - image.height))
        canvas.paste(back.convert("RGB"), (x, y))
        draw.text((x, y + thumb_h + 8), str(entry["name"]), fill=(228, 220, 200))
    return canvas


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing OpenAI Grey Float prop sheet: {SOURCE}")

    src_dir = ROOT / "art" / "src" / "props" / "grey_float" / "openai"
    export_dir = ROOT / "art" / "export" / "props" / "grey_float"
    game_dir = ROOT / "game" / "rooms" / "grey_float" / "props"
    review_dir = ROOT / "docs" / "art" / "review"
    for directory in (src_dir, export_dir, game_dir, review_dir):
        directory.mkdir(parents=True, exist_ok=True)

    source_copy = src_dir / "grey_float_props_openai_raw.png"
    shutil.copyfile(SOURCE, source_copy)
    sheet = Image.open(SOURCE).convert("RGBA")
    manifest: list[dict[str, object]] = []

    for prop in PROPS:
        cropped = crop_relative(sheet, prop["crop"])
        alpha = resize_to_height(trim_alpha(cropped), int(prop["target_height"]))
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
                "palette_locked": True,
                "alpha_cutout": True,
            }
        )

    contact_path = review_dir / "grey_float_openai_props_contact_sheet.png"
    make_contact_sheet(manifest).save(contact_path)

    json_path = ROOT / "docs" / "art" / "grey_float_openai_props.json"
    json_path.write_text(json.dumps({"props": manifest}, indent=2) + "\n", encoding="utf-8")

    md_lines = [
        "# Grey Float OpenAI Foreground Props",
        "",
        "Act I Grey Float foreground prop cutouts extracted from an OpenAI-generated source sheet, alpha-preserved, palette-locked, and staged for runtime use.",
        "",
        f"- Source sheet: `{source_copy.relative_to(ROOT).as_posix()}`",
        f"- Contact sheet: `{contact_path.relative_to(ROOT).as_posix()}`",
        "- Content line: hard-R, no explicit anatomy, no visible bodies, no child figures",
        "- Palette note: foreground props avoid absinthe green; the Float's trap warmth is amber.",
        "",
        "| Prop | Runtime PNG | Size | Position |",
        "|---|---|---:|---:|",
    ]
    for entry in manifest:
        md_lines.append(
            f"| {entry['name']} | `{entry['game_resource']}` | {entry['width']}x{entry['height']} | {entry['position']} |"
        )
    md_lines.append("")
    (ROOT / "docs" / "art" / "grey_float_openai_props.md").write_text("\n".join(md_lines), encoding="utf-8")

    print(f"Imported Grey Float OpenAI props: count={len(manifest)}, contact={contact_path}")


if __name__ == "__main__":
    main()
