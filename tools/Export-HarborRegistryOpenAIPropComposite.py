from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("registry_roll_book", 520, 555),
    ("registry_candles", 910, 642),
    ("registry_confession_slips", 1065, 720),
    ("registry_inkstand", 790, 720),
]


def main() -> None:
    background_path = ROOT / "game" / "rooms" / "harbor_registry" / "background" / "harbor_registry_bg.png"
    if not background_path.exists():
        raise FileNotFoundError(f"Missing Harbor Registry background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "harbor_registry" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing Harbor Registry prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 690, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R05 / Harbor Registry foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "harbor_registry_openai_prop_composite.png"
    image.save(out_path)
    print(f"Harbor Registry prop composite written: {out_path}")


if __name__ == "__main__":
    main()
