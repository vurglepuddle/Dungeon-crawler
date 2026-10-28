extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const View=preload("res://scripts/view/dungeon_view.gd")
const Required=preload("res://scripts/art/required_art.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
const Planes=preload("res://scripts/art/plane_materials.gd")
const Family=preload("res://scripts/art/art_family.gd")
const Faces=preload("res://scripts/sim/wall_faces.gd")
const Chrome=preload("res://scripts/ui/chrome.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1; push_error(message)
func digest(texture: Texture2D) -> String: return texture.get_image().get_data().hex_encode().sha256_text()
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
 var paths: Dictionary=Required.paths(); var issues: Array=Required.issues(paths)
 check(issues.is_empty(),"Every required painted path loads: "+str(issues))
 for h in [64,40,24]: check(paths.has("res://assets/art/porter_%d.png"%h),"Waiting Porter cannot disappear silently")
 var bad: Dictionary=paths.duplicate(); bad["res://tests/missing_required_porter.png"]="porter"
 var refused: Array=Required.issues(bad)
 check(refused.size()==1 and refused[0].contains("missing_required_porter"),"Missing assets are detected before drawing; no substitute art")
 check(Chrome.style() is StyleBoxTexture and Chrome.style().texture!=null and Chrome.surface("card") is StyleBoxTexture,"Chrome always uses painted sources")
 check(Family.for_floor(1).walls==1 and Family.for_floor(2).walls==2 and Family.for_floor(3).fixtures==2 and Family.for_floor(4).props==2 and Family.for_floor(3).planes=="calm_v3","One family mapping retains deep borrowed art")
 var samples: Array=[Vector2i(17,37),Vector2i(37,46),Vector2i(46,26),Vector2i(26,17)]
 for i in range(4):
  var normal: Array=[-Sim.DIRS[i][0],-Sim.DIRS[i][1]]
  check(Planes.ground_uv(17,37,normal)==samples[i],"Ground points toward negative binding normal")
  for u in range(64):
   for v in range(64):
    if u<2 or u>=62 or v<2 or v>=62: check(Planes.ground_uv(u,v,normal)==Vector2i(u,v),"Ground joint ring remains world aligned")
 var sim=Sim.new("B3VJ5K",2); var view=View.new(); root.add_child(view)
 for number in [1,2]:
  var state: Dictionary=sim.view_snapshot(); var f: Dictionary=sim.snapshot().floors[number-1]
  state.floor=number; state.tiles=f.tiles; state.fixtures=f.fixtures.duplicate(true); state.actors=[]; state.objects=[]; state.props=[]
  state.pos=f.start.duplicate(); state.facing=0
  view.update_state(state)
  for portal in view._portals:
   if portal.kind=="web" or portal.kind=="cord": check(portal.texture_path.contains("fixture_v2_"),"Portal uses canonical painted replacement")
  check(not view._sprites.any(func(s): return s.kind in ["web","cord"]),"No billboard doubles a portal")
  for fixture in state.fixtures:
   if fixture.type=="lock": fixture.open=true
   if fixture.type=="panel": fixture.open=true; fixture.revealed=true
  view.update_state(state)
  for portal in view._portals:
   if portal.kind=="lock": check(portal.texture_path.ends_with("door_open_overlay_v2.png"),"Opened lock is wood/arch with a transparent passage")
  for face in view._faces.values():
   if face.kind=="panel": check(face.texture_path.contains("cache_open_64") and face.panel_state=="","Opened cache is a painted wall recess")
  for cell in view._room_cells:
   for dy in range(-1,2):
    for dx in range(-1,2): check(state.tiles[(cell.y+dy)*17+cell.x+dx]==0,"Landmark fits a real room")
  check(not view._room_cells.is_empty(),"At least one quiet room landmark is present")
  var lift: Dictionary=state.fixtures.filter(func(t): return t.type=="lift")[0]
  var bind: Dictionary=Faces.all(state)[lift.id]
  state.pos=[lift.pos[0]-1,lift.pos[1]]; state.facing=1
  view.update_state(state); var before: String=digest(view._surfaces); var key: String=view._surface_key
  var cell:=Vector2i(lift.pos[0],lift.pos[1]); check(view._ground_cells.has(cell) and view._ground_cells[cell].normal==bind.normal,"Override is attached to fixture cell, independent of Finder cell")
  lift.active=true; view.update_state(state)
  check(key!=view._surface_key and before!=digest(view._surfaces),"Lift wakes on the ground without moving or turning")
  var fixed: Dictionary=view._ground_cells.duplicate(true); state.facing=2; view.update_state(state)
  check(view._ground_cells==fixed,"Turning cannot rotate the physical floor deck")
 # Actual Main inventory path covers both carried and worn spent padding.
 var app=load("res://scenes/main.tscn").instantiate(); app._save_path="user://tests/m4b_art_guard.json"; root.add_child(app)
 check(app.new_run("B3VJ5K",2),"Art-wired main starts")
 var id: String="f1_coat"; app.state.items[id].spent=true
 check(digest(app._item_icon(id))==digest(Paint.texture("res://assets/art/icons/coat_spent.png")),"Spent coat card/pack/equipment icon uses torn art")
 check(app.VIEW_RECT==Rect2(3,21,148,150) and app.VIEW_RECT.grow(3)==Rect2(0,18,154,156) and app.controls.compass.get_rect()==Rect2(85,294,66,44),"Owner vine registration remains exact")
 view.free(); app.queue_free(); await process_frame; await create_timer(0.3).timeout
 print("M4b painted kit: ",checks," checks, ",failures," failures; ",paths.size()," required textures")
 quit(1 if failures else 0)
