class_name UndercroftFloorGen
extends RefCounted
## Small constructive M1 generator. No engine/global RNG or scene dependency.

const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const WIDTH := 9
const HEIGHT := 11
var _rng: int = 1

static func normalize_seed(raw: String) -> String:
	var seed := raw.strip_edges().to_upper()
	if seed.is_empty() or seed.length() > 6:
		return ""
	for letter in seed:
		if not ALPHABET.contains(letter):
			return ""
	return seed

func _next(limit: int) -> int:
	_rng = (1664525 * _rng + 1013904223) & 0xffffffff
	return int((_rng >> 8) % limit)

func generate(raw: String) -> Dictionary:
	var seed := normalize_seed(raw)
	if seed.is_empty():
		return {"ok": false, "error": "Use 1-6 seed symbols."}
	_rng = 2166136261
	for byte in seed.to_utf8_buffer():
		_rng = ((_rng ^ byte) * 16777619) & 0xffffffff
	var aisle := 3 + _next(3)
	var side := -1 if _next(2) == 0 else 1
	if aisle == 3:
		side = 1
	elif aisle == 5:
		side = -1
	var tiles: Array = []
	tiles.resize(WIDTH * HEIGHT)
	tiles.fill(1)
	var route: Array = []
	for y in range(9, 2, -1):
		route.append([aisle, y])
	route.append([aisle + side, 3])
	route.append([aisle + side * 2, 3])
	route.append([aisle + side * 2, 2])
	route.append([aisle + side * 2, 1])
	for cell in route:
		tiles[cell[1] * WIDTH + cell[0]] = 0
	# A little entry room and optional alcoves. None crosses the gate cut.
	for y in [8, 9]:
		for x in range(aisle - 1, aisle + 2):
			tiles[y * WIDTH + x] = 0
	var alcove_side := -1 if _next(2) == 0 else 1
	tiles[5 * WIDTH + aisle + alcove_side] = 0
	var extra := 1 + _next(2)
	for dx in range(1, extra + 1):
		tiles[8 * WIDTH + aisle - side * dx] = 0
	return {
		"ok": true, "generator_version": "m1.1", "seed": seed,
		"width": WIDTH, "height": HEIGHT, "tiles": tiles,
		"start": [aisle, 9], "facing": 0, "route": route,
		"stone": [aisle, 8], "plate": [aisle, 7],
		"gate": [aisle, 6], "husk": [aisle, 4],
		"exit": route[-1].duplicate(), "side": side,
	}
