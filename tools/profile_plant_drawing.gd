extends SceneTree

# 诊断专用：固定阵型，不读取或推进玩家关卡。
class Bench extends "res://main.gd":
	var timings: Array[float] = []
	var frames := 0
	var case_index := 0
	var sizes := [0,15,45]
	func _ready() -> void:
		super._ready()
		collect_music_prewarm(true)
		setup_case()
	func setup_case() -> void:
		reset_game(1)
		sun_points = 100000
		var kinds := ["sunflower","pea","snow","energy_pea","wall","needle","yam_guard"]
		if "--third-batch" in OS.get_cmdline_user_args(): kinds = ["cactus","slime","squash","bbq_mushroom"]
		if "--fourth-batch" in OS.get_cmdline_user_args(): kinds = ["pumpkin","wind_grass","sky_pepper"]
		for i in sizes[case_index]: place_plant(kinds[i%kinds.size()],i%9,int(i/9))
		particles.clear()
		sun_points = 350
		frames = 0
		timings.clear()
	func _process(delta: float) -> void:
		for p in plants: p.anim += delta
		queue_redraw()
	func _draw() -> void:
		var start := Time.get_ticks_usec()
		super._draw()
		var elapsed := float(Time.get_ticks_usec()-start)/1000.0
		frames += 1
		if frames>30: timings.append(elapsed)
		if frames==150: call_deferred("finish_case")
	func finish_case() -> void:
		timings.sort()
		var total := 0.0
		for value in timings: total += value
		print("DRAW_PROFILE count=%d avg_ms=%.3f p95_ms=%.3f max_ms=%.3f" % [sizes[case_index],total/timings.size(),timings[int(timings.size()*0.95)],timings[-1]])
		case_index += 1
		if case_index==sizes.size(): get_tree().quit()
		else: setup_case()

func _init() -> void:
	call_deferred("setup")

func setup() -> void:
	root.add_child(Bench.new())
