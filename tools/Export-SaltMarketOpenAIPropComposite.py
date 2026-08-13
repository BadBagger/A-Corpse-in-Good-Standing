from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("boot_stall", 92, 548),
    ("market_crowd_dressing", 760, 545),
    ("church_sign", 1295, 405),
    ("confession_queue", 1165, 500),
    ("fishmonger", 430, 625),
]


def main() -> None:
    background_path = ROOT / "game" / "rooms" / "salt_market" / "background" / "salt_market_bg.png"
    if not background_path.exists():
        raise FileNotFoundError(f"Missing Salt Market background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "salt_market" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing Salt Market prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 600, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R03 / Salt Market foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "salt_market_openai_prop_composite.png"
    image.save(out_path)
    print(f"Salt Market prop composite written: {out_path}")


if __name__ == "__main__":
    main()
