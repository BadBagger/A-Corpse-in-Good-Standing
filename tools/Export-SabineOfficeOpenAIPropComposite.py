from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("frosted_sabine_door", 110, 220),
    ("damp_persian_rug", 430, 760),
    ("harbormaster_desk", 845, 565),
    ("harbor_chart_board", 1495, 495),
]


def main() -> None:
    background_path = ROOT / "game" / "rooms" / "sabine_office" / "background" / "sabine_office_bg.png"
    if not background_path.exists():
        raise FileNotFoundError(f"Missing Sabine Office background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "sabine_office" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing Sabine Office prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 620, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R12 / Sabine Office foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "sabine_office_openai_prop_composite.png"
    image.save(out_path)
    print(f"Sabine Office prop composite written: {out_path}")


if __name__ == "__main__":
    main()
