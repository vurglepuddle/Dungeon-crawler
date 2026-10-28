# Undercroft art pipeline spike

28 October 2026. Isolated source experiment; none of these files are wired into
the game. Start with **[contact_sheet_4x.png](contact_sheet_4x.png)**. It is a
2560 x 1600 PNG made by exact 4x nearest-neighbour enlargement of the committed
640 x 400 [native sheet](contact_sheet_native.png). Labels use VETKA at 16 px.

## What was generated and what was drawn

Three independent **built-in `image_gen.imagegen`** requests produced original
1254 x 1254 painted source images. The exact prompts and tool/mode are recorded
in [prompts.json](prompts.json). No downloaded art, image CLI or API key was used.
The tool calls used actual transparency for the monster and opaque backgrounds
for the wall and portrait. Original bytes and source alpha remain intact here:

- [Bell Porter source](sources/bell_porter_painted.png): bronze bell head,
  raised stone fist and teal robe, RGBA.
- [Stone wall source](sources/stone_wall_painted.png): flat masonry, RGB.
- [Finder portrait source](sources/finder_portrait_painted.png): hooded Finder,
  RGB, made as a large source for reduction to 32 x 32.

The comparison monster is drawn with integer polygons directly at 64 x 64 in
`draw_code_porter()` in [build_spike.py](build_spike.py), with an exported
[native source](sources/bell_porter_code_64.png). It shares the character brief
and palette; it does not trace or sample the generated image. It is a quick
code-art comparator, not an equal production-time contest with the painted art.

## Target assets

| Asset | Size / path |
| --- | --- |
| Painted monster, near | 61 x 64, `results/bell_porter_painted_h64.png` |
| Painted monster, middle | 38 x 40, `results/bell_porter_painted_h40.png` |
| Painted monster, far | 23 x 24, `results/bell_porter_painted_h24.png` |
| Code monster, near | 64 x 64, `results/bell_porter_code_h64.png` |
| Code monster, middle | 40 x 40, `results/bell_porter_code_h40.png` |
| Code monster, far | 24 x 24, `results/bell_porter_code_h24.png` |
| Wall | 64 x 64, `results/stone_wall_64.png` |
| Hero portrait | 32 x 32, `results/finder_portrait_32.png` |

Distances are size variants of the **same pose/source**, not three unrelated
generated monsters. This preserves silhouette and identity. No attack/idle
animation set has been made. The larger “PAINT SOURCE” thumbnail on the sheet
is also palette-reduced, for comparison; the actual high-resolution original
is the untouched source PNG linked above. The portrait appears at 1x and 2x
within the native sheet. All assets on the sheet share the same palette.

## Exact reduction pipeline

Run from the repository root:

```powershell
python art_src/spike/build_spike.py
```

The local environment used Python 3.12.8 and Pillow 11.1.0. These are **offline
authoring tools only**; the Godot game gets no Python or service dependency.
The script reads the three committed source PNGs and the existing VETKA font,
then recreates every derived PNG, the code source, palette and manifest.

1. Find the painted monster's bounding rectangle at alpha >= 128 and crop it.
   Preserve its aspect ratio, rounding width to nearest integer at each height.
2. Resize directly from the cropped source to 64, 40 and 24 px height using
   `Image.Resampling.NEAREST`. Resize the wall and portrait directly to 64 x 64
   and 32 x 32 with the same sampler. Code variants resize from the native 64.
3. Map pixels to one fixed hand-chosen palette with deterministic weighted
   squared RGB distance (`2*R^2 + 4*G^2 + B^2`, measured as differences).
   There is **no dithering, filtering, blur or adaptive per-asset palette**.
4. Derived alpha is binary: < 128 becomes transparent index 0, otherwise an
   opaque palette colour. This prevents translucent fringe colours at runtime.
   The original RGBA image remains untouched for a later improved cutout.
5. Write indexed PNGs with the same palette table and transparency index.
   Build the labelled sheet and enlarge it exactly 4x with nearest-neighbour.

[palette.gpl](palette.gpl) is editable in pixel-art tools. It has **32 entries:
31 opaque colours plus transparent index 0**. This is a global limit, not
32 colours for each asset. The combined derived assets, code source and sheets
use exactly 32 distinct RGBA values including transparency. The painted sources
are intentionally unrestricted and do not count as reduced output.

[manifest.json](manifest.json) records sizes, modes, actual colour counts,
SHA-256 hashes, crop bounds and Pillow version. The build validates palette
equality, index limits, binary alpha, target heights, nonempty sprites and exact
nearest-neighbour 4x enlargement. Two consecutive builds were compared by file
hash to check local reproducibility. No game test or phone playtest is implied.

## What the comparison shows

**Recommend hybrid, with manual pixel cleanup after reduction.** The generated
Porter has a convincing illustrated silhouette and useful material/colour
separation at 64 px. It still reads as a raised fist and bell at 40 px. At
24 px it is recognisable, but robe highlights turn into scattered pixels and
the bell opening is weak. The code version has fewer stray pixels and a much
stronger black bell opening at that distance. That matters for combat tells.

The 32 px portrait retains a face, eyes and hood; it is a useful starting point,
though facial expression deserves a deliberate pixel edit before acceptance.
The wall retains convincing large blocks, but direct nearest sampling carries
too much painted speckle into 64 px. The repeated patch on the sheet also
reveals that the source is **not a production seamless tile**: mortar courses
do not join perfectly across boundaries. Treat it as a front wall panel until
edge cleanup and a quieter shade pass are approved. A nice source is not a
finished wall atlas.

Next art milestone, after the playable: quiet the wall texture, preserve one
large bell void in each distance sprite, and hand-author a neutral/recovery
pose using the approved source. Test against the actual perspective background
and at the phone's scale. This spike has no in-game occlusion, movement or
animation acceptance yet. Code-drawn UI, 16 px item icons and threat symbols
should remain deliberately simple. Generated paintings are useful sources,
not a reason to surrender control over the final pixels.
