from __future__ import annotations

import json
from colorsys import rgb_to_hsv
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
REPORT_JSON = ROOT / "docs" / "art" / "salt_market_green_spill_grade.json"
REPORT_MD = ROOT / "docs" / "art" / "salt_market_green_spill_grade.md"

BLACK = (12, 16, 19)
SLATE = (42, 58, 64)
AMBER = (201, 138, 60)
BONE = (228, 220, 200)


TARGETS = [
    {
        "id": "salt_market_bg",
        "path": "game/rooms/salt_market/background/salt_market_bg.png",
        "regions": [(0, 330, 1550, 890), (0, 620, 1920, 990)],
        "note": "market, crowd, cloth, and wet street band; sky and distant Church glow are intentionally left mostly alone",
    },
    {
        "id": "boot_stall",
        "path": "game/rooms/salt_market/props/boot_stall.png",
        "regions": None,
        "note": "foreground stall cloth and wares",
    },
    {
        "id": "fishmonger",
        "path": "game/rooms/salt_market/props/fishmonger.png",
        "regions": None,
        "note": "foreground vendor and table",
    },
    {
        "id": "market_crowd_dressing",
        "path": "game/rooms/salt_market/props/market_crowd_dressing.png",
        "regions": None,
        "note": "foreground crowd dressing",
    },
    {
        "id": "confession_queue",
        "path": "game/rooms/salt_market/props/confession_queue.png",
        "regions": None,
        "note": "queue figures; Church sign/glow remains the allowed green source",
    },
]


def clamp(value: float) -> int:
    return max(0, min(255, round(value)))


def in_regions(x: int, y: int, regions: list[tuple[int, int, int, int]] | None) -> bool:
    if regions is None:
        return True
    return any(left <= x < right and top <= y < bottom for left, top, right, bottom in regions)


def is_green_spill(r: int, g: int, b: int, a: int) -> bool:
    if a <= 24:
        return False
    h, s, v = rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
    hue = h * 360.0
    return 58.0 <= hue <= 185.0 and s > 0.045 and v > 0.055 and g > r * 1.03 and g > b * 0.86


def grade_pixel(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
    if not is_green_spill(r, g, b, a):
        return r, g, b, a

    luminance = (r * 0.30) + (g * 0.52) + (b * 0.18)
    if luminance >= 150:
        target = (
            BONE[0] * 0.62 + AMBER[0] * 0.38,
            BONE[1] * 0.62 + AMBER[1] * 0.38,
            BONE[2] * 0.62 + AMBER[2] * 0.38,
        )
        blend = 0.48
    elif luminance >= 92:
        target = (
            AMBER[0] * 0.62 + SLATE[0] * 0.38,
            AMBER[1] * 0.62 + SLATE[1] * 0.38,
            AMBER[2] * 0.62 + SLATE[2] * 0.38,
        )
        blend = 0.58
    elif luminance >= 50:
        target = (
            SLATE[0] * 0.72 + AMBER[0] * 0.28,
            SLATE[1] * 0.72 + AMBER[1] * 0.28,
            SLATE[2] * 0.72 + AMBER[2] * 0.28,
        )
        blend = 0.68
    else:
        target = BLACK
        blend = 0.38

    nr = clamp(r * (1.0 - blend) + target[0] * blend + 6)
    ng = clamp(g * (1.0 - blend) + target[1] * blend - 18)
    nb = clamp(b * (1.0 - blend) + target[2] * blend - 10)
    return nr, ng, nb, a


def green_ratio(image: Image.Image, regions: list[tuple[int, int, int, int]] | None) -> float:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    total = 0
    green = 0
    for y in range(rgba.height):
        for x in range(rgba.width):
            if not in_regions(x, y, regions):
                continue
            r, g, b, a = pixels[x, y]
            if a <= 24:
                continue
            total += 1
            if is_green_spill(r, g, b, a):
                green += 1
    return (green / max(1, total)) * 100.0


def grade_image(path: Path, regions: list[tuple[int, int, int, int]] | None) -> dict[str, object]:
    image = Image.open(path).convert("RGBA")
    before = green_ratio(image, regions)
    pixels = image.load()
    changed = 0
    for y in range(image.height):
        for x in range(image.width):
            if not in_regions(x, y, regions):
                continue
            old = pixels[x, y]
            new = grade_pixel(*old)
            if new != old:
                changed += 1
                pixels[x, y] = new
    after = green_ratio(image, regions)
    image.save(path, optimize=True)
    return {
        "asset": path.relative_to(ROOT).as_posix(),
        "green_spill_percent_before": round(before, 2),
        "green_spill_percent_after": round(after, 2),
        "changed_pixels": changed,
    }


def main() -> None:
    records = []
    for target in TARGETS:
        path = ROOT / str(target["path"])
        if not path.exists():
            raise FileNotFoundError(path)
        record = grade_image(path, target["regions"])
        record["id"] = target["id"]
        record["note"] = target["note"]
        records.append(record)

    payload = {
        "status": "graded",
        "rule": "Salt Market keeps absinthe green for sky/Church/wrong-light only; visible people, market cloth, and foreground dressing are graded toward wet black, harbor slate, and whale-oil amber.",
        "target_count": len(records),
        "max_green_spill_percent_after": max(record["green_spill_percent_after"] for record in records),
        "records": records,
    }
    REPORT_JSON.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Salt Market Green Spill Grade",
        "",
        "Generated by `tools/Fix-SaltMarketGreenSpill.py`.",
        "",
        payload["rule"],
        "",
        f"- Targets: {payload['target_count']}",
        f"- Max green spill after: {payload['max_green_spill_percent_after']}%",
        "",
        "| Asset | Green spill before | Green spill after | Changed pixels |",
        "|---|---:|---:|---:|",
    ]
    for record in records:
        lines.append(
            f"| `{record['asset']}` | {record['green_spill_percent_before']}% | "
            f"{record['green_spill_percent_after']}% | {record['changed_pixels']} |"
        )
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"salt_market_green_spill_targets={len(records)}")
    print(f"max_green_spill_after={payload['max_green_spill_percent_after']}%")


if __name__ == "__main__":
    main()
