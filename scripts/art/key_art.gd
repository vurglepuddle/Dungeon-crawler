extends RefCounted
## B's R12 paintings. The belt deliberately keeps the generic key icon.
const Paint=preload("res://scripts/art/presentation_art.gd")
const METALS=["iron","bronze","gold"]
static func icon_path(metal: String) -> String: return "res://assets/art/items/icon_key_%s_16.png"%metal
static func icon(metal: String) -> Texture2D: return Paint.texture(icon_path(metal))
static func world_path(metal: String,distance: int) -> String: return "res://assets/art/items/item_key_%s_d%d.png"%[metal,distance]
static func plate_path(family: int,metal: String) -> String: return "res://assets/art/fixtures/lock_plate_f%d_%s_64.png"%[family,metal]
static func required() -> Array:
	var paths: Array=[]
	for metal in METALS:
		paths.append(icon_path(metal))
		for d in range(1,4): paths.append(world_path(metal,d))
		for family in range(1,5): paths.append(plate_path(family,metal))
	return paths
