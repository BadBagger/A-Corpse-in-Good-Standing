from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
EXPORT_DIR = ROOT / "art" / "export" / "characters" / "corvin" / "act_i_clean"
GAME_DIR = ROOT / "game" / "characters" / "corvin" / "sprites" / "act_i_clean"
REVIEW_DIR = ROOT / "docs" / "art" / "review"
REPORT_JSON = ROOT / "docs" / "art" / "corvin_act_i_palette_despill.json"
REPORT_MD = ROOT / "docs" / "art" / "corvin_act_i_palette_despill.md"

SHEETS = [
    "idle_side_left.png",
    "idle_side_right.png",
    "walk_side_left.png",
    "walk_side_right.png",
    "talk_side_left.png",
    "talk_side_right.png",
    "use_side_left.png",
    "use_side_right.png",
    "wet_side_left.png",
    "wet_side_right.png",
]

SLATE = (0x2A, 0x3A, 0x40)
WET_BLACK = (0x0C, 0x10, 0x13)
BONE = (0xE4, 0xDC, 0xC8)
AMBER = (0xC9, 0x8A, 0x3C)


def greenish_score(image: Image.Image) -> tuple[float, int, int]:
    rgba = image.convert("RGBA")
    opaque = 0
    greenish = 0
    for r, g, b, a in rgba.getdata():
        if a < 32:
            continue
        opaque += 1
        if g > r * 1.15 and g > b * 1.05 and g > 55:
            greenish += 1
    if opaque == 0:
        return 0.0, greenish, opaque
    return greenish / opaque * 100.0, greenish, opaque


def lerp(a: int, b: int, t: float) -> int:
    return round(a * (1.0 - t) + b * t)


def ramp_color(value: float) -> tuple[int, int, int]:
    if value < 0.62:
        t = max(0.0, min(1.0, value / 0.62))
        return (
            lerp(WET_BLACK[0], SLATE[0], t),
            lerp(WET_BLACK[1], SLATE[1], t),
            lerp(WET_BLACK[2], SLATE[2], t),
        )
    t = max(0.0, min(1.0, (value - 0.62) / 0.38))
    return (
        lerp(SLATE[0], BONE[0], t),
        lerp(SLATE[1], BONE[1], t),
        lerp(SLATE[2], BONE[2], t),
    )


def shift_green_cast(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if a < 12:
                pixels[x, y] = (0, 0, 0, 0)
                continue

            # Runtime Corvin must survive many room palettes. Keep luminance and
            # alpha, discard generated hue, and recolor through the locked noir ramp.
            value = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 255.0
            value = max(0.0, min(1.0, (value - 0.06) / 0.86))
            nr, ng, nb = ramp_color(value)
            pixels[x, y] = (nr, ng, nb, a)
    return rgba


def make_contact_sheet(rows: list[dict[str, object]]) -> None:
    sources = [GAME_DIR / str(row["sheet"]) for row in rows]
    thumb_w = 390
    thumb_h = 128
    label_w = 180
    pad = 18
    canvas = Image.new(
        "RGB",
        (label_w + thumb_w + pad * 3, len(sources) * (thumb_h + pad) + pad + 38),
        WET_BLACK,
    )
    draw = ImageDraw.Draw(canvas)
    draw.text((pad, 14), "Corvin Act I despilled runtime sheets", fill=BONE)
    y = pad + 38
    for row, path in zip(rows, sources):
        image = Image.open(path).convert("RGBA")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.NEAREST)
        draw.text((pad, y + 8), str(row["sheet"]).replace(".png", ""), fill=BONE)
        draw.text(
            (pad, y + 28),
            f"green {float(row['before_greenish_percent']):.1f}% -> {float(row['after_greenish_percent']):.1f}%",
            fill=AMBER,
        )
        back = Image.new("RGBA", (thumb_w, thumb_h), SLATE + (255,))
        back.alpha_composite(image, (0, max(0, thumb_h - image.height)))
        canvas.paste(back.convert("RGB"), (label_w + pad * 2, y))
        y += thumb_h + pad
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    canvas.save(REVIEW_DIR / "corvin_act_i_despill_contact_sheet.png")


def main() -> None:
    results: list[dict[str, object]] = []
    for sheet in SHEETS:
        export_path = EXPORT_DIR / sheet
        game_path = GAME_DIR / sheet
        if not export_path.exists():
            raise FileNotFoundError(f"Missing Corvin export sheet: {export_path}")
        if not game_path.exists():
            raise FileNotFoundError(f"Missing Corvin runtime sheet: {game_path}")

        source = Image.open(export_path).convert("RGBA")
        before_percent, before_count, opaque_count = greenish_score(source)
        fixed = shift_green_cast(source)
        after_percent, after_count, _ = greenish_score(fixed)
        fixed.save(export_path)
        fixed.save(game_path)
        results.append(
            {
                "sheet": sheet,
                "export_path": export_path.relative_to(ROOT).as_posix(),
                "game_path": game_path.relative_to(ROOT).as_posix(),
                "opaque_pixels": opaque_count,
                "before_greenish_pixels": before_count,
                "after_greenish_pixels": after_count,
                "before_greenish_percent": round(before_percent, 3),
                "after_greenish_percent": round(after_percent, 3),
            }
        )

    make_contact_sheet(results)
    REPORT_JSON.write_text(json.dumps({"status": "despilled", "sheets": results}, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Corvin Act I Palette Despill",
        "",
        "Corvin's runtime and export side sheets were shifted away from green-blue body tones toward harbor slate, wet black, bone, and amber so the protagonist fits the Act I room lighting.",
        "",
        "- Scope: Act I clean Corvin side idle, walk, talk, use, and wet sheets.",
        "- Runtime imports: `game/characters/corvin/sprites/act_i_clean`",
        "- Export source sheets: `art/export/characters/corvin/act_i_clean`",
        "- Review sheet: `docs/art/review/corvin_act_i_despill_contact_sheet.png`",
        "- Rule: green belongs to wrong-light set dressing, not Corvin's body or coat.",
        "",
        "| Sheet | Greenish before | Greenish after |",
        "|---|---:|---:|",
    ]
    for row in results:
        lines.append(
            f"| `{row['sheet']}` | {row['before_greenish_percent']}% | {row['after_greenish_percent']}% |"
        )
    lines.append("")
    REPORT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"Despilled Corvin Act I sheets: count={len(results)}")


if __name__ == "__main__":
    main()
