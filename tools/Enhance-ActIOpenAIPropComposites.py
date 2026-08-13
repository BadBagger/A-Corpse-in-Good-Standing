from __future__ import annotations

import ast
import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REVIEW_DIR = ROOT / "docs" / "art" / "review"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_prop_grounding_pass.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_prop_grounding_pass.md"

MANIFEST_ROOMS = {
    "almshouse": ("Almshouse", "almshouse_bg.png", "docs/art/almshouse_openai_props.json", "almshouse_openai_prop_composite.png"),
    "fish_hall": ("Fish Hall", "fish_hall_bg.png", "docs/art/fish_hall_openai_props.json", "fish_hall_openai_prop_composite.png"),
    "harbormaster_office": ("Harbormaster Office", "harbormaster_office_bg.png", "docs/art/harbormaster_office_openai_props.json", "harbormaster_office_openai_prop_composite.png"),
}

EXPORTER_FILES = [
    "Export-MudflatsOpenAIPropComposite.py",
    "Export-OldQuayOpenAIPropComposite.py",
    "Export-SaltMarketOpenAIPropComposite.py",
    "Export-HarborRegistryOpenAIPropComposite.py",
    "Export-BoneChandlerOpenAIPropComposite.py",
    "Export-ChurchOpenAIPropComposite.py",
    "Export-GreyFloatOpenAIPropComposite.py",
    "Export-SabineOfficeOpenAIPropComposite.py",
]


def parse_exporter(script_name: str) -> dict:
    path = ROOT / "tools" / script_name
    text = path.read_text(encoding="utf-8")
    props_match = re.search(r"PROPS\s*=\s*(\[[\s\S]*?\])\n\n", text)
    bg_match = re.search(r'"rooms"\s*/\s*"([^"]+)"\s*/\s*"background"\s*/\s*"([^"]+)"', text)
    out_match = re.search(r'out_path\s*=\s*out_dir\s*/\s*"([^"]+)"', text)
    title_match = re.search(r'draw\.text\([^,]+,\s*"([^"]+) foreground prop composite"', text)
    if not props_match or not bg_match or not out_match:
        raise ValueError(f"Could not parse prop exporter: {path}")
    room_id, background = bg_match.groups()
    title = title_match.group(1).split(" / ", 1)[-1] if title_match else room_id.replace("_", " ").title()
    props = [
        {
            "prop_id": prop_id,
            "game_resource": f"game/rooms/{room_id}/props/{prop_id}.png",
            "position": [x, y],
            "z": index,
        }
        for index, (prop_id, x, y) in enumerate(ast.literal_eval(props_match.group(1)))
    ]
    return {
        "room_id": room_id,
        "title": title,
        "background": f"game/rooms/{room_id}/background/{background}",
        "output": f"docs/art/review/{out_match.group(1)}",
        "props": props,
    }


def manifest_room(room_id: str, values: tuple[str, str, str, str]) -> dict:
    title, background_file, manifest_rel, output_file = values
    manifest = json.loads((ROOT / manifest_rel).read_text(encoding="utf-8"))
    props = []
    for index, entry in enumerate(sorted(manifest["props"], key=lambda item: int(item["z"]))):
        props.append(
            {
                "prop_id": entry["id"],
                "game_resource": entry["game_resource"],
                "position": entry["position"],
                "z": index,
            }
        )
    return {
        "room_id": room_id,
        "title": title,
        "background": f"game/rooms/{room_id}/background/{background_file}",
        "output": f"docs/art/review/{output_file}",
        "props": props,
    }


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def contact_shadow(prop: Image.Image, bbox: tuple[int, int, int, int]) -> Image.Image:
    left, top, right, bottom = bbox
    width = max(18, min(180, round((right - left) * 0.72)))
    height = max(8, min(36, round((bottom - top) * 0.055)))
    shadow = Image.new("RGBA", prop.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow, "RGBA")
    cx = (left + right) // 2
    cy = bottom - max(2, height // 4)
    draw.ellipse((cx - width // 2, cy - height, cx + width // 2, cy + height), fill=(12, 16, 19, 118))
    return shadow.filter(ImageFilter.GaussianBlur(radius=4))


def reflection(prop: Image.Image, bbox: tuple[int, int, int, int]) -> Image.Image:
    left, _top, right, bottom = bbox
    crop_h = max(18, min(130, round((bottom - bbox[1]) * 0.34)))
    source = prop.crop((left, max(bbox[1], bottom - crop_h), right, bottom))
    reflected = source.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    alpha = reflected.getchannel("A").point(lambda value: round(value * 0.18))
    reflected.putalpha(alpha)
    canvas = Image.new("RGBA", prop.size, (0, 0, 0, 0))
    canvas.alpha_composite(reflected.filter(ImageFilter.GaussianBlur(radius=1.2)), (left, bottom + 2))
    return canvas


def draw_room_label(image: Image.Image, title: str) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    draw.rectangle((28, 28, 650, 84), fill=(12, 16, 19, 190), outline=(201, 138, 60, 110))
    draw.text((44, 44), f"{title} foreground prop composite - grounded", fill=(228, 220, 200))


def composite_room(room: dict) -> dict:
    background_path = ROOT / room["background"]
    if not background_path.exists():
        raise FileNotFoundError(background_path)
    image = Image.open(background_path).convert("RGBA")
    prop_records = []
    for entry in sorted(room["props"], key=lambda item: int(item["z"])):
        prop_path = ROOT / entry["game_resource"]
        if not prop_path.exists():
            raise FileNotFoundError(prop_path)
        prop = Image.open(prop_path).convert("RGBA")
        bbox = alpha_bbox(prop)
        x, y = int(entry["position"][0]), int(entry["position"][1])
        if bbox:
            image.alpha_composite(contact_shadow(prop, bbox), (x, y))
            image.alpha_composite(reflection(prop, bbox), (x, y))
        image.alpha_composite(prop, (x, y))
        prop_records.append(
            {
                "id": entry["prop_id"],
                "resource": entry["game_resource"],
                "position": [x, y],
                "grounding": "contact_shadow_and_wet_reflection" if bbox else "blank_alpha_skipped",
            }
        )
    draw_room_label(image, room["title"])
    output = ROOT / room["output"]
    output.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(output, optimize=True)
    return {
        "room_id": room["room_id"],
        "title": room["title"],
        "output": room["output"],
        "background": room["background"],
        "prop_count": len(prop_records),
        "props": prop_records,
    }


def main() -> None:
    rooms = [parse_exporter(script) for script in EXPORTER_FILES]
    rooms.extend(manifest_room(room_id, values) for room_id, values in MANIFEST_ROOMS.items())
    rooms = sorted(rooms, key=lambda room: room["room_id"])
    records = [composite_room(room) for room in rooms]
    payload = {
        "generated_from": "tools/Enhance-ActIOpenAIPropComposites.py",
        "status": "grounded",
        "room_count": len(records),
        "prop_count": sum(record["prop_count"] for record in records),
        "grounding_pass": "contact shadows and wet-floor reflections added from each runtime prop alpha mask",
        "rooms": records,
    }
    REPORT_JSON.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Act I Prop Grounding Pass",
        "",
        "Generated by `tools/Enhance-ActIOpenAIPropComposites.py`.",
        "",
        "Status: grounded.",
        "",
        "This pass rebuilds Act I prop review composites from runtime background and prop PNGs, then adds deterministic contact shadows and wet-floor reflections from each prop alpha mask. It is review evidence for visual grounding; the runtime room scripts still place the original prop nodes.",
        "",
        f"- Rooms: {payload['room_count']}",
        f"- Props grounded: {payload['prop_count']}",
        "- Content line: hard-R, no explicit anatomy, no gore, no bodies, no child figures.",
        "",
        "| Room | Props | Composite |",
        "|---|---:|---|",
    ]
    for record in records:
        lines.append(f"| {record['title']} | {record['prop_count']} | `{record['output']}` |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"grounded_rooms={len(records)}")
    print(f"grounded_props={payload['prop_count']}")


if __name__ == "__main__":
    main()
