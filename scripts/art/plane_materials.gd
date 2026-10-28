extends RefCounted
const Paint=preload("res://scripts/art/presentation_art.gd")
const FLOORS=["dry_a","dry_b","dry_c","stain","chip","crack","wet_small","wet_hook","wet_corner","wet_split","wet_wide"]
const WEIGHTS=[[28,24,21,10,8,6,3,0,0,0,0],[14,12,10,6,5,5,10,10,10,9,9]]
static var _cells: Dictionary={}
static func path(seed: String,number: int,plane: String,x: int,y: int) -> String:
	var key: String="%s/%d/%s/%d/%d"%[seed,number,plane,x,y]
	if _cells.has(key): return _cells[key]
	var roll: int=Paint.mix_hash(key)%100
	var names: Array=FLOORS if plane=="floor" else ["plain","root","drip"]
	var weights: Array=WEIGHTS[clampi(number,1,2)-1] if plane=="floor" else ([98,0,2] if number==1 else [82,10,8])
	for i in range(names.size()):
		if roll<int(weights[i]):
			_cells[key]="res://assets/art/env/calm_v3_%s_%s.png"%[plane,names[i]]
			return _cells[key]
		roll-=int(weights[i])
	return ""
