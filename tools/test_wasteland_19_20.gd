extends SceneTree

const Data := preload("res://scripts/game_data.gd")
const Planner := preload("res://scripts/wave_planner.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var rng := RandomNumberGenerator.new()
	for level in [22,23]:
		var expected := ["normal","cone","bucket","basket","kart","camo"] if level==22 else ["normal","bucket","charger","glider","copper","basket"]
		var groups := 2 if level==22 else 3
		game.reset_game(level)
		assert(game.current_level==level and game.level_zombie_types()==expected)
		assert(Data.LEVEL_DATA[level].stage==level-3)
		assert(Data.LEVEL_DATA[level].plants==Data.LEVEL_DATA[21].plants)
		for seed_value in range(100):
			rng.seed = seed_value
			var plan := Planner.build(level,rng)
			assert(plan.size()==groups*10)
			assert(game.choose_preview_zombie() in expected)
			for group in range(groups):
				var seen := {}
				var score := 0
				for wave in plan.slice(group*10,(group+1)*10):
					for kind in wave:
						assert(kind in expected,"出现了阵容之外的僵尸")
						seen[kind] = true
						score += Data.ZOMBIE_POINTS[kind]
				assert(score==[42,88,157][group],"出怪预算不应改变")
				for kind in expected:
					assert(seen.has(kind),"每组应覆盖指定阵容")
	print("荒地第19、20关：100组随机种子验证通过")
	quit()
