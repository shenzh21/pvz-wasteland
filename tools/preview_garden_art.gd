extends SceneTree

class Sheet extends Node2D:
	var art_parent_transform := Transform2D.IDENTITY
	var time := 0.0
	func _process(delta: float) -> void:
		time += delta
		queue_redraw()
	func _draw() -> void:
		var art = load("res://scripts/garden_art.gd")
		draw_rect(Rect2(0,0,1280,720),Color("#e5edcd"))
		var names := ["向日葵","豌豆射手","寒冰射手","矮茎豌豆","聚能豆","坚果"]
		for i in art.KINDS.size():
			var x: float = 220.0+(i%3)*420
			var y: float = 160.0+(i/3 as int)*335
			var panel := StyleBoxFlat.new()
			panel.bg_color = Color("#f3f6dc")
			panel.set_corner_radius_all(24)
			draw_style_box(panel,Rect2(x-185,y-130,370,302))
			art.plant(self,art.KINDS[i],Vector2(x,y),2.05,time+float(i)*0.7)
			draw_string(ThemeDB.fallback_font,Vector2(x-150,y+137),names[i],HORIZONTAL_ALIGNMENT_CENTER,300,25,Color("#3d6243"))

func _init() -> void:
	call_deferred("capture")

func save_frame(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path)==OK)

func capture() -> void:
	var sheet := Sheet.new()
	root.add_child(sheet)
	if "--animate" in OS.get_cmdline_user_args():
		for frame in 240: await process_frame
		quit()
		return
	await save_frame("res://dist/garden-plants-preview.png")
	sheet.queue_free()
	await process_frame
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.collect_music_prewarm(true)
	game.reset_game(23)
	game.show_health_bars = false
	game.sun_points = 10000
	for row in [0,2,4]:
		game.place_plant("sunflower",0,row)
		game.place_plant("pea" if row==0 else "short_pea" if row==2 else "snow",1,row)
		game.place_plant("energy_pea",2,row)
		game.place_plant("wall",4,row)
	game.sun_points = 350
	game.particles.clear()
	game.queue_redraw()
	await save_frame("res://dist/garden-world-preview.png")
	quit()
