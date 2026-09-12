extends RefCounted

static func attack(game, plant: Dictionary) -> void:
	if plant.timer>0.0: return
	var center: Vector2 = game.cell_center(plant.col,plant.row)
	var target = null
	for z in game.zombies:
		if not z.dead and z.row==plant.row and z.x>=center.x:
			if target==null or z.x<target.x: target = z
	if target==null: return
	var start := center+Vector2(0,-34)
	var finish: Vector2 = game.zombie_display_position(target)
	game.projectiles.append({"pepper":true,"row":plant.row,"target":target,"start":start,"finish":finish,
		"x":start.x,"y":start.y,"elapsed":0.0,"duration":0.9,"dead":false})
	plant.timer = game.PLANT_DATA.sky_pepper.interval

static func update_projectile(game, projectile: Dictionary, delta: float) -> void:
	projectile.elapsed += delta
	var target: Dictionary = projectile.target
	# 原目标死亡后仍落在最后记录的位置，不凭空消失或改追其他目标。
	if not target.dead:
		projectile.finish = game.zombie_display_position(target)
		projectile.row = target.row
	var t := clampf(float(projectile.elapsed)/float(projectile.duration),0.0,1.0)
	var point: Vector2 = projectile.start.lerp(projectile.finish,t)+Vector2(0,-130.0*4.0*t*(1.0-t))
	projectile.x = point.x
	projectile.y = point.y
	if t<1.0: return
	projectile.dead = true
	var col := floori((point.x-game.BOARD_X)/game.CELL_W)
	if col>=0 and col<game.COLS:
		game.pepper_fires.append({"col":col,"row":int(projectile.row),"life":0.5})
	# 总宽一格：落点左右各半格；伤害只结算一次。
	for z in game.zombies:
		if not z.dead and z.row==projectile.row and absf(z.x-point.x)<=game.CELL_W*0.5:
			z.slow = 0.0
			game.damage_zombie(z,game.PLANT_DATA.sky_pepper.damage)
	game.burst(point,Color("#ef7938"),14)
	game.play_sfx(165.0,0.12,0.12,"noise")

static func update_effects(game, delta: float) -> void:
	for i in range(game.pepper_fires.size()-1,-1,-1):
		game.pepper_fires[i].life -= delta
		if game.pepper_fires[i].life<=0.0: game.pepper_fires.remove_at(i)
