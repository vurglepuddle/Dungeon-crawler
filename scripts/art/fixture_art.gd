extends RefCounted
## Large world sprites; inventory glyphs remain in item_art.gd.
static var _cache: Dictionary={}
static func texture(kind: String) -> Texture2D:
	if _cache.has(kind): return _cache[kind]
	var image:=Image.create(64,64,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(64):
		for x in range(64):
			var ink:=Color.TRANSPARENT
			match kind:
				"stairs_down":
					# Splayed stone rim around a real black well; treads descend into it.
					if y>=20 and y<=58 and x>=8-(y-20)/7 and x<=55+(y-20)/7:
						ink=Color("777970") if y<25 or x<12 or x>51 or y>54 else Color("080b11")
						if x>=15 and x<=48 and y>=27 and y<=51:
							var step: int=(y-27)/5
							ink=Color("3b4757").lerp(Color("999883"),step/6.0) if (y-27)%5==0 else Color("171d2b")
						if y==55 or x==9 or x==54: ink=Color("b6ae91")
				"stairs_up":
					if x>=9 and x<=54 and y>=3 and y<=59:
						ink=Color("171d2b")
						if x<13 or x>50 or y<7: ink=Color("777970")
						if y>=12 and x>=15 and x<=48:
							ink=Color("999883") if (y-12)%8<=1 else Color("3b4757")
							if y>44 and (y-12)%8<=1: ink=Color("d3c8a4")
				"plate":
					if y>=36 and y<=54 and x>=12-(y-36)/2 and x<=51+(y-36)/2:
						ink=Color("80643c") if y<51 else Color("3b4757")
						if y in [37,38,50] or x in [13,50]: ink=Color("b6ae91")
						if x>=28 and x<=35 and y>=41 and y<=46: ink=Color("59616a")
				"lift","lift_on":
					if x>=6 and x<=57 and y>=3 and y<=60:
						if x<=11 or x>=52: ink=Color("80643c") if x%4<2 else Color("b6ae91")
						elif y<9 or y>53: ink=Color("999883") if y%4==0 else Color("3b4757")
						else:
							ink=Color("080b11")
							if x in [19,20,43,44]: ink=Color("59616a")
							if y>43: ink=Color("80643c") if (x+y)%8<2 else Color("463f37")
							if kind=="lift_on" and y in [12,13] and x>=25 and x<=38: ink=Color("eeb95a")
			image.set_pixel(x,y,ink)
	var result:=ImageTexture.create_from_image(image)
	_cache[kind]=result
	return result
