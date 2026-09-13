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
		var art = preload("res://scripts/plant_batch3_art.gd")
		var kinds := ["cactus","slime","squash","bbq_mushroom"]
		var names := ["仙人掌","粘液多肉","倭瓜","烧烤蘑菇"]
		draw_rect(Rect2(0,0,1280,720),Color("#e5edcd"))
		for i in 4:
			var x := 330.0+(i%2)*620
			var y := 164.0+(i/2 as int)*335
			var panel := StyleBoxFlat.new()
			panel.bg_color = Color("#f3f6dc")
			panel.set_corner_radius_all(24)
			draw_style_box(panel,Rect2(x-285,y-134,570,302))
			var cycle := fposmod(time,3.0)
			var pulse := maxf(0,1-fposmod(time,1.42)*5) if animated else 0.0
			var charge := clampf((cycle-2.1)/0.72,0,1) if animated and kinds[i]=="bbq_mushroom" else 0.0
			var phase := 0
			var position := Vector2(x,y)
			if animated and kinds[i]=="squash":
				if cycle>=1.8 and cycle<1.96: phase = 1; position.y += 16
				elif cycle>=1.96 and cycle<2.28:
					phase = 2
					position.y -= sin((cycle-1.96)/0.32*PI)*95
				elif cycle>=2.28 and cycle<2.5: phase = 3; position.y += 38
			art.draw(self,kinds[i],position,2.0,time,pulse,charge,animated and cycle>1,phase)
			draw_string(ThemeDB.fallback_font,Vector2(x-175,y+136),names[i],HORIZONTAL_ALIGNMENT_CENTER,350,25,Color("#3d6243"))

func _init() -> void:
	call_deferred("capture")

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
	assert(root.get_texture().get_image().save_png("res://dist/plant-batch3-static.png")==OK)
	quit()
