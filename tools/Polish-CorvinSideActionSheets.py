from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
EXPORT_DIR = ROOT / "art" / "export" / "characters" / "corvin" / "act_i_clean"
GAME_DIR = ROOT / "game" / "characters" / "corvin" / "sprites" / "act_i_clean"
REPORT_JSON = ROOT / "docs" / "art" / "corvin_side_action_polish_bridge.json"
REPORT_MD = ROOT / "docs" / "art" / "corvin_side_action_polish_bridge.md"

CELL_W = 256
CELL_H = 512
BONE = (228, 220, 200, 205)
SLATE = (42, 58, 64, 210)

SPECS = [
    ("talk", "side_right", 6, [0, 10, 24, 14, -8, 0], [0, -2, -6, -3, 2, 0]),
    ("talk", "side_left", 6, [0, -10, -24, -14, 8, 0], [0, -2, -6, -3, 2, 0]),
    ("use", "side_right", 8, [0, 8, 16, 24, 28, 20, 8, 0], [0, -3, -8, -14, -12, -6, -2, 0]),
    ("use", "side_left", 8, [0, -8, -16, -24, -28, -20, -8, 0], [0, -3, -8, -14, -12, -6, -2, 0]),
    ("wet", "side_right", 8, [0, 5, 10, 14, 16, 12, 5, 0], [0, -2, -7, -13, -10, -5, -2, 0]),
    ("wet", "side_left", 8, [0, -5, -10, -14, -16, -12, -5, 0], [0, -2, -7, -13, -10, -5, -2, 0]),
]


def split_frame(frame: Image.Image) -> tuple[Image.Image, Image.Image]:
    lower = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    upper = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    lower.alpha_composite(frame.crop((0, 260, CELL_W, CELL_H)), (0, 260))
    upper.alpha_composite(frame.crop((0, 0, CELL_W, 318)), (0, 0))
    return lower, upper


def motion_polish_frame(source: Image.Image, horizontal_shift: int, vertical_shift: int, animation: str, direction: str, frame_index: int) -> Image.Image:
    lower, upper = split_frame(source)
    output = Image.new("RGBA", source.size, (0, 0, 0, 0))
    output.alpha_composite(lower)

    if horizontal_shift != 0 or vertical_shift != 0:
        shear = -0.06 if horizontal_shift > 0 else 0.06
        upper = upper.transform(
            upper.size,
            Image.Transform.AFFINE,
            (1.0, shear, horizontal_shift, 0.0, 1.0, vertical_shift),
            resample=Image.Resampling.BICUBIC,
        )
    output.alpha_composite(upper)

    draw = ImageDraw.Draw(output, "RGBA")
    facing = 1 if direction == "side_right" else -1
    hand_x = 138 + horizontal_shift if facing == 1 else 118 + horizontal_shift
    if animation == "talk" and 1 <= frame_index <= 4:
        for tick in range(2):
            y = 176 + frame_index * 7 + tick * 16 + vertical_shift
            x0 = min(hand_x - 28 * facing, hand_x + 28 * facing)
            x1 = max(hand_x - 28 * facing, hand_x + 28 * facing)
            draw.arc((x0, y - 10, x1, y + 22), 300 if facing == 1 else 60, 35 if facing == 1 else 155, fill=BONE, width=2)
    elif animation == "use" and 2 <= frame_index <= 5:
        reach_x = hand_x + facing * (12 + frame_index * 3)
        draw.line((hand_x, 202 + vertical_shift, reach_x, 188 + vertical_shift), fill=BONE, width=3)
        draw.ellipse((reach_x - 5, 183 + vertical_shift, reach_x + 5, 193 + vertical_shift), fill=SLATE)
    elif animation == "wet" and 2 <= frame_index <= 6:
        start_x = hand_x + facing * 16
        start_y = 218 + vertical_shift
        length = 12 + frame_index * 2
        draw.line((start_x, start_y, start_x + facing * length, start_y + 26), fill=(228, 220, 200, 185), width=3)
        draw.line((start_x - facing * 8, start_y + 12, start_x + facing * (length - 10), start_y + 42), fill=(42, 58, 64, 200), width=2)
        torso_x = 126 if facing == 1 else 130
        for streak in range(8):
            sx = torso_x + facing * ((streak % 4) * 5)
            sy = 150 + frame_index * 4 + streak * 13
            draw.line((sx, sy, sx + facing * 14, sy + 26), fill=(228, 220, 200, 175), width=3)
            draw.line((sx - facing * 7, sy + 8, sx + facing * 5, sy + 30), fill=(42, 58, 64, 185), width=2)
        for droplet in range(4):
            dx = facing * (12 + droplet * 8 + frame_index)
            dy = 32 + droplet * 6
            draw.ellipse((start_x + dx - 2, start_y + dy - 2, start_x + dx + 3, start_y + dy + 3), fill=BONE)
    return output


def polish_sheet(animation: str, direction: str, frames: int, shifts: list[int], verticals: list[int]) -> dict:
    export_path = EXPORT_DIR / f"{animation}_{direction}.png"
    game_path = GAME_DIR / f"{animation}_{direction}.png"
    if not export_path.exists():
        raise FileNotFoundError(export_path)
    source = Image.open(export_path).convert("RGBA")
    if source.size != (frames * CELL_W, CELL_H):
        raise ValueError(f"{export_path} has {source.size}, expected {(frames * CELL_W, CELL_H)}")

    out = Image.new("RGBA", source.size, (0, 0, 0, 0))
    for index in range(frames):
        frame = source.crop((index * CELL_W, 0, (index + 1) * CELL_W, CELL_H))
        polished = motion_polish_frame(frame, shifts[index], verticals[index], animation, direction, index)
        out.alpha_composite(polished, (index * CELL_W, 0))
    out.save(export_path, optimize=True)
    game_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(game_path, optimize=True)
    return {
        "animation": animation,
        "direction": direction,
        "frames": frames,
        "sheet_export": export_path.relative_to(ROOT).as_posix(),
        "godot_import": game_path.relative_to(ROOT).as_posix(),
        "max_horizontal_shift_px": max(abs(value) for value in shifts),
        "method": "deterministic 2D silhouette/readability polish bridge over existing Blender-rendered sheets",
    }


def main() -> None:
    records = [polish_sheet(*spec) for spec in SPECS]
    payload = {
        "generated_from": "tools/Polish-CorvinSideActionSheets.py",
        "status": "polished_pending_rendered_sheet_audit",
        "rule_locks": [
            "This is a deterministic 2D gameplay readability bridge, not final animation polish.",
            "It preserves the canonical 256x512 cell contract and byte-for-byte Godot import parity.",
            "Wet remains physical brine using bone/slate only and no arterial red.",
            "Final Corvin animation polish still belongs in the Blender source pass.",
        ],
        "rows": records,
    }
    REPORT_JSON.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Corvin Side Action Polish Bridge",
        "",
        "Generated by `tools/Polish-CorvinSideActionSheets.py`.",
        "",
        "Status: polished_pending_rendered_sheet_audit.",
        "",
        "This is a deterministic 2D gameplay readability bridge over the existing Blender-rendered sheets. It makes talk/use/wet visibly different in the playable Act I build while keeping final animation polish assigned to the Blender source pass.",
        "",
        "Rule locks:",
        "- Preserves 256x512 cells and existing frame counts.",
        "- Copies the polished sheet byte-for-byte into the Godot runtime sprite path.",
        "- Wet uses physical brine strokes in bone/slate only; no arterial red.",
        "- Does not approve final animation polish.",
        "",
        "| Animation | Direction | Frames | Max shift | Sheet | Godot import |",
        "|---|---|---:|---:|---|---|",
    ]
    for record in records:
        lines.append(
            f"| {record['animation']} | {record['direction']} | {record['frames']} | {record['max_horizontal_shift_px']}px | `{record['sheet_export']}` | `{record['godot_import']}` |"
        )
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"polished={len(records)}")


if __name__ == "__main__":
    main()
