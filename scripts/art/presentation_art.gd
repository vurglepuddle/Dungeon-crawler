extends RefCounted
## Read-only art cache; imports in exports, raw PNG fallback during integration.
static var _textures: Dictionary={}
static var _strips: Dictionary={}
static var _images: Dictionary={}
static func texture(path: String) -> Texture2D:
	if _textures.has(path): return _textures[path]
	var result: Texture2D
	if FileAccess.file_exists(path+".import") and ResourceLoader.exists(path): result=load(path)
	else:
		var image:=Image.load_from_file(path)
		if image!=null and not image.is_empty(): result=ImageTexture.create_from_image(image)
	if result==null: push_error("Required painted asset failed to load: "+path)
	_textures[path]=result
	return result
static func image(path: String) -> Image:
	if not _images.has(path): _images[path]=texture(path).get_image()
	return _images[path]
static func strips(path: String) -> Array:
	if not _strips.has(path):
		var source: Texture2D=texture(path)
		var columns: Array=[]
		for x in range(64):
			var strip:=AtlasTexture.new(); strip.atlas=source; strip.region=Rect2(x,0,1,64)
			columns.append(strip)
		_strips[path]=columns
	return _strips[path]
static func mix_hash(value: String) -> int:
	var result: int=2166136261
	for code in value.to_utf8_buffer(): result=((result^code)*16777619)&0xffffffff
	result=((result^(result>>16))*0x45d9f3b)&0xffffffff
	result=((result^(result>>16))*0x45d9f3b)&0xffffffff
	return (result^(result>>16))&0x7fffffff
