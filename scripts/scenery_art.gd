extends RefCounted

# 仅供开发期背景烘焙：散布由坐标决定，不消费战斗随机数。
const Art := preload("res://scripts/garden_art.gd")
const Shape := preload("res://scripts/plant_batch2_art.gd")

static func stone(v, p: Vector2, size: float, wild: bool) -> void:
	var ink := Color("#85764f") if wild else Color("#827558")
	var light := Color("#d7c79a") if wild else Color("#bdb395")
	Art.oval(v,p+Vector2(2,3)*size,Vector2(12,4)*size,Color(0.23,0.22,0.13,0.15))
	v.draw_colored_polygon(PackedVector2Array([p+Vector2(-12,1)*size,p+Vector2(-8,-6)*size,p+Vector2(1,-8)*size,p+Vector2(11,-3)*size,p+Vector2(13,3)*size,p+Vector2(5,6)*size,p+Vector2(-9,5)*size]),ink)
	v.draw_colored_polygon(PackedVector2Array([p+Vector2(-10,0)*size,p+Vector2(-7,-5)*size,p+Vector2(1,-6)*size,p+Vector2(9,-2)*size,p+Vector2(4,1)*size]),light)

static func tuft(v, p: Vector2, scale: float, wild: bool) -> void:
	var dark := Color("#7e854e") if wild else Color("#5b8e48")
	var light := Color("#c5bf7f") if wild else Color("#b0ce78")
	for i in 3:
		var tip := p+Vector2(-5+i*5,-5-((i+1)%3)*2)*scale
		Shape.curve(v,p,p+Vector2(-1,-3)*scale,tip+Vector2(2,1)*scale,tip,dark,2*scale)
	v.draw_line(p+Vector2(0,-1)*scale,p+Vector2(1,-7)*scale,light,1.5*scale,true)

static func draw(v, extended: bool) -> void:
	var wild: bool = v.is_wildland_level()
	var wasteland: bool = v.is_wasteland_level()
	var width: float = v.W+(650 if extended else 0)
	var soil := Color("#b6a078") if wild else Color("#bc955e") if wasteland else Color("#a9bf7d")
	v.draw_rect(Rect2(0,0,width,v.H),soil)
	# 远景只占草坪上方，不遮挡第一行的角色和血条。
	if wild:
		v.draw_rect(Rect2(0,90,width,60),Color("#cabc93"))
		for i in 9:
			var x := float(i*270-100)
			v.draw_colored_polygon(PackedVector2Array([Vector2(x,138),Vector2(x+90,109+i%3*4),Vector2(x+180,116),Vector2(x+300,145)]),Color("#ad9e78"))
			Shape.curve(v,Vector2(x+90,118),Vector2(x+142,119),Vector2(x+173,137),Vector2(x+255,139),Color("#dbcca3"),3)
	else:
		v.draw_rect(Rect2(0,90,width,53),Color("#829953") if wasteland else Color("#668b49"))
		for i in int(width/53)+1:
			var x := float(i*53)
			Art.oval(v,Vector2(x+25,101+posmod(i*17,11)),Vector2(35,19),Color("#94a960") if wasteland else Color("#82a85c"))
		for x in range(178,int(width),74):
			if wasteland and posmod(x,5)<2: continue
			var h := 29.0 if not wasteland else 18.0+posmod(x,15)
			v.draw_colored_polygon(PackedVector2Array([Vector2(x,139),Vector2(x,139-h),Vector2(x+6,135-h),Vector2(x+13,139-h),Vector2(x+13,139)]),Color("#c1b78a") if wasteland else Color("#e0d7af"))
		v.draw_line(Vector2(165,128),Vector2(width,128),Color("#a09167") if wasteland else Color("#c5b98e"),5)
	# 房屋与窄石径；操作栏仍在其上，不占种植格。
	v.draw_rect(Rect2(0,140,165,580),Color("#ac9270"))
	for y in range(150,710,38):
		v.draw_style_box(slab(Color("#cabc94") if not wild else Color("#bcb08b")),Rect2(136,y,24,31))
	v.draw_rect(Rect2(0,140,132,580),Color("#9c8e68") if wild else Color("#b77454"))
	for y in range(153,720,28): v.draw_line(Vector2(0,y),Vector2(130,y),Color(0.3,0.25,0.17,0.24),2)
	v.draw_rect(Rect2(18,223,93,159),Color("#674e3b"))
	v.draw_rect(Rect2(27,232,75,139),Color("#87b4ad"))
	v.draw_line(Vector2(64,232),Vector2(64,373),Color("#e0cba1"),5)
	v.draw_line(Vector2(27,302),Vector2(102,302),Color("#e0cba1"),5)
	if extended:
		var sx: float = v.BOARD_X+v.COLS*v.CELL_W
		v.draw_rect(Rect2(sx,140,685,580),Color("#b29c74") if wild else Color("#bca176") if wasteland else Color("#b6a27b"))
		# 候场区仍是泥地，不延伸草坪；石头与车辙错落分布。
		for i in 21:
			var p := Vector2(sx+24+posmod(i*191,630),163+posmod(i*137,518))
			stone(v,p,0.5+posmod(i*7,13)*0.06,wild)
		for i in 15:
			var x := sx+35+posmod(i*173,600)
			var y := 174+posmod(i*119,495)
			Shape.curve(v,Vector2(x,y),Vector2(x+21,y-5),Vector2(x+38,y+6),Vector2(x+65,y+3),Color(0.4,0.32,0.18,0.14),2)
		for i in 8: tuft(v,Vector2(sx+37+posmod(i*157,604),180+posmod(i*139,492)),1.7,wild)
	# 大块颜色保证读图，微小纹理只作辅衬。
	for row in v.ROWS:
		for col in v.COLS:
			var dirt: bool = wasteland and row%2==1
			var origin := Vector2(v.BOARD_X+col*v.CELL_W,v.BOARD_Y+row*v.CELL_H)
			var c := Color("#80b958") if (row+col)%2==0 else Color("#76ae50")
			if wasteland: c = (Color("#93b261") if (row+col)%2==0 else Color("#88a859")) if not dirt else (Color("#c6a06a") if col%2==0 else Color("#be9660"))
			if wild: c = (Color("#a3a56c") if col%2==0 else Color("#989c62")) if not dirt else (Color("#c5b182") if col%2==0 else Color("#bdaa7b"))
			v.draw_rect(Rect2(origin,Vector2(v.CELL_W,v.CELL_H)),c)
			v.draw_line(origin+Vector2(1,1),origin+Vector2(v.CELL_W-1,1),c.lightened(0.14),2)
			v.draw_line(origin+Vector2(v.CELL_W-1,1),origin+Vector2(v.CELL_W-1,v.CELL_H-1),c.darkened(0.06),1)
			v.draw_line(origin+Vector2(0,v.CELL_H-1),origin+Vector2(v.CELL_W,v.CELL_H-1),c.darkened(0.13),2)
			for i in 4:
				var p := origin+Vector2(13+posmod(col*31+row*17+i*37,91),17+posmod(row*41+col*23+i*29,75))
				if dirt:
					v.draw_polyline(PackedVector2Array([p-Vector2(8,1),p,p+Vector2(7,-4),p+Vector2(17,-2)]),c.darkened(0.13),1.2,true)
					if i%2==0: stone(v,p+Vector2(4,7),0.22,wild)
				else:
					Art.oval(v,p+Vector2(2,1),Vector2(10,2),Color(c.darkened(0.17),0.15))
					tuft(v,p,0.75,wild)
			if dirt:
				for i in 3:
					var p := origin+Vector2(15+posmod(col*43+i*31,95),3)
					v.draw_line(p,p+Vector2(2,4+posmod(i+col,4)),Color("#8b9c53") if not wild else Color("#939458"),3,true)
	var right: float = v.BOARD_X+v.COLS*v.CELL_W
	v.draw_rect(Rect2(v.BOARD_X,v.BOARD_Y-12,right-v.BOARD_X,12),Color("#8c7950") if wild else Color("#806a40"))
	v.draw_line(Vector2(v.BOARD_X,v.BOARD_Y-2),Vector2(right,v.BOARD_Y-2),Color("#b6bd79") if wild else Color("#b0cd79"),4)
	var bottom: float = v.BOARD_Y+v.ROWS*v.CELL_H
	v.draw_rect(Rect2(v.BOARD_X,bottom,right-v.BOARD_X,18),Color("#93835e") if wild else Color("#947447"))
	v.draw_line(Vector2(v.BOARD_X,bottom+1),Vector2(right,bottom+1),Color("#c6bc87") if wild else Color("#b2bf75"),3)
	for i in 41:
		var p := Vector2(v.BOARD_X+12+i*26,bottom+9+posmod(i*7,5))
		v.draw_line(p,p+Vector2(4,0),Color(0.9,0.8,0.55,0.25),2)

static var slab_style: StyleBoxFlat
static func slab(color: Color) -> StyleBoxFlat:
	if slab_style==null:
		slab_style = StyleBoxFlat.new()
		slab_style.set_corner_radius_all(4)
		slab_style.border_color = Color("#8d7d60")
		slab_style.set_border_width_all(2)
	slab_style.bg_color = color
	return slab_style
