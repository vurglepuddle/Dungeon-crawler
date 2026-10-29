extends Control
## Cached floor casting and grid walls share one camera with sprites/hotspots.
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Art=preload("res://scripts/art/item_art.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
const Held=preload("res://scripts/view/held_item.gd")
const Faces=preload("res://scripts/sim/wall_faces.gd")
const Times=preload("res://scripts/view/effect_times.gd")
const Metal=preload("res://scripts/art/key_art.gd")
const Family=preload("res://scripts/art/art_family.gd")
const Planes=preload("res://scripts/art/plane_materials.gd")
const WIDTH:=148
const HEIGHT:=150
const FOCAL:=74.0
const HORIZON:=71
const FAR:=3.6
## Hinge pixel of each painted lever size, d1 to d3. Side art is the owner's
## left-wall frames (29 Oct); right walls mirror it.
const LEVER_HINGES:={"front":[Vector2(16,22),Vector2(10,14),Vector2(6,8)],"side":[Vector2(10,19),Vector2(5,9),Vector2(3,6)]}
var state: Dictionary={}
var motion:=0.0
var flash:=0.0
var interaction_cues: Array=[]
var _pulse:=0.0
var _opaque_bounds: Dictionary={}
var _depths: Array[float]=[]
var _walls: Array=[]
var _sprites: Array=[]
var _projections: Dictionary={}
var _surfaces: Texture2D
var _surface_key: String=""
var _porters: Array[Texture2D]=[]
var _poses: Dictionary={}
var _restored: Array[Texture2D]=[]
var _fixture_textures: Dictionary={}
var _effects: Dictionary={}
var _strike: Dictionary={}
var _faces: Dictionary={}
var _bindings: Dictionary={}
var _portals: Array=[]
var _visible_cells: Array=[]
var _face_choices: Dictionary={}
var _lever_faces: Dictionary={}
var _glint_phases: Dictionary={}
var _sparkles: Dictionary={}
var _presentation_ms: float=0
var _has_sconce: bool=false
var _column_layers: Array=[]
var _creature_poses: Dictionary={}
var _hound_glow: Dictionary={}
var _ground_cells: Dictionary={}
var _room_cells: Dictionary={}
var _burning: Dictionary={}
var _dispel: Dictionary={}
var toss_lane: Array=[]
var held=Held.new()
var _has_flame: bool=false
const DAMAGE_FONT=preload("res://assets/font/vetka.ttf")

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for height in [64,40,24]:
		_porters.append(Paint.texture("res://assets/art/porter_%d.png"%height))
		_restored.append(load("res://assets/art/anim/porter_restored_%d.png"%height))
	for pose in ["idle","windup","recoil"]:
		_poses[pose]=[]
		for height in [64,40,24]: _poses[pose].append(load("res://assets/art/anim/bell_husk_%s_%d.png"%[pose,height]))
	for kind in ["edge","heavy","hands","damage_burst"]:
		_effects[kind]=[]
		for frame in range(3): _effects[kind].append(load("res://assets/art/fx/%s_%d_64.png"%[kind,frame]))
	for d in range(1,4):
		for pressed in ["up","down"]:
			var name: String
			for family in [1,2]:
				name="f%d_plate_%s_d%d"%[family,pressed,d]
				_fixture_textures[name]=Paint.texture("res://assets/art/fixtures/fixture_v2_%s.png"%name)
			for side in ["left","right"]:
				name="lever_%s_%s_d%d"%[side,pressed,d]
				_fixture_textures[name]=Paint.texture("res://assets/art/fixtures/fixture_v2_%s.png"%name)
			name="lever_front_%s_d%d"%[pressed,d]
			_fixture_textures[name]=Paint.texture("res://assets/art/fixtures/%s.png"%name)
	for family in ["gold","target"]:
		for pixels in [7,9]:
			var key: String="%s_%d"%[family,pixels]
			_sparkles[key]=[]
			for frame in range(3): _sparkles[key].append(Paint.texture("res://assets/art/fixtures/glint_%s_%d_%d.png"%[family,frame,pixels]))
	var wall_families: Array=[]
	for number in range(1,6):
		var floor_number: int=Family.for_floor(number).walls
		if not wall_families.has(floor_number): wall_families.append(floor_number)
	for floor_number in wall_families:
		for frame in range(2): Paint.strips("res://assets/art/env/painted_f%d_sconce_%d_v2.png"%[floor_number,frame])
	for kind in ["hound","ghost"]:
		_creature_poses[kind]={}
		for pose in ["idle","windup","recoil"]:
			_creature_poses[kind][pose]=[]
			for h in [64,40,24]: _creature_poses[kind][pose].append(Paint.texture("res://assets/art/creatures/%s_%s_%d.png"%["ash_hound_ember" if kind=="hound" else "wick_ghost",pose,h]))
	for pose in ["idle","windup","recoil"]:
		_hound_glow[pose]=[]
		for h in [64,40,24]: _hound_glow[pose].append(Paint.texture("res://assets/art/creatures/ash_hound_ember_glow_%s_%d.png"%[pose,h]))
	for d in range(1,4):
		for name in ["brazier_lit_0","brazier_lit_1","reed_torch_unlit","reed_torch_lit_0","reed_torch_lit_1","dawn_seal_pulse_0","dawn_seal_pulse_1"]:
			Paint.texture("res://assets/art/fixtures/%s_d%d.png"%[name,d])
	for kind in Held.FRAMES:
		for frame in Held.FRAMES[kind]: Paint.texture("res://assets/art/hands/hand_%s_%s_56.png"%[kind,frame])

func show_burn(id: String) -> void: _burning[id]=0.0; queue_redraw()
func show_dispel(id: String) -> void:
	for sprite in _sprites:
		if sprite.id==id: _dispel={"sprite":sprite.duplicate(),"age":0.0}; break
	queue_redraw()

func clear_strike() -> void:
	_strike={}; _burning={}; _dispel={}; toss_lane=[]; held.remaining=0; queue_redraw()

func show_strike(id: String,target: Dictionary,kind: String,damage: int) -> void:
	if target.is_empty(): return
	_strike={"id":id,"target":target.duplicate(),"kind":kind,"damage":damage,"age":0.0}
	# Retain the painted actor through a lethal hit's short recoil, while the
	# authoritative actor is already dead and no longer blocks the cell.
	for sprite in _sprites:
		if sprite.id==id: _strike.ghost=sprite.duplicate(); break
	queue_redraw()

func _pressed(plate: Dictionary) -> bool:
	return bool(plate.get("pressed",false))

func _latch_down(latch: Dictionary) -> bool:
	for fixture in state.fixtures:
		if fixture.id==latch.get("gate_id",""): return fixture.get("latched",false)
	return false

static func lamp(depth: float) -> float:
	return clampf((FAR-depth)/2.7,0.0,1.0)

## The carried Seal's light, tuned by the owner in data/presentation/seal_light.json.
## Full light out to `core`; then the light falls in `steps` gentle levels to
## black at `edge`, and each pixel is ordered-dithered (8x8 Bayer) between its
## level and the next darker one. The owner: "closest to you ... the darker bayer
## matrix is barely darker than the wall color ... then further in the wall turns
## darker and ... the matrix is of a slightly darker color on top ... until we
## reach full dark."
const BAYER8=[0,32,8,40,2,34,10,42,48,16,56,24,50,18,58,26,12,44,4,36,14,46,6,38,60,28,52,20,62,30,54,22,3,35,11,43,1,33,9,41,51,19,59,27,49,17,57,25,15,47,7,39,13,45,5,37,63,31,55,23,61,29,53,21]
const DITHER_LEVELS:=16
var _seal_light: Dictionary={}
var _dither_masks: Array=[]
func _seal_config() -> Dictionary:
	if _seal_light.is_empty():
		_seal_light={"core":1.1,"edge":3.5,"steps":8,"curve":1.0,"gain":1.0,"slate_gain":1.1}
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/presentation/seal_light.json")) if FileAccess.file_exists("res://data/presentation/seal_light.json") else null
		if data is Dictionary: _seal_light.merge(data,true)
	return _seal_light
## 0 inside the core, 1 at the edge of the dark.
func _seal_band(distance: float) -> float:
	var c: Dictionary=_seal_config()
	return clampf((distance-float(c.core))/maxf(0.01,float(c.edge)-float(c.core)),0.0,1.0)
func _seal_gain(family: int) -> float:
	return float(_seal_config()["slate_gain" if family==4 else "gain"])
## The two neighbouring levels at this distance: [upper brightness, lower
## brightness, share of pixels that drop to the lower one].
func _seal_levels(distance: float) -> Array:
	var c: Dictionary=_seal_config()
	var steps: float=maxf(1.0,float(c.steps))
	var v: float=pow(1.0-_seal_band(distance),float(c.curve))*steps
	var lower: float=floorf(v)
	if lower>=steps: return [1.0,1.0,0.0]
	return [(lower+1.0)/steps,lower/steps,1.0-(v-lower)]
static func _dithered_down(share: float,x: int,y: int) -> bool:
	return share>(BAYER8[posmod(y,8)*8+posmod(x,8)]+0.5)/64.0
## Screen-locked black dither strips, one per share level. Columns fade them so
## a pixel only drops to the next level, never straight to black.
func _dither_mask(share: float) -> Texture2D:
	if _dither_masks.is_empty():
		for level in range(DITHER_LEVELS+1):
			var image:=Image.create(8,HEIGHT,false,Image.FORMAT_RGBA8)
			for y in range(HEIGHT):
				for x in range(8):
					if _dithered_down(float(level)/DITHER_LEVELS,x,y): image.set_pixel(x,y,Color(0,0,0,1))
			_dither_masks.append(ImageTexture.create_from_image(image))
	return _dither_masks[clampi(roundi(share*DITHER_LEVELS),0,DITHER_LEVELS)]
## One column strip at the upper level, with the dithered share of its pixels
## dropped to the lower level.
func _seal_column(texture: Texture2D,rect: Rect2,source: Rect2,gain: float,levels: Array) -> void:
	var upper: float=gain*levels[0]
	if upper<=0.0: draw_rect(rect,Color.BLACK); return
	draw_texture_rect_region(texture,rect,source,Color(upper,upper,upper))
	if levels[2]>0.0 and levels[1]<levels[0]:
		draw_texture_rect_region(_dither_mask(levels[2]),rect,Rect2(posmod(int(rect.position.x),8),rect.position.y,1,rect.size.y),Color(1,1,1,1.0-levels[1]/levels[0]))
func _light(depth: float,_x: int=0,_y: int=0,family: int=4) -> float:
	if not state.get("seal_glow",false): return lamp(depth)
	var levels: Array=_seal_levels(depth)
	return _seal_gain(family)*lerpf(levels[0],levels[1],levels[2])

func update_state(snapshot: Dictionary) -> void:
	if not state.is_empty() and (state.floor!=snapshot.floor or state.pos!=snapshot.pos or state.facing!=snapshot.facing):
		# Input can resume before the effect ends. Never leave a hit painted on
		# empty space after stepping/turning or arriving on another landing.
		_strike={}
		_dispel={}
	state=snapshot
	_build_camera()
	queue_redraw()

func projection(id: String) -> Dictionary:
	return _projections.get(id,{}).duplicate()

func _solid(cell: Vector2i) -> bool:
	if cell.x<0 or cell.y<0 or cell.x>=state.width or cell.y>=state.height: return true
	if state.tiles[cell.y*state.width+cell.x]==1: return true
	return false

func _face_key(cell: Array,normal: Vector2i) -> String:
	return "%d:%d:%d:%d"%[cell[0],cell[1],normal.x,normal.y]

func _architecture() -> void:
	_faces={}; _portals=[]; _lever_faces={}
	_bindings=Faces.all(state)
	var bindings: Dictionary=_bindings
	for fixture in state.fixtures:
		var kind: String=fixture.type
		if kind=="latch" and bindings.has(fixture.id):
			_lever_faces[Faces.key(bindings[fixture.id].wall,bindings[fixture.id].normal)]=true
			continue
		if kind=="panel":
			if fixture.get("passage",false) and fixture.open:
				_portals.append({"id":fixture.id,"kind":"dawn","pos":fixture.wall,"center":Vector2(fixture.wall[0]+0.5,fixture.wall[1]+0.5)+Vector2(fixture.normal[0],fixture.normal[1])*0.5,"normal":Vector2(fixture.normal[0],fixture.normal[1]),"texture_path":"res://assets/art/env/painted_f%d_door_open_overlay_v2.png"%Family.at(state,fixture.pos).walls})
				continue
			var path: String="res://assets/art/fixtures/fixture_v2_f%d_cache_open_64.png"%Family.for_floor(state.floor).fixtures if fixture.open else "res://assets/art/env/painted_f%d_plain_0.png"%Family.at(state,fixture.pos).walls
			_faces[_face_key(fixture.wall,Vector2i(fixture.normal[0],fixture.normal[1]))]={"id":fixture.id,"kind":"panel","texture_path":path,"panel_state":"" if fixture.open else ("revealed" if fixture.revealed else "plain")}
			continue
		if kind in ["gate","lock","web","cord"]:
			var p:=Vector2i(fixture.pos[0],fixture.pos[1])
			var across_x: bool=state.tiles[p.y*state.width+p.x-1]==1 and state.tiles[p.y*state.width+p.x+1]==1
			var path: String="res://assets/art/fixtures/architecture_f%d_gate_%s_overlay_64.png"%[Family.for_floor(state.floor).fixtures,"open" if fixture.open else "closed"]
			if kind=="lock": path="res://assets/art/env/painted_f%d_%s_v2.png"%[Family.at(state,fixture.pos).walls,"door_open_overlay" if fixture.open else "door"]
			if kind=="web": path="res://assets/art/fixtures/fixture_v2_web_%s_d1.png"%("burnt" if fixture.open else "intact")
			if kind=="cord": path="res://assets/art/fixtures/fixture_v2_cord_grate_%s_d1.png"%("cut" if fixture.open else "intact")
			var normal:=Vector2(0,1) if across_x else Vector2(1,0)
			var center:=Vector2(p)+Vector2(0.5,0.5)
			# Locks formerly occupied a whole solid cell. Retain its entry face
			# in both states; never choose a different plane from camera facing.
			if kind=="lock": center+=normal*0.5
			_portals.append({"id":fixture.id,"kind":kind,"pos":fixture.pos,"center":center,"normal":normal,"texture_path":path,"metal":fixture.get("metal","") if kind=="lock" and not fixture.open else "","family":Family.at(state,fixture.pos).walls})
			continue
		if kind not in ["exit","stairs_up","stairs_down","lift"]: continue
		if not bindings.has(fixture.id): continue
		var binding: Dictionary=bindings[fixture.id]
		var art_kind: String=("lift_working" if fixture.active else "lift_dead") if kind=="lift" else kind
		var family: String="architecture_v3" if kind in ["stairs_up","stairs_down"] else ("architecture_v2" if art_kind=="lift_dead" else "architecture")
		_faces[Faces.key(binding.wall,binding.normal)]={"id":fixture.id,"kind":kind,"texture_path":"res://assets/art/fixtures/%s_f%d_%s_64.png"%[family,Family.for_floor(state.floor).fixtures,art_kind]}

func dressing_allowed(cell: Array) -> bool:
	# Both logical landings and their painted wall faces reserve a full ring.
	for fixture in state.fixtures:
		if fixture.type not in ["gate","lock","stairs_up","stairs_down","exit","lift"]: continue
		if maxi(absi(cell[0]-fixture.pos[0]),absi(cell[1]-fixture.pos[1]))<=1: return false
	for key in _faces:
		var parts: PackedStringArray=key.split(":")
		if maxi(absi(cell[0]-int(parts[0])),absi(cell[1]-int(parts[1])))<=1: return false
	# Openings between wall ends must not acquire a plausible false continuation.
	for d in Sim.DIRS:
		var p: Array=[cell[0]+d[0],cell[1]+d[1]]
		if p[0]<=0 or p[1]<=0 or p[0]>=state.width-1 or p[1]>=state.height-1: continue
		if state.tiles[p[1]*state.width+p[0]]==0:
			var across: Array=[-d[1],d[0]]
			if state.tiles[(p[1]+across[1])*state.width+p[0]+across[0]]==0 and state.tiles[(p[1]-across[1])*state.width+p[0]-across[0]]==0: return false
	return true

func _wall_path(cell: Array,normal: Vector2i) -> String:
	var key: String="%s/%d/%s"%[state.get("seed",""),state.floor,_face_key(cell,normal)]
	if not _face_choices.has(key):
		var value: int=Paint.mix_hash(key)
		var roll: int=value%24
		# The owner: a grate or banner hid the lever. Its face keeps bare or
		# dirty stone only (damp, crack).
		if _lever_faces.has(_face_key(cell,normal)) and roll not in [3,4]: roll=-1
		var suffix: String="plain_%d"%(value%3)
		if roll==0: suffix="sconce"
		elif roll==1: suffix="tapestry"
		elif roll==2: suffix="chains"
		elif roll==3: suffix="damp"
		elif roll==4: suffix="crack"
		elif roll==5: suffix="drain"
		elif roll==6 and dressing_allowed(cell): suffix="arch_blocked" if value%2==0 else "door_barricaded"
		_face_choices[key]=suffix
	var suffix: String=_face_choices[key]
	if suffix=="sconce":
		_has_sconce=true; suffix="sconce_%d"%(int(_presentation_ms/250)%2)
	return "res://assets/art/env/painted_f%d_%s%s.png"%[Family.at(state,[cell[0]+normal.x,cell[1]+normal.y]).walls,suffix,"_v2" if suffix in ["drain","chains","tapestry","crack","damp","sconce_0","sconce_1"] else ""]

func visible_cells() -> Array: return _visible_cells.duplicate(true)
## The owner: stepping into a room should map it, "closer to how a human would
## see it", not cell by cell. A room cell is open and inside some open 2x2
## patch (corridors never are). Closed gates, doors, webs and cords stop the
## fill; it maps up to 64 room cells plus the walls and mouths around them.
## Secrets stay hidden: a sleeping panel is only masonry on the map.
func room_cells() -> Array:
	if state.is_empty() or not _roomy(state.pos): return []
	var blocked: Dictionary={}
	for fixture in state.fixtures:
		if fixture.type in ["gate","lock","web","cord"] and not fixture.get("open",false): blocked[fixture.pos[1]*state.width+fixture.pos[0]]=true
	var room: Dictionary={}; var frontier: Array=[state.pos]
	while not frontier.is_empty() and room.size()<64:
		var cell: Array=frontier.pop_front()
		var key: int=cell[1]*state.width+cell[0]
		if room.has(key): continue
		room[key]=cell
		for d in Sim.DIRS:
			var next: Array=[cell[0]+d[0],cell[1]+d[1]]
			if not room.has(next[1]*state.width+next[0]) and not blocked.has(next[1]*state.width+next[0]) and _roomy(next): frontier.append(next)
	var result: Dictionary={}
	for cell in room.values():
		for dy in range(-1,2):
			for dx in range(-1,2):
				var near: Array=[cell[0]+dx,cell[1]+dy]
				if near[0]>=0 and near[1]>=0 and near[0]<state.width and near[1]<state.height: result[near[1]*state.width+near[0]]=near
	return result.values()
func _roomy(cell: Array) -> bool:
	for oy in [-1,0]:
		for ox in [-1,0]:
			var open:=true
			for dy in range(2):
				for dx in range(2):
					if _solid(Vector2i(cell[0]+ox+dx,cell[1]+oy+dy)): open=false
			if open: return true
	return false
func visible_landmarks() -> Array:
	var result: Array=[]
	for fixture in state.fixtures:
		if fixture.type=="panel" and not fixture.revealed: continue
		if _projections.has(fixture.id) and _visible_set.has(fixture.pos[1]*state.width+fixture.pos[0]): result.append(fixture.id)
	return result

func _survey_ray(origin: Vector2,ray: Vector2) -> void:
	var cell:=Vector2i(floori(origin.x),floori(origin.y))
	var dx: float=absf(1.0/ray.x) if absf(ray.x)>0.00001 else 100000.0
	var dy: float=absf(1.0/ray.y) if absf(ray.y)>0.00001 else 100000.0
	var sx: int=1 if ray.x>0 else -1; var sy: int=1 if ray.y>0 else -1
	var tx: float=(cell.x+1-origin.x)*dx if sx>0 else (origin.x-cell.x)*dx
	var ty: float=(cell.y+1-origin.y)*dy if sy>0 else (origin.y-cell.y)*dy
	var entry:=0.0
	while entry<FAR:
		if cell.x<0 or cell.y<0 or cell.x>=state.width or cell.y>=state.height: break
		var stop: bool=state.tiles[cell.y*state.width+cell.x]==1
		for fixture in state.fixtures:
			if fixture.type in ["gate","lock","web","cord"] and not fixture.open and fixture.pos==[cell.x,cell.y]: stop=true
		var finish: float=minf(FAR,minf(tx,ty))
		# Every visible surface counts, even a corner or side-wall sliver. A
		# whole cell need not contain the old centre/floor sample to be inked.
		if finish>entry+0.001 and (entry<3.35 or stop and entry<3.5):
			_visible_set[cell.y*state.width+cell.x]=[cell.x,cell.y]
		if stop: break
		if tx<ty: entry=tx; tx+=dx; cell.x+=sx
		else: entry=ty; ty+=dy; cell.y+=sy

var _visible_set: Dictionary={}

func _build_camera() -> void:
	if state.is_empty(): return
	var forward:=Vector2(Sim.DIRS[state.facing][0],Sim.DIRS[state.facing][1])
	var right:=Vector2(-forward.y,forward.x)
	var origin:=Vector2(state.pos[0]+0.5,state.pos[1]+0.5)
	var material_state: Array=[]
	for fixture in state.fixtures:
		if fixture.type=="lift": material_state.append([fixture.id,fixture.active])
		elif fixture.get("passage",false): material_state.append([fixture.id,fixture.open])
	var key: String="painted_v2/%s/%s/%s/%s/%s"%[state.seed,state.floor,state.pos,state.facing,material_state]+str([state.get("seal_glow",false),state.get("deep_materials",false)])
	if key!=_surface_key:
		_surface_key=key
		_ground_cells=Planes.ground_cells(state); _room_cells=Planes.room_cells(state)
		_build_surfaces(origin,forward,right)
	_depths.clear(); _walls.clear(); _sprites.clear(); _projections.clear()
	_visible_set={}; _architecture(); _has_sconce=false; _has_flame=false
	for column in range(WIDTH):
		var ray:=forward+right*((column+0.5-WIDTH*0.5)/FOCAL)
		_survey_ray(origin,ray)
		var cell:=Vector2i(floori(origin.x),floori(origin.y))
		var dx:=absf(1.0/ray.x) if absf(ray.x)>0.00001 else 100000.0
		var dy:=absf(1.0/ray.y) if absf(ray.y)>0.00001 else 100000.0
		var sx:=1 if ray.x>0 else -1
		var sy:=1 if ray.y>0 else -1
		var tx: float=(cell.x+1-origin.x)*dx if sx>0 else (origin.x-cell.x)*dx
		var ty: float=(cell.y+1-origin.y)*dy if sy>0 else (origin.y-cell.y)*dy
		var depth:=0.0
		var side:=false
		for _step in range(24):
			if tx<ty: depth=tx; tx+=dx; cell.x+=sx; side=true
			else: depth=ty; ty+=dy; cell.y+=sy; side=false
			if _solid(cell): break
		depth=maxf(0.1,depth); _depths.append(depth)
		var hit:=origin+ray*depth
		var u: float=hit.y-floorf(hit.y) if side else hit.x-floorf(hit.x)
		var normal:=Vector2i(-sx,0) if side else Vector2i(0,-sy)
		var face: Dictionary=_faces.get(_face_key([cell.x,cell.y],normal),{})
		var path: String=face.get("texture_path",_wall_path([cell.x,cell.y],normal))
		_walls.append({"depth":depth,"height":maxi(1,roundi(FOCAL/depth)),"u":clampi(int(u*64),0,63),"light":(_seal_gain(Family.at(state,[cell.x+normal.x,cell.y+normal.y]).walls) if state.get("seal_glow",false) else lamp(depth))*(0.78 if side else 1.0),"seal_distance":origin.distance_to(hit) if state.get("seal_glow",false) else -1.0,"path":path,"cell":[cell.x,cell.y],"id":face.get("id",""),"panel_state":face.get("panel_state","")})
		if face.has("id"):
			var h: float=FOCAL/depth
			if face.get("kind","") in ["stairs_up","stairs_down","lift","exit"]:
				# The doorway is inset in a complete masonry face. Attach cues
				# and touch to its actual arch, not the surrounding wall tile.
				if u>=0.18 and u<=0.82: _project_column(face.id,column,HORIZON-h*0.40,h*0.88,depth)
			else: _project_column(face.id,column,HORIZON-h/2,h,depth)
	_visible_cells=_visible_set.values()
	for portal in _portals:
		var columns: Dictionary={}
		var center: Vector2=portal.center
		var normal: Vector2=portal.normal
		var along:=Vector2(normal.y,-normal.x)
		for x in range(WIDTH):
			var ray:=forward+right*((x+0.5-WIDTH*0.5)/FOCAL)
			var divisor: float=ray.dot(normal)
			if absf(divisor)<0.0001: continue
			var distance: float=(center-origin).dot(normal)/divisor
			if distance<0.08 or distance>=FAR or distance>=_depths[x]: continue
			var u: float=(origin+ray*distance-center).dot(along)+0.5
			if u<0 or u>=1: continue
			var h: float=FOCAL/distance
			columns[x]={"depth":distance,"height":h,"u":clampi(int(u*64),0,63)}
			_project_column(portal.id,x,HORIZON-h/2,h,distance)
		portal.columns=columns
		portal.strips=Paint.strips(portal.texture_path)
	var sprites: Array=state.objects.duplicate(true)
	for prop in state.get("props",[]):
		# Dropped possessions and visiting actors always take precedence.
		if state.objects.any(func(o): return o.pos==prop.pos) or state.actors.any(func(a): return a.hp>0 and a.pos==prop.pos): continue
		var decoration: Dictionary=prop.duplicate(true); decoration.prop_kind=prop.kind; decoration.kind="decor"
		sprites.append(decoration)
	for fixture in state.fixtures:
		if fixture.type not in ["gate","lock","stairs_up","stairs_down","exit","lift","web","cord","panel"]:
			var sprite: Dictionary=fixture.duplicate(true)
			sprite.kind="lift_on" if fixture.type=="lift" and fixture.get("active",false) else fixture.type
			sprites.append(sprite)
	for actor in state.actors:
		if actor.hp>0: sprites.append(actor.duplicate(true))
	for sprite in sprites:
		var relative:=Vector2(sprite.pos[0]+0.5,sprite.pos[1]+0.5)-origin
		if sprite.kind=="decor":
			if sprite.prop_kind=="pillar":
				# Flush with the near side of the already solid masonry recess.
				relative-=forward*0.515
			else: relative+=Vector2(sprite.offset[0],sprite.offset[1])/100.0
		var depth: float=relative.dot(forward)
		var lateral: float=relative.dot(right)
		var wall_normal:=Vector2.ZERO
		var hinge:=Vector2.ZERO
		if sprite.kind=="latch":
			# Use the same physical wall binding as forward/PULL interaction.
			var binding: Dictionary=_bindings.get(sprite.id,{})
			if binding.is_empty():
				push_error("Lever has no physical wall: "+sprite.id); continue
			wall_normal=-Vector2(binding.normal[0],binding.normal[1])
			hinge=Vector2(sprite.pos[0]+0.5,sprite.pos[1]+0.5)+wall_normal*0.485
			relative=hinge-origin; depth=relative.dot(forward); lateral=relative.dot(right)
		# A possession at someone's feet must remain visible beside the body.
		# This is sprite placement only; pickup still targets the same sim cell.
		if sprite.kind!="decor" and not sprite.has("type") and not sprite.has("hp"):
			for resident in state.actors:
				if resident.hp>0 and resident.state=="peaceful" and resident.pos==sprite.pos:
					lateral+=0.35; break
			for fixture in state.fixtures:
				if fixture.pos==sprite.pos and fixture.type=="panel": lateral-=0.3; break
				if fixture.pos==sprite.pos and fixture.type in ["porter","lift"]:
					lateral+=0.3; break
		# Own-cell contents are shown at the bottom edge, where hands can reach.
		var underfoot: bool=sprite.pos==state.pos and sprite.kind!="latch"
		if underfoot and sprite.kind=="decor": continue
		if underfoot and sprite.kind=="exit": continue # The entrance is behind us.
		if underfoot: depth=0.72; lateral=0.0
		var near_limit: float=0.3 if sprite.kind=="latch" or sprite.kind=="decor" and sprite.prop_kind=="pillar" else 0.5
		if depth<near_limit or depth>=FAR: continue
		var texture: Texture2D
		var tall: int
		var hinge_pixel:=Vector2.ZERO
		var kind: String=sprite.kind
		var variant: int=0 if depth<1.5 else (1 if depth<2.5 else 2)
		if kind=="decor":
			texture=Paint.texture("res://assets/art/props/f%d_%s_d%d.png"%[Family.at(state,sprite.pos).props,sprite.prop_kind,variant+1])
			tall=roundi(FOCAL/depth) if sprite.prop_kind=="pillar" else [64,40,24][variant]
		elif kind=="husk":
			var pose: String="recoil" if sprite.get("state","")=="recovery" else str(sprite.get("state","idle"))
			texture=_poses.get(pose,_poses.idle)[variant]; tall=[64,40,24][variant]
		elif kind in ["hound","ghost"]:
			var pose: String="recoil" if sprite.state=="recovery" else ("windup" if sprite.state=="windup" else "idle")
			texture=_creature_poses[kind][pose][variant]; tall=[64,40,24][variant]
		elif kind in ["brazier","torch","seal"]:
			texture=_painted_fixture(sprite,variant); tall=texture.get_height(); _has_flame=true
		elif kind=="porter":
			texture=_restored[variant] if sprite.get("restored",false) else _porters[variant]; tall=[64,40,24][variant]
		elif kind=="plate":
			texture=_fixture_textures["f%d_plate_%s_d%d"%[Family.for_floor(state.floor).fixtures,"down" if _pressed(sprite) else "up",variant+1]]
			tall=texture.get_height()
		elif kind=="latch":
			# Sized with the wall it hangs on, so it grows as you step up (the
			# owner saw it shrink). Front d1 is drawn on a 64-texel face, the
			# owner's side d1 at one cell; the nearest painted size is scaled.
			var head_on: bool=absf(wall_normal.dot(forward))>0.9
			var hand: String="front" if head_on else ("left" if lateral<0 else "right")
			tall=roundi((40.0*FOCAL/64.0 if head_on else 36.0)/depth)
			for d in range(1,4):
				var name: String=("lever_front_%s_d%d" if head_on else "lever_"+hand+"_%s_d%d")%["down" if _latch_down(sprite) else "up",d]
				var candidate: Texture2D=_fixture_textures[name]
				if texture==null or absi(candidate.get_height()-tall)<absi(texture.get_height()-tall): texture=candidate; variant=d-1
			hinge_pixel=LEVER_HINGES["front" if head_on else "side"][variant]
			if hand=="right": hinge_pixel.x=texture.get_width()-hinge_pixel.x
		elif not sprite.has("type") and not sprite.has("hp"):
			var item_kind: String="coat_spent" if kind=="coat" and sprite.get("spent",false) else kind
			texture=Paint.texture(Metal.world_path(sprite.metal,variant+1) if kind=="key" and sprite.get("metal","")!="" else "res://assets/art/items/item_%s_d%d.png"%[item_kind,variant+1])
			tall=texture.get_height()
		else:
			push_error("No painted world representation for "+kind); continue
		var wide:=maxi(1,roundi(tall*texture.get_width()/float(texture.get_height())))
		var ground:=HORIZON+roundi(FOCAL*0.5/depth)
		if underfoot:
			ground=HEIGHT+4
		if kind=="plate":
			# A shallow floor trapezoid, not a billboard with a minimum height.
			ground=mini(HEIGHT+3,ground+maxi(2,roundi(8.0/depth)))
		if not sprite.has("type") and not sprite.has("hp"):
			for fixture in state.fixtures:
				if fixture.type=="plate" and fixture.pos==sprite.pos:
					# The object's feet meet the slab's centre; sort after the slab.
					ground-=2
		var rect:=Rect2(roundi(WIDTH*0.5+lateral*FOCAL/depth)-wide/2,ground-tall,wide,tall)
		if kind=="latch":
			var anchor: Vector2=(hinge_pixel*rect.size/texture.get_size()).round()
			rect.position=Vector2(roundi(WIDTH*0.5+lateral*FOCAL/depth),HORIZON-roundi(6.0/depth))-anchor
		var visible:=false
		for x in range(maxi(0,int(rect.position.x)),mini(WIDTH,int(rect.end.x))):
			if depth<_depths[x]: visible=true; break
		if not visible or rect.end.y<=0 or rect.position.y>=HEIGHT: continue
		sprite.merge({"depth":depth,"rect":rect,"texture":texture,"light":maxf(0.18,_light(depth,roundi(rect.get_center().x),0,1)),"underfoot":underfoot,"variant":variant,"wall_normal":wall_normal,"hinge":hinge,"origin":origin,"forward":forward,"right":right},true)
		_sprites.append(sprite)
		var texture_key: int=texture.get_instance_id()
		if not _opaque_bounds.has(texture_key): _opaque_bounds[texture_key]=texture.get_image().get_used_rect()
		var opaque: Rect2=Rect2(_opaque_bounds[texture_key])
		var ratio:=rect.size/Vector2(texture.get_width(),texture.get_height())
		var clipped:=Rect2(rect.position+opaque.position*ratio,opaque.size*ratio).intersection(Rect2(0,0,WIDTH,HEIGHT))
		if not clipped.has_area(): continue
		if kind!="decor": _projections[sprite.id]={"rect":clipped,"anchor":clipped.get_center(),"depth":depth}
	_sprites.sort_custom(func(a,b):
		if a.depth!=b.depth: return a.depth>b.depth
		if (a.kind=="plate")!=(b.kind=="plate"): return a.kind=="plate"
		return a.id>b.id)
	_column_layers=[]
	for x in range(WIDTH):
		var layers: Array=[]
		for sprite in _sprites:
			if x>=sprite.rect.position.x and x<sprite.rect.end.x: layers.append({"depth":sprite.depth,"sprite":sprite,"order":1 if sprite.kind=="plate" else 2})
		for portal in _portals:
			if portal.columns.has(x): layers.append({"depth":portal.columns[x].depth,"portal":portal,"column":portal.columns[x],"order":0})
		layers.sort_custom(func(a,b):
			if a.depth!=b.depth: return a.depth>b.depth
			return a.order<b.order)
		_column_layers.append(layers)

func _project_column(id: String,x: int,top: float,height: float,depth: float) -> void:
	if depth>=FAR: return
	var rect:=Rect2(x,maxf(0,top),1,minf(HEIGHT,top+height)-maxf(0,top))
	if not rect.has_area(): return
	if _projections.has(id): rect=rect.merge(_projections[id].rect)
	_projections[id]={"rect":rect,"anchor":rect.get_center(),"depth":depth,"architecture":true}

func _sprite_visible(sprite: Dictionary,x: int) -> bool:
	var depth: float=sprite.depth
	if sprite.kind=="latch":
		var ray: Vector2=sprite.forward+sprite.right*((x+0.5-WIDTH*0.5)/FOCAL)
		var divisor: float=ray.dot(sprite.wall_normal)
		if absf(divisor)<0.00001: return false
		depth=(sprite.hinge-sprite.origin).dot(sprite.wall_normal)/divisor
	return depth>0 and depth<_depths[x]+0.02

func _draw_sprite(sprite: Dictionary,shift: int,force_recoil: bool=false,only_column: int=-1) -> void:
	var rect: Rect2=sprite.rect; rect.position.y+=shift
	var texture: Texture2D=sprite.texture
	var hit: bool=not _strike.is_empty() and sprite.id==_strike.id
	if sprite.kind=="husk" and (hit or force_recoil): texture=_poses.recoil[sprite.variant]
	if sprite.kind in ["hound","ghost"] and (hit or force_recoil): texture=_creature_poses[sprite.kind].recoil[sprite.variant]
	if sprite.kind in ["brazier","torch","seal"]: texture=_painted_fixture(sprite,sprite.variant)
	var light: float=sprite.light
	var tint:=Color(light,light,light)
	if sprite.kind=="ghost" and not _dispel.is_empty() and _dispel.sprite.id==sprite.id: tint.a=clampf(1.0-_dispel.age/Times.DISPEL,0,1)
	if hit and not _strike.get("flash_drawn",false): tint=Color(2.5,2.5,2.5)
	var start: int=maxi(0,int(rect.position.x)) if only_column<0 else only_column
	var end: int=mini(WIDTH,int(rect.end.x)) if only_column<0 else only_column+1
	for x in range(start,end):
		if not _sprite_visible(sprite,x): continue
		if sprite.kind not in ["plate","latch"]:
			var texture_key: int=texture.get_instance_id()
			if not _opaque_bounds.has(texture_key): _opaque_bounds[texture_key]=texture.get_image().get_used_rect()
			var bounds: Rect2=Rect2(_opaque_bounds[texture_key]) if not sprite.has("type") and not sprite.has("hp") else Rect2(Vector2.ZERO,texture.get_size())
			var scale_factor: Vector2=rect.size/texture.get_size()
			var shadow: Rect2=Rect2(rect.position+bounds.position*scale_factor,bounds.size*scale_factor)
			var norm: float=(x-shadow.get_center().x)/maxf(1.0,shadow.size.x*0.5)
			if absf(norm)>1: continue
			draw_rect(Rect2(x,mini(HEIGHT-3,rect.end.y-3),1,maxi(1,roundi(3*(1-norm*norm)))),Color("080b11"))
		var source_x:=floorf((x-rect.position.x)*texture.get_width()/rect.size.x)
		draw_texture_rect_region(texture,Rect2(x,rect.position.y,1,rect.size.y),Rect2(source_x,0,1,texture.get_height()),tint)
		if sprite.kind=="hound":
			var pose: String="recoil" if hit or force_recoil or sprite.state=="recovery" else ("windup" if sprite.state=="windup" else "idle")
			var glow: Texture2D=_hound_glow[pose][sprite.variant]
			draw_texture_rect_region(glow,Rect2(x,rect.position.y,1,rect.size.y),Rect2(source_x,0,1,glow.get_height()),Color(0.85,0.85,0.85,tint.a))

func _build_surfaces(origin: Vector2,forward: Vector2,right: Vector2) -> void:
	var image:=Image.create(WIDTH,HEIGHT,false,Image.FORMAT_RGBA8)
	image.fill(Color("050609"))
	var images: Dictionary={}
	for y in range(HEIGHT):
		var floor_side: bool=y>HORIZON
		var offset: float=absf(y-HORIZON)+0.5
		var depth: float=FOCAL*0.5/offset
		if depth>=FAR: continue
		var light: float=lamp(depth)*(0.86 if floor_side else 0.64)
		for x in range(WIDTH):
			var point:=origin+(forward+right*((x+0.5-WIDTH*0.5)/FOCAL))*depth
			var u:=posmod(floori(point.x*64),64)
			var v:=posmod(floori(point.y*64),64)
			var cell:=Vector2i(floori(point.x),floori(point.y))
			var uv:=Vector2i(u,v)
			var path: String
			if floor_side and _ground_cells.has(cell):
				path=_ground_cells[cell].path; uv=Planes.ground_uv(u,v,_ground_cells[cell].normal)
			elif _room_cells.has(cell): path=_room_cells[cell]["floor" if floor_side else "ceiling"]
			else: path=Planes.path(state.seed,state.floor,"floor" if floor_side else "ceiling",cell.x,cell.y,Family.at(state,[cell.x,cell.y]))
			if not images.has(path): images[path]=Paint.image(path)
			var colour: Color=images[path].get_pixel(uv.x,uv.y)
			if state.get("seal_glow",false):
				var levels: Array=_seal_levels(origin.distance_to(point))
				light=_seal_gain(4 if path.contains("calm_v3_f4") else 1)*(levels[1] if _dithered_down(levels[2],x,y) else levels[0])*(0.86 if floor_side else 0.64)
			image.set_pixel(x,y,Color(colour.r*light,colour.g*light,colour.b*light,1))
	_surfaces=ImageTexture.create_from_image(image)

func _draw() -> void:
	draw_rect(Rect2(0,0,WIDTH,HEIGHT),Color("050609"))
	if state.is_empty(): return
	var shift:=roundi(motion)
	if _surfaces!=null: draw_texture(_surfaces,Vector2(0,shift))
	for column in range(_walls.size()):
		var wall: Dictionary=_walls[column]
		var top_wall: int=HORIZON+shift-wall.height/2
		var top:=maxi(0,top_wall)
		var bottom:=mini(HEIGHT,top_wall+wall.height)
		var light: float=wall.light
		if bottom<=top: continue
		var path: String=wall.path
		if path.contains("sconce_"): path=path.left(path.rfind("sconce_"))+"sconce_%d_v2.png"%(int(_presentation_ms/250)%2)
		var levels: Array=_seal_levels(wall.seal_distance) if wall.get("seal_distance",-1.0)>=0.0 else [1.0,1.0,0.0]
		var band: float=1.0-lerpf(levels[0],levels[1],levels[2])
		_seal_column(Paint.strips(path)[wall.u],Rect2(column,top,1,bottom-top),Rect2(0,(top-top_wall)*64.0/wall.height,1,(bottom-top)*64.0/wall.height),light,levels)
		if wall.panel_state!="":
			# The owner: "The picture on the wall should glow when you hold up the
			# seal." Held up, the Seal shows any mark it faces, revealed or not,
			# pulsing with it; put away, an unrevealed mark is faint scratches.
			var held_up: bool=held.kind=="seal"
			var marks: String="res://assets/art/fixtures/panel_sigil_%s_64.png"%("plain" if wall.panel_state=="plain" and not held_up else "revealed")
			var tint:=Color(light,light,light)*(1.0-band)
			if held_up:
				var pulse: float=0.5+0.5*sin(_presentation_ms/1000.0*TAU)
				tint=Color(1.0+0.7*pulse,1.0+0.55*pulse,1.0+0.25*pulse)
			elif wall.panel_state!="plain": tint=Color.WHITE
			tint.a=1.0
			draw_texture_rect_region(Paint.strips(marks)[wall.u],Rect2(column,top,1,bottom-top),Rect2(0,(top-top_wall)*64.0/wall.height,1,(bottom-top)*64.0/wall.height),tint)
		for layer in _column_layers[column]:
			if layer.has("sprite"):
				_draw_sprite(layer.sprite,shift,false,column)
			else:
				var p: Dictionary=layer.column
				var py: float=HORIZON+shift-p.height/2
				var from_y: float=maxf(0,py); var to_y: float=minf(HEIGHT,py+p.height)
				var seal: bool=state.get("seal_glow",false)
				var gain: float=_seal_gain(layer.portal.get("family",1)) if seal else lamp(p.depth)
				var portal_levels: Array=_seal_levels(p.depth*sqrt(1.0+pow((column+0.5-WIDTH*0.5)/FOCAL,2))) if seal else [1.0,1.0,0.0]
				var strips: Array=layer.portal.strips
				if _burning.has(layer.portal.id): strips=Paint.strips("res://assets/art/fixtures/fixture_v2_web_burning_%d_d1.png"%mini(1,int(float(_burning[layer.portal.id])/Times.WEB_FRAME)))
				if to_y>from_y:
					_seal_column(strips[p.u],Rect2(column,from_y,1,to_y-from_y),Rect2(0,(from_y-py)*64.0/p.height,1,(to_y-from_y)*64.0/p.height),gain,portal_levels)
					if layer.portal.get("metal","")!="":
						var plate: Array=Paint.strips(Metal.plate_path(layer.portal.family,layer.portal.metal))
						_seal_column(plate[p.u],Rect2(column,from_y,1,to_y-from_y),Rect2(0,(from_y-py)*64.0/p.height,1,(to_y-from_y)*64.0/p.height),gain,portal_levels)
	if not _dispel.is_empty(): _draw_sprite(_dispel.sprite,shift,true)
	if not _strike.is_empty():
		if _strike.has("ghost") and not _sprites.any(func(s): return s.id==_strike.id): _draw_sprite(_strike.ghost,shift,true)
		var frame: int=clampi(int(_strike.age/Times.STRIKE_FRAME),0,2)
		var anchor: Vector2=_strike.target.anchor+Vector2(0,shift-2*frame)
		var effect_size: float=clampf(_strike.target.rect.size.y,32,64)
		draw_texture_rect(_effects[_strike.kind][frame],Rect2((anchor-Vector2.ONE*effect_size*0.5).round(),Vector2.ONE*effect_size),false)
		draw_texture(_effects.damage_burst[frame],(anchor-Vector2(32,32)).round())
		var number: String=str(_strike.damage)
		var width: float=DAMAGE_FONT.get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		var baseline: Vector2=(anchor+Vector2(-width/2,-1)).round()
		draw_string(DAMAGE_FONT,baseline+Vector2.ONE,number,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("0c101c"))
		draw_string(DAMAGE_FONT,baseline,number,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("efe3ba"))
		_strike.flash_drawn=true
	for cue in interaction_cues:
		var rect: Rect2=cue.rect
		rect.position.y+=shift
		var colour: Color=cue.colour
		var signature: String="%d:%s"%[state.floor,cue.id]
		if not _glint_phases.has(signature): _glint_phases[signature]=Paint.mix_hash(signature)%2200
		var local_ms: int=(int(_presentation_ms)+_glint_phases[signature])%(900 if cue.selected else 2200)
		var sparkle_frame: int=0 if local_ms<70 else (1 if local_ms<170 else (2 if local_ms<260 else -1))
		if sparkle_frame>=0:
			var pixels: int=9 if rect.size.y>=32 else 7
			var point:=Vector2(clampf(rect.end.x-3,5,WIDTH-6),clampf(rect.position.y+rect.size.y*0.35,5,HEIGHT-6)).round()
			# Gold frames modulate to the exact item's accent on selected targets.
			var tint:=Color(colour.r/0.45,colour.g/0.64,colour.b/0.60) if cue.selected else Color.WHITE
			draw_texture(_sparkles["%s_%d"%["target" if cue.selected else "gold",pixels]][sparkle_frame],point-Vector2.ONE*(pixels/2),tint)
		if cue.get("threshold",false) and not cue.selected:
			# A little brass/lamplight point on the keystone ties the travel
			# verb to its arch even between the larger sparkle's brief pulses.
			var keystone: Vector2=Vector2(rect.get_center().x,rect.position.y+3).round()
			draw_texture(_sparkles.gold_7[0],keystone-Vector2(3,3),Color(1,1,1,0.8))
		if cue.selected:
			var bright: Color=colour.lightened(0.35+0.15*(sin(_pulse*3.0)+1)/2)
			rect=rect.grow(2).intersection(Rect2(2,2,WIDTH-4,HEIGHT-4))
			for corner in [rect.position,Vector2(rect.end.x,rect.position.y),Vector2(rect.position.x,rect.end.y),rect.end]:
				var inward: Vector2=(rect.get_center()-corner).sign()
				draw_line(corner,corner+Vector2(inward.x*6,0),Color("080b11"),4)
				draw_line(corner,corner+Vector2(0,inward.y*6),Color("080b11"),4)
				draw_line(corner,corner+Vector2(inward.x*6,0),bright,2)
				draw_line(corner,corner+Vector2(0,inward.y*6),bright,2)
	_draw_lane()
	draw_texture(held.texture(),Vector2(100,94))
	if flash>0: draw_rect(Rect2(1,1,WIDTH-2,HEIGHT-2),Color(0.9,0.15,0.1,flash),false,2)

func _painted_fixture(sprite: Dictionary,variant: int) -> Texture2D:
	var frame: int=int(_presentation_ms/(700 if sprite.kind=="seal" else 180))%2
	var name: String="dawn_seal_pulse_%d"%frame if sprite.kind=="seal" else ("brazier_lit_%d"%frame if sprite.kind=="brazier" else ("reed_torch_lit_%d"%frame if sprite.get("lit",false) else "reed_torch_unlit"))
	return Paint.texture("res://assets/art/fixtures/%s_d%d.png"%[name,variant+1])

func _draw_lane() -> void:
	var lanes: Array=[]
	if not toss_lane.is_empty(): lanes.append({"cells":toss_lane,"colour":Color("eeb95a")})
	for actor in state.actors:
		if actor.kind=="hound" and actor.state=="windup": lanes.append({"cells":actor.intent.lane,"colour":Color("965c48")})
	var forward:=Vector2(Sim.DIRS[state.facing][0],Sim.DIRS[state.facing][1])
	var right:=Vector2(-forward.y,forward.x)
	for lane in lanes:
		for cell in lane.cells:
			var relative:=Vector2(cell[0]-state.pos[0],cell[1]-state.pos[1])
			var depth: float=relative.dot(forward)
			if depth<0.5 or depth>=FAR: continue
			var center:=Vector2(WIDTH*0.5+relative.dot(right)*FOCAL/depth,HORIZON+FOCAL*0.5/depth-3)
			var half: float=minf(18,12/depth)
			if center.x<0 or center.x>=WIDTH or depth>_depths[clampi(int(center.x),0,WIDTH-1)]: continue
			draw_polyline(PackedVector2Array([center+Vector2(-half,0),center+Vector2(0,-3),center+Vector2(half,0),center+Vector2(0,3),center+Vector2(-half,0)]),lane.colour,1)

func _process(delta: float) -> void:
	var hand_active: bool=held.remaining>0
	held.advance(delta)
	if hand_active or held.kind in ["torch_lit","seal"]: queue_redraw()
	for id in _burning.keys():
		_burning[id]+=delta
		if _burning[id]>=Times.WEB_FRAME*2: _burning.erase(id)
		queue_redraw()
	if not _dispel.is_empty():
		_dispel.age+=delta
		if _dispel.age>=Times.DISPEL: _dispel={}
		queue_redraw()
	var previous: int=int(_presentation_ms/40)
	var previous_flame: int=int(_presentation_ms/250)
	var previous_fixture: int=int(_presentation_ms/180)
	_presentation_ms=fmod(_presentation_ms+delta*1000.0,22000000.0)
	if (not interaction_cues.is_empty() and int(_presentation_ms/40)!=previous) or (_has_sconce and int(_presentation_ms/250)!=previous_flame) or (_has_flame and int(_presentation_ms/180)!=previous_fixture): queue_redraw()
	if not _strike.is_empty():
		_strike.age+=delta
		if _strike.age>=Times.STRIKE_FRAME*3: _strike={}
		queue_redraw()
	var before:=int(_pulse*8)
	_pulse=fmod(_pulse+delta,TAU)
	if not interaction_cues.is_empty() and int(_pulse*8)!=before: queue_redraw()
