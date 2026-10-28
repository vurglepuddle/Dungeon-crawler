extends Control
## Cached floor casting and grid walls share one camera with sprites/hotspots.
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Art=preload("res://scripts/art/item_art.gd")
const Paint=preload("res://scripts/art/presentation_art.gd")
const Held=preload("res://scripts/view/held_item.gd")
const WIDTH:=148
const HEIGHT:=150
const FOCAL:=74.0
const HORIZON:=71
const FAR:=3.6
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
var _portals: Array=[]
var _visible_cells: Array=[]
var _face_choices: Dictionary={}
var _glint_phases: Dictionary={}
var _sparkles: Dictionary={}
var _presentation_ms: float=0
var _has_sconce: bool=false
var _column_layers: Array=[]
var _creature_poses: Dictionary={}
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
		if ResourceLoader.exists("res://assets/art/porter_%d.png"%height): _porters.append(load("res://assets/art/porter_%d.png"%height))
		_restored.append(load("res://assets/art/anim/porter_restored_%d.png"%height))
	for pose in ["idle","windup","recoil"]:
		_poses[pose]=[]
		for height in [64,40,24]: _poses[pose].append(load("res://assets/art/anim/bell_husk_%s_%d.png"%[pose,height]))
	for kind in ["edge","heavy","hands","damage_burst"]:
		_effects[kind]=[]
		for frame in range(3): _effects[kind].append(load("res://assets/art/fx/%s_%d_64.png"%[kind,frame]))
	for d in range(1,4):
		for pressed in ["up","down"]:
			var name: String="plate_%s_d%d"%[pressed,d]
			_fixture_textures[name]=load("res://assets/art/fx/%s.png"%name)
			for side in ["left","right"]:
				name="lever_%s_%s_d%d"%[side,pressed,d]
				_fixture_textures[name]=load("res://assets/art/fx/%s.png"%name)
	for family in ["gold","target"]:
		for pixels in [7,9]:
			var key: String="%s_%d"%[family,pixels]
			_sparkles[key]=[]
			for frame in range(3): _sparkles[key].append(Paint.texture("res://assets/art/fixtures/glint_%s_%d_%d.png"%[family,frame,pixels]))
	for floor_number in [1,2]:
		for frame in range(2): Paint.strips("res://assets/art/env/painted_f%d_sconce_%d.png"%[floor_number,frame])
	for kind in ["hound","ghost"]:
		_creature_poses[kind]={}
		for pose in ["idle","windup","recoil"]:
			_creature_poses[kind][pose]=[]
			for h in [64,40,24]: _creature_poses[kind][pose].append(Paint.texture("res://assets/art/creatures/%s_%s_%d.png"%["ash_hound_ember" if kind=="hound" else "wick_ghost",pose,h]))
	for d in range(1,4):
		for name in ["brazier_lit_0","brazier_lit_1","reed_torch_unlit","reed_torch_lit_0","reed_torch_lit_1","web_intact","web_burning_0","web_burning_1","web_burnt","cord_grate_intact","cord_grate_cut","dawn_seal_pulse_0","dawn_seal_pulse_1"]:
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
	for fixture in state.fixtures:
		if fixture.type=="lock" and not fixture.open and fixture.pos==[cell.x,cell.y]: return true
	return false

func _face_key(cell: Array,normal: Vector2i) -> String:
	return "%d:%d:%d:%d"%[cell[0],cell[1],normal.x,normal.y]

func _architecture() -> void:
	_faces={}; _portals=[]
	for fixture in state.fixtures:
		var kind: String=fixture.type
		if kind=="panel":
			_faces[_face_key(fixture.wall,Vector2i(fixture.normal[0],fixture.normal[1]))]={"id":fixture.id,"kind":"panel","texture_path":"res://assets/art/env/painted_f%d_plain_0.png"%mini(state.floor,2),"panel_state":"open" if fixture.open else ("revealed" if fixture.revealed else "plain")}
			continue
		if kind in ["gate","lock","web","cord"]:
			if kind=="lock" and not fixture.open: continue
			var p:=Vector2i(fixture.pos[0],fixture.pos[1])
			var across_x: bool=state.tiles[p.y*state.width+p.x-1]==1 and state.tiles[p.y*state.width+p.x+1]==1
			var path: String="res://assets/art/fixtures/architecture_f%d_gate_%s_overlay_64.png"%[mini(state.floor,2),"open" if fixture.open else "closed"]
			if kind=="web": path="res://assets/art/fixtures/web_%s_d1.png"%("burnt" if fixture.open else "intact")
			if kind=="cord": path="res://assets/art/fixtures/cord_grate_%s_d1.png"%("cut" if fixture.open else "intact")
			_portals.append({"id":fixture.id,"kind":kind,"pos":fixture.pos,"normal":Vector2(0,1) if across_x else Vector2(1,0),"texture_path":path})
			continue
		if kind not in ["exit","stairs_up","stairs_down","lift"]: continue
		var preferred: Array=[Vector2i.UP,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.DOWN] if kind=="stairs_down" else [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP]
		if kind=="lift": preferred=[Vector2i.RIGHT,Vector2i.DOWN,Vector2i.UP,Vector2i.LEFT]
		var placed:=false
		for direction in preferred:
			for distance in range(1,4):
				var cell: Vector2i=Vector2i(fixture.pos[0],fixture.pos[1])+direction*distance
				if cell.x<0 or cell.y<0 or cell.x>=state.width or cell.y>=state.height: break
				if state.tiles[cell.y*state.width+cell.x]!=1: continue
				var key:=_face_key([cell.x,cell.y],-direction)
				if _faces.has(key): break
				var art_kind: String=("lift_working" if fixture.active else "lift_dead") if kind=="lift" else kind
				_faces[key]={"id":fixture.id,"kind":kind,"texture_path":"res://assets/art/fixtures/architecture_f%d_%s_64.png"%[mini(state.floor,2),art_kind]}
				placed=true; break
			if placed: break

func _wall_path(cell: Array,normal: Vector2i) -> String:
	var key: String="%s/%d/%s"%[state.get("seed",""),state.floor,_face_key(cell,normal)]
	if not _face_choices.has(key):
		var value: int=Paint.mix_hash(key)
		var roll: int=value%24
		var suffix: String="plain_%d"%(value%3)
		if roll==0: suffix="sconce"
		elif roll==1: suffix="tapestry"
		elif roll==2: suffix="chains"
		elif roll==3: suffix="damp"
		elif roll==4: suffix="crack"
		elif roll==5: suffix="drain"
		elif roll==6: suffix="arch"
		_face_choices[key]=suffix
	var suffix: String=_face_choices[key]
	if suffix=="sconce":
		_has_sconce=true; suffix="sconce_%d"%(int(_presentation_ms/250)%2)
	return "res://assets/art/env/painted_f%d_%s.png"%[mini(state.floor,2),suffix]

func visible_cells() -> Array: return _visible_cells.duplicate(true)
func visible_landmarks() -> Array:
	var result: Array=[]
	for fixture in state.fixtures:
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
	for _i in range(12):
		if entry>=FAR or cell.x<0 or cell.y<0 or cell.x>=state.width or cell.y>=state.height: break
		var next: float=minf(tx,ty)
		if next>=FOCAL*0.5/(HEIGHT-HORIZON):
			var key: int=cell.y*state.width+cell.x
			_visible_set[key]=[cell.x,cell.y]
		var stop: bool=state.tiles[cell.y*state.width+cell.x]==1
		for fixture in state.fixtures:
			if fixture.type in ["gate","lock","web","cord"] and not fixture.open and fixture.pos==[cell.x,cell.y]: stop=true
		if stop: break
		if tx<ty: entry=tx; tx+=dx; cell.x+=sx
		else: entry=ty; ty+=dy; cell.y+=sy

var _visible_set: Dictionary={}

func _build_camera() -> void:
	if state.is_empty(): return
	var forward:=Vector2(Sim.DIRS[state.facing][0],Sim.DIRS[state.facing][1])
	var right:=Vector2(-forward.y,forward.x)
	var origin:=Vector2(state.pos[0]+0.5,state.pos[1]+0.5)
	var key: String="%s/%s/%s"%[state.floor,state.pos,state.facing]
	if key!=_surface_key:
		_surface_key=key
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
		for fixture in state.fixtures:
			if fixture.type=="lock" and not fixture.open and fixture.pos==[cell.x,cell.y]:
				path="res://assets/art/env/painted_f%d_door.png"%mini(state.floor,2); face={"id":fixture.id}
		_walls.append({"depth":depth,"height":maxi(1,roundi(FOCAL/depth)),"u":clampi(int(u*64),0,63),"light":lamp(depth)*(0.78 if side else 1.0),"path":path,"cell":[cell.x,cell.y],"id":face.get("id",""),"panel_state":face.get("panel_state","")})
		if face.has("id"):
			var h: float=FOCAL/depth
			_project_column(face.id,column,HORIZON-h/2,h,depth)
	_visible_cells=_visible_set.values()
	for portal in _portals:
		var columns: Dictionary={}
		var center:=Vector2(portal.pos[0]+0.5,portal.pos[1]+0.5)
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
	for fixture in state.fixtures:
		if fixture.type not in ["gate","lock","stairs_up","stairs_down","exit","lift","web","cord","panel"]:
			var sprite: Dictionary=fixture.duplicate(true)
			sprite.kind="lift_on" if fixture.type=="lift" and fixture.get("active",false) else fixture.type
			sprites.append(sprite)
	for actor in state.actors:
		if actor.hp>0: sprites.append(actor.duplicate(true))
	for sprite in sprites:
		var relative:=Vector2(sprite.pos[0]+0.5,sprite.pos[1]+0.5)-origin
		var depth: float=relative.dot(forward)
		var lateral: float=relative.dot(right)
		var wall_normal:=Vector2.ZERO
		var hinge:=Vector2.ZERO
		if sprite.kind=="latch":
			# Choose a fixed physical wall, independently of camera direction.
			for offset in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				var neighbor:=Vector2i(sprite.pos[0]+int(offset.x),sprite.pos[1]+int(offset.y))
				if state.tiles[neighbor.y*state.width+neighbor.x]==1:
					wall_normal=offset; break
			if wall_normal==Vector2.ZERO: continue
			hinge=Vector2(sprite.pos[0]+0.5,sprite.pos[1]+0.5)+wall_normal*0.485
			relative=hinge-origin; depth=relative.dot(forward); lateral=relative.dot(right)
		# A possession at someone's feet must remain visible beside the body.
		# This is sprite placement only; pickup still targets the same sim cell.
		if not sprite.has("type") and not sprite.has("hp"):
			for fixture in state.fixtures:
				if fixture.pos==sprite.pos and fixture.type=="panel": lateral-=0.3; break
				if fixture.pos==sprite.pos and fixture.type in ["porter","lift"]:
					lateral+=0.3; break
		# Own-cell contents are shown at the bottom edge, where hands can reach.
		var underfoot: bool=sprite.pos==state.pos and sprite.kind!="latch"
		if underfoot and sprite.kind=="exit": continue # The entrance is behind us.
		if underfoot: depth=0.72; lateral=0.0
		if depth<(0.3 if sprite.kind=="latch" else 0.5) or depth>=FAR: continue
		var texture: Texture2D
		var tall: int
		var kind: String=sprite.kind
		var variant: int=0 if depth<1.5 else (1 if depth<2.5 else 2)
		if kind=="husk":
			var pose: String="recoil" if sprite.get("state","")=="recovery" else str(sprite.get("state","idle"))
			texture=_poses.get(pose,_poses.idle)[variant]; tall=[64,40,24][variant]
		elif kind in ["hound","ghost"]:
			var pose: String="recoil" if sprite.state=="recovery" else ("windup" if sprite.state=="windup" else "idle")
			texture=_creature_poses[kind][pose][variant]; tall=[64,40,24][variant]
		elif kind in ["brazier","torch","seal"]:
			texture=_painted_fixture(sprite,variant); tall=texture.get_height(); _has_flame=true
		elif kind=="porter" and _porters.size()==3:
			texture=_restored[variant] if sprite.get("restored",false) else _porters[variant]; tall=[64,40,24][variant]
		elif kind=="plate":
			texture=_fixture_textures["plate_%s_d%d"%["down" if _pressed(sprite) else "up",variant+1]]
			tall=texture.get_height()
		elif kind=="latch":
			texture=_fixture_textures["lever_%s_%s_d%d"%["left" if lateral<0 else "right","down" if _latch_down(sprite) else "up",variant+1]]
			tall=texture.get_height()
		else:
			texture=Art.inventory(kind) if not sprite.has("type") else Art.texture(kind)
			tall=maxi(22,roundi((48.0 if kind=="porter" else 32.0)/depth))
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
			var anchor: Vector2=[Vector2(16,22),Vector2(10,14),Vector2(6,8)][variant]
			if lateral>=0: anchor.x-=1
			rect.position=Vector2(roundi(WIDTH*0.5+lateral*FOCAL/depth),HORIZON-roundi(6.0/depth))-anchor
		var visible:=false
		for x in range(maxi(0,int(rect.position.x)),mini(WIDTH,int(rect.end.x))):
			if depth<_depths[x]: visible=true; break
		if not visible or rect.end.y<=0 or rect.position.y>=HEIGHT: continue
		sprite.merge({"depth":depth,"rect":rect,"texture":texture,"light":maxf(0.18,lamp(depth)),"underfoot":underfoot,"variant":variant,"wall_normal":wall_normal,"hinge":hinge,"origin":origin,"forward":forward,"right":right},true)
		_sprites.append(sprite)
		var texture_key: int=texture.get_instance_id()
		if not _opaque_bounds.has(texture_key): _opaque_bounds[texture_key]=texture.get_image().get_used_rect()
		var opaque: Rect2=Rect2(_opaque_bounds[texture_key])
		var ratio:=rect.size/Vector2(texture.get_width(),texture.get_height())
		var clipped:=Rect2(rect.position+opaque.position*ratio,opaque.size*ratio).intersection(Rect2(0,0,WIDTH,HEIGHT))
		if not clipped.has_area(): continue
		_projections[sprite.id]={"rect":clipped,"anchor":clipped.get_center(),"depth":depth}
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
	if sprite.kind=="hound": tint=Color(maxf(light,0.48),maxf(light,0.48),maxf(light,0.48))
	if sprite.kind=="ghost" and not _dispel.is_empty() and _dispel.sprite.id==sprite.id: tint.a=clampf(1.0-_dispel.age/0.18,0,1)
	if hit and not _strike.get("flash_drawn",false): tint=Color(2.5,2.5,2.5)
	var start: int=maxi(0,int(rect.position.x)) if only_column<0 else only_column
	var end: int=mini(WIDTH,int(rect.end.x)) if only_column<0 else only_column+1
	for x in range(start,end):
		if not _sprite_visible(sprite,x): continue
		if sprite.kind not in ["plate","latch"]:
			var norm: float=(x-rect.get_center().x)/maxf(1.0,rect.size.x*0.5)
			draw_rect(Rect2(x,mini(HEIGHT-3,rect.end.y-3),1,maxi(1,roundi(3*(1-norm*norm)))),Color("080b11"))
		var source_x:=floorf((x-rect.position.x)*texture.get_width()/rect.size.x)
		draw_texture_rect_region(texture,Rect2(x,rect.position.y,1,rect.size.y),Rect2(source_x,0,1,texture.get_height()),tint)

func _build_surfaces(origin: Vector2,forward: Vector2,right: Vector2) -> void:
	var image:=Image.create(WIDTH,HEIGHT,false,Image.FORMAT_RGBA8)
	image.fill(Color("050609"))
	var floor_image: Image=Paint.image("res://assets/art/env/f%d_floor.png"%mini(state.floor,2))
	var ceiling_image: Image=Paint.image("res://assets/art/env/f%d_ceiling.png"%mini(state.floor,2))
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
			var colour: Color=floor_image.get_pixel(u,v) if floor_side else ceiling_image.get_pixel(u,v)
			# The supplied surface establishes mortar and ribs. Sparse wear in
			# world coordinates keeps its broad stone fills from becoming flat
			# polygons, while leaving those painted seams intact.
			if u>4 and v>4:
				var grain: int=posmod((floori(point.x*64)*73856093)^(floori(point.y*64)*19349663),61)
				if grain<3: colour=colour.lightened(0.10)
				elif grain<6: colour=colour.darkened(0.18)
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
		if path.contains("sconce_"): path=path.left(path.rfind("sconce_"))+"sconce_%d.png"%(int(_presentation_ms/250)%2)
		draw_texture_rect_region(Paint.strips(path)[wall.u],Rect2(column,top,1,bottom-top),Rect2(0,(top-top_wall)*64.0/wall.height,1,(bottom-top)*64.0/wall.height),Color(light,light,light))
		if wall.panel_state!="":
			var marks: String="res://assets/art/fixtures/panel_sigil_%s_64.png"%("plain" if wall.panel_state=="plain" else "revealed")
			draw_texture_rect_region(Paint.strips(marks)[wall.u],Rect2(column,top,1,bottom-top),Rect2(0,(top-top_wall)*64.0/wall.height,1,(bottom-top)*64.0/wall.height),Color.WHITE if wall.panel_state!="plain" else Color(light,light,light))
			if wall.panel_state=="open" and wall.u>=14 and wall.u<=50:
				var y0: float=maxf(0,top_wall+wall.height*22.0/64)
				var y1: float=minf(HEIGHT,top_wall+wall.height*51.0/64)
				if y1>y0: draw_rect(Rect2(column,y0,1,y1-y0),Color("080b11") if wall.u>14 and wall.u<50 else Color("80643c"))
		for layer in _column_layers[column]:
			if layer.has("sprite"):
				_draw_sprite(layer.sprite,shift,false,column)
			else:
				var p: Dictionary=layer.column
				var py: float=HORIZON+shift-p.height/2
				var from_y: float=maxf(0,py); var to_y: float=minf(HEIGHT,py+p.height)
				var gain: float=lamp(p.depth)
				var strips: Array=layer.portal.strips
				if _burning.has(layer.portal.id): strips=Paint.strips("res://assets/art/fixtures/web_burning_%d_d1.png"%mini(1,int(float(_burning[layer.portal.id])/0.12)))
				if to_y>from_y: draw_texture_rect_region(strips[p.u],Rect2(column,from_y,1,to_y-from_y),Rect2(0,(from_y-py)*64.0/p.height,1,(to_y-from_y)*64.0/p.height),Color(gain,gain,gain))
	if not _dispel.is_empty(): _draw_sprite(_dispel.sprite,shift,true)
	if not _strike.is_empty():
		if _strike.has("ghost") and not _sprites.any(func(s): return s.id==_strike.id): _draw_sprite(_strike.ghost,shift,true)
		var frame: int=clampi(int(_strike.age/0.08),0,2)
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
		var local_ms: int=(int(_presentation_ms)+_glint_phases[signature])%2200
		var sparkle_frame: int=0 if local_ms<70 else (1 if local_ms<170 else (2 if local_ms<260 else -1))
		if sparkle_frame>=0:
			var pixels: int=9 if rect.size.y>=32 else 7
			var point:=Vector2(clampf(rect.end.x-3,5,WIDTH-6),clampf(rect.position.y+rect.size.y*0.35,5,HEIGHT-6)).round()
			# Gold frames modulate to the exact item's accent on selected targets.
			var tint:=Color(colour.r/0.45,colour.g/0.64,colour.b/0.60) if cue.selected else Color.WHITE
			draw_texture(_sparkles["%s_%d"%["target" if cue.selected else "gold",pixels]][sparkle_frame],point-Vector2.ONE*(pixels/2),tint)
		if cue.selected:
			for corner in [rect.position,rect.end-Vector2.ONE]:
				var inward: Vector2=(rect.get_center()-corner).sign()
				draw_line(corner,corner+Vector2(inward.x*3,0),colour,1)
				draw_line(corner,corner+Vector2(0,inward.y*3),colour,1)
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
		if _burning[id]>=0.24: _burning.erase(id)
		queue_redraw()
	if not _dispel.is_empty():
		_dispel.age+=delta
		if _dispel.age>=0.18: _dispel={}
		queue_redraw()
	var previous: int=int(_presentation_ms/40)
	var previous_flame: int=int(_presentation_ms/250)
	var previous_fixture: int=int(_presentation_ms/180)
	_presentation_ms=fmod(_presentation_ms+delta*1000.0,22000000.0)
	if (not interaction_cues.is_empty() and int(_presentation_ms/40)!=previous) or (_has_sconce and int(_presentation_ms/250)!=previous_flame) or (_has_flame and int(_presentation_ms/180)!=previous_fixture): queue_redraw()
	if not _strike.is_empty():
		_strike.age+=delta
		if _strike.age>=0.24: _strike={}
		queue_redraw()
	var before:=int(_pulse*8)
	_pulse=fmod(_pulse+delta,TAU)
	if not interaction_cues.is_empty() and int(_pulse*8)!=before: queue_redraw()
