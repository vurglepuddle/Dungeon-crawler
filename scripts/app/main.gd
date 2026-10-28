extends Control

const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Witness = preload("res://scripts/gen/witness.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")
const View = preload("res://scripts/view/dungeon_view.gd")
const FONT = preload("res://assets/font/vetka.ttf")
const PORTRAIT = preload("res://assets/art/finder.png")
const INK := Color("d3c8a4")
const GOLD := Color("eeb95a")
var sim
var state: Dictionary = {}
var selected := ""
var lines: Array = ["Find the way out.", "Take the stone ahead."]
var controls: Dictionary = {}
var verbs: Array = []
var view
var _busy := 0.0
var _duration := 0.14
var _hurt := false
var _modal: PanelContainer
var _seed_input: LineEdit
var _modal_error: Label
var _stone_icon: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view = View.new()
	view.position = Vector2.ZERO
	view.size = Vector2(154, 118)
	view.clip_contents = true
	add_child(view)
	var icon := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	icon.fill(Color.TRANSPARENT)
	for y in range(16):
		for x in range(16):
			if absf(x - 7.5) / 7.0 + absf(y - 7.5) / 6.0 < 1.1:
				icon.set_pixel(x, y, Color("b6ae91") if x + y < 15 else Color("59616a"))
	_stone_icon = ImageTexture.create_from_image(icon)
	_create_controls()
	new_run("BELL42")

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.content_margin_left = 1
	box.content_margin_right = 1
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box

func _button(name_key: String, rect: Rect2, label: String, callback: Callable, visible_fill: bool = true) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_pressed_color", Color("efe3ba"))
	if visible_fill:
		button.add_theme_stylebox_override("normal", _style(Color("171d2b"), Color("59616a")))
		button.add_theme_stylebox_override("hover", _style(Color("263044"), GOLD))
		button.add_theme_stylebox_override("pressed", _style(Color("3b4757"), GOLD))
	else:
		for style_name in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	button.pressed.connect(callback)
	add_child(button)
	controls[name_key] = button
	return button

func _create_controls() -> void:
	_button("seed", Rect2(3, 0, 80, 18), "", _open_seed, false)
	_button("new_seed", Rect2(114, 0, 38, 18), "NEW", _random_run, false)
	_button("portrait", Rect2(3, 156, 32, 32), "", _portrait_help, false)
	for i in range(4):
		_button("pack%d" % i, Rect2(9 + i * 34, 192, 32, 22), "", _select.bind(i))
	for i in range(3):
		_button("verb%d" % i, Rect2(3 + i * 50, 239, 48, 22), "", _verb.bind(i))
	var names := ["turn_l", "fwd", "turn_r", "strafe_l", "back", "strafe_r"]
	for i in range(6):
		_button(names[i], Rect2(20 + (i % 3) * 41, 266 + (i / 3) * 38, 32, 32), "", _movement.bind(names[i]), false)
	_button("hot_front", Rect2(48, 82, 58, 25), "", _hotspot)
	controls.hot_front.visible = false

func new_run(raw: String) -> bool:
	var seed := Gen.normalize_seed(raw)
	if seed.is_empty():
		return false
	var proof: Dictionary = Witness.build(seed)
	if not proof.ok:
		lines = ["Floor failed its test.", "Try another seed."]
		push_error("Generation witness failed: " + seed + " " + proof.reason)
		queue_redraw()
		return false
	sim = Sim.new(seed)
	selected = ""
	_busy = 0
	_hurt = false
	lines = ["Find the way out.", "Take the stone ahead."]
	_sync()
	return true

func _sync() -> void:
	state = sim.snapshot()
	controls.seed.text = state.seed
	if not state.pack.has(selected):
		selected = ""
	verbs = sim.legal_verbs(selected)
	for i in range(3):
		var button: Button = controls["verb%d" % i]
		button.visible = i < verbs.size() or state.status != "playing" and i < 2
		button.text = verbs[i].label if i < verbs.size() else ""
	if state.status != "playing":
		controls.verb0.text = "RETRY"
		controls.verb1.text = "NEW"
	for i in range(4):
		var button: Button = controls["pack%d" % i]
		button.text = "" if i < state.pack.size() else "-"
		button.icon = _stone_icon if i < state.pack.size() else null
		button.add_theme_stylebox_override("normal", _style(Color("263044") if i < state.pack.size() and state.pack[i] == selected else Color("171d2b"), GOLD if i < state.pack.size() and state.pack[i] == selected else Color("59616a")))
	var front: Dictionary = sim.inspect_front()
	var hotspot: Button = controls.hot_front
	hotspot.visible = false
	hotspot.text = ""
	if state.status == "playing":
		if not selected.is_empty():
			var targets: Array = sim.targets(selected)
			if not targets.is_empty():
				hotspot.visible = true
				hotspot.text = targets[0].verb
		elif front.monster != "" or front.item != "" or front.plate or front.exit:
			hotspot.visible = true
			hotspot.text = "LOOK" if front.monster != "" or front.plate and front.item == "" else ("LEAVE" if front.exit else "TAKE")
		if front.monster != "":
			hotspot.position = Vector2(45, 35)
			hotspot.size = Vector2(64, 67)
			hotspot.text = ""
			for style_name in ["normal", "hover", "pressed"]:
				hotspot.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
		else:
			hotspot.position = Vector2(48, 68 if not front.exit else 90)
			hotspot.size = Vector2(58, 22)
			for style_name in ["normal", "hover", "pressed"]:
				hotspot.add_theme_stylebox_override(style_name, _style(Color("171d2b"), GOLD if not selected.is_empty() else Color("59616a")))
	view.update_state(state)
	queue_redraw()

func _can_input() -> bool:
	return _busy <= 0 and not is_instance_valid(_modal)

func _command(command: Dictionary) -> void:
	if not _can_input():
		return
	command = command.duplicate(true)
	command.expected_revision = state.revision
	var result: Dictionary = sim.apply(command)
	if not result.accepted:
		lines = [result.reason, ""]
		queue_redraw()
		return
	_hurt = false
	lines = ["Stone waits. So do you.", ""]
	match command.type:
		"move": lines = ["Footsteps in the dust.", ""]
		"turn": lines = ["You take a look.", "Looking costs no turn."]
		"pickup": lines = ["Round stone. HEAVY.", "A mason lost it, 1211."]
		"place": lines = ["The plate sinks.", "The gate latches open."]
		"guard": lines = ["You brace yourself.", ""]
		"hit": lines = ["Your fist rings bronze.", ""]
	for event in result.events:
		if event.type == "attack_resolved":
			if event.blocked:
				lines = ["You catch its blow.", "It reels. HIT now."]
			elif event.damage > 0:
				_hurt = true
				lines = ["Its arm finds you.", "GUARD the raised arm."]
			else:
				lines = ["Its blow finds air.", "It reels. HIT now."]
		elif event.type == "intent_announced":
			lines = ["The Husk raises an arm.", "GUARD or step away."]
		elif event.type == "monster_defeated":
			lines = ["The bell falls silent.", "The way is clear."]
		elif event.type == "run_ended":
			lines = ["Daylight. You made it.", "The abbey waits below."] if event.status == "won" else ["Lost, like the others.", "Try the seed again."]
	_busy = _duration if result.consumed_turn else 0.06
	_sync()

func _movement(key: String) -> void:
	if state.status != "playing":
		return
	if key in ["turn_l", "turn_r"]:
		_command({"type": "turn", "delta": -1 if key == "turn_l" else 1})
	else:
		_command({"type": "move", "step": key})

func _select(index: int) -> void:
	if not _can_input() or state.status != "playing":
		return
	if index >= state.pack.size():
		lines = ["An empty pocket.", ""]
	else:
		var item: String = state.pack[index]
		selected = "" if selected == item else item
		lines = ["Round stone. HEAVY.", "Touch a PLACE marker."] if not selected.is_empty() else ["Your hand is clear.", ""]
	_sync()

func _verb(index: int) -> void:
	if not _can_input():
		return
	if state.status != "playing":
		if index == 0:
			new_run(state.seed)
		elif index == 1:
			_random_run()
	elif index < verbs.size():
		_command(verbs[index].action)

func _hotspot() -> void:
	if not _can_input():
		return
	if not selected.is_empty():
		var targets: Array = sim.targets(selected)
		if not targets.is_empty():
			_command(targets[0].action)
		return
	var front: Dictionary = sim.inspect_front()
	if front.monster != "":
		lines = ["A hollow bell, awake.", "GUARD, then HIT it."]
		queue_redraw()
	elif sim.can_pickup():
		_command({"type": "pickup", "item_id": "stone"})
	elif front.exit:
		_command({"type": "leave", "target_id": "exit"})
	elif front.plate:
		lines = ["A plate wants weight.", "Select a HEAVY thing."]
		queue_redraw()

func _portrait_help() -> void:
	if _can_input():
		lines = ["Curved arrows turn.", "Straight arrows step."]
		queue_redraw()

func _random_run() -> void:
	if not _can_input():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize() # Seed choice belongs to the app, never to deterministic rules.
	var seed := ""
	for _i in range(6):
		seed += Gen.ALPHABET[rng.randi_range(0, Gen.ALPHABET.length() - 1)]
	new_run(seed)

func _open_seed() -> void:
	if not _can_input():
		return
	_modal = PanelContainer.new()
	_modal.position = Vector2(5, 70)
	_modal.size = Vector2(144, 178)
	_modal.add_theme_stylebox_override("panel", _style(Color("171d2b"), GOLD))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_modal.add_child(column)
	var title := Label.new()
	title.text = "Choose a seed"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)
	_seed_input = LineEdit.new()
	_seed_input.text = state.seed
	_seed_input.max_length = 6
	_seed_input.custom_minimum_size = Vector2(138, 26)
	_seed_input.add_theme_font_override("font", FONT)
	_seed_input.add_theme_font_size_override("font_size", 16)
	column.add_child(_seed_input)
	controls.seed_input = _seed_input
	_modal_error = Label.new()
	_modal_error.text = "No I, O, 0 or 1."
	_modal_error.add_theme_font_override("font", FONT)
	_modal_error.add_theme_font_size_override("font_size", 16)
	column.add_child(_modal_error)
	for label in ["START", "CANCEL"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(138, 26)
		button.add_theme_font_override("font", FONT)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_seed_submit if label == "START" else _close_seed)
		column.add_child(button)
		controls["seed_start" if label == "START" else "seed_cancel"] = button
	add_child(_modal)
	_seed_input.grab_focus()

func _seed_submit() -> void:
	if Gen.normalize_seed(_seed_input.text).is_empty():
		_modal_error.text = "Use A-Z, 2-9."
		return
	var seed := _seed_input.text
	_close_seed()
	new_run(seed)

func _close_seed() -> void:
	if is_instance_valid(_modal):
		_modal.queue_free()
		_modal = null
		for key in ["seed_input", "seed_start", "seed_cancel"]:
			controls.erase(key)

func _process(delta: float) -> void:
	if _busy > 0:
		_busy = maxf(0, _busy - delta)
		view.motion = sin((_duration - _busy) / _duration * PI) * 1.5
		view.flash = _busy / _duration if _hurt else 0.0
		view.queue_redraw()
		if _busy <= 0:
			view.motion = 0
			view.flash = 0

func _text(at: Vector2, value: String, colour: Color = INK) -> void:
	draw_string(FONT, at + Vector2(0, FONT.get_ascent(16)), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, colour)

func _draw() -> void:
	# The view is a child, so HUD bands are drawn here below its 118px boundary.
	draw_rect(Rect2(0, 118, 154, 224), Color("0c101c"))
	for y in [118, 154, 190, 238, 262]:
		draw_line(Vector2(0, y), Vector2(154, y), Color("59616a"))
	_text(Vector2(4, 119), lines[0])
	_text(Vector2(4, 135), lines[1])
	if state.is_empty():
		return
	draw_texture_rect(PORTRAIT, Rect2(3, 156, 32, 32), false)
	_text(Vector2(41, 155), "HP %d/%d" % [state.hp, state.max_hp], GOLD if _hurt else INK)
	_text(Vector2(41, 171), "FACE " + ["N", "E", "S", "W"][state.facing])
	for x in [106, 130]:
		draw_rect(Rect2(x, 158, 20, 26), Color("263044"), false)
		draw_line(Vector2(x + 5, 171), Vector2(x + 15, 171), Color("59616a"))
	_text(Vector2(9, 216), "HEAVY / select to use" if not selected.is_empty() else "PACK / 4 pockets", GOLD if not selected.is_empty() else Color("777970"))
	for i in range(6):
		var key: String = ["turn_l", "fwd", "turn_r", "strafe_l", "back", "strafe_r"][i]
		var button: Button = controls[key]
		var rect := button.get_rect()
		draw_rect(rect, Color("263044") if button.is_pressed() else Color("171d2b"))
		draw_rect(rect, Color("80643c") if key.begins_with("turn") else Color("59616a"), false)
		_arrow(rect.get_center(), key)

func _arrow(center: Vector2, key: String) -> void:
	var colour := GOLD if key.begins_with("turn") else Color("a8c2ad")
	if key.begins_with("turn"):
		var direction := -1 if key == "turn_l" else 1
		var points := PackedVector2Array([center + Vector2(-direction * 7, 8), center + Vector2(-direction * 7, -6), center + Vector2(direction * 7, -6)])
		draw_polyline(points, colour, 2)
		draw_colored_polygon(PackedVector2Array([center + Vector2(direction * 9, -6), center + Vector2(direction * 2, -11), center + Vector2(direction * 2, -1)]), colour)
	else:
		var direction := Vector2(0, -1) if key == "fwd" else (Vector2(0, 1) if key == "back" else (Vector2(-1, 0) if key == "strafe_l" else Vector2(1, 0)))
		var side := Vector2(-direction.y, direction.x)
		draw_line(center - direction * 8, center + direction * 6, colour, 2)
		draw_colored_polygon(PackedVector2Array([center + direction * 11, center + direction * 3 + side * 5, center + direction * 3 - side * 5]), colour)
		if key.begins_with("strafe"):
			draw_line(center - direction * 10 - side * 6, center - direction * 10 + side * 6, colour, 2)

func _public_state() -> Dictionary:
	return {"seed": state.seed, "floor": state.floor, "pos": state.pos.duplicate(),
		"facing": state.facing, "hp": state.hp, "turn": state.turn,
		"revision": state.revision, "status": state.status, "pack": state.pack.duplicate(),
		"selected": selected, "front": sim.inspect_front(), "gate_open": state.gate.open}

func pilot_call(name_key: String, args: Array) -> String:
	match name_key:
		"busy": return "1" if not _can_input() else "0"
		"state": return JSON.stringify(_public_state())
		"where":
			if args.is_empty(): return ""
			var key := str(args[0])
			if key == "view": return "77 63"
			if key in ["hot_item", "hot_plate", "hot_husk", "hot_exit"]:
				var front: Dictionary = sim.inspect_front()
				var present: bool = {"hot_item": front.item != "", "hot_plate": front.plate,
					"hot_husk": front.monster != "", "hot_exit": front.exit}[key]
				if not present: return ""
				key = "hot_front"
			if controls.has(key) and controls[key].visible:
				var center: Vector2 = controls[key].get_global_rect().get_center()
				return "%d %d" % [roundi(center.x), roundi(center.y)]
			return ""
		"new_run":
			if args.is_empty() or not new_run(str(args[0])): return JSON.stringify({"error": "Invalid seed or floor."})
			_close_seed()
			return JSON.stringify(_public_state())
		"assert":
			if args.size() < 2: return "error"
			var actual = _public_state().get(str(args[0]))
			var expected := str(args[1])
			if actual is String and expected.begins_with('"') and expected.ends_with('"'):
				var decoded = JSON.parse_string(expected)
				if decoded is String:
					expected = decoded
			var value := str(actual) if actual is String else JSON.stringify(actual)
			if value != expected:
				push_error("Pilot assertion: %s expected %s got %s" % [args[0], expected, value])
				# Autopilot may execute its next `quit` in this same frame.
				# Defer our nonzero exit so a trailing quit cannot overwrite it.
				get_tree().quit.call_deferred(1)
				return "failed"
			return "ok"
	return ""
