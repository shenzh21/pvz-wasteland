extends "res://main.gd"
var check_prepare := false

func _ready() -> void:
	super._ready()
	set_process(false)
	show_health_bars = false
	check_prepare = "--prepare-art-check" in OS.get_cmdline_user_args()
	if check_prepare:
		rng.seed = 42
		prepare_level(6)
		prepare_camera_x = 520.0
	queue_redraw()
	verify_capture.call_deferred()

func _draw() -> void:
	if check_prepare:
		super._draw()
		return
	draw_rect(Rect2(0,0,1280,720),Color("#253b2d"))
	draw_string(ThemeDB.fallback_font,Vector2(45,55),"小鬼：红衣 / 走路 / 啃咬 / 冰冻 / 卡丁车",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#ece6ce"))
	var cases := [
		{"kind":"normal","x":190.0,"draw_y":420.0,"draw_scale":1.6,"anim":.8,"walking":true,"slow":0.0},
		{"kind":"imp","x":440.0,"draw_y":440.0,"draw_scale":2.1,"anim":.8,"walking":true,"slow":0.0},
		{"kind":"imp","x":660.0,"draw_y":440.0,"draw_scale":2.1,"anim":.14,"walking":false,"biting":true,"slow":0.0},
		{"kind":"imp","x":875.0,"draw_y":440.0,"draw_scale":2.1,"anim":.8,"walking":true,"slow":2.0},
		{"kind":"kart","x":1110.0,"draw_y":430.0,"draw_scale":1.6,"anim":.8,"walking":true,"slow":0.0}
	]
	for z in cases:
		z.row = 0
		draw_zombie(z)
	draw_string(ThemeDB.fallback_font,Vector2(60,630),"左：普通僵尸比例参考；中：红衣小鬼与独立下颌；右：更新后的驾驶员",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("#bdcaae"))

func verify_capture() -> void:
	await RenderingServer.frame_post_draw
	var captured := get_viewport().get_texture().get_image()
	var output := "res://assets/zombies/imp/selection-check.png" if check_prepare else "res://assets/zombies/imp/game-preview.png"
	assert(captured.save_png(output)==OK,"无法写入截图")
	if check_prepare:
		var skin_pixels := 0
		for y in range(150,690):
			for x in range(780,1275):
				var c := captured.get_pixel(x,y)
				if absf(c.r-.588)<.035 and absf(c.g-.631)<.035 and absf(c.b-.514)<.035:
					skin_pixels += 1
		assert(skin_pixels>80,"选卡界面右侧必须可见僵尸，检查摄像机绘图偏移")
		print("Selection preview skin pixels: ",skin_pixels)
	get_tree().quit()
