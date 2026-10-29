extends SceneTree
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Codec=preload("res://scripts/persistence/state_codec.gd")
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(note)
func _initialize() -> void:
	for i in range(200):
		var seed: String="DEEP"+Sim.Gen.ALPHABET[(i/32)%32]+Sim.Gen.ALPHABET[i%32]
		var modern=Sim.new(seed,3,{"profile":"m5.1"}); var old=Sim.new(seed,3)
		check(modern._s.floors.slice(0,3)==old._s.floors,"All Abbey bytes match for "+seed)
		check(Codec.validate(modern.snapshot()),"Fresh schema-3 generation validates")
		var f: Dictionary=modern._s.floors[3]
		check(f.actors.size()>=6 and f.actors.size()<=8,"Six to eight creatures")
		for fixture in f.fixtures:
			if fixture.type not in ["gate","lock","web","cord"]: continue
			var p: Array=fixture.pos
			check((f.tiles[p[1]*f.width+p[0]-1]==1 and f.tiles[p[1]*f.width+p[0]+1]==1) or (f.tiles[(p[1]-1)*f.width+p[0]]==1 and f.tiles[(p[1]+1)*f.width+p[0]]==1),"One-cell painted portal mouth: "+fixture.id)
		for item in modern._s.items.values():
			if item.floor!=4 or item.location!="floor": continue
			check(f.actors.all(func(a): return a.pos!=item.pos) and f.fixtures.all(func(v): return v.pos!=item.pos),"Deep spawn reserves fixture/creature cells: "+item.id)
	for shape in [[1,1],[1,4],[4,1],[3,2],[4,4]]:
		var sim=Sim.new("BELL42",3,{"profile":"m5.1","deep_floors":2,"columns":shape[0],"rows":shape[1]})
		check(Codec.validate(sim.snapshot()),"Parameterized size/count validates: "+str(shape))
	var sim=Sim.new("BELL42",3,{"profile":"m5.1","start":"deep"})
	for key in ["act","fallen","wakes","deep_count","deep_blocks"]:
		for value in [null,{},"bad",true]:
			if typeof(value)==typeof(sim._s[key]) and value==sim._s[key]: continue
			var s: Dictionary=sim.snapshot(); s[key]=value
			check(not sim.restore_state(s),"Malformed m5 metadata refuses cleanly: "+key)
	print("M5a generation: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
