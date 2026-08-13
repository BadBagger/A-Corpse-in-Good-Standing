from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("poor_box", 545, 690),
    ("confession_booth", 705, 535),
    ("church_ledger_desk", 875, 665),
    ("church_tariff_sign", 1105, 645),
]


def main() -> None:
    background_path = (
        ROOT / "game" / "rooms" / "church_of_the_drowned" / "background" / "church_of_the_drowned_bg.png"
    )
    if not background_path.exists():
        raise FileNotFoundError(f"Missing Church background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "church_of_the_drowned" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing Church prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 760, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R09 / Church of the Drowned foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "church_of_the_drowned_openai_prop_composite.png"
    image.save(out_path)
    print(f"Church prop composite written: {out_path}")


if __name__ == "__main__":
    main()
