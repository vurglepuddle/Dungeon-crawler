extends Node
## Original note-data score, generated live into a bounded PCM ring buffer.
## No samples, files written, gameplay RNG, HTTP or imported audio resources.

const SAMPLE_RATE: int = 22050
const BUFFER_SECONDS: float = 0.14
const TRACK_PATHS: Dictionary = {
	"title": "res://data/music/title.json",
	"floor": "res://data/music/floor.json",
	"floor2": "res://data/music/floor2.json",
	"floor3": "res://data/music/floor3.json",
	"win": "res://data/music/win.json",
	"death": "res://data/music/death.json",
}

class Tone:
	var age: int = 0
	var length: int
	var level: float
	var decay: float
	var attack: float
	var release: float
	var partial: float
	var s: float = 0.0
	var c: float = 1.0
	var s2: float = 0.0
	var c2: float = 1.0
	var ds: float
	var dc: float
	var ds2: float
	var dc2: float

	func _init(pitch: int, duration: int, voice: String, velocity: float) -> void:
		length = duration
		level = velocity
		var frequency: float = 440.0 * pow(2.0, (pitch-69)/12.0)
		var bell: bool = voice == "bell"
		var ratio: float = 2.756 if bell else (3.0 if voice == "reed" else 2.0)
		partial = 0.32 if bell else (0.12 if voice == "reed" else 0.10)
		decay = exp(-(2.8 if bell else (0.45 if voice == "reed" else 0.12))/22050.0)
		attack = 110.0 if bell else 441.0
		release = maxf(1.0, minf(duration/3.0, 2205.0))
		var angle: float = TAU * frequency / 22050.0
		ds = sin(angle); dc = cos(angle)
		ds2 = sin(angle*ratio); dc2 = cos(angle*ratio)

	func sample() -> float:
		var envelope: float = minf(1.0, minf(age/attack, (length-age)/release))
		var value: float = (s+s2*partial)*level*envelope
		# Complex rotation: no trigonometry, allocation or RNG per sample.
		var next_s: float = s*dc+c*ds
		c = c*dc-s*ds; s = next_s
		next_s = s2*dc2+c2*ds2
		c2 = c2*dc2-s2*ds2; s2 = next_s
		level *= decay
		age += 1
		return value

var enabled: bool = true
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _tracks: Dictionary = {}
var _events: Array[Dictionary] = []
var _voices: Array[Tone] = []
var _current_track: String = ""
var _sample_cursor: int = 0
var _event_cursor: int = 0
var _length_samples: int = 0
var _loops_completed: int = 0
var _loop: bool = false
var _running: bool = false
var _suspended: bool = false
var _score_done: bool = false
var _drain_seconds: float = -1.0
var _fade_samples: int = 0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -18.0
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = BUFFER_SECONDS
	_player.stream = generator
	add_child(_player)
	set_process(false)
	if enabled and not _suspended and not _current_track.is_empty():
		_start_track()


func play(track: String) -> bool:
	## Unknown names reject without interrupting a valid playing track.
	if not TRACK_PATHS.has(track) or _load_score(track).is_empty():
		return false
	if track == _current_track and _running:
		return true
	_current_track = track
	if enabled and not _suspended and is_instance_valid(_player):
		_start_track()
	return true


func stop() -> void:
	## Explicit stop forgets the selection, so toggling MUSIC cannot restart it.
	_current_track = ""
	_halt_audio()


func play_floor(floor_number: int) -> bool:
	## Each authored landing has a theme; later depths retain the Lower Watch.
	if floor_number >= 3:
		return play("floor3")
	return play("floor2" if floor_number == 2 else "floor")


func set_enabled(value: bool) -> void:
	## Muting remembers the selected theme; unmuting restarts its phrase.
	if value == enabled:
		return
	enabled = value
	if not enabled:
		_halt_audio()
	elif not _suspended and not _current_track.is_empty() and is_instance_valid(_player):
		_start_track()


func is_playing() -> bool:
	return _running


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_suspended = true
		_halt_audio()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_suspended = false
		if enabled and not _current_track.is_empty() and is_instance_valid(_player):
			_start_track()


func _load_score(track: String) -> Dictionary:
	if _tracks.has(track):
		return _tracks[track]
	var file := FileAccess.open(TRACK_PATHS.get(track, ""), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var score: Dictionary = parsed
	if score.get("schema", 0) != 1 or score.get("id", "") != track:
		return {}
	var bpm: float = float(score.get("bpm", 0))
	var beats: float = float(score.get("beats", 0))
	if not is_finite(bpm) or bpm < 30.0 or bpm > 240.0 or not is_finite(beats) or beats <= 0.0 or beats > 256.0:
		return {}
	if not score.get("loop", null) is bool or not score.get("notes", null) is Array:
		return {}
	var notes: Array = score.notes
	if notes.is_empty() or notes.size() > 512:
		return {}
	for value: Variant in notes:
		if not value is Dictionary:
			return {}
		var note: Dictionary = value
		for key: String in ["beat", "beats", "pitch", "velocity"]:
			if not (note.get(key) is float or note.get(key) is int) or not is_finite(float(note[key])):
				return {}
		if note.beat < 0.0 or note.beat >= beats or note.beats <= 0.0 or note.beat+note.beats > beats:
			return {}
		if note.pitch != int(note.pitch) or note.pitch < 0 or note.pitch > 108 or note.velocity <= 0.0 or note.velocity > 1.0:
			return {}
		if not note.get("voice", "") in ["bell", "reed", "drone"]:
			return {}
	_tracks[track] = score
	return score


func _prepare_score(track: String) -> void:
	var score: Dictionary = _load_score(track)
	var samples_per_beat: float = 60.0/float(score.bpm)*SAMPLE_RATE
	_events.clear()
	for value: Dictionary in score.notes:
		_events.append({"start": roundi(float(value.beat)*samples_per_beat),
			"length": maxi(1, roundi(float(value.beats)*samples_per_beat)),
			"pitch": int(value.pitch), "voice": String(value.voice), "velocity": float(value.velocity)})
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.start < b.start or (a.start == b.start and a.pitch < b.pitch))
	_length_samples = roundi(float(score.beats)*samples_per_beat)
	_loop = score.loop
	_sample_cursor = 0
	_event_cursor = 0
	_loops_completed = 0
	_fade_samples = 0
	_score_done = false
	_drain_seconds = -1.0
	_voices.clear()


func _start_track() -> void:
	_halt_audio()
	_prepare_score(_current_track)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_running = _playback != null
	set_process(_running)
	if _running:
		_process(0.0)


func _halt_audio() -> void:
	_running = false
	set_process(false)
	if is_instance_valid(_player):
		_player.stop()
	_playback = null
	_voices.clear()


func _exit_tree() -> void:
	_halt_audio()
	if is_instance_valid(_player):
		_player.stream = null


func _process(delta: float) -> void:
	if not _running or _playback == null:
		return
	if _drain_seconds >= 0.0:
		_drain_seconds -= delta
		if _drain_seconds <= 0.0:
			_current_track = ""
			_halt_audio()
			return
	var available: int = mini(_playback.get_frames_available(), 4096)
	if available > 0:
		_playback.push_buffer(_mix_frames(available))
	if _score_done and _voices.is_empty() and _drain_seconds < 0.0:
		_drain_seconds = BUFFER_SECONDS + 0.05


func _mix_frames(count: int) -> PackedVector2Array:
	var buffer := PackedVector2Array()
	buffer.resize(count)
	for index: int in range(count):
		if _sample_cursor >= _length_samples and not _score_done:
			if _loop:
				_sample_cursor = 0
				_event_cursor = 0
				_loops_completed += 1
			else:
				_score_done = true
		while not _score_done and _event_cursor < _events.size() and _events[_event_cursor].start <= _sample_cursor:
			var event: Dictionary = _events[_event_cursor]
			_voices.append(Tone.new(event.pitch, event.length, event.voice, event.velocity))
			_event_cursor += 1
		var mixed: float = 0.0
		for voice_index: int in range(_voices.size()-1, -1, -1):
			var voice: Tone = _voices[voice_index]
			if voice.age >= voice.length:
				_voices.remove_at(voice_index)
			else:
				mixed += voice.sample()
		var gain: float = minf(1.0, _fade_samples/256.0)*0.22
		var sample: float = clampf(mixed*gain, -0.8, 0.8)
		buffer[index] = Vector2(sample, sample)
		_fade_samples += 1
		_sample_cursor += 1
	return buffer
