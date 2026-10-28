class_name UndercroftItemArt
extends RefCounted
static var _cache: Dictionary={}
static func texture(kind: String) -> Texture2D:
	if _cache.has(kind): return _cache[kind]
	var image:=Image.create(16,24,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(24):
		for x in range(16):
			var ink:=Color.TRANSPARENT
			match kind:
				"stone":
					if absf(x-7.5)/7+absf(y-16.0)/5<1.15: ink=Color("b6ae91") if x+y<23 else Color("59616a")
				"knife","shard":
					if y>=5 and y<=19 and abs(x-(18-y)/2)<2: ink=Color("d3c8a4") if x<8 else Color("59616a")
					if kind=="knife" and y in [17,18] and x<9: ink=Color("a18750")
				"clapper":
					if x>=6 and x<=9 and y>=4 and y<=16: ink=Color("a18750") if x<8 else Color("80643c")
					if (x-8)*(x-8)+(y-17)*(y-17)<=20: ink=Color("eeb95a") if x+y<25 else Color("80643c")
				"club":
					if x>=5 and x<=10 and y>=5 and y<=20: ink=Color("999883") if x<8 else Color("3b4757")
					if x>=4 and x<=11 and y>=4 and y<=9: ink=Color("b6ae91")
				"coat":
					if y>=6 and y<=19 and ((x>=4 and x<=11) or y<=11 and x>=1 and x<=14): ink=Color("4c8585") if x<8 else Color("22545a")
					if x in [7,8] and y>=7 and y<=19: ink=Color("a18750")
				"tonic":
					if x>=4 and x<=11 and y>=10 and y<=20: ink=Color("965c48") if x>5 else Color("d3c8a4")
					if x>=6 and x<=9 and y>=6 and y<=10: ink=Color("a18750")
				"bread":
					if absf(x-7.5)/7+absf(y-16)/5<1.3: ink=Color("bc7433") if y>14 else Color("eeb95a")
					if y in [13,14] and x in [5,9]: ink=Color("80643c")
				"bone":
					if (x in [7,8] and y>=8 and y<=19) or y in [7,8,19,20] and x>=5 and x<=10: ink=Color("d3c8a4")
				"key":
					if ((x-7)*(x-7)+(y-8)*(y-8)<=12 and (x-7)*(x-7)+(y-8)*(y-8)>=4) or x in [7,8] and y>=10 and y<=20 or y in [17,20] and x>=7 and x<=11: ink=Color("eeb95a")
				"seal":
					if abs(x-8)+abs(y-12)<=7: ink=Color("efe3ba") if abs(x-8)+abs(y-12)>4 else Color("4c8585")
				"lamp":
					if x>=4 and x<=11 and y>=9 and y<=20: ink=Color("eeb95a") if x in [4,11] or y in [9,20] else Color("d3c8a4")
				"plate":
					if y>=17 and y<=21 and x>=(21-y)/2 and x<=15-(21-y)/2: ink=Color("a18750") if y<19 else Color("59616a")
				"latch":
					if x>=6 and x<=9 and y>=8 and y<=22 or y in [7,8] and x>=7 and x<=13: ink=Color("a18750")
				"stairs_up","stairs_down":
					var step:=y/4
					if y>=4 and x>=step and x<16-step: ink=Color("999883") if y%4==0 else Color("3b4757")
					if x==8 and y>=3 and y<=13: ink=Color("efe3ba")
					if kind=="stairs_up" and y>=3 and y<=6 and absi(x-8)<=y-3: ink=Color("efe3ba")
					if kind=="stairs_down" and y>=11 and y<=14 and absi(x-8)<=14-y: ink=Color("efe3ba")
				"exit":
					if x>=2 and x<=13 and y>=2: ink=Color("a8c2ad") if x in [2,13] or y==2 else Color("22545a")
			image.set_pixel(x,y,ink)
	var result:=ImageTexture.create_from_image(image)
	_cache[kind]=result
	return result

static func inventory(kind: String) -> Texture2D:
	var key:=kind+"_inventory"
	if _cache.has(key): return _cache[key]
	var image:=texture(kind).get_image().get_region(Rect2i(0,5,16,16))
	var result:=ImageTexture.create_from_image(image)
	_cache[key]=result
	return result
