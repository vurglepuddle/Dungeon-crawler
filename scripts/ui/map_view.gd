extends Control
var data: Dictionary={}
var cell_size: int=8
var map_origin:=Vector2.ZERO
var seen_bounds:=Rect2i()
const INK=Color("4d2b1d")
const FAINT=Color("80643c")
func _known(cell: Array) -> bool:
	if cell[0]<0 or cell[1]<0 or cell[0]>=data.width or cell[1]>=data.height: return false
	return data.survey.seen[cell[1]*data.width+cell[0]]=="1" if data.has("survey") else cell==data.pos
func _walked(cell: Array) -> bool:
	return data.survey.walked[cell[1]*data.width+cell[0]]=="1" if data.has("survey") else cell==data.pos

func layout_seen() -> void:
	var lo:=Vector2i(data.width,data.height)
	var hi:=Vector2i(-1,-1)
	for y in range(data.height):
		for x in range(data.width):
			if _known([x,y]): lo=lo.min(Vector2i(x,y)); hi=hi.max(Vector2i(x,y))
	if hi.x<0: return
	seen_bounds=Rect2i(lo,hi-lo+Vector2i.ONE)
	cell_size=clampi(floori(minf((size.x-4)/seen_bounds.size.x,(size.y-8)/seen_bounds.size.y)),4,48)
	map_origin=(size-Vector2(seen_bounds.size)*cell_size)/2-Vector2(lo)*cell_size

func _center(cell: Array) -> Vector2:
	return map_origin+(Vector2(cell[0],cell[1])+Vector2(0.5,0.5))*cell_size
func _seen(cell: Array) -> bool: return _known(cell)
func _dashed(a: Vector2,b: Vector2,colour: Color=FAINT) -> void:
	var length: int=roundi(a.distance_to(b))
	var direction: Vector2=(b-a).normalized()
	for i in range(0,length,4): draw_line((a+direction*i).round(),(a+direction*mini(i+1,length)).round(),colour,1)
func frontier_cells() -> Array:
	var result: Array=[]
	for y in range(data.height):
		for x in range(data.width):
			if not _known([x,y]) or data.tiles[y*data.width+x]!=0: continue
			if data.fixtures.any(func(f): return f.pos==[x,y] and f.type in ["gate","lock"] and not f.open): continue
			for delta in [[0,-1],[1,0],[0,1],[-1,0]]:
				# No terrain lookup beyond the known edge. '?' means unsurveyed,
				# never proof that a hidden wall is a secret door or passage.
				var next: Array=[x+delta[0],y+delta[1]]
				if next[0]>=0 and next[1]>=0 and next[0]<data.width and next[1]<data.height and not _known(next):
					result.append([x,y]); break
	return result
func _draw() -> void:
	if data.is_empty(): return
	layout_seen()
	for y in range(data.height):
		for x in range(data.width):
			if not _seen([x,y]): continue
			var p: Vector2=(map_origin+Vector2(x,y)*cell_size).round()
			var rect:=Rect2(p,Vector2.ONE*(cell_size-1))
			if data.tiles[y*data.width+x]==1:
				# Surveyed masonry is stippled/hatching ink, never grey fill.
				for offset in range(1,cell_size-1,3): draw_line(p+Vector2(offset,cell_size-2),p+Vector2(mini(cell_size-2,offset+3),1),FAINT,1)
			elif _walked([x,y]):
				for pair in [[rect.position,Vector2(rect.end.x,rect.position.y)],[Vector2(rect.end.x,rect.position.y),rect.end],[rect.end,Vector2(rect.position.x,rect.end.y)],[Vector2(rect.position.x,rect.end.y),rect.position]]:
					draw_line(pair[0],pair[1],INK,1)
				draw_line(p+Vector2(2,cell_size-3),p+Vector2(mini(4,cell_size-2),cell_size-3),FAINT,1)
			else:
				_dashed(rect.position,Vector2(rect.end.x,rect.position.y)); _dashed(Vector2(rect.end.x,rect.position.y),rect.end)
				_dashed(rect.end,Vector2(rect.position.x,rect.end.y)); _dashed(Vector2(rect.position.x,rect.end.y),rect.position)
	for cell in frontier_cells():
		var p:=_center(cell).round()+Vector2(cell_size*0.2,-cell_size*0.15)
		# A small ink glyph fits even the eight-pixel cartographic pitch.
		draw_polyline(PackedVector2Array([p+Vector2(-1,-2),p+Vector2(1,-2),p+Vector2(1,0),p,p+Vector2(0,1)]),FAINT,1)
		draw_rect(Rect2(p+Vector2(0,3),Vector2.ONE),INK)
	for fixture in data.fixtures:
		if not _seen(fixture.pos) or not data.get("survey",{}).get("landmarks",[]).has(fixture.id): continue
		var c:=_center(fixture.pos)
		var r:=maxf(2,cell_size*0.36)
		match fixture.type:
			"gate","lock":
				draw_line(c+Vector2(-r,-r),c+Vector2(r,r),INK,1)
				if not fixture.open: draw_line(c+Vector2(-r,r),c+Vector2(r,-r),INK,1)
			"stairs_up","stairs_down","exit":
				var d:=1 if fixture.type=="stairs_down" else -1
				draw_line(c+Vector2(0,-r),c+Vector2(0,r),INK,1)
				draw_polyline(PackedVector2Array([c+Vector2(-r,0),c+Vector2(0,d*r),c+Vector2(r,0)]),INK,1)
				for row in [-2,0,2]: draw_line(c+Vector2(-r,row),c+Vector2(0,row),INK,1)
			"lift":
				draw_rect(Rect2(c-Vector2(r,r),Vector2(r*2,r*2)),INK,false,1)
				if fixture.active: draw_line(c+Vector2(-r,r),c+Vector2(r,-r),INK,1)
			"porter": draw_arc(c,r,PI,TAU,8,INK,1); draw_line(c+Vector2(-r,0),c+Vector2(r,0),INK,1)
			"plate": draw_rect(Rect2(c-Vector2(r,1),Vector2(r*2,2)),FAINT,false,1)
	var site: Array=data.get("seal_site",[])
	if not site.is_empty() and _seen(site):
		var c:=_center(site)
		var r:=maxf(3,cell_size*0.4)
		draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r,0),c+Vector2(0,r),c+Vector2(-r,0)]),INK)
	var center:=_center(data.pos)
	var direction:=Vector2([0,1,0,-1][data.facing],[-1,0,1,0][data.facing])
	var side:=Vector2(-direction.y,direction.x)
	var radius:=maxf(6,cell_size*0.55)
	draw_circle(center,radius+1,Color("d3c8a4"))
	draw_colored_polygon(PackedVector2Array([center+direction*radius,center-direction*radius*0.65+side*radius*0.65,center-direction*radius*0.65-side*radius*0.65]),Color("0f282d"))
