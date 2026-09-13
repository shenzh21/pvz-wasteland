extends SceneTree

const Rules := preload("res://scripts/wildland_rules.gd")
var game
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _init() -> void:
	call_deferred("run")

func reset() -> void:
	game.reset_game(24)
	game.sun_points = 10000

func giant(row: int, hp: float, col := 5) -> Dictionary:
	game.spawn_zombie(row,"giant",900.0)
	var z: Dictionary = game.zombies[-1]
	z.x = game.cell_center(col,row).x
	z.hp = hp
	return z

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	reset()
	check(game.LEVEL_DATA[23].reward=="wind_grass","上一关应解锁防风草")
	check(game.level_zombie_types()==["normal","cone","giant"] and game.wave_plan.size()==20,"芜地第一关阵容和波数")
	check(game.ZOMBIE_POINTS.giant==7,"巨人为7分")
	for row in range(5): check(game.is_plantable_cell(row)==(row%2==0),"沿用荒地格子")
	for group in range(2):
		var seen := {}
		for wave in game.wave_plan.slice(group*10,(group+1)*10):
			for kind in wave:
				check(kind in ["normal","cone","giant"],"出怪不能越界")
				seen[kind] = true
		check(seen.has("giant"),"每大波组均有巨人")
	game.place_plant("wall",1,0)
	game.place_plant("wall",5,0)
	game.place_plant("pea",2,2)
	game.place_plant("wind_grass",5,2)
	game.place_plant("pea",5,4)
	game.place_plant("pumpkin",5,4)
	Rules.update_wind(game,45.0)
	check(game.get_plant(5,0).hp==4000.0 and game.sand_buff==0.0,"首次45秒沙风必须跳过")
	Rules.update_wind(game,44.9)
	check(game.get_plant(5,0).hp==4000.0,"90秒前不受伤")
	Rules.update_wind(game,0.11)
	check(game.get_plant(5,0).hp==3700.0 and game.get_plant(1,0).hp==4000.0,"只伤最右侧植物")
	check(game.get_plant(5,2).hp==300.0 and game.get_plant(2,2).hp==300.0,"防风草免疫并保护左侧")
	check(game.get_pumpkin(5,4).hp==3700.0 and game.get_plant(5,4).hp==300.0,"南瓜优先挡沙风")
	var z := giant(1,3000.0)
	var start_x := float(z.x)
	game.update_zombies(1.0)
	check(is_equal_approx(start_x-z.x,22.5),"沙风移动提速50%")
	Rules.update_wind(game,5.0)
	check(game.sand_speed_multiplier()==1.0,"5秒后恢复速度")
	Rules.update_wind(game,39.9)
	Rules.update_wind(game,0.1)
	check(game.get_plant(5,0).hp==3400.0,"后续沙风持续周期触发")
	reset()
	game.place_plant("wind_grass",3,2)
	var p: Dictionary = game.get_plant(3,2)
	p.timer = 0.0
	var left := giant(2,3000.0,3)
	var right := giant(2,3000.0,4)
	Rules.attack_grass(game,p)
	check(left.hp==2980.0 and right.hp==3000.0,"只攻击范围内最左目标")
	check(is_equal_approx(p.timer,1.42/3.0),"三倍攻击频率")
	left.x = game.BOARD_X+2*game.CELL_W
	right.x = game.BOARD_X+5.5*game.CELL_W-1.0
	p.timer = 0.0
	Rules.attack_grass(game,p)
	check(left.hp==2960.0 and right.hp==3000.0,"左侧一格边界内仍优先攻击最左目标")
	left.x -= 1.0
	p.timer = 0.0
	Rules.attack_grass(game,p)
	check(left.hp==2960.0 and right.hp==2980.0,"右侧一格半内可以攻击")
	right.x += 1.0
	p.timer = 0.0
	Rules.attack_grass(game,p)
	check(right.hp==2980.0 and left.hp==2960.0,"左右范围外不攻击")
	for test_hp in [999.0,1000.0,1500.0,1501.0]:
		reset()
		z = giant(1,test_hp)
		Rules.update_giant(game,z,0.1,false)
		var expected: bool = test_hp>=1000.0 and test_hp<=1500.0
		check((float(z.get("giant_throw_time",0.0))>0.0)==expected,"投掷生命范围")
		if expected:
			check(game.zombies.size()==1,"蓄力时小鬼仍在背上")
			Rules.update_giant(game,z,1.01,false)
			check(game.zombies.size()==2,"只投出一个小鬼")
			var imp: Dictionary = game.zombies[-1]
			check(imp.row in [0,2],"荒地行投向相邻草地行")
			check(imp.airborne,"小鬼飞行中不能啃咬")
			Rules.update_flying_imp(game,imp,0.9)
			check(not imp.airborne and is_equal_approx(imp.x,game.cell_center(2,imp.row).x),"小鬼落在第三格")
			Rules.update_giant(game,z,2.0,false)
			check(game.zombies.size()==2,"不得重复投小鬼")
	reset()
	z = giant(2,1200.0,3)
	check(not Rules.update_giant(game,z,0.1,false),"走过第五格不投掷")
	z.x = game.cell_center(5,2).x
	Rules.update_giant(game,z,0.1,false)
	game.damage_zombie(z,1800.0)
	game.update_zombies(2.0)
	check(game.zombies.size()==1,"蓄力期间死亡不产生小鬼")
	reset()
	game.place_plant("wall",3,2)
	p = game.get_plant(3,2)
	z = giant(2,3000.0,3)
	Rules.update_giant(game,z,0.5,false)
	check(not p.dead and p.hp==4000.0,"砸击必须有前摇")
	Rules.update_giant(game,z,0.76,false)
	check(p.dead,"落棒秒杀坚果")
	reset()
	game.place_plant("wall",3,2)
	game.place_plant("pumpkin",3,2)
	z = giant(2,3000.0,3)
	Rules.update_giant(game,z,1.26,false)
	check(game.get_plant(3,2)==null and game.get_pumpkin(3,2)==null,"巨人同时砸毁南瓜和内部植物")
	reset()
	# 两个防卫队向同一格派兵，走真实的目标选择与僵尸更新入口。
	game.place_plant("yam_guard",3,0)
	game.place_plant("yam_guard",3,2)
	var upper: Dictionary = game.get_plant(3,0)
	var lower: Dictionary = game.get_plant(3,2)
	upper.deploy_dir = 1
	lower.deploy_dir = -1
	game.yam_minions.clear()
	game.spawn_yam_minion(upper)
	game.spawn_yam_minion(lower)
	var first: Dictionary = game.yam_minions[0]
	var second: Dictionary = game.yam_minions[1]
	check(not first.has("kind"),"小红薯使用独立实体结构")
	z = giant(1,3000.0,3)
	game.update_zombies(0.5)
	check(not first.dead and not second.dead,"砸击小红薯也需要前摇")
	game.update_zombies(0.76)
	check(first.dead and first.hp==0.0 and not second.dead and second.hp==500.0,"只砸死同格最前面的小红薯")
	game.update_zombies(0.5)
	check(not second.dead,"第二个小红薯需要新的砸击前摇")
	game.update_zombies(0.76)
	check(second.dead and second.hp==0.0,"随后砸死第二个小红薯")
	check(not upper.dead and not lower.dead,"砸死小红薯不伤害防卫队本体")
	var previous_x := float(z.x)
	game.update_zombies(0.1)
	check(z.x<previous_x,"清除阻挡后巨人继续前进")
	print("芜地规则测试：",failures," 个失败")
	if "--capture" in OS.get_cmdline_user_args():
		reset()
		game.place_plant("sunflower",1,0)
		game.place_plant("wind_grass",4,0)
		game.place_plant("wind_grass",4,2)
		game.place_plant("wind_grass",4,4)
		for i in range(3):
			z = giant(i*2,[3000.0,1900.0,900.0][i],7)
			z.walking = false
		game.sand_buff = 4.0
		game.game_time = 46.0
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot_wildland_test/preview.png")
		game.zombies[0].smash_time = 0.7
		game.zombies[1].giant_throw_time = 0.65
		game.zombies[1].hp = 1200.0
		game.zombies[2].imp_thrown = true
		game.sand_buff = 0.0
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot_wildland_test/actions.png")
	quit(1 if failures>0 else 0)
