extends SceneTree
const Required=preload("res://scripts/art/required_art.gd")
func _initialize() -> void:
	var file:=FileAccess.open("res://build/m5a_required_art.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(Required.paths(),"\t")); file.close()
	print("M5a required texture inventory written."); quit()
