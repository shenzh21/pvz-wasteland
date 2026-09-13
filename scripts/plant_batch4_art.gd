extends RefCounted

# 第四批美术源稿；战场复用烘焙部件，南瓜前后层共用同一动画时钟。
const KINDS := ["pumpkin","wind_grass","sky_pepper"]
const BAKE_KINDS := ["pumpkin_back","pumpkin_front","wind_grass","sky_pepper"]
const Art := preload("res://scripts/garden_art.gd")
const Shape := preload("res://scripts/plant_batch2_art.gd")

static func smooth(v, nodes: Array, color: Color, edge: Color, width := 2.3) -> void:
	var points := PackedVector2Array()
	for i in nodes.size():
		var p: Vector2 = nodes[i]
		var next: Vector2 = nodes[(i+1)%nodes.size()]
		var prev: Vector2 = nodes[(i-1+nodes.size())%nodes.size()]
		var after: Vector2 = nodes[(i+2)%nodes.size()]
		for j in 10: points.append(p.bezier_interpolate(p+(next-prev)/6,next-(after-p)/6,next,j/10.0))
	v.draw_colored_polygon(points,color)
	if edge.a>0:
		points.append(points[0])
		v.draw_polyline(points,edge,width,true)

static func pumpkin(v, pos: Vector2, size: float, back: bool, time := 0.0) -> void:
	if not v.has_method("begin_art_part"):
		Art.CachedArt.draw(v,"pumpkin_back" if back else "pumpkin_front",pos,size,time)
		return
	var parent: Transform2D = v.art_parent_transform
	v.draw_set_transform_matrix(parent*Transform2D(0,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO))
	var ink := Color("#825033")
	if back:
		Art.part(v,"shadow")
		Art.oval(v,Vector2(0,44),Vector2(49,7),Color(0.15,0.23,0.12,0.16))
		Art.part(v,"body")
		Art.oval(v,Vector2(0,24),Vector2(47,24),Color("#be632b"),ink,2.5)
		Art.oval(v,Vector2(-2,16),Vector2(44,18),Color("#eaa049"))
		# 留出真正的开口，后缘必须在内部植物的后面。
		Art.oval(v,Vector2(0,12),Vector2(41,13),Color("#855031"),Color("#f5c176"),3)
		Shape.curve(v,Vector2(-21,0),Vector2(-24,-8),Vector2(-17,-9),Vector2(-16,-12),Color("#63834a"),5)
		Art.part(v,"pumpkin_leaf")
		Art.leaf(v,Vector2(-33,-7),Vector2(-21,-4),Color("#8da353"))
	else:
		Art.part(v,"body")
		var front := PackedVector2Array()
		for i in 25:
			var a := PI*i/24.0
			front.append(Vector2(cos(a)*44,12+sin(a)*13))
		for i in 25:
			var a := PI-PI*i/24.0
			front.append(Vector2(cos(a)*47,24+sin(a)*23))
		v.draw_colored_polygon(front,Color("#da8434"))
		front.append(front[0])
		v.draw_polyline(front,ink,2.3,true)
		for x in [-33.0,-18.0,0.0,18.0,33.0]:
			var start_y := 12+sqrt(1-pow(x/44,2))*13
			var end_y := 24+sqrt(1-pow(x/47,2))*22
			Shape.curve(v,Vector2(x,start_y+2),Vector2(x*1.1,30),Vector2(x*1.02,38),Vector2(x*0.93,end_y-1),Color("#ad602b"),2.1)
			Shape.curve(v,Vector2(x-3,start_y+3),Vector2(x-5,30),Vector2(x-4,36),Vector2(x-3,end_y-4),Color("#efaa50"),2.4)
		var rim := PackedVector2Array()
		for i in 33:
			var a := PI*i/32.0
			rim.append(Vector2(cos(a)*44,12+sin(a)*13))
		v.draw_polyline(rim,Color("#ffcf82"),4,true)
		# 雕刻表情保持在前壁，绝不把开口画成不透明盖子。
		Shape.polygon(v,[Vector2(-27,26),Vector2(-12,30),Vector2(-23,35)],Color("#66432e"),Color("#a75b2b"))
		Shape.polygon(v,[Vector2(27,26),Vector2(12,30),Vector2(23,35)],Color("#66432e"),Color("#a75b2b"))
		Shape.polygon(v,[Vector2(-15,37),Vector2(-7,39),Vector2(-5,36),Vector2(2,37),Vector2(3,40),Vector2(14,37),Vector2(9,43),Vector2(-8,43)],Color("#69432c"),Color("#ba722e"))
	v.draw_set_transform_matrix(parent)

static func blade(v, root: Vector2, tip: Vector2, width: float, color: Color) -> void:
	var points := PackedVector2Array()
	var d := tip-root
	var n := Vector2(-d.y,d.x).normalized()*width
	for i in 17: points.append((root-n*0.5).bezier_interpolate(root+d*0.4-n*1.4,tip-d*0.2-n,tip,i/16.0))
	for i in 17: points.append(tip.bezier_interpolate(tip-d*0.3+n*0.2,root+d*0.4+n,root+n*0.5,i/16.0))
	v.draw_colored_polygon(points,color)
	points.append(points[0])
	v.draw_polyline(points,Color("#536a3d"),1.9,true)
	Shape.curve(v,root,root+d*0.4-n*0.3,tip-d*0.25-n*0.2,tip-d*0.12,color.lightened(0.24),2)

static func draw(v, kind: String, pos: Vector2, size: float, time := 0.0, pulse := 0.0, charge := 0.0) -> void:
	if kind=="pumpkin":
		pumpkin(v,pos,size,true,time)
		pumpkin(v,pos,size,false,time)
		return
	if kind in ["pumpkin_back","pumpkin_front"]:
		pumpkin(v,pos,size,kind=="pumpkin_back",time)
		return
	if not v.has_method("begin_art_part"):
		Art.CachedArt.draw(v,kind,pos,size,time,pulse,charge)
		return
	var parent: Transform2D = v.art_parent_transform
	v.draw_set_transform_matrix(parent*Transform2D(0,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO))
	Art.part(v,"shadow")
	Art.oval(v,Vector2(0,40),Vector2(34,6),Color(0.12,0.24,0.13,0.16))
	Art.part(v,"body")
	if kind=="wind_grass":
		# 高低交错的宽草叶，向迎风方向稍微拱起。
		Art.part(v,"wind_leaf_0")
		blade(v,Vector2(-16,35),Vector2(-27,-17),7,Color("#86964d"))
		Art.part(v,"wind_leaf_1")
		blade(v,Vector2(16,35),Vector2(40,-13),7,Color("#7c8b46"))
		Art.part(v,"wind_leaf_2")
		blade(v,Vector2(-10,35),Vector2(-11,-37),9,Color("#a4b363"))
		Art.part(v,"wind_leaf_3")
		blade(v,Vector2(9,35),Vector2(26,-35),10,Color("#97a757"))
		Art.part(v,"body")
		smooth(v,[Vector2(-16,32),Vector2(-19,3),Vector2(-10,-23),Vector2(8,-46),Vector2(7,-22),Vector2(19,1),Vector2(16,32),Vector2(0,39)],Color("#aab967"),Color("#536a3d"))
		Shape.curve(v,Vector2(-9,26),Vector2(-14,9),Vector2(-9,-15),Vector2(3,-33),Color("#d4dc98"),3)
		Shape.curve(v,Vector2(10,28),Vector2(16,12),Vector2(13,-4),Vector2(9,-13),Color("#82974e"),2)
		Art.eye(v,Vector2(-4,6),0.95)
		Art.eye(v,Vector2(10,5),0.9)
		v.draw_line(Vector2(-10,-3),Vector2(-1,0),Color("#52653a"),2.5,true)
		v.draw_line(Vector2(8,-1),Vector2(16,-5),Color("#52653a"),2.5,true)
		Shape.curve(v,Vector2(-1,18),Vector2(4,20),Vector2(8,18),Vector2(11,16),Color("#52653a"),2)
		Art.part(v,"wind_base")
		blade(v,Vector2(-5,38),Vector2(-36,17),6,Color("#849c51"))
		blade(v,Vector2(6,38),Vector2(37,14),6,Color("#b4bf70"))
	elif kind=="sky_pepper":
		Art.part(v,"leaf_left")
		Art.leaf(v,Vector2(-32,20),Vector2(0,37),Color("#669747"))
		Art.part(v,"leaf_right")
		Art.leaf(v,Vector2(32,19),Vector2(0,38),Color("#89b65c"))
		Art.part(v,"body")
		Shape.curve(v,Vector2(1,37),Vector2(-2,29),Vector2(4,26),Vector2(2,21),Color("#4e7540"),6)
		# 上扬的尖端和鼓起的椒身，保留朝天椒而不是普通甜椒的轮廓。
		Art.part(v,"head")
		smooth(v,[Vector2(-12,25),Vector2(-22,8),Vector2(-14,-15),Vector2(3,-36),Vector2(19,-46),Vector2(12,-26),Vector2(23,-3),Vector2(21,17),Vector2(8,29)],Color("#b64232"),Color("#7b4132"),2.5)
		smooth(v,[Vector2(-10,20),Vector2(-17,6),Vector2(-10,-13),Vector2(7,-33),Vector2(7,-20),Vector2(16,0),Vector2(14,18),Vector2(4,24)],Color("#ef7950"),Color.TRANSPARENT)
		Shape.curve(v,Vector2(-10,5),Vector2(-13,-6),Vector2(-4,-19),Vector2(5,-25),Color("#ffb97b"),4)
		Shape.curve(v,Vector2(13,17),Vector2(18,11),Vector2(18,3),Vector2(15,-2),Color("#d25539"),2.5)
		Art.eye(v,Vector2(-4,5),1.05)
		Art.eye(v,Vector2(11,4),0.9)
		Shape.curve(v,Vector2(-1,16),Vector2(4,19),Vector2(8,16),Vector2(12,13),Color("#803a30"),2)
		Shape.polygon(v,[Vector2(-15,25),Vector2(-10,19),Vector2(-3,24),Vector2(4,20),Vector2(10,24),Vector2(17,21),Vector2(11,30),Vector2(1,32)],Color("#81a84c"),Color("#527a3f"))
	v.draw_set_transform_matrix(parent)
