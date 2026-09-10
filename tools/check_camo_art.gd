extends "res://scripts/game_view.gd"
func _ready() -> void:
	show_health_bars = false
	capture.call_deferred()
func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#23372b"))
	draw_string(ThemeDB.fallback_font,Vector2(45,55),"军迷僵尸 · 迷彩匍匐造型",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#e7e3cb"))
	var samples := [
		{"x":280.0,"draw_y":235.0,"anim":.35,"walking":true,"label":"匍匐前进"},
		{"x":885.0,"draw_y":235.0,"anim":.14,"walking":false,"biting":true,"label":"停止啃咬"},
		{"x":280.0,"draw_y":490.0,"anim":.7,"walking":true,"arm_lost":true,"label":"断臂后继续爬行"},
		{"x":885.0,"draw_y":490.0,"anim":.8,"walking":false,"rooted":true,"slow":2.0,"label":"冰冻 / 被固定"}
	]
	for z in samples:
		z.kind="camo"
		z.row=0
		z.draw_scale=2.3
		if not z.has("slow"): z.slow=0.0
		draw_string(ThemeDB.fallback_font,Vector2(z.x-145,z.draw_y-115),z.label,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("#c4cfa9"))
		draw_camo_zombie(z)
	draw_string(ThemeDB.fallback_font,Vector2(45,665),"低位轮廓 · 迷彩帽与衣服 · 护肘 / 军靴 · 独立下颌",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#9cab8d"))
func capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://assets/zombies/camo/game-preview.png")
	get_tree().quit()
