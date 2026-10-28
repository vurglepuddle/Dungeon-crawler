extends SceneTree
## Focused score / streaming / controls regression. No scene or save is loaded.

const Music = preload("res://scripts/audio/music.gd")
var checks: int = 0
var failures: int = 0


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var music = Music.new()
	root.add_child(music)
	check(not music.is_playing(), "Autoload stays silent until requested")
	for track: String in ["title", "floor", "win"]:
		var score: Dictionary = music._load_score(track)
		check(not score.is_empty(), "%s original note data validates" % track)
		music._prepare_score(track)
		check(music._events.size() == score.notes.size(), "%s retains every authored note" % track)
		check(music._length_samples > 0, "%s has a finite duration" % track)
	check(music.play("title") and music.is_playing(), "Generator starts title")
	var cursor: int = music._sample_cursor
	check(music.play("title") and music._sample_cursor == cursor, "Repeated title play does not restart")
	check(not music.play("missing") and music._current_track == "title", "Bad track preserves title")
	music.set_enabled(false)
	check(not music.is_playing() and music._playback == null and music._voices.is_empty(), "MUSIC off releases playback and voices")
	check(music._current_track == "title", "Mute remembers selection")
	check(music.play("floor") and not music.is_playing(), "Disabled play changes selection without sound")
	music.set_enabled(true)
	check(music.is_playing() and music._current_track == "floor", "Unmute starts requested floor")
	music._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not music.is_playing() and music._suspended, "Android pause stops audio")
	music._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(music.is_playing() and not music._suspended, "Android resume restarts selected phrase")
	music.stop()
	music.set_enabled(false); music.set_enabled(true)
	check(not music.is_playing() and music._current_track.is_empty(), "Explicit stop survives toggle")

	# Chunk size and frame rate must not change the musical clock or PCM.
	music._prepare_score("title")
	var whole: PackedVector2Array = music._mix_frames(4429)
	music._prepare_score("title")
	var chunks: PackedVector2Array = music._mix_frames(4096)
	chunks.append_array(music._mix_frames(333))
	check(whole == chunks, "Synthesis is independent of process buffer partitioning")
	check(whole[0] == Vector2.ZERO, "Attack begins at zero without a click")
	var energy: float = 0.0
	for frame: Vector2 in whole:
		energy += absf(frame.x)
	check(energy > 1.0, "Note data produces audible nonzero PCM")

	# Render through the REAL floor loop boundary with the actual runtime mixer.
	music._prepare_score("floor")
	var length: int = music._length_samples
	var looped: PackedVector2Array = music._mix_frames(length+2205)
	check(music._loops_completed == 1 and music._sample_cursor == 2205, "Floor wraps at exact sample boundary")
	check(not music._score_done, "Floor remains live after loop")
	var peak: float = 0.0
	var finite: bool = true
	var stereo: bool = true
	for frame: Vector2 in looped:
		peak = maxf(peak, absf(frame.x))
		finite = finite and is_finite(frame.x) and is_finite(frame.y)
		stereo = stereo and frame.x == frame.y
	check(finite and stereo and peak > 0.01 and peak < 0.4, "Full floor PCM is finite, centred stereo and safely below clipping")
	check(absf(looped[length-1].x-looped[length].x) < 0.002, "Loop seam has no waveform jump")
	check(music._voices.size() <= 4, "Sparse score has bounded active voices")

	music.play("win")
	var playback_watch: WeakRef = weakref(music._playback)
	music._mix_frames(music._length_samples+11025)
	check(music._score_done and music._voices.is_empty(), "Win ends once with all releases finished")
	var silence: PackedVector2Array = music._mix_frames(512)
	var silent: bool = true
	for frame: Vector2 in silence:
		silent = silent and frame == Vector2.ZERO
	check(silent, "Finished win generates silence")
	music._process(0.0)
	music._process(0.25)
	check(not music.is_playing() and music._current_track.is_empty(), "Natural cue end drains buffer and forgets selection")
	music.set_enabled(false); music.set_enabled(true)
	check(not music.is_playing(), "Toggle cannot replay completed win")
	music.stop()
	music.free()
	# AudioServer releases its last mix-thread reference on the next audio tick.
	await create_timer(0.3).timeout
	await process_frame
	await process_frame
	check(playback_watch.get_ref() == null, "AudioServer releases the final playback")
	print("Music: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
