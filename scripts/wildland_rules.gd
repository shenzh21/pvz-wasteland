extends RefCounted

static func update_wind(game, delta: float) -> void:
	if not game.is_wildland_level(): return
	game.sand_buff = maxf(0.0,game.sand_buff-delta)
	game.sand_clock -= delta
	if game.sand_clock>0.0: return
	game.sand_clock += 45.0
	game.sand_buff = 5.0
	for row in range(game.ROWS):
		var rightmost = null
		for p in game.plants:
			if not p.dead and p.row==row and (rightmost==null or p.col>rightmost.col): rightmost = p
		if rightmost==null: continue
		var inner = game.get_plant(rightmost.col,row)
		if inner!=null and inner.kind=="wind_grass": continue
		var target = game.get_pumpkin(rightmost.col,row)
		if target==null: target = rightmost
		if target.kind in ["cherry","bbq_mushroom"]: continue
		if target.kind=="squash" and int(target.get("squash_phase",0))>0: continue
		target.hp -= 300.0
		if target.hp<=0.0: target.dead = true
		game.burst(game.cell_center(target.col,row),Color("#d9c28a"),9)
	game.play_sfx(95.0,0.6,0.22,"noise")

static func attack_grass(game, plant: Dictionary) -> void:
	if plant.timer>0.0: return
	# 以格子边界计：左侧1格 + 自身1格 + 右侧1.5格。
	var left: float = game.BOARD_X+(plant.col-1)*game.CELL_W
	var right: float = game.BOARD_X+(plant.col+2.5)*game.CELL_W
	var target = null
	for z in game.zombies:
		if not z.dead and not game.zombie_is_airborne(z) and z.row==plant.row and z.x>=left and z.x<right:
			if target==null or z.x<target.x: target = z
	if target==null: return
	game.damage_zombie(target,game.PLANT_DATA.wind_grass.damage)
	plant.timer = game.PLANT_DATA.wind_grass.interval
	plant.wind_attack = 0.16
	game.burst(Vector2(target.x,game.cell_center(plant.col,plant.row).y),Color("#d5df82"),3)

static func update_giant(game, z: Dictionary, delta: float, rooted: bool) -> bool:
	if float(z.get("giant_follow",0.0))>0.0:
		z.giant_follow = maxf(0.0,float(z.giant_follow)-delta)
		z.walking = false
		z.biting = false
		return true
	if rooted:
		z.giant_throw_time = 0.0
		z.smash_time = 0.0
		return false
	var elapsed := float(z.get("giant_throw_time",0.0))
	if not z.get("imp_thrown",false) and (elapsed>0.0 or (z.hp>=1000.0 and z.hp<=1500.0 and z.x>=game.BOARD_X+4*game.CELL_W)):
		if elapsed==0.0:
			var row := int(z.row)
			if not game.is_plantable_cell(row):
				var choices: Array[int] = []
				for next_row in [row-1,row+1]:
					if next_row>=0 and next_row<game.ROWS and game.is_plantable_cell(next_row): choices.append(next_row)
				row = choices[game.rng.randi_range(0,choices.size()-1)]
			z.imp_target_row = row
		z.walking = false
		z.biting = false
		z.smash_time = 0.0
		z.giant_throw_time = elapsed+delta
		if z.giant_throw_time>=1.1:
			z.imp_thrown = true
			z.giant_follow = 0.3
			game.spawn_zombie(int(z.imp_target_row),"imp",z.x)
			var imp: Dictionary = game.zombies[-1]
			imp.x = z.x
			imp.airborne = true
			imp.imp_flight = 0.0
			imp.flight_start = game.WildlandArt.rider_position(game,z)
			imp.flight_finish = game.cell_center(2,int(z.imp_target_row))-Vector2(0,game.ZOMBIE_BOARD_LIFT)
			imp.draw_y = imp.flight_start.y
			imp.draw_scale = 0.65
			game.play_sfx(210.0,0.15,0.16,"sweep_down")
		return true
	var target = game.plant_at_zombie(z)
	if target==null:
		z.smash_time = 0.0
		return false
	z.walking = false
	z.biting = false
	z.smash_time = float(z.get("smash_time",0.0))+delta
	if z.smash_time>=1.25:
		# 巨人的砸击不同于篮球：同时砸毁南瓜和内部植物，仍保留无敌规则。
		if target.kind=="pumpkin":
			var inner = game.get_plant(target.col,target.row)
			if inner!=null and inner.kind not in ["cherry","bbq_mushroom"] and not (inner.kind=="squash" and int(inner.get("squash_phase",0))>0):
				inner.dead = true
				inner.hp = 0.0
		target.dead = true
		target.hp = 0.0
		z.smash_time = 0.0
		game.shake = 3.0
		game.burst(game.cell_center(target.col,target.row),Color("#b6a16f"),12)
		game.play_sfx(82.0,0.2,0.25,"noise")
	return true

static func update_flying_imp(game, z: Dictionary, delta: float) -> void:
	z.imp_flight += delta
	var t := clampf(float(z.imp_flight)/0.9,0.0,1.0)
	var pos: Vector2 = z.flight_start.lerp(z.flight_finish,t)+Vector2(0,-150.0*4.0*t*(1.0-t))
	z.x = pos.x
	z.draw_y = pos.y
	z.draw_scale = lerpf(0.65,1.0,t)
	z.walking = false
	z.biting = false
	z.rooted = false
	if t>=1.0:
		z.airborne = false
		z.erase("draw_y")
		z.walking = true
		game.burst(pos,Color("#c5b57c"),7)
