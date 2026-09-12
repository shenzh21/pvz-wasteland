extends RefCounted

const ZombieArt := preload("res://scripts/zombie_art.gd")
const ImpArt := preload("res://scripts/imp_art.gd")
const GIANT_SCALE := 1.4

static func giant_origin(view, z: Dictionary) -> Vector2:
	var size := float(z.get("draw_scale",1.0))
	# 以脚底为缩放基准，不改变僵尸所处路线。
	return view.zombie_display_position(z)-Vector2(0,16)*size

static func rider_position(view, z: Dictionary) -> Vector2:
	var size := float(z.get("draw_scale",1.0))
	var t := clampf(float(z.get("giant_throw_time",0.0))/1.1,0.0,1.0)
	return giant_origin(view,z)+(Vector2(52,-33)+Vector2(-61,-88)*sin(t*PI*0.5))*size

static func grass(view, pos: Vector2, size: float, strike := 0.0) -> void:
	for i in range(7):
		var base := pos+Vector2((i-3)*6,35)*size
		var tip := pos+Vector2((i-3)*10+strike*75,-34+absi(i-3)*7)*size
		view.draw_colored_polygon(PackedVector2Array([base-Vector2(5,0)*size,tip,tip+Vector2(8,15)*size,base+Vector2(6,0)*size]),Color("#87934c") if i%2==0 else Color("#b3bd68"))
		view.draw_line(base,tip+Vector2(3,12)*size,Color("#d0d18a"),2*size)
	view.draw_circle(pos+Vector2(-8,7)*size,3*size,Color("#273c2a"))
	view.draw_circle(pos+Vector2(9,7)*size,3*size,Color("#273c2a"))
	view.draw_line(pos+Vector2(-9,0)*size,pos+Vector2(-2,3)*size,Color("#42552f"),3*size)
	view.draw_line(pos+Vector2(10,0)*size,pos+Vector2(3,3)*size,Color("#42552f"),3*size)

static func pepper(view, pos: Vector2, size: float, projectile := false, angle := 0.0) -> void:
	var parent: Transform2D = view.art_parent_transform
	view.draw_set_transform_matrix(parent*Transform2D(angle,pos)*Transform2D(Vector2(size,0),Vector2(0,size),Vector2.ZERO))
	if not projectile:
		view.draw_colored_polygon(PackedVector2Array([Vector2(0,35),Vector2(-31,18),Vector2(-26,36),Vector2(-5,40)]),Color("#508044"))
		view.draw_colored_polygon(PackedVector2Array([Vector2(0,36),Vector2(32,19),Vector2(26,36),Vector2(4,40)]),Color("#69964d"))
	view.draw_colored_polygon(PackedVector2Array([Vector2(-17,21),Vector2(-20,5),Vector2(-10,-17),Vector2(3,-39),Vector2(12,-46),Vector2(9,-24),Vector2(21,-2),Vector2(18,22),Vector2(5,31),Vector2(-7,29)]),Color("#773a2b"))
	view.draw_colored_polygon(PackedVector2Array([Vector2(-13,19),Vector2(-15,5),Vector2(-6,-15),Vector2(7,-34),Vector2(4,-22),Vector2(16,-2),Vector2(14,20),Vector2(4,25),Vector2(-6,24)]),Color("#e85632"))
	view.draw_line(Vector2(-8,9),Vector2(-2,-11),Color("#ffa45c"),4)
	view.draw_colored_polygon(PackedVector2Array([Vector2(-15,25),Vector2(-8,19),Vector2(0,25),Vector2(9,20),Vector2(17,25),Vector2(4,32)]),Color("#689d43"))
	view.draw_line(Vector2(2,30),Vector2(0,38),Color("#466d38"),5)
	if not projectile:
		view.draw_circle(Vector2(-6,7),3,Color("#302c22"))
		view.draw_circle(Vector2(9,7),3,Color("#302c22"))
		view.draw_line(Vector2(-5,17),Vector2(7,15),Color("#682c25"),2)
	view.draw_set_transform_matrix(parent)

static func pepper_fire(view, fire: Dictionary) -> void:
	var origin := Vector2(view.BOARD_X+fire.col*view.CELL_W,view.BOARD_Y+fire.row*view.CELL_H)
	var elapsed := 0.5-float(fire.life)
	var alpha := minf(float(fire.life)/0.15,1.0)
	view.draw_rect(Rect2(origin,Vector2(view.CELL_W,view.CELL_H)),Color(1.0,0.35,0.07,0.18*alpha))
	for i in range(9):
		var base := origin+Vector2(10+i*12,86+sin(i*2.3)*12)
		var height := 29.0+14.0*sin(elapsed*28.0+i*1.7)
		var sway := sin(elapsed*21.0+i)*7.0
		view.draw_colored_polygon(PackedVector2Array([base+Vector2(-9,0),base+Vector2(-11,-height*0.45),base+Vector2(sway,-height),base+Vector2(10,-height*0.3),base+Vector2(8,0)]),Color(0.96,0.32,0.09,alpha))
		view.draw_colored_polygon(PackedVector2Array([base+Vector2(-5,-1),base+Vector2(sway*0.5,-height*0.65),base+Vector2(5,-1)]),Color(1.0,0.79,0.21,alpha))

static func giant(view, z: Dictionary) -> void:
	var size := float(z.get("draw_scale",1.0))
	var pos := giant_origin(view,z)
	var body_size := size*GIANT_SCALE
	var broad := Transform2D(Vector2(1.6,0),Vector2(0,1),Vector2(-pos.x*0.6,0))
	var skeleton := ZombieArt.pose(z)
	var unit := ZombieArt.UNIT*body_size
	var base := Transform2D(Vector2(unit,0),Vector2(0,unit),pos-ZombieArt.ORIGIN*unit)
	# 小鬼坐在背篓里，抛出前随抬手动作离开后背。
	if not z.get("imp_thrown",false):
		var rider_pos := rider_position(view,z)
		view.draw_line(rider_pos+Vector2(-14,10)*size,pos+Vector2(6,-50)*size,Color("#a69570"),4*size)
		view.draw_line(rider_pos+Vector2(9,17)*size,pos+Vector2(37,23)*size,Color("#6d5b3f"),5*size)
		var rider := {"kind":"imp","anim":z.get("anim",0.0),"walking":false,"biting":false,"slow":0.0}
		ImpArt.draw(view,rider,rider_pos,size*0.65,view.art_parent_transform)
	ZombieArt.draw(view,z,pos,body_size,view.art_parent_transform*broad)
	# 破损补丁随躯干骨骼移动，分两个生命阶段追加。
	view.draw_set_transform_matrix(view.art_parent_transform*broad*base*skeleton.torso)
	var patches := 2 if float(z.hp)<1000.0 else 1 if float(z.hp)<2000.0 else 0
	for i in range(patches):
		var patch_pos := Vector2(139,178) if i==0 else Vector2(96,207)
		view.draw_rect(Rect2(patch_pos,Vector2(23,18)),Color("#baa779") if i==0 else Color("#8b9476"))
		for seam in range(4):
			view.draw_line(patch_pos+Vector2(seam*6,-2),patch_pos+Vector2(seam*6+3,5),Color("#433f32"),2)
	view.draw_set_transform_matrix(view.art_parent_transform*broad*base*skeleton.far_forearm)
	# 粗木棒握在手中，随抬手蓄力与下砸转动。
	view.draw_colored_polygon(PackedVector2Array([Vector2(87,233),Vector2(77,225),Vector2(8,281),Vector2(24,307),Vector2(40,300)]),Color("#30382b"))
	view.draw_colored_polygon(PackedVector2Array([Vector2(82,236),Vector2(77,232),Vector2(14,284),Vector2(26,301),Vector2(35,296)]),Color("#99815a"))
	view.draw_line(Vector2(22,282),Vector2(74,240),Color("#c0a571"),4)
	view.draw_line(Vector2(24,273),Vector2(43,292),Color("#a9ada0"),9)
	view.draw_circle(Vector2(29,280),3,Color("#505b4b"))
	view.draw_set_transform_matrix(view.art_parent_transform)
	if z.get("rooted",false): view.draw_rooted_effect(pos,size)
	if view.show_health_bars and not z.get("hide_bar",false):
		var bar_pos := pos+Vector2(-56,-112)*size
		bar_pos.y = maxf(94.0,bar_pos.y)
		view.draw_bar(bar_pos,112*size,float(z.hp)/float(z.max_hp),Color("#df6b54"))

static func terrain(view, cell: Vector2, row: int, col: int) -> void:
	# 固定种子式散布避免每帧随机，也避免石头、枯草排成整齐的线。
	for i in range(3):
		var p := cell+Vector2(12+posmod(col*37+row*19+i*43,94),14+posmod(col*23+row*41+i*29,79))
		if row%2==0:
			view.draw_line(p,p+Vector2(-5,-9),Color("#88864e"),2)
			view.draw_line(p,p+Vector2(3,-13),Color("#b4ae69"),2)
		else:
			view.draw_line(p,p+Vector2(14,-3),Color("#a78b5a"),2)
			view.draw_line(p+Vector2(14,-3),p+Vector2(21,2),Color("#a78b5a"),2)

static func wind(view) -> void:
	if view.sand_buff<=0.0 or view.game_state!="play": return
	view.draw_rect(Rect2(view.BOARD_X,90,view.W-view.BOARD_X,view.H-90),Color(0.85,0.74,0.45,0.13))
	for i in range(36):
		var x: float = view.BOARD_X+fposmod(float(i*137)-view.game_time*510.0,view.W-view.BOARD_X)
		var y := 125.0+posmod(i*79,560)
		view.draw_line(Vector2(x,y),Vector2(maxf(view.BOARD_X,x-30.0-float(i%4)*12),y+4),Color(0.94,0.86,0.59,0.5),2)
