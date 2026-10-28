extends "res://tests/qa/generation.gd"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/qa/results")
	var amount:=2048
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): amount=int(arg.get_slice("=",1))
	var seeds: Array=[]
	for index in range(amount): seeds.append("Q4"+Gen.ALPHABET[(index/1024)%32]+Gen.ALPHABET[(index/32)%32]+Gen.ALPHABET[index%32])
	for letter in Gen.ALPHABET:
		for code in [letter,letter.repeat(6)]:
			if not seeds.has(code): seeds.append(code)
	for code in ["BELL42","AAAAA9","99999A","AZ29AZ","A99999"]:
		if not seeds.has(code): seeds.append(code)
	stats={"seed_codes":seeds.size(),"floors":0,"witnesses":0,"replayed_witnesses":0,"replayed_actions":0,"groups":{},"landing_bounds":0}
	for index in range(seeds.size()):
		var seed: String=seeds[index]
		var sim=Sim.new(seed,3)
		var state: Dictionary=sim.snapshot()
		check(state.rules_version=="m4.1" and state.generator_version=="m4.1" and state.content_version=="m4.1" and Codec.validate(state),seed+" deep profile")
		if index%64==0: check(state==Sim.new(seed,3).snapshot(),seed+" deterministic")
		for number in range(3):
			var f: Dictionary=state.floors[number]
			stats.floors+=1
			check(flood(f).size()==f.tiles.count(0),seed+" connected floor "+str(number+1))
			for fixture in f.fixtures:
				if fixture.type not in ["gate","lock"]: continue
				var cut: Dictionary=flood(f,[fixture.pos])
				check(not cut.has(Vector2i(f.landing[0],f.landing[1])),seed+" gate cut "+fixture.id)
				if fixture.type=="lock":
					var key: Dictionary=state.items[fixture.key_id]
					check(cut.has(Vector2i(key.pos[0],key.pos[1])),seed+" key before lock")
			for landing in [f.start,f.landing]:
				var spaces:=0
				for d in Sim.DIRS:
					var p: Array=[landing[0]+d[0],landing[1]+d[1]]
					if p[0]<0 or p[1]<0 or p[0]>=17 or p[1]>=17 or f.tiles[p[1]*17+p[0]]!=0: continue
					if f.fixtures.any(func(v): return v.pos==p and (v.type=="porter" or v.type in ["gate","lock","web","cord"] and not v.open)): continue
					spaces+=1
				check(spaces>=f.actors.size(),seed+" occupied landing retains side capacity")
				stats.landing_bounds+=1
		var deep: Dictionary=state.floors[2]
		check(deep.fixtures.any(func(f): return f.type=="lock"),seed+" deep keyed gate always present")
		check(deep.actors.size()==3 and deep.actors.all(func(a): return a.damage==3 if a.kind=="hound" else a.damage==2),seed+" deep damage")
		for policy in ["keep","return","tour"]:
			var proof: Dictionary=Witness.build(seed,3,false,"return" if policy=="tour" else policy,policy=="tour")
			stats.witnesses+=1
			check(proof.ok,seed+"/"+policy+" witness "+proof.reason)
			if not proof.ok: continue
			check(proof.snapshot.status=="won" and proof.snapshot.hp==6 and Codec.validate(proof.snapshot),seed+" ending")
			if not stats.groups.has(policy): stats.groups[policy]={"runs":0,"turns":{}}
			var group: Dictionary=stats.groups[policy]; group.runs+=1
			group.turns[str(proof.snapshot.turn)]=group.turns.get(str(proof.snapshot.turn),0)+1
			if index%32==0 or index>=amount:
				var replay=Sim.new(seed,3)
				for action in proof.actions:
					check(replay.apply(action).accepted,seed+" ordinary replay")
					stats.replayed_actions+=1
				check(replay.state_hash()==Codec.canonical(proof.snapshot).sha256_text(),seed+" replay hash")
				stats.replayed_witnesses+=1
		if index%32==0: print("QA DEEP GENERATION ",index+1,"/",seeds.size()," witnesses ",stats.witnesses," failures ",failures.size())
	stats.checks=checks; stats.failures=failures
	var file:=FileAccess.open("res://tests/qa/results/deep_generation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(stats,"\t")); file.close()
	print("QA DEEP GENERATION COMPLETE ",JSON.stringify(stats))
	quit(0 if failures.is_empty() else 1)
