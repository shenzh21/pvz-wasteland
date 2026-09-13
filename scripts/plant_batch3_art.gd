extends RefCounted

# 第三批植物的程序化源稿；游戏使用开发期烘焙的部件图集。
const KINDS := ["cactus","slime","squash","bbq_mushroom"]
const Art := preload("res://scripts/garden_art.gd")
const Shape := preload("res://scripts/plant_batch2_art.gd")

static func draw(v, kind: String, pos: Vector2, size: float, time := 0.0, pulse := 0.0, charge := 0.0, attacking := false, phase := 0) -> void:
	if not v.has_method("begin_art_part"):
		Art.CachedArt.draw(v,kind,pos,size,time,pulse,charge,attacking,phase)
		return
	var parent: Transform2D = v.art_parent_transform
	v.draw_set_transform_matrix(parent*Transform2D(0,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO))
	Art.part(v,"shadow")
	Art.oval(v,Vector2(0,40),Vector2(35,7),Color(0.12,0.24,0.13,0.16))
	Art.part(v,"body")
	match kind:
		"cactus":
			var ink := Color("#426537")
			var green := Color("#83b957")
			for spec in [Vector3(-29,-20,-1),Vector3(29,-7,1)]:
				Art.part(v,"cactus_left" if spec.z<0 else "cactus_right")
				var x: float = spec.x
				Shape.curve(v,Vector2(spec.z*10,10),Vector2(x,17),Vector2(x,3),Vector2(x,spec.y),ink,15)
				Shape.curve(v,Vector2(spec.z*10,10),Vector2(x,17),Vector2(x,3),Vector2(x,spec.y),green,10)
				Art.oval(v,Vector2(x,spec.y),Vector2(5,5),green)
				Shape.curve(v,Vector2(x-2,spec.y+3),Vector2(x-4,0),Vector2(x-3,8),Vector2(spec.z*18,10),Color("#acd278"),2)
			# 顶部圆润，柱身一直延伸至土面，不在底部收成椭圆。
			Art.part(v,"body")
			var trunk := PackedVector2Array()
			for i in 21:
				var a := PI+PI*i/20.0
				trunk.append(Vector2(cos(a)*21,-17+sin(a)*22))
			trunk.append_array(PackedVector2Array([Vector2(21,36),Vector2(8,38),Vector2(-8,37),Vector2(-21,36)]))
			v.draw_colored_polygon(trunk,Color("#619244"))
			trunk.append(trunk[0])
			v.draw_polyline(trunk,ink,2.5,true)
			var lit := PackedVector2Array()
			for i in 21:
				var a := PI+PI*i/20.0
				lit.append(Vector2(-4+cos(a)*16,-17+sin(a)*18))
			lit.append_array(PackedVector2Array([Vector2(12,35),Vector2(-19,35)]))
			v.draw_colored_polygon(lit,green)
			Shape.curve(v,Vector2(-10,-28),Vector2(-15,-14),Vector2(-12,18),Vector2(-8,29),Color("#b5d57f"),3)
			Shape.curve(v,Vector2(8,-29),Vector2(14,-10),Vector2(13,17),Vector2(9,29),Color("#4f7e3e"),2)
			# 半眯单眼、侧向管口与红花冠沿用原设计。
			Art.oval(v,Vector2(0,-18),Vector2(10,7),Color("#f1f3d3"))
			Art.eye(v,Vector2(5,-17),0.8)
			v.draw_line(Vector2(-10,-23),Vector2(10,-24),ink,3,true)
			Art.oval(v,Vector2(21,-11),Vector2(11,10),green,ink,2)
			Art.oval(v,Vector2(27,-11),Vector2(5,8),Color("#b2d374"),ink,2)
			Art.oval(v,Vector2(28,-11),Vector2(2.5,4.5),Color("#3f6337"))
			Art.part(v,"flower")
			for i in 7:
				var a := TAU*i/7.0
				Art.oval(v,Vector2(-2,-40)+Vector2(cos(a)*10,sin(a)*7),Vector2(6,7),Color("#ed7660"),Color("#a54a40"),1.4)
			Art.oval(v,Vector2(-2,-40),Vector2(6,5),Color("#ffcf70"))
			Art.part(v,"body")
			for p in [Vector2(-15,0),Vector2(12,10),Vector2(-10,21),Vector2(13,-31),Vector2(-29,-11),Vector2(29,2)]:
				Art.oval(v,p,Vector2(2,2.5),Color("#5e873d"))
				v.draw_line(p,p+Vector2(-3,-4),Color("#ecdfad"),1.5,true)
				v.draw_line(p,p+Vector2(3,-3),Color("#ecdfad"),1.5,true)
			# 零散覆土压住根部；小草从两侧长出，不画成花盆底座。
			Art.part(v,"soil")
			v.draw_colored_polygon(PackedVector2Array([Vector2(-26,40),Vector2(-21,34),Vector2(-13,37),Vector2(-6,35),Vector2(2,39),Vector2(12,35),Vector2(19,36),Vector2(25,40)]),Color("#a78c54"))
			for p in [Vector2(-22,38),Vector2(22,39)]:
				v.draw_line(p,p+Vector2(-5,-7),Color("#6b9644"),2,true)
				v.draw_line(p,p+Vector2(2,-10),Color("#87b350"),2,true)
			Art.oval(v,Vector2(-12,39),Vector2(3,1.5),Color("#cbb780"))
			Art.oval(v,Vector2(15,40),Vector2(3,1.5),Color("#cbb780"))
		"slime":
			# 肉质莲座：后叶、核心、前叶分层，而不是一圈平面尖角。
			for i in 5:
				var a := PI+PI*i/4.0
				Art.part(v,"succulent_back_%d"%i)
				petal(v,Vector2(cos(a)*39,12+sin(a)*36),Vector2(0,24),Color("#68ad94") if i%2==0 else Color("#80c5a6"))
			Art.part(v,"body")
			Art.oval(v,Vector2(0,3),Vector2(24,28),Color("#4e9f85"),Color("#3c7361"),2.3)
			Art.oval(v,Vector2(-3,-1),Vector2(20,23),Color("#96d9b5"))
			Art.oval(v,Vector2(-10,-12),Vector2(6,9),Color("#d8f6d5"))
			Art.oval(v,Vector2(13,-2),Vector2(3,4),Color("#bceac9"))
			Art.eye(v,Vector2(-3,2))
			Art.eye(v,Vector2(12,1),0.9)
			Shape.curve(v,Vector2(0,14),Vector2(4,17),Vector2(9,16),Vector2(12,13),Color("#3c7361"),2)
			for i in 5:
				var a := PI*i/4.0
				Art.part(v,"succulent_front_%d"%i)
				petal(v,Vector2(cos(a)*37,23+sin(a)*20),Vector2(0,19),Color("#7fcba3") if i%2==0 else Color("#a2d8ad"))
			Art.part(v,"droplet")
			# 黏液只点缀叶尖，透明高光保留肉质叶片的厚度。
			Shape.curve(v,Vector2(29,24),Vector2(30,29),Vector2(34,33),Vector2(31,36),Color("#559e84"),4)
			Art.oval(v,Vector2(31,35),Vector2(3,4),Color("#c3ecd0"),Color("#64aa8d"),1)
			Art.oval(v,Vector2(30,33),Vector2(1,1.5),Color("#f1ffe7"))
		"squash":
			var outline := PackedVector2Array()
			var nodes := [Vector2(-8,-35),Vector2(-25,-16),Vector2(-37,10),Vector2(-25,33),Vector2(0,38),Vector2(28,31),Vector2(37,9),Vector2(25,-17),Vector2(9,-36)]
			# 平滑的上窄下宽瓜体，保留鼓起的左右瓜瓣。
			for i in nodes.size():
				var p: Vector2 = nodes[i]
				var next: Vector2 = nodes[(i+1)%nodes.size()]
				var prev: Vector2 = nodes[(i-1+nodes.size())%nodes.size()]
				var after: Vector2 = nodes[(i+2)%nodes.size()]
				for j in 8: outline.append(p.bezier_interpolate(p+(next-prev)/6,next-(after-p)/6,next,j/8.0))
			v.draw_colored_polygon(outline,Color("#669343"))
			outline.append(outline[0])
			v.draw_polyline(outline,Color("#426336"),2.5,true)
			Art.oval(v,Vector2(-5,1),Vector2(24,33),Color("#95b958"))
			Art.oval(v,Vector2(-11,-8),Vector2(11,23),Color("#b1cb76"))
			Shape.curve(v,Vector2(-21,-16),Vector2(-30,2),Vector2(-30,20),Vector2(-18,28),Color("#527d3b"),2.5)
			Shape.curve(v,Vector2(13,-26),Vector2(23,-5),Vector2(25,18),Vector2(18,29),Color("#789f49"),3)
			Shape.curve(v,Vector2(-3,-32),Vector2(-4,-45),Vector2(9,-45),Vector2(12,-48),Color("#426336"),7)
			Shape.curve(v,Vector2(-3,-33),Vector2(-3,-43),Vector2(7,-43),Vector2(11,-46),Color("#7d9d50"),3)
			Art.oval(v,Vector2(-8,-7),Vector2(9,7),Color("#f4f2cf"))
			Art.oval(v,Vector2(13,-8),Vector2(8,7),Color("#f4f2cf"))
			Art.eye(v,Vector2(-4,-6),0.75)
			Art.eye(v,Vector2(16,-7),0.75)
			v.draw_line(Vector2(-20,-18),Vector2(0,-11),Color("#385533"),5,true)
			v.draw_line(Vector2(5,-12),Vector2(24,-20),Color("#385533"),5,true)
			Shape.curve(v,Vector2(-19,0),Vector2(-14,4),Vector2(-9,5),Vector2(-4,3),Color("#7a9c4b"),2)
			Shape.curve(v,Vector2(8,3),Vector2(15,5),Vector2(20,3),Vector2(23,0),Color("#6c9143"),2)
			Shape.curve(v,Vector2(-8,19),Vector2(0,10),Vector2(9,11),Vector2(19,17),Color("#426336"),3)
		"bbq_mushroom":
			# 小菌柄扎根于叶座，帽沿遮住上端。
			Art.leaf(v,Vector2(-25,33),Vector2(0,40),Color("#718e45"))
			Art.leaf(v,Vector2(25,34),Vector2(0,40),Color("#91aa56"))
			Art.oval(v,Vector2(0,21),Vector2(16,20),Color("#9a6344"),Color("#62422f"),2.4)
			Art.oval(v,Vector2(-4,19),Vector2(11,16),Color("#d59b64"))
			# 菌盖先画弧顶再画下沿，炭烤格纹沿弧面弯曲。
			Art.part(v,"cap")
			Art.oval(v,Vector2(0,-9),Vector2(38,29),Color("#b64b35"),Color("#743c2d"),2.5)
			Art.oval(v,Vector2(-4,-14),Vector2(32,22),Color("#e9874e"))
			Art.oval(v,Vector2(-15,-24),Vector2(12,5),Color("#f5b96e"))
			for y in [-20.0,-7.0]:
				Shape.curve(v,Vector2(-28,y),Vector2(-10,y+6),Vector2(14,y+5),Vector2(29,y-2),Color("#995333"),2.5)
			for x in [-13.0,3.0,18.0]:
				Shape.curve(v,Vector2(x,-31),Vector2(x-4,-23),Vector2(x-3,-9),Vector2(x+4,1),Color("#995333"),2.5)
			for p in [Vector2(-22,-12),Vector2(-3,-24),Vector2(14,-13),Vector2(23,-3)]:
				Art.oval(v,p,Vector2(2.3,1.5),Color("#f4b16a"))
			Art.oval(v,Vector2(0,7),Vector2(36,8),Color("#f2b574"),Color("#a45b37"),2)
			for x in [-24,-12,0,12,24]: v.draw_line(Vector2(x,4),Vector2(x*0.8,11),Color("#c78550"),1.4,true)
			Art.part(v,"body")
			Art.eye(v,Vector2(-3,22),0.85)
			Art.eye(v,Vector2(9,22),0.8)
			Shape.curve(v,Vector2(0,31),Vector2(3,28),Vector2(6,28),Vector2(10,30),Color("#62422f"),2)
			Shape.curve(v,Vector2(21,-31),Vector2(27,-33),Vector2(28,-39),Vector2(25,-43),Color("#73513c"),3)
			Art.part(v,"ember")
			Art.oval(v,Vector2(25,-44),Vector2(4,5),Color("#ffcf67"))
			Art.oval(v,Vector2(25,-46),Vector2(2,3),Color("#fff1bd"))
	v.draw_set_transform_matrix(parent)

static func petal(v, tip: Vector2, root: Vector2, color: Color) -> void:
	var d := tip-root
	var n := Vector2(-d.y,d.x).normalized()*13
	var end := tip-d.normalized()*3
	var points := PackedVector2Array()
	# 圆钝叶尖、外鼓叶腹，避免看起来像普通草叶。
	for i in 13: points.append(root.bezier_interpolate(root+d*0.35+n*1.3,end+n,tip,i/12.0))
	for i in 13: points.append(tip.bezier_interpolate(end-n,root+d*0.35-n*1.3,root,i/12.0))
	v.draw_colored_polygon(points,color)
	points.append(points[0])
	v.draw_polyline(points,Color("#528a6c"),1.7,true)
	Shape.curve(v,root+d*0.25-n*0.35,root+d*0.5-n*0.5,end-n*0.3,tip-d*0.13,color.lightened(0.24),2.5)
