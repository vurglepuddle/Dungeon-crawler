extends Control
## Only owner-named sockets plus the separate candle. No simulation RNG/state.
const Paint=preload("res://scripts/art/presentation_art.gd")
const CANDLE="res://assets/art/ui/owner_candle.png"
var config: Dictionary={}
var candle_layout: Dictionary={}
var candle: Texture2D
var frozen: bool=false
var _rng:=RandomNumberGenerator.new()
var _wait: float=12
var _candle_wait: float=0.5
var _candle_frame: int=0
var _active: Dictionary={}
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE; texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/overlay_glints.json"))
	if FileAccess.file_exists("res://data/ui/overlay_candle.json"): candle_layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/overlay_candle.json"))
	if FileAccess.file_exists(CANDLE) or ResourceLoader.exists(CANDLE): candle=Paint.texture(CANDLE)
	frozen=Engine.has_meta("pilot")
	if not frozen:
		_rng.randomize(); _wait=_rng.randf_range(config.wait_seconds[0],config.wait_seconds[1])
	set_process(not frozen)
func _process(delta: float) -> void:
	if frozen or not is_visible_in_tree(): return
	_wait-=delta; _candle_wait-=delta
	if not _active.is_empty():
		_active.age+=delta
		if _active.age>=config.duration: _active={}
	if _wait<=0:
		var skull: int=_rng.randi_range(0,config.skulls.size()-1)
		var pair: bool=_rng.randf()<config.pair_chance
		_active={"skull":skull,"eyes":[0,1] if pair else [_rng.randi_range(0,1)],"age":0.0}
		_wait=_rng.randf_range(config.wait_seconds[0],config.wait_seconds[1])
	if _candle_wait<=0:
		_candle_frame=1-_candle_frame
		var base: float=candle_layout.get("duration_seconds",[0.43,0.27])[_candle_frame]
		_candle_wait=base+_rng.randf_range(-0.04,0.04)
	queue_redraw()
func _draw() -> void:
	if get_parent().texture==null: return
	if candle!=null and not candle_layout.is_empty():
		var offset:=Vector2(candle_layout.offset[0],candle_layout.offset[1])
		var frame_size:=Vector2(candle.get_width()/2,candle.get_height())
		draw_texture_rect_region(candle,Rect2(offset,frame_size),Rect2(Vector2(_candle_frame*frame_size.x,0),frame_size))
	if _active.is_empty(): return
	var phase: int=clampi(int(_active.age/config.duration*5),0,4)
	var ink:=Color(config.palette[[0,1,2,1,0][phase]])
	for eye in _active.eyes:
		var p: Array=config.skulls[_active.skull].sockets[eye]
		draw_rect(Rect2(p[0],p[1],1,1),ink)
