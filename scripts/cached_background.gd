extends RefCounted

static var textures: Dictionary = {}

static func warmup() -> void:
	if not textures.is_empty(): return
	for map in ["frontyard","wasteland","wildland"]:
		for extended in [false,true]:
			var key: String = map+("_extended" if extended else "")
			textures[key] = load("res://assets/backgrounds/"+key+".png")

static func get_texture(map: String, extended: bool) -> Texture2D:
	warmup()
	return textures[map+("_extended" if extended else "")]
