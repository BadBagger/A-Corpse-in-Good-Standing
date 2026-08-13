from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\KyleB\.codex\generated_images\019fed98-2fe1-7052-afd1-585c9b506c3f\call_leVR6JR1EDfjfdMfQbSBudCM.png")
RAW_DIR = ROOT / "art" / "src" / "portraits" / "act_i" / "openai"
EXPORT_DIR = ROOT / "art" / "export" / "portraits" / "act_i"
GAME_DIR = ROOT / "game" / "portraits" / "act_i"
CONTACT_SHEET = ROOT / "docs" / "art" / "review" / "act_i_openai_portraits_contact_sheet.png"
REPORT_JSON = ROOT / "docs" / "art" / "act_i_openai_portraits.json"
REPORT_MD = ROOT / "docs" / "art" / "act_i_openai_portraits.md"


PALETTE = {
    "bone": (228, 220, 200),
    "black": (12, 16, 19),
    "slate": (42, 58, 64),
    "green": (125, 155, 78),
    "amber": (201, 138, 60),
}


@dataclass(frozen=True)
class PortraitSpec:
    character_id: str
    display_name: str
    role: str
    emotion: str
    grid_col: int
    grid_row: int
    content_note: str


PORTRAITS = [
    PortraitSpec("corvin", "Corvin Vale", "player", "neutral", 0, 0, "Act I returned notary; wet coat and salt-knuckle read."),
    PortraitSpec("sabine", "Sabine Croix", "main_npc", "controlled", 1, 0, "Harbormaster authority portrait; no apology in the expression."),
    PortraitSpec("registrar", "The Registrar", "duel_opponent", "bored", 2, 0, "Act I Confession Duel opponent; ledger/ink identity preserved."),
    PortraitSpec("juno", "Juno Ash", "main_npc", "warm_danger", 0, 1, "Grey Float proprietor; hard-R styling remains portrait-only and non-explicit."),
    PortraitSpec("tomas", "Bollard-of-Tomas", "supporting_npc", "wry", 1, 1, "Talking mooring post; comic-tragic salt/calcification read."),
    PortraitSpec("prosper", "Half-Coin Prosper", "supporting_npc", "forgetful_kind", 2, 1, "Debt Forgiven path NPC; salt-memory rot and gentleness read."),
]


def ensure_dirs() -> None:
    for path in (RAW_DIR, EXPORT_DIR, GAME_DIR, CONTACT_SHEET.parent):
        path.mkdir(parents=True, exist_ok=True)


def make_square(image: Image.Image, fill: tuple[int, int, int]) -> Image.Image:
    width, height = image.size
    side = max(width, height)
    square = Image.new("RGB", (side, side), fill)
    square.paste(image, ((side - width) // 2, (side - height) // 2))
    return square


def palette_image() -> Image.Image:
    values: list[int] = []
    runtime_colors = ("bone", "black", "slate", "amber")
    for key in ("bone", "black", "slate", "amber"):
        color = PALETTE[key]
        values.extend(color)
    values.extend(list(PALETTE["black"]) * (256 - len(runtime_colors)))
    pal = Image.new("P", (1, 1))
    pal.putpalette(values)
    return pal


def palette_lock(image: Image.Image) -> Image.Image:
    return image.quantize(palette=palette_image(), dither=Image.Dither.FLOYDSTEINBERG).convert("RGB")


def portrait_grade(image: Image.Image) -> Image.Image:
    graded = Image.new("RGB", image.size)
    pixels: list[tuple[int, int, int]] = []
    for r, g, b in image.convert("RGB").getdata():
        if g > r * 1.04 and g > b * 1.01 and g > 56:
            luminance = int(round((r * 0.30) + (g * 0.52) + (b * 0.18)))
            r = int(round((r * 0.48) + (luminance * 0.36) + 10))
            g = int(round((g * 0.37) + (luminance * 0.42) + 3))
            b = int(round((b * 0.52) + (luminance * 0.28)))
        if max(r, g, b) > 88:
            r = int(round(r * 1.03 + 4))
            g = int(round(g * 0.92))
            b = int(round(b * 0.93))
        else:
            r = int(round(r * 0.97))
            g = int(round(g * 0.91))
            b = int(round(b * 0.96))
        pixels.append((max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b))))
    graded.putdata(pixels)
    return graded


def crop_panel(sheet: Image.Image, spec: PortraitSpec) -> Image.Image:
    col_w = sheet.width / 3.0
    row_h = sheet.height / 2.0
    inset_x = round(col_w * 0.018)
    inset_y = round(row_h * 0.018)
    left = round(spec.grid_col * col_w) + inset_x
    top = round(spec.grid_row * row_h) + inset_y
    right = round((spec.grid_col + 1) * col_w) - inset_x
    bottom = round((spec.grid_row + 1) * row_h) - inset_y
    panel = sheet.crop((left, top, right, bottom)).convert("RGB")
    return ImageOps.fit(make_square(panel, PALETTE["bone"]), (720, 720), Image.Resampling.LANCZOS, centering=(0.5, 0.42))


def build_contact(records: list[dict]) -> None:
    thumb = 240
    label_h = 44
    cols = 3
    rows = 2
    sheet = Image.new("RGB", (cols * thumb, rows * (thumb + label_h)), PALETTE["black"])
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for index, record in enumerate(records):
        image = Image.open(ROOT / record["game_resource"]).convert("RGB")
        image.thumbnail((thumb, thumb), Image.Resampling.LANCZOS)
        x = (index % cols) * thumb
        y = (index // cols) * (thumb + label_h)
        sheet.paste(image, (x, y))
        draw.rectangle((x, y + thumb, x + thumb, y + thumb + label_h), fill=PALETTE["slate"])
        draw.text((x + 8, y + thumb + 8), record["display_name"], fill=PALETTE["bone"], font=font)
        draw.text((x + 8, y + thumb + 24), record["emotion"], fill=PALETTE["amber"], font=font)
    sheet.save(CONTACT_SHEET)


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing OpenAI portrait source: {SOURCE}")
    ensure_dirs()

    raw_sheet = RAW_DIR / "act_i_portrait_sheet_openai_raw.png"
    shutil.copy2(SOURCE, raw_sheet)
    sheet = Image.open(raw_sheet).convert("RGB")

    records: list[dict] = []
    for spec in PORTRAITS:
        portrait = crop_panel(sheet, spec)
        raw_export = EXPORT_DIR / f"{spec.character_id}_{spec.emotion}_raw.png"
        game_export = GAME_DIR / f"{spec.character_id}_{spec.emotion}.png"
        portrait.save(raw_export, optimize=True)
        palette_lock(portrait_grade(portrait)).save(game_export, optimize=True)
        records.append(
            {
                "character_id": spec.character_id,
                "display_name": spec.display_name,
                "role": spec.role,
                "emotion": spec.emotion,
                "content_note": spec.content_note,
                "raw_source": str(raw_sheet.relative_to(ROOT)).replace("\\", "/"),
                "raw_export": str(raw_export.relative_to(ROOT)).replace("\\", "/"),
                "game_resource": str(game_export.relative_to(ROOT)).replace("\\", "/"),
                "width": 720,
                "height": 720,
                "game_bytes": game_export.stat().st_size,
            }
        )

    build_contact(records)
    report = {
        "generated_from": "OpenAI image generation via built-in image_gen tool",
        "importer": "tools/Import-ActIOpenAIPortraits.py",
        "source_sheet": str(raw_sheet.relative_to(ROOT)).replace("\\", "/"),
        "contact_sheet": str(CONTACT_SHEET.relative_to(ROOT)).replace("\\", "/"),
        "runtime_format": "720x720 warm-graded, palette-locked PNGs",
        "content_line": "hard-R, no explicit anatomy, no child figures",
        "portraits": records,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Act I OpenAI Portraits",
        "",
        "Six OpenAI-generated dialogue portraits were cropped from a single source sheet, preserved as raw exports, warm-graded, palette-locked for runtime use, and staged under `game/portraits/act_i`.",
        "",
        f"- Source sheet: `{report['source_sheet']}`",
        f"- Contact sheet: `{report['contact_sheet']}`",
        "- Content line: hard-R, no explicit anatomy, no child figures",
        "",
        "| Character | Emotion | Runtime PNG | Note |",
        "|---|---|---|---|",
    ]
    for record in records:
        lines.append(f"| {record['display_name']} | {record['emotion']} | `{record['game_resource']}` | {record['content_note']} |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"portraits={len(records)}")
    print(f"contact_sheet={CONTACT_SHEET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
