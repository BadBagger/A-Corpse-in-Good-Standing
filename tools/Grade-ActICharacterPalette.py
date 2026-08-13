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
BLACK = (12, 16, 19)

PERSON_SLATE_CAP_PERCENT = 34.0
SETPIECE_SLATE_CAP_PERCENT = 40.0

def clamp(value: float) -> int:
    return max(0, min(255, round(value)))


def color_distance(left: tuple[int, int, int], right: tuple[int, int, int]) -> float:
    return sum((left[index] - right[index]) ** 2 for index in range(3)) ** 0.5


def opaque_pixels(image: Image.Image) -> list[tuple[int, int, int, int]]:
    return [pixel for pixel in image.convert("RGBA").getdata() if pixel[3] > 32]


def green_cast_ratio(image: Image.Image) -> float:
    green = 0
    safe_palette = ((12, 16, 19), SLATE, AMBER, BONE)
    wrong_green = (125, 155, 78)
    pixels = opaque_pixels(image)
    for r, g, b, _a in pixels:
        h, s, v = rgb_to_hsv(r / 255, g / 255, b / 255)
        hue = h * 360.0
        pixel = (r, g, b)
        nearest_safe = min(color_distance(pixel, safe) for safe in safe_palette)
        nearest_green = color_distance(pixel, wrong_green)
        if 55.0 <= hue <= 180.0 and s > 0.045 and v > 0.035 and nearest_green < nearest_safe:
            green += 1
    return (green / max(1, len(pixels))) * 100.0


def green_dominance_ratio(image: Image.Image) -> float:
    green = 0
    pixels = opaque_pixels(image)
    for r, g, b, _a in pixels:
        h, s, v = rgb_to_hsv(r / 255, g / 255, b / 255)
        hue = h * 360.0
        if 55.0 <= hue <= 210.0 and s > 0.035 and v > 0.06 and g > (r * 1.06) and g > (b * 0.94):
            green += 1
    return (green / max(1, len(pixels))) * 100.0


def slate_proximity_ratio(image: Image.Image) -> float:
    pixels = opaque_pixels(image)
    slate_count = 0
    for r, g, b, _a in pixels:
        pixel = (r, g, b)
        nearest = min(
            (BLACK, SLATE, AMBER, BONE),
            key=lambda color: color_distance(pixel, color),
        )
        if nearest == SLATE:
            slate_count += 1
    return (slate_count / max(1, len(pixels))) * 100.0


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

    # Character clothes were drifting into the same blue-green mass as the room
    # shadows. Keep slate as a narrow outline/shadow language, but warm midtones
    # aggressively so people read as bodies inside the scene instead of green
    # background pieces.
    luminance = (r * 0.30) + (g * 0.52) + (b * 0.18)
    if color_distance((r, g, b), SLATE) < color_distance((r, g, b), BLACK) and luminance > 33:
        blend = 0.28 if luminance < 74 else 0.42
        r = clamp((r * (1.0 - blend)) + (AMBER[0] * blend))
        g = clamp((g * (1.0 - blend)) + (AMBER[1] * blend) - 14)
        b = clamp((b * (1.0 - blend)) + (AMBER[2] * blend) - 18)

    if g > r * 1.02 and g > b * 0.92 and luminance > 28:
        r = clamp(r + 10)
        g = clamp(g - 12)
        b = clamp(b - 8)

    # Transparent edges picked up green halos from generated cutouts. Warm them
    # slightly so subpixel fringes sit on amber/slate plates instead of glowing.
    if a < 190 and g > r and g >= b:
        r = clamp(r + 10)
        g = clamp(g - 8)
        b = clamp(b - 2)

    return r, g, b, a


def analyze_image(path: Path) -> dict[str, object]:
    image = Image.open(path).convert("RGBA")
    slate_percent = round(slate_proximity_ratio(image), 2)
    cap = SETPIECE_SLATE_CAP_PERCENT if "setpieces" in path.parts else PERSON_SLATE_CAP_PERCENT
    return {
        "asset": path.relative_to(ROOT).as_posix(),
        "width": image.width,
        "height": image.height,
        "wrong_light_green_percent": round(green_cast_ratio(image), 2),
        "green_dominance_percent": round(green_dominance_ratio(image), 2),
        "slate_proximity_percent": slate_percent,
        "slate_cap_percent": cap,
        "slate_cap_pass": slate_percent <= cap,
    }


def grade_image(path: Path) -> dict[str, object]:
    before = Image.open(path).convert("RGBA")
    before_ratio = green_cast_ratio(before)
    before_dominance = green_dominance_ratio(before)
    before_slate = slate_proximity_ratio(before)
    out = Image.new("RGBA", before.size, (0, 0, 0, 0))
    out.putdata([grade_pixel(*pixel) for pixel in before.getdata()])
    after_ratio = green_cast_ratio(out)
    after_dominance = green_dominance_ratio(out)
    after_slate = slate_proximity_ratio(out)
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
        "slate_proximity_percent_before": round(before_slate, 2),
        "slate_proximity_percent_after": round(after_slate, 2),
        "slate_proximity_delta": round(before_slate - after_slate, 2),
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
        "palette_rule": "Act I character overlays keep green reserved for wrong light; standee and crowd shadows are biased toward wet black and whale-oil amber. Slate is capped on character overlays so people do not collapse into the green-blue room shadow mass.",
        "person_slate_cap_percent": PERSON_SLATE_CAP_PERCENT,
        "setpiece_slate_cap_percent": SETPIECE_SLATE_CAP_PERCENT,
        "records": records,
        "current_assets": analysis_records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Act I Character Palette Grade",
        "",
        "Generated by `tools/Grade-ActICharacterPalette.py`.",
        "",
        "This pass audits whether Act I character standees and crowd setpieces drift toward forbidden absinthe wrong-light or too much slate/green-blue mass instead of wet black, bone, and whale-oil amber.",
        "",
        f"- Mode: `{'apply' if args.apply else 'audit'}`",
        f"- Person slate cap: {PERSON_SLATE_CAP_PERCENT}%",
        f"- Crowd/setpiece slate cap: {SETPIECE_SLATE_CAP_PERCENT}%",
    ]
    if records:
        lines.extend(
            [
                "",
                "| Asset | Wrong-light green before | Wrong-light green after | Green dominance before | Green dominance after | Slate proximity before | Slate proximity after |",
                "|---|---:|---:|---:|---:|---:|---:|",
            ]
        )
        for record in records:
            lines.append(
                f"| `{record['asset']}` | {record['wrong_light_green_percent_before']}% | "
                f"{record['wrong_light_green_percent_after']}% | "
                f"{record['green_dominance_percent_before']}% | "
                f"{record['green_dominance_percent_after']}% | "
                f"{record['slate_proximity_percent_before']}% | "
                f"{record['slate_proximity_percent_after']}% |"
            )
    lines.extend(
        [
            "",
            "## Current Assets",
            "",
            "| Asset | Wrong-light green | Broad green dominance | Slate proximity | Slate cap |",
            "|---|---:|---:|---:|---:|",
        ]
    )
    for record in analysis_records:
        lines.append(
            f"| `{record['asset']}` | {record['wrong_light_green_percent']}% | "
            f"{record['green_dominance_percent']}% | {record['slate_proximity_percent']}% | "
            f"{record['slate_cap_percent']}% |"
        )
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"mode={'apply' if args.apply else 'audit'}")
    print(f"graded_character_assets={len(records)}")
    print(f"audited_character_assets={len(analysis_records)}")
    print(f"report={REPORT_JSON.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
