extends SceneTree

const Planner := preload("res://scripts/wave_planner.gd")

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.reset_game(26)
	var expected := ["normal","bucket","kart","charger","runner","giant"]
	assert(game.level_zombie_types()==expected and game.level_title(26)=="芜地-第3关")
	assert(game.sand_clock==90.0 and game.desired_music_track()=="wildland")
	assert(game.LEVEL_DATA[26].plants==game.LEVEL_DATA[25].plants)
	var rng := RandomNumberGenerator.new()
	for seed_value in range(100):
		rng.seed = seed_value
		var plan := Planner.build(26,rng)
		assert(plan.size()==30)
		assert(game.choose_preview_zombie() in expected)
		for group in range(3):
			var seen := {}
			var score := 0
			for wave in plan.slice(group*10,(group+1)*10):
				for kind in wave:
					assert(kind in expected)
					seen[kind] = true
					score += game.ZOMBIE_POINTS[kind]
			assert(score==[42,88,157][group])
			for kind in expected: assert(seen.has(kind))
	print("芜地第三关：100组随机种子、阵容和预算验证通过")
	if "--capture" in OS.get_cmdline_user_args():
		game.game_state = "level_select"
		game.unlocked_level = 26
		game.campaign_completed = false
		game.level_select_offset = 21
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot_map_test/preview.png")
	quit()
