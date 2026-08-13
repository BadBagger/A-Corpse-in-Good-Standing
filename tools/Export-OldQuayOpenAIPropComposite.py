from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("calcified_bollard_row", 760, 620),
    ("salt_rope_cleat", 655, 740),
    ("empty_flask", 1115, 735),
    ("quay_crate_cluster", 1365, 700),
]


def main() -> None:
    background_path = ROOT / "game" / "rooms" / "old_quay" / "background" / "old_quay_bg.png"
    if not background_path.exists():
        raise FileNotFoundError(f"Missing Old Quay background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "old_quay" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing Old Quay prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 610, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R02 / Old Quay foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "old_quay_openai_prop_composite.png"
    image.save(out_path)
    print(f"Old Quay prop composite written: {out_path}")


if __name__ == "__main__":
    main()
