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
		var art = preload("res://scripts/plant_batch2_art.gd")
		var kinds := ["mine_hidden","mine","cherry","yam_guard","yam_minion","needle"]
		var names := ["土豆雷 · 未出土","土豆雷 · 已就绪","樱桃炸弹","红薯防卫队","小红薯","鬼针草射手"]
		draw_rect(Rect2(0,0,1280,720),Color("#e5edcd"))
		for i in kinds.size():
			var x := 220.0+(i%3)*420
			var y := 160.0+(i/3 as int)*335
			var panel := StyleBoxFlat.new()
			panel.bg_color = Color("#f3f6dc")
			panel.set_corner_radius_all(24)
			draw_style_box(panel,Rect2(x-185,y-130,370,302))
			var phase := fposmod(time,3.0)
			var charge := clampf((phase-1.8)/0.72,0.0,1.0) if animated and kinds[i]=="cherry" else 0.0
			var pulse := maxf(0,1-fposmod(time,0.65)*5) if animated else 0.0
			art.draw(self,kinds[i],Vector2(x,y),2.05 if kinds[i]!="yam_minion" else 1.6,time,pulse,charge,animated and phase>1.0 and phase<2.5)
			draw_string(ThemeDB.fallback_font,Vector2(x-175,y+137),names[i],HORIZONTAL_ALIGNMENT_CENTER,350,24,Color("#3d6243"))

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	var sheet := Sheet.new()
	root.add_child(sheet)
	if "--animate" in OS.get_cmdline_user_args():
		sheet.animated = true
		for frame in 240: await process_frame
		quit()
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://dist/plant-batch2-static.png")==OK)
	quit()
