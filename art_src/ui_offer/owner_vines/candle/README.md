# The owner's candle

The candle now lives in `assets/art/ui/owner_candle.png`: **14 x 17 px**, two
**7 x 17** frames side by side. Draw one frame at **(147,155)**, above the
candle-free `assets/art/ui/owner_vines.png`. Use nearest filtering and the
overlay's existing visibility rules. Suggested gentle loop: frame 0 for
430 ms, frame 1 for 270 ms. A wires the two atlas regions in `layout.json`.

To keep painting the overlay, start from
`../templates/screen_154x342_no_candle.png`. Keep the candle off that layer;
in Aseprite it can live on a separate hidden layer for reference. Export the
overlay to `assets/art/ui/owner_vines.png`. To repaint the flame, edit the
two cells of `owner_candle.png` directly. The wick and wax are identical in
both cells. The original `.ase` and `_done.png` have not been changed.

`corner_sheet_12x.png` shows **ORIG / CUT / F0 / F1**; F0 and F1 are isolated
on the checkerboard. `full_screen_pair_3x.png` shows both full overlays with
their candle composited. All enlargements are exact nearest-neighbour.
`source_original.png` is a byte-identical backup of the owner's finished PNG.

Run `python -B art_src/ui_offer/owner_vines/candle/build_candle.py --check`
from the repo root. The check proves frame 0 reconstructs the original
exactly, with **zero differing pixels**. Only the flame box
**x148–153, y155–160** (right/bottom exclusive: `[148,155,154,161]`) may differ
between frames. The patched edge is entirely beneath the original candle's
opaque pixels; the wick, wax, palette and binary alpha are checked too.
`verification.json` lists every changed coordinate.

`--build` reproduces this particular handoff from the saved original and
hand-placed pixel rows. Use it only to reproduce this cut: it overwrites the
runtime overlay and strip, so it would replace later painting. Future owner
edits will intentionally stop the original-reconstruction comparison being
a zero-difference test; retain this source backup as the extraction receipt.
