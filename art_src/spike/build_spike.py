"""Offline art experiment. Python 3.12 + Pillow 11.1; no game dependency.

All image resizing uses NEAREST. Indexed output shares exactly one palette:
index 0 is transparent; indices 1..31 are opaque. No dithering or downloads.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, __version__ as pillow_version


BASE = Path(__file__).resolve().parent
SOURCES = BASE / "sources"
RESULTS = BASE / "results"
ROOT = BASE.parents[1]
NEAREST = Image.Resampling.NEAREST

# A deliberately fixed cross-asset palette, rather than 32 colours per image.
HEX = [
    "000000",  # 0: transparent, not an opaque ink
    "0c101c", "171d2b", "263044", "3b4757", "59616a", "777970",
    "999883", "b6ae91", "d3c8a4", "efe3ba",  # blue/grey/parchment
    "0f282d", "173e43", "22545a", "326d71", "4c8585", "73a29a",
    "a8c2ad",  # teal
    "312018", "4d2b1d", "6b371e", "854624", "a45a28", "bc7433",
    "d49742", "eeb95a", "f6d889",  # skin/bronze
    "5d4b30", "80643c", "a18750", "453332", "965c48",
]
RGB = [tuple(bytes.fromhex(value)) for value in HEX]
PALETTE = [channel for colour in RGB for channel in colour]
PALETTE += [0] * (768 - len(PALETTE))


def indexed(size: tuple[int, int], colour: int = 0) -> Image.Image:
    result = Image.new("P", size, colour)
    result.putpalette(PALETTE)
    result.info["transparency"] = 0
    return result


def reduce_palette(source: Image.Image) -> Image.Image:
    """Deterministic nearest RGB mapping with fixed integer channel weights."""
    rgba = source.convert("RGBA")
    result = indexed(rgba.size)
    cache: dict[tuple[int, int, int], int] = {}
    mapped = []
    for red, green, blue, alpha in rgba.getdata():
        if alpha < 128:
            mapped.append(0)
            continue
        colour = (red, green, blue)
        if colour not in cache:
            cache[colour] = min(
                range(1, 32),
                key=lambda i: (
                    2 * (red - RGB[i][0]) ** 2
                    + 4 * (green - RGB[i][1]) ** 2
                    + (blue - RGB[i][2]) ** 2
                ),
            )
        mapped.append(cache[colour])
    result.putdata(mapped)
    return result


def sprite_crop(source: Image.Image) -> tuple[Image.Image, tuple[int, ...]]:
    rgba = source.convert("RGBA")
    mask = rgba.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("Monster source is empty after alpha threshold")
    return rgba.crop(bounds), bounds


def at_height(source: Image.Image, height: int) -> Image.Image:
    width = max(1, (source.width * height + source.height // 2) // source.height)
    return reduce_palette(source.resize((width, height), NEAREST))


def draw_code_porter() -> Image.Image:
    """Native 64px integer polygons, not tracing or sampling the painted art."""
    image = indexed((64, 64))
    d = ImageDraw.Draw(image)

    # Robe silhouette, feet and raised arm. Each shape is editable source.
    d.polygon([(14, 22), (26, 20), (44, 26), (55, 36), (49, 46),
               (56, 56), (45, 58), (37, 56), (24, 60), (11, 57),
               (15, 44), (8, 32)], fill=1)
    d.polygon([(17, 51), (28, 53), (27, 62), (12, 63), (10, 60)], fill=2)
    d.polygon([(40, 51), (49, 53), (56, 59), (54, 62), (38, 61)], fill=2)
    d.polygon([(16, 55), (25, 55), (23, 61), (12, 61)], fill=5)
    d.polygon([(40, 55), (46, 55), (52, 60), (40, 59)], fill=5)
    d.line([(14, 59), (20, 58), (23, 59)], fill=7)
    d.line([(42, 57), (47, 58), (48, 59)], fill=7)
    d.polygon([(15, 24), (25, 23), (40, 29), (50, 35), (45, 44),
               (50, 55), (40, 53), (30, 57), (16, 55), (20, 40),
               (11, 32)], fill=12)
    d.polygon([(19, 27), (29, 30), (39, 29), (44, 34), (33, 39),
               (20, 34), (12, 30)], fill=14)
    d.polygon([(20, 31), (31, 35), (39, 32), (34, 37), (27, 36)], fill=16)
    d.polygon([(21, 37), (26, 40), (20, 52), (29, 50), (25, 56),
               (16, 55)], fill=13)
    d.polygon([(35, 39), (40, 39), (43, 51), (48, 54), (39, 51)], fill=11)
    d.line([(24, 42), (34, 44), (43, 41)], fill=27, width=2)
    d.line([(26, 42), (33, 43), (39, 42)], fill=29)
    d.polygon([(30, 45), (33, 45), (30, 53), (28, 51)], fill=15)

    # Big bent stone arm and fist, separated from the bell by negative space.
    d.polygon([(8, 30), (1, 24), (1, 16), (7, 8), (8, 3),
               (12, 0), (19, 0), (23, 4), (22, 10), (15, 14),
               (13, 23), (15, 29)], fill=1)
    d.polygon([(8, 27), (3, 23), (4, 16), (10, 10), (11, 4),
               (14, 2), (18, 2), (21, 5), (19, 9), (13, 12),
               (11, 22)], fill=5)
    d.polygon([(5, 20), (6, 16), (13, 9), (15, 5), (19, 5),
               (18, 8), (11, 14), (9, 22)], fill=7)
    d.line([(12, 4), (13, 7), (16, 8)], fill=3)
    d.line([(17, 2), (17, 5), (20, 6)], fill=3)
    d.line([(7, 24), (11, 25), (12, 22)], fill=4)

    # Lower stone arm. A neutral pose would be a separate hand-edited source.
    d.polygon([(47, 32), (53, 32), (60, 40), (63, 46), (60, 51),
               (56, 51), (54, 47), (49, 46), (45, 39)], fill=1)
    d.polygon([(49, 34), (53, 35), (58, 41), (61, 46), (59, 49),
               (56, 45), (51, 44), (48, 39)], fill=5)
    d.polygon([(49, 35), (52, 35), (56, 41), (52, 41), (49, 38)], fill=7)
    d.line([(57, 43), (56, 46)], fill=3)
    d.line([(60, 45), (58, 48)], fill=3)

    # Bronze bell crown, conical shell and hollow lip.
    d.polygon([(31, 9), (31, 5), (40, 5), (43, 10), (41, 14),
               (45, 17), (47, 27), (51, 30), (51, 35), (45, 39),
               (30, 36), (23, 32), (24, 28), (28, 16)], fill=1)
    d.polygon([(33, 10), (33, 7), (39, 7), (40, 10), (38, 12)], fill=23)
    d.rectangle((35, 8, 37, 11), fill=18)
    d.polygon([(30, 15), (35, 12), (41, 14), (44, 18), (46, 28),
               (49, 30), (43, 34), (27, 30)], fill=22)
    d.polygon([(31, 16), (36, 14), (40, 16), (42, 27), (34, 29),
               (28, 28)], fill=24)
    d.polygon([(34, 16), (36, 16), (38, 27), (35, 28)], fill=26)
    d.polygon([(41, 18), (43, 20), (45, 29), (42, 30)], fill=20)
    d.line([(29, 19), (35, 17), (43, 20)], fill=27)
    d.line([(28, 27), (36, 26), (45, 29)], fill=25)
    d.ellipse((24, 28, 50, 38), fill=23)
    d.ellipse((26, 29, 48, 36), fill=18)
    d.ellipse((27, 29, 46, 34), fill=1)
    d.line([(28, 35), (36, 37), (45, 36)], fill=25)
    d.point((44, 22), fill=13)
    d.line([(29, 23), (30, 25)], fill=14)
    d.line([(41, 15), (43, 17)], fill=13)
    return image


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=False, transparency=0)


def contact_sheet(assets: dict[str, Image.Image]) -> Image.Image:
    canvas = indexed((640, 400), 1)
    d = ImageDraw.Draw(canvas)
    d.fontmode = "1"  # VETKA is rendered as binary pixels, no extra colours.
    font = ImageFont.truetype(str(ROOT / "assets/font/vetka.ttf"), 16)

    def text(x: int, y: int, label: str, colour: int = 9) -> None:
        d.text((x, y), label, font=font, fill=colour)

    def put(image: Image.Image, x: int, y: int) -> None:
        mask = image.convert("RGBA").getchannel("A")
        canvas.paste(image, (x, y), mask)

    def stage(x: int, y: int, width: int, height: int) -> None:
        d.rectangle((x, y, x + width - 1, y + height - 1), fill=2, outline=4)
        d.line((x + 2, y + height - 7, x + width - 3, y + height - 7), fill=3)

    text(12, 8, "UNDERCROFT / ART SPIKE", 10)
    text(12, 29, "31 OPAQUE INKS + ALPHA / ALL RESIZES NEAREST", 7)
    for x, height in [(120, 64), (228, 40), (336, 24)]:
        text(x + 15, 56, f"{height} PX")
    text(464, 56, "PAINT SOURCE", 16)
    text(12, 104, "PAINTED", 25)
    text(12, 192, "CODE", 16)
    for kind, top in [("painted", 78), ("code", 166)]:
        for x, height in [(120, 64), (228, 40), (336, 24)]:
            stage(x, top, 92, 78)
            image = assets[f"bell_porter_{kind}_h{height}"]
            put(image, x + (92 - image.width) // 2, top + 71 - image.height)

    # Source preview is also reduced to the same palette; originals stay intact.
    raw, _ = sprite_crop(Image.open(SOURCES / "bell_porter_painted.png"))
    preview = at_height(raw, 154)
    stage(456, 78, 172, 166)
    put(preview, 456 + (172 - preview.width) // 2, 83)

    d.line((12, 257, 628, 257), fill=4)
    text(12, 266, "STONE 64 X 64", 10)
    text(176, 266, "REPEAT CHECK", 7)
    text(352, 266, "FINDER 32", 10)
    text(488, 266, "PALETTE", 10)
    put(assets["stone_wall_64"], 12, 292)
    for x in (176, 240):
        for y in (289, 353):
            # Bottom part is deliberately cropped by its panel below.
            if y == 353:
                tile = assets["stone_wall_64"].crop((0, 0, 64, 32))
            else:
                tile = assets["stone_wall_64"]
            put(tile, x, y)
    put(assets["finder_portrait_32"], 352, 294)
    portrait_2x = assets["finder_portrait_32"].resize((64, 64), NEAREST)
    put(portrait_2x, 400, 294)
    text(352, 365, "1X + 2X", 7)

    for i in range(32):
        x, y = 488 + (i % 8) * 16, 294 + (i // 8) * 16
        d.rectangle((x, y, x + 13, y + 13), fill=i if i else 2)
        if i == 0:
            d.line((x, y, x + 13, y + 13), fill=10)
    text(488, 365, "0 = CLEAR", 7)
    text(12, 370, "4X SHEET", 7)
    return canvas


def main() -> None:
    SOURCES.mkdir(exist_ok=True)
    RESULTS.mkdir(exist_ok=True)
    painted, bounds = sprite_crop(Image.open(SOURCES / "bell_porter_painted.png"))
    code = draw_code_porter()
    save_png(code, SOURCES / "bell_porter_code_64.png")
    assets = {}
    for kind, source in [("painted", painted), ("code", code)]:
        for height in (64, 40, 24):
            assets[f"bell_porter_{kind}_h{height}"] = at_height(source, height)
    assets["stone_wall_64"] = reduce_palette(
        Image.open(SOURCES / "stone_wall_painted.png").resize((64, 64), NEAREST)
    )
    assets["finder_portrait_32"] = reduce_palette(
        Image.open(SOURCES / "finder_portrait_painted.png").resize((32, 32), NEAREST)
    )
    for name, asset in assets.items():
        save_png(asset, RESULTS / f"{name}.png")
    sheet = contact_sheet(assets)
    save_png(sheet, BASE / "contact_sheet_native.png")
    save_png(sheet.resize((2560, 1600), NEAREST), BASE / "contact_sheet_4x.png")
    palette_text = "GIMP Palette\nName: Undercroft Spike (0 transparent)\nColumns: 8\n#\n"
    palette_text += "\n".join(
        f"{r:3} {g:3} {b:3}  {i:02d} #{HEX[i]}"
        for i, (r, g, b) in enumerate(RGB)
    ) + "\n"
    (BASE / "palette.gpl").write_text(palette_text, encoding="utf-8")

    files = sorted(SOURCES.glob("*.png")) + sorted(RESULTS.glob("*.png"))
    files += [BASE / "contact_sheet_native.png", BASE / "contact_sheet_4x.png"]
    records = []
    union = set()
    for path in files:
        with Image.open(path) as image:
            colours = set(image.convert("RGBA").getdata())
            is_source_painting = path.parent == SOURCES and "painted" in path.stem
            if not is_source_painting:
                assert image.mode == "P", path
                assert image.getpalette() == PALETTE, path
                assert image.info.get("transparency") == 0, path
                assert max(image.getdata()) < 32, path
                assert len(colours) <= 32, path
                assert {a for _, _, _, a in colours} <= {0, 255}, path
                union |= colours
            records.append({
                "path": path.relative_to(BASE).as_posix(),
                "size": list(image.size),
                "mode": image.mode,
                "colours_rgba": len(colours),
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            })
    assert len(union) <= 32
    with Image.open(BASE / "contact_sheet_4x.png") as enlarged:
        assert enlarged.tobytes() == sheet.resize((2560, 1600), NEAREST).tobytes()
    for kind in ("painted", "code"):
        for height in (64, 40, 24):
            sprite = assets[f"bell_porter_{kind}_h{height}"]
            assert sprite.height == height
            assert sprite.convert("RGBA").getchannel("A").getbbox() is not None
    manifest = {
        "pipeline": "build_spike.py / offline Pillow",
        "pillow_version": pillow_version,
        "source_generation": "built-in image_gen.imagegen; see prompts.json",
        "resize": "NEAREST for every image resize including source reduction",
        "dither": "none",
        "alpha": "source preserved; derived sprites threshold at 128",
        "palette_entries": len(HEX),
        "opaque_palette_entries": 31,
        "union_derived_rgba_colours": len(union),
        "monster_source_crop_xyxy": list(bounds),
        "files": records,
    }
    (BASE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"assets": len(assets), "shared_rgba_colours": len(union),
                      "contact_sheet": "art_src/spike/contact_sheet_4x.png",
                      "validated": True}))


if __name__ == "__main__":
    main()
