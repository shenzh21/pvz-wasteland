extends SceneTree

class Sheet extends "res://scripts/game_view.gd":
	var equipment := true
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),Color("#e5edcd"))
		if equipment:
			var kinds := ["cone","bucket","charger","copper","kart","imp"]
			var names := ["路障","铁桶","钢盔冲锋","铜头","小鬼车","车毁后的小鬼"]
			for i in 6:
				var pos := Vector2(210+i%3*425,163+int(i/3)*350)
				var panel := StyleBoxFlat.new()
				panel.bg_color = Color("#f3f6dc")
				panel.set_corner_radius_all(20)
				draw_style_box(panel,Rect2(pos-Vector2(191,140),Vector2(383,327)))
				draw_zombie({"x":pos.x,"draw_y":pos.y+25,"row":2,"kind":kinds[i],"anim":0.0,"slow":0.0,"hp":2000.0,"max_hp":2000.0,"walking":false,"biting":false,"hide_bar":true,"draw_scale":1.3 if kinds[i]!="kart" else 1.6})
				draw_string(ThemeDB.fallback_font,pos+Vector2(-180,164),names[i],HORIZONTAL_ALIGNMENT_CENTER,360,23,Color("#3d6243"))
		else:
			var maps := ["frontyard","wasteland","wildland"]
			var names := ["前院","荒地","芜地"]
			for i in 3:
				var pos := Vector2(i%2*640,int(i/2)*360)
				draw_texture_rect(CachedBackground.get_texture(maps[i],false),Rect2(pos,Vector2(640,360)),false)
				draw_string(ThemeDB.fallback_font,pos+Vector2(20,34),names[i],HORIZONTAL_ALIGNMENT_LEFT,200,23,Color("#fff1ba"))
			draw_texture_rect_region(CachedBackground.get_texture("wildland",true),Rect2(640,360,640,360),Rect2(650,0,1280,720))
			draw_string(ThemeDB.fallback_font,Vector2(660,394),"芜地 · 选卡右侧候场区",HORIZONTAL_ALIGNMENT_LEFT,540,23,Color("#fff1ba"))

func _init() -> void: call_deferred("capture")

func capture() -> void:
	var sheet := Sheet.new()
	root.add_child(sheet)
	for equipment in [true,false]:
		sheet.equipment = equipment
		sheet.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://dist/"+("equipment-preview.png" if equipment else "scenery-preview.png"))==OK)
	quit()
