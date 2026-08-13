from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]

ROOMS = [
    ("R02", "The Old Quay", "old_quay", "old_quay_blockout_bg.png", [("tomas_bollard", 400, 735, 1.0)]),
    ("R03", "Salt Market", "salt_market", "salt_market_bg.png", []),
    ("R05", "Harbor Registry", "harbor_registry", "harbor_registry_bg.png", [("registrar", 1230, 705, 0.78)]),
    ("R06", "The Bone Chandler", "bone_chandler", "bone_chandler_bg.png", [("bone_chandler", 1200, 760, 0.78)]),
    ("R07", "The Almshouse", "almshouse", "almshouse_bg.png", [("prosper", 1190, 775, 0.82)]),
    ("R09", "Church of the Drowned", "church_of_the_drowned", "church_of_the_drowned_bg.png", [("teodor", 1230, 740, 0.78)]),
    ("R10", "The Grey Float", "grey_float", "grey_float_bg.png", [("juno", 1250, 745, 0.75)]),
    ("R12", "Sabine's Office", "sabine_office", "sabine_office_bg.png", [("sabine", 1260, 735, 0.76)]),
]


def composite_room(room_id: str, title: str, folder: str, background: str, standees: list[tuple[str, int, int, float]]) -> Image.Image:
    bg_path = ROOT / "game" / "rooms" / folder / "background" / background
    if not bg_path.exists():
        raise FileNotFoundError(f"Missing background for {room_id}: {bg_path}")
    image = Image.open(bg_path).convert("RGBA")
    for standee_id, foot_x, foot_y, scale in standees:
        standee_path = ROOT / "game" / "standees" / "act_i" / f"{standee_id}.png"
        if not standee_path.exists():
            raise FileNotFoundError(f"Missing standee for {room_id}: {standee_path}")
        standee = Image.open(standee_path).convert("RGBA")
        if scale != 1.0:
            standee = standee.resize(
                (round(standee.width * scale), round(standee.height * scale)),
                Image.Resampling.LANCZOS,
            )
        x = int(foot_x - standee.width / 2)
        y = int(foot_y - standee.height)
        image.alpha_composite(standee, (x, y))

    draw = ImageDraw.Draw(image)
    draw.rectangle((28, 28, 480, 84), fill=(12, 16, 19, 190))
    draw.text((44, 44), f"{room_id} / {title}", fill=(228, 220, 200))
    return image


def main() -> None:
    out_dir = ROOT / "docs" / "art" / "review" / "act_i_standee_room_composites"
    out_dir.mkdir(parents=True, exist_ok=True)

    thumbs = []
    for room_id, title, folder, background, standees in ROOMS:
        room = composite_room(room_id, title, folder, background, standees)
        room_path = out_dir / f"{folder}_standee_composite.png"
        room.save(room_path)
        thumb = room.copy()
        thumb.thumbnail((480, 270), Image.Resampling.LANCZOS)
        thumbs.append((room_id, title, thumb))

    pad = 24
    columns = 2
    thumb_w, thumb_h = 480, 270
    label_h = 36
    rows = (len(thumbs) + columns - 1) // columns
    sheet = Image.new(
        "RGB",
        (columns * thumb_w + (columns + 1) * pad, rows * (thumb_h + label_h) + (rows + 1) * pad),
        (12, 16, 19),
    )
    draw = ImageDraw.Draw(sheet)
    for index, (room_id, title, thumb) in enumerate(thumbs):
        col = index % columns
        row = index // columns
        x = pad + col * (thumb_w + pad)
        y = pad + row * (thumb_h + label_h + pad)
        sheet.paste(thumb.convert("RGB"), (x, y))
        draw.text((x, y + thumb_h + 8), f"{room_id} / {title}", fill=(228, 220, 200))

    contact_path = ROOT / "docs" / "art" / "review" / "act_i_standee_room_composite_contact_sheet.png"
    sheet.save(contact_path)
    print(f"Act I standee room composites written: {contact_path}")


if __name__ == "__main__":
    main()
