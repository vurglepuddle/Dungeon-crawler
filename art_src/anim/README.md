# Codex B: painted poses

Sources were made with the built-in `image_gen.imagegen` tool using real alpha.
Exact prompts, reference roles/paths and source locations: [prompts.json](prompts.json).
The source PNGs are preserved; no external art or API fallback was used.
Husk, Hound and Ghost each came from ONE three-pose source sheet. The restored
Porter was made with the old full-size Porter as an identity reference.

From the repository root, with local Python, Pillow, NumPy and SciPy:

```powershell
python art_src/anim/build_creatures.py
python art_src/fx/build_fx.py
python art_src/fx/build_fixtures.py
python art_src/anim/verify_art.py
```

The generator is not rerun by these scripts. Builds from saved source pixels
are deterministic and offline. `pipeline.py` reads the existing shared palette;
it never rewrites it or the old root-level game PNGs. No Python is used by the game.

`build_creatures.py` splits alpha-connected characters, associates detached
cloth fragments, and discards alpha flecks smaller than 32 SOURCE pixels.
This avoids the Hound's long tail leaking across a nominal sheet column.
It uses one scale per character set and a common bottom baseline, then maps to
31 opaque palette entries plus transparent index zero with the original
weighted RGB distance. Reduced alpha is binary. The 40/24 px poses are exact
nearest-neighbour derivatives of registered 64 px frames; crouches remain lower.
Porter uses the old waiting sprite's exact canvas size at each distance.

The per-set manifests record source SHA-256, extraction bounds, output hashes,
sizes and anchors. `verify_art.py` also checks strips against individual frames,
palette indices and tables, binary alpha and every exact 4x contact enlargement.

Optional owner-converter comparison:

```powershell
python art_src/anim/compare_reduction.py
```

The default executable is the owner's `E:/SD/Raster_to_Pixel/target/release/raster_to_pixel.exe`;
use `--converter <path>` elsewhere. It compares `--cell detail --alpha-mode binary
--cleanup conservative --palette art_src/spike/palette.gpl` with the same cropped
wind-up under plain nearest reduction. The shipping frames retain nearest:
its harder stone-fist and cloth boundaries suit the established sprites.
The alternate is review material only. See [ART.md](../../docs/ART.md) for wiring.
