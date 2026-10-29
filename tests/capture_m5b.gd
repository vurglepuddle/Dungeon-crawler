extends SceneTree
class Gallery extends "res://scripts/app/main.gd":
 var samples: Dictionary={}
 func pilot_call(name_key: String,args: Array) -> String:
  if name_key!="sample": return super.pilot_call(name_key,args)
  if samples.is_empty():
   var path: String="res://build/m5b_gallery_samples.json"
   for arg in OS.get_cmdline_user_args():
    if arg.begins_with("--samples="): path=arg.trim_prefix("--samples=")
   samples=JSON.parse_string(FileAccess.get_file_as_string(path))
  var sample: Dictionary=samples[str(args[0])]
  _close_modal(); _close_card()
  sim=Sim.new(sample.state.seed,sample.state.floor_count)
  if not sim.restore_state(sample.state): push_error("Invalid gallery fixture "+str(args[0])); get_tree().quit(1); return "failed"
  _mode="game"; selected=""; _busy=0; _hurt_time=0; _transitioning=false; _reset_presentation(); _survey.reset(sample.state.floor_count,sample.state.floors)
  view._face_choices.clear(); view._surface_key=""; view.clear_strike(); view._presentation_ms=0
  if sample.extra.has("dressing"):
   var f: Dictionary=sim.floor_data()
   for y in range(17):
    for x in range(17):
     for normal in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
      view._face_choices["%s/%d/%s"%[sample.state.seed,sample.state.floor,view._face_key([x,y],normal)]]=sample.extra.dressing
  lines=[str(args[0]).replace("_"," "),"Art comparison fixture."]
  _sync(); view.set_process(false); _ambience.set_process(false); _ambience.dust_enabled=false; _ambience.drips_enabled=false; _ambience.lamp_flicker_enabled=false
  if sample.extra.has("burn"): view._burning[sample.extra.burn]=sample.extra.age; view.queue_redraw()
  _overlay_life._active={}; _overlay_life._candle_frame=0
  if sample.extra.has("card"): _open_card(sample.extra.card)
  if sample.extra.get("keys",false): _belt_card("key")
  if sample.extra.get("map",false): _open_map()
  if str(args[0]).begins_with("overlay_") or str(args[0]).begins_with("candle_"): lines=["Overlay life.","Still air."]
  if sample.extra.has("flare"): _overlay_life._active={"skull":int(sample.extra.flare),"eyes":[0,1],"age":0.15}
  if sample.extra.has("candle"): _overlay_life._candle_frame=int(sample.extra.candle)
  _overlay_life.queue_redraw(); queue_redraw()
  return "ok"
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
 var app=Gallery.new(); app._save_path="user://tests/m5b_gallery_only.json"; app._profile_path="user://tests/m5b_gallery_profile.json"; root.add_child(app); current_scene=app
