extends SceneTree
## External probe: run against --main-pack build/m3d_resources.pck.
const Paint=preload("res://scripts/art/presentation_art.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void:
	check(not FileAccess.file_exists("res://tests/test_m3d.gd"),"Probe uses exported resources, not the source-tree test directory")
	for floor in [1,2]:
		for suffix in ["plain_0","plain_1","plain_2","sconce_0","sconce_1","crack","damp","chains","tapestry","drain","arch","door"]:
			var texture: Texture2D=Paint.texture("res://assets/art/env/painted_f%d_%s.png"%[floor,suffix])
			check(texture!=null and texture.get_size()==Vector2(64,64),"Packed painted wall "+suffix)
		for suffix in ["floor","ceiling"]:
			check(Paint.image("res://assets/art/env/f%d_%s.png"%[floor,suffix]).get_size()==Vector2i(64,64),"Packed cast surface "+suffix)
		for kind in ["exit","stairs_down","stairs_up","gate_closed","gate_open","lift_dead","lift_working"]:
			var texture: Texture2D=Paint.texture("res://assets/art/fixtures/architecture_f%d_%s_64.png"%[floor,kind])
			check(texture!=null and texture.get_size()==Vector2(64,64),"Packed architecture "+kind)
		for state in ["open","closed"]:
			var image: Image=Paint.image("res://assets/art/fixtures/architecture_f%d_gate_%s_overlay_64.png"%[floor,state])
			check(image.detect_alpha()!=Image.ALPHA_NONE,"Packed gate retains real transparency")
	for kind in ["knife","lamp","stone","bone","bread","torch","clapper","shard","tonic","club","coat","key","seal"]:
		check(Paint.texture("res://assets/art/icons/%s.png"%kind).get_size()==Vector2(16,16),"Packed icon "+kind)
	for kind in ["finder_fine","finder_hurt_v2","finder_near_death_v2"]:
		check(Paint.texture("res://assets/art/portrait/%s.png"%kind).get_size()==Vector2(32,32),"Packed Finder "+kind)
	for kind in ["splash","title","win","death"]:
		check(Paint.texture("res://assets/art/screens/%s.png"%kind)!=null,"Packed story plate "+kind)
	for family in ["gold","target"]:
		for frame in range(3):
			for pixels in [7,9]:
				check(Paint.texture("res://assets/art/fixtures/glint_%s_%d_%d.png"%[family,frame,pixels]).get_size()==Vector2(pixels,pixels),"Packed sparkle frame")
	check(Paint.texture("res://assets/art/ui_offer/map_parchment.png").get_size()==Vector2(144,324),"Packed parchment")
	for path in ["data/text/flavour.json","data/text/provenance.json","data/music/title.json","data/music/floor.json","data/music/floor2.json","data/music/win.json","data/music/death.json"]:
		check(JSON.parse_string(FileAccess.get_file_as_string("res://"+path)) is Dictionary,"Packed JSON "+path)
	print("M3d exported pack: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
