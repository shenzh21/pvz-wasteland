extends RefCounted
const PARTS := {
	"far_leg": preload("res://assets/zombies/camo/parts/far_leg.svg"),
	"far_boot": preload("res://assets/zombies/camo/parts/far_boot.svg"),
	"far_arm": preload("res://assets/zombies/camo/parts/far_arm.svg"),
	"torso": preload("res://assets/zombies/camo/parts/torso.svg"),
	"near_leg": preload("res://assets/zombies/camo/parts/near_leg.svg"),
	"near_boot": preload("res://assets/zombies/camo/parts/near_boot.svg"),
	"neck": preload("res://assets/zombies/camo/parts/neck.svg"),
	"near_upper_arm": preload("res://assets/zombies/camo/parts/near_upper_arm.svg"),
	"near_forearm": preload("res://assets/zombies/camo/parts/near_forearm.svg"),
	"head": preload("res://assets/zombies/camo/parts/head.svg"),
	"jaw": preload("res://assets/zombies/camo/parts/jaw.svg"),
	"cap": preload("res://assets/zombies/camo/parts/cap.svg"),
	"stump": preload("res://assets/zombies/camo/parts/stump.svg"),
}
const ORDER := ["far_leg","far_boot","far_arm","torso","near_leg","near_boot","neck","near_upper_arm","near_forearm","head","jaw","cap"]

static func around(p: Vector2,angle: float) -> Transform2D:
	return Transform2D(0.0,p)*Transform2D(angle,Vector2.ZERO)*Transform2D(0.0,-p)

static func pose(z: Dictionary) -> Dictionary:
	var t: float = z.get("anim",0.0)
	var biting: bool = z.get("biting",false)
	var crawling: bool = z.get("walking",true) and not z.get("rooted",false) and not biting
	var crawl := sin(t*3.0) if crawling else 0.0
	var breathe := sin(t*1.65*float(z.get("idle_rate",1.0)))
	var bite := (sin(t*11.0)+1.0)*.5 if biting else 0.0
	var body := Transform2D(0.0,Vector2(crawl*1.5,breathe*.65))
	var head := body * Transform2D(0.0,Vector2(-3*bite,crawl*.6)) * around(Vector2(102,112),breathe*.009)
	return {
		"torso":body,"neck":body,"head":head,"cap":head,
		"jaw":head*Transform2D(0.0,Vector2(0,bite*2.5))*around(Vector2(85,122),-bite*.08),
		"far_leg":around(Vector2(220,122),crawl*.07),
		"far_boot":around(Vector2(220,122),crawl*.07),
		"near_leg":around(Vector2(225,143),-crawl*.06),
		"near_boot":around(Vector2(225,143),-crawl*.06),
		"far_arm":body*around(Vector2(116,114),-crawl*.10),
		"near_upper_arm":body*around(Vector2(123,118),crawl*.09),
		"near_forearm":body*around(Vector2(123,118),crawl*.09)*around(Vector2(94,149),crawl*.05),
		"stump":body
	}

static func draw(view: Node2D,z: Dictionary,pos: Vector2,size: float,parent: Transform2D) -> Vector2:
	var unit := .45*size
	var base := Transform2D(Vector2(unit,0),Vector2(0,unit),pos-Vector2(155,100)*unit)
	var m := pose(z)
	var tint := Color(.72,1.0,1.12) if float(z.get("slow",0.0))>0 else Color.WHITE
	for id in ORDER:
		if z.get("arm_lost",false) and id in ["near_upper_arm","near_forearm"]: continue
		view.draw_set_transform_matrix(parent*base*m[id])
		view.draw_texture_rect(PARTS[id],Rect2(0,0,360,190),false,tint)
	if z.get("arm_lost",false):
		view.draw_set_transform_matrix(parent*base*m.stump)
		view.draw_texture_rect(PARTS.stump,Rect2(0,0,360,190),false,tint)
	view.draw_set_transform_matrix(parent)
	return base*m.head*Vector2(62,96)
