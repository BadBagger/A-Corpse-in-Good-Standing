from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

PROPS = [
    ("bone_trade_counter", 690, 545),
    ("prosper_watch_display", 1018, 612),
    ("bone_shelf_cluster", 1325, 500),
    ("salt_trade_tray", 650, 760),
]


def main() -> None:
    background_path = ROOT / "game" / "rooms" / "bone_chandler" / "background" / "bone_chandler_bg.png"
    if not background_path.exists():
        raise FileNotFoundError(f"Missing Bone Chandler background: {background_path}")

    image = Image.open(background_path).convert("RGBA")
    for prop_id, x, y in PROPS:
        prop_path = ROOT / "game" / "rooms" / "bone_chandler" / "props" / f"{prop_id}.png"
        if not prop_path.exists():
            raise FileNotFoundError(f"Missing Bone Chandler prop: {prop_path}")
        prop = Image.open(prop_path).convert("RGBA")
        image.alpha_composite(prop, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 650, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), "R06 / Bone Chandler foreground prop composite", fill=(228, 220, 200))

    out_dir = ROOT / "docs" / "art" / "review"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "bone_chandler_openai_prop_composite.png"
    image.save(out_path)
    print(f"Bone Chandler prop composite written: {out_path}")


if __name__ == "__main__":
    main()
