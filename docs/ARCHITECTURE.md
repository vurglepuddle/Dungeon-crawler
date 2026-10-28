# M1 architecture

The sim decides a turn; the scene makes its result visible. Rules are plain
RefCounted GDScript and do not depend on nodes, frame timing, input or files.
See [CONTRACT](CONTRACT.md) for concrete shapes and [DESIGN](DESIGN.md) for scope.

`scripts/gen/floor_gen.gd` constructs a small connected grid using a specified
seed hash/PRNG. `scripts/sim/dungeon_sim.gd` owns items, gates, combat and turn
resolution. `scripts/gen/witness.gd` walks the generated definition through
that same resolver and must win without damage before the app accepts it.
The witness is not a player hint. There is no search framework or fallback
library in M1: construction is bounded, and failures are explicit.

`scripts/app/main.gd` is the scene controller/UI: named Button controls become
commands, committed results replace its snapshot and briefly gate input.
No buffered clicks, repeat-walking or animation-driven rules. Selection is
a reference into the pack. Shared rule queries determine marked PLACE targets
and the verb strip. `scripts/view/dungeon_view.gd` renders a grid frustum with
integer perspective surfaces and occlusion, plus sprite/fixture positions.
Wall patches are nearest-sampled into cached textures at load; there is no
3D scene or runtime Python dependency. Game PNGs are copies in assets/art;
editable sources and the art experiment stay in art_src.

Data flows: seed -> generated floor -> real-rule witness -> live sim ->
snapshot/ordered events -> UI/view -> touch command -> sim. The controller
owns the short animation gate, and the sim owns revision/beat ordering.
VETKA remains 16 px at every text surface. Renderer coordinates and the
named-control lookup are logical pixels independent of window scale.

`scripts/dev/autopilot.gd` (Claude) drives the real input path through the
scene's pilot_call boundary. Headless tests separately exercise rules,
generation, deterministic replay and hundreds of complete seed witnesses.
Windowed screenshots validate actual controls and drawing; Android comfort
and interruption behaviour require Claude/the owner's phone test.

No persistence or audio in M1. M2 will add a persistence module outside the
sim, with versioned JSON under user:// and staged/backup recovery. Later
content tables and additional floors extend this small boundary when needed.
