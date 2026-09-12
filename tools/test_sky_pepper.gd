extends SceneTree

const Rules := preload("res://scripts/pepper_rules.gd")
const Planner := preload("res://scripts/wave_planner.gd")
var game
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _init() -> void:
	call_deferred("run")

func spawn(kind: String, x: float, row := 2) -> Dictionary:
	game.spawn_zombie(row,kind,x)
	var z: Dictionary = game.zombies[-1]
	z.x = x
	z.slow = 3.0
	return z

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.reset_game(25)
	game.sun_points = 10000
	check(game.LEVEL_DATA[24].reward=="sky_pepper","芜地第一关解锁")
	check(game.PLANT_DATA.sky_pepper.cost==200 and is_equal_approx(game.PLANT_DATA.sky_pepper.interval,2.13),"价格与攻速")
	var allowed := ["normal","cone","copper","camo","glider"]
	check(game.level_zombie_types()==allowed,"预览阵容")
	var rng := RandomNumberGenerator.new()
	for seed_value in range(30):
		rng.seed = seed_value
		var plan := Planner.build(25,rng)
		check(plan.size()==30,"三个大波组")
		for group in range(3):
			var seen := {}
			var points := 0
			for wave in plan.slice(group*10,(group+1)*10):
				for kind in wave:
					check(kind in allowed,"不混入其他僵尸")
					points += game.ZOMBIE_POINTS[kind]
					seen[kind] = true
			check(points==[42,88,157][group],"沿用现有预算")
			for kind in allowed: check(seen.has(kind),"阵容完整")
	game.place_plant("sky_pepper",2,2)
	var p: Dictionary = game.get_plant(2,2)
	p.timer = 0.0
	var camo := spawn("camo",700.0)
	var neighbor := spawn("normal",750.0)
	var outside := spawn("normal",761.0)
	var other_row := spawn("normal",700.0,1)
	var behind := spawn("normal",300.0)
	Rules.attack(game,p)
	check(game.projectiles.size()==1 and game.projectiles[-1].target==camo,"优先抛向同一行前方最近僵尸")
	game.update_projectiles(0.45)
	var shot: Dictionary = game.projectiles[-1]
	check(shot.y<minf(shot.start.y,shot.finish.y),"中途高抛")
	check(camo.hp==360.0,"落地前无伤害")
	game.update_projectiles(0.45)
	check(camo.hp==310.0 and neighbor.hp==140.0,"军迷及范围内目标一次50伤害")
	check(game.pepper_fires.size()==1 and game.pepper_fires[0].life==0.5,"命中格燃烧0.5秒")
	check(game.pepper_fires[0].col==floori((700.0-game.BOARD_X)/game.CELL_W) and game.pepper_fires[0].row==2,"火焰落在命中格")
	Rules.update_effects(game,0.49)
	check(game.pepper_fires.size()==1,"0.5秒前保留火焰")
	Rules.update_effects(game,0.02)
	check(game.pepper_fires.is_empty(),"0.5秒后移除火焰")
	check(camo.slow==0.0 and neighbor.slow==0.0,"火焰解除寒冰减速")
	check(outside.hp==190.0 and outside.slow==3.0 and other_row.hp==190.0 and behind.hp==190.0,"范围外不伤害不解冻")
	game.update_projectiles(1.0)
	check(camo.hp==310.0,"不得持续灼烧")
	game.zombies.clear()
	var glider := spawn("glider",850.0)
	p.timer = 0.0
	Rules.attack(game,p)
	game.update_projectiles(0.9)
	check(glider.hp==310.0 and glider.slow==0.0,"可命中空中滑翔伞")
	game.zombies.clear()
	var doomed := spawn("normal",800.0)
	p.timer = 0.0
	Rules.attack(game,p)
	game.damage_zombie(doomed,1000.0)
	neighbor = spawn("normal",820.0)
	game.update_projectiles(0.9)
	check(neighbor.hp==140.0,"原目标死亡后仍在落点结算")
	print("朝天椒与芜地第二关测试：",failures," 个失败")
	if "--capture" in OS.get_cmdline_user_args():
		game.reset_game(25)
		game.sun_points = 10000
		game.equipped_plants.assign(["sunflower","sky_pepper","wind_grass","pumpkin"])
		game.place_plant("sky_pepper",2,2)
		p = game.get_plant(2,2)
		p.timer = 0.0
		spawn("camo",900.0)
		Rules.attack(game,p)
		game.update_projectiles(0.9)
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot_pepper_test/preview.png")
	quit(1 if failures>0 else 0)
