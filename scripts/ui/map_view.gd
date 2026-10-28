extends Control
var data: Dictionary={}
func _draw() -> void:
	if data.is_empty(): return
	var scale:=7
	var origin:=Vector2(4,32)
	for y in range(data.height):
		for x in range(data.width):
			var index: int=y*data.width+x
			if not data.visited[index]: continue
			draw_rect(Rect2(origin+Vector2(x,y)*scale,Vector2(scale-1,scale-1)),Color("777970"))
			for fixture in data.fixtures:
				if fixture.pos==[x,y]:
					draw_rect(Rect2(origin+Vector2(x,y)*scale+Vector2(1,1),Vector2(4,4)),Color("eeb95a") if fixture.type in ["gate","lock"] else Color("4c8585"))
	var center:=origin+(Vector2(data.pos[0],data.pos[1])+Vector2(0.5,0.5))*scale
	var direction:=Vector2([0,1,0,-1][data.facing],[-1,0,1,0][data.facing])
	var side:=Vector2(-direction.y,direction.x)
	draw_circle(center,6,Color("0c101c"))
	draw_colored_polygon(PackedVector2Array([center+direction*6,center-direction*4+side*4,center-direction*4-side*4]),Color("efe3ba"))
