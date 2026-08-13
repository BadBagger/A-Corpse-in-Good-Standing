from __future__ import annotations

import json
import shutil
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(
    r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_WVecTVQ6rwKhQfzlnhzIfYNF.png"
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
        "id": "boot_stall",
        "name": "Boot stall",
        "crop": (0.00, 0.00, 0.42, 0.54),
        "target_height": 260,
        "position": (92, 548),
        "z": 3,
        "foreground_rects": [(0.04, 0.08, 0.96, 0.91)],
    },
    {
        "id": "church_sign",
        "name": "Church sign",
        "crop": (0.39, 0.00, 0.62, 0.55),
        "target_height": 220,
        "position": (1295, 405),
        "z": 4,
        "foreground_rects": [(0.12, 0.03, 0.88, 0.94)],
    },
    {
        "id": "confession_queue",
        "name": "Confession queue",
        "crop": (0.60, 0.00, 1.00, 0.56),
        "target_height": 260,
        "position": (1165, 500),
        "z": 4,
        "foreground_rects": [(0.03, 0.08, 0.98, 0.93)],
    },
    {
        "id": "fishmonger",
        "name": "Fishmonger",
        "crop": (0.00, 0.49, 0.46, 1.00),
        "target_height": 210,
        "position": (430, 625),
        "z": 4,
        "foreground_rects": [(0.03, 0.03, 0.97, 0.92)],
    },
    {
        "id": "market_crowd_dressing",
        "name": "Market crowd dressing",
        "crop": (0.45, 0.50, 1.00, 1.00),
        "target_height": 245,
        "position": (760, 545),
        "z": 3,
        "foreground_rects": [(0.03, 0.08, 0.98, 0.94)],
    },
]


def crop_relative(sheet: Image.Image, crop: tuple[float, float, float, float]) -> Image.Image:
    left = round(crop[0] * sheet.width)
    top = round(crop[1] * sheet.height)
    right = round(crop[2] * sheet.width)
    bottom = round(crop[3] * sheet.height)
    return sheet.crop((left, top, right, bottom))


def extract_foreground(image: Image.Image, foreground_rects: list[tuple[float, float, float, float]]) -> Image.Image:
    rgb = image.convert("RGB")
    bgr = cv2.cvtColor(np.array(rgb), cv2.COLOR_RGB2BGR)
    height, width = bgr.shape[:2]
    mask = np.full((height, width), cv2.GC_PR_BGD, np.uint8)
    border = max(6, min(width, height) // 32)
    mask[:border, :] = cv2.GC_BGD
    mask[-border:, :] = cv2.GC_BGD
    mask[:, :border] = cv2.GC_BGD
    mask[:, -border:] = cv2.GC_BGD
    for rect in foreground_rects:
        left = max(0, min(width - 1, round(rect[0] * width)))
        top = max(0, min(height - 1, round(rect[1] * height)))
        right = max(left + 1, min(width, round(rect[2] * width)))
        bottom = max(top + 1, min(height, round(rect[3] * height)))
        mask[top:bottom, left:right] = cv2.GC_PR_FGD

    bg_model = np.zeros((1, 65), np.float64)
    fg_model = np.zeros((1, 65), np.float64)
    cv2.grabCut(bgr, mask, None, bg_model, fg_model, 6, cv2.GC_INIT_WITH_MASK)
    alpha = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype("uint8")
    alpha = cv2.morphologyEx(alpha, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8), iterations=1)
    alpha = cv2.GaussianBlur(alpha, (3, 3), 0)

    rgba = image.convert("RGBA")
    rgba.putalpha(Image.fromarray(alpha, mode="L"))
    return trim_alpha(remove_small_alpha_components(rgba))


def remove_small_alpha_components(image: Image.Image, min_fraction: float = 0.012) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = np.array(rgba.getchannel("A"))
    _, labels, stats, _ = cv2.connectedComponentsWithStats((alpha > 0).astype("uint8"), 8)
    min_area = max(18, int(alpha.shape[0] * alpha.shape[1] * min_fraction))
    keep = np.zeros(alpha.shape, dtype="uint8")
    for label in range(1, stats.shape[0]):
        if stats[label, cv2.CC_STAT_AREA] >= min_area:
            keep[labels == label] = 255
    cleaned = cv2.GaussianBlur(keep, (3, 3), 0)
    rgba.putalpha(Image.fromarray(cleaned, mode="L"))
    return rgba


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
    thumb_w, thumb_h = 340, 220
    pad = 24
    label_h = 40
    columns = 3
    rows = 2
    canvas = Image.new("RGB", (columns * thumb_w + (columns + 1) * pad, rows * (thumb_h + label_h) + (rows + 1) * pad), (12, 16, 19))
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
        raise FileNotFoundError(f"Missing OpenAI Salt Market prop sheet: {SOURCE}")

    src_dir = ROOT / "art" / "src" / "props" / "salt_market" / "openai"
    export_dir = ROOT / "art" / "export" / "props" / "salt_market"
    game_dir = ROOT / "game" / "rooms" / "salt_market" / "props"
    review_dir = ROOT / "docs" / "art" / "review"
    for directory in (src_dir, export_dir, game_dir, review_dir):
        directory.mkdir(parents=True, exist_ok=True)

    source_copy = src_dir / "salt_market_props_openai_raw.png"
    shutil.copyfile(SOURCE, source_copy)
    sheet = Image.open(SOURCE).convert("RGBA")
    manifest: list[dict[str, object]] = []

    for prop in PROPS:
        raw = crop_relative(sheet, prop["crop"])
        alpha = resize_to_height(extract_foreground(raw, prop["foreground_rects"]), int(prop["target_height"]))
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

    contact_path = review_dir / "salt_market_openai_props_contact_sheet.png"
    make_contact_sheet(manifest).save(contact_path)

    json_path = ROOT / "docs" / "art" / "salt_market_openai_props.json"
    json_path.write_text(json.dumps({"props": manifest}, indent=2) + "\n", encoding="utf-8")

    md_lines = [
        "# Salt Market OpenAI Foreground Props",
        "",
        "Hub-room foreground prop cutouts extracted from an OpenAI-generated source sheet, alpha-matted, palette-locked, and staged for runtime use.",
        "",
        f"- Source sheet: `{source_copy.relative_to(ROOT).as_posix()}`",
        f"- Contact sheet: `{contact_path.relative_to(ROOT).as_posix()}`",
        "- Content line: hard-R, no explicit anatomy, adult figures only, no child figures",
        "",
        "| Prop | Runtime PNG | Size | Position |",
        "|---|---|---:|---:|",
    ]
    for entry in manifest:
        md_lines.append(
            f"| {entry['name']} | `{entry['game_resource']}` | {entry['width']}x{entry['height']} | {entry['position']} |"
        )
    md_lines.append("")
    (ROOT / "docs" / "art" / "salt_market_openai_props.md").write_text("\n".join(md_lines), encoding="utf-8")

    print(f"Imported Salt Market OpenAI props: count={len(manifest)}, contact={contact_path}")


if __name__ == "__main__":
    main()
