extends SceneTree
## Local audio-only authoring check. No scene, save, window or imported WAV.
const Synth = preload("res://scripts/audio/music.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var music = Synth.new()
	root.add_child(music)
	music.set_enabled(false)
	var piece: Dictionary = music._load_score("floor3")
	check(not piece.is_empty(), "Floor-three note data validates")
	check(piece.notes.size() == 27 and piece.loop, "27 authored events and looping")
	check(piece.bpm == 52 and piece.beats == 64, "Lower Watch tempo and long phrase")
	for floor_number: int in [1,2,3,4]:
		var expected: String = "floor" if floor_number == 1 else ("floor2" if floor_number == 2 else "floor3")
		check(music.play_floor(floor_number) and music._current_track == expected, "Floor %d selects %s" % [floor_number,expected])
		check(not music.is_playing(), "Disabled selection stays silent")
	check(music.play("floor3"), "Direct track ID works")
	check(not music.play("absent") and music._current_track == "floor3", "Bad ID preserves selection")
	music._prepare_score("floor3")
	var whole: PackedVector2Array = music._mix_frames(4429)
	music._prepare_score("floor3")
	var split: PackedVector2Array = music._mix_frames(4096)
	split.append_array(music._mix_frames(333))
	check(whole == split, "Clock and PCM independent of buffer partition")
	check(whole[0] == Vector2.ZERO, "Soft start at exact zero")
	music._prepare_score("floor3")
	var duration: int = music._length_samples
	check(duration > int(70 * Synth.SAMPLE_RATE), "Phrase exceeds seventy seconds")
	var left: int = duration + 4096
	var count := 0
	var peak := 0.0
	var finite := true
	var maximum_voices := 0
	var before_seam := 0.0
	var after_seam := 0.0
	var energy := 0.0
	while left > 0:
		var frames: PackedVector2Array = music._mix_frames(mini(left,4096))
		maximum_voices = maxi(maximum_voices,music._voices.size())
		for frame: Vector2 in frames:
			finite = finite and is_finite(frame.x) and frame.x == frame.y
			peak = maxf(peak,absf(frame.x))
			energy += absf(frame.x)
			if count == duration-1: before_seam = frame.x
			if count == duration: after_seam = frame.x
			count += 1
		left -= frames.size()
	check(finite and energy > 10.0, "Finite, centred, non-silent runtime PCM")
	check(peak > 0.01 and peak < 0.4, "Restrained runtime peak with headroom")
	check(maximum_voices <= 4, "Sparse bounded polyphony")
	check(music._loops_completed == 1 and music._sample_cursor == 4096, "Exact authored loop boundary")
	check(absf(before_seam-after_seam) < 0.002, "No waveform jump at seam")
	check(music.play_floor(2) and music._current_track == "floor2", "Returning upstairs restores floor two")
	music.stop()
	music.set_enabled(true)
	check(not music.is_playing(), "Explicit stop survives enabling")
	var result := {"checks":checks,"failures":failures,"runtime_peak_before_player_db":peak,
		"peak_with_default_minus18db":peak*db_to_linear(-18.0),"maximum_voices":maximum_voices,
		"duration_seconds":float(duration)/Synth.SAMPLE_RATE,"loop_delta":absf(before_seam-after_seam),
		"rendered_in_bounded_chunks":true,"windowed_run":false,"phone_listening":false}
	var receipt := FileAccess.open("res://art_src/music/floor3_runtime_check.json",FileAccess.WRITE)
	receipt.store_string(JSON.stringify(result,"  ")+"\n")
	receipt.close()
	print(JSON.stringify(result))
	music.queue_free()
	for _frame in range(4): await process_frame
	quit(0 if failures == 0 else 1)
