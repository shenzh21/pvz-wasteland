extends SceneTree

class Sheet extends Node2D:
	var art_parent_transform := Transform2D.IDENTITY
	var time := 0.0
	var animated := false
	func _process(delta: float) -> void:
		if animated:
			time += delta
			queue_redraw()
	func _draw() -> void:
		var art = preload("res://scripts/plant_batch4_art.gd")
		var garden = preload("res://scripts/garden_art.gd")
		var names := ["南瓜头","防风草","朝天椒","南瓜头 · 套种效果"]
		var kinds := ["pumpkin","wind_grass","sky_pepper","pumpkin"]
		draw_rect(Rect2(0,0,1280,720),Color("#e5edcd"))
		for i in 4:
			var pos := Vector2(330+(i%2)*620,152+int(i/2)*335)
			var panel := StyleBoxFlat.new()
			panel.bg_color = Color("#f3f6dc")
			panel.set_corner_radius_all(24)
			draw_style_box(panel,Rect2(pos-Vector2(285,122),Vector2(570,302)))
			if i==3:
				art.pumpkin(self,pos,2.0,true,time)
				garden.plant(self,"pea",pos,2.0,time)
				art.pumpkin(self,pos,2.0,false,time)
			else:
				var interval := 1.42/3.0 if kinds[i]=="wind_grass" else 2.13
				var clock := fposmod(time,interval)
				var pulse := maxf(0,1-clock/(0.16 if i==1 else 0.2)) if animated else 0.0
				var charge := clampf((clock-(interval-0.18))/0.18,0,1) if animated else 0.0
				art.draw(self,kinds[i],pos,2.0,time,pulse,charge)
			draw_string(ThemeDB.fallback_font,pos+Vector2(-230,148),names[i],HORIZONTAL_ALIGNMENT_CENTER,460,25,Color("#3d6243"))

func _init() -> void: call_deferred("capture")

func capture() -> void:
	var sheet := Sheet.new()
	root.add_child(sheet)
	if "--animate" in OS.get_cmdline_user_args():
		sheet.animated = true
		for frame in 270: await process_frame
		quit()
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://dist/plant-batch4-static.png")==OK)
	quit()
