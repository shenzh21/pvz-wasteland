extends SceneTree

var game
var failures := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.reset_game(21)
	game.sun_points = 10000
	check(game.wave_plan.size()==20,"新关卡应有20小波")
	for group in 2:
		var seen := {}
		for wave in game.wave_plan.slice(group*10,(group+1)*10):
			for kind in wave:
				check(kind in ["normal","cone","swing","basket"],"出怪阵容越界")
				seen[kind] = true
		check(seen.has("basket"),"每个大波组均应出现走步僵尸")
	game.place_plant("pea",3,2)
	var pea: Dictionary = game.get_plant(3,2)
	game.place_plant("pumpkin",3,2)
	var shell: Dictionary = game.get_pumpkin(3,2)
	check(pea!=null and shell!=null,"必须能套种")
	game.spawn_zombie(2,"basket",900.0)
	var z: Dictionary = game.zombies[-1]
	z.x = game.cell_center(3,2).x+300.0
	game.update_zombies(0.1)
	game.update_zombies(1.1)
	check(game.projectiles.is_empty() and z.throw_phase==1,"蓄力完成前不得出手")
	game.damage_zombie(z,400.0)
	game.update_zombies(1.0)
	check(game.projectiles.is_empty(),"出手前击杀必须打断")
	game.spawn_zombie(2,"basket",900.0)
	z = game.zombies[-1]
	z.x = game.cell_center(3,2).x+300.0
	game.update_zombies(0.1)
	game.update_zombies(1.21)
	check(game.projectiles.size()==1 and z.speed==15.0,"出手后必须只有一个球并降速")
	game.update_projectiles(0.4)
	var ball: Dictionary = game.projectiles[-1]
	check(ball.y<minf(ball.start.y,ball.finish.y),"篮球中途须有明显抛物线高度")
	game.update_projectiles(0.5)
	check(shell.hp==3700.0 and pea.hp==300.0,"篮球应优先伤南瓜，不伤内部植物")
	game.update_zombies(0.4)
	game.update_zombies(1.0)
	check(game.projectiles.size()==1,"出手后不能凭空再生篮球")
	z.x = game.cell_center(3,2).x+50.0
	check(game.plant_at_zombie(z)==shell,"南瓜碰撞应稍大并优先承伤")
	game.remove_plant_with_shovel(shell)
	check(game.get_pumpkin(3,2)==null and game.get_plant(3,2)==pea,"铲除外壳应保留内部植物")
	game.place_plant("pumpkin",4,0)
	game.place_plant("pea",4,0)
	check(game.get_pumpkin(4,0)!=null and game.get_plant(4,0)!=null,"先种壳再种植物也应兼容")
	game.place_plant("pumpkin",4,1)
	check(game.get_pumpkin(4,1)==null,"南瓜不得种在荒地")
	# 荒地行可以向两侧草地投球，落点必须使用目标行而不是投手行。
	for target_row in [0,2]:
		game.reset_game(21)
		game.sun_points = 10000
		game.place_plant("pea",3,target_row)
		pea = game.get_plant(3,target_row)
		game.spawn_zombie(1,"basket",900.0)
		z = game.zombies[-1]
		z.x = game.cell_center(3,target_row).x+361.0
		check(not game.update_basket_attack(z,0.1,false),"三列之外不得索敌")
		z.x = game.cell_center(3,target_row).x-1.0
		check(not game.update_basket_attack(z,0.1,false),"不得向身后索敌")
		z.x = game.cell_center(3,target_row).x+360.0
		check(game.update_basket_attack(z,0.1,false),"必须能向上下相邻行索敌")
		game.update_basket_attack(z,1.21,false)
		check(game.projectiles[-1].row==target_row,"篮球必须落在锁定的目标行")
		# 球出手后才补南瓜，也必须优先挡球，破壳不溢出伤害。
		game.place_plant("pumpkin",3,target_row)
		shell = game.get_pumpkin(3,target_row)
		shell.hp = 100.0
		game.update_projectiles(0.8)
		check(shell.dead and pea.hp==300.0,"跨行篮球应打破南瓜而不伤内部植物")
	game.reset_game(21)
	game.sun_points = 10000
	game.place_plant("pea",3,2)
	game.spawn_zombie(0,"basket",900.0)
	z = game.zombies[-1]
	z.x = game.cell_center(3,2).x+120.0
	check(not game.update_basket_attack(z,0.1,false),"不能投向相隔两行的植物")
	print("篮球与南瓜交互验证：",failures," 个失败")
	if "--capture" in OS.get_cmdline_user_args():
		game.reset_game(21)
		game.sun_points = 10000
		for i in 4:
			game.spawn_zombie(2,"basket",450+i*200)
			var actor: Dictionary = game.zombies[-1]
			actor.x = 450+i*200
			actor.throw_phase = 0 if i==0 else 1 if i<3 else 2
			actor.throw_time = 0.0 if i==0 else 0.65 if i==1 else 1.1
			actor.walking = false
		game.place_plant("pea",1,2)
		game.place_plant("pumpkin",1,2)
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot_basket_test/preview.png")
	quit(1 if failures>0 else 0)
