"""Paint all verb icons on one sheet, then split it back into the game files.

    python art_src/ui_offer/verb_sheet/verb_sheet.py make    # files -> sheet
    python art_src/ui_offer/verb_sheet/verb_sheet.py split   # sheet -> files

The sheet is indexed with the icons' shared palette (index 0 transparent).
Each icon keeps its own canvas (12x12, or 6x12/8x12 for the compact
versions); slots sit on a 16 px grid, and anything painted outside a slot is
ignored. `split` only rewrites icons whose pixels changed.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
ICONS = ROOT / 'assets/art/ui_offer'
SHEET = HERE / 'verb_sheet.png'
LAYOUT = HERE / 'layout.json'
COLUMNS, PITCH, MARGIN = 6, 16, 2


def icon_names():
    names = sorted(p.stem[5:] for p in ICONS.glob('verb_*.png'))
    # Each compact version sits right after its full-size icon.
    return sorted(names, key=lambda n: (n.split('_compact')[0], '_compact' in n))


def make():
    names = icon_names()
    first = Image.open(ICONS / f'verb_{names[0]}.png')
    rows = (len(names) + COLUMNS - 1) // COLUMNS
    size = (MARGIN * 2 + COLUMNS * PITCH - (PITCH - 12), MARGIN * 2 + rows * PITCH - (PITCH - 12))
    sheet = Image.new('P', size, 0)
    sheet.putpalette(first.getpalette())
    layout = []
    for i, name in enumerate(names):
        icon = Image.open(ICONS / f'verb_{name}.png')
        assert icon.mode == 'P' and icon.getpalette() == first.getpalette(), name
        x, y = MARGIN + (i % COLUMNS) * PITCH, MARGIN + (i // COLUMNS) * PITCH
        sheet.paste(icon, (x, y))
        layout.append({'name': name, 'x': x, 'y': y, 'w': icon.width, 'h': icon.height})
    sheet.save(SHEET, transparency=0)
    LAYOUT.write_text(json.dumps(layout, indent=1) + '\n')
    guides(size, layout)
    print(f'{len(names)} icons -> {SHEET.relative_to(ROOT)}')


def guides(size, layout):
    """A slot-outline layer to put under the sheet, and a labelled 6x preview."""
    guide = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(guide)
    for slot in layout:
        draw.rectangle([slot['x'] - 1, slot['y'] - 1, slot['x'] + slot['w'], slot['y'] + slot['h']],
                       outline=(120, 120, 150, 255))
    guide.save(HERE / 'verb_sheet_guide.png')
    scale = 6
    preview = Image.new('RGBA', (size[0] * scale, size[1] * scale + 12), (30, 28, 40, 255))
    preview.alpha_composite(guide.resize((size[0] * scale, size[1] * scale), Image.NEAREST))
    art = Image.open(SHEET).convert('RGBA').resize((size[0] * scale, size[1] * scale), Image.NEAREST)
    preview.alpha_composite(art)
    draw = ImageDraw.Draw(preview)
    for slot in layout:
        label = slot['name'].replace('_compact', ' c')
        draw.text((slot['x'] * scale, (slot['y'] + slot['h']) * scale + 1), label, fill=(225, 212, 170, 255))
    preview.save(HERE / 'verb_sheet_labels_6x.png')


def split():
    sheet = Image.open(SHEET)
    if sheet.mode != 'P':
        sys.exit('The sheet must stay indexed (Aseprite: Sprite > Color Mode > Indexed).')
    changed = []
    for slot in json.loads(LAYOUT.read_text()):
        icon = sheet.crop((slot['x'], slot['y'], slot['x'] + slot['w'], slot['y'] + slot['h']))
        icon.putpalette(sheet.getpalette())
        path = ICONS / f"verb_{slot['name']}.png"
        old = Image.open(path)
        if old.mode == 'P' and list(old.getdata()) == list(icon.getdata()) and old.getpalette() == icon.getpalette():
            continue
        icon.save(path, transparency=0)
        changed.append(path.name)
    print(f'{len(changed)} icons updated' + (': ' + ', '.join(changed) if changed else ''))


if __name__ == '__main__':
    {'make': make, 'split': split}[sys.argv[1] if len(sys.argv) > 1 else 'make']()
