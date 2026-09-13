extends RefCounted

# 美术源码保留在 garden_art / plant_batch2_art，tools/bake_plant_art.gd 可重新烘焙。
# 所有实例共享一张图集，只实时改变各部件的位置、旋转、缩放和眼睛状态。
static var atlas: Texture2D
static var parts: Dictionary = {}

static func warmup() -> void:
	if atlas != null: return
	atlas = load("res://assets/plants/parts.png")
	var data: Resource = load("res://assets/plants/parts.tres")
	parts = data.get_meta("parts")

static func pivot(at: Vector2, angle := 0.0, scale := Vector2.ONE) -> Transform2D:
	return Transform2D(angle,at)*Transform2D(Vector2(scale.x,0),Vector2(0,scale.y),Vector2.ZERO)*Transform2D(0,-at)

static func draw(v, kind: String, pos: Vector2, size: float, time := 0.0, pulse := 0.0, charge := 0.0, attacking := false, phase := 0) -> void:
	warmup()
	var parent: Transform2D = v.art_parent_transform
	var local := parent*Transform2D(0,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO)
	var first := kind in ["sunflower","pea","snow","short_pea","energy_pea","wall"]
	var breath := sin(time*(2.1 if first else 2.2))*(0.012 if first else 0.015)
	if kind in ["mine","mine_hidden"]: breath = 0.0
	var strike := maxf(0,sin(time*11))*float(attacking)
	var swell := charge*0.16 if kind in ["cherry","bbq_mushroom"] else 0.0
	var angle := sin(time*2.0)*0.015 if kind=="yam_guard" else -strike*0.06 if kind=="yam_minion" else 0.0
	var body := local*pivot(Vector2(0,38 if first else 36),angle,Vector2(1-breath+swell,1+breath+swell))
	if kind=="cherry": body.origin += local.basis_xform(Vector2(sin(time*65)*charge*2,0))
	if kind=="cactus": body = body*pivot(Vector2(0,37),pulse*0.035)
	if kind.begins_with("pumpkin_"):
		body = local*pivot(Vector2(0,46),0,Vector2(1-breath*0.5,1+breath*0.65))
	if kind=="wind_grass":
		body = body*pivot(Vector2(0,36),sin(time*2.4)*0.025+pulse*0.16-charge*0.07)
	if kind=="slime": body = body*pivot(Vector2(0,25),0,Vector2(1+pulse*0.045,1-pulse*0.035))
	if kind=="squash" and phase>0:
		var shape := Vector2(1.13,0.8) if phase==1 else Vector2(0.9,1.1) if phase==2 else Vector2(1.25,0.62)
		body = local*pivot(Vector2.ZERO,0,shape)
	var head := body
	if kind in ["pea","snow","short_pea","energy_pea"]:
		head = body*Transform2D(0,Vector2(-pulse*4,sin(time*2.1)*0.8))
	elif kind=="needle":
		head = local*Transform2D(sin(time*2.0)*0.025,Vector2(-pulse*4,-pulse*2))
	elif kind=="sky_pepper":
		head = body*pivot(Vector2(1,27),-charge*0.12+pulse*0.13,Vector2(1+charge*0.05-pulse*0.025,1-charge*0.08+pulse*0.04))
	var blink := fposmod(time,4.7 if first else 4.9)>(4.52 if first else 4.72)
	for part_data in parts[kind]:
		var name: String = part_data.name
		var transform := body
		if name=="shadow" and kind=="squash" and phase==2: continue
		if name=="shadow":
			transform = local
			if kind=="squash" and phase in [1,3]:
				transform = local*Transform2D(0,Vector2(0,-8 if phase==1 else -19))
		elif name=="soil": transform = local
		elif name=="pumpkin_leaf": transform = body*pivot(Vector2(-21,-4),sin(time*2)*0.055)
		elif name=="wind_base": transform = local
		elif name.begins_with("wind_leaf_"):
			var index := name.get_slice("_",2).to_int()
			var root: Vector2 = [Vector2(-16,35),Vector2(16,35),Vector2(-10,35),Vector2(9,35)][index]
			var sway := (sin(time*(2.2+charge*2)+index*0.8)-sin(index*0.8))*(0.035+charge*0.025)
			transform = body*pivot(root,sway+pulse*(0.07+index*0.02))
		elif name=="flower": transform = body*pivot(Vector2(-2,-35),sin(time*2.4)*0.05-pulse*0.1)
		elif name=="cactus_left": transform = body*pivot(Vector2(-10,10),sin(time*2.2)*0.025)
		elif name=="cactus_right": transform = body*pivot(Vector2(10,10),-sin(time*2.2)*0.025)
		elif name.begins_with("succulent_"):
			var index := float(name.get_slice("_",2).to_int())
			var wiggle := (sin(time*(5.0 if attacking else 1.8)+index*0.7)-sin(index*0.7))*(0.04 if attacking else 0.025)
			transform = body*pivot(Vector2(0,24 if name.contains("back") else 19),wiggle)
		elif name=="droplet": transform = body*Transform2D(0,Vector2(0,sin(time*3)*1.5))
		elif name=="cap": transform = body*pivot(Vector2(0,8),sin(time*3)*0.025+sin(time*55)*charge*0.025)
		elif name=="ember": transform = body*pivot(Vector2(25,-44),0,Vector2.ONE*(1+sin(time*17)*0.15+charge*0.4))
		elif name.begins_with("head"): transform = head
		elif name=="leaf_left": transform = body*pivot(Vector2(0,35),-sin(time*2.7)*0.06)
		elif name=="leaf_right": transform = body*pivot(Vector2(0,37),(sin(time*2.7+1.2)-sin(1.2))*0.06)
		elif name=="petals": transform = body*pivot(Vector2(0,-7),sin(time*1.8)*0.045)
		elif name=="yam_leaf_left": transform = body*pivot(Vector2(-3,-25),-sin(time*2.8)*0.12)
		elif name=="yam_leaf_right": transform = body*pivot(Vector2(0,-27),(sin(time*2.8+1)-sin(1.0))*0.12)
		elif name=="shield": transform = body*Transform2D(0,Vector2(strike*9,-strike*3))
		v.draw_set_transform_matrix(transform)
		var shut: bool = blink and name.ends_with("/eye")
		var region: Rect2 = part_data.closed if shut else part_data.region
		var dest: Rect2 = part_data.closed_dest if shut else part_data.dest
		v.draw_texture_rect_region(atlas,dest,region)
	if kind=="sunflower" and pulse>0:
		v.draw_set_transform_matrix(body)
		v.draw_arc(Vector2(0,-7),37+(1-pulse)*8,0,TAU,32,Color(1,0.9,0.45,pulse*0.45),2,true)
	elif kind=="energy_pea":
		v.draw_set_transform_matrix(head)
		for a in [-2.2,-1.0,1.2]:
			v.draw_circle(Vector2(-3,-9)+Vector2(cos(a+time*0.6),sin(a+time*0.6))*31,3,Color("#f1ffba"))
	elif kind=="mine":
		var glow := (sin(time*7)+1)*0.5
		v.draw_set_transform_matrix(body*Transform2D(Vector2(1,0),Vector2(0,12.0/11),Vector2(1,-24)))
		v.draw_circle(Vector2.ZERO,11,Color(1,0.35,0.12,glow*0.22))
		v.draw_set_transform_matrix(body*Transform2D(Vector2(1,0),Vector2(0,4.0/3),Vector2(0,-26)))
		v.draw_circle(Vector2.ZERO,3,Color(1,0.96,0.65,glow))
	v.draw_set_transform_matrix(parent)
