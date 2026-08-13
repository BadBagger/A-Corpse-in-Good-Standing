from __future__ import annotations

import json
import shutil
from pathlib import Path

from collections import deque

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_AV2tJ8FuFmGimLGDANppnWjg.png"
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
        "id": "ice_table_body_outline",
        "name": "Ice table body outline",
        "crop": (0.00, 0.00, 0.60, 0.52),
        "target_height": 265,
        "position": (330, 565),
        "z": 4,
    },
    {
        "id": "coroner_tag_tray",
        "name": "Coroner tag tray",
        "crop": (0.60, 0.02, 1.00, 0.34),
        "target_height": 120,
        "position": (900, 645),
        "z": 5,
    },
    {
        "id": "visitor_book",
        "name": "Visitor book",
        "crop": (0.56, 0.34, 1.00, 0.66),
        "target_height": 165,
        "position": (1110, 610),
        "z": 5,
    },
    {
        "id": "day_count_board",
        "name": "Day-count evidence board",
        "crop": (0.00, 0.58, 0.56, 1.00),
        "target_height": 210,
        "position": (1350, 510),
        "z": 4,
    },
    {
        "id": "floor_drain_grate",
        "name": "Floor drain grate",
        "crop": (0.58, 0.66, 1.00, 1.00),
        "target_height": 155,
        "position": (1410, 725),
        "z": 5,
    },
]


def crop_relative(sheet: Image.Image, crop: tuple[float, float, float, float]) -> Image.Image:
    left = round(crop[0] * sheet.width)
    top = round(crop[1] * sheet.height)
    right = round(crop[2] * sheet.width)
    bottom = round(crop[3] * sheet.height)
    return sheet.crop((left, top, right, bottom))


def trim_alpha_or_background(image: Image.Image, margin: int = 8) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()

    # Generated sheets often arrive on a subtle studio gradient rather than true
    # alpha. Flood-fill from the crop edges so only connected background falls out;
    # interior dark ink and slate prop details survive.
    visited: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()
    for x in range(rgba.width):
        queue.append((x, 0))
        queue.append((x, rgba.height - 1))
    for y in range(rgba.height):
        queue.append((0, y))
        queue.append((rgba.width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or x < 0 or y < 0 or x >= rgba.width or y >= rgba.height:
            continue
        r, g, b, a = pixels[x, y]
        # Smooth source-sheet backgrounds are low-detail grey/brown fields.
        # Prop edges are higher contrast, brighter, or darker than this band.
        if not (28 <= r <= 105 and 26 <= g <= 100 and 22 <= b <= 92 and abs(r - g) < 38 and abs(g - b) < 42):
            continue
        visited.add((x, y))
        pixels[x, y] = (r, g, b, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))

    alpha = rgba.getchannel("A").filter(ImageFilter.MinFilter(3))
    rgba.putalpha(alpha)
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        return rgba
    return rgba.crop(
        (
            max(0, bbox[0] - margin),
            max(0, bbox[1] - margin),
            min(rgba.width, bbox[2] + margin),
            min(rgba.height, bbox[3] + margin),
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
            if a < 16:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            nr, ng, nb = nearest_palette_color(r, g, b)
            pixels[x, y] = (nr, ng, nb, a)
    return rgba


def make_contact_sheet(entries: list[dict[str, object]]) -> Image.Image:
    thumb_w, thumb_h = 340, 220
    pad = 22
    label_h = 38
    columns = 3
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
        raise FileNotFoundError(f"Missing OpenAI Fish Hall prop sheet: {SOURCE}")

    src_dir = ROOT / "art" / "src" / "props" / "fish_hall" / "openai"
    export_dir = ROOT / "art" / "export" / "props" / "fish_hall"
    game_dir = ROOT / "game" / "rooms" / "fish_hall" / "props"
    review_dir = ROOT / "docs" / "art" / "review"
    for directory in (src_dir, export_dir, game_dir, review_dir):
        directory.mkdir(parents=True, exist_ok=True)

    source_copy = src_dir / "fish_hall_props_openai_raw.png"
    shutil.copyfile(SOURCE, source_copy)
    sheet = Image.open(SOURCE).convert("RGBA")
    manifest: list[dict[str, object]] = []

    for prop in PROPS:
        cropped = crop_relative(sheet, prop["crop"])
        alpha = resize_to_height(trim_alpha_or_background(cropped), int(prop["target_height"]))
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

    contact_path = review_dir / "fish_hall_openai_props_contact_sheet.png"
    make_contact_sheet(manifest).save(contact_path)

    json_path = ROOT / "docs" / "art" / "fish_hall_openai_props.json"
    json_path.write_text(json.dumps({"props": manifest}, indent=2) + "\n", encoding="utf-8")

    md_lines = [
        "# Fish Hall OpenAI Foreground Props",
        "",
        "Act I Fish Hall foreground prop cutouts extracted from an OpenAI-generated source sheet, alpha-preserved, palette-locked, and staged for runtime use.",
        "",
        f"- Source sheet: `{source_copy.relative_to(ROOT).as_posix()}`",
        f"- Contact sheet: `{contact_path.relative_to(ROOT).as_posix()}`",
        "- Content line: hard-R, no explicit anatomy, no gore, no bodies, no child figures",
        "- Palette note: avoid absinthe green and arterial red; foreground objects grade to slate, bone, and amber.",
        "",
        "| Prop | Runtime PNG | Size | Position |",
        "|---|---|---:|---:|",
    ]
    for entry in manifest:
        md_lines.append(
            f"| {entry['name']} | `{entry['game_resource']}` | {entry['width']}x{entry['height']} | {entry['position']} |"
        )
    md_lines.append("")
    (ROOT / "docs" / "art" / "fish_hall_openai_props.md").write_text("\n".join(md_lines), encoding="utf-8")

    print(f"Imported Fish Hall OpenAI props: count={len(manifest)}, contact={contact_path}")


if __name__ == "__main__":
    main()
