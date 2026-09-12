extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.money = 25000
	game.starting_sun_level = 0
	game.unlocked_level = 23
	game.purchase_starting_sun()
	assert(game.starting_sun_level==0 and game.money==25000)
	game.unlocked_level = 24
	game.purchase_starting_sun()
	assert(game.starting_sun_level==1 and game.money==15000)
	game.reset_game(1)
	assert(game.sun_points==250)
	game.purchase_starting_sun()
	assert(game.starting_sun_level==2 and game.money==3000)
	game.purchase_starting_sun()
	assert(game.starting_sun_level==2 and game.money==3000)
	game.starting_sun_level = 0
	game.load_save_game()
	assert(game.starting_sun_level==2)
	game.reset_game(24)
	assert(game.sun_points==350 and game.sand_clock==90.0)
	game.starting_sun_level = 0
	game.money = 9999
	game.purchase_starting_sun()
	assert(game.starting_sun_level==0 and game.money==9999)
	print("初始阳光升级：解锁、价格、上限、存档及开局数值验证通过")
	if "--capture" in OS.get_cmdline_user_args():
		game.game_state = "shop"
		game.money = 25000
		game.queue_redraw()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot_sun_test/shop.png")
	quit()
