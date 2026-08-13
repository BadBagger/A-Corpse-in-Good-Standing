from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
EXPORT_ROOT = ROOT / "art" / "export" / "atmosphere" / "act_i"
REVIEW_DIR = ROOT / "docs" / "art" / "review"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_atmosphere_setpieces.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_atmosphere_setpieces.md"

ATMOSPHERE = [
    {
        "id": "old_quay_water_glint",
        "room_code": "R02",
        "room_folder": "old_quay",
        "background": "game/rooms/old_quay/background/old_quay_bg.png",
        "x": 0,
        "y": 650,
        "width": 1920,
        "height": 310,
        "frames": 8,
        "fps": 6.0,
        "z": 2,
        "kind": "water_glint",
    },
    {
        "id": "salt_market_lamp_flicker",
        "room_code": "R03",
        "room_folder": "salt_market",
        "background": "game/rooms/salt_market/background/salt_market_bg.png",
        "x": 1210,
        "y": 210,
        "width": 540,
        "height": 500,
        "frames": 8,
        "fps": 7.0,
        "z": 3,
        "kind": "lamp_flicker",
    },
    {
        "id": "harbor_registry_lamp_smoke",
        "room_code": "R05",
        "room_folder": "harbor_registry",
        "background": "game/rooms/harbor_registry/background/harbor_registry_bg.png",
        "x": 700,
        "y": 300,
        "width": 520,
        "height": 430,
        "frames": 10,
        "fps": 8.0,
        "z": 3,
        "kind": "lamp_smoke",
    },
    {
        "id": "grey_float_steam_drift",
        "room_code": "R10",
        "room_folder": "grey_float",
        "background": "game/rooms/grey_float/background/grey_float_bg.png",
        "x": 120,
        "y": 330,
        "width": 1640,
        "height": 470,
        "frames": 10,
        "fps": 6.0,
        "z": 5,
        "kind": "steam_drift",
    },
    {
        "id": "sabine_office_window_rain",
        "room_code": "R12",
        "room_folder": "sabine_office",
        "background": "game/rooms/sabine_office/background/sabine_office_bg.png",
        "x": 900,
        "y": 90,
        "width": 650,
        "height": 470,
        "frames": 8,
        "fps": 6.0,
        "z": 3,
        "kind": "window_rain",
    },
]


WET_BLACK = (0x0C, 0x10, 0x13)
HARBOR_SLATE = (0x2A, 0x3A, 0x40)
BONE = (0xE4, 0xDC, 0xC8)
ABSINTHE = (0x7D, 0x9B, 0x4E)
AMBER = (0xC9, 0x8A, 0x3C)


def clamp(value: int) -> int:
    return max(0, min(255, value))


def transparent_blur_mask(size: tuple[int, int], margin: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (margin, margin, size[0] - margin - 1, size[1] - margin - 1),
        radius=max(16, margin * 2),
        fill=110,
    )
    mask = mask.filter(ImageFilter.GaussianBlur(max(10, margin)))
    pixels = mask.load()
    for y in range(size[1]):
        for x in range(size[0]):
            edge = min(x, y, size[0] - 1 - x, size[1] - 1 - y)
            if edge < 8:
                pixels[x, y] = 0
    return mask


def dithered_line_overlay(size: tuple[int, int], color: tuple[int, int, int], alpha: int, offset: int, spacing: int, angle: str) -> Image.Image:
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    width, height = size
    if angle == "vertical":
        for x in range(-height, width + height, spacing):
            draw.line((x + offset, 0, x + offset + height // 3, height), fill=(*color, alpha), width=2)
    else:
        for y in range(-width, height + width, spacing):
            draw.line((0, y + offset, width, y + offset - width // 4), fill=(*color, alpha), width=2)
    return overlay


def make_water_glint(region: Image.Image, index: int, frames: int) -> Image.Image:
    phase = (index / frames) * math.tau
    crop = region.filter(ImageFilter.GaussianBlur(1.8))
    crop = ImageEnhance.Contrast(crop).enhance(1.04)
    crop = ImageEnhance.Brightness(crop).enhance(0.72 + 0.025 * math.sin(phase))
    overlay = Image.new("RGBA", region.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    for y in range(28, region.height, 28):
        wobble = int(math.sin(phase + y * 0.035) * 28)
        draw.line((40 + wobble, y, region.width - 80 + wobble, y + 8), fill=(*BONE, 7), width=1)
        draw.line((0 - wobble, y + 13, region.width // 2 - wobble, y + 18), fill=(*AMBER, 5), width=1)
    frame = Image.alpha_composite(crop, overlay)
    frame.putalpha(transparent_blur_mask(region.size, 72))
    return frame


def make_lamp_flicker(region: Image.Image, index: int, frames: int) -> Image.Image:
    phase = (index / frames) * math.tau
    alpha = int(3 + 5 * (0.5 + 0.5 * math.sin(phase * 1.7)))
    overlay = Image.new("RGBA", region.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    draw.ellipse((155, 120, 450, 380), fill=(*AMBER, alpha))
    draw.ellipse((240, 195, 370, 295), fill=(*BONE, max(1, alpha // 6)))
    overlay = overlay.filter(ImageFilter.GaussianBlur(14))
    overlay.putalpha(transparent_blur_mask(region.size, 74))
    return overlay


def make_lamp_smoke(region: Image.Image, index: int, frames: int) -> Image.Image:
    phase = (index / frames) * math.tau
    overlay = Image.new("RGBA", region.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    for column in range(4):
        cx = 180 + column * 58 + int(math.sin(phase + column) * 16)
        top = 40 + column * 8
        draw.ellipse((cx - 28, top, cx + 58, top + 220), fill=(*ABSINTHE, 3))
        draw.ellipse((cx - 54, top + 90, cx + 72, top + 330), fill=(*HARBOR_SLATE, 4))
    draw.ellipse((130, 250, 420, 430), fill=(*AMBER, 2))
    overlay = overlay.filter(ImageFilter.GaussianBlur(24))
    overlay.putalpha(transparent_blur_mask(region.size, 76))
    return overlay


def make_steam_drift(region: Image.Image, index: int, frames: int) -> Image.Image:
    phase = (index / frames) * math.tau
    overlay = Image.new("RGBA", region.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    for band in range(7):
        y = 60 + band * 56
        x_shift = int(math.sin(phase + band * 0.7) * 44)
        draw.ellipse((160 + x_shift, y, 600 + x_shift, y + 170), fill=(*BONE, 3))
        draw.ellipse((720 - x_shift, y + 20, 1180 - x_shift, y + 180), fill=(*AMBER, 2))
        draw.ellipse((1120 + x_shift // 2, y - 10, 1580 + x_shift // 2, y + 150), fill=(*BONE, 2))
    overlay = overlay.filter(ImageFilter.GaussianBlur(34))
    overlay.putalpha(transparent_blur_mask(region.size, 96))
    return overlay


def make_window_rain(region: Image.Image, index: int, frames: int) -> Image.Image:
    phase = int((index / frames) * 40)
    overlay = Image.new("RGBA", region.size, (0, 0, 0, 0))
    rain = dithered_line_overlay(region.size, BONE, 14, phase, 46, "vertical")
    slate = dithered_line_overlay(region.size, HARBOR_SLATE, 16, -phase, 62, "vertical")
    overlay = Image.alpha_composite(overlay, slate)
    overlay = Image.alpha_composite(overlay, rain)
    draw = ImageDraw.Draw(overlay, "RGBA")
    draw.rectangle((0, region.height - 90, region.width, region.height), fill=(*HARBOR_SLATE, 8))
    overlay = overlay.filter(ImageFilter.GaussianBlur(1.2))
    overlay.putalpha(transparent_blur_mask(region.size, 74))
    return overlay


def make_frame(region: Image.Image, item: dict[str, object], index: int) -> Image.Image:
    kind = str(item["kind"])
    frames = int(item["frames"])
    if kind == "water_glint":
        return make_water_glint(region, index, frames)
    if kind == "lamp_flicker":
        return make_lamp_flicker(region, index, frames)
    if kind == "lamp_smoke":
        return make_lamp_smoke(region, index, frames)
    if kind == "steam_drift":
        return make_steam_drift(region, index, frames)
    if kind == "window_rain":
        return make_window_rain(region, index, frames)
    raise ValueError(f"Unknown atmosphere kind: {kind}")


def build_sheet(item: dict[str, object]) -> Image.Image:
    background = Image.open(ROOT / str(item["background"])).convert("RGBA")
    x = int(item["x"])
    y = int(item["y"])
    width = int(item["width"])
    height = int(item["height"])
    frames = int(item["frames"])
    region = background.crop((x, y, x + width, y + height))
    sheet = Image.new("RGBA", (width * frames, height), (0, 0, 0, 0))
    for index in range(frames):
        sheet.alpha_composite(make_frame(region, item, index), (index * width, 0))
    return sheet


def make_review(records: list[dict[str, object]]) -> Image.Image:
    thumb_w = 460
    thumb_h = 258
    pad = 24
    label_h = 40
    columns = 2
    rows = math.ceil(len(records) / columns)
    canvas = Image.new("RGB", (columns * thumb_w + (columns + 1) * pad, rows * (thumb_h + label_h) + (rows + 1) * pad), WET_BLACK)
    draw = ImageDraw.Draw(canvas)
    for index, record in enumerate(records):
        background = Image.open(ROOT / str(record["background"])).convert("RGBA")
        sheet = Image.open(ROOT / str(record["runtime_path"])).convert("RGBA")
        first = sheet.crop((0, 0, int(record["width"]), int(record["height"])))
        background.alpha_composite(first, (int(record["x"]), int(record["y"])))
        background.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = pad + (index % columns) * (thumb_w + pad)
        y = pad + (index // columns) * (thumb_h + label_h + pad)
        canvas.paste(background.convert("RGB"), (x, y))
        draw.text((x, y + thumb_h + 10), f"{record['room_code']} / {record['id']}", fill=BONE)
    return canvas


def main() -> None:
    EXPORT_ROOT.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, object]] = []
    for item in ATMOSPHERE:
        sheet = build_sheet(item)
        room_folder = str(item["room_folder"])
        runtime_dir = ROOT / "game" / "rooms" / room_folder / "atmosphere"
        export_dir = EXPORT_ROOT / room_folder
        runtime_dir.mkdir(parents=True, exist_ok=True)
        export_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{item['id']}.png"
        runtime_path = runtime_dir / filename
        export_path = export_dir / filename
        sheet.save(runtime_path, optimize=True)
        sheet.save(export_path, optimize=True)
        record = dict(item)
        record["runtime_path"] = runtime_path.relative_to(ROOT).as_posix()
        record["export_path"] = export_path.relative_to(ROOT).as_posix()
        record["sheet_width"] = int(item["width"]) * int(item["frames"])
        records.append(record)

    review_path = REVIEW_DIR / "act_i_atmosphere_setpieces_contact_sheet.png"
    make_review(records).save(review_path, optimize=True)

    REPORT_JSON.write_text(
        json.dumps(
            {
                "status": "exported",
                "count": len(records),
                "review": review_path.relative_to(ROOT).as_posix(),
                "setpieces": records,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    lines = [
        "# Act I Atmosphere Setpieces",
        "",
        "Generated by `tools/Build-ActIAtmosphereSetpieces.py` from the current OpenAI room plates.",
        "",
        "These are subtle transparent runtime overlays: water glint, lamp flicker, smoke, steam, and window rain. They add motion without changing puzzle coordinates or replacing final paintover sources.",
        "",
        f"- Review: `{review_path.relative_to(ROOT).as_posix()}`",
        "- Content line: hard-R, no explicit anatomy, no gore, no child figures",
        "",
        "| Room | Setpiece | Frames | FPS | Runtime sheet |",
        "|---|---|---:|---:|---|",
    ]
    for record in records:
        lines.append(
            f"| {record['room_code']} | {record['id']} | {record['frames']} | {record['fps']} | `{record['runtime_path']}` |"
        )
    lines.append("")
    REPORT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"atmosphere_setpieces={len(records)}")
    print(f"review={review_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
