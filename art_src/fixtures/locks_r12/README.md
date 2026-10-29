# R12: family-registered lock plates

Twelve transparent64x64 wall-UV overlays: four painted door families times
iron/bronze/gold. The keyhole coordinates are f1(31,41), f2-f4(32,40).
Offsets are already baked into each face, so A draws every overlay atUV(0,0).

Build via `python -B art_src/items/keys_r12/build_keys.py` from the repository
root. This shares the key's accepted painted metal patch and native ramps.
No existing door, wall, fixture, Fall or hand asset is written.

Compose with the matching `painted_fF_door_v2.png` before wall-column sampling;
use the same light modulation as the door. Hide the plate on open doors.
Choose F from the actual closed door's selected material family, including
per-block selection, rather than using the simulation floor number.

`layout.json` supplies every exact path, opaque bound and registration.
`contact_sheet_*` shows all four families and overlay-only insets.
`lock_doors_f1_*` through`lock_doors_f4_*` show each family's three metals at
64/40/24px; `lock_doors_all_*` combines those four proofs. Each has native and
exact4x nearest partners. These are offline wall-face composites, not Godot
captures and not a new screen layout. No animation or UI badge is baked in.
