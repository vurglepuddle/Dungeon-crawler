extends RefCounted
## Authoritative runtime texture inventory, shared by source and isolated-PCK checks.
## Optional owner vines are deliberately absent; current paintings never fall back.
const Family=preload("res://scripts/art/art_family.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
const Icons=preload("res://scripts/art/item_art.gd")
const Catalog=preload("res://scripts/content/catalog.gd")
const Held=preload("res://scripts/view/held_item.gd")
static var _paths: Dictionary={}
static func add(path: String,family: String) -> void: _paths[path]=family
static func paths() -> Dictionary:
	_paths={}
	var fall_path: String="res://data/presentation/fall.json"
	if FileAccess.file_exists(fall_path):
		var fall=JSON.parse_string(FileAccess.get_file_as_string(fall_path))
		if fall is Dictionary:
			for path in fall.get("frames",[]): add(path,"fall_frames")
	add("res://assets/art/finder.png","portrait_preload")
	for kind in Icons.ICONS: add(Icons.icon_path(kind),"accepted_pack_icon")
	add("res://assets/art/ui/owner_candle.png","owner_candle")
	for key in ["turn_l","fwd","turn_r","strafe_l","back","strafe_r"]: add("res://assets/art/ui_offer/arrow_%s.png"%key,"arrow_pad")
	for kind in ["knife","shard","club","stone","bone","bread","tonic","coat","coat_spent","key","clapper","lamp"]:
		for d in range(1,4): add("res://assets/art/items/item_%s_d%d.png"%[kind,d],"world_items_working_tree")
	var families: Array=[]
	for number in range(1,6):
		var family: Dictionary=Family.for_floor(number)
		if not families.has(family): families.append(family)
	for family in families:
		var floor_number: int=family.walls
		for suffix in ["plain_0","plain_1","plain_2","sconce_0_v2","sconce_1_v2","tapestry_v2","chains_v2","damp_v2","crack_v2","drain_v2","arch_blocked","door_barricaded","door_v2","door_open_overlay_v2"]:
			add("res://assets/art/env/painted_f%d_%s.png"%[floor_number,suffix],"walls_and_lock")
		for suffix in ["exit","lift_working","gate_closed_overlay","gate_open_overlay"]:
			add("res://assets/art/fixtures/architecture_f%d_%s_64.png"%[family.fixtures,suffix],"architecture")
		for kind in ["stairs_down","stairs_up"]: add("res://assets/art/fixtures/architecture_v3_f%d_%s_64.png"%[family.fixtures,kind],"architecture")
		add("res://assets/art/fixtures/architecture_v2_f%d_lift_dead_64.png"%family.fixtures,"architecture")
		for kind in ["rubble","bone_heap","skeleton","pots","statue","candles","crate","pillar"]:
			for d in range(1,4): add("res://assets/art/props/f%d_%s_d%d.png"%[family.props,kind,d],"room_props")
	for family in families:
		for suffix in ["dry_a","dry_b","dry_c","stain","chip","crack","wet_small","wet_hook","wet_corner","wet_split","wet_wide"]:
			add("res://assets/art/env/%s_floor_%s.png"%[family.planes,suffix],"floor")
		for suffix in ["plain","root","drip"]: add("res://assets/art/env/%s_ceiling_%s.png"%[family.planes,suffix],"ceiling")
	for kind in ["brazier_lit_0","brazier_lit_1","reed_torch_unlit","reed_torch_lit_0","reed_torch_lit_1","dawn_seal_pulse_0","dawn_seal_pulse_1"]:
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
			for family in [1,2]: add("res://assets/art/fixtures/fixture_v2_f%d_plate_%s_d%d.png"%[family,state_name,d],"plate")
			for side in ["left","right"]: add("res://assets/art/fixtures/fixture_v2_lever_%s_%s_d%d.png"%[side,state_name,d],"lever_side")
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
	for family in [1,2]:
		for state_name in ["up","down"]: add("res://assets/art/fixtures/lever_wall_f%d_%s_64.png"%[family,state_name],"lever_wall")
		for name in ["floor_lift_dead","floor_lift_working","floor_stairs_down","cache_open"]:
			add("res://assets/art/fixtures/fixture_v2_f%d_%s_64.png"%[family,name],"ground_cache")
	for name in ["web_intact","web_burning_0","web_burning_1","web_burnt","cord_grate_intact","cord_grate_cut"]:
		add("res://assets/art/fixtures/fixture_v2_%s_d1.png"%name,"portal")
	for family in families:
		for name in ["drain","cracked","compass"]: add("res://assets/art/env/%s_room_floor_%s.png"%[family.planes,name],"room_landmarks")
		for name in ["roots","chain","boss"]: add("res://assets/art/env/%s_room_ceiling_%s.png"%[family.planes,name],"room_landmarks")
	for h in [64,40,24]:
		for pose in ["idle","windup","recoil"]: add("res://assets/art/creatures/ash_hound_ember_glow_%s_%d.png"%[pose,h],"hound_glow")
	return _paths.duplicate()

static func issues(required: Dictionary={}) -> Array:
	var failures: Array=[]
	if required.is_empty(): required=paths()
	for path in required:
		if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
			failures.append("Missing required painted asset: "+path); continue
		var texture: Texture2D=Paint.texture(path)
		if texture==null or texture.get_width()<=0 or texture.get_height()<=0 or texture.get_image().is_empty():
			failures.append("Cannot load required painted asset: "+path)
	return failures
