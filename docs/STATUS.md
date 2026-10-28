# Status and handoff

Where the project stands, who is doing what, and how we work. Claude keeps this
current so that any session (or a reader catching up) can pick up the thread.
Last updated 29 October 2026, shortly after midnight.

## Where we are

UNDERCROFT is a playable two-floor run on the owner's Pixel 9a: down to the
Dawn Seal and home again, with the Bell Porter's lift, fire and webs, the Ash
Hound, the Wick Ghost, throwing, the Seal's reveal and a hidden cache. The
owner has played it many times on the phone ("this is actually awesome ...
crunchy pixel art vibes really give King's Field") and **save, full close,
reopen and Continue is verified on the device**.

Latest verified and pushed milestone: **M3f** (`5810909`). Latest phone build:
`build/Undercroft-M3f.apk` (the owner has played it). Later commits are art
batches, an audit and settings, none needing a new APK on their own.

The owner's verdicts that steer what comes next:

- **Too easy and short**: about six minutes, no food used. A third, harder
  floor and tuning are being designed now (M4a).
- They love the painted, aged, "dirty dungeon" look, two or three frames per
  moving thing, the glass health vial, the dark background behind the bottom
  controls, optional branches that are **easy to miss**, sneaky but fair
  encounters, and the 1990s jank of tossing a torch at a web.
- Long-term dream (later slices, not now): "a dense 10-floor-deep difficult
  crawler where you barely survive", with more content variety.

## The workers

All are persistent Codex threads. Thread IDs and the exact resume command are
in Claude's memory (`codex-collaboration`). Workers never commit; Claude
verifies, commits with explicit paths and pushes.

| Worker | Owns | State at this update |
| --- | --- | --- |
| **A**: game code | `scripts/` (except dev, fx, audio/music), `scenes/`, `data/` (except music/text), tests except `tests/qa/`, DESIGN/CONTRACT/ARCHITECTURE, `M*_RESULTS.md` | **M4a delivered, awaiting Claude's review** (reply in the session scratchpad `codex_m4a_reply.md`; results in `docs/M4A_RESULTS.md`): owner fixes (the brazier lights from a tap with a torch, the web burns from a lit torch held or equipped, travel faces never say "blocked"), B's world item sprites, and `docs/proposals/M4_DEPTH.md` (third floor and difficulty) plus its safe implementation |
| **B**: creatures, fixtures, music | `art_src/{anim,fx,creatures,fixtures,hands,items,music}`, matching `assets/art/` folders, `data/music/`, `scripts/audio/music.gd`, `docs/ART.md`, `docs/MUSIC.md` | **Running**: painted repaint of the remaining pixel-drawn fixtures (plate, side levers, web, cord grate, underfoot lift and stair ground, opened cache recess, spent-coat icon) |
| **C**: environment, screens, UI art, manual | `art_src/{env,icons,screens,portrait,props,ui_offer}`, matching `assets/art/` folders, `scripts/fx/`, `data/text/`, `docs/MANUAL.md`, `POLISH.md`, `ENV_ART.md` | Idle. Last: painted wall dressings `dressing_v2`, ivy v4 (backup vines) |
| **D**: QA | `tests/qa/`, `docs/QA_REPORT.md`, `docs/ART_AUDIT.md` | Idle. Last: placeholder-art audit. Re-sweep after M4a lands |
| **Claude** | `project.godot`, `export_presets.cfg`, `assets/icon/`, `scripts/dev/` (autopilot, pointer), `docs/BRIEF.md`, `COLLAB_LOG.md`, this file, Git, builds, phone | Orchestrating |

The owner also paints: a hand-made 154 x 342 **vine overlay** in progress in
`art_src/ui_offer/owner_vines/` (Aseprite `.ase` files may be committed; the
repo is private). A's overlay layer is ready and empty. Rules: draw it above
the chrome and above the compass needle, below cards, modals and the map.

## Queue for Codex A's next turn (after M4a)

1. **Wire C's painted `dressing_v2`** (`docs/ENV_ART.md`): the `_v2` dressing
   paths and sconce prewarm paths; the closed lock uses `painted_fN_door_v2`;
   an opened lock draws `painted_fN_door_open_overlay_v2` through the portal
   path (no more borrowed portcullis art).
2. **Act on D's `docs/ART_AUDIT.md`**: wire painted assets that exist but
   aren't used (head-on lever faces, the ember Hound glow layers at about 0.85
   gain, room landmark floor/ceiling faces), then B's repainted fixtures when
   they land. Keep the intentional code visuals: map ink, digits, glints,
   lanes, arrows, compass.
3. **The owner's vine overlay**, when the owner delivers it.
4. Whatever M4a leaves as a proposal, after Claude reviews `M4_DEPTH.md`.

Claude disabled Godot's stock boot image (`b4d6719`), so the LOST MOTH splash
comes first.

## Ideas parked for later slices

- A sealed arch that hides something, found by striking it with a HEAVY item.
- The ten-floor "barely survive" crawler; more creatures, more owners whose
  returned things repair the dungeon (a miller's hand restarts a waterwheel,
  a knight's name turns a patrol into an escort).
- C's costed list of small delights in `docs/POLISH.md`.

## How Claude verifies and ships

- Read the worker's reply and its screenshot sheet, then rerun its scripts
  (latest: `tests/run_m3f_checks.ps1`, `tests/run_m3f_pilots.ps1`) and D's
  `tests/qa/run.ps1`. Pilots are muted unless `--with-sound`, and pilots hide
  the desktop pointer unless `--show-pointer`.
- Commit only verified work, with explicit paths (another worker may be
  mid-turn), credit the authors, push to `origin main`.
- Build the APK from a **clean detached worktree** at the commit (so nobody's
  half-written files leak in): `--import`, then
  `--export-debug "Android" build/DungeonCrawler.apk`, then copy it to
  `build/Undercroft-<milestone>.apk`. Install with
  `adb -s 55141JEBF03084 install -r` when the phone is connected.
- Owner feedback goes first in the next turn, in the owner's words, with
  screenshots taken from the phone (`adb exec-out screencap -p`).
- A worker turn that ends with "Selected model is at capacity" is a transient
  Codex bug: wait about 30 seconds and resume the same thread.
