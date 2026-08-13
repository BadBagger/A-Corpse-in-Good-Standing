from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("brine_silt", 846, 825),
    ("tomas_bollard", 268, 405),
    ("missing_boots", 897, 785),
]


def main() -> None:
    background_path = ROOT / "game" / "rooms" / "mudflats" / "background" / "mudflats_bg.png"
    if not background_path.exists():
        raise FileNotFoundError(f"Missing mudflats background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "mudflats" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing mudflats prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 600, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R01 / Mudflats foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "mudflats_openai_prop_composite.png"
    image.save(out_path)
    print(f"Mudflats prop composite written: {out_path}")


if __name__ == "__main__":
    main()
