extends Control
## A tiny 2D column renderer. Grid rays supply wall depth/occlusion, no 3D nodes.

const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Art = preload("res://scripts/art/item_art.gd")
const WALL_PATH := "res://assets/art/stone_wall.png"
const MONSTER_PATHS := ["res://assets/art/bell_husk_64.png", "res://assets/art/bell_husk_40.png", "res://assets/art/bell_husk_24.png"]
const FOCAL := 76.0
const HORIZON := 63
var state: Dictionary = {}
var motion := 0.0
var flash := 0.0
var _wall_strips: Array[Texture2D] = []
var _monsters: Array[Texture2D] = []
var _depths: Array[float] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture: Texture2D = load(WALL_PATH)
	var image := texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for x in range(64):
		var strip := Image.create(1, 64, false, Image.FORMAT_RGBA8)
		strip.blit_rect(image, Rect2i(x, 0, 1, 64), Vector2i.ZERO)
		_wall_strips.append(ImageTexture.create_from_image(strip))
	for path in MONSTER_PATHS:
		_monsters.append(load(path))

func update_state(snapshot: Dictionary) -> void:
	state = snapshot
	queue_redraw()

func _solid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= state.width or cell.y >= state.height:
		return true
	if state.tiles[cell.y * state.width + cell.x] == 1: return true
	for fixture in state.fixtures:
		if fixture.type in ["gate","lock"] and not fixture.open and fixture.pos==[cell.x,cell.y]: return true
	return false

func _draw() -> void:
	draw_rect(Rect2(0, 0, 154, 118), Color("0c101c"))
	if state.is_empty() or state.status == "error" or _wall_strips.is_empty():
		return
	var horizon := HORIZON + roundi(motion)
	draw_rect(Rect2(0, 18, 154, horizon - 18), Color("171d2b"))
	draw_rect(Rect2(0, horizon, 154, 118 - horizon), Color("263044"))
	for y in range(horizon + 5, 118, 8):
		draw_line(Vector2(0, y), Vector2(154, y), Color("2b3442"))
	var forward := Vector2(Sim.DIRS[state.facing][0], Sim.DIRS[state.facing][1])
	var right := Vector2(-forward.y, forward.x)
	var origin := Vector2(state.pos[0] + 0.5, state.pos[1] + 0.5)
	_depths.clear()
	for column in range(154):
		var ray := forward + right * ((column + 0.5 - 77.0) / FOCAL)
		var cell := Vector2i(floori(origin.x), floori(origin.y))
		var dx := absf(1.0 / ray.x) if absf(ray.x) > 0.00001 else 100000.0
		var dy := absf(1.0 / ray.y) if absf(ray.y) > 0.00001 else 100000.0
		var sx := 1 if ray.x > 0 else -1
		var sy := 1 if ray.y > 0 else -1
		var tx := (cell.x + 1 - origin.x) * dx if sx > 0 else (origin.x - cell.x) * dx
		var ty := (cell.y + 1 - origin.y) * dy if sy > 0 else (origin.y - cell.y) * dy
		var depth := 0.0
		var side := false
		for _step in range(24):
			if tx < ty:
				depth = tx
				tx += dx
				cell.x += sx
				side = true
			else:
				depth = ty
				ty += dy
				cell.y += sy
				side = false
			if _solid(cell):
				break
		depth = maxf(0.1, depth)
		_depths.append(depth)
		var height := maxi(1, roundi(FOCAL / depth))
		var wall_top := horizon - height / 2
		var top := maxi(18, wall_top)
		var bottom := mini(118, wall_top + height)
		var hit := origin + ray * depth
		var u := hit.y - floorf(hit.y) if side else hit.x - floorf(hit.x)
		var index := clampi(int(u * 64.0), 0, 63)
		var brightness := clampf(1.0 - depth * 0.105, 0.25, 0.9) * (0.8 if side else 1.0)
		var gate_kind: String=""
		for fixture in state.fixtures:
			if fixture.type in ["gate","lock"] and not fixture.open and fixture.pos==[cell.x,cell.y]: gate_kind=fixture.type
		if gate_kind!="":
			var colour := Color("80643c") if index % 12 < 4 or index < 3 or index > 60 else Color("171d2b")
			draw_rect(Rect2(column, top, 1, bottom - top), colour * Color(brightness, brightness, brightness) * (Color(0.65,0.9,1.2) if gate_kind=="lock" else Color.WHITE))
			for cross in [wall_top + height / 5, wall_top + height * 4 / 5]:
				if cross >= 18 and cross < 118:
					draw_rect(Rect2(column, cross, 1, maxi(1, height / 20)), Color("a18750") * Color(brightness, brightness, brightness))
		else:
			var v_start := (top - wall_top) * 64.0 / height
			var v_height := (bottom - top) * 64.0 / height
			draw_texture_rect_region(_wall_strips[index], Rect2(column, top, 1, bottom - top),
				Rect2(0, v_start, 1, v_height), Color(brightness * (0.8 if state.floor>1 else 0.95), brightness, brightness * 1.06))
	var sprites: Array = state.objects.duplicate(true)
	for fixture in state.fixtures:
		if fixture.type not in ["gate","lock"]:
			sprites.append({"kind":fixture.type,"pos":fixture.pos})
	for actor in state.actors:
		if actor.hp>0: sprites.append({"kind":actor.kind,"pos":actor.pos,"state":actor.state})
	for sprite in sprites:
		var relative := Vector2(sprite.pos[0] + 0.5, sprite.pos[1] + 0.5) - origin
		sprite.depth = relative.dot(forward)
		sprite.lateral = relative.dot(right)
	sprites.sort_custom(func(a, b): return a.depth > b.depth)
	for sprite in sprites:
		if sprite.depth < 0.5 or sprite.depth > 4.0:
			continue
		var depth: float = sprite.depth
		var screen_x := roundi(77 + sprite.lateral * FOCAL / depth)
		var ground := horizon + roundi(FOCAL * 0.5 / depth)
		var texture: Texture2D
		var tall: int
		var tint := Color.WHITE
		if sprite.kind == "husk":
			var variant := 0 if depth < 1.5 else (1 if depth < 2.5 else 2)
			texture = _monsters[variant]
			tall = [64, 40, 24][variant]
			if sprite.state == "recovery":
				tint = Color(0.67, 0.75, 0.8)
				ground += 3
		else:
			texture = Art.texture(sprite.kind)
			tall = maxi(5, roundi((42.0 if sprite.kind in ["exit","stairs_up","stairs_down"] else 20.0) / depth))
		var wide := maxi(1, roundi(tall * texture.get_width() / float(texture.get_height())))
		var left := screen_x - wide / 2
		var top := ground - tall
		for column in range(maxi(0, left), mini(154, left + wide)):
			if depth >= _depths[column]:
				continue
			var source_x := floorf((column - left) * texture.get_width() / float(wide))
			draw_texture_rect_region(texture, Rect2(column, top, 1, tall), Rect2(source_x, 0, 1, texture.get_height()), tint)
	if flash > 0:
		draw_rect(Rect2(2, 20, 150, 96), Color(0.9, 0.15, 0.1, flash), false, 3)
