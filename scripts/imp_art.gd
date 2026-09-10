extends RefCounted
const Basic := preload("res://scripts/zombie_art.gd")
const PARTS := {
	"far_thigh": preload("res://assets/zombies/imp/parts/far_thigh.svg"),
	"far_calf": preload("res://assets/zombies/imp/parts/far_calf.svg"),
	"far_shoe": preload("res://assets/zombies/imp/parts/far_shoe.svg"),
	"near_thigh": preload("res://assets/zombies/imp/parts/near_thigh.svg"),
	"near_calf": preload("res://assets/zombies/imp/parts/near_calf.svg"),
	"near_shoe": preload("res://assets/zombies/imp/parts/near_shoe.svg"),
	"far_upper_arm": preload("res://assets/zombies/imp/parts/far_upper_arm.svg"),
	"far_forearm": preload("res://assets/zombies/imp/parts/far_forearm.svg"),
	"torso": preload("res://assets/zombies/imp/parts/torso.svg"),
	"near_upper_arm": preload("res://assets/zombies/imp/parts/near_upper_arm.svg"),
	"near_forearm": preload("res://assets/zombies/imp/parts/near_forearm.svg"),
	"neck": preload("res://assets/zombies/imp/parts/neck.svg"),
	"head": preload("res://assets/zombies/imp/parts/head.svg"),
	"jaw": preload("res://assets/zombies/imp/parts/jaw.svg"),
	"stump": preload("res://assets/zombies/imp/parts/stump.svg"),
}
const ORDER := ["far_thigh","far_calf","far_shoe","near_thigh","near_calf","near_shoe","far_upper_arm","far_forearm","torso","near_upper_arm","near_forearm","neck","head","jaw"]
const ANATOMY := Transform2D(Vector2(1.08,0),Vector2(0,.64),Vector2(-10.56,52.2))

static func render(view: Node2D,z: Dictionary,base: Transform2D,parent: Transform2D,driver: bool) -> void:
	var m := Basic.pose(z)
	var tint := Color(.72,1.0,1.12) if float(z.get("slow",0.0))>0 else Color.WHITE
	for id in ORDER:
		if driver and id in ["far_thigh","far_calf","far_shoe","near_thigh","near_calf","near_shoe"]: continue
		var shape := Transform2D.IDENTITY if id in ["head","jaw","neck"] else ANATOMY
		view.draw_set_transform_matrix(parent * base * shape * m[id])
		view.draw_texture_rect(PARTS[id],Rect2(0,0,240,360),false,tint)
	view.draw_set_transform_matrix(parent)

static func draw(view: Node2D,z: Dictionary,pos: Vector2,size: float,parent: Transform2D = Transform2D.IDENTITY) -> void:
	var unit := .40*size
	var base := Transform2D(Vector2(unit,0),Vector2(0,unit),pos-Vector2(132,194)*unit)
	render(view,z,base,parent,false)

static func draw_driver(view: Node2D,z: Dictionary,pos: Vector2,size: float,parent: Transform2D = Transform2D.IDENTITY) -> void:
	var unit := .30*size
	var base := Transform2D(Vector2(unit,0),Vector2(0,unit),pos+Vector2(4,-39)*size-Vector2(102,91)*unit)
	var seated := z.duplicate()
	seated.walking = false
	seated.biting = false
	render(view,seated,base,parent,true)
