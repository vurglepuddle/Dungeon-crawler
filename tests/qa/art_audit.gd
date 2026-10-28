extends SceneTree
## Read-only source/asset inventory. No scene, saves, import, or builder runs.
const Paint=preload("res://scripts/art/presentation_art.gd")
const Art=preload("res://scripts/art/item_art.gd")
const Catalog=preload("res://scripts/content/catalog.gd")
const Held=preload("res://scripts/view/held_item.gd")
var paths: Dictionary={}
var missing: Array=[]
var failed: Array=[]

func add(path: String, family: String) -> void:
	paths[path]=family

func _initialize() -> void:
	AudioServer.set_bus_mute(0,true)
	for kind in Catalog.ITEMS:
		var path: String="res://assets/art/icons/%s.png"%kind
		if kind=="torch": path="res://assets/art/fixtures/reed_torch_icon_unlit_16.png"
		if kind=="seal": path="res://assets/art/fixtures/dawn_seal_icon_16.png"
		add(path,"inventory")
	add("res://assets/art/fixtures/reed_torch_icon_lit_16.png","inventory")
	for kind in ["knife","shard","club","stone","bone","bread","tonic","coat","coat_spent","key","clapper","lamp"]:
		for d in range(1,4): add("res://assets/art/items/item_%s_d%d.png"%[kind,d],"world_items_working_tree")
	for floor_number in [1,2]:
		for suffix in ["plain_0","plain_1","plain_2","sconce_0","sconce_1","tapestry","chains","damp","crack","drain","arch_blocked","door_barricaded","door"]:
			add("res://assets/art/env/painted_f%d_%s.png"%[floor_number,suffix],"walls_and_lock")
		for suffix in ["exit","lift_working","gate_closed_overlay","gate_open_overlay"]:
			add("res://assets/art/fixtures/architecture_f%d_%s_64.png"%[floor_number,suffix],"architecture")
		for kind in ["stairs_down","stairs_up"]: add("res://assets/art/fixtures/architecture_v3_f%d_%s_64.png"%[floor_number,kind],"architecture")
		add("res://assets/art/fixtures/architecture_v2_f%d_lift_dead_64.png"%floor_number,"architecture")
		for kind in ["rubble","bone_heap","skeleton","pots","statue","candles","crate","pillar"]:
			for d in range(1,4): add("res://assets/art/props/f%d_%s_d%d.png"%[floor_number,kind,d],"room_props")
	for suffix in ["dry_a","dry_b","dry_c","stain","chip","crack","wet_small","wet_hook","wet_corner","wet_split","wet_wide"]:
		add("res://assets/art/env/calm_v3_floor_%s.png"%suffix,"floor")
	for suffix in ["plain","root","drip"]: add("res://assets/art/env/calm_v3_ceiling_%s.png"%suffix,"ceiling")
	for kind in ["brazier_lit_0","brazier_lit_1","reed_torch_unlit","reed_torch_lit_0","reed_torch_lit_1","web_intact","web_burning_0","web_burning_1","web_burnt","cord_grate_intact","cord_grate_cut","dawn_seal_pulse_0","dawn_seal_pulse_1"]:
		for d in range(1,4): add("res://assets/art/fixtures/%s_d%d.png"%[kind,d],"capability_fixtures")
	for state_name in ["plain","revealed"]: add("res://assets/art/fixtures/panel_sigil_%s_64.png"%state_name,"secret_mark")
	for h in [64,40,24]:
		add("res://assets/art/porter_%d.png"%h,"porter")
		add("res://assets/art/anim/porter_restored_%d.png"%h,"porter")
		for kind in ["bell_husk","ash_hound_ember","wick_ghost"]:
			for pose in ["idle","windup","recoil"]:
				add("res://assets/art/%s/%s_%s_%d.png"%["anim" if kind=="bell_husk" else "creatures",kind,pose,h],"creatures")
	for d in range(1,4):
		for state_name in ["up","down"]:
			add("res://assets/art/fx/plate_%s_d%d.png"%[state_name,d],"plate")
			for side in ["left","right"]: add("res://assets/art/fx/lever_%s_%s_d%d.png"%[side,state_name,d],"lever_side")
			add("res://assets/art/fixtures/lever_front_%s_d%d.png"%[state_name,d],"lever_front")
	for kind in ["edge","heavy","hands","damage_burst"]:
		for frame in range(3): add("res://assets/art/fx/%s_%d_64.png"%[kind,frame],"combat_fx")
	for kind in ["gold","target"]:
		for size in [7,9]:
			for frame in range(3): add("res://assets/art/fixtures/glint_%s_%d_%d.png"%[kind,frame,size],"glints")
	for kind in Held.FRAMES:
		for frame in Held.FRAMES[kind]: add("res://assets/art/hands/hand_%s_%s_56.png"%[kind,frame],"held_items")
	for kind in ["finder_fine","finder_hurt_v2","finder_near_death_v2"]: add("res://assets/art/portrait/%s.png"%kind,"portrait")
	for kind in ["slate","leather"]: add("res://assets/art/ui/%s.png"%kind,"chrome")
	add("res://assets/art/chrome_32.png","chrome")
	for kind in ["message_slate","pack_leather","belt_loops","hp_vial_empty","hp_vial_full","map_parchment_torn_v2"]: add("res://assets/art/ui_offer/%s.png"%kind,"hud")
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/verb_layout.json"))
	for entry in layout.buttons+layout.cards: add("res://"+entry.icon_path,"verb_stamps")
	add("res://assets/art/ui_offer/verb_pack.png","verb_stamps")
	for kind in ["splash","title","win","death","logotype_140"]: add("res://assets/art/screens/%s.png"%kind,"screens")
	for kind in ["splash_flutter","title_flicker","win_dawn","death_gutter"]:
		for frame in range(2 if kind=="splash_flutter" else 3): add("res://assets/art/screens/%s_%d.png"%[kind,frame],"screens")
	var groups: Dictionary={}
	for path in paths:
		if not FileAccess.file_exists(path) and not ResourceLoader.exists(path): missing.append(path); continue
		var texture: Texture2D=Paint.texture(path)
		if texture==null or texture.get_width()<=0 or texture.get_height()<=0: failed.append(path)
		groups[paths[path]]=groups.get(paths[path],0)+1
	var icons: Array=[]
	for kind in Catalog.ITEMS:
		var texture: Texture2D=Art.inventory(kind)
		icons.append({"kind":kind,"size":[texture.get_width(),texture.get_height()] if texture!=null else []})
	var source_hashes: Dictionary={}
	for path in ["res://scripts/view/dungeon_view.gd","res://scripts/view/held_item.gd","res://scripts/app/main.gd","res://scripts/art/item_art.gd","res://scripts/art/fixture_art.gd","res://scripts/ui/chrome.gd","res://scripts/ui/item_button.gd","res://scripts/ui/map_view.gd","res://scripts/art/plane_materials.gd"]:
		source_hashes[path]=FileAccess.get_sha256(path)
	var boot: Dictionary={}
	for key in ["application/boot_splash/image","application/boot_splash/show_image","application/boot_splash/fullsize","application/boot_splash/use_filter","application/config/icon"]:
		boot[key]=ProjectSettings.get_setting(key)
	var result: Dictionary={"expected_texture_paths":paths.size(),"families":groups,"missing":missing,"failed":failed,"inventory_sizes":icons,"boot_settings":boot,"optional_owner_vines_present":FileAccess.file_exists("res://assets/art/ui/owner_vines.png"),"source_hashes":source_hashes}
	DirAccess.make_dir_recursive_absolute("res://tests/qa/results")
	var file:=FileAccess.open("res://tests/qa/results/art_audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")); file.close()
	print("ART AUDIT ",JSON.stringify(result))
	quit(0 if missing.is_empty() and failed.is_empty() else 1)
