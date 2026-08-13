from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("juno_ledger_table", 290, 560),
    ("bilge_regulator", 860, 465),
    ("privacy_screen", 1335, 440),
    ("hot_pool_steps", 1135, 665),
]


def main() -> None:
    background_path = ROOT / "game" / "rooms" / "grey_float" / "background" / "grey_float_bg.png"
    if not background_path.exists():
        raise FileNotFoundError(f"Missing Grey Float background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "grey_float" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing Grey Float prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 610, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R10 / Grey Float foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "grey_float_openai_prop_composite.png"
    image.save(out_path)
    print(f"Grey Float prop composite written: {out_path}")


if __name__ == "__main__":
    main()
