extends SceneTree
## External script, launched with --main-pack from an empty resource directory.
const Paint=preload("res://scripts/art/presentation_art.gd")
const Held=preload("res://scripts/view/held_item.gd")
const W=preload("res://scripts/gen/witness.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	check(not FileAccess.file_exists("res://tests/test_m4a.gd"),"Probe uses the actual exported resource pack")
	for kind in Held.FRAMES:
		for frame in Held.FRAMES[kind]:
			var texture: Texture2D=Paint.texture("res://assets/art/hands/hand_%s_%s_56.png"%[kind,frame])
			check(texture!=null and texture.get_size()==Vector2(48,56),"Packed held frame "+kind+"/"+frame)
	for path in ["res://assets/art/env/calm_v3_floor_wet_hook.png","res://assets/art/env/calm_v3_ceiling_plain.png","res://assets/art/env/painted_f1_arch_blocked.png","res://assets/art/fixtures/architecture_v3_f1_stairs_down_64.png","res://assets/art/fixtures/architecture_v2_f1_lift_dead_64.png","res://assets/art/fixtures/lever_front_up_d1.png","res://assets/art/props/f1_pillar_d1.png","res://assets/art/screens/logotype_140.png","res://assets/art/screens/title_flicker_2.png","res://assets/art/ui_offer/pack_leather.png","res://assets/art/ui_offer/map_parchment_torn_v2.png"]:
		check(Paint.texture(path)!=null,"Packed M4a art: "+path)
	check(FileAccess.file_exists("res://data/ui/verb_layout.json"),"Runtime verb layouts ship without art_src")
	for kind in ["knife","shard","club","stone","bone","bread","tonic","coat","coat_spent","key","clapper","lamp"]:
		for depth in range(1,4):
			var texture=Paint.texture("res://assets/art/items/item_%s_d%d.png"%[kind,depth])
			check(texture!=null and texture.get_size()==[Vector2(64,48),Vector2(40,30),Vector2(24,18)][depth-1],"Packed dedicated item "+kind+"/"+str(depth))
	var app=load("res://scenes/main.tscn").instantiate()
	app._save_path="user://tests/m4a_packed.json"; root.add_child(app); current_scene=app
	check(app.new_run("BELL42",3),"Packaged game starts a generated run")
	var proof: Dictionary=W.build("BELL42",3,false,"return",true)
	for action in proof.actions:
		while app._transitioning: await process_frame
		app._busy=0; app._command(action)
		check(app._save_ok,"Packaged content/action saves: "+action.type)
	check(app.state.status=="won" and app.state.hp==6 and app.state.floor_count==3 and app.state.rules_version=="m4.1" and app._public_state().secrets_found==1,"Packaged full tour wins with all capability branches and secret")
	app.queue_free(); await process_frame; await create_timer(0.3).timeout
	print("M4a exported pack: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
