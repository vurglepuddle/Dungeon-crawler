extends Node2D
## Presentation only. No simulation, input, RNG, audio, textures or save access.
## Coordinates passed to set_view_rect() are local to this Node2D.
## Redraws at 20 Hz; at most 12 dust pixels, 3 drips and 3 screen rectangles.
signal fade_finished(dark: bool)

@export var dust_enabled: bool = true
@export var drips_enabled: bool = true
@export var lamp_flicker_enabled: bool = true
@export_range(0.0, 1.0) var intensity: float = 1.0

var view_rect: Rect2 = Rect2(0, 0, 148, 150)
var floor_index: int = 1
var _clock: float = 0.0
var _redraw_clock: float = 0.0
var _fade_alpha: float = 0.0
var _fade_from: float = 0.0
var _fade_target: float = 0.0
var _fade_time: float = 0.0
var _fade_duration: float = 0.0
var _fading: bool = false
var _flash_colour: Color = Color("efe3ba")
var _flash_left: float = 0.0
var _flash_duration: float = 0.18
var _flash_amount: float = 0.18

func set_view_rect(rect: Rect2) -> void:
	view_rect = rect.abs()
	queue_redraw()

func set_floor(number: int) -> void:
	floor_index = maxi(1, number)
	queue_redraw()

func flash(colour: Color = Color("efe3ba"), seconds: float = 0.18, amount: float = 0.18) -> void:
	_flash_colour = colour
	_flash_duration = maxf(0.0, seconds)
	_flash_left = _flash_duration
	_flash_amount = clampf(amount, 0.0, 0.35)
	queue_redraw()

func fade_out(seconds: float = 0.22) -> void:
	_start_fade(1.0, seconds)

func fade_in(seconds: float = 0.28) -> void:
	_start_fade(0.0, seconds)

func fade_alpha() -> float:
	return _fade_alpha

func lamp_gain() -> float:
	if not lamp_flicker_enabled:
		return 1.0
	# Slow overlapping waves, 0.7%-2.3% black veil; never a flashing lamp.
	return 1.0 - (0.015 + sin(_clock * 1.7) * 0.005 + sin(_clock * 3.1 + 0.7) * 0.003) * clampf(intensity, 0.0, 1.0)

func _start_fade(target: float, seconds: float) -> void:
	_fade_from = _fade_alpha
	_fade_target = target
	_fade_time = 0.0
	_fade_duration = maxf(0.0, seconds)
	_fading = _fade_duration > 0.0
	if not _fading:
		_fade_alpha = target
		fade_finished.emit(target >= 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	var elapsed: float = maxf(0.0, delta)
	_clock = fmod(_clock + elapsed, 3600.0)
	_flash_left = maxf(0.0, _flash_left - elapsed)
	if _fading:
		_fade_time = minf(_fade_duration, _fade_time + elapsed)
		var t: float = _fade_time / _fade_duration
		_fade_alpha = lerpf(_fade_from, _fade_target, t * t * (3.0 - 2.0 * t))
		if _fade_time >= _fade_duration:
			_fading = false
			_fade_alpha = _fade_target
			fade_finished.emit(_fade_target >= 1.0)
			queue_redraw()
	_redraw_clock += elapsed
	if _redraw_clock >= 0.05:
		_redraw_clock = fmod(_redraw_clock, 0.05)
		if visible and view_rect.has_area():
			queue_redraw()

func _ink(rect: Rect2, colour: Color) -> void:
	var clipped: Rect2 = rect.intersection(view_rect)
	if clipped.has_area():
		draw_rect(clipped, colour)

func _draw() -> void:
	if not view_rect.has_area():
		return
	var strength: float = clampf(intensity, 0.0, 1.0)
	var span: Vector2 = view_rect.size
	if dust_enabled and strength > 0.0:
		for i in range(12):
			var x: float = fposmod(i * 37.0 + sin(_clock * 0.19 + i) * 5.0 + _clock * (0.5 + i * 0.03), span.x)
			var y: float = fposmod(i * 23.0 - _clock * (0.8 + i * 0.07), span.y)
			var light: float = maxf(0.0, 1.0 - absf(x - span.x * 0.5) / (span.x * 0.55))
			var alpha: float = (0.04 + light * 0.16) * strength
			_ink(Rect2(view_rect.position + Vector2(floorf(x), floorf(y)), Vector2.ONE), Color(0.83, 0.78, 0.64, alpha))
	if floor_index >= 2 and drips_enabled and strength > 0.0:
		for i in range(3):
			var phase: float = fposmod(_clock * 0.27 + i * 0.37, 1.0)
			if phase > 0.27:
				continue
			var x: float = floorf(span.x * (0.18 + i * 0.31))
			var y: float = floorf(span.y * (0.06 + phase * phase * 9.5))
			_ink(Rect2(view_rect.position + Vector2(x, y), Vector2(1, 2)), Color(0.45, 0.64, 0.60, 0.23 * strength))
	_ink(view_rect, Color(0, 0, 0, 1.0 - lamp_gain()))
	if _flash_left > 0.0 and _flash_duration > 0.0:
		var colour: Color = _flash_colour
		colour.a = _flash_amount * (_flash_left / _flash_duration) * strength
		_ink(view_rect, colour)
	# Transition black is last, so dust and flashes cannot bleed through stairs.
	if _fade_alpha > 0.0:
		_ink(view_rect, Color(0, 0, 0, _fade_alpha))
