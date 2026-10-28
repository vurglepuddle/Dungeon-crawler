# Painted pack icons: r10 silhouette revision

Current set: eight accepted r9 icons, seven revised state PNGs and one optional
club alternate. All are static 16x16, shared palette/binary alpha, centre (8,8).
No C-owned icon, world sprite, launcher asset or UI source is written.

```powershell
python -B art_src/items/build_pack_icons.py
python -B art_src/items/verify_pack_icons.py
python -B art_src/items/pack_icons/r10/verify.py
```

The default builder dispatches to `r10/build.py`, which writes only the seven
requested revisions and `assets/art/items/icon_club_16_alt.png`. Accepted
stone, bone, bread, clapper, lamp, key, tonic and the normal club are untouched.
Pillow/numpy/scipy are authoring dependencies only; there is no runtime Python.

The original fifteen r9 runtime PNGs, original manifest/verification and the
original builder snapshot are frozen in `r9/`. Its snapshot is an archival
record, not a current executable entry point. The old comparison PNGs in this
directory remain r9 history. Current comparison pairs are in `r10/`:

- `icons_r9_r10_context_4x.png`: each revision on real leather and slate,
  r9/r10 side by side; includes the optional club.
- `icons_r9_r10_pack_4x.png`: whole native eight-slot strips plus the accepted
  neighbours. Regular club remains the accepted version in this set.
- `icons_r9_r10_card_4x.png`: the same family on actual slate card material.
- `icons_r10_silhouettes_4x.png`: shape coverage beside the coloured revisions.
- `seal_launcher_match_4x.png`: approved 46px launcher disc beside r9/r10 Seal.

Every 4x sheet has a native partner and uses exact nearest enlargement. Slate
panels group icons for review; they do not propose a new game-card layout.
There was no Godot run or new image generation.

R10 follows the owner's pixel-art review: larger continuous silhouettes,
clean dark edges and a few material colour clusters. Knife steel, aqua glass,
teal quilting, leather/brass and straw retain their painted-material ramps.
Both coats use exactly the old readable garment coverage, with two grouped
tears in the spent state. Reeds share their body below the compact bright
flame. The Seal uses **the actual launcher source**,
`art_src/icon/dawn_seal_disc_46.png`, area-reduced by material with a quiet gold
ring/rays, teal gaps and bright arch core; the source is read-only.

`manifest.json` describes the current base set. `r10/manifest.json` records
the eight writes, optional status and accepted-file hashes. Verification
checks the r9 archive byte hashes, accepted files unchanged, source/output
hashes, palette/alpha/anchors, continuous silhouettes, shared coat coverage,
registered torch body and exact review enlargement. Colour/coverage counts
are review evidence, not a substitute for the owner's visual judgement.

See `docs/ART.md`, **R10: owner silhouette review**, for the unchanged runtime
paths/state lookup and optional club path. Leave the normal club selected
unless the alternate is explicitly chosen.
