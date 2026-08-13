from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "art" / "act_i_background_manifest.json"
RAW_DIR = ROOT / "art" / "src" / "backgrounds" / "act_i" / "openai"
CONTACT_SHEET_PATH = ROOT / "docs" / "art" / "review" / "act_i_openai_contact_sheet.png"
REPORT_JSON_PATH = ROOT / "docs" / "art" / "act_i_openai_art_pass.json"
REPORT_MD_PATH = ROOT / "docs" / "art" / "act_i_openai_art_pass.md"

PALETTE = {
    "bone": (228, 220, 200),
    "black": (12, 16, 19),
    "slate": (42, 58, 64),
    "green": (125, 155, 78),
    "amber": (201, 138, 60),
}


@dataclass(frozen=True)
class PlateImport:
    room_id: str
    source_path: Path


PLATES = [
    PlateImport("mudflats", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_YXwKZgGrOvg0obvuVozrGlCf.png")),
    PlateImport("old_quay", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_gBNTSptrXaYR6jWPN833oWPy.png")),
    PlateImport("salt_market", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_tLLeRCxoP6PuP43JbhaIvbmK.png")),
    PlateImport("harbor_registry", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_B093a4hvxvjpPjKp3pO914MO.png")),
    PlateImport("bone_chandler", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_cE7papjngvNh5qhjlneUxst5.png")),
    PlateImport("fish_hall", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_uBOcIerk7oJ2jCIOOupQQxDs.png")),
    PlateImport("almshouse", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_mM6jn2tVa3bypOY5xk3y1vKL.png")),
    PlateImport("church_of_the_drowned", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_e0ZMYfxyQznEi2LxioZ2Wdkf.png")),
    PlateImport("grey_float", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_ooZAMBeratQAXsouVfgr06Di.png")),
    PlateImport("harbormaster_office", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_BQI8rHgLiHSJGHK3GlGJyru6.png")),
    PlateImport("sabine_office", Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_2maQDlNAXpIjS3FDe5s8FG2A.png")),
]


def load_manifest() -> dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8-sig"))


def make_palette_image() -> Image.Image:
    palette_values: list[int] = []
    for color in PALETTE.values():
        palette_values.extend(color)
    # Pillow may use any palette slot during quantization. Fill unused entries
    # with approved wet black so no stray pure-black pixels fail G9.
    palette_values.extend(list(PALETTE["black"]) * (256 - len(PALETTE)))

    palette_image = Image.new("P", (1, 1))
    palette_image.putpalette(palette_values)
    return palette_image


def resize_cover(image: Image.Image, width: int, height: int) -> Image.Image:
    image = ImageOps.exif_transpose(image).convert("RGB")
    src_w, src_h = image.size
    scale = max(width / src_w, height / src_h)
    resized = image.resize((round(src_w * scale), round(src_h * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def palette_lock(image: Image.Image) -> Image.Image:
    palette_image = make_palette_image()
    return image.quantize(palette=palette_image, dither=Image.Dither.FLOYDSTEINBERG).convert("RGB")


def write_flat_psd(path: Path, image: Image.Image) -> None:
    width, height = image.size
    channels = 3
    header = bytearray()
    header += b"8BPS"
    header += (1).to_bytes(2, "big")
    header += b"\0" * 6
    header += channels.to_bytes(2, "big")
    header += height.to_bytes(4, "big")
    header += width.to_bytes(4, "big")
    header += (8).to_bytes(2, "big")
    header += (3).to_bytes(2, "big")
    header += (0).to_bytes(4, "big")
    header += (0).to_bytes(4, "big")
    header += (0).to_bytes(4, "big")
    header += (0).to_bytes(2, "big")

    r, g, b = image.split()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(header) + r.tobytes() + g.tobytes() + b.tobytes())


def build_contact_sheet(records: list[dict]) -> None:
    thumb_w, thumb_h = 480, 270
    cols = 2
    rows = (len(records) + cols - 1) // cols
    label_h = 34
    sheet = Image.new("RGB", (cols * thumb_w, rows * (thumb_h + label_h)), PALETTE["black"])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    for index, record in enumerate(records):
        image = Image.open(ROOT / record["export_png"]).convert("RGB")
        image.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        x = (index % cols) * thumb_w
        y = (index // cols) * (thumb_h + label_h)
        sheet.paste(image, (x, y))
        draw.rectangle((x, y + thumb_h, x + thumb_w, y + thumb_h + label_h), fill=PALETTE["slate"])
        draw.text((x + 10, y + thumb_h + 10), f"{record['room_code']} {record['title']}", fill=PALETTE["bone"], font=font)

    CONTACT_SHEET_PATH.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT_SHEET_PATH)


def main() -> None:
    manifest = load_manifest()
    rooms_by_id = {room["room_id"]: room for room in manifest["rooms"]}
    stage = manifest["native_resolution"]
    width = int(stage["width"])
    height = int(stage["height"])

    records = []
    for plate in PLATES:
        if not plate.source_path.exists():
            raise FileNotFoundError(f"Missing generated source for {plate.room_id}: {plate.source_path}")
        if plate.room_id not in rooms_by_id:
            raise KeyError(f"Unknown Act I room id in plate import: {plate.room_id}")

        room = rooms_by_id[plate.room_id]
        raw_target = RAW_DIR / f"{plate.room_id}_openai_raw.png"
        raw_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(plate.source_path, raw_target)

        image = resize_cover(Image.open(raw_target), width, height)
        locked = palette_lock(image)

        export_png = ROOT / room["export_png"]
        godot_png = ROOT / room["godot_background_resource"]
        psd_path = ROOT / room["paintover_source"]

        write_flat_psd(psd_path, locked)
        export_png.parent.mkdir(parents=True, exist_ok=True)
        godot_png.parent.mkdir(parents=True, exist_ok=True)
        locked.save(export_png, optimize=True)
        locked.save(godot_png, optimize=True)

        records.append(
            {
                "room_id": plate.room_id,
                "room_code": room["room_code"],
                "title": room["title"],
                "openai_source": str(raw_target.relative_to(ROOT)).replace("\\", "/"),
                "paintover_source": room["paintover_source"],
                "export_png": room["export_png"],
                "godot_background_resource": room["godot_background_resource"],
                "source_bytes": raw_target.stat().st_size,
                "export_bytes": export_png.stat().st_size,
                "psd_bytes": psd_path.stat().st_size,
            }
        )

    build_contact_sheet(records)

    report = {
        "generated_from": "OpenAI image generation via built-in image_gen tool",
        "importer": "tools/Import-ActIOpenAIBackgrounds.py",
        "native_resolution": stage,
        "palette_lock": "Floyd-Steinberg quantized to locked Act I palette without arterial red",
        "contact_sheet": str(CONTACT_SHEET_PATH.relative_to(ROOT)).replace("\\", "/"),
        "rooms": records,
    }
    REPORT_JSON_PATH.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Act I OpenAI Art Pass",
        "",
        "OpenAI-generated source plates were imported, preserved under `art/src/backgrounds/act_i/openai`, palette-locked for runtime, and synced to the Godot room background paths.",
        "",
        f"- Rooms imported: {len(records)}",
        f"- Contact sheet: `{report['contact_sheet']}`",
        "- Runtime palette: locked Act I palette, no arterial red",
        "",
        "| Room | Raw source | Runtime export |",
        "|---|---|---|",
    ]
    for record in records:
        lines.append(f"| {record['room_code']} {record['title']} | `{record['openai_source']}` | `{record['export_png']}` |")
    REPORT_MD_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"imported={len(records)}")
    print(f"contact_sheet={CONTACT_SHEET_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
