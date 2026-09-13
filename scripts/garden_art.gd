extends RefCounted

# 轻量卡通素材层：局部坐标绘制，复用于战场、卡片与图鉴。
const KINDS := ["sunflower", "pea", "snow", "short_pea", "energy_pea", "wall"]
const INK := Color("#315c3d")
const CachedArt := preload("res://scripts/cached_plant_art.gd")

# 烘焙器记录分层；正常游戏直接复用贴图，不重新计算曲线。
static func part(v, name: String) -> void:
	if v.has_method("begin_art_part"): v.begin_art_part(name)

static func oval(v, center: Vector2, radius: Vector2, color: Color, edge := Color.TRANSPARENT, width := 2.0) -> void:
	var points := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	v.draw_colored_polygon(points, color)
	if edge.a > 0.0:
		points.append(points[0])
		v.draw_polyline(points, edge, width, true)

static func leaf(v, tip: Vector2, root: Vector2, color: Color) -> void:
	var d := tip-root
	var n := Vector2(-d.y,d.x).normalized()*9.0
	var p := PackedVector2Array()
	for i in 13:
		var t := i/12.0
		p.append(root.bezier_interpolate(root+d*0.2+n*1.5,root+d*0.7+n,tip,t))
	for i in 13:
		var t := i/12.0
		p.append(tip.bezier_interpolate(root+d*0.7-n,root+d*0.2-n*1.5,root,t))
	v.draw_colored_polygon(p,color)
	p.append(p[0])
	v.draw_polyline(p,INK,1.8,true)
	v.draw_line(root,tip*0.9+root*0.1,color.lightened(0.27),1.7,true)

static func eye(v, p: Vector2, size := 1.0, blink := false) -> void:
	if v.has_method("begin_art_part"):
		v.push_eye_part()
		blink = v.force_blink
	draw_eye(v,p,size,blink)
	if v.has_method("begin_art_part"): v.pop_eye_part()

static func draw_eye(v, p: Vector2, size: float, blink: bool) -> void:
	if blink:
		v.draw_line(p-Vector2(3,0)*size,p+Vector2(3,0)*size,Color("#263e30"),2*size,true)
		return
	oval(v,p,Vector2(3.5,5.5)*size,Color("#263e30"))
	oval(v,p+Vector2(-0.7,-1.8)*size,Vector2(1.2,1.7)*size,Color("#fffce7"))

static func plant(v, kind: String, pos: Vector2, size: float, time := 0.0, pulse := 0.0) -> void:
	if not v.has_method("begin_art_part"):
		CachedArt.draw(v,kind,pos,size,time,pulse)
		return
	var parent: Transform2D = v.art_parent_transform
	var local := parent*Transform2D(0.0,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO)
	v.draw_set_transform_matrix(local)
	part(v,"shadow")
	oval(v,Vector2(0,39),Vector2(30,7),Color(0.12,0.24,0.12,0.17))
	var breath := sin(time*2.1)*0.012
	var blink := fposmod(time,4.7)>4.52
	# 以根部为轴轻微呼吸，影子不随身体变形。
	v.draw_set_transform_matrix(local*Transform2D(0,Vector2(0,38))*Transform2D(Vector2(1-breath,0),Vector2(0,1+breath),Vector2.ZERO)*Transform2D(0,Vector2(0,-38)))
	part(v,"body")
	if kind=="wall":
		oval(v,Vector2(0,3),Vector2(32,35),Color("#945529"),Color("#633e28"),3)
		oval(v,Vector2(-2,0),Vector2(28,31),Color("#d69a52"))
		oval(v,Vector2(-10,-11),Vector2(14,17),Color("#e8b66d"))
		for i in 8:
			var p := Vector2(-19+posmod(i*17,38),-23+posmod(i*23,53))
			v.draw_arc(p,4,0.4,2.2,6,Color("#b87a3e"),1.5,true)
		# 面部整体右移，远眼更窄，形成朝右的三分之四侧脸。
		eye(v,Vector2(3,-3),1.15,blink)
		eye(v,Vector2(21,-4),0.9,blink)
		v.draw_arc(Vector2(14,10),6,0.15,PI-0.15,12,Color("#70432c"),2,true)
	else:
		var low := kind=="short_pea"
		if not low:
			v.draw_line(Vector2(0,6),Vector2(0,38),INK,9,true)
			v.draw_line(Vector2(-1,6),Vector2(-1,36),Color("#65aa49"),5,true)
		part(v,"leaf_left")
		leaf(v,Vector2(-32,(18 if not low else 27)+sin(time*2.7)*2),Vector2(0,35),Color("#6fac48"))
		part(v,"leaf_right")
		leaf(v,Vector2(31,(17 if not low else 27)+sin(time*2.7+1.2)*2),Vector2(0,37),Color("#87c957"))
		part(v,"head")
		if kind=="sunflower":
			part(v,"petals")
			for i in 12:
				var a := TAU*i/12.0+sin(time*1.8)*0.045
				var p := Vector2(cos(a),sin(a))*25.0+Vector2(0,-7)
				oval(v,p,Vector2(10,12),Color("#efac32"),Color("#ac712e"),1.8)
				oval(v,p+Vector2(-1,-3),Vector2(7,8),Color("#ffda59"))
			part(v,"head")
			oval(v,Vector2(0,-7),Vector2(22,23),Color("#87502f"),Color("#79492f"),2.5)
			oval(v,Vector2(-2,-10),Vector2(19,19),Color("#b57b43"))
			for p in [Vector2(-13,-20),Vector2(-7,-25),Vector2(2,-26),Vector2(12,-20)]:
				oval(v,p,Vector2(1.2,1.5),Color("#d5a361"))
			eye(v,Vector2(-8,-9),1.0,blink)
			eye(v,Vector2(8,-9),1.0,blink)
			if pulse>0:
				v.draw_arc(Vector2(0,-7),37+(1-pulse)*8,0,TAU,32,Color(1,0.9,0.45,pulse*0.45),2,true)
			oval(v,Vector2(-14,0),Vector2(4,2),Color("#dc9963"))
			oval(v,Vector2(14,0),Vector2(4,2),Color("#dc9963"))
			v.draw_arc(Vector2(0,-1),7,0.15,PI-0.15,12,Color("#553826"),2,true)
		else:
			var c := Color("#84cdea") if kind=="snow" else Color("#49af80") if kind=="energy_pea" else Color("#91d454")
			var h := Vector2(-3-pulse*4,(8 if low else -9)+sin(time*2.1)*0.8)
			oval(v,h,Vector2(25,24),c.darkened(0.18),INK,2.5)
			oval(v,h+Vector2(-3,-4),Vector2(21,19),c)
			oval(v,h+Vector2(-10,-12),Vector2(8,4),c.lightened(0.38))
			# 管口有外沿、内壁与暗膛，不再是粘在头侧的一颗圆球。
			v.draw_style_box(muzzle_style(c),Rect2(h+Vector2(12,-11),Vector2(24,21)))
			oval(v,h+Vector2(34,-1),Vector2(8,12),c.lightened(0.15),INK,2.2)
			oval(v,h+Vector2(35,-1),Vector2(4.5,7.5),Color("#284c40"))
			v.draw_arc(h+Vector2(35,-1),5,-1.4,0.5,8,c.darkened(0.2),1.8,true)
			eye(v,h+Vector2(-5,-5),1.15,blink)
			if kind!="snow": leaf(v,h+Vector2(-26,-26),h+Vector2(-13,-18),c.darkened(0.15))
			if kind=="snow":
				# 冰晶向后展开，带切面和暗边，避免三根相同白三角。
				for spec in [Vector3(-18,-29,-0.55),Vector3(-9,-35,-0.2),Vector3(1,-29,0.25)]:
					var center := h+Vector2(spec.x,spec.y)
					var crystal := PackedVector2Array()
					for point in [Vector2(-5,9),Vector2(-5,-4),Vector2(0,-11),Vector2(6,-3),Vector2(5,9)]:
						crystal.append(center+point.rotated(spec.z))
					v.draw_colored_polygon(crystal,Color("#bdeaf5"))
					crystal.append(crystal[0])
					v.draw_polyline(crystal,Color("#568fa8"),1.5,true)
					v.draw_line(center+Vector2(0,-8).rotated(spec.z),center+Vector2(0,7).rotated(spec.z),Color("#f2fdff"),2,true)
			if kind=="energy_pea":
				v.draw_arc(h,31,-2.5,2.4,32,Color("#b6ffd1"),3,true)
				part(v,"effect")
				for a in [-2.2,-1.0,1.2]:
					var p := h+Vector2(cos(a+time*0.6),sin(a+time*0.6))*31
					oval(v,p,Vector2(3,3),Color("#f1ffba"))
	v.draw_set_transform_matrix(parent)

static var mouth_styles: Dictionary = {}

static func muzzle_style(c: Color) -> StyleBoxFlat:
	if not mouth_styles.has(c):
		var style := StyleBoxFlat.new()
		style.bg_color = c
		style.border_color = INK
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		mouth_styles[c] = style
	return mouth_styles[c]

static func terrain(v, origin: Vector2, row: int, col: int, dirt: bool, wild: bool) -> void:
	# 坐标散列形成固定纹理：不逐帧随机，也不改变游戏随机数序列。
	var dark := Color("#9a8559") if wild else Color("#ac793e") if dirt else Color("#4b9b43")
	var light := Color("#d8c693") if wild else Color("#e3b878") if dirt else Color("#a5da70")
	v.draw_rect(Rect2(origin+Vector2(1,1),Vector2(118,5)),Color(light,0.22))
	for i in 5:
		var p := origin+Vector2(9+posmod(col*31+row*53+i*43,99),14+posmod(col*47+row*29+i*31,77))
		if dirt:
			v.draw_polyline(PackedVector2Array([p+Vector2(-7,0),p,p+Vector2(5,3),p+Vector2(11,1)]),Color(dark,0.32),1.5,true)
			if i%2==0:
				oval(v,p+Vector2(4,-2),Vector2(3,2),light.darkened(0.1))
		else:
			v.draw_line(p,p+Vector2(-3,-5),Color(dark,0.34),1.5,true)
			v.draw_line(p,p+Vector2(2,-7),Color(light,0.5),1.5,true)
			v.draw_line(p,p+Vector2(5,-3),Color(dark,0.3),1.5,true)
	if dirt:
		for i in 6:
			if posmod(col*13+i*7+row,5)<2: continue
			var x := origin.x+8+i*20+posmod(col*7+i*3,9)
			v.draw_line(Vector2(x,origin.y+2),Vector2(x+3,origin.y+5+posmod(i+col,4)),Color("#779b48") if not wild else Color("#99975d"),3,true)
