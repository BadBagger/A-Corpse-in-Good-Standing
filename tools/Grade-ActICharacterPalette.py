from __future__ import annotations

import json
import argparse
from colorsys import rgb_to_hsv
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
STANDEE_DIR = ROOT / "game" / "standees" / "act_i"
SETPIECE_DIRS = [
    ROOT / "game" / "rooms" / "salt_market" / "setpieces",
]
REPORT_JSON = ROOT / "docs" / "art" / "act_i_character_palette_grade.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_character_palette_grade.md"

SLATE = (42, 58, 64)
AMBER = (201, 138, 60)
BONE = (228, 220, 200)

def clamp(value: float) -> int:
    return max(0, min(255, round(value)))


def color_distance(left: tuple[int, int, int], right: tuple[int, int, int]) -> float:
    return sum((left[index] - right[index]) ** 2 for index in range(3)) ** 0.5


def green_cast_ratio(image: Image.Image) -> float:
    total = 0
    green = 0
    safe_palette = ((12, 16, 19), SLATE, AMBER, BONE)
    wrong_green = (125, 155, 78)
    for r, g, b, a in image.convert("RGBA").getdata():
        if a <= 8:
            continue
        total += 1
        h, s, v = rgb_to_hsv(r / 255, g / 255, b / 255)
        hue = h * 360.0
        pixel = (r, g, b)
        nearest_safe = min(color_distance(pixel, safe) for safe in safe_palette)
        nearest_green = color_distance(pixel, wrong_green)
        if 55.0 <= hue <= 180.0 and s > 0.045 and v > 0.035 and nearest_green < nearest_safe:
            green += 1
    return (green / max(1, total)) * 100.0


def green_dominance_ratio(image: Image.Image) -> float:
    total = 0
    green = 0
    for r, g, b, a in image.convert("RGBA").getdata():
        if a <= 32:
            continue
        total += 1
        h, s, v = rgb_to_hsv(r / 255, g / 255, b / 255)
        hue = h * 360.0
        if 55.0 <= hue <= 210.0 and s > 0.035 and v > 0.06 and g > (r * 1.06) and g > (b * 0.94):
            green += 1
    return (green / max(1, total)) * 100.0


def grade_pixel(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
    if a <= 8:
        return r, g, b, a

    h, s, v = rgb_to_hsv(r / 255, g / 255, b / 255)
    hue = h * 360.0
    luminance = (r * 0.30) + (g * 0.52) + (b * 0.18)

    if 55.0 <= hue <= 210.0 and s > 0.035 and g > (r * 1.03) and g > (b * 0.90):
        if luminance >= 150:
            target = (
                (BONE[0] * 0.70) + (AMBER[0] * 0.30),
                (BONE[1] * 0.70) + (AMBER[1] * 0.30),
                (BONE[2] * 0.70) + (AMBER[2] * 0.30),
            )
            blend = 0.58
        elif luminance >= 104:
            target = (
                (AMBER[0] * 0.72) + (BONE[0] * 0.28),
                (AMBER[1] * 0.72) + (BONE[1] * 0.28),
                (AMBER[2] * 0.72) + (BONE[2] * 0.28),
            )
            blend = 0.62
        elif luminance >= 74:
            target = (
                (SLATE[0] * 0.68) + (AMBER[0] * 0.32),
                (SLATE[1] * 0.68) + (AMBER[1] * 0.32),
                (SLATE[2] * 0.68) + (AMBER[2] * 0.32),
            )
            blend = 0.70
        else:
            target = SLATE
            blend = 0.76
        r = clamp((r * (1.0 - blend)) + (target[0] * blend))
        g = clamp((g * (1.0 - blend)) + (target[1] * blend) - 18)
        b = clamp((b * (1.0 - blend)) + (target[2] * blend))
    elif 170.0 < hue <= 215.0 and s > 0.12:
        target = SLATE
        blend = 0.20
        r = clamp((r * (1.0 - blend)) + (target[0] * blend))
        g = clamp((g * (1.0 - blend)) + (target[1] * blend))
        b = clamp((b * (1.0 - blend)) + (target[2] * blend))

    # Transparent edges picked up green halos from generated cutouts. Warm them
    # slightly so subpixel fringes sit on amber/slate plates instead of glowing.
    if a < 190 and g > r and g >= b:
        r = clamp(r + 10)
        g = clamp(g - 8)
        b = clamp(b - 2)

    return r, g, b, a


def analyze_image(path: Path) -> dict[str, object]:
    image = Image.open(path).convert("RGBA")
    return {
        "asset": path.relative_to(ROOT).as_posix(),
        "width": image.width,
        "height": image.height,
        "wrong_light_green_percent": round(green_cast_ratio(image), 2),
        "green_dominance_percent": round(green_dominance_ratio(image), 2),
    }


def grade_image(path: Path) -> dict[str, object]:
    before = Image.open(path).convert("RGBA")
    before_ratio = green_cast_ratio(before)
    before_dominance = green_dominance_ratio(before)
    out = Image.new("RGBA", before.size, (0, 0, 0, 0))
    out.putdata([grade_pixel(*pixel) for pixel in before.getdata()])
    after_ratio = green_cast_ratio(out)
    after_dominance = green_dominance_ratio(out)
    out.save(path, optimize=True)
    return {
        "asset": path.relative_to(ROOT).as_posix(),
        "width": before.width,
        "height": before.height,
        "wrong_light_green_percent_before": round(before_ratio, 2),
        "wrong_light_green_percent_after": round(after_ratio, 2),
        "wrong_light_green_delta": round(before_ratio - after_ratio, 2),
        "green_dominance_percent_before": round(before_dominance, 2),
        "green_dominance_percent_after": round(after_dominance, 2),
        "green_dominance_delta": round(before_dominance - after_dominance, 2),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Audit or apply the Act I character palette grade.")
    parser.add_argument("--apply", action="store_true", help="Rewrite Act I character PNGs with the palette grade.")
    args = parser.parse_args()

    source_paths = sorted(STANDEE_DIR.glob("*.png"))
    for directory in SETPIECE_DIRS:
        source_paths.extend(sorted(directory.glob("*.png")))
    records = [grade_image(path) for path in source_paths] if args.apply else []
    analysis_records = [analyze_image(path) for path in source_paths]
    report = {
        "status": "graded" if args.apply else "audited",
        "asset_count": len(records),
        "current_asset_count": len(analysis_records),
        "palette_rule": "Act I character overlays keep green reserved for wrong light; standee and crowd shadows are biased toward harbor slate and whale-oil amber. Broad green dominance is audited separately from exact absinthe-palette proximity.",
        "records": records,
        "current_assets": analysis_records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Act I Character Palette Grade",
        "",
        "Generated by `tools/Grade-ActICharacterPalette.py`.",
        "",
        "This pass audits whether Act I character standees and crowd setpieces drift toward forbidden absinthe wrong-light instead of wet black, harbor slate, bone, or whale-oil amber.",
        "",
        f"- Mode: `{'apply' if args.apply else 'audit'}`",
    ]
    if records:
        lines.extend(
            [
                "",
                "| Asset | Wrong-light green before | Wrong-light green after | Green dominance before | Green dominance after |",
                "|---|---:|---:|---:|---:|",
            ]
        )
        for record in records:
            lines.append(
                f"| `{record['asset']}` | {record['wrong_light_green_percent_before']}% | "
                f"{record['wrong_light_green_percent_after']}% | "
                f"{record['green_dominance_percent_before']}% | "
                f"{record['green_dominance_percent_after']}% |"
            )
    lines.extend(
        [
            "",
            "## Current Assets",
            "",
            "| Asset | Wrong-light green | Broad green dominance |",
            "|---|---:|---:|",
        ]
    )
    for record in analysis_records:
        lines.append(f"| `{record['asset']}` | {record['wrong_light_green_percent']}% | {record['green_dominance_percent']}% |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"mode={'apply' if args.apply else 'audit'}")
    print(f"graded_character_assets={len(records)}")
    print(f"audited_character_assets={len(analysis_records)}")
    print(f"report={REPORT_JSON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
