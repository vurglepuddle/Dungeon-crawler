# Status and handoff

Where the project stands, who is doing what, and how we work. Claude keeps this
current so that any session (or a reader catching up) can pick up the thread.
Last updated 29 October 2026, about 2 a.m.

## Where we are

UNDERCROFT is a playable three-floor run on the owner's Pixel 9a: down to the
Dawn Seal and home again, with the Bell Porter's lift, fire and webs, the Ash
Hound, the Wick Ghost, throwing, the Seal's reveal and a hidden cache. The
owner has played it many times on the phone ("this is actually awesome ...
crunchy pixel art vibes really give King's Field") and **save, full close,
reopen and Continue is verified on the device**.

Latest verified and pushed milestone: **M4a** (`1da39f8`): a third floor, The
Lower Watch (harder blows: 2 HP, the Hound 3), plus the owner's brazier, web
and travel-face fixes and B's painted floor items. Then B's painted fixtures
v2 (`9d637ad`, not wired yet). Latest phone build:
`build/Undercroft-M4a-vines.apk` (M4a plus the owner's overlay), **built but not yet installed or played** (the
phone was not connected). The owner last played M3f.

The owner's verdicts that steer what comes next:

- **Too easy and short**: about six minutes, no food used. M4a answers with a
  third floor; bots take 84-146 turns (core) and 176-225 (full tour). No more
  depth tuning until the owner has played three floors.
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
| **A**: game code | `scripts/` (except dev, fx, audio/music), `scenes/`, `data/` (except music/text), tests except `tests/qa/`, DESIGN/CONTRACT/ARCHITECTURE, `M*_RESULTS.md` | **Running M4b**: wire C's `dressing_v2`, B's painted fixtures v2 (incl. world-cell lift/stair ground), the Hound glow and room landmarks, a required-asset guard, and a one-function floor-to-art mapping ready for floor three |
| **B**: creatures, fixtures, music | `art_src/{anim,fx,creatures,fixtures,hands,items,music}`, matching `assets/art/` folders, `data/music/`, `scripts/audio/music.gd`, `docs/ART.md`, `docs/MUSIC.md` | **Running r9**: a floor-three music piece and painted 16 px pack icons (`assets/art/items/icon_<kind>_16.png`) |
| **C**: environment, screens, UI art, manual | `art_src/{env,icons,screens,portrait,props,ui_offer}`, matching `assets/art/` folders, `scripts/fx/`, `data/text/`, `docs/MANUAL.md`, `POLISH.md`, `ENV_ART.md` | **Running r11**: a Lower Watch (`f3`) environment family and the manual updated for M4a |
| **D**: QA | `tests/qa/`, `docs/QA_REPORT.md`, `docs/ART_AUDIT.md` | **Running r3** in a clean worktree (session scratchpad `qa/`, at `9d637ad`): adversarial/softlock/save coverage of the three-floor m4.1 profile and measured difficulty. Claude copies its `tests/qa/` and QA_REPORT back |
| **Claude** | `project.godot`, `export_presets.cfg`, `assets/icon/`, `scripts/dev/` (autopilot, pointer), `docs/BRIEF.md`, `COLLAB_LOG.md`, this file, Git, builds, phone | Orchestrating |

The owner also paints: a hand-made 154 x 342 **vine overlay** in progress in
`art_src/ui_offer/owner_vines/` (Aseprite `.ase` files may be committed; the
repo is private). It is wired (`assets/art/ui/owner_vines.png`). Rules: draw it above
the chrome and above the compass needle, below cards, modals and the map.
**It stays visible while cards and menus are open; only the map hides it**
(owner, 29 Oct: the map "makes sense not to have the overlay, as it's
distracting"). Today's code hides it for cards and modals too: change that.

## Queue after this round

1. The owner plays `Undercroft-M4a.apk` (three floors); their verdict on
   length and difficulty steers any further depth work (see M4_DEPTH.md's
   "what I would cut").
2. A wires C's floor-three family, B's floor-three music and painted pack
   icons, and fixes anything D's deep sweep finds.
3. Done: **the owner's vine overlay** is wired (`90f6077`,
   `assets/art/ui/owner_vines.png`, source in
   `art_src/ui_offer/owner_vines/templates/`). Keep the frame and compass box
   pixel-exact under it. The owner: "the blue added a nice contrast".
4. **Bring the owner's overlay to life** (owner's request, 29 Oct). Change
   only these pixels; the rest of the owner's art stays exactly as painted.
   - **Candle flame, 2 frames.** The flame sits at about x148-152, y154-161
     (bottom-right of the view frame), with the candle below it from y162.
     C paints a second flame frame as a small patch that only moves the
     flame (`assets/art/ui/owner_vines_candle_1.png`; frame 0 is the owner's
     own). A swaps the two on a slow, slightly irregular beat.
   - **Eye glints, tiny and blue.** Each socket already holds one teal
     pixel (palette 15, `4c8585`):
     - bat-skull crest: (75,16) and (79,16);
     - top-left skull: (5,21) and (9,21);
     - bottom-left skull: (1,163) and (6,163);
     - compass hub skull: (116,337) and (119,337).

     **All four skulls glint** (owner confirmed).

     Now and then, at random and **pretty rare**, one socket flares
     15 -> 16 -> 17 -> 16 -> 15 (`73a29a`, `a8c2ad`) over about 0.3 s. Sometimes both sockets of one
     skull flare together ("ooo spooky"). Keep it rare enough to catch the
     eye, not a constant twinkle. Draw it in code over the overlay. It shows
     whenever the overlay shows (with cards and menus open too, not with the
     map open). Keep it out of the simulation and the pilots' pixel checks.

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
  (latest: `tests/run_m4a_checks.ps1`, `tests/run_m4a_pilots.ps1`) and D's
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
