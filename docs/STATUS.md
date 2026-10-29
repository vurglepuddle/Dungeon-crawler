# Status and handoff

Where the project stands, who is doing what, and how we work. Claude keeps this
current so that any session (or a reader catching up) can pick up the thread.
Last updated 29 October 2026, end of the evening session (M5b and the new light on the phone). The "Where
we are" section below is from the 4 a.m. handoff; the queue is current.

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
handed in** at this update. Codex usage is limited since 28 October (at most
two workers at once, see above). If a worker reports it has run out of usage,
tell the owner right away.

| Worker | Owns | Last delivered |
| --- | --- | --- |
| **A**: game code | `scripts/` (except dev, fx, audio/music), `scenes/`, `data/` (except music/text), tests except `tests/qa/`, DESIGN/CONTRACT/ARCHITECTURE, `M*_RESULTS.md` | M5b (`docs/M5B_RESULTS.md`), after M5a |
| **B**: creatures, fixtures, music | `art_src/{anim,fx,creatures,fixtures,hands,items,music}`, matching `assets/art/` folders, `data/music/`, `scripts/audio/music.gd`, `docs/ART.md`, `docs/MUSIC.md` | r11 (the f4 Deep family, crumble frames), r12 (iron/bronze/gold keys and lock plates, halved in r12b). For this stretch B also covered environment art, while C rested |
| **C**: environment, screens, UI art, manual | `art_src/{env,icons,screens,portrait,props,ui_offer}`, matching `assets/art/` folders, `scripts/fx/`, `data/text/`, `docs/MANUAL.md`, `POLISH.md`, `ENV_ART.md` | The Lower Watch family, the manual for M4a, the owner's candle as its own sprite |
| **D**: QA | `tests/qa/`, `docs/QA_REPORT.md`, `docs/ART_AUDIT.md` | Deep-profile sweep, 18 runner phases. Worked in a clean worktree (`<scratchpad>/qa`) so A's edits couldn't disturb it |
| **Claude** | `project.godot`, `export_presets.cfg`, `assets/icon/`, `scripts/dev/` (autopilot, pointer), `docs/BRIEF.md`, `COLLAB_LOG.md`, this file, Git, builds, phone | Orchestrating |

**Tell A at the start of its next turn:** Claude edited A's files after M5b.
See "Claude, late evening" in the queue below: the Seal's light in
`dungeon_view.gd`, the held-up mark glow, the room-filling map
(`dungeon_view.gd` `room_cells`, `map_view.gd`, `main.gd` `_capture_survey`),
the Fall's held Seal and hidden verbs (`main.gd` `_wake_transition`), and
`test_m5b.gd`'s light check.

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

## 29 October, afternoon: the owner's verdict and a new direction

The owner played M4c several times: **"VERY FUN, loving it."** They will fix
some visuals by hand. Their breakthrough: the three floors are the perfect
**tutorial**. Taking the Seal makes the floor crumble; you fall into **the
Deep** with nothing but the Seal; it is giant, confusing, hostile, stairs only
go down, and the way out is a lift at the bottom; the existing dawn ending
stays. Claude's proposal and the owner's open questions:
**`docs/proposals/THE_DEEP.md`** (first milestone: M5a, the scaffold).

Fixed directly by Claude the same afternoon (A's file `dungeon_view.gd`; tell
A at its next turn):

- **Levers are sized with their wall.** Every lever closer than 1.5 cells was
  drawn at one size, so it looked smaller when you stepped up to it. Height
  is now world-scaled (`40*FOCAL/64/depth` head-on, `36/depth` side-on), using
  the nearest painted size, with per-size hinge pixels in `LEVER_HINGES`.
- **The owner's own side-lever frames** (`art_src/fixtures/lever_front/
  lever_corridor_f2_native_corrected1/2.png`, up/down, 26x36 native) replace
  `fixture_v2_lever_{left,right}_{up,down}_d1`; right walls mirror them; d2
  (13x18) and d3 (9x12) are nearest reductions the owner may retouch. B's
  `docs/ART.md` table still lists the old 32x40 side canvases.
- **A lever's wall face gets no grate, banner, chains, sconce or blocked
  arch**, only bare or damp/cracked stone (`_lever_faces` in `_wall_path`).

**Codex budget:** the promotion ended on 28 October. Run at most two workers
at once (A and B); D only for a sweep, at medium effort. Claude makes small
fixes directly.

## Queue for the next session

**Landed on 29 October, evening (all verified and pushed):**

- **M5a** (`3b07816`, A): the Fall, the Deep (one 33x33 floor of four
  blocks, a chain of needs), the Winding, skip start, no permadeath. See
  `docs/M5A_RESULTS.md`.
- **M5b** (`189f521`, A): the owner's M5a notes.
  - The map surveys everything visible in light and line of sight.
  - Iron, bronze and gold keys: one belt icon, with a key list.
  - The Seal's stepped, dithered light pool.
  - Seeded f1-f4 art families per Deep block.
  - The Fall's counter stays on the Abbey.
  - See `docs/M5B_RESULTS.md`.
- **B r11-r12:** the f4 Deep family, the crumble frames, the keys and lock
  plates (halved at the owner's request: "we don't need to make it look like
  the entire door is the keyhole").
- **The owner's own art:**
  - side-lever frames;
  - hand grips (stone, torches, punch);
  - the crumble frames, made "more 3d";
  - the first verb-icon pass, with BURN.
- **Claude's fixes and follow-ups** (tell A; all in A's files):
  - **Levers:** sized with their wall; no dressing on a lever's face.
  - **The Fall:**
    - B's frames at 0.7 s, shaking with the view;
    - the Seal leaves its pedestal;
    - you clutch the Seal while falling;
    - no verbs from the room below until it fades in.
  - **The hand:** the Seal shows only while selected (it was "glued").
  - **Art:** the Winding wears f4.
  - **The arrow pad** is PNGs (`assets/art/ui_offer/arrow_*.png`).
- **The owner's verdict on M5a:** a full run in 578 turns, "long enough, but
  not exhausting"; "I like how sprawling and confusing it is".

- **Claude, late evening, from the owner's phone notes** (`112d1d4`,
  `1cde2bc`; tell A, all in A's files):
  - **The Seal's light** follows the owner's mockup (gentle levels, each
    8x8-Bayer-dithered only into the next darker one, no overexposure), with
    numbers in `data/presentation/seal_light.json`;
  - **held up**, the Seal shows and pulses any mark it faces;
  - **the map** draws seen floor solid, not dashed, and standing in a room
    maps all of it (`dungeon_view.gd`, `room_cells`).
  - The owner: "I think it looks great ... excellent work, I'm very
    satisfied."

**Next:**

1. **The owner is thinking about the game and painting.** Start the next
   session from their words.
   - Light tuning (`seal_light.json`): an optional warm-near, cool-far tint,
     as in the owner's mockup.
   - The dawn mark art is thin (`panel_sigil_revealed_64.png`); the owner may
     repaint it.
2. **Combat revamp:** the owner wants "more depth there and a more
   interesting loop". Write a proposal before the Deep fills with enemies.
3. **Later Deep vocabulary:**
   - traps, unique rooms and puzzle chains that make the run "even longer
     with interesting puzzles";
   - one-way drops and dawn locks;
   - two-creature encounters (after combat).
4. **Owner art in progress:** more verb icons (`verb_sheet.py split` after
   each pass), and the arrow pad if they want. Two working files are
   uncommitted and still the owner's: `assets/art/ui_offer/sleepy_skull_v3.png`
   and the overlay template `.ase`.
5. **Tools:**
   - `build/fall_clip.mp4` and `.gif` were recorded with Godot's
     `--write-movie <dir>/f.png --fixed-fps 30` and a pilot (`wait` counts
     frames), from the clean worktree, then encoded with ffmpeg;
   - for QA, D runs only for sweeps, at medium effort.

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
- Owner feedback goes first in the next turn, in the owner's words, with any
  screenshots the owner shares.
- **Never capture the owner's phone screen** (`adb exec-out screencap`) unless
  they ask or agree first: they chat with clients on it. To check a launch,
  use `adb shell pidof io.github.vurglepuddle.dungeoncrawler` instead.
- A worker turn that ends with "Selected model is at capacity" is a transient
  Codex bug: wait about 30 seconds and resume the same thread.
