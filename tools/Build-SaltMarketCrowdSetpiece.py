from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "game" / "rooms" / "salt_market" / "background" / "salt_market_bg.png"
OUT_DIR = ROOT / "game" / "rooms" / "salt_market" / "setpieces"
EXPORT_DIR = ROOT / "art" / "export" / "setpieces" / "salt_market"
REVIEW_DIR = ROOT / "docs" / "art" / "review"
REPORT_JSON = ROOT / "docs" / "art" / "salt_market_crowd_setpiece.json"
REPORT_MD = ROOT / "docs" / "art" / "salt_market_crowd_setpiece.md"

REGION = {
    "x": 1070,
    "y": 455,
    "width": 520,
    "height": 330,
}

STATES = [
    ("idle_murmur", 8, 8),
    ("turn_to_corvin", 10, 10),
    ("settle", 6, 10),
]


def clamp(value: int) -> int:
    return max(0, min(255, value))


def neutralize_crowd_green(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if a <= 16:
                continue
            if g > r * 1.05 and g > b * 1.03 and g > 54:
                luminance = int(round((r * 0.30) + (g * 0.52) + (b * 0.18)))
                r = int(round((r * 0.48) + (luminance * 0.30) + 18))
                g = int(round((g * 0.50) + (luminance * 0.24)))
                b = int(round((b * 0.42) + (luminance * 0.20) + 4))
                pixels[x, y] = (clamp(r), clamp(g), clamp(b), a)
    return rgba


def make_frame(base: Image.Image, state: str, index: int, count: int) -> Image.Image:
    frame = base.copy()
    alpha = build_region_mask(frame.size)

    phase = index / max(1, count - 1)
    if state == "idle_murmur":
        delta = [-3, 1, 4, 0, -2, 2, 3, -1][index % 8]
        frame = ImageEnhance.Brightness(frame).enhance(1.0 + (delta * 0.012))
        overlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay, "RGBA")
        draw.ellipse((280, 120, 450, 300), fill=(201, 138, 60, 8 + max(0, delta) * 2))
        frame = Image.alpha_composite(frame, overlay)
    elif state == "turn_to_corvin":
        overlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay, "RGBA")
        amber = int(12 + 34 * phase)
        shade = int(36 * phase)
        draw.polygon([(0, 30), (220, 0), (210, 330), (0, 330)], fill=(12, 16, 19, shade))
        draw.ellipse((120, 58, 430, 320), fill=(201, 138, 60, amber))
        draw.line((125, 210, 390, 235), fill=(228, 220, 200, int(18 * phase)), width=3)
        frame = Image.alpha_composite(frame, overlay)
    elif state == "settle":
        frame = ImageEnhance.Brightness(frame).enhance(1.03 - (phase * 0.03))
        overlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay, "RGBA")
        draw.ellipse((180, 90, 420, 310), fill=(201, 138, 60, int(22 * (1.0 - phase))))
        frame = Image.alpha_composite(frame, overlay)

    frame = neutralize_crowd_green(frame)
    frame.putalpha(alpha)
    return frame


def build_region_mask(size: tuple[int, int]) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    # Soft-ish hand-authored coverage around the crowd and booth area. The sheet
    # must not be an opaque rectangle over the room plate.
    draw.ellipse((34, 72, 270, 318), fill=150)
    draw.ellipse((160, 56, 436, 320), fill=170)
    draw.ellipse((332, 72, 520, 300), fill=120)
    draw.rectangle((110, 112, 500, 292), fill=145)
    draw.rectangle((312, 28, 506, 150), fill=80)
    return mask.filter(ImageFilter.GaussianBlur(14))


def build_sheet(background: Image.Image, state: str, frames: int) -> Image.Image:
    x = REGION["x"]
    y = REGION["y"]
    width = REGION["width"]
    height = REGION["height"]
    base = background.crop((x, y, x + width, y + height)).convert("RGBA")
    sheet = Image.new("RGBA", (width * frames, height), (0, 0, 0, 0))
    for index in range(frames):
        sheet.alpha_composite(make_frame(base, state, index, frames), (index * width, 0))
    return sheet


def make_review(background: Image.Image, sheets: dict[str, Image.Image]) -> Image.Image:
    panel_w = 640
    panel_h = 360
    label_h = 34
    rows = len(STATES)
    review = Image.new("RGB", (panel_w * 2, rows * (panel_h + label_h)), (12, 16, 19))
    draw = ImageDraw.Draw(review)
    for row, (state, frames, _fps) in enumerate(STATES):
        y = row * (panel_h + label_h)
        source = background.copy().convert("RGBA")
        first = sheets[state].crop((0, 0, REGION["width"], REGION["height"]))
        source.alpha_composite(first, (REGION["x"], REGION["y"]))
        source.thumbnail((panel_w, panel_h), Image.Resampling.LANCZOS)
        review.paste(source.convert("RGB"), (0, y))

        strip = sheets[state].copy()
        strip.thumbnail((panel_w, panel_h), Image.Resampling.LANCZOS)
        review.paste(strip.convert("RGB"), (panel_w, y))
        draw.rectangle((0, y + panel_h, panel_w * 2, y + panel_h + label_h), fill=(42, 58, 64))
        draw.text((12, y + panel_h + 10), f"{state}: {frames} frames", fill=(228, 220, 200))
    return review


def main() -> None:
    background = Image.open(BACKGROUND).convert("RGBA")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)

    records = []
    sheets: dict[str, Image.Image] = {}
    for state, frames, fps in STATES:
        sheet = build_sheet(background, state, frames)
        sheets[state] = sheet
        runtime_path = OUT_DIR / f"salt_market_crowd_{state}.png"
        export_path = EXPORT_DIR / f"salt_market_crowd_{state}.png"
        sheet.save(runtime_path, optimize=True)
        sheet.save(export_path, optimize=True)
        records.append(
            {
                "state": state,
                "frames": frames,
                "fps": fps,
                "runtime_path": str(runtime_path.relative_to(ROOT)).replace("\\", "/"),
                "export_path": str(export_path.relative_to(ROOT)).replace("\\", "/"),
                "width": REGION["width"],
                "height": REGION["height"],
                "sheet_width": REGION["width"] * frames,
            }
        )

    review = make_review(background, sheets)
    review_path = REVIEW_DIR / "salt_market_crowd_setpiece_review.png"
    review.save(review_path, optimize=True)

    report = {
        "id": "salt_market_crowd",
        "source_background": str(BACKGROUND.relative_to(ROOT)).replace("\\", "/"),
        "bounds": REGION,
        "anchor": {"x": REGION["x"], "y": REGION["y"]},
        "z_index": 4,
        "trigger": {"room_code": "R03", "hotspot": "MarketCrowd", "verb": "talk"},
        "review": str(review_path.relative_to(ROOT)).replace("\\", "/"),
        "states": records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Salt Market Crowd Setpiece",
        "",
        "Sectional animated overlay generated from the integrated Salt Market room plate.",
        "",
        f"- Review: `{report['review']}`",
        f"- Bounds: x={REGION['x']} y={REGION['y']} w={REGION['width']} h={REGION['height']}",
        "- Runtime trigger: `MarketCrowd` talk/use interaction",
        "",
        "| State | Frames | FPS | Runtime sheet |",
        "|---|---:|---:|---|",
    ]
    for record in records:
        lines.append(f"| {record['state']} | {record['frames']} | {record['fps']} | `{record['runtime_path']}` |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"setpiece=salt_market_crowd")
    print(f"review={review_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
