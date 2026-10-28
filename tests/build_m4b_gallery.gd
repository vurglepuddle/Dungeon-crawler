extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const W=preload("res://scripts/gen/witness.gd")
const Faces=preload("res://scripts/sim/wall_faces.gd")
var samples: Dictionary={}
func add_sample(label: String,s: Dictionary,number: int,pos: Array,facing: int,extra: Dictionary={}) -> void:
 var copy: Dictionary=s.duplicate(true); copy.status="playing"; copy.floor=number; copy.pos=pos.duplicate(); copy.facing=facing
 samples[label]={"state":copy,"extra":extra}
func _initialize() -> void:
 var seed: String="B3VJ5K"; var sim=Sim.new(seed,2); var fresh: Dictionary=sim.snapshot()
 var tour: Dictionary=W.build(seed,2,false,"return",true); assert(tour.ok,tour.reason)
 for action in tour.actions: assert(sim.apply(action).accepted)
 var done: Dictionary=sim.snapshot()
 for number in [1,2]:
  var f: Dictionary=fresh.floors[number-1]; var x: int=f.start[0]; var tag: String="f%d_"%number
  for dressing in ["drain","chains","tapestry","crack","damp","sconce_0","sconce_1"]:
   add_sample(tag+dressing,fresh,number,[x-1,14],3,{"dressing":dressing})
  if f.fixtures.any(func(t): return t.type=="lock"):
   add_sample(tag+"lock_closed",fresh,number,[x,6],0)
   add_sample(tag+"lock_open",done,number,[x,6],0)
  for phase in ["up","down"]:
   add_sample(tag+"plate_"+phase,fresh if phase=="up" else done,number,[x,14],0)
  var latch: Dictionary=f.fixtures.filter(func(t): return t.type=="latch")[0]
  var bind: Dictionary=Faces.all(f)[latch.id]
  var facing: int=Sim.DIRS.find([-bind.normal[0],-bind.normal[1]])
  add_sample(tag+"lever_front",done,number,latch.pos,facing)
  add_sample(tag+"lever_side",done,number,[x,10],0)
  var lift: Dictionary=f.fixtures.filter(func(t): return t.type=="lift")[0]
  bind=Faces.all(f)[lift.id]; facing=Sim.DIRS.find([-bind.normal[0],-bind.normal[1]])
  add_sample(tag+"lift_dead_underfoot",fresh,number,lift.pos,facing)
  add_sample(tag+"lift_working_underfoot",done,number,lift.pos,facing)
  add_sample(tag+"lift_approach",done,number,[lift.pos[0]-1,lift.pos[1]],1)
  if number==1:
   var down: Dictionary=f.fixtures.filter(func(t): return t.type=="stairs_down")[0]
   bind=Faces.all(f)[down.id]; facing=Sim.DIRS.find([-bind.normal[0],-bind.normal[1]])
   add_sample(tag+"stairs_top",done,number,down.pos,facing)
  add_sample(tag+"room",fresh,number,[x,15],0)
 var web: Dictionary=fresh.floors[0].fixtures.filter(func(t): return t.type=="web")[0]
 add_sample("web_intact",fresh,1,[web.pos[0]+1,web.pos[1]],3)
 for frame in [0,1]: add_sample("web_burning_%d"%frame,done,1,[web.pos[0]+1,web.pos[1]],3,{"burn":web.id,"age":0.04+0.12*frame})
 add_sample("web_burnt",done,1,[web.pos[0]+1,web.pos[1]],3)
 var cord: Dictionary=fresh.floors[1].fixtures.filter(func(t): return t.type=="cord")[0]
 for phase in ["intact","cut"]: add_sample("cord_"+phase,fresh if phase=="intact" else done,2,[cord.pos[0]-1,cord.pos[1]],1)
 var panel: Dictionary=done.floors[0].fixtures.filter(func(t): return t.type=="panel")[0]
 add_sample("cache_open",done,1,panel.pos,Sim.DIRS.find([-panel.normal[0],-panel.normal[1]]))
 var hound: Dictionary=fresh.floors[0].actors.filter(func(t): return t.kind=="hound")[0]
 var hound_scene: Dictionary=fresh.duplicate(true)
 hound_scene.floors[0].fixtures.filter(func(t): return t.type=="web")[0].open=true
 add_sample("hound_embers",hound_scene,1,[hound.pos[0]+3,hound.pos[1]],3)
 var spent: Dictionary=done.duplicate(true); spent.items.f1_coat.location="pack"; spent.items.f1_coat.floor=0; spent.items.f1_coat.pos=[]; spent.items.f1_coat.spent=true
 if not spent.pack.has("f1_coat"): spent.pack.append("f1_coat")
 spent.equipment.body=""; spent.items.f1_coat.slot=""
 add_sample("spent_coat_pack",spent,1,spent.floors[0].start,0)
 var three=Sim.new(seed,3); var proof3: Dictionary=W.build(seed,3,false,"return",true); assert(proof3.ok)
 for action in proof3.actions: assert(three.apply(action).accepted)
 var s3: Dictionary=three.snapshot(); var d3: Dictionary=s3.floors[1].fixtures.filter(func(t): return t.type=="stairs_down")[0]
 var b3: Dictionary=Faces.all(s3.floors[1])[d3.id]
 add_sample("f2_stairs_top",s3,2,d3.pos,Sim.DIRS.find([-b3.normal[0],-b3.normal[1]]))
 var file=FileAccess.open("res://build/m4b_gallery_samples.json",FileAccess.WRITE); file.store_string(JSON.stringify(samples)); file.close()
 var lines: Array=["# Authored renderer fixtures, not a gameplay route. Muted by Autopilot.","wait 5"]
 for label in samples: lines.append_array(["call sample "+label,"wait 4","shot "+label])
 lines.append("close")
 file=FileAccess.open("res://tests/pilot/m4b_gallery.txt",FileAccess.WRITE); file.store_string("\n".join(lines)+"\n"); file.close()
 print("Gallery fixtures: ",samples.size()); quit()
