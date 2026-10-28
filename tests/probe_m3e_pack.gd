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
	check(not FileAccess.file_exists("res://tests/test_m3e.gd"),"Probe uses the actual exported resource pack")
	for kind in Held.FRAMES:
		for frame in Held.FRAMES[kind]:
			var texture: Texture2D=Paint.texture("res://assets/art/hands/hand_%s_%s_56.png"%[kind,frame])
			check(texture!=null and texture.get_size()==Vector2(48,56),"Packed held frame "+kind+"/"+frame)
	var app=load("res://scenes/main.tscn").instantiate()
	app._save_path="user://tests/m3e_packed.json"; root.add_child(app); current_scene=app
	check(app.new_run("BELL42"),"Packaged game starts a generated run")
	var proof: Dictionary=W.build("BELL42",2,false,"return",true)
	for action in proof.actions:
		while app._transitioning: await process_frame
		app._busy=0; app._command(action)
		check(app._save_ok,"Packaged content/action saves: "+action.type)
	check(app.state.status=="won" and app.state.hp==6 and app._public_state().secrets_found==1,"Packaged full tour wins with all capability branches and secret")
	app.queue_free(); await process_frame; await create_timer(0.3).timeout
	print("M3e exported pack: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
