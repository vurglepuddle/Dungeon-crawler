# UNDERCROFT original score

28 October 2026. Five original short compositions by Codex B, written for this
game as explicit note lists. No Bach, MIDI transcription, public-domain
arrangement, downloaded composition, sample pack, external service or gameplay
RNG is involved. Claude registered the autoload; B supplies music and the
player, while scene calls, settings persistence and the MUSIC UI belong to A.

## Pieces

| Track ID | Piece | Score | Length | Playback |
| --- | --- | --- | --- | --- |
| `title` | The Unclaimed Door | `data/music/title.json` | 20.00 s, 72 BPM | Loop |
| `floor` | A Bell Below the Stone | `data/music/floor.json` | 29.09 s, 66 BPM | Loop |
| `win` | Something Returned | `data/music/win.json` | 5.71 s, 84 BPM | Once |
| `floor2` | Under the Last Landing | `data/music/floor2.json` | 34.29 s, 56 BPM | Loop |
| `death` | The Last Wick | `data/music/death.json` | 4.00 s, 60 BPM | Once |

The original three use D Dorian and the bell motif **D5 - A5 - E5 - F5**
(MIDI 74,81,76,77): a distant call, then a close uneasy semitone.
The floor theme leaves large spaces over low D/A/C support. The title places
the call a little higher in the foreground. The win cue answers it with B
natural and high D, making the Porter's return feel warmer without adding a
separate style. There are only 14, 16 and 9 note events respectively.

The floor-two variation moves the call down an octave to D4-A4-E4-F4, slows
the phrase from 66 to 56 BPM and removes some reed movement. Its 14 events
sit over a lower bass answer, keeping the same place recognisable further
below the abbey. The six-event death cue lets the bell fall through D4, A3,
E3, F3 and D3, decreasing in strength like a lamp sputtering out. It ends in
silence; there is no triumphant cadence. The first three scores are unchanged.

Review WAVs are offline authoring previews under `art_src/music/previews/`:
`title.wav`, `floor.wav`, `win.wav`, `floor2.wav`, `death.wav`. They include the default gentle gain.
The game never loads them. Actual speaker balance, appeal and Pixel 9a CPU/
background behaviour still need a human/device pass.

## Runtime player

`scripts/audio/music.gd` is registered by Claude as the `Music` autoload. It creates one
AudioStreamPlayer but remains silent until requested. Existing SFX remain an
independent node/control; the music script never changes the Master bus volume.

```gdscript
Music.play("title")       # title / menu
Music.play("floor")       # run / continue; repeated calls do not restart
Music.play_floor(floor)   # preferred run/continue/stair hook: floor1 or floor2
Music.play("win")         # committed win; one short cue, then silence
Music.play("death")       # committed death; lamp-out cue, once
Music.set_enabled(false)  # MUSIC toggle, independent of SFX
Music.set_enabled(true)
Music.stop()              # explicit silence; forgets the selection
```

`play(track)` returns false for an unknown or invalid score, leaving a valid
current track intact. With MUSIC disabled, it remembers the requested track
without producing audio. Enabling restarts that phrase from its beginning.
`stop()` clears the selection, so an off/on toggle cannot restart stopped
music. A naturally completed win also clears its selection after draining the
last buffered audio. No calls write files or alter saved game state.

`play_floor(floor_number)` selects `floor` for the first floor and `floor2`
for deeper floors, returning the same success boolean as `play`. Call it after
new run, continue and committed stairs/lift arrivals, so returning upstairs
restores the first theme. Direct `play("floor2")` also works. Call `play("death")`
after committed death instead of immediately stopping music; do not restart
the cue every time the end screen redraws. Both one-shot tracks clear selection
after their buffered release, so toggling MUSIC later does not replay them.

The player handles application pause by releasing playback. Resume restarts
the selected phrase if music remains enabled. It never tries to catch up for
time spent in the background. Let the settings owner save the MUSIC preference
through the existing settings path and restore it using `set_enabled`.

The synthesizer streams at 22,050 Hz into a requested 0.14-second generator
buffer; each fill is capped at 4096 stereo frames. It never renders a whole
track into RAM or writes temporary audio. Sine oscillators with a decaying
inharmonic partial make the bell; quieter reed and drone tones support it.
Oscillators use rotations with trigonometry only at note onset. Soft attacks,
releases, a start ramp, and -18 dB player volume keep the output restrained.
The musical clock uses integer sample positions, independent of process frame
rate or buffer partitions. Loop boundaries are part of the authored phrase.

Engine reference for playback lifecycle review:
[Godot 4.3 AudioStreamPlayer implementation](https://github.com/godotengine/godot/blob/4.3/scene/audio/audio_stream_player_internal.cpp).

## Note data and rebuilding

JSON schema 1 has `id`, `title`, `mode`, `bpm`, `beats`, `loop`, `notes`.
Each note records `beat`, MIDI `pitch`, duration in `beats`, `voice`
(`bell`, `reed`, `drone`) and `velocity` in (0,1]. Notes are sorted by beat
and pitch. There are no dependencies on imported samples or Godot audio files.

`art_src/music/build_score.py` is the editable composition source. Run:

```powershell
python art_src/music/build_score.py
```

Python's standard library recreates all five note JSONs, preview WAVs and
`art_src/music/manifest.json` deterministically. This is an offline authoring
tool, never a runtime requirement. Preserve JSON files in the Android package:
ensure the export include filter covers `data/music/*.json` as well as the
other game data. Exclude `art_src/*` from the export to avoid shipping source
paintings and review WAVs. B has not edited export settings or project.godot.

## Verification

```powershell
E:/SD/GODOT/Godot.exe --headless --audio-driver Dummy --path . -s res://tests/test_music.gd
```

**46 checks, zero failures**, using Godot 4.3. The focused test loads every
authored score, renders real runtime PCM, compares whole/chunked output, crosses
the full floor loop, checks finite stereo samples and clipping headroom, and
checks win completion, unknown names, repeated play, stop, mute, pause/resume,
and final AudioServer playback release. It additionally crosses the entire
lower-floor loop, verifies its slower phrase, checks the floor selection hook
in both directions and renders death through its final exact silence. It gives AudioServer several frames
to finish asynchronous cleanup before quitting. The sandboxed executable logs
a root-certificate-store startup error, unrelated to these local audio checks;
the final run has no leaked-playback warning. No game scene, save or full-suite
run was needed. Listening and phone acceptance remain outstanding.
