extends RefCounted

const ARMOR := {
	"cone":preload("res://assets/zombies/equipment/cone.svg"),
	"bucket":preload("res://assets/zombies/equipment/bucket.svg"),
	"charger":preload("res://assets/zombies/equipment/charger.svg"),
	"copper":preload("res://assets/zombies/equipment/copper.svg")
}
const KART_BODY := preload("res://assets/zombies/equipment/kart_body.svg")
const KART_BACK := preload("res://assets/zombies/equipment/kart_back.svg")
const WHEEL := preload("res://assets/zombies/equipment/kart_wheel.svg")

static func armor(v, kind: String, pos: Vector2, size: float, angle := 0.0, dropped := false) -> void:
	var parent: Transform2D = v.art_parent_transform
	var center := Vector2(0,-36 if kind in ["cone","bucket"] else -8) if dropped else Vector2.ZERO
	v.draw_set_transform_matrix(parent*Transform2D(angle,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO)*Transform2D(0,-center))
	v.draw_texture_rect(ARMOR[kind],Rect2(-48,-68,96,112),false)
	v.draw_set_transform_matrix(parent)

static func kart(v, pos: Vector2, size: float, wheel_angle: float, back: bool) -> void:
	var parent: Transform2D = v.art_parent_transform
	var local := parent*Transform2D(0,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO)
	v.draw_set_transform_matrix(local)
	if back:
		v.draw_texture_rect(KART_BACK,Rect2(-64,-45,128,90),false)
	else:
		for x in [-31.0,35.0]:
			v.draw_set_transform_matrix(local*Transform2D(wheel_angle,Vector2(x,31)))
			v.draw_texture_rect(WHEEL,Rect2(-16,-16,32,32),false)
		v.draw_set_transform_matrix(local)
		v.draw_texture_rect(KART_BODY,Rect2(-64,-45,128,90),false)
	v.draw_set_transform_matrix(parent)
