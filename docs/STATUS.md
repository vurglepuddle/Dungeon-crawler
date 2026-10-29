# Status and handoff

Where the project stands, who is doing what, and how we work. Claude keeps this
current so that any session (or a reader catching up) can pick up the thread.
Last updated 29 October 2026, about 4 a.m., at the end of a 12-hour session.

## Where we are

UNDERCROFT is a playable **three-floor** run on the owner's Pixel 9a: down
through the Abbey Below and the Drowned Courses to the Lower Watch, take the
Dawn Seal, and bring it home. It has the Bell Porter's lift, fire and webs,
the Ash Hound, the Wick Ghost, throwing, the Seal's reveal and a hidden cache.
**Save, full close, reopen and Continue are verified on the device.**

Latest verified and pushed milestone: **M4c** (`ff8f956`), plus Claude's
small follow-ups up to `46bd50a`. Latest phone build:
`build/Undercroft-M4c.apk`, **installed on the phone** (29 Oct, ~3:50 a.m.).
The owner played M4c on desktop and phone tonight: "I love everything else!
Played through it again", "Loving the vibe of the game tho. JANK! (I freaking
love jank)", "THANK YOU SO MUCH, this is SOOOOO gooood".

What landed tonight, in order:

- **M4a** (`1da39f8`): third floor, the Lower Watch. Deep Husk/Ghost blows
  cost 2 HP, the Hound's lunge 3. The owner's brazier, web and travel-face
  fixes. B's painted floor items.
- **M4b** (`1c3f945`): the painted kit wired (C's `dressing_v2`, B's fixtures
  v2 including world-cell lift and stair ground, Hound embers, room
  landmarks), a required-asset guard (no silent code-art fallbacks), and one
  floor-to-art mapping.
- **M4c** (`ff8f956`): the owner's playtest notes.
  - Opened doors stay in their plane; effects are slower.
  - The owner's vines stay under cards and menus; only the map hides them.
  - Rare skull eye glints (`data/ui/overlay_glints.json`) and a two-frame
    candle sprite.
  - The Lower Watch's own art and music.
  - All painted pack icons.
  - An unrevealed cache gives only a puzzled message; once revealed, a blade
    in hand offers PRY. Capability verbs use the selection, then the hand.
- **The owner's vine overlay** (`90f6077`, then C cut the candle out:
  `3f17c33`).
- Claude's follow-ups:
  - hand animations slowed to 0.6 s per pose, 0.8 s for the ring, 0.3 s
    torch, 1.0 s Seal (`b5573da`);
  - a pointer crash fix (`00fe505`);
  - **no painted bevel on any surface** (`d478b5b`, `46bd50a`). The owner:
    the bevel's yellow/teal lines "look a bit weird and outdated now".
- D's deep-profile QA (`9d2c868`): no findings.
  - Careless bots die 59% of the time, all on floor three.
  - Greedy and never-guard bots win 256/256, with a median of 5 HP at the
    Seal.

The owner's standing verdicts:

- **Jank is welcome.** Busy painted art and imperfect details are fine ("90s
  games weren't perfect ... we can always change it later"). Flag a visual
  quirk once, then let the owner decide. The exception is **animations, which
  must be slow enough to read**.
- They love the painted, aged, "dirty dungeon" look, two or three frames per
  moving thing, the glass health vial, optional branches that are **easy to
  miss**, sneaky but fair encounters, and the 1990s jank of tossing a torch
  at a web.
- Accepted as-is for now: the Lower Watch's rusty look, the busy wooden door,
  chains that read as rusted into the wall, the stairwell you stare down,
  B's r10 icons (the Seal "looks like a lemon slice, which I like").
- Long-term dream (later slices): "a dense 10-floor-deep difficult crawler
  where you barely survive".

## The workers

All are persistent Codex threads. Thread IDs and the exact resume command are
in Claude's memory (`codex-collaboration`). Workers never commit; Claude
verifies, commits with explicit paths and pushes. **All four are idle and
handed in** at this update. Codex usage had a full reset available. If a
worker reports it has run out of usage, tell the owner right away.

| Worker | Owns | Last delivered |
| --- | --- | --- |
| **A**: game code | `scripts/` (except dev, fx, audio/music), `scenes/`, `data/` (except music/text), tests except `tests/qa/`, DESIGN/CONTRACT/ARCHITECTURE, `M*_RESULTS.md` | M4c (`docs/M4C_RESULTS.md`) |
| **B**: creatures, fixtures, music | `art_src/{anim,fx,creatures,fixtures,hands,items,music}`, matching `assets/art/` folders, `data/music/`, `scripts/audio/music.gd`, `docs/ART.md`, `docs/MUSIC.md` | Painted fixtures v2, floor-three music, r10 pack icons (the club alternate `icon_club_16_alt.png` is unused) |
| **C**: environment, screens, UI art, manual | `art_src/{env,icons,screens,portrait,props,ui_offer}`, matching `assets/art/` folders, `scripts/fx/`, `data/text/`, `docs/MANUAL.md`, `POLISH.md`, `ENV_ART.md` | The Lower Watch family, the manual for M4a, the owner's candle as its own sprite |
| **D**: QA | `tests/qa/`, `docs/QA_REPORT.md`, `docs/ART_AUDIT.md` | Deep-profile sweep, 18 runner phases. Worked in a clean worktree (`<scratchpad>/qa`) so A's edits couldn't disturb it |
| **Claude** | `project.godot`, `export_presets.cfg`, `assets/icon/`, `scripts/dev/` (autopilot, pointer), `docs/BRIEF.md`, `COLLAB_LOG.md`, this file, Git, builds, phone | Orchestrating |

**Tell A at the start of its next turn:** Claude edited A's files after M4c:
- `scripts/ui/chrome.gd` and `main.gd`: `Chrome.surface()` always crops the
  sources' 4-px bevel. Buttons and the bronze frame (`Chrome.style`) keep
  their chrome.
- `scripts/view/held_item.gd`: the hand timings above.

The owner also paints. Their **vine overlay** is wired
(`assets/art/ui/owner_vines.png`, working template
`art_src/ui_offer/owner_vines/templates/screen_154x342_no_candle.png`, `.ase`
may be committed). The candle is now its own sprite
(`assets/art/ui/owner_candle.png`, two 7x17 frames at (147,155)); keep it off
the overlay. The owner plans to keep adding to the overlay: drop new exports
into `assets/art/ui/owner_vines.png`. If skulls move, update
`data/ui/overlay_glints.json`. Draw the overlay above the chrome and the
compass needle, below cards, modals and the map; it stays visible under
cards and menus, and only the map hides it.

## Queue for the next session

1. **Owner feedback first**, from their phone play of M4c (length,
   difficulty, whether floor three earns its minutes). Depth tuning waits for
   that. See `docs/proposals/M4_DEPTH.md`, "what I would cut", and D's
   numbers above.
2. Any new overlay exports from the owner (copy in; check the glint sockets
   still match).
3. Optional, when wanted: D re-sweeps M4c's input changes (selection-then-hand
   capability verbs, PRY, the puzzled cache tap) adversarially. A's suites
   cover them, but D's runner had reduced sweep counts in M4c.

## Ideas parked for later slices

- A sealed arch that hides something, found by striking it with a HEAVY item.
- The ten-floor "barely survive" crawler; more creatures, more owners whose
  returned things repair the dungeon (a miller's hand restarts a waterwheel,
  a knight's name turns a patrol into an escort).
- C's costed list of small delights in `docs/POLISH.md`.

## How Claude verifies and ships

- Read the worker's reply and its screenshot sheet, then rerun its scripts
  (latest: `tests/run_m4c_checks.ps1`, `tests/run_m4c_pilots.ps1`) and D's
  `tests/qa/run.ps1`. Pilots are muted unless `--with-sound`, and pilots hide
  the desktop pointer unless `--show-pointer`.
- To keep things moving, commit a worker's turn as soon as it hands in, start
  its next turn, and verify the commit in a **clean detached worktree**
  (`<scratchpad>/m3a`) in parallel.
- Commit with explicit paths (another worker may be mid-turn), credit the
  authors, push to `origin main`. `project.godot` sometimes gets a harmless
  key reorder when the owner opens the editor.
- Build the APK from a clean detached worktree (`m3a` or `qa`): `--import`,
  then `--export-debug "Android" build/DungeonCrawler.apk` (create `build/`
  first in a fresh worktree), then copy it to
  `build/Undercroft-<milestone>.apk`. Install with
  `adb -s 55141JEBF03084 install -r` when the phone is connected; launch it
  with `adb shell monkey -p io.github.vurglepuddle.dungeoncrawler -c
  android.intent.category.LAUNCHER 1`.
- Owner feedback goes first in the next turn, in the owner's words, with
  screenshots taken from the phone (`adb exec-out screencap -p`).
- A worker turn that ends with "Selected model is at capacity" is a transient
  Codex bug: wait about 30 seconds and resume the same thread.
