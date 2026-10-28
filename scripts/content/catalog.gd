class_name UndercroftCatalog
extends RefCounted
## JSON-safe content. Rules refer to capabilities/fields, never specific item IDs.
const CREATURES := {"husk":{"hp":2,"braced":true,"sight":4}}
const ITEMS := {
	"clapper": {"name":"Bell clapper","tags":["HEAVY"],"slot":"hand","damage":3,"heal":0,"provenance":"Lost by the Porter.","purpose":"Return: wakes the lift."},
	"knife": {"name": "Rust knife", "tags": ["EDGE"], "slot": "hand", "damage": 1, "heal": 0, "provenance": "Lost by a cook, 1203."},
	"stone": {"name": "Round stone", "tags": ["HEAVY"], "slot": "hand", "damage": 2, "heal": 0, "provenance": "Lost by a mason, 1211."},
	"club": {"name": "Iron club", "tags": ["HEAVY"], "slot": "hand", "damage": 2, "heal": 0, "provenance": "Lost by a guard, 1194."},
	"coat": {"name": "Padded coat", "tags": [], "slot": "body", "damage": 0, "heal": 0, "provenance": "Lost on a cold night.", "armour": 1},
	"tonic": {"name": "Red tonic", "tags": [], "slot": "", "damage": 0, "heal": 2, "provenance": "Lost by a nurse, 1209."},
	"bread": {"name": "Dry bread", "tags": ["FOOD"], "slot": "", "damage": 0, "heal": 1, "provenance": "Lost by a baker, 1211."},
	"bone": {"name": "Ham bone", "tags": ["FOOD", "HEAVY"], "slot": "hand", "damage": 2, "heal": 1, "provenance": "Lost by a dog, 1210."},
	"shard": {"name": "Glass shard", "tags": ["EDGE"], "slot": "hand", "damage": 1, "heal": 0, "provenance": "Lost from a window."},
	"lamp": {"name": "Hooded lamp", "tags": ["GLOW"], "slot": "hand", "damage": 1, "heal": 0, "provenance": "Lost by a monk, 1198."},
	"key": {"name": "Abbey key", "tags": [], "slot": "belt", "damage": 0, "heal": 0, "provenance": "It remembers its lock."},
	"seal": {"name": "Dawn Seal", "tags": ["GLOW"], "slot": "belt", "damage": 0, "heal": 0, "provenance": "Lost by the dawn."},
}
static func item(kind: String) -> Dictionary:
	return ITEMS.get(kind, {}).duplicate(true)
