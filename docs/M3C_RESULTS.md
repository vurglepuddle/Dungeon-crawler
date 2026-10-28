# M3c: tactile panels and combat tells

Start with `build/m3c_shots/m3c_sheet_2x.png` (native version beside it).
Fourteen panels are actual windowed captures. The last two are explicitly
labelled **asset previews** of B's Hound/Ghost poses, not playable encounters.
The individual PNGs include early/middle/late EDGE frames for timing review.

This is the requested coherent checkpoint: chrome, B's first asset/audio
wiring and the reproduced phone issues. No commit. Capability content follows
in the next round. B/C authored files were preserved; no project/export,
autopilot, Android SaveStore, font or launcher settings were changed. Editor
import created metadata for new parallel art; leave those files with its owner.

## What changed

- Buttons and compass retain their original bronze painting. Large areas use
  continuous dark slate, green enamel or leather sources, never the small
  repeating tile. Native bevels, corner studs, strap loops and a leather fold
  make the panels physical without extra labels. The contrasting accent is
  verdigris. The compass needle kicks and settles on turns; a narrow glass
  oil gauge repeats health beside the original portrait bar.
- B's idle/raised-fist/recoil Husk paintings replace the old single sprite
  and recovery offset/tint at all three distances. The restored Porter now
  raises its palms and lights its painted chest; the procedural chest dot is
  removed.
- The pressure plate is a shallow inset trapezoid selected from the sim's
  pressed state. It paints before its supporting weight. No slab shadow,
  pedestal or distant minimum height turns it upright again.
- The lever has a world-fixed wall hinge. Its perspective and occlusion use
  that wall plane. The handle flips down when latched and remains visible
  after the interaction is spent. It no longer overlaps the Husk's body.
- Actual strikes use EDGE/HEAVY/hands effects, event damage in VETKA 16 and
  one drawn frame of target flash. A lethal hit keeps a short painted recoil
  after the authoritative actor is dead. Three 80ms frames do not extend the
  normal 130ms action gate. Moving/turning/floor travel clears stale effect
  coordinates. Hurt feedback includes the Finder's two-pixel shudder.
- The existing Music autoload now plays title/floor/win. MUSIC and SFX are
  independent and persist in `user://settings.cfg`. Isolated pilots/tests
  derive their own settings filename beside their save. The late floor2/death
  compositions are available from B but are not selected by this integration.

The logical bands remain 18 top / 156 framed view / 34 messages / 38 equipment /
22 pack / 24 verbs / 48 pad+compass / 2 footer. The picture is 148 x 150 at
(3,21). Camera gap x54-96 stays empty. Targets remain at least 18 x 18; the
six movement tiles remain 24 x 22. Pack icons keep the native centred layout.

## Run and review

Open the project with Godot 4.3 and run the main scene. NEW RUN defaults to
BELL42; the title has separate MUSIC and SFX switches. Existing saves continue
with unchanged rules and hashes. The owner can export the existing Android
preset; no new project settings are required.

From the repository directory, the full windowed batch is:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_m3c_pilots.ps1
python tests/build_m3c_sheet.py
```

The execution-policy override is confined to that PowerShell process. The
runner opens separate windowed processes at 462 x 1026, uses only isolated
`user://tests/` slots, records each exit in `build/m3c_pilot_results.json` and
stops on failure. It runs gallery, return, keep, room, restoration A/B, RING,
spent-RING A/B, audio-preference A/B, HEAVY and bare hands: **13 passes**.
New pilot sources can be regenerated with:

```powershell
E:/SD/GODOT/Godot.exe --headless --path . -s res://tests/build_m3c_pilots.gd
```

For one capture, use the existing command pattern:

```powershell
E:/SD/GODOT/Godot.exe --path . --resolution 462x1026 -- --pilot=res://tests/pilot/m3c_gallery.txt --out=E:/SD/GODOT/Dungeon-crawler/build/m3c_shots --save-path=user://tests/m3c_gallery.json --timeout=90
```

## Evidence

Eight headless suites, **120,044 checks, zero failures**:

| Suite | Checks |
| --- | ---: |
| test_m2 | 31,374 |
| test_m3 | 58,957 |
| test_m3b_ring | 28,888 |
| test_m3_lift | 133 |
| test_ui_layout | 146 |
| test_m3_view | 317 |
| test_music | 46 |
| test_m3c | 183 |

Run each with Godot `--headless --audio-driver Dummy --path . -s res://tests/NAME.gd`.
The new integration suite covers independent settings, score routing, compass
settling, registered poses, plate ordering, the used wall lever, restored pose,
nonblocking effects, lethal recoil, stale-coordinate clearing, audio release
and a damage-free ordinary-action run. Existing suites replay legacy saves,
300 full stairs witnesses, 300 restoration witnesses and 300 RING witnesses,
plus keep/exploration/floor-count boundary policies.

The generator is unchanged: stairs range **65-95 turns**, restoration **60-85**.
BELL42 returns by lift in **66 turns, 6/6 HP**; keeping the clapper takes
**74 turns, 6/6**. The bare-hand capture wins in **67 turns, 6/6**. The gallery
takes **68 turns, 5/6**, deliberately accepting a hit and backing off the plate
for its photograph. Those extra gallery actions are real inputs.

Greedy pack pressure is also unchanged. BELL42 floor one offers **9** ordinary
pickups against **8** free entry slots: stone, club, coat, bread, tonic, club,
bone, shard, clapper. It leaves with zero free slots. Floor two offers **4**
against **0** free entry slots: stone, bread, lamp, coat; three remain behind.
Keys and Seal use the protected belt and are excluded from these counts.

B's current art verifier passes **172 runtime PNGs and 23 exact 4x contacts**.
The five new UI surfaces share the 32-entry palette and rebuild offline with
`python art_src/m3c/build_surfaces.py`. Painting, exact prompt and reduction
source are under `art_src/m3c/`; runtime surfaces are `assets/art/ui/`.
The game gains no Python, image-service or external audio dependency.

## Limits and remaining work

One early restoration close reached the correct saved hash, then exited with
native code 0xC0000005. No engine trace established its cause. Main now stops
audio on close and scene exit, with a 50ms mixer grace period before immediate
teardown. The final batch passes, as do five additional restoration closes;
the short shutdown probe also passed 20 times. This is evidence against a
repeat, not proof of the original native cause. The code review used Godot's
[4.3 player lifecycle](https://github.com/godotengine/godot/blob/4.3/scene/audio/audio_stream_player_internal.cpp)
and [deferred audio cleanup](https://github.com/godotengine/godot/blob/4.3/servers/audio_server.cpp).
Final relevant logs contain the known local root-certificate-store startup
diagnostic; they have no leaked-playback warning. The game uses no network.

This build has not been exported or installed on the phone here. Speaker
balance, background/resume, touch comfort, motion readability and sustained
device performance need owner acceptance. B/C parallel art beyond the wiring
listed above is outside this milestone's in-game acceptance.

Still to implement: renewable FIRE/brazier/torch/web; EDGE fixture;
FOOD/pacified Ash Hound and its two-cell lunge; optional GLOW/Wick Ghost;
explicit TOSS and lane preview; Seal return glow/reveal; one hinted secret.
Their assets do not imply their rules have shipped.

My read: the existing run is fairer and more tactile now. The raised fist is
the biggest improvement: the picture finally teaches the timing. Restoration
still supplies the emotional payoff. Third-run variety remains the content
problem; more surface polish alone will not solve it.
