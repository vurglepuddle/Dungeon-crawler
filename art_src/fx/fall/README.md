# The Fall: crumble frames

The game plays three transparent overlays over the 148x150 dungeon view when
the Finder takes the Dawn Seal:

- `assets/art/fx/fall_crumble_0.png`: cracks spread;
- `assets/art/fx/fall_crumble_1.png`: the floor splits;
- `assets/art/fx/fall_crumble_2.png`: the floor is gone.

The order and timing (0.7 s each) live in `data/presentation/fall.json`. The
overlays shake with the view, so a painted hole moves with the floor.

**The owner is giving these frames a human pass (29 October 2026).** Edit the
runtime PNGs directly. `build_fall.py` would overwrite them, so don't rerun it
without carrying the owner's pixels over.
