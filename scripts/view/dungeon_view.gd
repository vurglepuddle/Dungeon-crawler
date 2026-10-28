extends Control
## Cached floor casting and grid walls share one camera with sprites/hotspots.
const Sim=preload("res://scripts/sim/dungeon_sim.gd")
const Art=preload("res://scripts/art/item_art.gd")
const Fixtures=preload("res://scripts/art/fixture_art.gd")
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
var _wall_strips: Array[Texture2D]=[]
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
const DAMAGE_FONT=preload("res://assets/font/vetka.ttf")

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var image: Image=load("res://assets/art/stone_wall.png").get_image()
	image.convert(Image.FORMAT_RGBA8)
	for x in range(64):
		var strip:=Image.create(1,64,false,Image.FORMAT_RGBA8)
		strip.blit_rect(image,Rect2i(x,0,1,64),Vector2i.ZERO)
		_wall_strips.append(ImageTexture.create_from_image(strip))
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

func clear_strike() -> void:
	_strike={}; queue_redraw()

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
	state=snapshot
	_build_camera()
	queue_redraw()

func projection(id: String) -> Dictionary:
	return _projections.get(id,{}).duplicate()

func _solid(cell: Vector2i) -> bool:
	if cell.x<0 or cell.y<0 or cell.x>=state.width or cell.y>=state.height: return true
	if state.tiles[cell.y*state.width+cell.x]==1: return true
	for fixture in state.fixtures:
		if fixture.type in ["gate","lock"] and not fixture.open and fixture.pos==[cell.x,cell.y]: return true
	return false

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
	for column in range(WIDTH):
		var ray:=forward+right*((column+0.5-WIDTH*0.5)/FOCAL)
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
		var gate_kind: String=""
		for fixture in state.fixtures:
			if fixture.type in ["gate","lock"] and not fixture.open and fixture.pos==[cell.x,cell.y]: gate_kind=fixture.type
		_walls.append({"depth":depth,"height":maxi(1,roundi(FOCAL/depth)),"u":clampi(int(u*64),0,63),"light":lamp(depth)*(0.78 if side else 1.0),"gate":gate_kind,"cell":[cell.x,cell.y]})
	# Closed gates are rendered as walls, but still have an object projection.
	for fixture in state.fixtures:
		if fixture.type not in ["gate","lock"] or fixture.open: continue
		var first: int=WIDTH
		var last: int=-1
		var height: int=0
		for x in range(_walls.size()):
			if _walls[x].cell==fixture.pos:
				first=mini(first,x); last=maxi(last,x); height=maxi(height,_walls[x].height)
		if last>=first:
			var rect:=Rect2(first,HORIZON-height/2,last-first+1,height).intersection(Rect2(0,0,WIDTH,HEIGHT))
			_projections[fixture.id]={"rect":rect,"anchor":rect.get_center(),"depth":1.0}
	var sprites: Array=state.objects.duplicate(true)
	for fixture in state.fixtures:
		if fixture.type not in ["gate","lock"]:
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
		elif kind=="porter" and _porters.size()==3:
			texture=_restored[variant] if sprite.get("restored",false) else _porters[variant]; tall=[64,40,24][variant]
		elif kind=="plate":
			texture=_fixture_textures["plate_%s_d%d"%["down" if _pressed(sprite) else "up",variant+1]]
			tall=texture.get_height()
		elif kind=="latch":
			texture=_fixture_textures["lever_%s_%s_d%d"%["left" if lateral<0 else "right","down" if _latch_down(sprite) else "up",variant+1]]
			tall=texture.get_height()
		elif kind in ["stairs_up","stairs_down","lift","lift_on"]:
			texture=Fixtures.texture("lift_floor" if underfoot and kind in ["lift","lift_on"] else kind); tall=maxi(24,roundi(58.0/depth))
		else:
			texture=Art.texture(kind); tall=maxi(22,roundi((48.0 if kind in ["exit","porter"] else 32.0)/depth))
		var wide:=maxi(1,roundi(tall*texture.get_width()/float(texture.get_height())))
		var ground:=HORIZON+roundi(FOCAL*0.5/depth)
		if underfoot:
			tall=44 if kind in ["stairs_up","stairs_down"] else tall
			wide=64 if kind in ["stairs_up","stairs_down"] else wide
			ground=HEIGHT+8 if kind in ["stairs_up","stairs_down"] else HEIGHT+4
			if kind in ["lift","lift_on"]: tall=44; wide=64; ground=HEIGHT+2
			if kind=="exit": wide=26
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

func _sprite_visible(sprite: Dictionary,x: int) -> bool:
	var depth: float=sprite.depth
	if sprite.kind=="latch":
		var ray: Vector2=sprite.forward+sprite.right*((x+0.5-WIDTH*0.5)/FOCAL)
		var divisor: float=ray.dot(sprite.wall_normal)
		if absf(divisor)<0.00001: return false
		depth=(sprite.hinge-sprite.origin).dot(sprite.wall_normal)/divisor
	return depth>0 and depth<_depths[x]+0.02

func _draw_sprite(sprite: Dictionary,shift: int,force_recoil: bool=false) -> void:
	var rect: Rect2=sprite.rect; rect.position.y+=shift
	var texture: Texture2D=sprite.texture
	var hit: bool=not _strike.is_empty() and sprite.id==_strike.id
	if sprite.kind=="husk" and (hit or force_recoil): texture=_poses.recoil[sprite.variant]
	var light: float=sprite.light
	var tint:=Color(light,light,light)
	if hit and not _strike.get("flash_drawn",false): tint=Color(2.5,2.5,2.5)
	for x in range(maxi(0,int(rect.position.x)),mini(WIDTH,int(rect.end.x))):
		if not _sprite_visible(sprite,x): continue
		if sprite.kind not in ["plate","latch"]:
			var norm: float=(x-rect.get_center().x)/maxf(1.0,rect.size.x*0.5)
			draw_rect(Rect2(x,mini(HEIGHT-3,rect.end.y-3),1,maxi(1,roundi(3*(1-norm*norm)))),Color("080b11"))
		var source_x:=floorf((x-rect.position.x)*texture.get_width()/rect.size.x)
		draw_texture_rect_region(texture,Rect2(x,rect.position.y,1,rect.size.y),Rect2(source_x,0,1,texture.get_height()),tint)

func _build_surfaces(origin: Vector2,forward: Vector2,right: Vector2) -> void:
	var image:=Image.create(WIDTH,HEIGHT,false,Image.FORMAT_RGBA8)
	image.fill(Color("050609"))
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
			var hash_value: int=absi(cell.x*331+cell.y*719+u*17+v*43)
			var colour: Color
			if floor_side:
				colour=Color("59616a") if posmod(cell.x+cell.y,2)==0 else Color("51545a")
				if u<2 or v<2: colour=Color("171d2b")
				elif u==3 or v==3: colour=Color("777970")
				elif hash_value%41<3: colour=Color("777970")
				elif hash_value%31<2: colour=Color("3b4757")
				# Short cracks, not a noisy full-screen checker.
				if u>30 and u<45 and v==20+(u-30)/3 and posmod(cell.x*3+cell.y,4)==0: colour=Color("263044")
			else:
				colour=Color("51545a") if hash_value%29<2 else Color("3b4757")
				if u<5 or v<5: colour=Color("777970") if u==2 or v==2 else Color("263044")
				if u>27 and u<36: colour=Color("59616a")
			image.set_pixel(x,y,Color(colour.r*light,colour.g*light,colour.b*light,1))
	_surfaces=ImageTexture.create_from_image(image)

func _draw() -> void:
	draw_rect(Rect2(0,0,WIDTH,HEIGHT),Color("050609"))
	if state.is_empty() or _wall_strips.is_empty(): return
	var shift:=roundi(motion)
	if _surfaces!=null: draw_texture(_surfaces,Vector2(0,shift))
	for column in range(_walls.size()):
		var wall: Dictionary=_walls[column]
		var top_wall: int=HORIZON+shift-wall.height/2
		var top:=maxi(0,top_wall)
		var bottom:=mini(HEIGHT,top_wall+wall.height)
		var light: float=wall.light
		if bottom<=top: continue
		if wall.gate!="":
			var colour:=Color("80643c") if wall.u%12<4 or wall.u<3 or wall.u>60 else Color("080b11")
			draw_rect(Rect2(column,top,1,bottom-top),colour*Color(light,light,light))
			for cross in [top_wall+wall.height/5,top_wall+wall.height*4/5]:
				if cross>=0 and cross<HEIGHT: draw_rect(Rect2(column,cross,1,maxi(1,wall.height/20)),Color("a18750")*Color(light,light,light))
		else:
			draw_texture_rect_region(_wall_strips[wall.u],Rect2(column,top,1,bottom-top),Rect2(0,(top-top_wall)*64.0/wall.height,1,(bottom-top)*64.0/wall.height),Color(light*(0.8 if state.floor>1 else 0.95),light,light))
	for sprite in _sprites:
		_draw_sprite(sprite,shift)
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
		colour.a=(0.7+sin(_pulse*2.0)*0.25) if cue.selected else (0.55+sin(_pulse*2.0)*0.2)
		if cue.selected:
			for corner in [rect.position,rect.end-Vector2.ONE]:
				var inward: Vector2=(rect.get_center()-corner).sign()
				draw_line(corner,corner+Vector2(inward.x*3,0),colour,1)
				draw_line(corner,corner+Vector2(0,inward.y*3),colour,1)
		else:
			var glint:=Vector2(clampf(rect.end.x-1,2,WIDTH-3),clampf(rect.end.y-3,2,HEIGHT-3)).round()
			draw_line(glint-Vector2(2,0),glint+Vector2(2,0),colour,1)
			draw_line(glint-Vector2(0,2),glint+Vector2(0,2),colour,1)
	if flash>0: draw_rect(Rect2(1,1,WIDTH-2,HEIGHT-2),Color(0.9,0.15,0.1,flash),false,2)

func _process(delta: float) -> void:
	if not _strike.is_empty():
		_strike.age+=delta
		if _strike.age>=0.24: _strike={}
		queue_redraw()
	var before:=int(_pulse*8)
	_pulse=fmod(_pulse+delta,TAU)
	if not interaction_cues.is_empty() and int(_pulse*8)!=before: queue_redraw()
