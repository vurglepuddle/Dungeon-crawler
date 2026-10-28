extends SceneTree
const Sim = preload("res://scripts/sim/dungeon_sim.gd")
const Gen = preload("res://scripts/gen/floor_gen.gd")
const Witness = preload("res://scripts/gen/witness.gd")
const Codec = preload("res://scripts/persistence/state_codec.gd")
var checks := 0
var failures: Array = []
var stats := {"seed_codes":0, "generated_runs":0, "floors":0, "witnesses":0, "replayed_witnesses":0, "replayed_actions":0, "groups":{}, "loot":{}, "layouts":{}}

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("QA FAIL: ", message)

func flood(f: Dictionary, blocked: Array = []) -> Dictionary:
	var seen := {Vector2i(f.start[0], f.start[1]):true}
	var queue: Array = [f.start]
	var cursor := 0
	while cursor < queue.size():
		var cell: Array = queue[cursor]; cursor += 1
		for d in Sim.DIRS:
			var next: Array = [cell[0]+d[0], cell[1]+d[1]]
			if next[0]<0 or next[1]<0 or next[0]>=f.width or next[1]>=f.height or f.tiles[next[1]*f.width+next[0]]!=0 or blocked.has(next): continue
			var key := Vector2i(next[0],next[1])
			if not seen.has(key): seen[key]=true; queue.append(next)
	return seen

func _initialize() -> void:
	var amount := 3072
	var extra_counts := 256
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount = int(arg.get_slice("=",1))
		if arg.begins_with("--extra-counts="): extra_counts = int(arg.get_slice("=",1))
	var seeds: Array = []
	for i in range(amount):
		seeds.append("QA" + Gen.ALPHABET[(i/32768)%32] + Gen.ALPHABET[(i/1024)%32] + Gen.ALPHABET[(i/32)%32] + Gen.ALPHABET[i%32])
	for letter in Gen.ALPHABET:
		for seed in [letter, letter.repeat(6)]:
			if not seeds.has(seed): seeds.append(seed)
	for seed in ["BELL42", "A99999", "9AAAAA", "AZ29AZ", "99999A"]:
		if not seeds.has(seed): seeds.append(seed)
	stats.seed_codes = seeds.size()
	for index in range(seeds.size()):
		var seed: String = seeds[index]
		var counts := [1,2,3,4] if index < extra_counts or index >= amount else [1,2]
		for count in counts:
			var sim = Sim.new(seed,count)
			var state: Dictionary = sim.snapshot()
			stats.generated_runs += 1
			check(Codec.validate(state), "%s/%d initial codec" % [seed,count])
			if index%64 == 0: check(state == Sim.new(seed,count).snapshot(), "%s/%d repeatable" % [seed,count])
			stats.layouts[Codec.canonical(state.floors.map(func(f): return f.tiles)).sha256_text()] = true
			for number in range(count):
				var f: Dictionary = state.floors[number]
				stats.floors += 1
				check(flood(f).size()==f.tiles.count(0), "%s/%d floor %d connected" % [seed,count,number+1])
				for fixture in f.fixtures:
					if fixture.type in ["gate","lock"]:
						var cut: Dictionary = flood(f,[fixture.pos])
						check(not cut.has(Vector2i(f.landing[0],f.landing[1])), "%s/%d %s cuts" % [seed,count,fixture.id])
						if fixture.type == "lock":
							var key: Dictionary = state.items[fixture.key_id]
							check(cut.has(Vector2i(key.pos[0],key.pos[1])), "%s key before lock" % seed)
				check(flood(f,[[f.start[0],8]]).has(Vector2i(f.start[0],f.layout.loop_top)), "%s middle loop" % seed)
				var offered := 0
				var kinds: Dictionary = {}
				for item in state.items.values():
					if item.floor==number+1 and sim.definition(item.id).slot!="belt":
						offered += 1
						kinds[item.kind] = kinds.get(item.kind,0)+1
				var group: String = "floor_%d" % (number+1)
				if not stats.loot.has(group): stats.loot[group]={"histogram":{},"kind_counts":{},"floors":0}
				var loot: Dictionary = stats.loot[group]
				loot.floors += 1
				loot.histogram[str(offered)] = loot.histogram.get(str(offered),0)+1
				for kind in kinds: loot.kind_counts[kind]=loot.kind_counts.get(kind,0)+kinds[kind]
			for choice in ["keep","return"]:
				var proof: Dictionary = Witness.build(seed,count,false,choice)
				stats.witnesses += 1
				check(proof.ok, "%s/%d/%s witness: %s" % [seed,count,choice,proof.reason])
				if not proof.ok: continue
				check(Codec.validate(proof.snapshot) and proof.snapshot.hp==6 and proof.snapshot.status=="won", "%s/%d/%s ending" % [seed,count,choice])
				var group: String = "%d_%s" % [count,choice]
				if not stats.groups.has(group): stats.groups[group]={"runs":0,"turns":{},"actions":{}}
				var record: Dictionary = stats.groups[group]
				record.runs += 1
				for pair in [["turns",proof.snapshot.turn],["actions",proof.actions.size()]]:
					record[pair[0]][str(pair[1])] = record[pair[0]].get(str(pair[1]),0)+1
				if index%64==0 or index>=amount:
					var replay = Sim.new(seed,count)
					for action in proof.actions:
						stats.replayed_actions += 1
						check(replay.apply(action).accepted, "%s replay %s" % [seed,JSON.stringify(action)])
					check(replay.state_hash()==Codec.canonical(proof.snapshot).sha256_text(), "%s/%d/%s replay hash" % [seed,count,choice])
					stats.replayed_witnesses += 1
		if index%32==0: print("QA generation ",index+1,"/",seeds.size()," seeds; ",stats.witnesses," witnesses; ",failures.size()," failures")
	stats.distinct_layouts = stats.layouts.size()
	stats.erase("layouts")
	stats.checks = checks
	stats.failures = failures
	var file := FileAccess.open("res://tests/qa/results/generation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(stats,"\t")); file.close()
	print("QA GENERATION COMPLETE ",JSON.stringify(stats))
	quit(1 if not failures.is_empty() else 0)
