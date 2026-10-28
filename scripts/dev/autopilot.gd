extends Node
## Autoload "Autopilot": scripted playtesting of the real game. It does nothing
## unless the game is started with user args, e.g.
##   Godot --path . --resolution 462x1026 -- --pilot=res://tests/pilot/title.txt --out=C:/tmp/shots
## A pilot file has one command per line:
##   wait N          let N frames pass
##   waitidle        wait until the screen says it isn't animating
##   tap X Y         touch press+release at logical coordinates
##   tapnamed NAME   tap the centre of a named control; the screen answers
##                   pilot_call("where", [NAME]) with "x y" in logical pixels
##   swipe DIR [X Y] one swipe up/down/left/right, centred on X Y (default:
##                   the middle of the first-person view)
##   hold X Y N      touch down at X Y, keep it down for N frames, release
##   key NAME        press a key (e.g. KEY_SPACE)
##   call METHOD     call a method on the current screen (debug hooks)
##   shot NAME       save the logical frame (upscaled 3x) as NAME.png in --out
##   close           behave like the OS closing the app (WM_CLOSE_REQUEST, which
##                   should save), then quit; a second pilot run can Continue
##   pause           send APPLICATION_PAUSED (Android backgrounding) to the tree
##   quit
## Blank lines and lines starting with # are ignored.
## Pilot runs are muted (master bus) unless --with-sound is passed.

var _lines: PackedStringArray = []
var _pc := 0
var _wait := 0
var _out := ""
var _deadline := 0 # msec; a stuck pilot quits instead of hanging the window
var _pending_release := false
var _release_at := Vector2.ZERO


func _ready() -> void:
	var pilot := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pilot="):
			pilot = arg.trim_prefix("--pilot=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--timeout="):
			_deadline = int(arg.trim_prefix("--timeout=")) * 1000
	if pilot == "":
		set_process(false)
		return
	_lines = FileAccess.get_file_as_string(pilot).split("\n")
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.set_meta("pilot", true)
	# Pilots run in real windows on the owner's desktop: keep them silent unless
	# a run asks for sound. Muting the master bus leaves the game's own MUSIC/SFX
	# switches (and pilots that test them) untouched.
	if not OS.get_cmdline_user_args().has("--with-sound"):
		AudioServer.set_bus_mute(0, true)
	_deadline = Time.get_ticks_msec() + (_deadline if _deadline > 0 else 120000)
	print("[pilot] running ", pilot)


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() > _deadline:
		push_error("[pilot] timed out at line %d: %s" % [_pc, _lines[mini(_pc, _lines.size() - 1)]])
		get_tree().quit(1)
		return
	if _wait > 0:
		_wait -= 1
		return
	if _pending_release:
		_pending_release = false
		_touch(_release_at, false)
		_wait = 2
		return
	while _pc < _lines.size():
		var line := _lines[_pc].strip_edges()
		_pc += 1
		if line == "" or line.begins_with("#"):
			continue
		var a := line.split(" ", false)
		match a[0]:
			"wait":
				_wait = int(a[1])
				return
			"waitidle":
				var scr := get_tree().current_scene
				if scr and scr.has_method("pilot_call") and scr.pilot_call("busy", []) == "1":
					_pc -= 1 # re-check this line next frame
					return
			"tap":
				_touch(Vector2(float(a[1]), float(a[2])), true)
				_touch(Vector2(float(a[1]), float(a[2])), false)
				_wait = 2
				return
			"tapnamed":
				var scr := get_tree().current_scene
				var where := ""
				if scr and scr.has_method("pilot_call"):
					where = str(scr.pilot_call("where", [a[1]]))
				var xy := where.split(" ", false)
				if xy.size() != 2:
					push_error("[pilot] no control named " + a[1])
					get_tree().quit(1)
					return
				_touch(Vector2(float(xy[0]), float(xy[1])), true)
				_touch(Vector2(float(xy[0]), float(xy[1])), false)
				_wait = 2
				return
			"swipe":
				var at := Vector2(77, 56)
				if a.size() >= 4:
					at = Vector2(float(a[2]), float(a[3]))
				_swipe(a[1], at)
				_wait = 2
				return
			"hold":
				_touch(Vector2(float(a[1]), float(a[2])), true)
				_release_at = Vector2(float(a[1]), float(a[2]))
				_wait = int(a[3])
				_pending_release = true
				return
			"close":
				get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
				get_tree().quit()
				return
			"pause":
				get_tree().root.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
			"key":
				var ev := InputEventKey.new()
				ev.keycode = OS.find_keycode_from_string(a[1].trim_prefix("KEY_"))
				ev.pressed = true
				Input.parse_input_event(ev)
			"call":
				var scr := get_tree().current_scene
				if scr and scr.has_method("pilot_call"):
					print("[pilot] ", scr.pilot_call(a[1], a.slice(2)))
			"shot":
				_shot(a[1])
			"quit":
				get_tree().quit()
				return
			_:
				push_error("[pilot] unknown command: " + line)
	get_tree().quit()


func _touch(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = _to_window(pos)
	ev.pressed = pressed
	# Godot's emulate_mouse_from_touch turns this into a click for Buttons.
	Input.parse_input_event(ev)


func _swipe(dir: String, c: Vector2) -> void:
	var v := {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}[dir] as Vector2
	var a := InputEventScreenTouch.new()
	a.position = _to_window(c)
	a.pressed = true
	Input.parse_input_event(a)
	var d := InputEventScreenDrag.new()
	d.position = _to_window(c + v * 30.0)
	d.relative = v * 30.0
	Input.parse_input_event(d)
	var b := InputEventScreenTouch.new()
	b.position = d.position
	b.pressed = false
	Input.parse_input_event(b)


## Logical (viewport) coordinates to window coordinates.
func _to_window(p: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * p


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	var path := _out.path_join(shot_name + ".png")
	img.save_png(path)
	print("[pilot] shot ", path)
