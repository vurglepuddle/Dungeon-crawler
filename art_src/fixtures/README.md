# M3c fixtures and readable states

Original bases: built-in `image_gen.imagegen` with real alpha. Exact prompts
are in [prompts.json](prompts.json). The cold brazier, unlit reed bundle and
Dawn Seal paintings are preserved in `sources/`; the Torch draft and selected
source are identical preserved copies. Their apparent source-image halo is
fully transparent outside the reeds and is absent in the reduced asset.
No API fallback, external art, samples or downloads were used.

```powershell
python -B art_src/fixtures/build_m3c.py
python -B art_src/creatures/build_ember_hound.py
python -B art_src/anim/verify_art.py
```

Fixtures require Python/Pillow. The Hound lighting edit also uses the existing
NumPy/SciPy splitter. All runtime colours and alpha use the original shared
palette and binary-alpha contract. Painted bases are cropped at alpha >=128,
fitted once to a fixed near canvas, then sampled at distance with NEAREST.
Fire is drawn as two editable integer polygon variants over ONE base, so the
bowl/torch never moves with the flame. Torch has one continuous pale reed
drawn at native size to retain the shaft when reduced. The Seal pulse changes
only inner-disc inks, with identical alpha, base and silhouette.

Web silk, cord/grate, scored glyphs and 16x16 icons are original integer pixel
drawings. Web and grate are redrawn on each native distance grid so the vital
threads/cords remain at least one pixel wide, rather than disappearing under
sampling. Only the two burning states animate; intact/burnt are fixed states.
The side grate is a discrete nearest-sampled skew, supplied both left/right.

Panel bases are frozen copies of C's `assets/art/env/f1_plain_0.png` and
`f2_plain_0.png`. Builds read the frozen copies, not C's live files. The first
and last two rows/columns of these 64x64 wall tiles are unchanged. Plain has a
scored dawn glyph; revealed has a faint mint/gold version. Transparent glyph
overlays allow another masonry family to share the mark. These are wall UV
textures, not billboard floor objects.

`manifest.json` lists every output, size, anchor, purpose, timing, source hash,
strip frame count and state order. Exact anchors/depth selection, review
sheets, animation timing and integration are in [ART.md](../../docs/ART.md).
The builders do not start Godot; the game needs neither Python nor a network.

## Hound lighting edit

`art_src/creatures/sources/ash_hound_ember_sheet.png` is a lighting-only edit of
the first batch's saved Hound sheet. Prompt/reference metadata lives here in
`prompts.json`. The new derivative prefix is `ash_hound_ember`; accepted old
files are preserved. The companion `ash_hound_ember_glow_*` files retain only
the hottest amber inks and share each pose's exact canvas. They are optional
colour overlays for drawing after lamp tint, not extra animation frames.
The lamp-comparison sheet includes an approximate 35% body / 85% glow pass,
re-quantized to the palette for review. It is not an engine screenshot.
