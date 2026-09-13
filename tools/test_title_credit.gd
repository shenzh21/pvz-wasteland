extends SceneTree

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.game_state = "title"
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://dist/title-credit-0.4.png")
	assert(error == OK)
	quit()
