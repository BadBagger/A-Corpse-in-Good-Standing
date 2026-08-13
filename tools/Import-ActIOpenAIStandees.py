from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

SHEETS = [
    {
        "id": "act_i_npc_standees_a",
        "source": Path(
            r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_WyEuVqeFJpNeBxPn6NwXpD58.png"
        ),
        "entries": [
            ("registrar", "The Registrar", 0, 0, 420),
            ("juno", "Juno Ash", 1, 0, 470),
            ("prosper", "Half-Coin Prosper", 0, 1, 360),
            ("tomas_bollard", "Bollard-of-Tomas", 1, 1, 400),
        ],
    },
    {
        "id": "act_i_npc_standees_b",
        "source": Path(
            r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_zZjE5WqpIBr8lMnpU4GDgZXl.png"
        ),
        "entries": [
            ("sabine", "Sabine Croix", 0, 0, 460),
            ("teodor", "Brother Teodor", 1, 0, 420),
            ("bone_chandler", "The Bone Chandler", 0, 1, 430),
            ("market_crowd", "Salt Market Crowd", 1, 1, 430),
        ],
    },
]

PALETTE = [
    (0x0C, 0x10, 0x13),
    (0x2A, 0x3A, 0x40),
    (0xE4, 0xDC, 0xC8),
    (0x7D, 0x9B, 0x4E),
    (0xC9, 0x8A, 0x3C),
    (0x8E, 0x1B, 0x22),
]


def is_key_pixel(r: int, g: int, b: int) -> bool:
    return g > 145 and g > r * 1.55 and g > b * 1.55


def remove_green_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if is_key_pixel(r, g, b):
                pixels[x, y] = (r, g, b, 0)
            elif g > 90 and g > r * 1.25 and g > b * 1.25:
                # Soft despill around antialiased edges.
                pixels[x, y] = (r, min(g, max(r, b) + 16), b, a)
    return rgba


def trim_alpha(image: Image.Image, margin: int = 10) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    left = max(0, bbox[0] - margin)
    top = max(0, bbox[1] - margin)
    right = min(image.width, bbox[2] + margin)
    bottom = min(image.height, bbox[3] + margin)
    return image.crop((left, top, right, bottom))


def keep_largest_alpha_component(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    width, height = rgba.size
    visited: set[tuple[int, int]] = set()
    best: list[tuple[int, int]] = []

    for y in range(height):
        for x in range(width):
            if (x, y) in visited or alpha.getpixel((x, y)) == 0:
                continue
            stack = [(x, y)]
            visited.add((x, y))
            component: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    if (nx, ny) in visited or alpha.getpixel((nx, ny)) == 0:
                        continue
                    visited.add((nx, ny))
                    stack.append((nx, ny))
            if len(component) > len(best):
                best = component

    if not best:
        return rgba

    keep = set(best)
    pixels = rgba.load()
    for y in range(height):
        for x in range(width):
            if alpha.getpixel((x, y)) > 0 and (x, y) not in keep:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return rgba


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


def palette_lock(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            nr, ng, nb = nearest_palette_color(r, g, b)
            pixels[x, y] = (nr, ng, nb, a)
    return rgba


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


def make_contact_sheet(entries: list[dict[str, object]]) -> Image.Image:
    thumb_w, thumb_h = 360, 300
    pad = 28
    label_h = 44
    columns = 4
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
    src_dir = ROOT / "art" / "src" / "standees" / "act_i" / "openai"
    export_dir = ROOT / "art" / "export" / "standees" / "act_i"
    game_dir = ROOT / "game" / "standees" / "act_i"
    review_dir = ROOT / "docs" / "art" / "review"
    src_dir.mkdir(parents=True, exist_ok=True)
    export_dir.mkdir(parents=True, exist_ok=True)
    game_dir.mkdir(parents=True, exist_ok=True)
    review_dir.mkdir(parents=True, exist_ok=True)

    manifest: list[dict[str, object]] = []

    for sheet_info in SHEETS:
        source = sheet_info["source"]
        if not source.exists():
            raise FileNotFoundError(f"Missing generated standee sheet: {source}")
        sheet_copy = src_dir / f"{sheet_info['id']}_openai_raw.png"
        shutil.copyfile(source, sheet_copy)
        sheet = Image.open(source).convert("RGBA")

        for slug, name, column, row, target_height in sheet_info["entries"]:
            raw = crop_cell(sheet, column, row)
            alpha = trim_alpha(keep_largest_alpha_component(remove_green_key(raw)))
            alpha = resize_to_height(alpha, target_height)
            locked = palette_lock(alpha)

            raw_path = export_dir / f"{slug}_raw.png"
            game_path = game_dir / f"{slug}.png"
            alpha.save(raw_path)
            locked.save(game_path)

            manifest.append(
                {
                    "id": slug,
                    "name": name,
                    "raw_export": raw_path.relative_to(ROOT).as_posix(),
                    "game_resource": game_path.relative_to(ROOT).as_posix(),
                    "source_sheet": sheet_copy.relative_to(ROOT).as_posix(),
                    "width": locked.width,
                    "height": locked.height,
                    "target_height": target_height,
                    "palette_locked": True,
                    "alpha_cutout": True,
                }
            )

    contact = make_contact_sheet(manifest)
    contact_path = review_dir / "act_i_openai_standees_contact_sheet.png"
    contact.save(contact_path)

    json_path = ROOT / "docs" / "art" / "act_i_openai_standees.json"
    json_path.write_text(json.dumps({"standees": manifest}, indent=2) + "\n", encoding="utf-8")

    md_lines = [
        "# Act I OpenAI Standees",
        "",
        "Eight OpenAI-generated in-world standees were cropped from two chroma-key sheets, alpha-matted, palette-locked, and staged for runtime use.",
        "",
        f"- Contact sheet: `{contact_path.relative_to(ROOT).as_posix()}`",
        "- Content line: hard-R, no explicit anatomy, no child figures",
        "",
        "| Standee | Runtime PNG | Size |",
        "|---|---|---|",
    ]
    for entry in manifest:
        md_lines.append(
            f"| {entry['name']} | `{entry['game_resource']}` | {entry['width']}x{entry['height']} |"
        )
    md_lines.append("")
    (ROOT / "docs" / "art" / "act_i_openai_standees.md").write_text(
        "\n".join(md_lines), encoding="utf-8"
    )

    print(f"Imported Act I OpenAI standees: count={len(manifest)}, contact={contact_path}")


if __name__ == "__main__":
    main()
