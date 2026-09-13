extends RefCounted

# 第二批植物，共用静态造型和由游戏状态驱动的动画。
const Art := preload("res://scripts/garden_art.gd")
const KINDS := ["mine","cherry","yam_guard","needle"]

static func polygon(v, points: Array, color: Color, outline: Color) -> void:
	var p := PackedVector2Array(points)
	v.draw_colored_polygon(p,color)
	p.append(p[0])
	v.draw_polyline(p,outline,2.2,true)

static func curve(v, start: Vector2, a: Vector2, b: Vector2, end: Vector2, color: Color, width: float) -> void:
	var p := PackedVector2Array()
	for i in 25: p.append(start.bezier_interpolate(a,b,end,i/24.0))
	v.draw_polyline(p,color,width,true)

static func yam(v, small: bool, time: float, strike: float) -> void:
	var ink := Color("#75422f")
	var body := PackedVector2Array()
	for i in 40:
		var a := TAU*i/40.0
		body.append(Vector2(cos(a)*(25+4*sin(a)),sin(a)*32+4))
	v.draw_colored_polygon(body,Color("#b75b40"))
	body.append(body[0])
	v.draw_polyline(body,ink,2.5,true)
	Art.oval(v,Vector2(-3,-1),Vector2(22,27),Color("#dd8454"))
	Art.oval(v,Vector2(-11,-12),Vector2(7,12),Color("#f0a874"))
	curve(v,Vector2(-4,-24),Vector2(-8,-34),Vector2(4,-37),Vector2(8,-34),Color("#508341"),4)
	Art.part(v,"yam_leaf_left")
	Art.leaf(v,Vector2(-22,-34+sin(time*2.8)*3),Vector2(-3,-25),Color("#78b951"))
	Art.part(v,"yam_leaf_right")
	Art.leaf(v,Vector2(19,-39+sin(time*2.8+1)*3),Vector2(0,-27),Color("#92c965"))
	Art.part(v,"body")
	Art.eye(v,Vector2(1,-3),1.05,fposmod(time,4.9)>4.72)
	Art.eye(v,Vector2(16,-4),0.9,fposmod(time,4.9)>4.72)
	v.draw_line(Vector2(-4,-12),Vector2(6,-10),ink,2,true)
	v.draw_line(Vector2(12,-11),Vector2(20,-14),ink,2,true)
	curve(v,Vector2(4,11),Vector2(9,13),Vector2(13,12),Vector2(17,9),ink,2)
	for p in [Vector2(-16,7),Vector2(-9,22),Vector2(19,18)]:
		v.draw_line(p,p+Vector2(2,-3),Color("#a9563c"),1.6,true)
	if small:
		Art.oval(v,Vector2(-14,35),Vector2(9,4),Color("#72533b"))
		Art.oval(v,Vector2(14,35),Vector2(9,4),Color("#72533b"))
		# 小红薯的叶盾和短枝体现驻守身份，不另加金属装备。
		var push := Vector2(strike*9,-strike*3)
		Art.part(v,"shield")
		polygon(v,[Vector2(23,4)+push,Vector2(40,6)+push,Vector2(38,22)+push,Vector2(29,31)+push,Vector2(22,22)+push],Color("#719c48"),Color("#395e38"))
		v.draw_line(Vector2(30,9)+push,Vector2(30,26)+push,Color("#c0d98a"),2,true)
	else:
		# 编织状叶座保持植物身份。
		Art.leaf(v,Vector2(-36,22),Vector2(0,35),Color("#689b43"))
		Art.leaf(v,Vector2(35,24),Vector2(0,35),Color("#8ab957"))

static func draw(v, kind: String, position: Vector2, size: float, time := 0.0, pulse := 0.0, charge := 0.0, attacking := false) -> void:
	if not v.has_method("begin_art_part"):
		Art.CachedArt.draw(v,kind,position,size,time,pulse,charge,attacking)
		return
	var parent: Transform2D = v.art_parent_transform
	var local := parent*Transform2D(0,position)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO)
	v.draw_set_transform_matrix(local)
	Art.part(v,"shadow")
	Art.oval(v,Vector2(0,38),Vector2(34,7),Color(0.13,0.24,0.12,0.16))
	var breath := sin(time*2.2)*0.015 if kind not in ["mine","mine_hidden"] else 0.0
	var strike := maxf(0,sin(time*11))*float(attacking)
	var swelling := charge*0.16 if kind=="cherry" else 0.0
	var angle := sin(time*2.0)*0.015 if kind=="yam_guard" else -strike*0.06 if kind=="yam_minion" else 0.0
	var shake := Vector2(sin(time*65)*charge*2.0,0) if kind=="cherry" else Vector2.ZERO
	v.draw_set_transform_matrix(local*Transform2D(angle,Vector2(0,36)+shake)*Transform2D(Vector2(1-breath+swelling,0),Vector2(0,1+breath+swelling),Vector2.ZERO)*Transform2D(0,Vector2(0,-36)))
	Art.part(v,"body")
	match kind:
		"mine", "mine_hidden":
			var armed := kind=="mine"
			Art.oval(v,Vector2(0,32),Vector2(34,8),Color("#947249"))
			Art.oval(v,Vector2(-2,30),Vector2(29,6),Color("#bd975f"))
			if armed:
				Art.oval(v,Vector2(0,12),Vector2(29,23),Color("#b27a42"),Color("#795235"),2.4)
				Art.oval(v,Vector2(-3,8),Vector2(25,19),Color("#e0ad6b"))
				Art.oval(v,Vector2(-12,1),Vector2(8,4),Color("#f2cb8e"))
				Art.eye(v,Vector2(-5,10))
				Art.eye(v,Vector2(12,9))
				curve(v,Vector2(-1,21),Vector2(4,24),Vector2(9,24),Vector2(14,20),Color("#754931"),2)
				for p in [Vector2(-19,15),Vector2(20,19),Vector2(-8,-5)]:
					Art.oval(v,p,Vector2(1.5,1.2),Color("#b8834d"))
			var stem_y := -7.0 if armed else 26.0
			v.draw_line(Vector2(1,stem_y),Vector2(1,stem_y-14),Color("#735e43"),4,true)
			Art.oval(v,Vector2(1,stem_y-17),Vector2(7,8),Color("#ef6650") if armed else Color("#ab9370"),Color("#785341"),2)
			Art.oval(v,Vector2(-1,stem_y-20),Vector2(2,3),Color("#ffe6a5"))
			if armed:
				var glow := (sin(time*7)+1)*0.5
				Art.part(v,"effect")
				Art.oval(v,Vector2(1,stem_y-17),Vector2(11,12),Color(1,0.35,0.12,glow*0.22))
				Art.oval(v,Vector2(0,stem_y-19),Vector2(3,4),Color(1,0.96,0.65,glow))
			Art.part(v,"body")
			for p in [Vector2(-27,31),Vector2(19,34),Vector2(29,29)]:
				Art.oval(v,p,Vector2(4,2),Color("#d3b17b"))
		"cherry":
			curve(v,Vector2(-17,1),Vector2(-15,-20),Vector2(4,-21),Vector2(3,-35),Color("#426d3c"),5)
			curve(v,Vector2(19,4),Vector2(18,-16),Vector2(3,-20),Vector2(3,-35),Color("#426d3c"),5)
			Art.leaf(v,Vector2(29,-34),Vector2(3,-29),Color("#87bd52"))
			for i in 2:
				var p := Vector2(-17,13) if i==0 else Vector2(19,16)
				Art.oval(v,p,Vector2(22,23),Color("#b9363e"),Color("#70353a"),2.5)
				Art.oval(v,p+Vector2(-3,-4),Vector2(18,18),Color("#ec6151"))
				Art.oval(v,p+Vector2(-10,-12),Vector2(5,7),Color("#ffb593"))
				Art.eye(v,p+Vector2(-3,-2),0.9)
				Art.eye(v,p+Vector2(10,-3),0.85)
				v.draw_line(p+Vector2(-7,-10),p+Vector2(1,-8),Color("#70353a"),2,true)
				v.draw_line(p+Vector2(6,-9),p+Vector2(14,-12),Color("#70353a"),2,true)
				v.draw_arc(p+Vector2(4,10),4,PI+0.2,TAU-0.2,8,Color("#70353a"),2,true)
		"yam_guard", "yam_minion":
			yam(v,kind=="yam_minion",time,strike)
		"needle":
			v.draw_line(Vector2(0,37),Vector2(0,-2),Color("#395e38"),8,true)
			v.draw_line(Vector2(-1,35),Vector2(-1,1),Color("#77ab52"),4,true)
			Art.leaf(v,Vector2(-33,15),Vector2(0,31),Color("#72a24a"))
			Art.leaf(v,Vector2(32,12),Vector2(0,34),Color("#91bf5c"))
			v.draw_set_transform_matrix(local*Transform2D(sin(time*2.0)*0.025,Vector2(-pulse*4,-pulse*2)))
			Art.part(v,"head")
			# 保留紫色种荚识别色，用带倒钩的芒针表现邻行射击。
			for i in 9:
				var a := TAU*i/9.0
				var start := Vector2(cos(a),sin(a))*19+Vector2(0,-9)
				var tip := Vector2(cos(a),sin(a))*33+Vector2(0,-9)
				v.draw_line(start,tip,Color("#65603b"),2.4,true)
				v.draw_line(tip,tip+Vector2(-4,-4).rotated(a),Color("#a9ba71"),1.8,true)
			Art.oval(v,Vector2(0,-8),Vector2(23,24),Color("#785090"),Color("#4c4057"),2.5)
			Art.oval(v,Vector2(-3,-12),Vector2(19,18),Color("#b88bc4"))
			Art.oval(v,Vector2(-11,-21),Vector2(7,4),Color("#debee2"))
			Art.eye(v,Vector2(-4,-10))
			Art.eye(v,Vector2(11,-11),0.9)
			curve(v,Vector2(0,2),Vector2(5,5),Vector2(9,5),Vector2(13,1),Color("#58405f"),2)
	v.draw_set_transform_matrix(parent)
