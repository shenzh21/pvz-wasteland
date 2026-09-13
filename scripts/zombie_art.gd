extends RefCounted
# Shared SVG canvas: 240 x 360. World anchor: (132, 210).
const ORIGIN := Vector2(132,210)
const GIANT_TORSO := preload("res://assets/zombies/giant/torso.svg")
const GIANT_PARTS := {
	"head": preload("res://assets/zombies/giant/head.svg"),
	"jaw": preload("res://assets/zombies/giant/jaw.svg"),
	"far_upper_arm": preload("res://assets/zombies/giant/far_upper_arm.svg"),
	"near_upper_arm": preload("res://assets/zombies/giant/near_upper_arm.svg"),
	"far_forearm": preload("res://assets/zombies/giant/far_forearm.svg"),
	"near_forearm": preload("res://assets/zombies/giant/near_forearm.svg"),
}
const UNIT := 0.46
const PARTS := {
	"far_thigh": preload("res://assets/zombies/basic/parts/far_thigh.svg"),
	"far_calf": preload("res://assets/zombies/basic/parts/far_calf.svg"),
	"far_shoe": preload("res://assets/zombies/basic/parts/far_shoe.svg"),
	"near_thigh": preload("res://assets/zombies/basic/parts/near_thigh.svg"),
	"near_calf": preload("res://assets/zombies/basic/parts/near_calf.svg"),
	"near_shoe": preload("res://assets/zombies/basic/parts/near_shoe.svg"),
	"far_upper_arm": preload("res://assets/zombies/basic/parts/far_upper_arm.svg"),
	"far_forearm": preload("res://assets/zombies/basic/parts/far_forearm.svg"),
	"torso": preload("res://assets/zombies/basic/parts/torso.svg"),
	"tie": preload("res://assets/zombies/basic/parts/tie.svg"),
	"near_upper_arm": preload("res://assets/zombies/basic/parts/near_upper_arm.svg"),
	"near_forearm": preload("res://assets/zombies/basic/parts/near_forearm.svg"),
	"neck": preload("res://assets/zombies/basic/parts/neck.svg"),
	"head": preload("res://assets/zombies/basic/parts/head.svg"),
	"jaw": preload("res://assets/zombies/basic/parts/jaw.svg"),
	"stump": preload("res://assets/zombies/basic/parts/stump.svg"),
}
const BASKET_PARTS := {
	"torso": preload("res://assets/zombies/basket/parts/torso.svg"),
	"far_upper_arm": preload("res://assets/zombies/basket/parts/far_upper_arm.svg"),
	"near_upper_arm": preload("res://assets/zombies/basket/parts/near_upper_arm.svg"),
	"far_thigh": preload("res://assets/zombies/basket/parts/far_thigh.svg"),
	"near_thigh": preload("res://assets/zombies/basket/parts/near_thigh.svg"),
	"far_calf": preload("res://assets/zombies/basket/parts/far_calf.svg"),
	"near_calf": preload("res://assets/zombies/basket/parts/near_calf.svg"),
}
const PIVOTS := {
	"far_thigh": Vector2(126,239),
	"far_calf": Vector2(112,281),
	"far_shoe": Vector2(122,320),
	"near_thigh": Vector2(157,240),
	"near_calf": Vector2(166,284),
	"near_shoe": Vector2(157,322),
	"far_upper_arm": Vector2(100,163),
	"far_forearm": Vector2(86,207),
	"torso": Vector2(134,233),
	"tie": Vector2(121,157),
	"near_upper_arm": Vector2(155,164),
	"near_forearm": Vector2(172,212),
	"neck": Vector2(121,137),
	"head": Vector2(124,120),
	"jaw": Vector2(121,124),
}
const ORDER := ["far_thigh","far_calf","far_shoe","near_thigh","near_calf","near_shoe","far_upper_arm","far_forearm","torso","tie","near_upper_arm","near_forearm","neck","head","jaw"]
# 巨人近侧左臂抬起投掷时应遮住头部，而不是被脸截断；远侧持棒臂仍在后层。
const GIANT_ORDER := ["far_thigh","far_calf","far_shoe","near_thigh","near_calf","near_shoe","far_upper_arm","far_forearm","torso","neck","head","jaw","near_upper_arm","near_forearm"]

static func turn_part(id: String, angle: float) -> Transform2D:
	var pivot: Vector2 = PIVOTS[id]
	return Transform2D(0.0,pivot) * Transform2D(angle,Vector2.ZERO) * Transform2D(0.0,-pivot)

static func pose(z: Dictionary) -> Dictionary:
	var t: float = z.get("anim",0.0)
	var biting: bool = z.get("biting",false)
	var walking: bool = z.get("walking",not biting)
	var is_swing: bool = String(z.get("kind",""))=="swing"
	var is_charger: bool = String(z.get("kind",""))=="charger"
	var rate := 2.65 * clampf(float(z.get("speed",15.0))/15.0,0.8,1.7)
	var g := sin(t*rate) if walking else 0.0
	var bite := (sin(t*11.0)+1.0)*0.5 if biting else 0.0
	var idle := not walking and not biting
	var idle_time := t * float(z.get("idle_rate",1.0))
	var sway := sin(idle_time*1.65) if idle else 0.0
	var arm_sway := sin(idle_time*1.65-0.5) if idle else 0.0
	var bob := sin(t*rate*2.0)*1.1 if walking else sin(idle_time*3.3)*0.7 if idle else 0.0
	if z.get("kind","")=="basket" and int(z.get("throw_phase",0))==1:
		bob += 8.0*sin(PI*clampf(float(z.get("throw_time",0.0))/1.2,0.0,1.0))
	# 摇摆僵尸以较慢的四拍感摆动上半身；啃食时收住动作，腿仍只跟随实际行走。
	var swing_amount := 1.0 if is_swing and not biting else 0.0
	var swing_beat := sin(t*4.35)*swing_amount
	var swing_counter := sin(t*4.35+1.15)*swing_amount
	var lane_lean := clampf(float(z.get("row",0))-float(z.get("draw_row",z.get("row",0))),-1.0,1.0)*0.055 if is_swing else 0.0
	# 原地待机只动腰部以上，腿脚保持固定；头、手臂稍有延迟。
	var charge_lean := -0.075 if is_charger and walking else 0.0
	var body := Transform2D(0.0,Vector2(swing_beat*2.4-3.0 if is_charger and walking else swing_beat*2.4,bob+absf(swing_counter)*1.2)) * turn_part("torso",sway*0.015+swing_beat*0.065+lane_lean+charge_lean)
	var m := {}
	m.far_thigh = turn_part("far_thigh",-.20*g)
	m.far_calf = m.far_thigh * turn_part("far_calf",.18*maxf(g,0.0))
	m.far_shoe = m.far_calf * turn_part("far_shoe",.04*g)
	m.near_thigh = turn_part("near_thigh",.20*g)
	m.near_calf = m.near_thigh * turn_part("near_calf",.18*maxf(-g,0.0))
	m.near_shoe = m.near_calf * turn_part("near_shoe",-.04*g)
	m.torso = body
	m.tie = body * turn_part("tie",.035*g+.04*bite+arm_sway*.022-swing_beat*.09)
	m.far_upper_arm = body * turn_part("far_upper_arm",.06*g+.85*bite+arm_sway*.026+swing_counter*.18+(.16 if is_charger and walking else 0.0))
	m.far_forearm = m.far_upper_arm * turn_part("far_forearm",.18*bite+arm_sway*.014-swing_beat*.10)
	m.near_upper_arm = body * turn_part("near_upper_arm",-.055*g+.75*bite-arm_sway*.024-swing_counter*.16+(.13 if is_charger and walking else 0.0))
	m.near_forearm = m.near_upper_arm * turn_part("near_forearm",.2*bite-arm_sway*.014+swing_beat*.11)
	m.neck = body
	m.head = body * Transform2D(0.0,Vector2(-8*bite,2*bite)) * turn_part("head",-.025*bite+sway*.01-swing_beat*.045-lane_lean*.35)
	m.jaw = m.head * Transform2D(0.0,Vector2(0,4*bite)) * turn_part("jaw",-.09*bite)
	m.stump = body
	if z.get("kind","")=="basket" and int(z.get("throw_phase",0))<3:
		var phase := int(z.get("throw_phase",0))
		var lift := smoothstep(0.25,1.0,float(z.get("throw_time",0.0))/1.2) if phase==1 else 1.0 if phase==2 else 0.0
		var follow := clampf(float(z.get("throw_time",0.0))/0.35,0.0,1.0) if phase==2 else 0.0
		m.far_upper_arm = body * turn_part("far_upper_arm",lerpf(0.15,2.7,lift)*(1.0-follow))
		m.far_forearm = m.far_upper_arm * turn_part("far_forearm",lerpf(-1.35,-0.35,lift)*(1.0-follow))
		m.near_upper_arm = body * turn_part("near_upper_arm",lerpf(0.25,1.6,lift)*(1.0-follow))
		m.near_forearm = m.near_upper_arm * turn_part("near_forearm",0.65*(1.0-follow))
	if z.get("kind","")=="giant":
		var throwing: bool = not z.get("imp_thrown",false) and float(z.get("giant_throw_time",0.0))>0.0
		var motion := clampf(float(z.get("giant_throw_time",0.0))/1.1,0.0,1.0) if throwing else clampf(float(z.get("smash_time",0.0))/1.25,0.0,1.0)
		var lift := sin(motion*PI*0.5) if throwing else smoothstep(0.0,0.65,motion)*(1.0-smoothstep(0.75,1.0,motion))
		var follow := clampf(float(z.get("giant_follow",0.0))/0.3,0.0,1.0)
		if follow>0.0:
			throwing = true
			lift = follow
		m.far_upper_arm = body*turn_part("far_upper_arm",0.1 if throwing else 2.6*lift)
		m.far_forearm = m.far_upper_arm*turn_part("far_forearm",0.0 if throwing else -0.5*lift)
		m.near_upper_arm = body*turn_part("near_upper_arm",(2.9 if throwing else 1.2)*lift)
		m.near_forearm = m.near_upper_arm*turn_part("near_forearm",0.35*lift)
	return m

static func draw(view: Node2D, z: Dictionary, pos: Vector2, size: float, parent: Transform2D = Transform2D.IDENTITY) -> Vector2:
	var m := pose(z)
	var unit := UNIT*size
	var base := Transform2D(Vector2(unit,0),Vector2(0,unit),pos-ORIGIN*unit)
	var tint := Color(0.72,1.0,1.12) if float(z.get("slow",0.0))>0.0 else Color.WHITE
	var lost: bool = z.get("arm_lost",false)
	var flag: bool = z.get("kind", "normal")=="flag"
	var basketball_uniform: bool = z.get("kind", "")=="basket"
	var giant: bool = z.get("kind","")=="giant"
	for id in GIANT_ORDER if giant else ORDER:
		if basketball_uniform and id=="tie": continue
		if giant and id=="tie": continue
		if lost and id in ["near_upper_arm","near_forearm"]: continue
		if flag and id in ["far_upper_arm","far_forearm"]: continue
		view.draw_set_transform_matrix(parent * base * m[id])
		var texture: Texture2D = BASKET_PARTS.get(id,PARTS[id]) if basketball_uniform else PARTS[id]
		if giant:
			if id=="torso": texture = GIANT_TORSO
			elif GIANT_PARTS.has(id): texture = GIANT_PARTS[id]
		view.draw_texture_rect(texture,Rect2(0,0,240,360),false,tint)
	if lost:
		view.draw_set_transform_matrix(parent * base * m.stump)
		view.draw_texture_rect(PARTS.stump,Rect2(0,0,240,360),false,tint)
	view.draw_set_transform_matrix(parent)
	return base * m.head * Vector2(102,91)
