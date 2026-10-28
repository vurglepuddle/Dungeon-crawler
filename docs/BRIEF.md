# Brief

What the owner asked for, the hard constraints, and what the previous
experiment taught us. Design decisions live in `DESIGN.md`; this file only
changes if the owner changes the brief.

## The owner's vision (28 October 2026)

A *forgotten first-person dungeon crawler from the early 1990s*, in the spirit
of Eye of the Beholder, Dungeon Master and Lands of Lore, with enough modern
mechanics to make you want one more run.

- First-person, grid-based, 90-degree turns, illustrated walls, doors,
  enemies and objects. 2D perspective tricks, no 3D engine needed.
- Retro pixel art, retro interface, portraits, equipment slots, old-school charm.
- **Loot and inventory management that is part of the fun**: strange items,
  comparing equipment, discovering interactions, real decisions about what to keep.
- **Things to discover**: puzzles, secrets, meaningful encounters, unexpected
  interactions; not just stronger monsters.
- The owner deliberately does not prescribe mechanics, items, enemies, puzzles
  or combat. Claude and Codex invent them together and should surprise them.

## Hard constraints

- Godot 4.3 (`E:/SD/GODOT/Godot.exe`), Android target, owner's phone is a
  **Pixel 9a** (1080 x 2424, about 20:9), portrait.
- Touch only, **no virtual joystick**. Turn-based.
- Procedurally generated floors with **reproducible seeds**.
- Original retro graphics, generated or drawn programmatically. No downloaded
  asset packs, no paid dependencies, no external services; offline.
- **Readable UI**: the owner uses ~1.5x system fonts. No tiny text, icons or
  touch targets.
- A **playable vertical slice**: a complete short dungeon run with satisfying
  exploration, loot and a few interesting mechanics, over many shallow systems.
  Something fun to pick up when bored.
- Saves use `user://` only. Save, fully close the app, reopen, load: must work.
- Commit to Git (main or feature branches); both collaborators may commit and push.
- Document design decisions, mechanics, architecture and discoveries in Markdown.

## Display baseline (set up by Claude)

- Logical viewport **154 x 342**, `keep_width`, integer scale. On the Pixel 9a
  that is exactly **7x** (1078 px wide) and the logical height grows to ~346.
  Design layouts for 154 x 342; extra height on taller phones is a bonus.
- Font: the owner's own pixel font **VETKA** (`assets/font/vetka.ttf`, 16 px is
  native: 1 font brick = 1 logical pixel). At 7x the owner confirmed VETKA 16 px
  as "perfect, no strain" in the last game. Treat 16 px as the minimum size.
  A 144-px-wide line held about 21 characters, so plan on **~22 characters per
  line** here. This is the single biggest design constraint: item names,
  descriptions and messages must be short.
- Touch targets: **at least 18 x 18 logical px** (~126 physical px, ~7.6 mm).
  Item icons 16 x 16 inside 20 x 20 slots or larger.
- Renderer: GL Compatibility (most reliable on Android for 2D). Nearest filtering.

## Lessons from the previous experiment (Wind-up Warren, `E:/SD/GODOT/Crawler`)

That repo is the owner's own and may be read for patterns (it is a reference,
not a template). What worked:

- A **pure deterministic simulation** (no nodes, seeded RNG, actions in, events
  out) made solvability bots, replays, saves and tests easy.
- A **witness/solver bot** that plays generated floors to the end caught
  unsolvable generation before any human did. Do it again.
- **Autopilot** (`scripts/dev/autopilot.gd`) drove the *real* UI with taps and
  saved screenshots. Code review did not replace this: real input found bugs
  (stale queued input after transitions, overwritten error messages, double
  walkers) that unit tests missed.
- Saves: versioned JSON, staged write + last-good backup. Absolute paths
  silently failed on Android; `user://` fixed it. Save on every committed turn
  and on pause/close (`NOTIFICATION_APPLICATION_PAUSED`, `WM_CLOSE_REQUEST`).
- Strings were capped for the phone (21 chars x 2 lines). The owner reads the
  game with no strain only because of this discipline.
- Music: last time it was public-domain Bach synthesised at runtime from note
  JSON. **Not this time**: the owner has heard those pieces far too often and
  Bach is not required. Original music (or fresh public-domain sources) is
  welcome; runtime synthesis still fits the offline rule.

## How to run things

- Headless tests: `E:/SD/GODOT/Godot.exe --headless --path . -s res://tests/<file>.gd`
- Windowed run (desktop): `E:/SD/GODOT/Godot.exe --path .`
- Debug APK: `E:/SD/GODOT/Godot.exe --headless --path . --export-debug "Android" build/DungeonCrawler.apk`
- Phone: `adb install -r build/DungeonCrawler.apk` (only when the owner's phone is plugged in).
