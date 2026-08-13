from __future__ import annotations

import json
import shutil
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_A4RrSEyqd0W20C883Ky4TmFP.png"
)
BOOTS_SOURCE = Path(
    r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_6SIoL0uIoe5PpOofGneEc7jG.png"
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
        "id": "tomas_bollard",
        "name": "Bollard-of-Tomas",
        "source_file": "game/standees/act_i/tomas_bollard.png",
        "target_height": 300,
        "foot_position": (390, 705),
        "z": 3,
    },
    {
        "id": "missing_boots",
        "name": "Missing boots",
        "external_source": str(BOOTS_SOURCE),
        "target_height": 155,
        "foot_position": (965, 910),
        "z": 5,
        "background_mode": "manual_polygon",
        "manual_polygon": [
            (0.05, 0.86),
            (0.12, 0.30),
            (0.27, 0.04),
            (0.62, 0.08),
            (0.90, 0.28),
            (0.98, 0.82),
            (0.83, 0.94),
            (0.18, 0.94),
        ],
        "foreground_rects": [
            (0.08, 0.20, 0.46, 0.80),
            (0.48, 0.10, 0.91, 0.82),
            (0.03, 0.65, 0.95, 0.94),
        ],
    },
    {
        "id": "brine_silt",
        "name": "Brine and silt",
        "cell": (1, 1),
        "target_height": 120,
        "foot_position": (1085, 945),
        "z": 2,
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


def extract_foreground(
    image: Image.Image,
    foreground_rects: list[tuple[float, float, float, float]] | None = None,
    background_mode: str = "grabcut",
    manual_polygon: list[tuple[float, float]] | None = None,
) -> Image.Image:
    if background_mode == "corner_dark":
        return extract_non_corner_background(image)
    if background_mode == "manual_polygon":
        return extract_manual_polygon(image, manual_polygon or [])

    rgb = image.convert("RGB")
    bgr = cv2.cvtColor(np.array(rgb), cv2.COLOR_RGB2BGR)
    height, width = bgr.shape[:2]
    mask = np.full((height, width), cv2.GC_PR_BGD, np.uint8)
    border = max(8, min(width, height) // 28)
    mask[:border, :] = cv2.GC_BGD
    mask[-border:, :] = cv2.GC_BGD
    mask[:, :border] = cv2.GC_BGD
    mask[:, -border:] = cv2.GC_BGD
    seed_rects = foreground_rects or [(0.08, 0.08, 0.92, 0.92)]
    for rect in seed_rects:
        left = max(0, min(width - 1, round(rect[0] * width)))
        top = max(0, min(height - 1, round(rect[1] * height)))
        right = max(left + 1, min(width, round(rect[2] * width)))
        bottom = max(top + 1, min(height, round(rect[3] * height)))
        mask[top:bottom, left:right] = cv2.GC_FGD
    bg_model = np.zeros((1, 65), np.float64)
    fg_model = np.zeros((1, 65), np.float64)
    cv2.grabCut(bgr, mask, None, bg_model, fg_model, 7, cv2.GC_INIT_WITH_MASK)
    foreground = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype("uint8")

    # Keep confident opaque artwork and smooth the mask enough for pixel-art scale.
    kernel = np.ones((3, 3), np.uint8)
    foreground = cv2.morphologyEx(foreground, cv2.MORPH_OPEN, kernel, iterations=1)
    foreground = cv2.morphologyEx(foreground, cv2.MORPH_CLOSE, kernel, iterations=2)
    foreground = cv2.GaussianBlur(foreground, (3, 3), 0)

    rgba = image.convert("RGBA")
    rgba.putalpha(Image.fromarray(foreground, mode="L"))
    return trim_alpha(rgba)


def extract_non_corner_background(image: Image.Image) -> Image.Image:
    rgb = np.array(image.convert("RGB")).astype(np.int16)
    height, width = rgb.shape[:2]
    sample = np.concatenate(
        [
            rgb[: max(6, height // 20), :].reshape(-1, 3),
            rgb[-max(6, height // 20) :, :].reshape(-1, 3),
            rgb[:, : max(6, width // 20)].reshape(-1, 3),
            rgb[:, -max(6, width // 20) :].reshape(-1, 3),
        ],
        axis=0,
    )
    background = np.median(sample, axis=0)
    distance = np.sqrt(np.sum((rgb - background) ** 2, axis=2))
    alpha = np.where(distance > 18, 255, 0).astype("uint8")
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8), iterations=1)
    alpha = cv2.GaussianBlur(alpha, (3, 3), 0)
    rgba = image.convert("RGBA")
    rgba.putalpha(Image.fromarray(alpha, mode="L"))
    return trim_alpha(rgba)


def extract_manual_polygon(image: Image.Image, polygon: list[tuple[float, float]]) -> Image.Image:
    rgba = image.convert("RGBA")
    mask = Image.new("L", rgba.size, 0)
    if not polygon:
        polygon = [(0.02, 0.12), (0.98, 0.12), (0.98, 0.92), (0.02, 0.92)]
    points = [(round(x * rgba.width), round(y * rgba.height)) for x, y in polygon]
    draw = ImageDraw.Draw(mask)
    draw.polygon(points, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(1.0))
    rgba.putalpha(mask)
    return trim_alpha(rgba)


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
    thumb_w, thumb_h = 360, 260
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
        raise FileNotFoundError(f"Missing OpenAI mudflats prop sheet: {SOURCE}")

    src_dir = ROOT / "art" / "src" / "props" / "mudflats" / "openai"
    export_dir = ROOT / "art" / "export" / "props" / "mudflats"
    game_dir = ROOT / "game" / "rooms" / "mudflats" / "props"
    review_dir = ROOT / "docs" / "art" / "review"
    for directory in (src_dir, export_dir, game_dir, review_dir):
        directory.mkdir(parents=True, exist_ok=True)

    source_copy = src_dir / "mudflats_props_openai_raw.png"
    shutil.copyfile(SOURCE, source_copy)
    sheet = Image.open(SOURCE).convert("RGBA")
    manifest: list[dict[str, object]] = []

    for prop in PROPS:
        source_file = prop.get("source_file")
        external_source = prop.get("external_source")
        if external_source:
            raw_source = Path(str(external_source))
            if not raw_source.exists():
                raise FileNotFoundError(f"Missing mudflats external source prop: {raw_source}")
            raw = Image.open(raw_source).convert("RGBA")
            alpha = resize_to_height(
                extract_foreground(
                    raw,
                    prop.get("foreground_rects"),
                    str(prop.get("background_mode", "grabcut")),
                    prop.get("manual_polygon"),
                ),
                int(prop["target_height"]),
            )
        elif source_file:
            raw_source = ROOT / str(source_file)
            if not raw_source.exists():
                raise FileNotFoundError(f"Missing mudflats source prop: {raw_source}")
            raw = Image.open(raw_source).convert("RGBA")
            alpha = resize_to_height(trim_alpha(raw), int(prop["target_height"]))
        else:
            column, row = prop["cell"]
            raw = crop_cell(sheet, column, row)
            alpha = resize_to_height(
                extract_foreground(
                    raw,
                    prop.get("foreground_rects"),
                    str(prop.get("background_mode", "grabcut")),
                    prop.get("manual_polygon"),
                ),
                int(prop["target_height"]),
            )
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
                "foot_position": prop["foot_position"],
                "z": prop["z"],
                "palette_locked": True,
                "alpha_cutout": True,
            }
        )

    contact_path = review_dir / "mudflats_openai_props_contact_sheet.png"
    make_contact_sheet(manifest).save(contact_path)

    json_path = ROOT / "docs" / "art" / "mudflats_openai_props.json"
    json_path.write_text(json.dumps({"props": manifest}, indent=2) + "\n", encoding="utf-8")

    md_lines = [
        "# Mudflats OpenAI Foreground Props",
        "",
        "Opening-room foreground prop cutouts extracted from an OpenAI-generated source sheet, alpha-matted, palette-locked, and staged for runtime use.",
        "",
        f"- Source sheet: `{source_copy.relative_to(ROOT).as_posix()}`",
        f"- Contact sheet: `{contact_path.relative_to(ROOT).as_posix()}`",
        "- Content line: hard-R, no explicit anatomy, no child figures",
        "",
        "| Prop | Runtime PNG | Size | Foot position |",
        "|---|---|---:|---:|",
    ]
    for entry in manifest:
        md_lines.append(
            f"| {entry['name']} | `{entry['game_resource']}` | {entry['width']}x{entry['height']} | {entry['foot_position']} |"
        )
    md_lines.append("")
    (ROOT / "docs" / "art" / "mudflats_openai_props.md").write_text("\n".join(md_lines), encoding="utf-8")

    print(f"Imported mudflats OpenAI props: count={len(manifest)}, contact={contact_path}")


if __name__ == "__main__":
    main()
