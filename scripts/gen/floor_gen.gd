class_name UndercroftFloorGen
extends RefCounted
const Catalog = preload("res://scripts/content/catalog.gd")
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const WIDTH := 17
const HEIGHT := 17
var _rng: int = 1

static func normalize_seed(raw: String) -> String:
	var seed := raw.strip_edges().to_upper()
	if seed.is_empty() or seed.length() > 6: return ""
	for letter in seed:
		if not ALPHABET.contains(letter): return ""
	return seed

func _next(limit: int) -> int:
	_rng = (1664525 * _rng + 1013904223) & 0xffffffff
	return int((_rng >> 8) % limit)

func _carve(tiles: Array, x1: int, y1: int, x2: int, y2: int) -> void:
	for y in range(y1, y2 + 1):
		for x in range(x1, x2 + 1):
			tiles[y * WIDTH + x] = 0

func generate(raw: String, count: int = 2) -> Dictionary:
	var seed := normalize_seed(raw)
	if seed.is_empty() or count < 1 or count > 4: return {"ok": false, "error": "Invalid seed or count."}
	_rng = 2166136261
	for byte in seed.to_utf8_buffer():
		_rng = ((_rng ^ byte) * 16777619) & 0xffffffff
	var floors: Array = []
	var items: Dictionary = {}
	items.knife_start = {"id": "knife_start", "kind": "knife", "location": "equip", "floor": 0, "pos": [], "slot": "hand", "spent": false}
	for index in range(count):
		var number := index + 1
		var prefix := "f%d_" % number
		var spine := 6 + _next(5)
		var side := -1 if _next(2) == 0 else 1
		var branch := spine + side * (3 + _next(2))
		var tiles: Array = []
		tiles.resize(WIDTH * HEIGHT)
		tiles.fill(1)
		_carve(tiles, spine - 2, 12, spine + 2, 15)
		_carve(tiles, spine, 4, spine, 12)
		_carve(tiles, spine - 2, 1, spine + 2, 4)
		_carve(tiles, mini(spine, branch), 9, maxi(spine, branch), 9)
		_carve(tiles, mini(spine, branch), 6, maxi(spine, branch), 6)
		_carve(tiles, branch, 6, branch, 9)
		_carve(tiles, branch - 1, 7, branch + 1, 8)
		if _next(2)==0: _carve(tiles,spine+side*3,3,spine+side*3,3)
		if _next(2)==0: _carve(tiles,spine-side*3,14,spine-side*3,14)
		var fixtures: Array = [
			{"id": prefix+"plate", "type": "plate", "pos": [spine, 13], "gate_id": prefix+"gate", "pressed": false},
			{"id": prefix+"gate", "type": "gate", "pos": [spine, 10], "plate_id": prefix+"plate", "open": false, "latched": false},
			{"id": prefix+"latch", "type": "latch", "pos": [spine, 9], "gate_id": prefix+"gate"},
			{"id": prefix+"lock", "type": "lock", "pos": [spine, 5], "key_id": prefix+"key", "open": false},
			{"id": prefix+"up", "type": "exit" if number == 1 else "stairs_up", "pos": [spine, 15]},
		]
		if number < count:
			fixtures.append({"id": prefix+"down", "type": "stairs_down", "pos": [spine, 2]})
		var visited: Array = []
		visited.resize(WIDTH * HEIGHT)
		visited.fill(false)
		floors.append({"width": WIDTH, "height": HEIGHT, "tiles": tiles, "fixtures": fixtures,
			"actors": [{"id": prefix+"husk", "kind": "husk", "pos": [spine, 7], "hp": Catalog.CREATURES.husk.hp, "state": "idle", "intent": {}}],
			"visited": visited, "start": [spine, 15], "landing": [spine, 2]})
		var offerings: Array = [
			["stone", spine, 14], ["club", spine+1, 14], ["coat", spine-1, 14],
			["bread", spine-2, 13], ["tonic", spine+2, 13], ["bone", branch, 7],
			["tonic", branch-1, 8], ["bread", branch+1, 8],
			["shard", spine-1, 3], ["lamp", spine+1, 3], ["key", branch, 8]]
		if number == count: offerings.append(["seal", spine, 2])
		for item_index in range(offerings.size()):
			var offer: Array = offerings[item_index]
			var id := prefix + (str(offer[0]) if offer[0] in ["stone", "key", "seal", "club", "coat"] else "%s_%d" % [offer[0], item_index])
			items[id] = {"id": id, "kind": offer[0], "location": "floor", "floor": number,
				"pos": [offer[1], offer[2]], "slot": "", "spent": false}
	return {"ok": true, "seed": seed, "floors": floors, "items": items}
