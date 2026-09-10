extends SceneTree

func _initialize() -> void:
	var view = load("res://main.gd").new()
	view.rng.seed = 17
	view.build_zombie_preview()
	var before = view.preview_zombies.duplicate(true)
	view.update_preview_idle(.65)
	var art = load("res://scripts/zombie_art.gd")
	var unique_times := {}
	for i in before.size():
		var old: Dictionary = before[i]
		var now: Dictionary = view.preview_zombies[i]
		assert(is_equal_approx(float(now.anim)-float(old.anim),.65),"选卡必须推进动画时间")
		assert(now.x==old.x and now.draw_y==old.draw_y,"待机不能改变站位")
		unique_times[now.anim] = true
		var a: Dictionary = art.pose(old)
		var b: Dictionary = art.pose(now)
		for id in ["far_thigh","far_calf","far_shoe","near_thigh","near_calf","near_shoe"]:
			assert(a[id].is_equal_approx(b[id]),"待机脚部必须站定")
		assert(not a.head.is_equal_approx(b.head),"头部应有轻微待机摇摆")
		assert(not a.torso.is_equal_approx(b.torso),"肩部应有轻微待机摇摆")
	assert(unique_times.size()>1,"僵尸待机节奏不应完全同步")
	view.free()
	print("PASS: preview animation advances; feet/positions fixed; head/torso sway; phases staggered")
	quit()
