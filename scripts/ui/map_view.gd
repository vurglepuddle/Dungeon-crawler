extends Control
var data: Dictionary={}
var cell_size: int=8
var map_origin:=Vector2.ZERO
var seen_bounds:=Rect2i()

func layout_seen() -> void:
	var lo:=Vector2i(data.width,data.height)
	var hi:=Vector2i(-1,-1)
	for y in range(data.height):
		for x in range(data.width):
			if data.visited[y*data.width+x]: lo=lo.min(Vector2i(x,y)); hi=hi.max(Vector2i(x,y))
	if hi.x<0: return
	seen_bounds=Rect2i(lo,hi-lo+Vector2i.ONE)
	cell_size=clampi(floori(minf((size.x-4)/seen_bounds.size.x,(size.y-8)/seen_bounds.size.y)),4,48)
	map_origin=(size-Vector2(seen_bounds.size)*cell_size)/2-Vector2(lo)*cell_size

func _center(cell: Array) -> Vector2:
	return map_origin+(Vector2(cell[0],cell[1])+Vector2(0.5,0.5))*cell_size
func _seen(cell: Array) -> bool: return data.visited[cell[1]*data.width+cell[0]]
func _draw() -> void:
	if data.is_empty(): return
	layout_seen()
	for y in range(data.height):
		for x in range(data.width):
			if not _seen([x,y]): continue
			draw_rect(Rect2(map_origin+Vector2(x,y)*cell_size,Vector2(cell_size-1,cell_size-1)),Color("777970"))
	for fixture in data.fixtures:
		if not _seen(fixture.pos): continue
		var c:=_center(fixture.pos)
		var r:=maxf(2,cell_size*0.36)
		match fixture.type:
			"gate","lock":
				draw_line(c+Vector2(-r,-r),c+Vector2(r,r),Color("eeb95a"),2)
				if not fixture.open: draw_line(c+Vector2(-r,r),c+Vector2(r,-r),Color("eeb95a"),2)
			"stairs_up","stairs_down","exit":
				var d:=1 if fixture.type=="stairs_down" else -1
				draw_line(c+Vector2(0,-r),c+Vector2(0,r),Color("efe3ba"),2)
				draw_polyline(PackedVector2Array([c+Vector2(-r,0),c+Vector2(0,d*r),c+Vector2(r,0)]),Color("efe3ba"),2)
			"lift": draw_rect(Rect2(c-Vector2(r,r),Vector2(r*2,r*2)),Color("4c8585"),not fixture.active,2 if fixture.active else -1)
			"porter": draw_circle(c,r,Color("bc7433"))
			"plate": draw_rect(Rect2(c-Vector2(r,2),Vector2(r*2,4)),Color("a18750"))
	var site: Array=data.get("seal_site",[])
	if not site.is_empty() and _seen(site):
		var c:=_center(site)
		var r:=maxf(3,cell_size*0.4)
		draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r,0),c+Vector2(0,r),c+Vector2(-r,0)]),Color("eeb95a"))
	var center:=_center(data.pos)
	var direction:=Vector2([0,1,0,-1][data.facing],[-1,0,1,0][data.facing])
	var side:=Vector2(-direction.y,direction.x)
	var radius:=maxf(6,cell_size*0.55)
	draw_circle(center,radius+1,Color("0c101c"))
	draw_colored_polygon(PackedVector2Array([center+direction*radius,center-direction*radius*0.65+side*radius*0.65,center-direction*radius*0.65-side*radius*0.65]),Color("efe3ba"))
