# M3d: the painted undercroft

Start with `build/m3d_shots/m3d_sheet_2x.png`. All twenty panels are actual
windowed captures: splash/title, dressed corridor and room, exit, both stair
arches, closed/open gate, dead/working lift, selected sparkle, ink map, top
rail/icons, hurt/near-death portraits, endings, card and continued survey.
The native sheet and individual PNGs are beside it. No illustrative mockup or
future-creature preview is presented as a game screenshot.

Nothing committed. Project/export settings, launcher, font imports, autopilot
and Android SaveStore are unchanged. B/C authored assets, FX and text are
read-only inputs. C's late room props, room-face variants, logotype and icon
option remain unwired for M3e. No new generated painting was needed here.

## What is in the game

- Exit, stairs and lift are fixed architectural wall faces. Their UVs follow
  the same DDA columns as the stone around them. The door has a daylight sill;
  down steps disappear into a recess and up steps rise toward light. Dead
  lift chains/cobwebs become taut chains and a warm lamp after restoration.
- Gates are projected portal planes, with real corridor/room imagery behind
  transparent iron apertures. Per-column depth sorting keeps nearer actors
  in front. A creature standing on the threshold paints in front of its arch
  so the raised fist remains readable. The old floor sprites are removed.
- C's primary painted wall family is chosen by a stable mixed hash over seed,
  floor, cell and signed normal. Plain stone dominates; cracks, damp, chains,
  tapestry, drains, recesses and four-fps sconces provide sparse dressing.
  Floor/ceiling images are cast in world space, with sparse stone wear over
  their broad fills. Floor-two paint receives normal
  distance/side lighting once, without the previous extra blue multiplier.
- B's gold/target sparkles have three frames, a long quiet interval and stable
  mixed phases per object. Selection retains item-colour cues and the exact
  real tap target. All frames are cached; animation never changes rules.
- Known possessions use C's native 16px icons. Finder paintings select fine
  at 4-6 HP, hurt at 2-3, near-death at 1; near-death beats a transient hurt
  reaction. Existing health feedback/shudder and the compact pad stay intact.
- The skippable publisher mark and title painting fit above live run controls.
  Endings use their painted plates, with result/epitaph outside the image.
  Provenance, floor names and seeded epitaphs use C's checked short text.
  The original score now also selects its floor-two and death variations.
- C's bounded ambience adds dust, restrained lamp variation, deeper-floor
  drips and stair/lift fades. Arrival state and knowledge save before the old
  picture fades. Reset/close cancels stale callbacks; no fade resolves combat.

Logical geometry stays 154 x 342: 18 top / 156 framed view / 34 messages /
38 equipment / 22 pack / 24 verbs / 48 pad+compass / 2 footer. The picture is
148 x 150. The rail leaves x54-96 clear, and MAP is a real bronze button.
VETKA remains 16px and touch targets remain at least 18px. Tile cells, reach,
generation, actions and rules versions are unchanged. An arrival stair may
be behind you: turn to see its wall, or use the existing UP strip verb.

## The cartographer's sheet

C's parchment is the whole panel. The heading is centred dark lettering,
with no beige label rectangle or flat map backing. Solid ink outlines walked
ground; dashes show glimpsed ground; surveyed masonry uses hatching. Known
stairs/gates/lift/Porter/Seal room are ink glyphs, and the Finder is a dark pin.
A small ? marks an unsurveyed edge without consulting hidden neighbour terrain;
it does not promise a passage through an unknown wall.

The renderer reports its forward camera rays and lamp range, stopped by walls
and closed gates/doors. Surveying deliberately stops at closed iron even when
the picture shows through its bars. Architectural discovery also needs a
visible, lit wall projection: standing on a fixture cell while looking away,
or glimpsing that cell before its distant backing wall enters the lamp, cannot
invent its glyph. The old cardinal `visited` mask is retained solely for
legacy rule hashes and is not used by the live map.

Checked `ui.survey` stores per-floor seen/walked bit strings and landmark IDs,
with a separate checksum. It saves on every committed action, including free
turns, and on pause/close. The public `survey_hash` lets pilots verify it.
Older saves without survey metadata remain playable, with unchanged progress
and payload hashes; they start a fresh survey from the loaded viewpoint.

## Run and reproduce

Open the normal project in Godot 4.3 and run. Continue accepts prior saves;
NEW RUN defaults to BELL42. The main scene/project settings need no edits.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_m3d_checks.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_m3d_pilots.ps1
python tests/build_m3d_sheet.py
```

The execution-policy override applies only to the invoked PowerShell process.
Checks run sequentially because inherited suites share a test storage slot.
The windowed runner uses isolated save/settings slots, fresh processes for
every reopen, and 462 x 1026 windows. New captures go to `m3d_shots`; the
thirteen historical regressions go to `m3d_regression_shots`, preserving old
milestone screenshots. JSON receipts and per-run logs are in `build/`.

Regenerate only the new pilots with Godot
`--headless --path . -s res://tests/build_m3d_pilots.gd`.

## Evidence

Eleven headless suites: **121,453 checks, zero failures**.

| Suite | Checks |
| --- | ---: |
| test_m1 | 130 |
| test_m2 | 31,374 |
| test_m3 | 58,957 |
| test_m3_lift | 133 |
| test_m3b_ring | 28,888 |
| test_ui_layout | 146 |
| test_m3_view | 288 |
| test_music | 46 |
| test_fx | 172 |
| test_m3c | 183 |
| test_m3d | 1,136 |

The new survey/presentation suite covers camera exclusion, closed/open gate
sightlines, dark/behind-camera architectural discovery, checksum corruption,
exact survey continue, portrait thresholds, title controls and face stability
across **100 seeds / 250 floors**, including all four floor counts. The old
arrival-stair sprite assertion now checks a fixed backing wall found by turning;
the M3c UI route test awaits the new travel fade. Existing rule/legacy replay
checks remain intact. No fixture cell or witness action was changed.

**20 windowed pilots pass:** seven new gallery/gate/death/survey/fade pilots,
plus all thirteen M3c regressions. Both survey pairs compare exact payload and
knowledge hashes. Mid-fade A asserts `travel_pending=true` before close; B
continues the already committed destination with `travel_pending=false`.

Normal BELL42 restoration remains **66 turns, 6/6 HP**; keep/RING remains
**74 turns, 6/6**. The photo gallery is **72 turns, 6/6**, adding real steps
for close architecture photographs. Existing 300-seed witnesses retain stairs
**65-95 turns** and restoration **60-85**. Greedy pressure is unchanged:
BELL42 offers 9 ordinary pickups against 8 free entry slots on floor one,
then 4 against 0 free slots on floor two; three later offerings remain behind.

An exported-resource probe passes **87 more checks**, for **121,540 total**.
`tests/stage_m3d.py` copies finalized runtime inputs into an ignored disposable
project. Import/export there preserves source settings and excludes C's ongoing
props/new screens. `build/m3d_resources.pck` then loads from an empty resource
directory: painted walls/surfaces, canonical architecture, gate alpha, icons,
Finder states, plates, sparkles, parchment and all flavour/music JSON resolve.
The external script is `tests/probe_m3d_pack.gd`; run it with `--main-pack`,
not as an ordinary source-tree suite. This verifies packaged paths and imported
textures rather than silently falling back to source PNGs.

Art verification also passes: B's **318 runtime PNGs / 29 exact 4x contacts**;
C's current verifier checks **166 PNGs**, palette/alpha, boundaries and short
text. Its count includes later work and does not imply every file is wired.
The runtime remains Godot-only, with no Python, authoring tool or online service.

## Remaining acceptance

No APK was built or installed here. Pixel 9a touch comfort, map legibility,
speaker balance, lifecycle behaviour and sustained performance need the owner's
phone pass. The exported resource check covers availability, not device speed.
The final windowed runs exit normally; the host still prints its known local
root-certificate startup diagnostic. No network feature was added.

M3e remains FIRE/EDGE fixtures, FOOD/Hound, GLOW/Ghost, TOSS, the Seal's return
glow/reveal and one hinted secret, plus C's late props/logotype/icon option.
This round makes the place and restoration legible; it does not add run choices.
My read: the architecture and paper map give the existing loop a stronger sense
of place. The next design gain should come from those encounter choices.
