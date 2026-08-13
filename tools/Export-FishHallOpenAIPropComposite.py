from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "game" / "rooms" / "fish_hall" / "background" / "fish_hall_bg.png"
MANIFEST = ROOT / "docs" / "art" / "fish_hall_openai_props.json"
OUTPUT = ROOT / "docs" / "art" / "review" / "fish_hall_openai_prop_composite.png"


def main() -> None:
    if not BACKGROUND.exists():
        raise FileNotFoundError(f"Missing Fish Hall background: {BACKGROUND}")
    if not MANIFEST.exists():
        raise FileNotFoundError(f"Missing Fish Hall prop manifest: {MANIFEST}")

    background = Image.open(BACKGROUND).convert("RGBA")
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    for entry in sorted(payload["props"], key=lambda item: int(item["z"])):
        prop = Image.open(ROOT / entry["game_resource"]).convert("RGBA")
        x, y = entry["position"]
        background.alpha_composite(prop, (int(x), int(y)))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    background.convert("RGB").save(OUTPUT)
    print(f"Exported Fish Hall prop composite -> {OUTPUT}")


if __name__ == "__main__":
    main()
