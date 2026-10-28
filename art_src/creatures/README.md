# Ash Hound and Wick Ghost

Original three-pose source sheets are preserved in `sources/`.
Exact built-in imagegen prompts: [../anim/prompts.json](../anim/prompts.json).
Rebuild both with `python art_src/anim/build_creatures.py` from the repo root.
The common pipeline and dependencies are documented in
[../anim/README.md](../anim/README.md).

Review `ash_hound_contact_4x.png` and `wick_ghost_contact_4x.png`; each includes
all three poses at 64, 40 and 24 px height. Manifests contain every file,
source hash, extraction bound, output size and bottom-centre anchor.
The Hound's wide crouch and Ghost's raised sleeves deliberately use wider
canvases. Keep the complete canvas and aspect ratio when switching poses.
